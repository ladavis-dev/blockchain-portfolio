// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/Bank.sol";

/// @title BankTest
/// @notice Comprehensive test suite for Bank.sol
/// @dev Demonstrates vm.deal, vm.prank, and transaction testing
contract BankTest is Test {
    // ============ State Variables ============
    
    Bank public bank;
    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    
    // ============ Events ============
    
    event Deposit(address indexed depositor, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed withdrawer, uint256 amount, uint256 newBalance);
    event EmergencyWithdrawal(address indexed owner, uint256 amount);
    
    // ============ Setup ============
    
    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        
        // Fund test accounts
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(charlie, 100 ether);
        
        // Deploy bank
        bank = new Bank();
        
        console2.log("=== Bank Test Setup ===");
        console2.log("Bank deployed at:", address(bank));
        console2.log("Alice balance:", alice.balance);
    }
    
    // ============ Deposit Tests ============
    
    /// @notice Test basic deposit
    function testDeposit() public {
        uint256 depositAmount = 1 ether;
        
        vm.prank(alice);
        bank.deposit{value: depositAmount}();
        
        assertEq(bank.balances(alice), depositAmount);
        assertEq(address(bank).balance, depositAmount);
        
        console2.log("Alice deposited:", depositAmount);
        console2.log("Alice bank balance:", bank.balances(alice));
    }
    
    /// @notice Test deposit emits event
    function testDepositEmitsEvent() public {
        uint256 depositAmount = 2 ether;
        
        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, depositAmount, depositAmount);
        
        vm.prank(alice);
        bank.deposit{value: depositAmount}();
    }
    
    /// @notice Test multiple deposits from same user
    function testMultipleDeposits() public {
        vm.startPrank(alice);
        
        bank.deposit{value: 1 ether}();
        bank.deposit{value: 2 ether}();
        bank.deposit{value: 0.5 ether}();
        
        vm.stopPrank();
        
        assertEq(bank.balances(alice), 3.5 ether);
        console2.log("Alice total deposits:", bank.balances(alice));
    }
    
    /// @notice Test deposits from multiple users
    function testMultipleUserDeposits() public {
        vm.prank(alice);
        bank.deposit{value: 5 ether}();
        
        vm.prank(bob);
        bank.deposit{value: 3 ether}();
        
        vm.prank(charlie);
        bank.deposit{value: 7 ether}();
        
        assertEq(bank.balances(alice), 5 ether);
        assertEq(bank.balances(bob), 3 ether);
        assertEq(bank.balances(charlie), 7 ether);
        assertEq(bank.totalDeposits(), 15 ether);
        assertEq(address(bank).balance, 15 ether);
        
        console2.log("Total deposits:", bank.totalDeposits());
    }
    
    /// @notice Test zero deposit reverts
    function testCannotDepositZero() public {
        vm.prank(alice);
        vm.expectRevert(Bank.ZeroAmount.selector);
        bank.deposit{value: 0}();
    }
    
    // ============ Withdrawal Tests ============
    
    /// @notice Test basic withdrawal
    function testWithdraw() public {
        // Setup: Alice deposits
        vm.startPrank(alice);
        bank.deposit{value: 5 ether}();
        
        uint256 balanceBefore = alice.balance;
        
        // Withdraw half
        bank.withdraw(2.5 ether);
        
        vm.stopPrank();
        
        assertEq(bank.balances(alice), 2.5 ether);
        assertEq(alice.balance, balanceBefore + 2.5 ether);
        
        console2.log("Alice withdrew 2.5 ether");
        console2.log("Alice remaining bank balance:", bank.balances(alice));
    }
    
    /// @notice Test withdraw emits event
    function testWithdrawEmitsEvent() public {
        vm.prank(alice);
        bank.deposit{value: 3 ether}();
        
        vm.expectEmit(true, false, false, true);
        emit Withdrawal(alice, 1 ether, 2 ether);
        
        vm.prank(alice);
        bank.withdraw(1 ether);
    }
    
    /// @notice Test withdrawAll function
    function testWithdrawAll() public {
        vm.startPrank(alice);
        bank.deposit{value: 10 ether}();
        
        uint256 balanceBefore = alice.balance;
        bank.withdrawAll();
        
        vm.stopPrank();
        
        assertEq(bank.balances(alice), 0);
        assertEq(alice.balance, balanceBefore + 10 ether);
    }
    
    /// @notice Test cannot withdraw more than balance
    function testCannotWithdrawMoreThanBalance() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();
        
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Bank.InsufficientBalance.selector, 2 ether, 1 ether)
        );
        bank.withdraw(2 ether);
    }
    
    /// @notice Test cannot withdraw with zero balance
    function testCannotWithdrawWithZeroBalance() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Bank.InsufficientBalance.selector, 1 ether, 0)
        );
        bank.withdraw(1 ether);
    }
    
    /// @notice Test withdrawAll with zero balance reverts
    function testCannotWithdrawAllWithZeroBalance() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Bank.InsufficientBalance.selector, 1, 0)
        );
        bank.withdrawAll();
    }
    
    // ============ Owner Functions Tests ============
    
    /// @notice Test emergency withdraw by owner
    function testEmergencyWithdraw() public {
        // Users deposit
        vm.prank(alice);
        bank.deposit{value: 5 ether}();
        
        vm.prank(bob);
        bank.deposit{value: 3 ether}();
        
        uint256 ownerBalanceBefore = owner.balance;
        uint256 contractBalance = address(bank).balance;
        
        // Owner emergency withdraws
        bank.emergencyWithdraw();
        
        assertEq(address(bank).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);
        
        console2.log("Owner emergency withdrew:", contractBalance);
    }
    
    /// @notice Test non-owner cannot emergency withdraw
    function testNonOwnerCannotEmergencyWithdraw() public {
        vm.prank(alice);
        bank.deposit{value: 5 ether}();
        
        vm.prank(alice);
        vm.expectRevert(Bank.NotOwner.selector);
        bank.emergencyWithdraw();
    }
    
    /// @notice Test ownership transfer
    function testTransferOwnership() public {
        bank.transferOwnership(alice);
        assertEq(bank.owner(), alice);
        
        // Now alice can emergency withdraw
        vm.prank(bob);
        bank.deposit{value: 1 ether}();
        
        vm.prank(alice);
        bank.emergencyWithdraw();
        
        assertEq(address(bank).balance, 0);
    }
    
    // ============ Receive & Fallback Tests ============
    
    /// @notice Test direct ETH transfer (receive)
    function testReceiveEth() public {
        vm.prank(alice);
        (bool success, ) = address(bank).call{value: 1 ether}("");
        
        assertTrue(success);
        assertEq(bank.balances(alice), 1 ether);
    }
    
    /// @notice Test fallback with data
    function testFallbackWithData() public {
        vm.prank(alice);
        (bool success, ) = address(bank).call{value: 1 ether}("random data");
        
        assertTrue(success);
        assertEq(bank.balances(alice), 1 ether);
    }
    
    // ============ View Functions Tests ============
    
    /// @notice Test getBalance function
    function testGetBalance() public {
        vm.prank(alice);
        bank.deposit{value: 5 ether}();
        
        assertEq(bank.getBalance(alice), 5 ether);
        assertEq(bank.getBalance(bob), 0);
    }
    
    /// @notice Test getContractBalance function
    function testGetContractBalance() public {
        vm.prank(alice);
        bank.deposit{value: 5 ether}();
        
        vm.prank(bob);
        bank.deposit{value: 3 ether}();
        
        assertEq(bank.getContractBalance(), 8 ether);
    }
    
    // ============ Reentrancy Tests ============
    
    /// @notice Test reentrancy protection
    function testReentrancyProtection() public {
        // Deploy attacker
        ReentrancyAttacker attacker = new ReentrancyAttacker(address(bank));
        vm.deal(address(attacker), 10 ether);
        
        // Attacker deposits
        attacker.deposit{value: 1 ether}();
        
        // Add more funds for the attack to try to steal
        vm.prank(alice);
        bank.deposit{value: 5 ether}();
        
        // Attack should fail due to reentrancy guard
        vm.expectRevert(Bank.ReentrancyGuard.selector);
        attacker.attack();
        
        console2.log("Reentrancy attack successfully prevented");
    }
}

/// @title ReentrancyAttacker
/// @notice Malicious contract attempting reentrancy attack
contract ReentrancyAttacker {
    Bank public bank;
    uint256 public attackCount;
    
    constructor(address _bank) {
        bank = Bank(payable(_bank));
    }
    
    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }
    
    function attack() external {
        bank.withdraw(1 ether);
    }
    
    receive() external payable {
        attackCount++;
        if (attackCount < 3 && address(bank).balance >= 1 ether) {
            bank.withdraw(1 ether);
        }
    }
}
