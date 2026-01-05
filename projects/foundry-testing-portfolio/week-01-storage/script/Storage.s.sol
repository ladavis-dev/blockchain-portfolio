// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {Storage} from "../src/Storage.sol";

/// @title StorageScript
/// @notice Deployment script for Storage.sol
/// @dev Run with: forge script script/Storage.s.sol --rpc-url <RPC_URL> --broadcast
contract StorageScript is Script {
    function setUp() public {}

    function run() public {
        // Get private key from environment or use default anvil key
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("=== Storage Deployment Script ===");
        console2.log("Deployer address:", deployer);
        console2.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy Storage contract
        Storage storageContract = new Storage();
        
        console2.log("Storage deployed at:", address(storageContract));
        
        // Verify deployment
        console2.log("Initial value:", storageContract.retrieve());
        console2.log("Owner:", storageContract.owner());
        
        // Store initial value as verification
        storageContract.store(42);
        console2.log("Stored initial value: 42");
        console2.log("Retrieved value:", storageContract.retrieve());
        
        vm.stopBroadcast();
        
        console2.log("=== Deployment Complete ===");
    }
}

/// @title StorageInteractionScript
/// @notice Script for interacting with deployed Storage contract
contract StorageInteractionScript is Script {
    function run() public {
        // Contract address (update after deployment)
        address storageAddress = vm.envAddress("STORAGE_ADDRESS");
        
        uint256 privateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        
        Storage storageContract = Storage(storageAddress);
        
        console2.log("=== Storage Interaction Script ===");
        console2.log("Contract address:", storageAddress);
        console2.log("Current value:", storageContract.retrieve());
        
        vm.startBroadcast(privateKey);
        
        // Increment value
        storageContract.increment();
        console2.log("After increment:", storageContract.retrieve());
        
        // Store new value
        storageContract.store(100);
        console2.log("After store(100):", storageContract.retrieve());
        
        vm.stopBroadcast();
    }
}
