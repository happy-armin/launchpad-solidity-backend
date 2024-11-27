// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import necessary contracts and interfaces
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IDOPool is Ownable {
	using SafeERC20 for IERC20;

	// Struct to store timestamp-related information for the IDO
	struct Timestamps {
		uint256 startTimestamp; // Start timestamp of the IDO
		uint256 endTimestamp; // End timestamp of the IDO
		uint256 claimTimestamp; // Timestamp when tokens can be claimed
	}

	// Struct to store user-related information for the IDO
	struct UserInfo {
		uint256 stakedAmount; // Amount of tokens staked by the user
		uint256 claimedAmount; // Amount of tokens claimed by the user
		bool hasClaimed; // Flag indicating if the user has claimed their tokens
	}

	// Struct to store DEX-related information for the IDO
	struct DEXInfo {
		address router; // Uniswap V2 Router contract address
		address factory; // Uniswap V2 Factory contract address
	}

	// Struct to store token-related information for the IDO
	struct TokenInfo {
		IERC20 rewardToken; // ERC20 token used as the reward
		uint256 rewardTokenPrice; // Price of the reward token
		IERC20 buyToken; // ERC20 token used for buying the reward token
		uint256 buyTokenSupply; // Total supply of the buy token
		uint256 softCap; // Soft cap for the IDO
		uint256 hardCap; // Hard cap for the IDO
	}

	// Flag indicating if the IDO has been distributed
	bool public distributed = false;

	TokenInfo public tokenInfo; // store the token pool info
	Timestamps public timestamps; // stores the timestamps
	DEXInfo public dexInfo; // stores the DEX info
	string public metadataUrl; // store the avatar url

	// Mapping to store user-related information
	mapping(address => UserInfo) public userInfo;

	event PoolCreated(
		address indexed holder,
		address pool,
		address rewardToken,
		address buyToken,
		uint256 price,
		uint256 softCap,
		uint256 hardCap,
		uint256 startTime,
		uint256 endTime,
		uint256 claimTime,
		string ipfsUrl
	);
	// Events for token staking, refunding, and claiming
	event TokenStake(address indexed holder, address pool, uint256 amount);
	event TokenRefund(address indexed holder, address pool);
	event TokenClaim(address indexed holder, address pool, uint256 amount);

	// Constructor that initializes the contract
	constructor(
		address initialOwner,
		TokenInfo memory _tokenInfo,
		Timestamps memory _timestamps,
		DEXInfo memory _dexInfo,
		string memory _metadataUrl
	) Ownable(initialOwner) {
		tokenInfo = _tokenInfo;
		dexInfo = _dexInfo;
		metadataUrl = _metadataUrl;
		setTimestamps(_timestamps);

		emit PoolCreated(
			owner(),
			address(this),
			address(tokenInfo.rewardToken),
			address(tokenInfo.buyToken),
			tokenInfo.rewardTokenPrice,
			tokenInfo.softCap,
			tokenInfo.hardCap,
			timestamps.startTimestamp,
			timestamps.endTimestamp,
			timestamps.claimTimestamp,
			metadataUrl
		);
	}

	// Function to set the soft cap
	function setSoftCap(uint256 _softCap) external {
		tokenInfo.softCap = _softCap;
	}

	// Function to set the hard cap
	function setHardCap(uint256 _hardCap) external {
		tokenInfo.hardCap = _hardCap;
	}

	// Function to set the timestamps for the IDO
	function setTimestamps(Timestamps memory _timestamp) internal {
		// Require that the start timestamp is greater than the current timestamp
		require(
			_timestamp.startTimestamp > block.timestamp,
			"Start timestamp must be more than current timestamp"
		);
		// Require that the start timestamp is less than the end timestamp
		require(
			_timestamp.startTimestamp < _timestamp.endTimestamp,
			"Start timestamp must be less than end timestamp"
		);
		// Require that the end timestamp is less than the claim timestamp
		require(
			_timestamp.endTimestamp < _timestamp.claimTimestamp,
			"End timestamp must be less than claim timestamp"
		);

		// Set the timestamps
		timestamps = _timestamp;
	}

	function updateTimestamps(Timestamps memory _timestamp) external onlyOwner {
		// Require that the start timestamp is greater than the current timestamp
		require(
			_timestamp.startTimestamp > block.timestamp,
			"Start timestamp must be more than current timestamp"
		);
		// Require that the start timestamp is less than the end timestamp
		require(
			_timestamp.startTimestamp < _timestamp.endTimestamp,
			"Start timestamp must be less than end timestamp"
		);
		// Require that the end timestamp is less than the claim timestamp
		require(
			_timestamp.endTimestamp < _timestamp.claimTimestamp,
			"End timestamp must be less than claim timestamp"
		);

		// Set the timestamps
		timestamps = _timestamp;
	}

	// getter function for getting pool timestamps
	function getTimestamps() external view returns (Timestamps memory) {
		return timestamps;
	}

	// getter function for getting total staked amount for progress of project
	function getTotalStakedAmount() external view returns (uint256) {
		return tokenInfo.buyTokenSupply;
	}

	// Function to allow users to stake their tokens
	function stake(uint256 amount) external {
		// Require that the project has started
		require(
			block.timestamp >= timestamps.startTimestamp,
			"Project not started"
		);

		// Require that the project has not ended
		require(
			block.timestamp < timestamps.endTimestamp,
			"Project already ended"
		);

		// Require that the amount being staked does not exceed the hard cap
		require(
			amount + tokenInfo.buyTokenSupply <= tokenInfo.hardCap,
			"Overfilled"
		);

		// Require that the amount being staked is greater than zero
		require(amount > 0, "Amount must be greater than zero");

		// Transfer the staked tokens from the user to the contract
		tokenInfo.buyToken.safeTransferFrom(msg.sender, address(this), amount);

		// Update the user's staked amount and claim status
		UserInfo storage newUser = userInfo[msg.sender];
		newUser.stakedAmount = newUser.stakedAmount + amount;
		newUser.hasClaimed = false;

		// Update the total buy token supply
		tokenInfo.buyTokenSupply = tokenInfo.buyTokenSupply + amount;

		// Emit the TokenStake event
		emit TokenStake(msg.sender, address(this), amount);
	}

	// Function to allow users to refund their staked tokens
	function refund() external {
		// Require that the project has ended
		require(
			block.timestamp >= timestamps.endTimestamp,
			"Project not ended yet"
		);

		// Require that the project has not succeeded (soft cap not reached)
		require(
			tokenInfo.buyTokenSupply < tokenInfo.softCap,
			"Project is succeed"
		);

		// Get the user's staked amount
		UserInfo storage newUser = userInfo[msg.sender];

		// Require that the user has staked an amount
		require(newUser.stakedAmount > 0, "You have no staked amount");

		// Transfer the staked tokens back to the user
		tokenInfo.buyToken.safeTransfer(msg.sender, newUser.stakedAmount);

		// Update the total buy token supply
		tokenInfo.buyTokenSupply =
			tokenInfo.buyTokenSupply -
			newUser.stakedAmount;

		// Reset the user's staked amount
		newUser.stakedAmount = 0;

		// Emit the TokenRefund event
		emit TokenRefund(msg.sender, address(this));
	}

	// Function to allow users to claim their rewards
	function claim() external {
		// Require that the project is claimable
		require(
			block.timestamp >= timestamps.claimTimestamp,
			"Project not claimable"
		);

		// Require that the project has succeeded (soft cap reached)
		require(
			tokenInfo.buyTokenSupply >= tokenInfo.softCap,
			"Project is not succeed"
		);

		// Get the user's staked amount
		UserInfo storage newUser = userInfo[msg.sender];

		// Require that the user has staked an amount
		require(newUser.stakedAmount > 0, "You have no staked amount");

		// Calculate the user's claimable reward amount
		newUser.claimedAmount =
			(newUser.stakedAmount * 1e18) /
			tokenInfo.rewardTokenPrice;
		newUser.hasClaimed = true;

		// Transfer the reward tokens to the user
		tokenInfo.rewardToken.safeTransfer(msg.sender, newUser.claimedAmount);

		// Emit the TokenClaim event
		emit TokenClaim(msg.sender, address(this), newUser.claimedAmount);
	}

	// Function to allow the owner to withdraw the buy tokens
	function withdraw() external onlyOwner {
		// Require that the project has ended
		require(
			block.timestamp >= timestamps.endTimestamp,
			"Project not ended yet"
		);

		// Require that the project has succeeded (soft cap reached)
		require(
			tokenInfo.buyTokenSupply >= tokenInfo.softCap,
			"Project is not succeed"
		);

		// Require that the tokens have not been distributed yet
		require(!distributed, "Already distributed");

		// Transfer the buy tokens to the owner
		tokenInfo.buyToken.transfer(owner(), tokenInfo.buyTokenSupply);

		// Set the distributed flag to true
		distributed = true;
	}
}
