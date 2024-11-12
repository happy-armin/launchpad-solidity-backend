//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FeeToken is ERC20 {
    uint256 initial_supply; // Stores the initial supply of the token

    // Constructor function to initialize the token
    constructor(
        string memory name, // Token name
        string memory symbol, // Token symbol
        uint256 _initial_supply // Initial supply of the token
    ) ERC20(name, symbol) {
        // Set the initial supply
        initial_supply = _initial_supply;

        // Mint the initial supply to the contract deployer
        _mint(msg.sender, initial_supply);
    }
}
