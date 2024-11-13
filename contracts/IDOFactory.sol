// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IDOPool} from "./IDOPool.sol";

contract IDOFactory is Ownable {
    event IDOCreated(
        address indexed owner,
        address idoPool,
        address rewardToken
    );

    constructor(address initialOwner) Ownable(initialOwner) {}

    function createIDO(
        IDOPool.TokenInfo memory tokenInfo,
        IDOPool.Timestamps memory timestamp,
        IDOPool.DEXInfo memory dexInfo
    ) external onlyOwner {
        IDOPool idoPool = new IDOPool(owner(), tokenInfo, timestamp, dexInfo);

        emit IDOCreated(
            msg.sender,
            address(idoPool),
            address(tokenInfo.rewardToken)
        );
    }
}
