// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";

interface IHomemadeBroochNFT is IERC1155 {
    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data)
        external
        payable;
    function setTokenUnlock(uint256 id, bool unlocked, uint256 basePrice) external;
    function withdraw(address to) external;
    function setURI(string memory newuri) external;
    function transferOwnership(address newOwner) external;
    function tokenSupply(uint256 id) external view returns (uint256);
}
