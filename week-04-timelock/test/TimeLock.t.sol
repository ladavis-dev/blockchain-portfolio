// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/TimeLock.sol";

/// @title TimeLockTest
/// @notice Comprehensive test suite for reverts and events
/// @dev Focus: vm.expectRevert, vm.expectEmit, vm.warp, vm.roll
contract TimeLockTest is Test {
    // ============ State Variables ============
    
    TimeLock public timeLock;
    address public owner;
    address public alice;
    address public bob;
    
    uint256 constant MIN_LOCK = 1 days;
    uint256 constant MAX_LOCK = 365 days;
    uint256 constant MIN_DEPOSIT = 0.01 ether;
    
    // ============ Events (must redeclare) ============
    
    event Deposited(
        address indexed user,
        uint256 indexed lockId,
        uint256 amount,
        uint256 unlockTime
    );
    
    event Withdrawn(
        address indexed user,
        uint256 indexed lockId,
        uint256 amount
    );
    
    event EmergencyWithdraw(
        address indexed user,
        uint256 totalAmount,
        uint256 penalty
    );
    
    event BoundsUpdated(uint256 newMinDuration, uint256 newMaxDuration);
    event PauseStateChanged(bool isPaused);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // ============ Setup ============
    
    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        
        timeLock = new TimeLock(MIN_LOCK, MAX_LOCK);
        
        console2.log("=== TimeLock Test Setup ===");
        console2.log("Contract deployed at:", address(timeLock));
        console2.log("Min lock:", MIN_LOCK);
        console2.log("Max lock:", MAX_LOCK);
    }
    
    // ============ Event Tests ============
    
    /// @notice Test Deposited event with all parameters
    function testDepositEmitsEvent() public {
        uint256 depositAmount = 1 ether;
        uint256 lockDuration = 7 days;
        uint256 expectedUnlockTime = block.timestamp + lockDuration;
        
        // Check all indexed parameters and data
        vm.expectEmit(true, true, false, true);
        emit Deposited(alice, 0, depositAmount, expectedUnlockTime);
        
        vm.prank(alice);
        timeLock.deposit{value: depositAmount}(lockDuration);
        
        console2.log("Deposit event verified");
    }
    
    /// @notice Test event with only indexed parameters checked
    function testDepositEventIndexedOnly() public {
        uint256 lockDuration = 7 days;
        
        // Only check indexed: user and lockId
        vm.expectEmit(true, true, false, false);
        emit Deposited(alice, 0, 0, 0); // non-indexed values don't matter
        
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(lockDuration);
    }
    
    /// @notice Test Withdrawn event
    function testWithdrawEmitsEvent() public {
        // Setup: deposit and wait
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(MIN_LOCK);
        
        // Advance time
        vm.warp(block.timestamp + MIN_LOCK + 1);
        
        // Expect withdrawal event
        vm.expectEmit(true, true, false, true);
        emit Withdrawn(alice, 0, 1 ether);
        
        vm.prank(alice);
        timeLock.withdraw(0);
    }
    
    /// @notice Test EmergencyWithdraw event
    function testEmergencyWithdrawEmitsEvent() public {
        uint256 depositAmount = 1 ether;
        uint256 expectedPenalty = depositAmount / 10;
        uint256 expectedPayout = depositAmount - expectedPenalty;
        
        vm.prank(alice);
        timeLock.deposit{value: depositAmount}(30 days);
        
        // Emergency withdraw before unlock
        vm.expectEmit(true, false, false, true);
        emit EmergencyWithdraw(alice, expectedPayout, expectedPenalty);
        
        vm.prank(alice);
        timeLock.emergencyWithdraw(0);
    }
    
    /// @notice Test multiple events in sequence
    function testMultipleDepositsEmitEvents() public {
        // First deposit
        vm.expectEmit(true, true, false, true);
        emit Deposited(alice, 0, 1 ether, block.timestamp + 7 days);
        
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(7 days);
        
        // Second deposit
        vm.expectEmit(true, true, false, true);
        emit Deposited(alice, 1, 2 ether, block.timestamp + 14 days);
        
        vm.prank(alice);
        timeLock.deposit{value: 2 ether}(14 days);
        
        console2.log("Multiple events verified");
    }
    
    /// @notice Test BoundsUpdated event
    function testBoundsUpdateEmitsEvent() public {
        uint256 newMin = 2 days;
        uint256 newMax = 180 days;
        
        vm.expectEmit(false, false, false, true);
        emit BoundsUpdated(newMin, newMax);
        
        timeLock.updateBounds(newMin, newMax);
    }
    
    /// @notice Test OwnershipTransferred event
    function testOwnershipTransferEmitsEvent() public {
        vm.expectEmit(true, true, false, false);
        emit OwnershipTransferred(owner, alice);
        
        timeLock.transferOwnership(alice);
    }
    
    // ============ Revert Tests - Custom Errors ============
    
    /// @notice Test revert with InsufficientDeposit error
    function testCannotDepositBelowMinimum() public {
        uint256 tooSmall = MIN_DEPOSIT - 1;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                TimeLock.InsufficientDeposit.selector,
                tooSmall,
                MIN_DEPOSIT
            )
        );
        
        vm.prank(alice);
        timeLock.deposit{value: tooSmall}(7 days);
    }
    
    /// @notice Test revert with InvalidLockDuration - too short
    function testCannotDepositWithTooShortLock() public {
        uint256 tooShort = MIN_LOCK - 1;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                TimeLock.InvalidLockDuration.selector,
                tooShort,
                MIN_LOCK,
                MAX_LOCK
            )
        );
        
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(tooShort);
    }
    
    /// @notice Test revert with InvalidLockDuration - too long
    function testCannotDepositWithTooLongLock() public {
        uint256 tooLong = MAX_LOCK + 1;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                TimeLock.InvalidLockDuration.selector,
                tooLong,
                MIN_LOCK,
                MAX_LOCK
            )
        );
        
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(tooLong);
    }
    
    /// @notice Test revert with StillLocked error
    function testCannotWithdrawBeforeUnlock() public {
        uint256 lockDuration = 7 days;
        
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(lockDuration);
        
        // Advance time but not enough
        vm.warp(block.timestamp + lockDuration - 1);
        
        uint256 currentTime = block.timestamp;
        uint256 unlockTime = currentTime + 1;
        
        vm.expectRevert(
            abi.encodeWithSelector(
                TimeLock.StillLocked.selector,
                currentTime,
                unlockTime
            )
        );
        
        vm.prank(alice);
        timeLock.withdraw(0);
    }
    
    /// @notice Test revert with LockNotFound error
    function testCannotWithdrawNonexistentLock() public {
        vm.expectRevert(
            abi.encodeWithSelector(TimeLock.LockNotFound.selector, 999)
        );
        
        vm.prank(alice);
        timeLock.withdraw(999);
    }
    
    /// @notice Test revert with AlreadyWithdrawn error
    function testCannotWithdrawTwice() public {
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(MIN_LOCK);
        
        vm.warp(block.timestamp + MIN_LOCK + 1);
        
        vm.prank(alice);
        timeLock.withdraw(0);
        
        vm.expectRevert(
            abi.encodeWithSelector(TimeLock.AlreadyWithdrawn.selector, 0)
        );
        
        vm.prank(alice);
        timeLock.withdraw(0);
    }
    
    /// @notice Test revert with NotOwner error
    function testNonOwnerCannotUpdateBounds() public {
        vm.expectRevert(TimeLock.NotOwner.selector);
        
        vm.prank(alice);
        timeLock.updateBounds(1 days, 30 days);
    }
    
    /// @notice Test revert with ContractPaused error
    function testCannotDepositWhenPaused() public {
        timeLock.setPaused(true);
        
        vm.expectRevert(TimeLock.ContractPaused.selector);
        
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(7 days);
    }
    
    /// @notice Test revert with ZeroAddress error
    function testCannotTransferOwnershipToZero() public {
        vm.expectRevert(TimeLock.ZeroAddress.selector);
        timeLock.transferOwnership(address(0));
    }
    
    /// @notice Test revert with InvalidBounds error
    function testCannotSetInvalidBounds() public {
        // Min >= Max should fail
        vm.expectRevert(TimeLock.InvalidBounds.selector);
        timeLock.updateBounds(30 days, 7 days);
    }
    
    // ============ Time Manipulation Tests ============
    
    /// @notice Test successful withdrawal after unlock time
    function testWithdrawAfterUnlock() public {
        uint256 lockDuration = 7 days;
        uint256 depositAmount = 1 ether;
        
        vm.prank(alice);
        timeLock.deposit{value: depositAmount}(lockDuration);
        
        // Fast forward past unlock time
        vm.warp(block.timestamp + lockDuration + 1);
        
        uint256 balanceBefore = alice.balance;
        
        vm.prank(alice);
        timeLock.withdraw(0);
        
        assertEq(alice.balance, balanceBefore + depositAmount);
        console2.log("Withdrawal successful after time warp");
    }
    
    /// @notice Test exact boundary - withdraw at exact unlock time
    function testWithdrawAtExactUnlockTime() public {
        uint256 lockDuration = 7 days;
        
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(lockDuration);
        
        // Warp to EXACT unlock time
        vm.warp(block.timestamp + lockDuration);
        
        // Should succeed at exact unlock time
        vm.prank(alice);
        timeLock.withdraw(0);
    }
    
    /// @notice Test one second before unlock fails
    function testCannotWithdrawOneSecondEarly() public {
        uint256 lockDuration = 7 days;
        
        vm.prank(alice);
        uint256 lockId = timeLock.deposit{value: 1 ether}(lockDuration);
        
        // Warp to one second before unlock
        uint256 unlockTime = block.timestamp + lockDuration;
        vm.warp(unlockTime - 1);
        
        vm.expectRevert(
            abi.encodeWithSelector(
                TimeLock.StillLocked.selector,
                unlockTime - 1,
                unlockTime
            )
        );
        
        vm.prank(alice);
        timeLock.withdraw(lockId);
    }
    
    /// @notice Test time remaining calculation
    function testTimeRemaining() public {
        uint256 lockDuration = 7 days;
        
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(lockDuration);
        
        // Initially, time remaining should equal lock duration
        assertEq(timeLock.getTimeRemaining(alice, 0), lockDuration);
        
        // After 3 days
        vm.warp(block.timestamp + 3 days);
        assertEq(timeLock.getTimeRemaining(alice, 0), 4 days);
        
        // After full duration
        vm.warp(block.timestamp + 5 days);
        assertEq(timeLock.getTimeRemaining(alice, 0), 0);
    }
    
    /// @notice Test isWithdrawable status changes
    function testIsWithdrawableStatus() public {
        uint256 lockDuration = 7 days;
        
        vm.prank(alice);
        timeLock.deposit{value: 1 ether}(lockDuration);
        
        // Initially not withdrawable
        assertFalse(timeLock.isWithdrawable(alice, 0));
        
        // Still not withdrawable just before unlock
        vm.warp(block.timestamp + lockDuration - 1);
        assertFalse(timeLock.isWithdrawable(alice, 0));
        
        // Withdrawable at unlock time
        vm.warp(block.timestamp + 2);
        assertTrue(timeLock.isWithdrawable(alice, 0));
    }
    
    // ============ Block Number Tests (vm.roll) ============
    
    /// @notice Test block number changes
    function testBlockNumberManipulation() public {
        uint256 initialBlock = block.number;
        
        vm.roll(initialBlock + 100);
        
        assertEq(block.number, initialBlock + 100);
        console2.log("Block advanced from", initialBlock, "to", block.number);
    }
    
    // ============ Integration Tests ============
    
    /// @notice Test full lifecycle with multiple locks
    function testFullLifecycleMultipleLocks() public {
        // Alice creates multiple locks
        vm.startPrank(alice);
        
        timeLock.deposit{value: 1 ether}(7 days);
        timeLock.deposit{value: 2 ether}(14 days);
        timeLock.deposit{value: 3 ether}(30 days);
        
        vm.stopPrank();
        
        assertEq(timeLock.getLockCount(alice), 3);
        assertEq(timeLock.totalLocked(alice), 6 ether);
        
        // Fast forward 7 days - first lock unlocks
        vm.warp(block.timestamp + 7 days);
        
        assertTrue(timeLock.isWithdrawable(alice, 0));
        assertFalse(timeLock.isWithdrawable(alice, 1));
        assertFalse(timeLock.isWithdrawable(alice, 2));
        
        // Withdraw first lock
        vm.prank(alice);
        timeLock.withdraw(0);
        
        assertEq(timeLock.totalLocked(alice), 5 ether);
        
        // Fast forward to 14 days total
        vm.warp(block.timestamp + 7 days);
        
        assertTrue(timeLock.isWithdrawable(alice, 1));
        
        console2.log("Full lifecycle test passed");
    }
    
    /// @notice Test emergency withdraw penalty calculation
    function testEmergencyWithdrawPenalty() public {
        uint256 depositAmount = 10 ether;
        uint256 expectedPenalty = 1 ether;  // 10%
        uint256 expectedPayout = 9 ether;
        
        vm.prank(alice);
        timeLock.deposit{value: depositAmount}(30 days);
        
        uint256 balanceBefore = alice.balance;
        
        vm.prank(alice);
        timeLock.emergencyWithdraw(0);
        
        assertEq(alice.balance, balanceBefore + expectedPayout);
        console2.log("Penalty:", expectedPenalty);
        console2.log("Payout:", expectedPayout);
    }
}
