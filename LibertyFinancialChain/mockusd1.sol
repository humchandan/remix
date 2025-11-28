// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSD1 is ERC20 {
    // 1. Initialize with 18 decimals to match BSC standards
    constructor() ERC20("MUSD1", "USD1") {
        // Mint 1 Million tokens to the deployer immediately
        _mint(msg.sender, 1_0000_000 * 10**18);
    }

    // 2. Faucet: Allows anyone to get 1,000 free tokens for testing
    function faucet() external {
        _mint(msg.sender, 1_000 * 10**18);
    }
}