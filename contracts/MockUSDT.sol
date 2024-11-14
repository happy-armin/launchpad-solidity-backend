// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDT is ERC20 {
	// Constructor function to initialize the token
	constructor(uint256 initialSupply) ERC20("Tether USDT", "USDT") {
		// Mint the initial supply to the contract deployer
		_mint(msg.sender, initialSupply);
	}
}
