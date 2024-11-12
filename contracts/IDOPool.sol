// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IDOPool {
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
        address router;
        address factory;
    }

    struct TokenInfo {
        address rewardToken;
        uint256 rewardTokenPrice;
        address buyToken;
        uint256 buyTokenSupply;
        uint256 softCap;
        uint256 hardCap;
    }

    TokenInfo public tokenInfo;
    Timestamps public timestamps;
    DEXInfo public dexInfo;

    mapping(address => UserInfo) public userInfo;

    event TokenStake(address indexed holder, uint256 amount);
    event TokenRefund(address indexed holder);
    event TokenClaim(address indexed holder, uint256 amount);

    constructor(
        TokenInfo memory _tokenInfo,
        Timestamps memory _timestamps,
        DEXInfo memory _dexInfo
    ) {
        tokenInfo = _tokenInfo;
        dexInfo = _dexInfo;
        setTimestamps(_timestamps);
    }

    function setTimestamps(Timestamps memory _timestamp) internal {
        require(
            _timestamp.startTimestamp < block.timestamp,
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

        IERC20(tokenInfo.buyToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        UserInfo storage newUser = userInfo[msg.sender];
        newUser.stakedAmount = amount;
        newUser.hasClaimed = false;

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

        IERC20(tokenInfo.buyToken).safeTransferFrom(
            address(this),
            msg.sender,
            newUser.stakedAmount
        );

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
            newUser.stakedAmount /
            tokenInfo.rewardTokenPrice;
        newUser.hasClaimed = true;

        IERC20(tokenInfo.rewardToken).safeTransferFrom(
            address(this),
            msg.sender,
            newUser.claimedAmount
        );

        emit TokenClaim(msg.sender, newUser.claimedAmount);
    }
}
