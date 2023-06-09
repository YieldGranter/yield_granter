// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGauge {
    function depositAll(uint tokenId) external;
    function withdraw(uint amount) external;
    function withdrawToken(uint amount, uint tokenId) external;
    function getReward(address account, address[] memory tokens) external;
}
