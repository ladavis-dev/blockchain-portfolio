# 🔐 Foundry Smart Contract Testing Portfolio

> A comprehensive journey mastering Solidity contract testing with Foundry's unified stack (Forge + Anvil + Cast + forge-std).

## 🎯 Portfolio Overview

This repository demonstrates full-stack mastery of smart contract testing using Foundry. Each week builds progressively on core concepts, culminating in a production-ready testing workflow suitable for DeFi, NFT, and DAO systems.

## 📚 Learning Path

| Week | Focus | Contract | Key Skills |
|------|-------|----------|------------|
| 1 | Forge Basics + Deployment | `Storage.sol` | `forge init`, `forge build`, `forge test`, `forge script`, `anvil` |
| 2 | Transactions & Signers | `Bank.sol` | `vm.deal`, `vm.prank`, `cast send/call` |
| 3 | Assertions & State Validation | `Counter.sol` | `forge-std/Test.sol` assertions |
| 4 | Reverts & Events | `TimeLock.sol` | `vm.expectRevert`, `vm.expectEmit` |
| 5 | Fixtures, Snapshots & Gas | `Voting.sol` | `setUp()`, `vm.snapshot/revertTo`, `--gas-report` |
| 6 | Capstone: Integrated DEX | `MiniExchange.sol` | Fuzzing, forking, `vm.warp`, full integration |

## 🧱 The Testing Stack Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│  Top Layer: forge-std/Test.sol + vm cheatcodes              │
│  → Assertions, events, reverts, time control                │
├─────────────────────────────────────────────────────────────┤
│  Middle Layer: Forge                                        │
│  → Compiles, runs tests in native EVM, fuzzes inputs        │
├─────────────────────────────────────────────────────────────┤
│  Bottom Layer: Anvil                                        │
│  → Local Ethereum node, forking, deterministic state        │
└─────────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

```bash
# Clone this repository
git clone https://gitlab.com/YOUR_USERNAME/foundry-testing-portfolio.git
cd foundry-testing-portfolio

# Navigate to any week
cd week-01-storage

# Install dependencies
forge install

# Run tests
forge test -vvv

# Run with gas report
forge test --gas-report
```

## 📋 Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation) installed
- Basic Solidity knowledge
- Git for version control

## 🏗️ Project Structure

```
foundry-testing-portfolio/
├── README.md
├── week-01-storage/          # Forge basics + deployment
├── week-02-bank/             # Transactions & signers  
├── week-03-counter/          # Assertions & state validation
├── week-04-timelock/         # Reverts & events
├── week-05-voting/           # Fixtures, snapshots, gas
└── week-06-miniexchange/     # Capstone DEX project
```

Each week contains:
- `src/` - Smart contracts
- `test/` - Comprehensive test suites
- `script/` - Deployment scripts
- `README.md` - Week-specific documentation

## 🧠 Study Pattern

| Day | Activity |
|-----|----------|
| Mon-Tue | Read Foundry Book sections (forge, anvil, cast) |
| Wed-Thu | Build and test example contract |
| Fri-Sat | Extend features (add reverts, events, fuzz inputs) |
| Sun | Document findings + commit README updates |

## 🎓 Skills Demonstrated

- ✅ Native Solidity testing without JavaScript frameworks
- ✅ Forge compilation, testing, and scripting
- ✅ Anvil local node management and forking
- ✅ Cast command-line interactions
- ✅ Comprehensive assertion patterns
- ✅ Event and revert verification
- ✅ Fuzz testing for edge cases
- ✅ Gas optimization and reporting
- ✅ Mainnet forking for real-world testing

## 📖 Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [forge-std Reference](https://github.com/foundry-rs/forge-std)
- [Cheatcodes Reference](https://book.getfoundry.sh/cheatcodes/)

## 👤 Author

**L.A. Davis**  
Blockchain Security Engineer

---

*This portfolio was created as part of a structured learning path for smart contract security engineering.*


