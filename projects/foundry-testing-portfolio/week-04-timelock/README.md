# Week 4: Reverts & Events

## 🎯 Learning Objectives

- Master `vm.expectRevert` for all revert types
- Use `vm.expectEmit` to verify event emissions
- Control time with `vm.warp` and `vm.roll`
- Test time-dependent contract logic
- Handle indexed vs non-indexed event parameters

---

## 📚 Concepts Covered

### Revert Testing

```solidity
// Expect any revert
vm.expectRevert();
failingFunction();

// Expect specific error message (string)
vm.expectRevert("Insufficient balance");
failingFunction();

// Expect custom error (no args)
vm.expectRevert(CustomError.selector);
failingFunction();

// Expect custom error with arguments
vm.expectRevert(abi.encodeWithSelector(
    CustomError.selector,
    arg1,
    arg2
));
failingFunction();

// Expect Panic (overflow, assert, etc.)
vm.expectRevert(stdError.arithmeticError);
overflowFunction();
```

### Event Testing

```solidity
// vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, checkData)
// Topics = indexed parameters
// Data = non-indexed parameters

// Check all topics and data
vm.expectEmit(true, true, true, true);
emit ExpectedEvent(indexed1, indexed2, indexed3, data);
functionThatEmits();

// Check only first indexed parameter
vm.expectEmit(true, false, false, false);
emit ExpectedEvent(indexed1, 0, 0, 0);
functionThatEmits();

// Optionally specify emitter address
vm.expectEmit(true, true, true, true, address(contract));
emit ExpectedEvent(...);
functionThatEmits();
```

### Time Manipulation

```solidity
// Set block.timestamp
vm.warp(1704067200); // Jan 1, 2024 00:00:00 UTC

// Advance time by duration
vm.warp(block.timestamp + 1 days);

// Set block.number
vm.roll(1000000);

// Advance blocks
vm.roll(block.number + 100);
```

---

## 🔧 Contract: TimeLock.sol

A time-locked vault demonstrating **secure time-based access control**.

### Features Implemented

- Lock periods for deposits with configurable duration
- Time-based withdrawals with strict unlock enforcement
- Emergency withdrawal with 10% penalty
- Pausable contract functionality
- Comprehensive event emission for all state changes
- Custom errors with descriptive arguments
- Configurable lock duration bounds (owner-only)

---

## 🧪 Tests Executed

### Event Verification Tests

| Test | Description |
|------|-------------|
| `testDepositEmitsEvent` | Full event parameter verification |
| `testDepositEventIndexedOnly` | Indexed-only topic checking |
| `testWithdrawEmitsEvent` | Withdrawal event after unlock |
| `testEmergencyWithdrawEmitsEvent` | Penalty + payout event data |
| `testMultipleDepositsEmitEvents` | Sequential event ordering |
| `testBoundsUpdateEmitsEvent` | Admin config change event |
| `testOwnershipTransferEmitsEvent` | Ownership transfer event |

### Revert Tests (Custom Errors)

| Test | Error Tested | Security Focus |
|------|--------------|----------------|
| `testCannotDepositBelowMinimum` | `InsufficientDeposit` | Input validation |
| `testCannotDepositWithTooShortLock` | `InvalidLockDuration` | Bounds enforcement |
| `testCannotDepositWithTooLongLock` | `InvalidLockDuration` | Bounds enforcement |
| `testCannotWithdrawBeforeUnlock` | `StillLocked` | Time-based access |
| `testCannotWithdrawNonexistentLock` | `LockNotFound` | Invalid state |
| `testCannotWithdrawTwice` | `AlreadyWithdrawn` | Double-spend prevention |
| `testNonOwnerCannotUpdateBounds` | `NotOwner` | Authorization |
| `testCannotDepositWhenPaused` | `ContractPaused` | Circuit breaker |
| `testCannotTransferOwnershipToZero` | `ZeroAddress` | Zero-address guard |
| `testCannotSetInvalidBounds` | `InvalidBounds` | Config validation |

### Time Manipulation Tests

| Test | Description |
|------|-------------|
| `testWithdrawAfterUnlock` | Successful withdrawal after `vm.warp` |
| `testWithdrawAtExactUnlockTime` | Boundary: withdraw at exact unlock |
| `testCannotWithdrawOneSecondEarly` | Boundary: one second before unlock |
| `testTimeRemaining` | Countdown calculation accuracy |
| `testIsWithdrawableStatus` | Boolean status across time |
| `testBlockNumberManipulation` | `vm.roll` block advancement |

### Integration Tests

| Test | Description |
|------|-------------|
| `testFullLifecycleMultipleLocks` | Multiple locks with staggered unlocks |
| `testEmergencyWithdrawPenalty` | 10% penalty calculation verification |

---

## 🧠 Key Learnings

### 1. Understanding vm.expectEmit

```solidity
// Event definition
event Transfer(
    address indexed from,    // topic1
    address indexed to,      // topic2
    uint256 amount           // data (not indexed)
);

// Testing: check both indexed params, ignore data
vm.expectEmit(true, true, false, false);
emit Transfer(alice, bob, 0); // amount doesn't matter
contract.transfer(alice, bob, 100);
```

### 2. Testing Time-Dependent Logic

```solidity
function testUnlockAfterDelay() public {
    uint256 lockDuration = 7 days;

    // Deposit with lock
    vault.deposit{value: 1 ether}(lockDuration);

    // Try to withdraw immediately — should fail
    vm.expectRevert(TimeLock.StillLocked.selector);
    vault.withdraw(0);

    // Advance time past lock period
    vm.warp(block.timestamp + lockDuration + 1);

    // Now withdrawal should succeed
    vault.withdraw(0);
}
```

### 3. Boundary Testing Is Critical

```solidity
// Exact unlock time — should succeed
vm.warp(block.timestamp + lockDuration);
vault.withdraw(0); // passes

// One second early — should fail
vm.warp(unlockTime - 1);
vm.expectRevert(...);
vault.withdraw(0); // reverts
```

Off-by-one errors in time logic are a common audit finding.

### 4. Custom Errors with Arguments

```solidity
// Verify the exact error data including parameters
vm.expectRevert(
    abi.encodeWithSelector(
        TimeLock.StillLocked.selector,
        currentTime,    // what time it is now
        unlockTime      // when unlock happens
    )
);
```

Testing error arguments ensures contracts communicate failures clearly.

---

## 🔗 On-Chain Execution (Anvil)

### Start Local Chain

```bash
anvil
```

### Deploy

```bash
forge script script/TimeLock.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast
```

---

## 🚀 Running This Week's Project

```bash
cd week-04-timelock

# Compile
forge build

# Run all tests
forge test -vv

# Run revert tests only
forge test --match-test "testCannot" -vv

# Run event tests only
forge test --match-test "Emit" -vv

# Run time-based tests
forge test --match-test "Lock" -vv

# Gas profiling
forge test --gas-report
```

---

## ✅ Checklist

- [x] Implemented TimeLock.sol with lock periods
- [x] Tested all custom error types with arguments
- [x] Used vm.expectEmit for event verification
- [x] Tested indexed vs non-indexed parameters
- [x] Used vm.warp for time manipulation
- [x] Tested edge cases around lock boundaries
- [x] Emergency withdrawal with penalty logic
- [x] Pause/unpause functionality tested
- [x] On-chain deployment via Anvil
- [x] All tests passing

---

## 🔜 Next Week Preview

**Week 5: Fixtures, Snapshots & Gas**  
Advanced test organization with `vm.snapshot`, `vm.revertTo`, and gas optimization analysis.
