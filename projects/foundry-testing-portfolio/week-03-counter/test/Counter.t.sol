// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/Counter.sol";

/// @title CounterTest
/// @notice Comprehensive test suite demonstrating all assertion types
/// @dev Focus: assertEq, assertGt, assertLt, assertApproxEq, and fuzz testing
contract CounterTest is Test {
    // ============ State Variables ============
    
    Counter public counter;
    address public owner;
    address public alice;
    
    uint256 constant INITIAL_COUNT = 50;
    uint256 constant STEP = 5;
    uint256 constant MIN_COUNT = 0;
    uint256 constant MAX_COUNT = 100;
    uint256 constant PRECISION = 1e18;
    
    // ============ Events ============
    
    event CountChanged(uint256 indexed oldValue, uint256 indexed newValue, address indexed by);
    event StepChanged(uint256 oldStep, uint256 newStep);
    
    // ============ Setup ============
    
    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        
        counter = new Counter(INITIAL_COUNT, STEP, MIN_COUNT, MAX_COUNT);
        
        console2.log("=== Counter Test Setup ===");
        console2.log("Initial count:", counter.count());
        console2.log("Step:", counter.step());
        console2.log("Bounds:", MIN_COUNT, "to", MAX_COUNT);
    }
    
    // ============ Basic Equality Tests (assertEq) ============
    
    /// @notice Test initial state with assertEq
    function testInitialState() public view {
        assertEq(counter.count(), INITIAL_COUNT, "Initial count mismatch");
        assertEq(counter.step(), STEP, "Step mismatch");
        assertEq(counter.minCount(), MIN_COUNT, "Min count mismatch");
        assertEq(counter.maxCount(), MAX_COUNT, "Max count mismatch");
        assertEq(counter.owner(), owner, "Owner mismatch");
    }
    
    /// @notice Test increment updates count correctly
    function testIncrement() public {
        uint256 countBefore = counter.count();
        counter.increment();
        
        assertEq(
            counter.count(), 
            countBefore + STEP, 
            "Count should increase by step"
        );
    }
    
    /// @notice Test multiple increments
    function testMultipleIncrements() public {
        uint256 incrementCount = 5;
        
        for (uint256 i = 0; i < incrementCount; i++) {
            counter.increment();
        }
        
        assertEq(
            counter.count(),
            INITIAL_COUNT + (STEP * incrementCount),
            "Count should increase by step * incrementCount"
        );
    }
    
    /// @notice Test incrementBy with specific amount
    function testIncrementBy() public {
        uint256 amount = 15;
        counter.incrementBy(amount);
        
        assertEq(counter.count(), INITIAL_COUNT + amount);
    }
    
    /// @notice Test decrement
    function testDecrement() public {
        uint256 countBefore = counter.count();
        counter.decrement();
        
        assertEq(counter.count(), countBefore - STEP);
    }
    
    // ============ Comparison Tests (assertGt, assertLt, assertGe, assertLe) ============
    
    /// @notice Test count is always within bounds
    function testCountWithinBounds() public view {
        assertGe(counter.count(), counter.minCount(), "Count should be >= min");
        assertLe(counter.count(), counter.maxCount(), "Count should be <= max");
    }
    
    /// @notice Test increment increases count
    function testIncrementIncreasesCount() public {
        uint256 countBefore = counter.count();
        counter.increment();
        
        assertGt(counter.count(), countBefore, "Count should increase after increment");
    }
    
    /// @notice Test decrement decreases count
    function testDecrementDecreasesCount() public {
        uint256 countBefore = counter.count();
        counter.decrement();
        
        assertLt(counter.count(), countBefore, "Count should decrease after decrement");
    }
    
    /// @notice Test remaining capacity
    function testRemainingCapacity() public view {
        uint256 remaining = counter.getRemainingCapacity();
        
        assertEq(remaining, MAX_COUNT - INITIAL_COUNT);
        assertGe(remaining, 0, "Remaining should be non-negative");
        assertLe(remaining, MAX_COUNT, "Remaining should not exceed max");
    }
    
    // ============ Boolean Tests (assertTrue, assertFalse) ============
    
    /// @notice Test isAtMax when not at max
    function testNotAtMax() public view {
        assertFalse(counter.isAtMax(), "Should not be at max initially");
    }
    
    /// @notice Test isAtMax when at max
    function testIsAtMaxWhenAtMax() public {
        counter.setCount(MAX_COUNT);
        assertTrue(counter.isAtMax(), "Should be at max");
    }
    
    /// @notice Test isAtMin
    function testIsAtMin() public {
        counter.setCount(MIN_COUNT);
        assertTrue(counter.isAtMin(), "Should be at min");
        
        counter.increment();
        assertFalse(counter.isAtMin(), "Should not be at min after increment");
    }
    
    // ============ Approximate Equality Tests ============
    
    /// @notice Test percentage calculation with precision
    function testPercentageOfMax() public view {
        // Initial: 50 / 100 = 50% = 0.5e18
        uint256 percentage = counter.getPercentageOfMax();
        uint256 expected = (INITIAL_COUNT * PRECISION) / MAX_COUNT;
        
        assertEq(percentage, expected, "Percentage calculation mismatch");
    }
    
    /// @notice Test percentage with approximate equality
    function testPercentageApproximate() public {
        counter.setCount(33);
        
        // 33% should be approximately 0.33e18
        uint256 percentage = counter.getPercentageOfMax();
        uint256 expected = 0.33e18;
        
        // Allow 1% relative difference
        assertApproxEqRel(
            percentage, 
            expected, 
            0.01e18, 
            "Percentage should be approximately 33%"
        );
    }
    
    /// @notice Test average calculation with absolute tolerance
    function testAverageValueApproxAbs() public {
        // Add some values to history
        counter.increment(); // 55
        counter.increment(); // 60
        counter.decrement(); // 55
        
        // History: [50, 55, 60, 55]
        // Average: 220 / 4 = 55
        uint256 average = counter.getAverageValue();
        uint256 expected = 55 * PRECISION;
        
        // Allow 1 wei absolute difference (for rounding)
        assertApproxEqAbs(
            average,
            expected,
            1,
            "Average should be approximately 55"
        );
    }
    
    /// @notice Test relative precision for percentages
    function testRelativePrecision() public {
        counter.setCount(99);
        
        uint256 percentage = counter.getPercentageOfMax();
        uint256 expected = 0.99e18;
        
        // Allow 0.1% relative difference
        assertApproxEqRel(
            percentage,
            expected,
            0.001e18,
            "Should be approximately 99%"
        );
    }
    
    // ============ Not Equal Tests ============
    
    /// @notice Test values are different after change
    function testNotEqualAfterChange() public {
        uint256 valueBefore = counter.count();
        counter.increment();
        
        assertNotEq(counter.count(), valueBefore, "Count should change after increment");
    }
    
    // ============ Array Tests ============
    
    /// @notice Test history array
    function testHistoryArray() public {
        counter.increment();
        counter.increment();
        counter.decrement();
        
        uint256[] memory history = counter.getHistory();
        
        assertEq(history.length, 4, "History should have 4 entries");
        assertEq(history[0], INITIAL_COUNT, "First entry should be initial");
        assertEq(history[1], INITIAL_COUNT + STEP, "Second entry after increment");
        assertEq(history[2], INITIAL_COUNT + (2 * STEP), "Third entry after increment");
        assertEq(history[3], INITIAL_COUNT + STEP, "Fourth entry after decrement");
    }
    
    /// @notice Test history length grows correctly
    function testHistoryLengthGrows() public {
        uint256 initialLength = counter.getHistoryLength();
        assertEq(initialLength, 1, "Should start with 1 entry");
        
        counter.increment();
        assertEq(counter.getHistoryLength(), 2);
        
        counter.increment();
        assertEq(counter.getHistoryLength(), 3);
    }
    
    // ============ Fuzz Tests ============
    
    /// @notice Fuzz test: increment by random valid amounts
    function testFuzzIncrementBy(uint256 amount) public {
        // Bound amount to valid range
        uint256 remaining = counter.getRemainingCapacity();
        amount = bound(amount, 1, remaining);
        
        uint256 countBefore = counter.count();
        counter.incrementBy(amount);
        
        assertEq(counter.count(), countBefore + amount);
        assertLe(counter.count(), MAX_COUNT);
    }
    
    /// @notice Fuzz test: multiple random increments stay in bounds
    function testFuzzMultipleIncrements(uint8 times) public {
        // Bound to reasonable number
        times = uint8(bound(times, 0, 10));
        
        for (uint8 i = 0; i < times; i++) {
            if (counter.count() + STEP <= MAX_COUNT) {
                counter.increment();
            }
        }
        
        // Invariant: always within bounds
        assertGe(counter.count(), MIN_COUNT);
        assertLe(counter.count(), MAX_COUNT);
    }
    
    /// @notice Fuzz test: random setCount stays in bounds
    function testFuzzSetCount(uint256 value) public {
        value = bound(value, MIN_COUNT, MAX_COUNT);
        
        counter.setCount(value);
        
        assertEq(counter.count(), value);
        assertGe(counter.count(), MIN_COUNT);
        assertLe(counter.count(), MAX_COUNT);
    }
    
    /// @notice Fuzz test: percentage always <= 100%
    function testFuzzPercentageNeverExceeds100(uint256 value) public {
        value = bound(value, MIN_COUNT, MAX_COUNT);
        counter.setCount(value);
        
        uint256 percentage = counter.getPercentageOfMax();
        
        assertLe(percentage, PRECISION, "Percentage should never exceed 100%");
    }
    
    /// @notice Fuzz test: user increment tracking
    function testFuzzUserIncrements(uint8 times) public {
        times = uint8(bound(times, 1, 10));
        
        vm.startPrank(alice);
        for (uint8 i = 0; i < times; i++) {
            if (counter.count() + STEP <= MAX_COUNT) {
                counter.increment();
            }
        }
        vm.stopPrank();
        
        // User's increment count should match
        assertGe(counter.incrementsByUser(alice), 0);
        assertLe(counter.incrementsByUser(alice), times);
    }
    
    // ============ Edge Case Tests ============
    
    /// @notice Test at exact boundaries
    function testExactBoundaries() public {
        // Set to max
        counter.setCount(MAX_COUNT);
        assertEq(counter.count(), MAX_COUNT);
        assertTrue(counter.isAtMax());
        assertEq(counter.getRemainingCapacity(), 0);
        
        // Set to min
        counter.setCount(MIN_COUNT);
        assertEq(counter.count(), MIN_COUNT);
        assertTrue(counter.isAtMin());
        assertEq(counter.getRemainingCapacity(), MAX_COUNT);
    }
    
    /// @notice Test increments until max calculation
    function testIncrementsUntilMax() public view {
        uint256 remaining = MAX_COUNT - INITIAL_COUNT; // 50
        uint256 expectedIncrements = remaining / STEP;  // 10
        
        assertEq(counter.getIncrementsUntilMax(), expectedIncrements);
    }
}
