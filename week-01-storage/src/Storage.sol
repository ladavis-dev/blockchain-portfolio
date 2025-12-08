// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Storage
/// @author Your Name
/// @notice A simple storage contract for learning Foundry basics
/// @dev Demonstrates state variables, events, and basic access control
contract Storage {
    // ============ State Variables ============
    
    uint256 private storedValue;
    address public owner;
    
    // ============ Events ============
    
    /// @notice Emitted when a new value is stored
    /// @param oldValue The previous stored value
    /// @param newValue The new stored value
    /// @param updatedBy Address that performed the update
    event ValueStored(uint256 indexed oldValue, uint256 indexed newValue, address updatedBy);
    
    /// @notice Emitted when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // ============ Errors ============
    
    /// @notice Thrown when a non-owner tries to call owner-only functions
    error NotOwner();
    
    /// @notice Thrown when trying to store the same value
    error SameValue();
    
    // ============ Modifiers ============
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    // ============ Constructor ============
    
    constructor() {
        owner = msg.sender;
        storedValue = 0;
    }
    
    // ============ External Functions ============
    
    /// @notice Store a new value
    /// @param _value The value to store
    function store(uint256 _value) external {
        uint256 oldValue = storedValue;
        if (_value == oldValue) revert SameValue();
        
        storedValue = _value;
        emit ValueStored(oldValue, _value, msg.sender);
    }
    
    /// @notice Retrieve the stored value
    /// @return The currently stored value
    function retrieve() external view returns (uint256) {
        return storedValue;
    }
    
    /// @notice Store a value (owner only)
    /// @param _value The value to store
    function ownerStore(uint256 _value) external onlyOwner {
        uint256 oldValue = storedValue;
        storedValue = _value;
        emit ValueStored(oldValue, _value, msg.sender);
    }
    
    /// @notice Transfer ownership to a new address
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    
    /// @notice Increment the stored value by 1
    function increment() external {
        uint256 oldValue = storedValue;
        storedValue = oldValue + 1;
        emit ValueStored(oldValue, storedValue, msg.sender);
    }
    
    /// @notice Decrement the stored value by 1
    function decrement() external {
        require(storedValue > 0, "Cannot decrement below zero");
        uint256 oldValue = storedValue;
        storedValue = oldValue - 1;
        emit ValueStored(oldValue, storedValue, msg.sender);
    }
}
