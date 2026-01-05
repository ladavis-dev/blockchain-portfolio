# Week 1: Forge Basics + Deployment Scripts

## 🎯 Learning Objectives

- Initialize a Foundry project from scratch
- Understand the Foundry project structure
- Write and compile basic Solidity contracts
- Create and run deployment scripts
- Use `setUp()` as a test fixture


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
| `testInitialValueIsZero` | Verify default state |
| `testStore` | Basic store and retrieve |
| `testStoreEmitsEvent` | Event emission on store |
| `testMultipleStores` | Sequential state changes |

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
forge script script/Storage.s.sol --rpc-url http://localhost:8545 --broadcast --private-key <ANVIL_PRIVATE_KEY>
```

## 🔍 Key Behaviors & Edge Cases

This contract intentionally validates failure modes and boundary conditions to demonstrate defensive smart contract design and test-driven development using Foundry.

### Key behaviors verified
- Owner-only access is enforced for privileged functions
- All state mutations emit events for off-chain indexing and monitoring
- Increment and decrement operations update state deterministically

### Edge cases handled and tested
- Reverts when attempting to store an identical value
- Prevents arithmetic underflow when decrementing at zero
- Prevents ownership transfer to the zero address
- Enforces access control using custom Solidity errors (not string reverts)

All behaviors above are validated through automated Foundry tests using `expectRevert`, `expectEmit`, and execution traces.



## ✅ Checklist

### Project Setup
- [x] Initialized Foundry project
- [x] Configured foundry.toml
- [x] Installed forge-std

### Contract Development
- [x] Wrote Storage.sol with store/retrieve logic
- [x] Implemented owner-only access control
- [x] Added custom errors and events
- [x] Handled edge cases (same value, underflow, zero address)

### Testing
- [x] Created comprehensive test suite (16 tests)
- [x] Validated revert conditions with expectRevert
- [x] Verified event emission with expectEmit
- [x] Used console2.log for debugging
- [x] All tests passing via `forge test`

### Deployment & Execution
- [x] Created deployment script
- [x] Deployed to local Anvil node

### Evidence & Documentation
- [x] Captured forge test output screenshots
- [x] Documented key behaviors and edge cases
- [x] Organized visual artifacts under screenshots/
