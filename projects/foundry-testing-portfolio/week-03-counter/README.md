# Week 3: Assertions, State Validation & Gas Analysis

## 🎯 Learning Objectives

- Validate complex state transitions using Foundry assertions
- Test numerical precision and percentage-based logic
- Apply fuzz testing with bounded inputs
- Analyze gas usage at the function level
- Verify historical state and derived metrics
- Execute and validate on-chain deployments with Anvil

---

## 📚 Concepts Covered

### Assertion Techniques Used

```solidity
// Exact equality
assertEq(actual, expected);

// Inequality & bounds
assertGt(a, b);
assertGe(a, b);
assertLt(a, b);
assertLe(a, b);

// Boolean state
assertTrue(condition);
assertFalse(condition);

// Approximate comparisons (math & percentages)
assertApproxEqAbs(a, b, maxDelta);
assertApproxEqRel(a, b, maxPercent);

// Arrays & storage
assertEq(array1, array2);
```

### Fuzzing & Safety

```solidity
// Bound fuzz inputs to safe ranges
value = bound(value, min, max);

// Fuzz test example
function testFuzzSetCount(uint256 value) public {
    value = bound(value, 0, 100);
    counter.setCount(value);
    assertEq(counter.count(), value);
}
```

---

## 🔧 Contract: Counter.sol

An advanced stateful counter demonstrating:

- Increment / decrement logic
- Step-based counting
- Min/max bounds enforcement
- Percentage-of-max calculations
- Remaining capacity calculations
- Historical state tracking (array)
- Owner-controlled mutations
- Deterministic initial configuration

---

## 🧪 Tests Executed

### Core State Tests

| Test | Description |
|------|-------------|
| `testInitialState` | Verify constructor sets values correctly |
| `testIncrement` | Single increment updates count |
| `testDecrement` | Single decrement updates count |
| `testIncrementBy` | Increment by arbitrary amount |
| `testMultipleIncrements` | Sequential increments accumulate |
| `testExactBoundaries` | Behavior at min/max limits |
| `testIsAtMax` | Boolean check at maximum |
| `testIsAtMin` | Boolean check at minimum |
| `testNotAtMax` | Boolean check below maximum |
| `testNotEqualAfterChange` | State differs after mutation |

### Derived Metrics Tests

| Test | Description |
|------|-------------|
| `testPercentageOfMax` | Percentage calculation accuracy |
| `testPercentageApproximate` | Approximate percentage matching |
| `testRelativePrecision` | Relative tolerance verification |
| `testRemainingCapacity` | Capacity calculation correctness |
| `testIncrementsUntilMax` | Steps-to-max calculation |

### Historical State Tests

| Test | Description |
|------|-------------|
| `testHistoryArray` | History records all changes |
| `testHistoryLengthGrows` | Array length increments properly |

### Fuzz Tests

| Test | Description |
|------|-------------|
| `testFuzzSetCount(uint256)` | Random valid counts |
| `testFuzzIncrementBy(uint256)` | Random increment amounts |
| `testFuzzMultipleIncrements(uint8)` | Random iteration counts |
| `testFuzzUserIncrements(uint8)` | Per-user tracking with fuzzing |
| `testFuzzPercentageNeverExceeds100(uint256)` | Invariant: percentage ≤ 100% |

---

## ⛽ Gas Report Highlights

| Function | Min | Avg | Max | Calls |
|----------|-----|-----|-----|-------|
| `count()` | 2,328 | 2,328 | 2,328 | 4,264 |
| `increment()` | 65,021 | 68,686 | 99,221 | 2,188 |
| `incrementBy()` | 80,277 | 80,277 | 80,277 | 257 |
| `setCount()` | 37,256 | 61,564 | 61,968 | 518 |
| `getPercentageOfMax()` | 4,723 | 4,723 | 4,723 | 259 |
| `getRemainingCapacity()` | 4,547 | 4,547 | 4,547 | 259 |

**Insights:**
- Read functions (`count`, `getPercentageOfMax`) are cheap (~2-5k gas)
- Write functions (`increment`, `setCount`) cost significantly more (~60-100k gas)
- History array pushes contribute to variable gas costs

---

## 🧠 Key Learnings

### 1. Precision Matters in Smart Contracts

```solidity
assertApproxEqRel(
    counter.getPercentageOfMax(),
    expected,
    0.01e18 // 1% tolerance
);
```

Used for percentage math where integer division causes rounding.

### 2. Bound Your Fuzz Inputs

```solidity
value = bound(value, MIN_COUNT, MAX_COUNT);
```

Prevents meaningless failures while preserving randomness.

### 3. State Derivation Is Testable

```solidity
assertEq(
    counter.getRemainingCapacity(),
    counter.maxCount() - counter.count()
);
```

Derived values should always be asserted — never assumed correct.

### 4. Gas Is a First-Class Signal

Foundry's gas table helps:
- Identify expensive state mutations
- Compare reads vs writes
- Validate expected complexity
- Spot optimization opportunities

---

## 🔗 On-Chain Execution (Anvil)

### Start Local Chain

```bash
anvil
```

### Deploy & Execute Script

```bash
forge script script/Counter.s.sol \
  --rpc-url http://localhost:8545 \
  --broadcast
```

### Deployment Results

- Contract deployed successfully
- Initial state configured on-chain
- Transactions recorded in `/broadcast`

---

## 🚀 Running This Week's Project

```bash
cd week-03-counter

# Compile
forge build

# Full test suite
forge test -vv

# Gas profiling
forge test --gas-report

# Extended fuzzing
forge test --fuzz-runs 1000

# Match specific tests
forge test --match-test testFuzz -vv
```

---

## ✅ Checklist

- [x] Stateful contract with bounded logic
- [x] Exact & approximate assertions
- [x] Comparison assertions (Gt, Lt, Ge, Le)
- [x] Boolean assertions (assertTrue, assertFalse)
- [x] Fuzz testing with safe bounds
- [x] Historical state validation
- [x] Derived metrics testing
- [x] Gas usage analysis
- [x] On-chain deployment via Anvil
- [x] All tests passing

---

## 🔜 Next Week Preview

**Week 4: Reverts & Events**  
Deep dive into `vm.expectRevert`, `vm.expectEmit`, and time manipulation with `vm.warp`.
