// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import necessary contracts and interfaces
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IDOPool } from "./IDOPool.sol";
import { FeeToken } from "./FeeToken.sol";

contract IDOFactory is Ownable {
	struct FeeInfo {
		string feeName;
		string feeSymbol;
		uint256 feeSupply;
	}

	// The constructor takes an initial owner address and initializes the Ownable contract
	constructor(address initialOwner) Ownable(initialOwner) {}

	// This event is emitted when a new IDO (Initial DEX Offering) is created
	event IDOCreated(
		address indexed owner,
		address idoPool,
		address rewardToken
	);

	/**
	 * @dev Creates a new IDO contract
	 * @param poolOwner The address of the pool owner
	 * @param tokenInfo The token information for the IDO
	 * @param timestamp The timestamp information for the IDO
	 * @param dexInfo The DEX information for the IDO
	 */
	function createIDO(
		address poolOwner,
		FeeInfo memory feeInfo,
		IDOPool.TokenInfo memory tokenInfo,
		IDOPool.Timestamps memory timestamp,
		IDOPool.DEXInfo memory dexInfo
	) external onlyOwner {
		// Deploy a new FeeToken contract with the provided parameters
		FeeToken feeToken = new FeeToken(
			feeInfo.feeName,
			feeInfo.feeSymbol,
			feeInfo.feeSupply
		);

		// Set the new created feeToken to the new pool's reward token
		tokenInfo.rewardToken = feeToken;

		// Deploy a new IDOP001 contract with the provided parameters
		IDOPool idoPool = new IDOPool(poolOwner, tokenInfo, timestamp, dexInfo);

		IERC20(feeToken).transfer(address(idoPool), feeInfo.feeSupply);

		// Emit the IDOCreated event with the necessary information
		emit IDOCreated(
			poolOwner,
			address(idoPool),
			address(tokenInfo.rewardToken)
		);
	}
}
