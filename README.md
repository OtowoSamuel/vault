# Vault Smart Contract

A simple ERC20 token vault that allows users to deposit and withdraw tokens with withdrawal fees.

## Features

- **Deposit**: Users can deposit ERC20 tokens into the vault
- **Withdraw**: Users can withdraw their tokens with a fee deduction
- **Fee Collection**: Admin can withdraw accumulated fees
- **Transparency**: View functions to check balances and fees

## Contract Details

### Vault.sol
- Manages user deposits and withdrawals
- Charges a configurable withdrawal fee (max 10%)
- Stores accumulated fees for admin withdrawal
- Uses simple percentage-based fee calculation

### MockERC20.sol
- Simple ERC20 token implementation for testing
- Includes basic transfer, approve, and transferFrom functions

## Usage

1. Deploy the contracts:
   ```bash
   forge script script/VaultDeploy.s.sol --rpc-url <RPC_URL> --broadcast
   ```

2. Run tests:
   ```bash
   forge test
   ```

## Functions

### User Functions
- `deposit(uint256 amount)` - Deposit tokens into vault
- `withdraw(uint256 amount)` - Withdraw tokens (with fee)
- `getBalance(address user)` - Check user balance
- `calculateWithdrawalFee(uint256 amount)` - Calculate fee for amount

### Admin Functions
- `withdrawFees()` - Withdraw all accumulated fees

### View Functions
- `getTotalFees()` - Total fees collected
- `getVaultBalance()` - Total tokens in vault

## Example

```solidity
// Deploy vault with 5% withdrawal fee
Vault vault = new Vault(tokenAddress, 5, adminAddress);

// User deposits 1000 tokens
vault.deposit(1000 * 1e18);

// User withdraws 500 tokens, pays 25 tokens fee, receives 475 tokens
vault.withdraw(500 * 1e18);

// Admin withdraws 25 tokens in fees
vault.withdrawFees();
```

## Testing

The test suite covers:
- Basic deposit/withdraw functionality
- Fee calculations
- Admin permissions
- Edge cases and error conditions
- Multiple user interactions
- Event emissions
