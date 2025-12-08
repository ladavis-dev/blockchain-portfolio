# Week 5: Fixtures, Snapshots & Gas Reporting

## 🎯 Learning Objectives

- Design reusable test fixtures with `setUp()`
- Use `vm.snapshot()` and `vm.revertTo()` for state management
- Generate and analyze gas reports
- Optimize gas consumption
- Create modular test helpers

## 📚 Concepts Covered

### Snapshot & Revert

```solidity
// Take a snapshot of current state
uint256 snapshotId = vm.snapshot();

// ... perform operations ...

// Revert to snapshot
vm.revertTo(snapshotId);
// State is now restored to when snapshot was taken
```

### Gas Reporting

```bash
# Run tests with gas report
forge test --gas-report

# Output shows per-function gas usage:
# | Function    | min  | avg  | median | max  | # calls |
# |-------------|------|------|--------|------|---------|
# | vote        | 2034 | 2534 | 2534   | 3034 | 100     |
```

### Advanced Fixtures

```solidity
contract VotingTest is Test {
    // Shared state
    Voting public voting;
    address[] public voters;
    
    // Base setup
    function setUp() public {
        voting = new Voting();
        _createVoters(10);
    }
    
    // Reusable helper
    function _createVoters(uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            voters.push(makeAddr(string(abi.encodePacked("voter", i))));
        }
    }
    
    // Fixture modifier
    modifier withProposal() {
        voting.createProposal("Test Proposal");
        _;
    }
    
    // Use fixture
    function testVote() public withProposal {
        voting.vote(0, true);
    }
}
```

## 🔧 Contract: Voting.sol

A governance voting system demonstrating:
- Proposal creation and management
- Vote delegation
- Quorum requirements
- Voting periods with time constraints
- Vote weight calculations

## 🧪 Tests Demonstrated

| Test | Technique | Purpose |
|------|-----------|---------|
| `testCreateProposal` | Base `setUp` | Fixture usage |
| `testMultipleScenarios` | `vm.snapshot` | State branching |
| `testGasOptimization` | `--gas-report` | Gas measurement |
| `testDelegation` | Helper functions | Complex setup |
| `testQuorum` | Snapshot revert | Reset between tests |

## 📝 Key Learnings

### 1. Effective Fixture Design

```solidity
contract BaseTest is Test {
    // Common state
    Voting voting;
    address admin;
    address[] voters;
    
    function setUp() public virtual {
        admin = makeAddr("admin");
        voting = new Voting(admin);
        _setupVoters();
    }
    
    function _setupVoters() internal {
        for (uint i = 0; i < 5; i++) {
            voters.push(makeAddr(string.concat("voter", vm.toString(i))));
            vm.deal(voters[i], 1 ether);
        }
    }
}

// Inherit and extend
contract ProposalTest is BaseTest {
    uint256 proposalId;
    
    function setUp() public override {
        super.setUp();
        proposalId = _createTestProposal();
    }
}
```

### 2. Snapshot for Branching Tests

```solidity
function testVotingScenarios() public {
    voting.createProposal("Proposal 1");
    
    // Take snapshot before voting
    uint256 beforeVoting = vm.snapshot();
    
    // Scenario 1: All vote yes
    _everyoneVotesYes();
    assertTrue(voting.isPassed(0));
    
    // Revert and try different scenario
    vm.revertTo(beforeVoting);
    
    // Scenario 2: All vote no
    _everyoneVotesNo();
    assertFalse(voting.isPassed(0));
}
```

### 3. Gas Optimization Testing

```solidity
function testGasComparison() public {
    // Method 1
    uint256 gasBefore = gasleft();
    voting.voteBasic(0, true);
    uint256 gasMethod1 = gasBefore - gasleft();
    
    // Reset
    vm.revertTo(snapshot);
    
    // Method 2
    gasBefore = gasleft();
    voting.voteOptimized(0, true);
    uint256 gasMethod2 = gasBefore - gasleft();
    
    console2.log("Basic:", gasMethod1);
    console2.log("Optimized:", gasMethod2);
    assertLt(gasMethod2, gasMethod1);
}
```

### 4. Modular Test Helpers

```solidity
// In test file
function _registerAllVoters() internal {
    for (uint i = 0; i < voters.length; i++) {
        vm.prank(admin);
        voting.registerVoter(voters[i], 100);
    }
}

function _submitVotes(bool[] memory votes) internal {
    for (uint i = 0; i < votes.length; i++) {
        vm.prank(voters[i]);
        voting.vote(0, votes[i]);
    }
}
```

## 🚀 Running This Week's Project

```bash
cd week-05-voting

# Compile
forge build

# Run tests with gas report
forge test --gas-report

# Run tests with detailed gas per test
forge test -vvv --gas-report

# Run specific test with gas focus
forge test --match-test testGas --gas-report

# Snapshot gas for comparison
forge snapshot

# Compare against previous snapshot
forge snapshot --check
```

## ✅ Checklist

- [ ] Implemented Voting.sol with governance logic
- [ ] Created reusable test fixtures
- [ ] Used vm.snapshot for state management
- [ ] Generated and analyzed gas reports
- [ ] Created helper functions for complex setups
- [ ] Tested edge cases with snapshots
- [ ] All tests passing with optimal gas
