// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IDOPool.sol";

contract IDOFactory {
    event IDOCreated(
        address indexed owner,
        address idoPool,
        address rewardToken
    );

    constructor() {}

    function createIDO(
        IDOPool.TokenInfo memory tokenInfo,
        IDOPool.Timestamps memory timestamp,
        IDOPool.DEXInfo memory dexInfo
    ) external {
        IDOPool idoPool = new IDOPool(tokenInfo, timestamp, dexInfo);

        emit IDOCreated(
            msg.sender,
            address(idoPool),
            address(tokenInfo.rewardToken)
        );
    }
}
