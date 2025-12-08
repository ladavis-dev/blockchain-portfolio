# Week 4: Reverts & Events

## 🎯 Learning Objectives

- Master `vm.expectRevert` for all revert types
- Use `vm.expectEmit` to verify event emissions
- Control time with `vm.warp` and `vm.roll`
- Test time-dependent contract logic
- Handle indexed vs non-indexed event parameters

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

## 🔧 Contract: TimeLock.sol

A time-locked vault demonstrating:
- Lock periods for deposits
- Time-based withdrawals
- Emergency unlock mechanisms
- Event emission for all actions
- Complex revert conditions

## 🧪 Tests Demonstrated

| Test | Cheatcode | Purpose |
|------|-----------|---------|
| `testDepositEmitsEvent` | `vm.expectEmit` | Verify event structure |
| `testCannotWithdrawBeforeUnlock` | `vm.expectRevert` | Time-based revert |
| `testWithdrawAfterUnlock` | `vm.warp` | Time advancement |
| `testMultipleIndexedEvents` | `vm.expectEmit` | Multiple topics |
| `testCustomErrorWithArgs` | `vm.expectRevert` | Error arguments |

## 📝 Key Learnings

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
    
    // Try to withdraw immediately - should fail
    vm.expectRevert(TimeLock.StillLocked.selector);
    vault.withdraw();
    
    // Advance time past lock period
    vm.warp(block.timestamp + lockDuration + 1);
    
    // Now withdrawal should succeed
    vault.withdraw();
}
```

### 3. Testing Multiple Events

```solidity
function testMultipleEvents() public {
    // Expect events in order
    vm.expectEmit(true, true, false, true);
    emit Event1(param1, param2, data1);
    
    vm.expectEmit(true, false, false, true);
    emit Event2(param1, data2);
    
    // This call emits both events
    contract.functionThatEmitsTwoEvents();
}
```

### 4. Common Revert Patterns

```solidity
// String revert
vm.expectRevert("Only owner");

// Custom error without args
vm.expectRevert(Unauthorized.selector);

// Custom error with args
vm.expectRevert(abi.encodeWithSelector(
    InsufficientBalance.selector,
    requested,
    available
));

// Panic codes
vm.expectRevert(stdError.arithmeticError);  // overflow/underflow
vm.expectRevert(stdError.divisionError);    // division by zero
vm.expectRevert(stdError.assertionError);   // assert() failure
```

## 🚀 Running This Week's Project

```bash
cd week-04-timelock

# Compile
forge build

# Run all tests
forge test -vvv

# Run revert tests only
forge test --match-test "testCannot" -vvv

# Run event tests only  
forge test --match-test "Emit" -vvv

# Run time-based tests
forge test --match-test "Lock" -vvv
```

## ✅ Checklist

- [ ] Implemented TimeLock.sol with lock periods
- [ ] Tested all custom error types
- [ ] Used vm.expectEmit for event verification
- [ ] Tested indexed vs non-indexed parameters
- [ ] Used vm.warp for time manipulation
- [ ] Tested edge cases around lock boundaries
- [ ] All tests passing
