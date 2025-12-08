// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console2.sol";
import "../src/Storage.sol";

/// @title StorageTest
/// @notice Comprehensive test suite for Storage.sol
/// @dev Demonstrates Foundry testing basics: setUp, assertions, console logging
contract StorageTest is Test {
    // ============ State Variables ============
    
    Storage public storageContract;
    address public owner;
    address public alice;
    address public bob;
    
    // ============ Events (must redeclare for testing) ============
    
    event ValueStored(uint256 indexed oldValue, uint256 indexed newValue, address updatedBy);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // ============ Setup ============
    
    /// @notice Runs before each test function
    /// @dev This is where we deploy fresh contract instances
    function setUp() public {
        // Create test addresses
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        
        // Deploy fresh Storage contract for each test
        storageContract = new Storage();
        
        // Debug output - shows in verbose mode (-vvv)
        console2.log("=== Test Setup Complete ===");
        console2.log("Owner address:", owner);
        console2.log("Storage deployed at:", address(storageContract));
    }
    
    // ============ Initialization Tests ============
    
    /// @notice Test that initial value is zero
    function testInitialValueIsZero() public view {
        uint256 value = storageContract.retrieve();
        console2.log("Initial value:", value);
        assertEq(value, 0, "Initial value should be 0");
    }
    
    /// @notice Test that owner is set correctly
    function testOwnerIsDeployer() public view {
        address contractOwner = storageContract.owner();
        console2.log("Contract owner:", contractOwner);
        console2.log("Expected owner:", owner);
        assertEq(contractOwner, owner, "Owner should be deployer");
    }
    
    // ============ Store Function Tests ============
    
    /// @notice Test basic store and retrieve
    function testStore() public {
        uint256 valueToStore = 42;
        
        console2.log("Storing value:", valueToStore);
        storageContract.store(valueToStore);
        
        uint256 retrievedValue = storageContract.retrieve();
        console2.log("Retrieved value:", retrievedValue);
        
        assertEq(retrievedValue, valueToStore, "Retrieved value should match stored value");
    }
    
    /// @notice Test storing multiple values sequentially
    function testMultipleStores() public {
        uint256[] memory values = new uint256[](3);
        values[0] = 10;
        values[1] = 20;
        values[2] = 30;
        
        for (uint256 i = 0; i < values.length; i++) {
            storageContract.store(values[i]);
            uint256 retrieved = storageContract.retrieve();
            
            console2.log("Iteration", i);
            console2.log("  Stored:", values[i]);
            console2.log("  Retrieved:", retrieved);
            
            assertEq(retrieved, values[i], "Value mismatch in sequential store");
        }
    }
    
    /// @notice Test store emits ValueStored event
    function testStoreEmitsEvent() public {
        uint256 newValue = 100;
        
        // We expect an event with these parameters
        // The first two are indexed (topics), third is not
        vm.expectEmit(true, true, false, true);
        emit ValueStored(0, newValue, address(this));
        
        storageContract.store(newValue);
        console2.log("Event emitted for value:", newValue);
    }
    
    /// @notice Test storing same value reverts
    function testCannotStoreSameValue() public {
        storageContract.store(50);
        
        // Expect custom error
        vm.expectRevert(Storage.SameValue.selector);
        storageContract.store(50);
        
        console2.log("Correctly reverted on same value");
    }
    
    // ============ Owner Functions Tests ============
    
    /// @notice Test owner can use ownerStore
    function testOwnerCanOwnerStore() public {
        uint256 value = 999;
        storageContract.ownerStore(value);
        
        assertEq(storageContract.retrieve(), value, "Owner store failed");
        console2.log("Owner successfully stored:", value);
    }
    
    /// @notice Test non-owner cannot use ownerStore
    function testNonOwnerCannotOwnerStore() public {
        // Impersonate alice
        vm.prank(alice);
        
        vm.expectRevert(Storage.NotOwner.selector);
        storageContract.ownerStore(123);
        
        console2.log("Non-owner correctly blocked from ownerStore");
    }
    
    /// @notice Test ownership transfer
    function testTransferOwnership() public {
        console2.log("Current owner:", storageContract.owner());
        
        // Expect the event
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(owner, alice);
        
        storageContract.transferOwnership(alice);
        
        console2.log("New owner:", storageContract.owner());
        assertEq(storageContract.owner(), alice, "Ownership not transferred");
    }
    
    /// @notice Test cannot transfer ownership to zero address
    function testCannotTransferToZeroAddress() public {
        vm.expectRevert("Invalid address");
        storageContract.transferOwnership(address(0));
    }
    
    // ============ Increment/Decrement Tests ============
    
    /// @notice Test increment function
    function testIncrement() public {
        storageContract.store(5);
        storageContract.increment();
        
        assertEq(storageContract.retrieve(), 6, "Increment failed");
        console2.log("Incremented from 5 to 6");
    }
    
    /// @notice Test multiple increments
    function testMultipleIncrements() public {
        for (uint256 i = 0; i < 5; i++) {
            storageContract.increment();
        }
        
        assertEq(storageContract.retrieve(), 5, "Multiple increments failed");
        console2.log("Incremented 5 times from 0 to 5");
    }
    
    /// @notice Test decrement function
    function testDecrement() public {
        storageContract.store(10);
        storageContract.decrement();
        
        assertEq(storageContract.retrieve(), 9, "Decrement failed");
        console2.log("Decremented from 10 to 9");
    }
    
    /// @notice Test cannot decrement below zero
    function testCannotDecrementBelowZero() public {
        // Value starts at 0
        vm.expectRevert("Cannot decrement below zero");
        storageContract.decrement();
        
        console2.log("Correctly prevented underflow");
    }
    
    // ============ Edge Case Tests ============
    
    /// @notice Test storing max uint256
    function testStoreMaxUint() public {
        uint256 maxValue = type(uint256).max;
        console2.log("Storing max uint256");
        
        storageContract.store(maxValue);
        assertEq(storageContract.retrieve(), maxValue, "Max uint storage failed");
    }
    
    /// @notice Test storing 1 (boundary test)
    function testStoreBoundaryValue() public {
        storageContract.store(1);
        assertEq(storageContract.retrieve(), 1, "Boundary value 1 failed");
        
        // Now test decrement back to 0
        storageContract.decrement();
        assertEq(storageContract.retrieve(), 0, "Decrement to 0 failed");
    }
}
