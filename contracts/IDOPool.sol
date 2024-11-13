// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IUniswapV2Router02 } from "./interfaces/IUniswapV2Router02.sol";
import { IUniswapV2Factory } from "./interfaces/IUniswapV2Factory.sol";

contract IDOPool is Ownable {
	using SafeERC20 for IERC20;

	struct Timestamps {
		uint256 startTimestamp;
		uint256 endTimestamp;
		uint256 claimTimestamp;
	}

	struct UserInfo {
		uint256 stakedAmount;
		uint256 claimedAmount;
		bool hasClaimed;
	}

	struct DEXInfo {
		IUniswapV2Router02 router;
		IUniswapV2Factory factory;
	}

	struct TokenInfo {
		IERC20 rewardToken;
		uint256 rewardTokenPrice;
		IERC20 buyToken;
		uint256 buyTokenSupply;
		uint256 softCap;
		uint256 hardCap;
	}

	bool public distributed = false;

	TokenInfo public tokenInfo;
	Timestamps public timestamps;
	DEXInfo public dexInfo;

	mapping(address => UserInfo) public userInfo;

	event TokenStake(address indexed holder, uint256 amount);
	event TokenRefund(address indexed holder);
	event TokenClaim(address indexed holder, uint256 amount);

	constructor(
		address initialOwner,
		TokenInfo memory _tokenInfo,
		Timestamps memory _timestamps,
		DEXInfo memory _dexInfo
	) Ownable(initialOwner) {
		tokenInfo = _tokenInfo;
		dexInfo = _dexInfo;
		setTimestamps(_timestamps);
	}

	function setSoftCap(uint256 _softCap) external {
		tokenInfo.softCap = _softCap;
	}

	function setTimestamps(Timestamps memory _timestamp) public onlyOwner {
		require(
			_timestamp.startTimestamp > block.timestamp,
			"Start timestamp must be more than current timestamp"
		);
		require(
			_timestamp.startTimestamp < _timestamp.endTimestamp,
			"Start timestamp must be less than end timestamp"
		);
		require(
			_timestamp.endTimestamp < _timestamp.claimTimestamp,
			"End timestamp must be less than claim timestamp"
		);

		timestamps = _timestamp;
	}

	function stake(uint256 amount) external {
		require(
			block.timestamp >= timestamps.startTimestamp,
			"Project not started"
		);
		require(
			block.timestamp < timestamps.endTimestamp,
			"Project already ended"
		);
		require(
			amount + tokenInfo.buyTokenSupply <= tokenInfo.hardCap,
			"Overfilled"
		);
		require(amount > 0, "Amount must be greater than zero");

		tokenInfo.buyToken.safeTransferFrom(msg.sender, address(this), amount);

		UserInfo storage newUser = userInfo[msg.sender];
		newUser.stakedAmount = amount;
		newUser.hasClaimed = false;

		tokenInfo.buyTokenSupply = tokenInfo.buyTokenSupply + amount;

		emit TokenStake(msg.sender, amount);
	}

	function refund() external {
		require(
			block.timestamp >= timestamps.endTimestamp,
			"Project not ended yet"
		);
		require(
			tokenInfo.buyTokenSupply < tokenInfo.softCap,
			"Project is succeed"
		);

		UserInfo storage newUser = userInfo[msg.sender];

		require(newUser.stakedAmount > 0, "You have no staked amount");

		tokenInfo.buyToken.safeTransfer(msg.sender, newUser.stakedAmount);

		tokenInfo.buyTokenSupply =
			tokenInfo.buyTokenSupply -
			newUser.stakedAmount;

		newUser.stakedAmount = 0;

		emit TokenRefund(msg.sender);
	}

	function claim() external {
		require(
			block.timestamp >= timestamps.claimTimestamp,
			"Project not claimable"
		);
		require(
			tokenInfo.buyTokenSupply >= tokenInfo.softCap,
			"Project is not succeed"
		);

		UserInfo storage newUser = userInfo[msg.sender];

		require(newUser.stakedAmount > 0, "You have no staked amount");

		newUser.claimedAmount =
			(newUser.stakedAmount * 1e18) /
			tokenInfo.rewardTokenPrice;
		newUser.hasClaimed = true;

		tokenInfo.rewardToken.safeTransfer(msg.sender, newUser.claimedAmount);

		emit TokenClaim(msg.sender, newUser.claimedAmount);
	}

	function withdraw() external onlyOwner {
		require(
			block.timestamp >= timestamps.endTimestamp,
			"Project not ended yet"
		);
		require(
			tokenInfo.buyTokenSupply >= tokenInfo.softCap,
			"Project is not succeed"
		);
		require(!distributed, "Already distributed");

		uint256 rewardTokenAmount = (tokenInfo.buyTokenSupply * 1e18) /
			tokenInfo.rewardTokenPrice;

		tokenInfo.rewardToken.approve(address(dexInfo.router), rewardTokenAmount);
		tokenInfo.buyToken.approve(
			address(dexInfo.router),
			tokenInfo.buyTokenSupply
		);

		dexInfo.router.addLiquidity(
			address(tokenInfo.rewardToken),
			address(tokenInfo.buyToken),
			rewardTokenAmount,
			tokenInfo.buyTokenSupply,
			0,
			0,
			owner(),
			block.timestamp
		);

		distributed = true;
	}
}
