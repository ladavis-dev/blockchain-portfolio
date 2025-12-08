// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Counter
/// @author Your Name
/// @notice Advanced counter for learning assertions and state validation
/// @dev Demonstrates bounds checking, step counting, and mathematical operations
contract Counter {
    // ============ State Variables ============
    
    uint256 public count;
    uint256 public step;
    uint256 public maxCount;
    uint256 public minCount;
    address public owner;
    
    uint256[] public history;
    mapping(address => uint256) public incrementsByUser;
    
    uint256 public constant PRECISION = 1e18;
    
    // ============ Events ============
    
    event CountChanged(uint256 indexed oldValue, uint256 indexed newValue, address indexed by);
    event StepChanged(uint256 oldStep, uint256 newStep);
    event BoundsChanged(uint256 newMin, uint256 newMax);
    event CounterReset(address by);
    
    // ============ Errors ============
    
    error ExceedsMaxCount(uint256 attempted, uint256 max);
    error BelowMinCount(uint256 attempted, uint256 min);
    error InvalidStep();
    error InvalidBounds();
    error NotOwner();
    error Overflow();
    
    // ============ Modifiers ============
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    // ============ Constructor ============
    
    constructor(uint256 _initialCount, uint256 _step, uint256 _min, uint256 _max) {
        require(_min <= _initialCount && _initialCount <= _max, "Invalid initial count");
        require(_step > 0, "Step must be positive");
        
        owner = msg.sender;
        count = _initialCount;
        step = _step;
        minCount = _min;
        maxCount = _max;
        
        history.push(_initialCount);
    }
    
    // ============ Core Functions ============
    
    /// @notice Increment counter by step amount
    function increment() external {
        uint256 newCount = count + step;
        
        if (newCount > maxCount) {
            revert ExceedsMaxCount(newCount, maxCount);
        }
        
        uint256 oldCount = count;
        count = newCount;
        history.push(newCount);
        incrementsByUser[msg.sender]++;
        
        emit CountChanged(oldCount, newCount, msg.sender);
    }
    
    /// @notice Increment by a specific amount
    /// @param _amount Amount to increment by
    function incrementBy(uint256 _amount) external {
        if (_amount == 0) revert InvalidStep();
        
        uint256 newCount = count + _amount;
        
        if (newCount > maxCount) {
            revert ExceedsMaxCount(newCount, maxCount);
        }
        if (newCount < count) {
            revert Overflow(); // Overflow check
        }
        
        uint256 oldCount = count;
        count = newCount;
        history.push(newCount);
        incrementsByUser[msg.sender]++;
        
        emit CountChanged(oldCount, newCount, msg.sender);
    }
    
    /// @notice Decrement counter by step amount
    function decrement() external {
        if (count < step + minCount) {
            revert BelowMinCount(count - step, minCount);
        }
        
        uint256 oldCount = count;
        count = oldCount - step;
        history.push(count);
        
        emit CountChanged(oldCount, count, msg.sender);
    }
    
    /// @notice Decrement by a specific amount
    /// @param _amount Amount to decrement by
    function decrementBy(uint256 _amount) external {
        if (_amount == 0) revert InvalidStep();
        
        if (count < _amount + minCount) {
            revert BelowMinCount(count - _amount, minCount);
        }
        
        uint256 oldCount = count;
        count = oldCount - _amount;
        history.push(count);
        
        emit CountChanged(oldCount, count, msg.sender);
    }
    
    // ============ Owner Functions ============
    
    /// @notice Set the step value
    /// @param _newStep New step value
    function setStep(uint256 _newStep) external onlyOwner {
        if (_newStep == 0) revert InvalidStep();
        
        uint256 oldStep = step;
        step = _newStep;
        
        emit StepChanged(oldStep, _newStep);
    }
    
    /// @notice Set the min and max bounds
    /// @param _newMin New minimum value
    /// @param _newMax New maximum value
    function setBounds(uint256 _newMin, uint256 _newMax) external onlyOwner {
        if (_newMin > _newMax) revert InvalidBounds();
        if (count < _newMin || count > _newMax) revert InvalidBounds();
        
        minCount = _newMin;
        maxCount = _newMax;
        
        emit BoundsChanged(_newMin, _newMax);
    }
    
    /// @notice Reset counter to minimum value
    function reset() external onlyOwner {
        uint256 oldCount = count;
        count = minCount;
        history.push(count);
        
        emit CountChanged(oldCount, count, msg.sender);
        emit CounterReset(msg.sender);
    }
    
    /// @notice Set counter to specific value (owner only)
    /// @param _value Value to set
    function setCount(uint256 _value) external onlyOwner {
        if (_value < minCount) revert BelowMinCount(_value, minCount);
        if (_value > maxCount) revert ExceedsMaxCount(_value, maxCount);
        
        uint256 oldCount = count;
        count = _value;
        history.push(_value);
        
        emit CountChanged(oldCount, _value, msg.sender);
    }
    
    // ============ View Functions ============
    
    /// @notice Get current count as percentage of max
    /// @return Percentage with 18 decimal precision
    function getPercentageOfMax() external view returns (uint256) {
        if (maxCount == 0) return 0;
        return (count * PRECISION) / maxCount;
    }
    
    /// @notice Get remaining capacity until max
    /// @return Remaining count until max
    function getRemainingCapacity() external view returns (uint256) {
        return maxCount - count;
    }
    
    /// @notice Get how many increments until max (at current step)
    /// @return Number of increments possible
    function getIncrementsUntilMax() external view returns (uint256) {
        uint256 remaining = maxCount - count;
        return remaining / step;
    }
    
    /// @notice Get full history of count changes
    /// @return Array of historical values
    function getHistory() external view returns (uint256[] memory) {
        return history;
    }
    
    /// @notice Get history length
    /// @return Number of entries in history
    function getHistoryLength() external view returns (uint256) {
        return history.length;
    }
    
    /// @notice Check if counter is at max
    /// @return True if count equals maxCount
    function isAtMax() external view returns (bool) {
        return count == maxCount;
    }
    
    /// @notice Check if counter is at min
    /// @return True if count equals minCount
    function isAtMin() external view returns (bool) {
        return count == minCount;
    }
    
    /// @notice Calculate average value from history
    /// @return Average with 18 decimal precision
    function getAverageValue() external view returns (uint256) {
        if (history.length == 0) return 0;
        
        uint256 sum = 0;
        for (uint256 i = 0; i < history.length; i++) {
            sum += history[i];
        }
        
        return (sum * PRECISION) / history.length;
    }
}
