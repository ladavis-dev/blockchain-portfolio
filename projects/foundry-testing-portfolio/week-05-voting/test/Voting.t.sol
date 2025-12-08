// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/Voting.sol";

/// @title VotingTest
/// @notice Comprehensive test suite for fixtures, snapshots, and gas optimization
/// @dev Focus: setUp patterns, vm.snapshot, vm.revertTo, gas-report
contract VotingTest is Test {
    // ============ State Variables ============
    
    Voting public voting;
    address public admin;
    address[] public voters;
    
    uint256 constant VOTER_COUNT = 5;
    uint256 constant DEFAULT_WEIGHT = 100;
    uint256 constant QUORUM = 50; // 50%
    uint256 constant VOTING_PERIOD = 7 days;
    
    // ============ Events ============
    
    event ProposalCreated(uint256 indexed proposalId, address indexed proposer, string description, uint256 startTime, uint256 endTime);
    event VoteCast(address indexed voter, uint256 indexed proposalId, bool support, uint256 weight);
    event VoterRegistered(address indexed voter, uint256 weight);
    
    // ============ Setup - Base Fixture ============
    
    function setUp() public {
        admin = makeAddr("admin");
        
        // Deploy voting contract
        voting = new Voting(admin, QUORUM, VOTING_PERIOD);
        
        // Create and register voters
        _createVoters(VOTER_COUNT);
        _registerAllVoters();
        
        console2.log("=== Voting Test Setup ===");
        console2.log("Admin:", admin);
        console2.log("Voters registered:", VOTER_COUNT);
        console2.log("Total weight:", voting.totalRegisteredWeight());
    }
    
    // ============ Helper Functions (Fixtures) ============
    
    /// @notice Create voter addresses
    function _createVoters(uint256 count) internal {
        for (uint256 i = 0; i < count; i++) {
            string memory label = string(abi.encodePacked("voter", vm.toString(i)));
            voters.push(makeAddr(label));
            vm.deal(voters[i], 1 ether);
        }
    }
    
    /// @notice Register all voters with admin
    function _registerAllVoters() internal {
        vm.startPrank(admin);
        for (uint256 i = 0; i < voters.length; i++) {
            voting.registerVoter(voters[i], DEFAULT_WEIGHT);
        }
        vm.stopPrank();
    }
    
    /// @notice Create a test proposal from first voter
    function _createTestProposal() internal returns (uint256) {
        vm.prank(voters[0]);
        return voting.createProposal("Test Proposal");
    }
    
    /// @notice Have all voters vote yes
    function _allVoteYes(uint256 proposalId) internal {
        for (uint256 i = 0; i < voters.length; i++) {
            vm.prank(voters[i]);
            voting.vote(proposalId, true);
        }
    }
    
    /// @notice Have all voters vote no
    function _allVoteNo(uint256 proposalId) internal {
        for (uint256 i = 0; i < voters.length; i++) {
            vm.prank(voters[i]);
            voting.vote(proposalId, false);
        }
    }
    
    /// @notice Have half vote yes, half vote no
    function _splitVote(uint256 proposalId) internal {
        for (uint256 i = 0; i < voters.length; i++) {
            vm.prank(voters[i]);
            voting.vote(proposalId, i % 2 == 0);
        }
    }
    
    // ============ Basic Fixture Tests ============
    
    /// @notice Test setup fixture is working
    function testSetupFixture() public view {
        assertEq(voting.admin(), admin);
        assertEq(voting.quorumPercentage(), QUORUM);
        assertEq(voting.totalRegisteredWeight(), VOTER_COUNT * DEFAULT_WEIGHT);
        
        for (uint256 i = 0; i < voters.length; i++) {
            assertEq(voting.getVoterWeight(voters[i]), DEFAULT_WEIGHT);
        }
    }
    
    /// @notice Test proposal creation
    function testCreateProposal() public {
        uint256 proposalId = _createTestProposal();
        
        assertEq(proposalId, 0);
        assertEq(voting.getProposalCount(), 1);
    }
    
    // ============ Snapshot Tests ============
    
    /// @notice Test different voting outcomes using snapshots
    function testVotingOutcomesWithSnapshots() public {
        uint256 proposalId = _createTestProposal();
        
        // Take snapshot before any voting
        uint256 beforeVoting = vm.snapshot();
        
        // Scenario 1: All vote YES
        console2.log("=== Scenario 1: All YES ===");
        _allVoteYes(proposalId);
        
        (,,uint256 forVotes1, uint256 againstVotes1,,,,) = _getProposalData(proposalId);
        assertEq(forVotes1, VOTER_COUNT * DEFAULT_WEIGHT);
        assertEq(againstVotes1, 0);
        assertTrue(voting.isPassed(proposalId));
        console2.log("For votes:", forVotes1);
        console2.log("Passed:", voting.isPassed(proposalId));
        
        // Revert to before voting
        vm.revertTo(beforeVoting);
        
        // Scenario 2: All vote NO
        console2.log("=== Scenario 2: All NO ===");
        _allVoteNo(proposalId);
        
        (,,uint256 forVotes2, uint256 againstVotes2,,,,) = _getProposalData(proposalId);
        assertEq(forVotes2, 0);
        assertEq(againstVotes2, VOTER_COUNT * DEFAULT_WEIGHT);
        assertFalse(voting.isPassed(proposalId));
        console2.log("Against votes:", againstVotes2);
        console2.log("Passed:", voting.isPassed(proposalId));
        
        // Revert again
        vm.revertTo(beforeVoting);
        
        // Scenario 3: Split vote
        console2.log("=== Scenario 3: Split Vote ===");
        _splitVote(proposalId);
        
        (,,uint256 forVotes3, uint256 againstVotes3,,,,) = _getProposalData(proposalId);
        console2.log("For votes:", forVotes3);
        console2.log("Against votes:", againstVotes3);
    }
    
    /// @notice Test multiple proposals with snapshots
    function testMultipleProposalsWithSnapshots() public {
        // Create first proposal
        uint256 proposal1 = _createTestProposal();
        
        uint256 afterFirstProposal = vm.snapshot();
        
        // Vote on first proposal
        _allVoteYes(proposal1);
        
        // Create second proposal
        vm.prank(voters[1]);
        uint256 proposal2 = voting.createProposal("Second Proposal");
        
        assertEq(voting.getProposalCount(), 2);
        
        // Revert to after first proposal creation
        vm.revertTo(afterFirstProposal);
        
        // Now only first proposal exists
        assertEq(voting.getProposalCount(), 1);
        
        // And no votes have been cast
        assertFalse(voting.hasVoted(voters[0], proposal1));
    }
    
    // ============ Gas Optimization Tests ============
    
    /// @notice Compare gas for single vs batch registration
    function testGasBatchVsSingleRegistration() public {
        // Create new voting contract for clean comparison
        Voting votingNew = new Voting(admin, QUORUM, VOTING_PERIOD);
        
        address[] memory newVoters = new address[](10);
        uint256[] memory weights = new uint256[](10);
        
        for (uint256 i = 0; i < 10; i++) {
            newVoters[i] = makeAddr(string(abi.encodePacked("newVoter", vm.toString(i))));
            weights[i] = 100;
        }
        
        // Take snapshot
        uint256 beforeReg = vm.snapshot();
        
        // Method 1: Single registration
        uint256 gasBefore = gasleft();
        vm.startPrank(admin);
        for (uint256 i = 0; i < 10; i++) {
            votingNew.registerVoter(newVoters[i], weights[i]);
        }
        vm.stopPrank();
        uint256 singleGas = gasBefore - gasleft();
        
        // Revert
        vm.revertTo(beforeReg);
        
        // Method 2: Batch registration
        gasBefore = gasleft();
        vm.prank(admin);
        votingNew.registerVotersBatch(newVoters, weights);
        uint256 batchGas = gasBefore - gasleft();
        
        console2.log("=== Gas Comparison ===");
        console2.log("Single registration (10x):", singleGas);
        console2.log("Batch registration:", batchGas);
        console2.log("Gas saved:", singleGas - batchGas);
        
        // Batch should be more efficient
        assertLt(batchGas, singleGas, "Batch should use less gas");
    }
    
    /// @notice Measure voting gas consumption
    function testGasVoting() public {
        uint256 proposalId = _createTestProposal();
        
        uint256 gasBefore = gasleft();
        vm.prank(voters[0]);
        voting.vote(proposalId, true);
        uint256 gasUsed = gasBefore - gasleft();
        
        console2.log("Gas for single vote:", gasUsed);
        
        // Vote should be reasonably efficient
        assertLt(gasUsed, 100000, "Voting should use less than 100k gas");
    }
    
    /// @notice Track gas across all voters
    function testGasAllVotersVoting() public {
        uint256 proposalId = _createTestProposal();
        
        uint256[] memory gasUsed = new uint256[](voters.length);
        
        for (uint256 i = 0; i < voters.length; i++) {
            uint256 gasBefore = gasleft();
            vm.prank(voters[i]);
            voting.vote(proposalId, true);
            gasUsed[i] = gasBefore - gasleft();
        }
        
        console2.log("=== Gas per voter ===");
        uint256 total = 0;
        for (uint256 i = 0; i < voters.length; i++) {
            console2.log("Voter", i, ":", gasUsed[i]);
            total += gasUsed[i];
        }
        console2.log("Average gas:", total / voters.length);
    }
    
    // ============ Complex Scenario Tests ============
    
    /// @notice Test full proposal lifecycle
    function testProposalLifecycle() public {
        // Create proposal
        uint256 proposalId = _createTestProposal();
        assertTrue(voting.isVotingActive(proposalId));
        
        // All voters vote yes
        _allVoteYes(proposalId);
        
        // Try to execute while voting active - should fail
        vm.expectRevert(Voting.VotingStillActive.selector);
        voting.executeProposal(proposalId);
        
        // Fast forward past voting period
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        
        // Now execute should work
        voting.executeProposal(proposalId);
        
        (,,,,,, bool executed,) = _getProposalData(proposalId);
        assertTrue(executed);
    }
    
    /// @notice Test quorum requirements with snapshots
    function testQuorumScenarios() public {
        uint256 proposalId = _createTestProposal();
        uint256 beforeVoting = vm.snapshot();
        
        // Scenario 1: Exactly at quorum (50% = 2.5 voters, need 3)
        console2.log("=== Quorum Test ===");
        console2.log("Quorum required:", voting.getQuorumVotes());
        
        // Only 2 voters vote (40% of weight) - below quorum
        vm.prank(voters[0]);
        voting.vote(proposalId, true);
        vm.prank(voters[1]);
        voting.vote(proposalId, true);
        
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        
        // Should fail quorum
        vm.expectRevert(Voting.QuorumNotReached.selector);
        voting.executeProposal(proposalId);
        
        // Revert and try with enough voters
        vm.revertTo(beforeVoting);
        
        // 3 voters (60% of weight) - above quorum
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(voters[i]);
            voting.vote(proposalId, true);
        }
        
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        
        // Should succeed
        voting.executeProposal(proposalId);
    }
    
    /// @notice Test delegation
    function testDelegation() public {
        // Voter 0 delegates to voter 1
        vm.prank(voters[0]);
        voting.delegate(voters[1]);
        
        // Create and vote
        uint256 proposalId = _createTestProposal();
        
        // Both can still vote (simplified - real impl would transfer power)
        vm.prank(voters[0]);
        voting.vote(proposalId, true);
        
        vm.prank(voters[1]);
        voting.vote(proposalId, true);
    }
    
    // ============ Event Tests ============
    
    /// @notice Test events are emitted correctly
    function testEventsEmitted() public {
        // Test ProposalCreated event
        vm.expectEmit(true, true, false, true);
        emit ProposalCreated(0, voters[0], "Test Proposal", block.timestamp, block.timestamp + VOTING_PERIOD);
        
        vm.prank(voters[0]);
        voting.createProposal("Test Proposal");
        
        // Test VoteCast event
        vm.expectEmit(true, true, false, true);
        emit VoteCast(voters[1], 0, true, DEFAULT_WEIGHT);
        
        vm.prank(voters[1]);
        voting.vote(0, true);
    }
    
    // ============ Helper ============
    
    function _getProposalData(uint256 proposalId) internal view returns (
        uint256 id,
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 startTime,
        uint256 endTime,
        bool executed,
        address proposer
    ) {
        (description, forVotes, againstVotes, startTime, endTime, executed, proposer) = 
            voting.getProposal(proposalId);
        id = proposalId;
    }
}

/// @title VotingGasTest
/// @notice Dedicated gas measurement tests
contract VotingGasTest is Test {
    Voting public voting;
    address public admin;
    address[] public voters;
    
    function setUp() public {
        admin = makeAddr("admin");
        voting = new Voting(admin, 50, 7 days);
        
        // Setup many voters for gas testing
        vm.startPrank(admin);
        for (uint256 i = 0; i < 50; i++) {
            address voter = makeAddr(string(abi.encodePacked("v", vm.toString(i))));
            voters.push(voter);
            voting.registerVoter(voter, 100);
        }
        vm.stopPrank();
    }
    
    /// @notice Benchmark proposal creation gas
    function testGasProposalCreation() public {
        vm.prank(voters[0]);
        voting.createProposal("Benchmark proposal with a reasonably long description for testing");
    }
    
    /// @notice Benchmark voting gas
    function testGasVote() public {
        vm.prank(voters[0]);
        voting.createProposal("Test");
        
        vm.prank(voters[1]);
        voting.vote(0, true);
    }
    
    /// @notice Benchmark batch registration
    function testGasBatchRegistration() public {
        Voting newVoting = new Voting(admin, 50, 7 days);
        
        address[] memory newVoters = new address[](20);
        uint256[] memory weights = new uint256[](20);
        
        for (uint256 i = 0; i < 20; i++) {
            newVoters[i] = makeAddr(string(abi.encodePacked("new", vm.toString(i))));
            weights[i] = 100;
        }
        
        vm.prank(admin);
        newVoting.registerVotersBatch(newVoters, weights);
    }
}
