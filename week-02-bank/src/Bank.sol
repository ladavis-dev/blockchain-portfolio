// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Bank
/// @author Your Name
/// @notice A simple ETH bank for learning transactions and signers
/// @dev Demonstrates payable functions, balance tracking, and reentrancy protection
contract Bank {
    // ============ State Variables ============
    
    mapping(address => uint256) public balances;
    address public owner;
    bool private locked;
    uint256 public totalDeposits;
    
    // ============ Events ============
    
    event Deposit(address indexed depositor, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed withdrawer, uint256 amount, uint256 newBalance);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    
    // ============ Errors ============
    
    error InsufficientBalance(uint256 requested, uint256 available);
    error TransferFailed();
    error NotOwner();
    error ReentrancyGuard();
    error ZeroAmount();
    
    // ============ Modifiers ============
    
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }
    
    modifier nonReentrant() {
        if (locked) revert ReentrancyGuard();
        locked = true;
        _;
        locked = false;
    }
    
    modifier validAmount() {
        if (msg.value == 0) revert ZeroAmount();
        _;
    }
    
    // ============ Constructor ============
    
    constructor() {
        owner = msg.sender;
    }
    
    // ============ External Functions ============
    
    /// @notice Deposit ETH into the bank
    function deposit() external payable validAmount {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }
    
    /// @notice Withdraw ETH from the bank
    /// @param _amount Amount of ETH to withdraw (in wei)
    function withdraw(uint256 _amount) external nonReentrant {
        uint256 userBalance = balances[msg.sender];
        
        if (_amount > userBalance) {
            revert InsufficientBalance(_amount, userBalance);
        }
        
        // Update state BEFORE external call (checks-effects-interactions)
        balances[msg.sender] = userBalance - _amount;
        totalDeposits -= _amount;
        
        // External call
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) revert TransferFailed();
        
        emit Withdrawal(msg.sender, _amount, balances[msg.sender]);
    }
    
    /// @notice Withdraw all user's balance
    function withdrawAll() external nonReentrant {
        uint256 userBalance = balances[msg.sender];
        
        if (userBalance == 0) {
            revert InsufficientBalance(1, 0);
        }
        
        balances[msg.sender] = 0;
        totalDeposits -= userBalance;
        
        (bool success, ) = payable(msg.sender).call{value: userBalance}("");
        if (!success) revert TransferFailed();
        
        emit Withdrawal(msg.sender, userBalance, 0);
    }
    
    /// @notice Emergency withdrawal for owner (drains entire contract)
    /// @dev Only callable by owner, for emergency situations
    function emergencyWithdraw() external onlyOwner nonReentrant {
        uint256 contractBalance = address(this).balance;
        
        // Reset all state
        totalDeposits = 0;
        
        (bool success, ) = payable(owner).call{value: contractBalance}("");
        if (!success) revert TransferFailed();
        
        emit EmergencyWithdrawal(owner, contractBalance);
    }
    
    /// @notice Transfer ownership to a new address
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid address");
        owner = newOwner;
    }
    
    // ============ View Functions ============
    
    /// @notice Get balance of a specific address
    /// @param _account The address to check
    /// @return The balance of the address
    function getBalance(address _account) external view returns (uint256) {
        return balances[_account];
    }
    
    /// @notice Get the contract's total ETH balance
    /// @return The contract's balance
    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    // ============ Receive & Fallback ============
    
    /// @notice Receive ETH directly (treated as deposit)
    receive() external payable {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }
    
    /// @notice Fallback for calls with data but no matching function
    fallback() external payable {
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
        emit Deposit(msg.sender, msg.value, balances[msg.sender]);
    }
}
