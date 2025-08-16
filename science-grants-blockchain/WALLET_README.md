# In-App Wallet System

This document describes the in-app wallet system implemented for the Science Grants Blockchain application.

## Overview

The wallet system provides users with an in-app wallet where they can store ICP tokens before making donations. Each user gets a unique subaccount bound to their principal, following standard IC wallet practices.

## Architecture

### Components

1. **Wallet Canister** (`src/wallet/main.mo`)
   - Manages user subaccounts
   - Handles ICP transfers
   - Provides balance queries
   - Generates account identifiers for deposits

2. **Grants System Integration** (`src/grants_system/main.mo`)
   - Integrates with wallet canister
   - Validates wallet balance before donations
   - Transfers funds from user wallet during donations

3. **Frontend Components**
   - `WalletPanel.tsx` - Displays wallet balance and account ID
   - Updated `DonationForm.tsx` - Shows wallet balance and validates funds
   - Updated `App.tsx` - Integrates wallet panel into donation flow

## Features

### User Wallet Management
- **Automatic Wallet Creation**: Wallets are created automatically when users first interact with the system
- **Subaccount Generation**: Each user gets a deterministic subaccount based on their principal
- **Balance Tracking**: Real-time balance updates from the ICP ledger
- **Account ID Display**: Users can see their account ID for deposits

### Donation Flow
1. User connects their Internet Identity
2. System creates/loads their wallet
3. User funds their wallet by transferring ICP to their account ID
4. User selects a project and enters donation amount
5. System validates wallet balance
6. Funds are transferred from user wallet to grants system
7. Donation is recorded

### Security Features
- **Principal-based Access**: All wallet operations require user authentication
- **Balance Validation**: Prevents donations exceeding wallet balance
- **Subaccount Isolation**: Each user's funds are isolated in their own subaccount

## Deployment

### Prerequisites
- DFX installed and configured
- Internet Identity canister deployed
- ICP Ledger canister access

### Steps

1. **Deploy the wallet canister**:
   ```bash
   cd science-grants-blockchain
   dfx deploy wallet
   ```

2. **Update grants system with wallet canister ID**:
   ```bash
   # Get the wallet canister ID
   dfx canister id wallet
   
   # Update the grants system (manual step for now)
   # Edit src/grants_system/main.mo and update walletCanisterId
   ```

3. **Deploy the grants system**:
   ```bash
   dfx deploy grants_system
   ```

4. **Deploy the frontend**:
   ```bash
   dfx deploy frontend
   ```

## API Reference

### Wallet Canister Functions

#### `createWallet()`
Creates a new wallet for the calling user.

**Returns**: `Result.Result<WalletInfo, Text>`

#### `getWallet()`
Retrieves wallet information for the calling user.

**Returns**: `Result.Result<WalletInfo, Text>`

#### `getBalance()`
Gets the current balance of the user's wallet.

**Returns**: `Result.Result<Tokens, Text>`

#### `transfer(request: TransferRequest)`
Transfers ICP from the user's wallet to another account.

**Parameters**:
- `request.to`: Destination account identifier
- `request.amount`: Amount to transfer
- `request.memo`: Optional memo

**Returns**: `Result.Result<Nat64, Text>`

#### `getAccountId()`
Gets the account identifier for deposits.

**Returns**: `Result.Result<AccountIdentifier, Text>`

### Grants System Wallet Functions

#### `createUserWallet()`
Creates a wallet for the calling user (delegates to wallet canister).

#### `getUserWallet()`
Gets wallet information for the calling user.

#### `getWalletBalance()`
Gets the user's wallet balance.

#### `getWalletAccountId()`
Gets the user's account identifier for deposits.

## Frontend Integration

### Wallet Panel
The `WalletPanel` component displays:
- Current wallet balance
- Account ID for deposits
- Copy-to-clipboard functionality
- Refresh balance button

### Donation Form Updates
The donation form now:
- Shows current wallet balance
- Validates sufficient funds before donation
- Refreshes balance after successful donation

## Development Notes

### Mock Implementation
During development, the system uses mock implementations:
- Mock wallet balance (1 ICP)
- Mock account ID
- Simulated wallet creation

### Real Implementation
For production:
- Replace mock implementations with real canister calls
- Update canister IDs in configuration
- Test with real ICP transfers

## Security Considerations

1. **Principal Validation**: All wallet operations validate the calling principal
2. **Balance Checks**: Donations are validated against actual wallet balance
3. **Subaccount Security**: Each user's subaccount is cryptographically derived
4. **Transfer Validation**: All transfers include proper fee calculations

## Future Enhancements

1. **Multi-token Support**: Extend to support other tokens (IS20)
2. **Transaction History**: Add transaction logging and history
3. **Batch Operations**: Support for batch donations
4. **Advanced Security**: Add additional security features like time-locks
5. **UI Improvements**: Better balance visualization and transaction status

## Troubleshooting

### Common Issues

1. **Wallet not found**: Ensure user is authenticated and wallet is created
2. **Insufficient balance**: Check wallet balance and fund if needed
3. **Transfer failures**: Verify account IDs and network connectivity
4. **Canister ID issues**: Ensure wallet canister ID is correctly set in grants system

### Debug Commands

```bash
# Check wallet canister status
dfx canister status wallet

# Check grants system status
dfx canister status grants_system

# View wallet canister logs
dfx canister call wallet getWallet

# Check user balance
dfx canister call grants_system getWalletBalance
```
