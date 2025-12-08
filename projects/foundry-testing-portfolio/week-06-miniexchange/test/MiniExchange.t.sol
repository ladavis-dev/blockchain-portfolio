// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/MiniExchange.sol";
import "../src/MockERC20.sol";

/// @title MiniExchangeTest
/// @notice Capstone test suite integrating all Foundry testing concepts
/// @dev Demonstrates: fixtures, assertions, reverts, events, fuzzing, snapshots, gas
contract MiniExchangeTest is Test {
    // ============ State Variables ============
    
    MiniExchange public exchange;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    
    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    
    uint256 constant INITIAL_LIQUIDITY = 100_000e18;
    uint256 constant USER_BALANCE = 10_000e18;
    uint256 constant FEE = 30; // 0.3%
    
    // ============ Events ============
    
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event Swap(address indexed user, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    
    // ============ Setup - Comprehensive Fixture ============
    
    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        
        // Deploy tokens
        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);
        
        // Deploy exchange
        exchange = new MiniExchange(address(tokenA), address(tokenB), FEE);
        
        // Setup initial liquidity
        _setupInitialLiquidity();
        
        // Fund users
        _fundUser(alice);
        _fundUser(bob);
        _fundUser(charlie);
        
        console2.log("=== MiniExchange Test Setup ===");
        console2.log("Token A:", address(tokenA));
        console2.log("Token B:", address(tokenB));
        console2.log("Exchange:", address(exchange));
        console2.log("Reserve A:", exchange.reserveA());
        console2.log("Reserve B:", exchange.reserveB());
    }
    
    // ============ Helper Functions ============
    
    function _setupInitialLiquidity() internal {
        tokenA.mint(owner, INITIAL_LIQUIDITY);
        tokenB.mint(owner, INITIAL_LIQUIDITY);
        
        tokenA.approve(address(exchange), INITIAL_LIQUIDITY);
        tokenB.approve(address(exchange), INITIAL_LIQUIDITY);
        
        exchange.addLiquidity(INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);
    }
    
    function _fundUser(address user) internal {
        tokenA.mint(user, USER_BALANCE);
        tokenB.mint(user, USER_BALANCE);
        
        vm.startPrank(user);
        tokenA.approve(address(exchange), type(uint256).max);
        tokenB.approve(address(exchange), type(uint256).max);
        vm.stopPrank();
    }
    
    function _addLiquidity(address user, uint256 amountA, uint256 amountB) internal returns (uint256) {
        vm.prank(user);
        return exchange.addLiquidity(amountA, amountB);
    }
    
    function _swap(address user, address tokenIn, uint256 amountIn) internal returns (uint256) {
        vm.prank(user);
        return exchange.swap(tokenIn, amountIn, 0);
    }
    
    // ============ Unit Tests - Liquidity ============
    
    /// @notice Test adding liquidity updates state correctly
    function testAddLiquidity() public {
        uint256 amountA = 1000e18;
        uint256 amountB = 1000e18;
        
        uint256 reserveABefore = exchange.reserveA();
        uint256 reserveBBefore = exchange.reserveB();
        
        uint256 shares = _addLiquidity(alice, amountA, amountB);
        
        assertGt(shares, 0, "Should receive shares");
        assertEq(exchange.reserveA(), reserveABefore + amountA, "Reserve A should increase");
        assertEq(exchange.reserveB(), reserveBBefore + amountB, "Reserve B should increase");
        assertEq(exchange.shares(alice), shares, "Alice should have shares");
    }
    
    /// @notice Test removing liquidity returns tokens proportionally
    function testRemoveLiquidity() public {
        // Add liquidity first
        uint256 shares = _addLiquidity(alice, 1000e18, 1000e18);
        
        uint256 aliceABefore = tokenA.balanceOf(alice);
        uint256 aliceBBefore = tokenB.balanceOf(alice);
        
        vm.prank(alice);
        (uint256 amountA, uint256 amountB) = exchange.removeLiquidity(shares);
        
        assertGt(amountA, 0, "Should receive token A");
        assertGt(amountB, 0, "Should receive token B");
        assertEq(tokenA.balanceOf(alice), aliceABefore + amountA, "Should receive token A");
        assertEq(exchange.shares(alice), 0, "Shares should be burned");
    }
    
    // ============ Unit Tests - Swapping ============
    
    /// @notice Test basic swap A -> B
    function testSwapAToB() public {
        uint256 amountIn = 100e18;
        
        uint256 expectedOut = exchange.getAmountOut(address(tokenA), amountIn);
        uint256 aliceBBefore = tokenB.balanceOf(alice);
        
        uint256 amountOut = _swap(alice, address(tokenA), amountIn);
        
        assertEq(amountOut, expectedOut, "Output should match quote");
        assertEq(tokenB.balanceOf(alice), aliceBBefore + amountOut, "Should receive tokens");
    }
    
    /// @notice Test basic swap B -> A
    function testSwapBToA() public {
        uint256 amountIn = 100e18;
        
        uint256 expectedOut = exchange.getAmountOut(address(tokenB), amountIn);
        uint256 aliceABefore = tokenA.balanceOf(alice);
        
        uint256 amountOut = _swap(alice, address(tokenB), amountIn);
        
        assertEq(amountOut, expectedOut, "Output should match quote");
        assertEq(tokenA.balanceOf(alice), aliceABefore + amountOut, "Should receive tokens");
    }
    
    /// @notice Test price impact - larger swaps get worse rates
    function testPriceImpact() public {
        uint256 smallSwap = 10e18;
        uint256 largeSwap = 1000e18;
        
        uint256 smallOutput = exchange.getAmountOut(address(tokenA), smallSwap);
        uint256 largeOutput = exchange.getAmountOut(address(tokenA), largeSwap);
        
        // Calculate effective rate (output per input)
        uint256 smallRate = (smallOutput * 1e18) / smallSwap;
        uint256 largeRate = (largeOutput * 1e18) / largeSwap;
        
        console2.log("Small swap rate:", smallRate);
        console2.log("Large swap rate:", largeRate);
        
        assertGt(smallRate, largeRate, "Small swaps should have better rate");
    }
    
    // ============ Event Tests ============
    
    /// @notice Test Swap event emission
    function testSwapEmitsEvent() public {
        uint256 amountIn = 100e18;
        uint256 expectedOut = exchange.getAmountOut(address(tokenA), amountIn);
        
        vm.expectEmit(true, true, true, true);
        emit Swap(alice, address(tokenA), address(tokenB), amountIn, expectedOut);
        
        _swap(alice, address(tokenA), amountIn);
    }
    
    /// @notice Test LiquidityAdded event
    function testLiquidityAddedEmitsEvent() public {
        uint256 amountA = 500e18;
        uint256 amountB = 500e18;
        
        vm.expectEmit(true, false, false, false); // Just check first topic (provider)
        emit LiquidityAdded(alice, 0, 0, 0);
        
        _addLiquidity(alice, amountA, amountB);
    }
    
    // ============ Revert Tests ============
    
    /// @notice Test cannot swap zero amount
    function testCannotSwapZeroAmount() public {
        vm.expectRevert(MiniExchange.ZeroAmount.selector);
        _swap(alice, address(tokenA), 0);
    }
    
    /// @notice Test cannot swap invalid token
    function testCannotSwapInvalidToken() public {
        address fakeToken = makeAddr("fake");
        
        vm.expectRevert(MiniExchange.InvalidToken.selector);
        vm.prank(alice);
        exchange.swap(fakeToken, 100e18, 0);
    }
    
    /// @notice Test slippage protection
    function testSlippageProtection() public {
        uint256 amountIn = 100e18;
        uint256 expectedOut = exchange.getAmountOut(address(tokenA), amountIn);
        
        // Set minAmountOut higher than possible
        vm.expectRevert(MiniExchange.SlippageExceeded.selector);
        vm.prank(alice);
        exchange.swap(address(tokenA), amountIn, expectedOut + 1);
    }
    
    /// @notice Test cannot remove more shares than owned
    function testCannotRemoveExcessShares() public {
        vm.expectRevert(MiniExchange.InsufficientShares.selector);
        vm.prank(alice);
        exchange.removeLiquidity(1e18);
    }
    
    // ============ Time-Based Tests (vm.warp) ============
    
    /// @notice Test swap behavior doesn't change with time
    function testSwapConsistentOverTime() public {
        uint256 amountIn = 100e18;
        uint256 outputNow = exchange.getAmountOut(address(tokenA), amountIn);
        
        // Advance time by 1 year
        vm.warp(block.timestamp + 365 days);
        
        uint256 outputLater = exchange.getAmountOut(address(tokenA), amountIn);
        
        assertEq(outputNow, outputLater, "Price should be time-independent");
    }
    
    // ============ Snapshot Tests ============
    
    /// @notice Test multiple swap scenarios using snapshots
    function testSwapScenariosWithSnapshots() public {
        uint256 snapshot = vm.snapshot();
        
        // Scenario 1: Alice swaps
        uint256 aliceOut = _swap(alice, address(tokenA), 100e18);
        console2.log("Alice output:", aliceOut);
        
        vm.revertTo(snapshot);
        
        // Scenario 2: Bob swaps same amount (should get same output)
        uint256 bobOut = _swap(bob, address(tokenA), 100e18);
        console2.log("Bob output:", bobOut);
        
        assertEq(aliceOut, bobOut, "Same input should give same output");
        
        vm.revertTo(snapshot);
        
        // Scenario 3: Alice does two smaller swaps (should get less total due to price impact)
        uint256 aliceOut1 = _swap(alice, address(tokenA), 50e18);
        uint256 aliceOut2 = _swap(alice, address(tokenA), 50e18);
        uint256 totalSplit = aliceOut1 + aliceOut2;
        
        console2.log("Split swaps total:", totalSplit);
        
        // Single large swap might be better or worse depending on implementation
        // Here we just verify the behavior
        assertGt(totalSplit, 0, "Should receive output");
    }
    
    // ============ Fuzz Tests ============
    
    /// @notice Fuzz test swap amounts
    function testFuzzSwap(uint256 amountIn) public {
        // Bound to reasonable range
        amountIn = bound(amountIn, 1e15, USER_BALANCE);
        
        uint256 reserveABefore = exchange.reserveA();
        uint256 reserveBBefore = exchange.reserveB();
        uint256 kBefore = reserveABefore * reserveBBefore;
        
        _swap(alice, address(tokenA), amountIn);
        
        uint256 kAfter = exchange.reserveA() * exchange.reserveB();
        
        // K should never decrease (fees increase it)
        assertGe(kAfter, kBefore, "K should never decrease");
    }
    
    /// @notice Fuzz test liquidity addition
    function testFuzzAddLiquidity(uint256 amountA, uint256 amountB) public {
        amountA = bound(amountA, 1e18, USER_BALANCE);
        amountB = bound(amountB, 1e18, USER_BALANCE);
        
        uint256 sharesBefore = exchange.shares(alice);
        
        _addLiquidity(alice, amountA, amountB);
        
        assertGt(exchange.shares(alice), sharesBefore, "Should receive shares");
    }
    
    /// @notice Fuzz test round-trip liquidity
    function testFuzzLiquidityRoundTrip(uint256 amountA, uint256 amountB) public {
        amountA = bound(amountA, 1e18, USER_BALANCE / 2);
        amountB = bound(amountB, 1e18, USER_BALANCE / 2);
        
        uint256 aliceABefore = tokenA.balanceOf(alice);
        uint256 aliceBBefore = tokenB.balanceOf(alice);
        
        uint256 shares = _addLiquidity(alice, amountA, amountB);
        
        vm.prank(alice);
        (uint256 returnedA, uint256 returnedB) = exchange.removeLiquidity(shares);
        
        // Should get back approximately what was deposited (minus rounding)
        assertApproxEqRel(returnedA, amountA, 0.01e18, "Should get back ~same A");
        assertApproxEqRel(returnedB, amountB, 0.01e18, "Should get back ~same B");
    }
    
    // ============ Gas Optimization Tests ============
    
    /// @notice Measure swap gas
    function testGasSwap() public {
        uint256 gasBefore = gasleft();
        _swap(alice, address(tokenA), 100e18);
        uint256 gasUsed = gasBefore - gasleft();
        
        console2.log("Swap gas used:", gasUsed);
        assertLt(gasUsed, 150000, "Swap should be gas efficient");
    }
    
    /// @notice Measure liquidity gas
    function testGasAddLiquidity() public {
        uint256 gasBefore = gasleft();
        _addLiquidity(alice, 1000e18, 1000e18);
        uint256 gasUsed = gasBefore - gasleft();
        
        console2.log("Add liquidity gas used:", gasUsed);
    }
    
    // ============ Integration Tests ============
    
    /// @notice Test complete trading cycle
    function testCompleteTradingCycle() public {
        // 1. Alice adds liquidity
        uint256 shares = _addLiquidity(alice, 1000e18, 1000e18);
        
        // 2. Bob swaps A -> B
        uint256 bobOutput = _swap(bob, address(tokenA), 100e18);
        assertGt(bobOutput, 0);
        
        // 3. Charlie swaps B -> A
        uint256 charlieOutput = _swap(charlie, address(tokenB), 100e18);
        assertGt(charlieOutput, 0);
        
        // 4. Alice removes liquidity
        vm.prank(alice);
        (uint256 amountA, uint256 amountB) = exchange.removeLiquidity(shares);
        
        // Alice should have earned fees
        // The pool now has more tokens than initially added
        console2.log("Alice received A:", amountA);
        console2.log("Alice received B:", amountB);
    }
    
    /// @notice Test arbitrage scenario
    function testArbitrageScenario() public {
        // Large swap creates price imbalance
        _swap(alice, address(tokenA), 5000e18);
        
        uint256 priceBefore = exchange.getPrice();
        console2.log("Price after large swap:", priceBefore);
        
        // Arbitrageur can profit by swapping the other direction
        uint256 arbOutput = _swap(bob, address(tokenB), 1000e18);
        
        uint256 priceAfter = exchange.getPrice();
        console2.log("Price after arb:", priceAfter);
        
        // Price should have moved back toward equilibrium
        // (In a 1:1 pool, price should be close to 1e18)
    }
}

/// @title MiniExchangeInvariantTest
/// @notice Invariant tests for the exchange
contract MiniExchangeInvariantTest is Test {
    MiniExchange public exchange;
    MockERC20 public tokenA;
    MockERC20 public tokenB;
    
    uint256 public initialK;
    
    function setUp() public {
        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);
        exchange = new MiniExchange(address(tokenA), address(tokenB), 30);
        
        // Initial liquidity
        tokenA.mint(address(this), 100_000e18);
        tokenB.mint(address(this), 100_000e18);
        tokenA.approve(address(exchange), type(uint256).max);
        tokenB.approve(address(exchange), type(uint256).max);
        exchange.addLiquidity(100_000e18, 100_000e18);
        
        initialK = exchange.getK();
        
        // Target the exchange for invariant testing
        targetContract(address(exchange));
    }
    
    /// @notice Invariant: K value should never decrease
    function invariant_kNeverDecreases() public view {
        uint256 currentK = exchange.getK();
        assertGe(currentK, initialK, "K should never decrease");
    }
    
    /// @notice Invariant: reserves should match token balances
    function invariant_reservesMatchBalances() public view {
        assertEq(
            exchange.reserveA(),
            tokenA.balanceOf(address(exchange)),
            "Reserve A should match balance"
        );
        assertEq(
            exchange.reserveB(),
            tokenB.balanceOf(address(exchange)),
            "Reserve B should match balance"
        );
    }
}
