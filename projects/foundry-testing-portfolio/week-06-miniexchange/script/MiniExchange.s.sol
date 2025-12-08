// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/MiniExchange.sol";
import "../src/MockERC20.sol";

contract MiniExchangeScript is Script {
    function run() public {
        uint256 deployerPrivateKey = vm.envOr(
            "PRIVATE_KEY",
            uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80)
        );
        
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("=== MiniExchange Deployment ===");
        console2.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy tokens
        MockERC20 tokenA = new MockERC20("Token A", "TKNA", 18);
        MockERC20 tokenB = new MockERC20("Token B", "TKNB", 18);
        
        console2.log("Token A deployed:", address(tokenA));
        console2.log("Token B deployed:", address(tokenB));
        
        // Deploy exchange
        MiniExchange exchange = new MiniExchange(
            address(tokenA),
            address(tokenB),
            30  // 0.3% fee
        );
        
        console2.log("Exchange deployed:", address(exchange));
        
        // Setup initial liquidity
        uint256 initialLiquidity = 10_000e18;
        tokenA.mint(deployer, initialLiquidity);
        tokenB.mint(deployer, initialLiquidity);
        
        tokenA.approve(address(exchange), initialLiquidity);
        tokenB.approve(address(exchange), initialLiquidity);
        
        exchange.addLiquidity(initialLiquidity, initialLiquidity);
        
        console2.log("Initial liquidity added:", initialLiquidity);
        console2.log("Reserve A:", exchange.reserveA());
        console2.log("Reserve B:", exchange.reserveB());
        console2.log("K value:", exchange.getK());
        
        vm.stopBroadcast();
        
        console2.log("=== Deployment Complete ===");
    }
}
