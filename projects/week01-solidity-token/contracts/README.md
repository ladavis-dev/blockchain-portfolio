# Week 01 – ERC20 Token: HelloToken

## 📌 Overview
This project demonstrates a basic **ERC20 token** implementation using Solidity and the OpenZeppelin library.  
The token is named **HelloToken (HTK)** and mints an initial supply of tokens to the deployer’s address.

This is the first project in my **Blockchain Security Engineer Portfolio**, designed to showcase Solidity development fundamentals and best practices.

---

## ⚙️ Tech Stack
- **Solidity** ^0.8.0
- **Hardhat** (compile, test, deploy)
- **OpenZeppelin Contracts** (ERC20 implementation)
- **Mocha/Chai** for testing

---

## 📝 Contract
File: [`projects/week01-solidity-token/contracts/HelloToken.sol`](projects/week01-solidity-token/contracts/HelloToken.sol)
    
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract HelloToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("HelloToken", "HTK") {
        _mint(msg.sender, initialSupply);
    }
}
