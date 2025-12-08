# Week 6: Capstone - MiniExchange (Integrated DEX)

## 🎯 Learning Objectives

- Integrate all testing concepts from previous weeks
- Implement mainnet forking tests
- Use advanced fuzzing for DeFi logic
- Test complex token interactions
- Simulate real-world DEX scenarios

## 📚 Concepts Covered

### Mainnet Forking

```bash
# Start Anvil with mainnet fork
anvil --fork-url https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY

# Run tests against fork
forge test --fork-url https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
```

```solidity
// In tests - fork at specific block
function setUp() public {
    // Fork mainnet at block 18000000
    vm.createSelectFork("mainnet", 18000000);
}
```

### Advanced Fuzzing

```solidity
// Fuzz with assumptions
function testFuzzSwap(uint256 amountIn) public {
    // Bound inputs
    amountIn = bound(amountIn, 1e18, 1000e18);
    
    // Assume valid state
    vm.assume(token.balanceOf(user) >= amountIn);
    
    // Test
    exchange.swap(amountIn);
}

// Invariant testing
function invariant_totalSupplyConstant() public {
    assertEq(token.totalSupply(), INITIAL_SUPPLY);
}
```

### Testing Token Interactions

```solidity
// Deal ERC20 tokens
deal(address(token), user, 1000e18);

// Check balances changed correctly
uint256 balanceBefore = token.balanceOf(user);
exchange.swap(...);
uint256 balanceAfter = token.balanceOf(user);
assertEq(balanceAfter, balanceBefore - swapAmount);
```

## 🔧 Contract: MiniExchange.sol

A simplified DEX demonstrating:
- ERC20 token trading pairs
- Constant product AMM (x * y = k)
- Liquidity provision and withdrawal
- Price impact calculations
- Fee mechanics

## 🧪 Complete Test Coverage

| Category | Tests | Techniques |
|----------|-------|------------|
| Unit | Swap, add/remove liquidity | All assertions |
| Integration | Multi-token swaps | Fixtures, helpers |
| Fuzz | Random amounts | bound(), vm.assume |
| Invariant | k constant, reserves | invariant_ prefix |
| Fork | Real token behavior | vm.createSelectFork |
| Gas | Swap efficiency | --gas-report |

## 📝 Key Learnings

### 1. Testing AMM Invariants

```solidity
function invariant_kNeverDecreases() public {
    uint256 k = exchange.reserveA() * exchange.reserveB();
    assertGe(k, initialK, "K should never decrease");
}
```

### 2. Fork Testing Real Tokens

```solidity
function testSwapWithRealUSDC() public {
    // Fork mainnet
    vm.createSelectFork(vm.envString("ETH_RPC_URL"));
    
    // Real USDC address
    IERC20 usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    
    // Deal real USDC
    deal(address(usdc), user, 10000e6);
    
    // Test against real token
    vm.prank(user);
    usdc.approve(address(exchange), 1000e6);
    
    vm.prank(user);
    exchange.swap(address(usdc), 1000e6);
}
```

### 3. Price Impact Testing

```solidity
function testPriceImpact() public {
    uint256 smallSwap = 1e18;
    uint256 largeSwap = 100e18;
    
    uint256 smallOutput = exchange.getAmountOut(smallSwap);
    uint256 largeOutput = exchange.getAmountOut(largeSwap);
    
    // Large swaps should have worse rate
    uint256 smallRate = smallOutput * 1e18 / smallSwap;
    uint256 largeRate = largeOutput * 1e18 / largeSwap;
    
    assertGt(smallRate, largeRate, "Large swaps should have price impact");
}
```

### 4. Comprehensive Fuzzing

```solidity
function testFuzzAddLiquidity(uint256 amountA, uint256 amountB) public {
    amountA = bound(amountA, 1e18, 1_000_000e18);
    amountB = bound(amountB, 1e18, 1_000_000e18);
    
    // Assume reasonable ratio
    vm.assume(amountA * 100 >= amountB);
    vm.assume(amountB * 100 >= amountA);
    
    uint256 sharesBefore = exchange.balanceOf(user);
    
    _addLiquidity(user, amountA, amountB);
    
    assertGt(exchange.balanceOf(user), sharesBefore);
}
```

## 🚀 Running This Week's Project

```bash
cd week-06-miniexchange

# Compile
forge build

# Run all tests
forge test -vvv

# Run with mainnet fork (requires RPC URL)
export ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
forge test --fork-url $ETH_RPC_URL -vvv

# Run invariant tests
forge test --match-contract Invariant

# Run fuzz tests with more runs
forge test --match-test testFuzz --fuzz-runs 1000

# Full gas report
forge test --gas-report

# Snapshot for CI comparison
forge snapshot
```

## ✅ Final Checklist

### From All Weeks:
- [ ] **Week 1**: setUp fixtures, console2.log debugging
- [ ] **Week 2**: vm.deal, vm.prank for transactions
- [ ] **Week 3**: All assertion types (eq, gt, approx)
- [ ] **Week 4**: vm.expectRevert, vm.expectEmit
- [ ] **Week 5**: vm.snapshot, vm.revertTo, gas optimization

### Week 6 Specific:
- [ ] Implemented MiniExchange with AMM logic
- [ ] Created comprehensive unit tests
- [ ] Added fuzz tests for all user inputs
- [ ] Implemented invariant tests for AMM properties
- [ ] Created fork tests for real token behavior
- [ ] Generated complete gas report
- [ ] All tests passing

## 🎓 Portfolio Complete!

Congratulations! You now have a complete Foundry testing portfolio demonstrating:

1. **Core Foundry Skills**: forge, anvil, cast
2. **Test Organization**: fixtures, helpers, inheritance
3. **Assertion Mastery**: all types with proper usage
4. **Cheatcode Proficiency**: prank, deal, warp, expect*
5. **Advanced Testing**: fuzzing, invariants, forking
6. **Gas Awareness**: optimization and reporting

This portfolio showcases the skills needed for blockchain security engineering roles.
