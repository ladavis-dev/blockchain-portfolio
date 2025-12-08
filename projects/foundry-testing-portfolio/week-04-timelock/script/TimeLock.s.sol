// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/TimeLock.sol";

contract TimeLockScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        
        console2.log("=== TimeLock Deployment ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        TimeLock timeLock = new TimeLock(
            1 days,    // min lock
            365 days   // max lock
        );
        
        console2.log("TimeLock deployed at:", address(timeLock));
        console2.log("Min lock duration:", timeLock.minLockDuration());
        console2.log("Max lock duration:", timeLock.maxLockDuration());
        
        vm.stopBroadcast();
    }
}
