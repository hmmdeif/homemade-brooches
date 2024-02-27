// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

interface IPlayerNFT {
    function mint(
        uint256 _avatarId,
        string calldata _name,
        string calldata _discord,
        string calldata _twitter,
        string calldata _telegram,
        bool _upgrade,
        bool _makeActive
    ) external;
}
