📅 Weekly Progress — Blockchain Security Engineering (Foundry)

This document tracks my weekly progress as I build secure smart contracts, simulate attacks, design DeFi mechanisms, and strengthen my testing workflows using Foundry, Solidity, Anvil, and Cast.

Each week includes:

🏗️ Project

📘 Concepts learned

🧪 Testing coverage

🛡️ Security lessons

🧰 Tools mastered

📝 Notes & reflections

Week 01 — Foundry Basics (Storage, Counter, Events, Reverts)
🏗️ Project

SimpleStorage.sol

Counter.sol (events + reverts)

📘 Concepts Learned

Foundry project structure (src/, test/, script/, foundry.toml)

Difference between forge build and forge test

Basic event testing with vm.expectEmit()

Validating reverts with vm.expectRevert()

🧪 Testing Coverage

Unit tests for read/write functions

Event emission tests

Revert tests for invalid state transitions

🛡️ Security Lessons

Prefer custom errors over require strings (gas savings)

Importance of validating state before mutation

Visibility specifiers (external vs public) in secure design

🧰 Tools Mastered

forge test -vvv (verbose trace)

cast for calling contracts

anvil as local deterministic chain

📝 Notes

Great introduction to Foundry’s developer experience. Learned how cheatcodes replace 90% of what Hardhat plugins did.

Week 02 — Allowlist Access Control + Custom Errors
🏗️ Project

Greeter.sol with allowlist-based permissioning

📘 Concepts Learned

Mapping-based allowlist design

Using vm.prank() to simulate msg.sender

Namespacing custom errors: Greeter.NotAllowed.selector

🧪 Testing Coverage

Access control tests

State update tests

Revert tests

Event tests

🛡️ Security Lessons

Always pair access control with custom errors

Avoid hardcoded owner addresses

Prefer explicit allowlists over boolean flags

🧰 Tools Mastered

Deep dive into cheatcodes: vm.prank, vm.expectRevert

Lint warnings: named imports, modifier wrapping

📝 Notes

Understanding access control patterns is critical—this week reinforced secure design choices for permissioned functions.

Week 03 — PiggyBank Vault (Secure Withdrawal Patterns)
🏗️ Project

PiggyBank.sol — ETH vault with controlled withdraw logic

📘 Concepts Learned

Receive vs fallback functions

Safe ETH sending patterns (avoid transfer)

Handling custom withdrawal errors

🧪 Testing Coverage

Deposit tests

Withdraw success path

Expected reverts (wrong sender, insufficient balance)

Fuzz testing deposit inputs

🛡️ Security Lessons

Using call{value: …} is the safest ETH transfer method

Need to test revert paths involving fallback revert logic

Withdrawals must be protected from reentrancy

🧰 Tools Mastered

forge test -vvvv for full trace debugging

Understanding return/revert paths in verbose logs

📝 Notes

Foundry trace output helped identify a failing test caused by the test contract’s fallback behavior—a great debugging experience.

Week 04 — Fuzzing & Property-Based Testing
🏗️ Project

Fuzz tests for arithmetic, vault logic, and access control patterns

📘 Concepts Learned

Writing fuzz tests (function testFuzz…(uint256 x))

Constraining fuzz inputs

Coverage of edge cases through randomness

🧪 Testing Coverage

Fuzzing setters

Fuzzing ERC20-like transfer behavior

Foundry’s automatic shrinking

🛡️ Security Lessons

Fuzzing exposes unexpected behavior quickly

Edge-case centric design improves robustness

Fuzz → invariants → formal verification pipeline

🧰 Tools Mastered

forge test --fuzz-runs <n>

Fuzz logs + debugging unexpected panic codes

📝 Notes

Fuzzing feels like having a second engineer relentlessly trying to break your logic.

Week 05 — ERC20 Token + Attack Surface Testing
🏗️ Project

Minimal ERC20 implementation

Custom mint/burn logic

📘 Concepts Learned

ERC20 lifecycle

Testing allowances, approvals, and transfers

Common ERC20 vulnerabilities

🧪 Testing Coverage

Allowance inflation tests

Transfer edge-case tests

Fuzzed mint/burn flows

🛡️ Security Lessons

Approve/transferFrom requires careful design

Token accounting must be exact

Attackers often target allowance manipulation

🧰 Tools Mastered

forge test --gas-report

Profiling gas for token functions

📝 Notes

ERC20 tokens are simple but easy to get wrong—security requires precision.

Week 06 — ERC721 + Permit + Anti-MEV Techniques
🏗️ Project

NFT with permit

Anti-front-running mint design

📘 Concepts Learned

NFT metadata flow

Signature-based authorization

Basic MEV mitigation patterns

🧪 Testing Coverage

Signature validity tests

Replay prevention

Permit event testing

🛡️ Security Lessons

MEV is not an abstract threat—it's real

Permit signatures reduce trust assumptions

NFT mints require strict replay protection

🧰 Tools Mastered

ECDSA utilities

vm.sign cheatcode

📝 Notes

Strong week for improving trust-minimized mint mechanics.

Week 07 — Flash Loan Simulator (Anvil Fork Testing)
🏗️ Project

Recreated Aave-style flash loan vault

Tested behavior on forked mainnet

📘 Concepts Learned

Fork testing with Anvil

Simulating real-world liquidity pools

Atomic loan execution

🧪 Testing Coverage

Fork-based invariants

Liquidity checks

Flash loan repayment validation

🛡️ Security Lessons

Flash loans reveal hidden assumptions

Always assert the final state of liquidity

🧰 Tools Mastered

anvil --fork-url <RPC>

Fork-state manipulation

📝 Notes

Fork testing brings realism—best way to validate protocol assumptions.

Week 08 — Simple AMM + Sandwich Attack Simulation
🏗️ Project

Constant product AMM (x·y = k)

Basic MEV attack reproduction

📘 Concepts Learned

Swap curves

Slippage calculations

Front-run / back-run modeling

🧪 Testing Coverage

Swap path tests

MEV ordering simulations

Price impact tests

🛡️ Security Lessons

AMMs require careful slippage design

MEV is inevitable—design to reduce harm

🧰 Tools Mastered

Block manipulation via vm.roll

Simulation of attacker + victim flows

📝 Notes

Understanding AMMs at the test level helps grasp modern DEX design.

Future Weeks

Time-lock vaults

DAO governance

Oracle manipulation

Reentrancy simulations

On-chain randomness abuse

Multisig wallet design

Cross-chain bridging fundamentals
