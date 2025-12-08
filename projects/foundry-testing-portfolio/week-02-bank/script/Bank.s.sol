// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/Bank.sol";

/// @title BankScript
/// @notice Deployment and interaction script for Bank.sol
contract BankScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("=== Bank Deployment Script ===");
        console2.log("Deployer:", deployer);
        console2.log("Deployer balance:", deployer.balance);
        
        vm.startBroadcast(deployerPrivateKey);
        
        Bank bank = new Bank();
        console2.log("Bank deployed at:", address(bank));
        
        // Make initial deposit
        bank.deposit{value: 0.1 ether}();
        console2.log("Initial deposit: 0.1 ETH");
        console2.log("Deployer bank balance:", bank.balances(deployer));
        
        vm.stopBroadcast();
        
        console2.log("=== Deployment Complete ===");
        console2.log("");
        console2.log("To interact with the bank, set:");
        console2.log("export BANK_ADDRESS=", address(bank));
    }
}

/// @title BankInteractionScript
/// @notice Script for common bank interactions
contract BankInteractionScript is Script {
    function run() public {
        address bankAddress = vm.envAddress("BANK_ADDRESS");
        uint256 privateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        
        Bank bank = Bank(payable(bankAddress));
        address user = vm.addr(privateKey);
        
        console2.log("=== Bank Interaction ===");
        console2.log("Bank address:", bankAddress);
        console2.log("User:", user);
        console2.log("User ETH balance:", user.balance);
        console2.log("User bank balance:", bank.balances(user));
        console2.log("Contract total:", bank.getContractBalance());
        
        vm.startBroadcast(privateKey);
        
        // Deposit more
        bank.deposit{value: 0.5 ether}();
        console2.log("Deposited 0.5 ETH");
        
        // Check new balance
        console2.log("New bank balance:", bank.balances(user));
        
        // Withdraw some
        bank.withdraw(0.2 ether);
        console2.log("Withdrew 0.2 ETH");
        console2.log("Final bank balance:", bank.balances(user));
        
        vm.stopBroadcast();
    }
}
