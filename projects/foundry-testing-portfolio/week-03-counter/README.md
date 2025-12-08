# Week 3: Assertions & State Validation

## 🎯 Learning Objectives

- Master all `forge-std/Test.sol` assertion functions
- Validate state changes with precision
- Test mathematical invariants
- Understand assertion failure messages
- Compare values with appropriate precision

## 📚 Concepts Covered

### Assertion Functions Reference

```solidity
// Equality assertions
assertEq(a, b);                    // a == b
assertEq(a, b, "message");         // with custom message

// Comparison assertions
assertGt(a, b);                    // a > b
assertGe(a, b);                    // a >= b
assertLt(a, b);                    // a < b
assertLe(a, b);                    // a <= b

// Boolean assertions
assertTrue(condition);              // condition is true
assertFalse(condition);             // condition is false

// Approximate equality (for decimals/rounding)
assertApproxEqAbs(a, b, maxDelta); // |a - b| <= maxDelta
assertApproxEqRel(a, b, maxPercent); // relative difference

// Not equal
assertNotEq(a, b);

// Array assertions
assertEq(arr1, arr2);              // arrays are equal
```

### Special Assertions

```solidity
// Check for specific revert
vm.expectRevert();
vm.expectRevert("Error message");
vm.expectRevert(CustomError.selector);
vm.expectRevert(abi.encodeWithSelector(CustomError.selector, arg1, arg2));

// Bound values for fuzzing
value = bound(value, min, max);
```

## 🔧 Contract: Counter.sol

An advanced counter demonstrating:
- Basic increment/decrement
- Step-based counting
- Maximum/minimum bounds
- Percentage calculations
- Owner-controlled resets

## 🧪 Tests Demonstrated

| Test | Assertion Used | Purpose |
|------|----------------|---------|
| `testIncrement` | `assertEq` | Basic equality |
| `testBounds` | `assertGe`, `assertLe` | Range validation |
| `testPercentage` | `assertApproxEqRel` | Relative precision |
| `testFuzzIncrement` | `bound`, `assertEq` | Fuzz testing |
| `testArrayState` | `assertEq(arr)` | Array comparison |

## 📝 Key Learnings

### 1. Choosing the Right Assertion

```solidity
// Use assertEq for exact values
assertEq(counter.count(), 10);

// Use assertApproxEqAbs for calculations with small rounding
assertApproxEqAbs(result, expected, 1); // within 1 wei

// Use assertApproxEqRel for percentage comparisons
assertApproxEqRel(result, expected, 0.01e18); // within 1%
```

### 2. Custom Error Messages

```solidity
assertEq(
    counter.count(), 
    expected, 
    "Count should match expected after increment"
);
```

### 3. Fuzz Testing with Bounds

```solidity
function testFuzzIncrement(uint256 times) public {
    // Bound to reasonable range
    times = bound(times, 1, 100);
    
    for (uint256 i = 0; i < times; i++) {
        counter.increment();
    }
    
    assertEq(counter.count(), times);
}
```

### 4. Testing State Invariants

```solidity
function testInvariant_NeverExceedsMax() public {
    // Invariant: count should never exceed maxCount
    assertLe(counter.count(), counter.maxCount());
}
```

## 🚀 Running This Week's Project

```bash
cd week-03-counter

# Compile
forge build

# Run all tests
forge test -vvv

# Run fuzz tests with more runs
forge test --fuzz-runs 1000

# Run specific test
forge test --match-test testFuzz -vvv

# Check gas usage
forge test --gas-report
```

## ✅ Checklist

- [ ] Implemented Counter.sol with bounds
- [ ] Used assertEq for exact comparisons
- [ ] Used assertGt/assertLt for ranges
- [ ] Used assertApproxEqAbs for calculations
- [ ] Implemented fuzz tests with bound()
- [ ] Added descriptive error messages
- [ ] All tests passing
