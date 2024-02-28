// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IHomemadeBroochNFT} from "./interfaces/IHomemadeBroochNFT.sol";
import {IBroochUpgrader} from "./interfaces/IBroochUpgrader.sol";

contract BroochUpgrader is ERC1155Holder, Ownable, IBroochUpgrader {

    error TokenLocked(uint256 tokenId, bool unlocked);
    error WrongMsgValue(uint256 given, uint256 actual);

    IHomemadeBroochNFT private _homemadeBrooch;

    mapping(uint256 tokenId => bool isUnlocked) public tokenUnlocked;
    mapping(uint256 tokenId => uint256 amount) public upgradePrices;

    constructor(address _owner, address homemadeBrooch) Ownable(_owner) {
        _homemadeBrooch = IHomemadeBroochNFT(homemadeBrooch);
    }

    function upgradeBrooch(uint256 tokenId) public payable {
        if (!tokenUnlocked[tokenId]) {
            revert TokenLocked(tokenId, tokenUnlocked[tokenId]);
        }
        uint256 total = (_homemadeBrooch.tokenSupply(tokenId) * 1e18) + upgradePrices[tokenId];
        if (msg.value != total) {
            revert WrongMsgValue(msg.value, total);
        }
        _homemadeBrooch.safeTransferFrom(msg.sender, address(this), tokenId - 1, 1, "");
        _homemadeBrooch.setTokenUnlock(tokenId, true, upgradePrices[tokenId]);

        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 1;

        _homemadeBrooch.mintBatch{value: msg.value}(msg.sender, ids, amounts, "");
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

    receive() external payable {}
}
