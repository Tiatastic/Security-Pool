# Smart Contract Security Insurance System

## Overview

The Smart Contract Security Insurance System is a blockchain-based insurance mechanism designed to protect clients against exploits or vulnerabilities in their blockchain protocols. This system allows clients to purchase coverage, submit claims in the event of security incidents, and receive reimbursements based on approved claims.

## Purpose

In the rapidly evolving blockchain ecosystem, security vulnerabilities can lead to significant financial losses. This contract provides a decentralized insurance solution that:

1. Allows protocols to insure themselves against potential exploits
2. Creates a transparent claims process with clear verification parameters
3. Establishes a pool-based coverage system for efficient risk distribution
4. Offers administrative controls with appropriate checks and balances

## Key Features

- **Insurance Coverage Purchase**: Clients can buy insurance coverage for their protocols
- **Flexible Coverage Management**: Ability to add to existing coverage
- **Claim Submission and Processing**: Streamlined process for submitting and resolving claims
- **Administrative Controls**: Secure management of the insurance pool
- **Transparent Claim Verification**: Clear process for approving or denying claims
- **Claim Expiration System**: Automated handling of outdated claims

## Contract Structure

### Error Constants

The contract utilizes descriptive error constants to provide clear feedback when operations fail:

| Error Code | Description |
|------------|-------------|
| ERR-INVALID-AMOUNT | Invalid amount specified |
| ERR-INSUFFICIENT-FUNDS | Insufficient funds for the operation |
| ERR-CLAIM-NOT-FOUND | The specified claim does not exist |
| ERR-UNAUTHORIZED-ACCESS | Caller lacks permission for this operation |
| ERR-ALREADY-INSURED | Client is already insured |
| ERR-INVALID-PRINCIPAL | Invalid principal address provided |
| ERR-NOT-INSURED | Client does not have insurance coverage |
| ERR-ZERO-AMOUNT | Amount specified is zero |
| ERR-CLAIM-ALREADY-PROCESSED | Claim has already been processed |
| ERR-INSURANCE-POOL-EMPTY | Insurance pool has no funds |
| ERR-CLAIM-NOT-EXPIRED | Claim has not yet expired |
| ERR-CLAIM-EXCEEDS-COVERAGE | Claim amount exceeds available coverage |
| ERR-TRANSFER-FAILED | STX transfer operation failed |

### System Constants

- `CLAIM-EXPIRATION-PERIOD`: 4320 blocks (approximately 30 days assuming 10-minute block times)

### State Variables

- `insurance-pool-balance`: Tracks the total funds available in the insurance pool
- `system-administrator`: Principal address with administrative privileges

### Data Structures

- `insured-clients`: Maps client addresses to their insurance coverage amounts
- `insurance-claims`: Maps claim identifiers to claim details including status, timestamp, and paid amount

## Public Functions

### Insurance Operations

#### `purchase-insurance`
Allows clients to purchase insurance coverage.
- Parameters: `coverage-amount` (uint)
- Returns: (response bool uint)
- Example: `(contract-call? .blockchain-insurance purchase-insurance u1000)`

#### `submit-claim`
Enables insured clients to submit claims for security incidents.
- Parameters: `claim-amount` (uint)
- Returns: (response bool uint)
- Example: `(contract-call? .blockchain-insurance submit-claim u500)`

### Administrative Functions

#### `approve-claim`
Allows administrators to approve and process insurance claims.
- Parameters: `client-address` (principal), `claim-amount` (uint)
- Returns: (response uint uint)
- Example: `(contract-call? .blockchain-insurance approve-claim 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u500)`

#### `deny-claim`
Enables administrators to deny invalid insurance claims.
- Parameters: `client-address` (principal), `claim-amount` (uint)
- Returns: (response bool uint)
- Example: `(contract-call? .blockchain-insurance deny-claim 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u500)`

#### `expire-claim`
Marks outdated claims as expired.
- Parameters: `client-address` (principal), `claim-amount` (uint)
- Returns: (response bool uint)
- Example: `(contract-call? .blockchain-insurance expire-claim 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u500)`

#### `transfer-admin-rights`
Transfers administrative privileges to a new address.
- Parameters: `new-admin-address` (principal)
- Returns: (response principal uint)
- Example: `(contract-call? .blockchain-insurance transfer-admin-rights 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE)`

#### `admin-withdraw-funds`
Allows administrators to withdraw funds from the insurance pool.
- Parameters: `amount` (uint)
- Returns: (response bool uint)
- Example: `(contract-call? .blockchain-insurance admin-withdraw-funds u1000)`

### Read-Only Functions

#### `get-insurance-pool-funds`
Returns the current balance of the insurance pool.
- Parameters: None
- Returns: (response uint)
- Example: `(contract-call? .blockchain-insurance get-insurance-pool-funds)`

#### `has-insurance-coverage`
Checks if a client has insurance coverage.
- Parameters: `client-address` (principal)
- Returns: bool
- Example: `(contract-call? .blockchain-insurance has-insurance-coverage 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)`

#### `get-insurance-coverage`
Returns the insurance coverage amount for a client.
- Parameters: `client-address` (principal)
- Returns: (response uint)
- Example: `(contract-call? .blockchain-insurance get-insurance-coverage 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)`

#### `get-claim-information`
Returns information about a specific insurance claim.
- Parameters: `client-address` (principal), `claim-amount` (uint)
- Returns: (response { status: string-ascii, timestamp: uint, reimbursed-amount: uint })
- Example: `(contract-call? .blockchain-insurance get-claim-information 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u500)`

## Workflow Examples

### Client Purchases Insurance

```clarity
;; Client purchases insurance coverage of 10,000 STX
(contract-call? .blockchain-insurance purchase-insurance u10000)
```

### Client Submits a Claim

```clarity
;; Client submits a claim for 5,000 STX
(contract-call? .blockchain-insurance submit-claim u5000)
```

### Administrator Approves a Claim

```clarity
;; Administrator approves a client's claim
(contract-call? .blockchain-insurance approve-claim 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 u5000)
```

## Contract Events

The contract emits events for important actions:

- **insurance-purchased**: When a client purchases insurance coverage
- **claim-submitted**: When a client submits an insurance claim
- **claim-approved**: When an administrator approves a claim
- **claim-denied**: When an administrator denies a claim
- **claim-expired**: When a claim is marked as expired
- **admin-transferred**: When administrative privileges are transferred
- **admin-withdrawal**: When an administrator withdraws funds

## Security Considerations

1. **Administrator Controls**: The contract relies on responsible administration. Consider implementing a multi-signature approach for critical operations.

2. **Fund Security**: The insurance pool holds funds that need to be protected from unauthorized access.

3. **Claim Validation**: Ensure thorough off-chain verification of claims before approval.

4. **Price Oracle Dependency**: Consider integrating with a reliable price oracle if coverage amounts are denominated in USD but stored in STX.

5. **Scalability**: As the user base grows, monitor gas costs and optimize accordingly.

## Deployment

To deploy this contract:

1. Ensure you have Clarinet installed
2. Add the contract to your Clarinet project
3. Run the tests to verify functionality
4. Deploy to testnet for further validation
5. Deploy to mainnet