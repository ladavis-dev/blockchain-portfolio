# Week 2: Transactions & Signers (ETH Bank)

## 🎯 Learning Objectives

- Implement ETH transfers using `payable` functions
- Safely manage user balances with checks-effects-interactions
- Fund and impersonate accounts using Foundry cheatcodes
- Test multi-user transaction flows
- Defend against reentrancy attacks
- Deploy and interact with contracts on a local Anvil chain

---

## 📚 Concepts Covered

### Core Cheatcodes Used

```solidity
// Fund an address with ETH
vm.deal(address, amount);

// Impersonate an address (single call)
vm.prank(address);

// Impersonate an address (multiple calls)
vm.startPrank(address);
vm.stopPrank();

// Deterministic test addresses
address alice = makeAddr("alice");
```

### Transaction & Chain Control

```solidity
// Control block timestamp
vm.warp(timestamp);

// Control block number
vm.roll(blockNumber);
```

---

## 🔧 Contract: Bank.sol

A simplified ETH bank demonstrating **secure transaction handling**.

### Features Implemented

- ETH deposits via `deposit()`, `receive()`, and `fallback()`
- Per-user balance tracking
- Partial and full withdrawals
- Owner-only emergency withdrawal
- Custom errors for gas-efficient reverts
- Reentrancy protection using a mutex lock
- Events for off-chain observability

---

## 🧪 Tests Demonstrated

| Test | Description | Security Focus |
|------|-------------|----------------|
| `testDeposit` | Basic ETH deposit | Payable correctness |
| `testWithdraw` | Partial withdrawals | Balance accounting |
| `testWithdrawAll` | Full balance exit | State reset safety |
| `testMultipleUserDeposits` | Multi-user accounting | Isolation |
| `testCannotDepositZero` | Zero-value guard | Input validation |
| `testCannotWithdrawMoreThanBalance` | Overdraw protection | Invariant enforcement |
| `testEmergencyWithdraw` | Owner drain | Privileged access |
| `testNonOwnerCannotEmergencyWithdraw` | Access control | Authorization |
| `testReentrancyProtection` | Active exploit attempt | Reentrancy defense |
| `testReceiveEth` | Plain ETH transfer | Fallback safety |

---

## 🔍 Key Behaviors & Edge Cases

**Verified behaviors:**

- ETH is credited correctly to sender balances
- State updates occur before external calls
- Events emit with correct parameters
- Owner privileges are enforced strictly

**Edge cases tested:**

- Zero-value deposits revert
- Withdrawals exceeding balance revert
- Withdrawals with zero balance revert
- Reentrancy attacks are blocked
- Emergency withdrawal restricted to owner only

All behaviors are validated via automated Foundry tests.

---

## 🧠 Security Patterns Reinforced

### Checks-Effects-Interactions

```solidity
// Update state BEFORE external call
balances[msg.sender] -= amount;

// External call LAST
(bool success, ) = msg.sender.call{value: amount}("");
```

### Reentrancy Guard (Mutex)

```solidity
modifier nonReentrant() {
    if (locked) revert ReentrancyGuard();
    locked = true;
    _;
    locked = false;
}
```

---

## 🚀 Running This Week's Project

```bash
cd week-02-bank

# Install dependencies (if not already installed)
forge install

# Compile contracts
forge build

# Run full test suite
forge test -vv

# Start local Ethereum node (separate terminal)
anvil

# Deploy to Anvil
forge script script/Bank.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast
```

---

## 🧪 Interacting with Cast

```bash
export BANK_ADDRESS=<deployed_address>
export PRIVATE_KEY=<private_key>

# Check bank ETH balance
cast balance $BANK_ADDRESS --rpc-url http://localhost:8545

# Deposit ETH
cast send $BANK_ADDRESS "deposit()" \
  --value 1ether \
  --private-key $PRIVATE_KEY \
  --rpc-url http://localhost:8545

# Check user balance
cast call $BANK_ADDRESS \
  "balances(address)" \
  0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 \
  --rpc-url http://localhost:8545
```

---

## ✅ Checklist

- [x] Implemented ETH bank with deposits and withdrawals
- [x] Used `vm.deal` to fund test accounts
- [x] Used `vm.prank` / `vm.startPrank` for impersonation
- [x] Tested multi-user interactions
- [x] Implemented and validated reentrancy protection
- [x] Verified access control on privileged functions
- [x] Deployed to local Anvil chain
- [x] Interacted via Cast
- [x] All tests passing

---
