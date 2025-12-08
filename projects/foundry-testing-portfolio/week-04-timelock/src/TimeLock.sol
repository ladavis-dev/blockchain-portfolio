// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title TimeLock
/// @author Your Name
/// @notice A time-locked vault for learning revert and event testing
/// @dev Demonstrates time-based access control and comprehensive events
contract TimeLock {
    // ============ Structs ============
    
    struct Lock {
        uint256 amount;
        uint256 unlockTime;
        bool exists;
    }
    
    // ============ State Variables ============
    
    mapping(address => Lock[]) public userLocks;
    mapping(address => uint256) public totalLocked;
    
    address public owner;
    uint256 public minLockDuration;
    uint256 public maxLockDuration;
    bool public paused;
    
    uint256 public constant MIN_DEPOSIT = 0.01 ether;
    
    // ============ Events ============
    
    /// @notice Emitted when a new deposit is locked
    event Deposited(
        address indexed user,
        uint256 indexed lockId,
        uint256 amount,
        uint256 unlockTime
    );
    
    /// @notice Emitted when funds are withdrawn
    event Withdrawn(
        address indexed user,
        uint256 indexed lockId,
        uint256 amount
    );
    
    /// @notice Emitted when emergency withdrawal is used
    event EmergencyWithdraw(
        address indexed user,
        uint256 totalAmount,
        uint256 penalty
    );
    
    /// @notice Emitted when lock duration bounds change
    event BoundsUpdated(
        uint256 newMinDuration,
        uint256 newMaxDuration
    );
    
    /// @notice Emitted when contract is paused/unpaused
    event PauseStateChanged(bool isPaused);
    
    /// @notice Emitted on ownership transfer
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    
    // ============ Errors ============
    
    error NotOwner();
    error ContractPaused();
    error InsufficientDeposit(uint256 sent, uint256 minimum);
    error InvalidLockDuration(uint256 duration, uint256 min, uint256 max);
    error LockNotFound(uint256 lockId);
    error StillLocked(uint256 currentTime, uint256 unlockTime);
    error AlreadyWithdrawn(uint256 lockId);
    error NoLocksExist();
    error TransferFailed();
    error ZeroAddress();
    error InvalidBounds();
    
    // ============ Modifiers ============
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }
    
    // ============ Constructor ============
    
    constructor(uint256 _minLockDuration, uint256 _maxLockDuration) {
        require(_minLockDuration < _maxLockDuration, "Invalid bounds");
        
        owner = msg.sender;
        minLockDuration = _minLockDuration;
        maxLockDuration = _maxLockDuration;
        
        emit OwnershipTransferred(address(0), msg.sender);
    }
    
    // ============ Core Functions ============
    
    /// @notice Deposit ETH with a time lock
    /// @param _lockDuration How long to lock the funds (in seconds)
    /// @return lockId The ID of the created lock
    function deposit(uint256 _lockDuration) external payable whenNotPaused returns (uint256 lockId) {
        if (msg.value < MIN_DEPOSIT) {
            revert InsufficientDeposit(msg.value, MIN_DEPOSIT);
        }
        
        if (_lockDuration < minLockDuration || _lockDuration > maxLockDuration) {
            revert InvalidLockDuration(_lockDuration, minLockDuration, maxLockDuration);
        }
        
        uint256 unlockTime = block.timestamp + _lockDuration;
        
        lockId = userLocks[msg.sender].length;
        
        userLocks[msg.sender].push(Lock({
            amount: msg.value,
            unlockTime: unlockTime,
            exists: true
        }));
        
        totalLocked[msg.sender] += msg.value;
        
        emit Deposited(msg.sender, lockId, msg.value, unlockTime);
    }
    
    /// @notice Withdraw a specific lock after unlock time
    /// @param _lockId The ID of the lock to withdraw
    function withdraw(uint256 _lockId) external whenNotPaused {
        if (_lockId >= userLocks[msg.sender].length) {
            revert LockNotFound(_lockId);
        }
        
        Lock storage userLock = userLocks[msg.sender][_lockId];
        
        if (!userLock.exists) {
            revert AlreadyWithdrawn(_lockId);
        }
        
        if (block.timestamp < userLock.unlockTime) {
            revert StillLocked(block.timestamp, userLock.unlockTime);
        }
        
        uint256 amount = userLock.amount;
        userLock.exists = false;
        userLock.amount = 0;
        totalLocked[msg.sender] -= amount;
        
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
        
        emit Withdrawn(msg.sender, _lockId, amount);
    }
    
    /// @notice Withdraw all unlocked funds
    function withdrawAllUnlocked() external whenNotPaused {
        Lock[] storage locks = userLocks[msg.sender];
        
        if (locks.length == 0) revert NoLocksExist();
        
        uint256 totalToWithdraw = 0;
        
        for (uint256 i = 0; i < locks.length; i++) {
            if (locks[i].exists && block.timestamp >= locks[i].unlockTime) {
                totalToWithdraw += locks[i].amount;
                totalLocked[msg.sender] -= locks[i].amount;
                locks[i].exists = false;
                locks[i].amount = 0;
                
                emit Withdrawn(msg.sender, i, locks[i].amount);
            }
        }
        
        if (totalToWithdraw == 0) revert NoLocksExist();
        
        (bool success, ) = payable(msg.sender).call{value: totalToWithdraw}("");
        if (!success) revert TransferFailed();
    }
    
    /// @notice Emergency withdraw with 10% penalty
    /// @param _lockId The ID of the lock to emergency withdraw
    function emergencyWithdraw(uint256 _lockId) external {
        if (_lockId >= userLocks[msg.sender].length) {
            revert LockNotFound(_lockId);
        }
        
        Lock storage userLock = userLocks[msg.sender][_lockId];
        
        if (!userLock.exists) {
            revert AlreadyWithdrawn(_lockId);
        }
        
        uint256 amount = userLock.amount;
        uint256 penalty = amount / 10; // 10% penalty
        uint256 payout = amount - penalty;
        
        userLock.exists = false;
        userLock.amount = 0;
        totalLocked[msg.sender] -= amount;
        
        // Send payout to user
        (bool success, ) = payable(msg.sender).call{value: payout}("");
        if (!success) revert TransferFailed();
        
        // Penalty stays in contract (goes to owner)
        
        emit EmergencyWithdraw(msg.sender, payout, penalty);
    }
    
    // ============ Owner Functions ============
    
    /// @notice Update lock duration bounds
    function updateBounds(uint256 _newMin, uint256 _newMax) external onlyOwner {
        if (_newMin >= _newMax) revert InvalidBounds();
        
        minLockDuration = _newMin;
        maxLockDuration = _newMax;
        
        emit BoundsUpdated(_newMin, _newMax);
    }
    
    /// @notice Pause/unpause the contract
    function setPaused(bool _paused) external onlyOwner {
        paused = _paused;
        emit PauseStateChanged(_paused);
    }
    
    /// @notice Transfer ownership
    function transferOwnership(address _newOwner) external onlyOwner {
        if (_newOwner == address(0)) revert ZeroAddress();
        
        address oldOwner = owner;
        owner = _newOwner;
        
        emit OwnershipTransferred(oldOwner, _newOwner);
    }
    
    /// @notice Withdraw accumulated penalties
    function withdrawPenalties() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 lockedBalance = 0;
        
        // This is simplified - in production you'd track penalties separately
        (bool success, ) = payable(owner).call{value: contractBalance - lockedBalance}("");
        if (!success) revert TransferFailed();
    }
    
    // ============ View Functions ============
    
    /// @notice Get all locks for a user
    function getUserLocks(address _user) external view returns (Lock[] memory) {
        return userLocks[_user];
    }
    
    /// @notice Get specific lock details
    function getLock(address _user, uint256 _lockId) external view returns (Lock memory) {
        if (_lockId >= userLocks[_user].length) {
            revert LockNotFound(_lockId);
        }
        return userLocks[_user][_lockId];
    }
    
    /// @notice Check if a lock is withdrawable
    function isWithdrawable(address _user, uint256 _lockId) external view returns (bool) {
        if (_lockId >= userLocks[_user].length) return false;
        
        Lock memory userLock = userLocks[_user][_lockId];
        return userLock.exists && block.timestamp >= userLock.unlockTime;
    }
    
    /// @notice Get time remaining until unlock
    function getTimeRemaining(address _user, uint256 _lockId) external view returns (uint256) {
        if (_lockId >= userLocks[_user].length) {
            revert LockNotFound(_lockId);
        }
        
        Lock memory userLock = userLocks[_user][_lockId];
        
        if (!userLock.exists || block.timestamp >= userLock.unlockTime) {
            return 0;
        }
        
        return userLock.unlockTime - block.timestamp;
    }
    
    /// @notice Get number of locks for user
    function getLockCount(address _user) external view returns (uint256) {
        return userLocks[_user].length;
    }
}
