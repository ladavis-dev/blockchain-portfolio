// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/Voting.sol";

contract VotingScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("=== Voting Deployment ===");
        
        vm.startBroadcast(deployerPrivateKey);
        
        Voting voting = new Voting(
            deployer,  // admin
            50,        // 50% quorum
            7 days     // voting period
        );
        
        console2.log("Voting deployed at:", address(voting));
        console2.log("Admin:", voting.admin());
        console2.log("Quorum:", voting.quorumPercentage(), "%");
        
        // Register deployer as voter
        voting.registerVoter(deployer, 100);
        console2.log("Deployer registered with weight 100");
        
        vm.stopBroadcast();
    }
}
