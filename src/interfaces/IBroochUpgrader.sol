// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBroochUpgrader {
    function upgradeBrooch(uint256 tokenId) external payable;
    function setTokenUpgradePrice(uint256 id, bool unlocked, uint256 upgradePrice) external;
    function withdraw(address to) external;
    function transferBroochOwnership(address newOwner) external;
    function setURI(string memory newUri) external;
}
