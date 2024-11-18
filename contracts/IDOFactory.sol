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

	// Mapping variable for manage block list
	mapping(address => bool) private blockList;

	// This event is emitted when a new IDO (Initial DEX Offering) is created
	event IDOCreated(
		address indexed owner,
		address idoPool,
		address rewardToken
	);

	// This event is emitted when added or removed block accounts
	event addedToBlock(address account);
	event removedFromBlock(address account);

	// The constructor takes an initial owner address and initializes the Ownable contract
	constructor(address initialOwner) Ownable(initialOwner) {}

	/**
	 * @dev Add to block list
	 * @param account The address of the will-blocked user
	 */
	function addToBlock(address account) external onlyOwner {
		blockList[account] = true;

		emit addedToBlock(account);
	}

	/**
	 * @dev Remove from the block list
	 * @param account The address of the will-unblocked user
	 */
	function removeFromBlock(address account) external onlyOwner {
		blockList[account] = false;

		emit removedFromBlock(account);
	}

	/**
	 * @dev Creates a new IDO contract
	 * @param tokenInfo The token information for the IDO
	 * @param timestamp The timestamp information for the IDO
	 * @param dexInfo The DEX information for the IDO
	 */
	function createIDO(
		FeeInfo memory feeInfo,
		IDOPool.TokenInfo memory tokenInfo,
		IDOPool.Timestamps memory timestamp,
		IDOPool.DEXInfo memory dexInfo,
		string memory metadataUrl
	) external {
		require(blockList[msg.sender] == false, "Account is in the block list");

		// Deploy a new FeeToken contract with the provided parameters
		FeeToken feeToken = new FeeToken(
			feeInfo.feeName,
			feeInfo.feeSymbol,
			feeInfo.feeSupply
		);

		// Set the new created feeToken to the new pool's reward token
		tokenInfo.rewardToken = feeToken;

		// Deploy a new IDOP001 contract with the provided parameters
		IDOPool idoPool = new IDOPool(msg.sender, tokenInfo, timestamp, dexInfo, metadataUrl);

		IERC20(feeToken).transfer(address(idoPool), feeInfo.feeSupply);

		// Emit the IDOCreated event with the necessary information
		emit IDOCreated(
			msg.sender,
			address(idoPool),
			address(tokenInfo.rewardToken)
		);
	}
}
