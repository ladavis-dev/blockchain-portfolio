// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/Counter.sol";

/// @title CounterScript
/// @notice Deployment script for Counter.sol
contract CounterScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        
        console2.log("=== Counter Deployment ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        Counter counter = new Counter(
            50,   // initial count
            5,    // step
            0,    // min
            100   // max
        );
        
        console2.log("Counter deployed at:", address(counter));
        console2.log("Initial count:", counter.count());
        
        // Demonstrate some operations
        counter.increment();
        console2.log("After increment:", counter.count());
        
        counter.incrementBy(10);
        console2.log("After incrementBy(10):", counter.count());
        
        console2.log("Percentage of max:", counter.getPercentageOfMax());
        console2.log("Remaining capacity:", counter.getRemainingCapacity());
        
        vm.stopBroadcast();
    }
}
