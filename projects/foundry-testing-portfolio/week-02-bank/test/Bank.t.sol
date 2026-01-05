// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Bank} from "../src/Bank.sol";

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

    /// @notice Allow this test contract (owner) to receive ETH.
    /// @dev Fixes emergencyWithdraw failing with TransferFailed().
    receive() external payable {}

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

    function testDeposit() public {
        uint256 depositAmount = 1 ether;

        vm.prank(alice);
        bank.deposit{value: depositAmount}();

        assertEq(bank.balances(alice), depositAmount);
        assertEq(address(bank).balance, depositAmount);

        console2.log("Alice deposited:", depositAmount);
        console2.log("Alice bank balance:", bank.balances(alice));
    }

    function testDepositEmitsEvent() public {
        uint256 depositAmount = 2 ether;

        vm.expectEmit(true, false, false, true);
        emit Deposit(alice, depositAmount, depositAmount);

        vm.prank(alice);
        bank.deposit{value: depositAmount}();
    }

    function testMultipleDeposits() public {
        vm.startPrank(alice);

        bank.deposit{value: 1 ether}();
        bank.deposit{value: 2 ether}();
        bank.deposit{value: 0.5 ether}();

        vm.stopPrank();

        assertEq(bank.balances(alice), 3.5 ether);
        console2.log("Alice total deposits:", bank.balances(alice));
    }

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

    function testCannotDepositZero() public {
        vm.prank(alice);
        vm.expectRevert(Bank.ZeroAmount.selector);
        bank.deposit{value: 0}();
    }

    // ============ Withdrawal Tests ============

    function testWithdraw() public {
        vm.startPrank(alice);
        bank.deposit{value: 5 ether}();

        uint256 balanceBefore = alice.balance;

        bank.withdraw(2.5 ether);

        vm.stopPrank();

        assertEq(bank.balances(alice), 2.5 ether);
        assertEq(alice.balance, balanceBefore + 2.5 ether);

        console2.log("Alice withdrew 2.5 ether");
        console2.log("Alice remaining bank balance:", bank.balances(alice));
    }

    function testWithdrawEmitsEvent() public {
        vm.prank(alice);
        bank.deposit{value: 3 ether}();

        vm.expectEmit(true, false, false, true);
        emit Withdrawal(alice, 1 ether, 2 ether);

        vm.prank(alice);
        bank.withdraw(1 ether);
    }

    function testWithdrawAll() public {
        vm.startPrank(alice);
        bank.deposit{value: 10 ether}();

        uint256 balanceBefore = alice.balance;
        bank.withdrawAll();

        vm.stopPrank();

        assertEq(bank.balances(alice), 0);
        assertEq(alice.balance, balanceBefore + 10 ether);
    }

    function testCannotWithdrawMoreThanBalance() public {
        vm.prank(alice);
        bank.deposit{value: 1 ether}();

        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Bank.InsufficientBalance.selector, 2 ether, 1 ether)
        );
        bank.withdraw(2 ether);
    }

    function testCannotWithdrawWithZeroBalance() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Bank.InsufficientBalance.selector, 1 ether, 0)
        );
        bank.withdraw(1 ether);
    }

    function testCannotWithdrawAllWithZeroBalance() public {
        vm.prank(alice);
        vm.expectRevert(
            abi.encodeWithSelector(Bank.InsufficientBalance.selector, 1, 0)
        );
        bank.withdrawAll();
    }

    // ============ Owner Functions Tests ============

    function testEmergencyWithdraw() public {
        vm.prank(alice);
        bank.deposit{value: 5 ether}();

        vm.prank(bob);
        bank.deposit{value: 3 ether}();

        uint256 ownerBalanceBefore = owner.balance;
        uint256 contractBalance = address(bank).balance;

        bank.emergencyWithdraw();

        assertEq(address(bank).balance, 0);
        assertEq(owner.balance, ownerBalanceBefore + contractBalance);

        console2.log("Owner emergency withdrew:", contractBalance);
    }

    function testNonOwnerCannotEmergencyWithdraw() public {
        vm.prank(alice);
        bank.deposit{value: 5 ether}();

        vm.prank(alice);
        vm.expectRevert(Bank.NotOwner.selector);
        bank.emergencyWithdraw();
    }

    function testTransferOwnership() public {
        bank.transferOwnership(alice);
        assertEq(bank.owner(), alice);

        vm.prank(bob);
        bank.deposit{value: 1 ether}();

        vm.prank(alice);
        bank.emergencyWithdraw();

        assertEq(address(bank).balance, 0);
    }

    // ============ Receive & Fallback Tests ============

    function testReceiveEth() public {
        vm.prank(alice);
        (bool success, ) = address(bank).call{value: 1 ether}("");

        assertTrue(success);
        assertEq(bank.balances(alice), 1 ether);
    }

    function testFallbackWithData() public {
        vm.prank(alice);
        (bool success, ) = address(bank).call{value: 1 ether}("random data");

        assertTrue(success);
        assertEq(bank.balances(alice), 1 ether);
    }

    // ============ View Functions Tests ============

    function testGetBalance() public {
        vm.prank(alice);
        bank.deposit{value: 5 ether}();

        assertEq(bank.getBalance(alice), 5 ether);
        assertEq(bank.getBalance(bob), 0);
    }

    function testGetContractBalance() public {
        vm.prank(alice);
        bank.deposit{value: 5 ether}();

        vm.prank(bob);
        bank.deposit{value: 3 ether}();

        assertEq(bank.getContractBalance(), 8 ether);
    }

    // ============ Reentrancy Tests ============

    function testReentrancyProtection() public {
        ReentrancyAttacker attacker = new ReentrancyAttacker(address(bank));
        vm.deal(address(attacker), 10 ether);

        attacker.deposit{value: 1 ether}();

        vm.prank(alice);
        bank.deposit{value: 5 ether}();

        // Run the attack; it should NOT revert, but it should detect the guard blocking reentry.
        attacker.attack();

        assertTrue(attacker.reentryBlocked(), "Expected reentry to be blocked by ReentrancyGuard");
        assertEq(address(bank).balance, 5 ether, "Attacker should not drain Alice's deposit");

        console2.log("Reentrancy attempt was blocked (guard triggered)");
    }
}

/// @title ReentrancyAttacker
/// @notice Malicious contract attempting reentrancy attack
contract ReentrancyAttacker {
    Bank public bank;
    uint256 public attackCount;
    bool public reentryBlocked;

    constructor(address _bank) {
        bank = Bank(payable(_bank));
    }

    function deposit() external payable {
        bank.deposit{value: msg.value}();
    }

    function attack() external {
        // Initiate a withdrawal which triggers receive() below.
        bank.withdraw(1 ether);
    }

    receive() external payable {
        attackCount++;

        // Attempt reentry via low-level call so we can observe the revert selector
        // WITHOUT reverting this receive(), otherwise the Bank sees a failed transfer (TransferFailed).
        (bool ok, bytes memory data) = address(bank).call(
            abi.encodeWithSignature("withdraw(uint256)", 1 ether)
        );

        if (!ok && data.length >= 4) {
            bytes4 sel;
            assembly {
                sel := mload(add(data, 0x20))
            }
            if (sel == Bank.ReentrancyGuard.selector) {
                reentryBlocked = true;
            }
        }
    }
}

