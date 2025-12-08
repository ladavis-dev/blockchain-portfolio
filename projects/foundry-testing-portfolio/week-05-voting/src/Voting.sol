// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Voting
/// @author Your Name
/// @notice A governance voting system for learning fixtures and gas optimization
/// @dev Demonstrates complex state management and gas-efficient patterns
contract Voting {
    // ============ Structs ============
    
    struct Proposal {
        uint256 id;
        string description;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 startTime;
        uint256 endTime;
        bool executed;
        address proposer;
    }
    
    struct Voter {
        uint256 weight;
        bool registered;
        address delegate;
        mapping(uint256 => bool) hasVoted;
    }
    
    // ============ State Variables ============
    
    mapping(address => Voter) public voters;
    Proposal[] public proposals;
    
    address public admin;
    uint256 public quorumPercentage;
    uint256 public votingPeriod;
    uint256 public totalRegisteredWeight;
    
    uint256 public constant MIN_VOTING_PERIOD = 1 days;
    uint256 public constant MAX_VOTING_PERIOD = 30 days;
    
    // ============ Events ============
    
    event ProposalCreated(
        uint256 indexed proposalId,
        address indexed proposer,
        string description,
        uint256 startTime,
        uint256 endTime
    );
    
    event VoteCast(
        address indexed voter,
        uint256 indexed proposalId,
        bool support,
        uint256 weight
    );
    
    event VoterRegistered(address indexed voter, uint256 weight);
    event DelegateChanged(address indexed voter, address indexed newDelegate);
    event ProposalExecuted(uint256 indexed proposalId);
    event QuorumUpdated(uint256 oldQuorum, uint256 newQuorum);
    
    // ============ Errors ============
    
    error NotAdmin();
    error NotRegistered();
    error AlreadyRegistered();
    error AlreadyVoted();
    error VotingNotActive();
    error VotingStillActive();
    error ProposalNotFound();
    error AlreadyExecuted();
    error QuorumNotReached();
    error InvalidVotingPeriod();
    error CannotDelegateToSelf();
    error InvalidWeight();
    
    // ============ Modifiers ============
    
    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }
    
    modifier onlyRegistered() {
        if (!voters[msg.sender].registered) revert NotRegistered();
        _;
    }
    
    // ============ Constructor ============
    
    constructor(address _admin, uint256 _quorumPercentage, uint256 _votingPeriod) {
        require(_quorumPercentage <= 100, "Invalid quorum");
        require(_votingPeriod >= MIN_VOTING_PERIOD && _votingPeriod <= MAX_VOTING_PERIOD, "Invalid period");
        
        admin = _admin;
        quorumPercentage = _quorumPercentage;
        votingPeriod = _votingPeriod;
    }
    
    // ============ Admin Functions ============
    
    /// @notice Register a voter with voting weight
    function registerVoter(address _voter, uint256 _weight) external onlyAdmin {
        if (voters[_voter].registered) revert AlreadyRegistered();
        if (_weight == 0) revert InvalidWeight();
        
        voters[_voter].weight = _weight;
        voters[_voter].registered = true;
        totalRegisteredWeight += _weight;
        
        emit VoterRegistered(_voter, _weight);
    }
    
    /// @notice Register multiple voters at once (gas optimized)
    function registerVotersBatch(address[] calldata _voters, uint256[] calldata _weights) external onlyAdmin {
        require(_voters.length == _weights.length, "Length mismatch");
        
        uint256 addedWeight = 0;
        
        for (uint256 i = 0; i < _voters.length; i++) {
            if (!voters[_voters[i]].registered && _weights[i] > 0) {
                voters[_voters[i]].weight = _weights[i];
                voters[_voters[i]].registered = true;
                addedWeight += _weights[i];
                
                emit VoterRegistered(_voters[i], _weights[i]);
            }
        }
        
        totalRegisteredWeight += addedWeight;
    }
    
    /// @notice Update quorum percentage
    function setQuorum(uint256 _newQuorum) external onlyAdmin {
        require(_newQuorum <= 100, "Invalid quorum");
        
        uint256 oldQuorum = quorumPercentage;
        quorumPercentage = _newQuorum;
        
        emit QuorumUpdated(oldQuorum, _newQuorum);
    }
    
    // ============ Voter Functions ============
    
    /// @notice Create a new proposal
    function createProposal(string calldata _description) external onlyRegistered returns (uint256) {
        uint256 proposalId = proposals.length;
        
        proposals.push(Proposal({
            id: proposalId,
            description: _description,
            forVotes: 0,
            againstVotes: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + votingPeriod,
            executed: false,
            proposer: msg.sender
        }));
        
        emit ProposalCreated(
            proposalId,
            msg.sender,
            _description,
            block.timestamp,
            block.timestamp + votingPeriod
        );
        
        return proposalId;
    }
    
    /// @notice Cast a vote on a proposal
    function vote(uint256 _proposalId, bool _support) external onlyRegistered {
        if (_proposalId >= proposals.length) revert ProposalNotFound();
        
        Proposal storage proposal = proposals[_proposalId];
        Voter storage voter = voters[msg.sender];
        
        if (block.timestamp < proposal.startTime || block.timestamp > proposal.endTime) {
            revert VotingNotActive();
        }
        
        if (voter.hasVoted[_proposalId]) revert AlreadyVoted();
        
        uint256 weight = _getVotingPower(msg.sender);
        voter.hasVoted[_proposalId] = true;
        
        if (_support) {
            proposal.forVotes += weight;
        } else {
            proposal.againstVotes += weight;
        }
        
        emit VoteCast(msg.sender, _proposalId, _support, weight);
    }
    
    /// @notice Delegate voting power to another address
    function delegate(address _to) external onlyRegistered {
        if (_to == msg.sender) revert CannotDelegateToSelf();
        if (!voters[_to].registered && _to != address(0)) revert NotRegistered();
        
        voters[msg.sender].delegate = _to;
        
        emit DelegateChanged(msg.sender, _to);
    }
    
    /// @notice Execute a passed proposal
    function executeProposal(uint256 _proposalId) external {
        if (_proposalId >= proposals.length) revert ProposalNotFound();
        
        Proposal storage proposal = proposals[_proposalId];
        
        if (block.timestamp <= proposal.endTime) revert VotingStillActive();
        if (proposal.executed) revert AlreadyExecuted();
        if (!_quorumReached(_proposalId)) revert QuorumNotReached();
        
        proposal.executed = true;
        
        // In real implementation, this would execute the proposal logic
        
        emit ProposalExecuted(_proposalId);
    }
    
    // ============ View Functions ============
    
    /// @notice Get voting power including delegations
    function _getVotingPower(address _voter) internal view returns (uint256) {
        uint256 power = voters[_voter].weight;
        
        // Add delegated power (simplified - doesn't handle chains)
        // In production, you'd track this more carefully
        
        return power;
    }
    
    /// @notice Check if quorum is reached
    function _quorumReached(uint256 _proposalId) internal view returns (bool) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 totalVotes = proposal.forVotes + proposal.againstVotes;
        uint256 requiredVotes = (totalRegisteredWeight * quorumPercentage) / 100;
        
        return totalVotes >= requiredVotes;
    }
    
    /// @notice Get proposal details
    function getProposal(uint256 _proposalId) external view returns (
        string memory description,
        uint256 forVotes,
        uint256 againstVotes,
        uint256 startTime,
        uint256 endTime,
        bool executed,
        address proposer
    ) {
        if (_proposalId >= proposals.length) revert ProposalNotFound();
        
        Proposal storage p = proposals[_proposalId];
        return (
            p.description,
            p.forVotes,
            p.againstVotes,
            p.startTime,
            p.endTime,
            p.executed,
            p.proposer
        );
    }
    
    /// @notice Check if proposal passed
    function isPassed(uint256 _proposalId) external view returns (bool) {
        if (_proposalId >= proposals.length) revert ProposalNotFound();
        
        Proposal storage proposal = proposals[_proposalId];
        
        return proposal.forVotes > proposal.againstVotes && _quorumReached(_proposalId);
    }
    
    /// @notice Get total proposals count
    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }
    
    /// @notice Check if address has voted on proposal
    function hasVoted(address _voter, uint256 _proposalId) external view returns (bool) {
        return voters[_voter].hasVoted[_proposalId];
    }
    
    /// @notice Get voter's weight
    function getVoterWeight(address _voter) external view returns (uint256) {
        return voters[_voter].weight;
    }
    
    /// @notice Check if voting is active for proposal
    function isVotingActive(uint256 _proposalId) external view returns (bool) {
        if (_proposalId >= proposals.length) return false;
        
        Proposal storage proposal = proposals[_proposalId];
        return block.timestamp >= proposal.startTime && block.timestamp <= proposal.endTime;
    }
    
    /// @notice Calculate quorum requirement
    function getQuorumVotes() external view returns (uint256) {
        return (totalRegisteredWeight * quorumPercentage) / 100;
    }
}
