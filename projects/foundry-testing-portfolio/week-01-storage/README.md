# Week 1: Forge Basics + Deployment Scripts

## 🎯 Learning Objectives

- Initialize a Foundry project from scratch
- Understand the Foundry project structure
- Write and compile basic Solidity contracts
- Create and run deployment scripts
- Use `setUp()` as a test fixture
- Debug with `console2.log()`

## 📚 Concepts Covered

### Foundry Project Structure
```
week-01-storage/
├── foundry.toml      # Foundry configuration
├── src/              # Smart contracts
│   └── Storage.sol
├── test/             # Test files
│   └── Storage.t.sol
└── script/           # Deployment scripts
    └── Storage.s.sol
```

### Key Commands

```bash
# Initialize new project
forge init

# Build/compile contracts
forge build

# Run all tests
forge test

# Run tests with verbosity
forge test -vvv

# Run specific test
forge test --match-test testStore

# Run deployment script
forge script script/Storage.s.sol --rpc-url http://localhost:8545 --broadcast

# Start local Anvil node
anvil
```

## 🔧 Contract: Storage.sol

A simple contract demonstrating:
- State variable storage
- Getter and setter functions
- Events for state changes
- Access control basics

## 🧪 Tests Demonstrated

| Test | Description |
|------|-------------|
| `testInitialValue` | Verify default state |
| `testStore` | Basic store and retrieve |
| `testStoreEmitsEvent` | Event emission on store |
| `testMultipleStores` | Sequential state changes |
| `testConsoleLogging` | Debug output with console2 |

## 📝 Key Learnings

### 1. The `setUp()` Function
Every test contract can have a `setUp()` function that runs before each test:

```solidity
function setUp() public {
    storage = new Storage();
}
```

### 2. Console Logging
Use `console2.log()` for debugging:

```solidity
import "forge-std/console2.sol";

console2.log("Value stored:", value);
```

### 3. Test Naming Convention
- Test functions MUST start with `test`
- Use descriptive names: `testCannotWithdrawWithoutBalance`

## 🚀 Running This Week's Project

```bash
cd week-01-storage

# Compile
forge build

# Run tests
forge test -vvv

# Start local node (in separate terminal)
anvil

# Deploy to local node
forge script script/Storage.s.sol --rpc-url http://localhost:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

## ✅ Checklist

- [ ] Initialized Foundry project
- [ ] Wrote Storage.sol with store/retrieve functions
- [ ] Created comprehensive test suite
- [ ] Used console2.log for debugging
- [ ] Created deployment script
- [ ] Deployed to local Anvil node
- [ ] All tests passing
