;; Smart Contract Security Insurance System
;; This contract provides an insurance mechanism for blockchain protocols against exploits or vulnerabilities.
;; Clients can purchase coverage up to specific amounts, submit claims when incidents occur, and receive
;; reimbursement based on approved claims. The system includes claim verification, administrative controls,
;; and a pool-based coverage system.

;; Error constants
(define-constant ERR-INVALID-AMOUNT (err u100))
(define-constant ERR-INSUFFICIENT-FUNDS (err u101))
(define-constant ERR-CLAIM-NOT-FOUND (err u102))
(define-constant ERR-UNAUTHORIZED-ACCESS (err u103))
(define-constant ERR-ALREADY-INSURED (err u104))
(define-constant ERR-INVALID-PRINCIPAL (err u105))
(define-constant ERR-NOT-INSURED (err u106))
(define-constant ERR-ZERO-AMOUNT (err u107))
(define-constant ERR-CLAIM-ALREADY-PROCESSED (err u108))
(define-constant ERR-INSURANCE-POOL-EMPTY (err u109))
(define-constant ERR-CLAIM-NOT-EXPIRED (err u110))
(define-constant ERR-CLAIM-EXCEEDS-COVERAGE (err u111))

;; System constants
(define-constant CLAIM-EXPIRATION-PERIOD u4320) ;; 30 days in blocks (assuming 10-minute block times)

;; Contract state variables
(define-data-var insurance-pool-balance uint u0)
(define-data-var system-administrator principal tx-sender)

;; Data structures
(define-map insured-clients principal uint)
(define-map insurance-claims 
  { client-address: principal, claim-amount: uint } 
  { claim-status: (string-ascii 20), submission-timestamp: uint, paid-amount: uint })

;; Insurance Operations

;; Function for clients to purchase insurance coverage
(define-public (purchase-insurance (coverage-amount uint))
  (let ((client-address tx-sender))
    (asserts! (> coverage-amount u0) ERR-ZERO-AMOUNT)
    (asserts! (is-none (map-get? insured-clients client-address)) ERR-ALREADY-INSURED)
    (match (stx-transfer? coverage-amount client-address (as-contract tx-sender))
      success (begin
        (var-set insurance-pool-balance (+ (var-get insurance-pool-balance) coverage-amount))
        (map-set insured-clients client-address coverage-amount)
        (print { event: "insurance-purchased", insured-amount: coverage-amount, client: client-address })
        (ok true))
      error (err error))))

;; Function for clients to submit insurance claims
(define-public (submit-claim (claim-amount uint))
  (let (
    (client-address tx-sender)
    (insured-amount (default-to u0 (map-get? insured-clients client-address)))
  )
    (asserts! (> claim-amount u0) ERR-ZERO-AMOUNT)
    (asserts! (is-some (map-get? insured-clients client-address)) ERR-NOT-INSURED)
    (asserts! (>= insured-amount claim-amount) ERR-CLAIM-EXCEEDS-COVERAGE)
    (asserts! (is-none (map-get? insurance-claims { client-address: client-address, claim-amount: claim-amount })) ERR-CLAIM-ALREADY-PROCESSED)
    
    (map-set insurance-claims 
      { client-address: client-address, claim-amount: claim-amount } 
      { claim-status: "pending", submission-timestamp: block-height, paid-amount: u0 })
    
    (print { event: "claim-submitted", client: client-address, claim-amount: claim-amount, timestamp: block-height })
    (ok true)))

;; Administrative Functions

;; Helper function to calculate reimbursement amount
(define-private (calculate-payout-amount (claim-amount uint) (available-balance uint))
  (if (>= available-balance claim-amount)
      claim-amount
      available-balance))

;; Function for administrators to approve and process claims
(define-public (approve-claim (client-address principal) (claim-amount uint))
  (let (
    (claim-identifier { client-address: client-address, claim-amount: claim-amount })
    (claim-record (unwrap! (map-get? insurance-claims claim-identifier) ERR-CLAIM-NOT-FOUND))
    (available-funds (var-get insurance-pool-balance))
    (insured-amount (unwrap! (map-get? insured-clients client-address) ERR-NOT-INSURED))
  )
    (asserts! (is-eq tx-sender (var-get system-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get claim-status claim-record) "pending") ERR-CLAIM-ALREADY-PROCESSED)
    (asserts! (> available-funds u0) ERR-INSURANCE-POOL-EMPTY)
    (asserts! (<= claim-amount insured-amount) ERR-CLAIM-EXCEEDS-COVERAGE)
    (asserts! (< (- block-height (get submission-timestamp claim-record)) CLAIM-EXPIRATION-PERIOD) ERR-CLAIM-NOT-EXPIRED)
    
    (let ((payout-amount (calculate-payout-amount claim-amount available-funds)))
      (match (as-contract (stx-transfer? payout-amount tx-sender client-address))
        success (begin
          (var-set insurance-pool-balance (- available-funds payout-amount))
          (if (< payout-amount claim-amount)
              (map-set insurance-claims claim-identifier 
                { claim-status: "partial-payment", submission-timestamp: block-height, paid-amount: payout-amount })
              (begin
                (map-delete insurance-claims claim-identifier)
                (map-delete insured-clients client-address)))
          (print { event: "claim-approved", client: client-address, claim-amount: claim-amount, payout: payout-amount })
          (ok payout-amount))
        error (err error)))))

;; Function for administrators to deny claims
(define-public (deny-claim (client-address principal) (claim-amount uint))
  (let (
    (claim-identifier { client-address: client-address, claim-amount: claim-amount })
    (claim-record (unwrap! (map-get? insurance-claims claim-identifier) ERR-CLAIM-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender (var-get system-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (is-eq (get claim-status claim-record) "pending") ERR-CLAIM-ALREADY-PROCESSED)
    (asserts! (< (- block-height (get submission-timestamp claim-record)) CLAIM-EXPIRATION-PERIOD) ERR-CLAIM-NOT-EXPIRED)
    
    (map-set insurance-claims claim-identifier 
      { claim-status: "denied", submission-timestamp: (get submission-timestamp claim-record), paid-amount: u0 })
    
    (print { event: "claim-denied", client: client-address, claim-amount: claim-amount })
    (ok true)))

;; Function to expire outdated claims
(define-public (expire-claim (client-address principal) (claim-amount uint))
  (let (
    (claim-identifier { client-address: client-address, claim-amount: claim-amount })
    (claim-record (unwrap! (map-get? insurance-claims claim-identifier) ERR-CLAIM-NOT-FOUND))
  )
    (if (and (is-eq (get claim-status claim-record) "pending")
             (>= (- block-height (get submission-timestamp claim-record)) CLAIM-EXPIRATION-PERIOD))
        (begin
          (map-set insurance-claims claim-identifier 
            { claim-status: "expired", submission-timestamp: (get submission-timestamp claim-record), paid-amount: u0 })
          (print { event: "claim-expired", client: client-address, claim-amount: claim-amount })
          (ok true))
        (ok false))))

;; Function for transferring administrator privileges
(define-public (transfer-admin-rights (new-admin-address principal))
  (begin
    (asserts! (is-eq tx-sender (var-get system-administrator)) ERR-UNAUTHORIZED-ACCESS)
    (asserts! (not (is-eq new-admin-address 'SP000000000000000000002Q6VF78)) ERR-INVALID-PRINCIPAL)
    (print { event: "admin-transferred", previous-admin: (var-get system-administrator), new-admin: new-admin-address })
    (ok (var-set system-administrator new-admin-address))))

;; Read-only Functions

;; Function to query the current insurance pool balance
(define-read-only (get-insurance-pool-funds)
  (ok (var-get insurance-pool-balance)))

;; Function to check if a client has insurance coverage
(define-read-only (has-insurance-coverage (client-address principal))
  (is-some (map-get? insured-clients client-address)))

;; Function to query the insurance amount for a client
(define-read-only (get-insurance-coverage (client-address principal))
  (ok (default-to u0 (map-get? insured-clients client-address))))

;; Function to check the status of an insurance claim
(define-read-only (get-claim-information (client-address principal) (claim-amount uint))
  (match (map-get? insurance-claims { client-address: client-address, claim-amount: claim-amount })
    claim-record (ok { 
      status: (get claim-status claim-record), 
      timestamp: (get submission-timestamp claim-record), 
      reimbursed-amount: (get paid-amount claim-record) 
    })
    ERR-CLAIM-NOT-FOUND))