// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IHomemadeBroochNFT {
    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external payable;
}
