// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IHomemadeBroochNFT} from "./interfaces/IHomemadeBroochNFT.sol";
import {IBroochUpgrader} from "./interfaces/IBroochUpgrader.sol";

contract BroochUpgrader is IBroochUpgrader, ERC165, Ownable {

    IHomemadeBroochNFT private _homemadeBrooch;

    mapping(uint256 => bool) public tokenUnlocked;
    mapping(uint256 => uint256) public upgradePrices;

    constructor(address _owner, address homemadeBrooch) Ownable(_owner) {
        _homemadeBrooch = IHomemadeBroochNFT(homemadeBrooch);
    }

    function upgradeBrooch(uint256 tokenId) public payable {
        require(tokenUnlocked[tokenId], "Upgrade: token locked");
        uint256 total = (_homemadeBrooch.tokenSupply(tokenId) * 1e18) + upgradePrices[tokenId];
        require(msg.value == total, "Upgrade: wrong msg.value");
        _homemadeBrooch.safeTransferFrom(msg.sender, address(this), tokenId - 1, 1, "");
        _homemadeBrooch.setTokenUnlock(tokenId, true, upgradePrices[tokenId]);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        _homemadeBrooch.mintBatch{ value: msg.value }(msg.sender, ids, amounts, "");
        _homemadeBrooch.setTokenUnlock(tokenId, false, upgradePrices[tokenId]);
    }

    // OWNABLE

    function withdraw(address to) public onlyOwner {
        _homemadeBrooch.withdraw(to);
        payable(to).transfer(address(this).balance);
    }

    function setTokenUpgradePrice(uint256 id, bool unlocked, uint256 upgradePrice) public onlyOwner {
        tokenUnlocked[id] = unlocked;
        upgradePrices[id] = upgradePrice;
    }

    function transferBroochOwnership(address newOwner) public onlyOwner {
        _homemadeBrooch.transferOwnership(newOwner);
    }

    function setURI(string memory newUri) public onlyOwner {
        _homemadeBrooch.setURI(newUri);
    }

    // END OWNABLE

    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    receive() external payable {}

    fallback() external payable {}
}
