// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {Storage} from "../src/Storage.sol";

contract StorageTest is Test {
    Storage public storageContract;
    address public owner;
    address public alice;
    address public bob;

    event ValueStored(uint256 indexed oldValue, uint256 indexed newValue, address updatedBy);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");

        storageContract = new Storage();

        console2.log("=== Test Setup Complete ===");
        console2.log("Owner address:", owner);
        console2.log("Storage deployed at:", address(storageContract));
    }

    function testInitialValueIsZero() public view {
        uint256 value = storageContract.retrieve();
        assertEq(value, 0, "Initial value should be 0");
    }

    function testOwnerIsDeployer() public view {
        assertEq(storageContract.owner(), owner, "Owner should be deployer");
    }

    function testStore() public {
        storageContract.store(42);
        assertEq(storageContract.retrieve(), 42, "Stored value mismatch");
    }

    function testMultipleStores() public {
        uint256[] memory values =  new uint256[](3);
        values[0] = 10;
        values[1] = 20;
        values[2] = 30;

        for (uint256 i = 0; i < values.length; i++) {
            storageContract.store(values[i]);
            uint256 retrieved = storageContract.retrieve();
            assertEq(retrieved, values[i], "Value mismatch in sequential store");
        }
    }

    function testStoreEmitsEvent() public {
        uint256 newValue = 100;

        vm.expectEmit(true, true, false, true);
        emit ValueStored(0, newValue, address(this));

        storageContract.store(newValue);
    }

    function testCannotStoreSameValue() public {
        storageContract.store(50);
        vm.expectRevert(Storage.SameValue.selector);
        storageContract.store(50);
    }

    function testOwnerCanOwnerStore() public {
        storageContract.ownerStore(999);
        assertEq(storageContract.retrieve(), 999, "Owner store failed");
    }

    function testNonOwnerCannotOwnerStore() public {
        vm.prank(alice);
        vm.expectRevert(Storage.NotOwner.selector);
        storageContract.ownerStore(123);
    }

    function testTransferOwnership() public {
        vm.expectEmit(true, true, false, true);
        emit OwnershipTransferred(owner, alice);

        storageContract.transferOwnership(alice);
        assertEq(storageContract.owner(), alice, "Ownership not transferred");
    }

    function testCannotTransferToZeroAddress() public {
        vm.expectRevert(Storage.InvalidAddress.selector);
        storageContract.transferOwnership(address(0));
    }

    function testIncrement() public {
        storageContract.store(5);
        storageContract.increment();
        assertEq(storageContract.retrieve(), 6, "Increment failed");
    }

    function testMultipleIncrements() public {
        for (uint256 i = 0; i < 5; i++) storageContract.increment();
        assertEq(storageContract.retrieve(), 5, "Multiple increments failed");
    }

    function testDecrement() public {
        storageContract.store(10);
        storageContract.decrement();
        assertEq(storageContract.retrieve(), 9, "Decrement failed");
    }

    function testCannotDecrementBelowZero() public {
        vm.expectRevert(Storage.CannotDecrementBelowZero.selector);
        storageContract.decrement();
    }

    function testStoreMaxUint() public {
        uint256 maxValue = type(uint256).max;
        storageContract.store(maxValue);
        assertEq(storageContract.retrieve(), maxValue, "Max uint storage failed");
    }

    function testStoreBoundaryValue() public {
        storageContract.store(1);
        assertEq(storageContract.retrieve(), 1, "Boundary value 1 failed");
        storageContract.decrement();
        assertEq(storageContract.retrieve(), 0, "Decrement to 0 failed");
    }
}
