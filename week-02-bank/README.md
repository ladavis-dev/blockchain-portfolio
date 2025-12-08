# Week 2: Transactions & Signers

## 🎯 Learning Objectives

- Understand ETH transfers and `payable` functions
- Master `vm.deal` for funding test accounts
- Use `vm.prank` and `vm.startPrank` for impersonation
- Interact with contracts using Cast commands
- Handle `receive()` and `fallback()` functions

## 📚 Concepts Covered

### Key Cheatcodes

```solidity
// Give ETH to an address
vm.deal(address, amount);

// Impersonate address for next call only
vm.prank(address);

// Impersonate address for multiple calls
vm.startPrank(address);
vm.stopPrank();

// Create labeled address
address alice = makeAddr("alice");

// Create address with private key
(address user, uint256 privateKey) = makeAddrAndKey("user");

// Set block.timestamp
vm.warp(timestamp);

// Set block.number
vm.roll(blockNumber);
```

### Cast Commands

```bash
# Check balance
cast balance <address> --rpc-url http://localhost:8545

# Send ETH
cast send <to> --value 1ether --private-key <key> --rpc-url http://localhost:8545

# Call view function
cast call <contract> "balanceOf(address)" <address> --rpc-url http://localhost:8545

# Send transaction
cast send <contract> "deposit()" --value 1ether --private-key <key> --rpc-url http://localhost:8545
```

## 🔧 Contract: Bank.sol

A simple bank contract demonstrating:
- ETH deposits with `payable`
- Balance tracking per user
- Withdrawals with proper checks
- Emergency functions for owner
- Reentrancy protection

## 🧪 Tests Demonstrated

| Test | Description | Cheatcode Used |
|------|-------------|----------------|
| `testDeposit` | Basic deposit flow | `vm.deal`, `vm.prank` |
| `testWithdraw` | Withdrawal mechanics | `vm.startPrank` |
| `testMultipleUsers` | Multiple depositors | `makeAddr`, `vm.deal` |
| `testEmergencyWithdraw` | Owner-only emergency | `vm.prank` |
| `testReentrancyProtection` | Attack prevention | Attack contract |

## 📝 Key Learnings

### 1. Funding Test Accounts
```solidity
address alice = makeAddr("alice");
vm.deal(alice, 10 ether);
// alice now has 10 ETH
```

### 2. Impersonation Patterns
```solidity
// Single call
vm.prank(alice);
bank.deposit{value: 1 ether}();

// Multiple calls
vm.startPrank(alice);
bank.deposit{value: 1 ether}();
bank.withdraw(0.5 ether);
vm.stopPrank();
```

### 3. Testing ETH Transfers
```solidity
uint256 balanceBefore = address(alice).balance;
// ... perform action
uint256 balanceAfter = address(alice).balance;
assertEq(balanceAfter, balanceBefore - 1 ether);
```

### 4. Testing Payable Functions
```solidity
// Send ETH with function call
bank.deposit{value: 1 ether}();

// Verify contract received it
assertEq(address(bank).balance, 1 ether);
```

## 🚀 Running This Week's Project

```bash
cd week-02-bank

# Compile
forge build

# Run tests
forge test -vvv

# Start Anvil (separate terminal)
anvil

# Deploy
forge script script/Bank.s.sol --rpc-url http://localhost:8545 --broadcast

# Interact with Cast
export BANK_ADDRESS=<deployed_address>
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# Check contract balance
cast balance $BANK_ADDRESS --rpc-url http://localhost:8545

# Deposit ETH
cast send $BANK_ADDRESS "deposit()" --value 1ether --private-key $PRIVATE_KEY --rpc-url http://localhost:8545

# Check your balance in the bank
cast call $BANK_ADDRESS "balances(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url http://localhost:8545
```

## ✅ Checklist

- [ ] Implemented Bank.sol with deposit/withdraw
- [ ] Used vm.deal to fund test accounts
- [ ] Used vm.prank for impersonation
- [ ] Tested multiple user scenarios
- [ ] Implemented and tested reentrancy protection
- [ ] Deployed and interacted via Cast
- [ ] All tests passing
