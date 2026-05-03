// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MiniExchange} from "../src/MiniExchange.sol";
import {MockERC20} from "../src/MockERC20.sol";
import "forge-std/interfaces/IERC20.sol";

/// @title MiniExchangeTest
/// @notice Capstone test suite integrating all Foundry testing concepts
/// @dev Demonstrates: fixtures, assertions, reverts, events, fuzzing, snapshots, gas
contract MiniExchangeTest is Test {
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

    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 shares);
    event Swap(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    function setUp() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 18000000);
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);

        exchange = new MiniExchange(address(tokenA), address(tokenB), FEE);

        _setupInitialLiquidity();

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

    function testRemoveLiquidity() public {
        uint256 shares = _addLiquidity(alice, 1000e18, 1000e18);

        uint256 aliceABefore = tokenA.balanceOf(alice);
        uint256 aliceBBefore = tokenB.balanceOf(alice);

        vm.prank(alice);
        (uint256 amountA, uint256 amountB) = exchange.removeLiquidity(shares);

        assertGt(amountA, 0, "Should receive token A");
        assertGt(amountB, 0, "Should receive token B");
        assertEq(tokenA.balanceOf(alice), aliceABefore + amountA, "Should receive token A");
        assertEq(tokenB.balanceOf(alice), aliceBBefore + amountB, "Should receive token B");
        assertEq(exchange.shares(alice), 0, "Shares should be burned");
    }

    function testSwapAToB() public {
        uint256 amountIn = 100e18;

        uint256 expectedOut = exchange.getAmountOut(address(tokenA), amountIn);
        uint256 aliceBBefore = tokenB.balanceOf(alice);

        uint256 amountOut = _swap(alice, address(tokenA), amountIn);

        assertEq(amountOut, expectedOut, "Output should match quote");
        assertEq(tokenB.balanceOf(alice), aliceBBefore + amountOut, "Should receive tokens");
    }

    function testSwapBToA() public {
        uint256 amountIn = 100e18;

        uint256 expectedOut = exchange.getAmountOut(address(tokenB), amountIn);
        uint256 aliceABefore = tokenA.balanceOf(alice);

        uint256 amountOut = _swap(alice, address(tokenB), amountIn);

        assertEq(amountOut, expectedOut, "Output should match quote");
        assertEq(tokenA.balanceOf(alice), aliceABefore + amountOut, "Should receive tokens");
    }

    function testPriceImpact() public view {
        uint256 smallSwap = 10e18;
        uint256 largeSwap = 1000e18;

        uint256 smallOutput = exchange.getAmountOut(address(tokenA), smallSwap);
        uint256 largeOutput = exchange.getAmountOut(address(tokenA), largeSwap);

        uint256 smallRate = (smallOutput * 1e18) / smallSwap;
        uint256 largeRate = (largeOutput * 1e18) / largeSwap;

        console2.log("Small swap rate:", smallRate);
        console2.log("Large swap rate:", largeRate);

        assertGt(smallRate, largeRate, "Small swaps should have better rate");
    }

    function testSwapEmitsEvent() public {
        uint256 amountIn = 100e18;
        uint256 expectedOut = exchange.getAmountOut(address(tokenA), amountIn);

        vm.expectEmit(true, true, true, true);
        emit Swap(alice, address(tokenA), address(tokenB), amountIn, expectedOut);

        _swap(alice, address(tokenA), amountIn);
    }

    function testLiquidityAddedEmitsEvent() public {
        uint256 amountA = 500e18;
        uint256 amountB = 500e18;

        vm.expectEmit(true, false, false, false);
        emit LiquidityAdded(alice, 0, 0, 0);

        _addLiquidity(alice, amountA, amountB);
    }

    function testCannotSwapZeroAmount() public {
        vm.expectRevert(MiniExchange.ZeroAmount.selector);
        _swap(alice, address(tokenA), 0);
    }

    function testCannotSwapInvalidToken() public {
        address fakeToken = makeAddr("fake");

        vm.expectRevert(MiniExchange.InvalidToken.selector);
        vm.prank(alice);
        exchange.swap(fakeToken, 100e18, 0);
    }

    function testSlippageProtection() public {
        uint256 amountIn = 100e18;
        uint256 expectedOut = exchange.getAmountOut(address(tokenA), amountIn);

        vm.expectRevert(MiniExchange.SlippageExceeded.selector);
        vm.prank(alice);
        exchange.swap(address(tokenA), amountIn, expectedOut + 1);
    }

    function testCannotRemoveExcessShares() public {
        vm.expectRevert(MiniExchange.InsufficientShares.selector);
        vm.prank(alice);
        exchange.removeLiquidity(1e18);
    }

    function testSwapConsistentOverTime() public {
        uint256 amountIn = 100e18;
        uint256 outputNow = exchange.getAmountOut(address(tokenA), amountIn);

        vm.warp(block.timestamp + 365 days);

        uint256 outputLater = exchange.getAmountOut(address(tokenA), amountIn);

        assertEq(outputNow, outputLater, "Price should be time-independent");
    }

    function testSwapScenariosWithSnapshots() public {
        uint256 snapshot = vm.snapshotState();

        uint256 aliceOut = _swap(alice, address(tokenA), 100e18);
        console2.log("Alice output:", aliceOut);

        vm.revertToState(snapshot);

        uint256 bobOut = _swap(bob, address(tokenA), 100e18);
        console2.log("Bob output:", bobOut);

        assertEq(aliceOut, bobOut, "Same input should give same output");

        vm.revertToState(snapshot);

        uint256 aliceOut1 = _swap(alice, address(tokenA), 50e18);
        uint256 aliceOut2 = _swap(alice, address(tokenA), 50e18);
        uint256 totalSplit = aliceOut1 + aliceOut2;

        console2.log("Split swaps total:", totalSplit);
        assertGt(totalSplit, 0, "Should receive output");
    }

    function testFuzzSwap(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e15, USER_BALANCE);

        uint256 reserveABefore = exchange.reserveA();
        uint256 reserveBBefore = exchange.reserveB();
        uint256 kBefore = reserveABefore * reserveBBefore;

        _swap(alice, address(tokenA), amountIn);

        uint256 kAfter = exchange.reserveA() * exchange.reserveB();

        assertGe(kAfter, kBefore, "K should never decrease during swaps");
    }

    function testFuzzAddLiquidity(uint256 amountA, uint256 amountB) public {
        amountA = bound(amountA, 1e18, USER_BALANCE);
        amountB = bound(amountB, 1e18, USER_BALANCE);

        uint256 sharesBefore = exchange.shares(alice);

        _addLiquidity(alice, amountA, amountB);

        assertGt(exchange.shares(alice), sharesBefore, "Should receive shares");
    }

    function testFuzzLiquidityRoundTrip(uint256 amountA) public {
        amountA = bound(amountA, 1e18, 5_000e18);
        uint256 amountB = amountA;

        uint256 aliceABefore = tokenA.balanceOf(alice);
        uint256 aliceBBefore = tokenB.balanceOf(alice);

        vm.prank(alice);
        uint256 shares = exchange.addLiquidity(amountA, amountB);

        vm.prank(alice);
        (uint256 amountAOut, uint256 amountBOut) = exchange.removeLiquidity(shares);

        assertApproxEqRel(amountAOut, amountA, 0.01e18, "Should get back ~same A");
        assertApproxEqRel(amountBOut, amountB, 0.01e18, "Should get back ~same B");

        assertApproxEqRel(tokenA.balanceOf(alice), aliceABefore, 0.01e18);
        assertApproxEqRel(tokenB.balanceOf(alice), aliceBBefore, 0.01e18);
    }

    function testGasSwap() public {
        uint256 gasBefore = gasleft();
        _swap(alice, address(tokenA), 100e18);
        uint256 gasUsed = gasBefore - gasleft();

        console2.log("Swap gas used:", gasUsed);
        assertLt(gasUsed, 150000, "Swap should be gas efficient");
    }

    function testGasAddLiquidity() public {
        uint256 gasBefore = gasleft();
        _addLiquidity(alice, 1000e18, 1000e18);
        uint256 gasUsed = gasBefore - gasleft();

        console2.log("Add liquidity gas used:", gasUsed);
    }

    function testCompleteTradingCycle() public {
        uint256 shares = _addLiquidity(alice, 1000e18, 1000e18);

        uint256 bobOutput = _swap(bob, address(tokenA), 100e18);
        assertGt(bobOutput, 0);

        uint256 charlieOutput = _swap(charlie, address(tokenB), 100e18);
        assertGt(charlieOutput, 0);

        vm.prank(alice);
        (uint256 amountA, uint256 amountB) = exchange.removeLiquidity(shares);

        console2.log("Alice received A:", amountA);
        console2.log("Alice received B:", amountB);

        assertGt(amountA, 0);
        assertGt(amountB, 0);
    }

    function testArbitrageScenario() public {
        _swap(alice, address(tokenA), 5000e18);

        uint256 priceBefore = exchange.getPrice();
        console2.log("Price after large swap:", priceBefore);

        uint256 arbOutput = _swap(bob, address(tokenB), 1000e18);

        uint256 priceAfter = exchange.getPrice();
        console2.log("Price after arb:", priceAfter);

        assertGt(arbOutput, 0, "Arbitrage swap should return output");
        assertGt(priceAfter, priceBefore, "Price should move back toward equilibrium");
    }
    function testFork_USDCInteraction() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), 18000000);

        address user = makeAddr("user");

        // Real USDC on mainnet
        address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

        IERC20 usdc = IERC20(USDC);

        // Give user real USDC
        deal(USDC, user, 10_000e6);

        assertEq(usdc.balanceOf(user), 10_000e6);

        vm.startPrank(user);
        usdc.approve(address(exchange), 1000e6);
        vm.stopPrank();
    }
}

/// @title MiniExchangeInvariantTest
/// @notice Invariant tests for the exchange
contract MiniExchangeInvariantTest is Test {
    MiniExchange public exchange;
    MockERC20 public tokenA;
    MockERC20 public tokenB;

    function setUp() public {
        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);
        exchange = new MiniExchange(address(tokenA), address(tokenB), 30);

        tokenA.mint(address(this), 100_000e18);
        tokenB.mint(address(this), 100_000e18);
        tokenA.approve(address(exchange), type(uint256).max);
        tokenB.approve(address(exchange), type(uint256).max);

        exchange.addLiquidity(100_000e18, 100_000e18);

        targetContract(address(exchange));
    }

    function invariant_kIsPositive() public view {
        uint256 currentK = exchange.getK();
        assertGt(currentK, 0, "K should always remain positive");
    }

    function invariant_reservesMatchBalances() public view {
        assertEq(exchange.reserveA(), tokenA.balanceOf(address(exchange)), "Reserve A should match balance");
        assertEq(exchange.reserveB(), tokenB.balanceOf(address(exchange)), "Reserve B should match balance");
    }
}
