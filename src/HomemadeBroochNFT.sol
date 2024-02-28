// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IHomemadeBroochNFT} from "./interfaces/IHomemadeBroochNFT.sol";

contract HomemadeBroochNFT is ERC1155, Ownable, IERC2981, IHomemadeBroochNFT {

    error ZeroAddress();
    error LengthMismatch(uint256 idLength, uint256 valueLength);
    error TokenLocked(uint256 tokenId, bool unlocked);
    error WrongMsgValue(uint256 given, uint256 actual);

    address private _royaltyReceiver;
    uint8 private _royaltyFee;

    mapping(uint256 tokenId => uint256 totalSupply) public tokenSupply;
    mapping(uint256 tokenId => bool isUnlocked) public tokenUnlocked;
    mapping(uint256 tokenId => uint256 amount) public baseTokenPrice;

    constructor(address _owner, string memory _uri) ERC1155(_uri) Ownable(_owner) {
        _royaltyFee = 30; // 3%
        _royaltyReceiver = _owner;

        tokenUnlocked[0] = true;
        baseTokenPrice[0] = 10 ether; // 10 whole FTM
    }

    function supportsInterface(bytes4 interfaceId) public view override(IERC165, ERC1155) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data)
        public
        payable
    {
        if (to == address(0)) {
            revert ZeroAddress();
        }
        if (ids.length == 0 || ids.length != values.length) {
            revert LengthMismatch(ids.length, values.length);
        }

        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; ++i) {
            if (!tokenUnlocked[ids[i]]) {
                revert TokenLocked(ids[i], tokenUnlocked[ids[i]]);
            }
            for (uint256 j = 0; j < values[i]; ++j) {
                total += ((tokenSupply[ids[i]] + j) * 1e18) + baseTokenPrice[ids[i]];
            }
            tokenSupply[ids[i]] += values[i];
        }
        if (total != msg.value) {
            revert WrongMsgValue(msg.value, total);
        }

        _mintBatch(to, ids, values, data);
    }

    function royaltyInfo(uint256, /*_tokenId*/ uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 amount = (_salePrice * _royaltyFee) / 1000;
        return (_royaltyReceiver, amount);
    }

    // OWNABLE

    function withdraw(address to) public onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function setTokenUnlock(uint256 id, bool unlocked, uint256 basePrice) public onlyOwner {
        tokenUnlocked[id] = unlocked;
        baseTokenPrice[id] = basePrice;
    }

    function transferOwnership(address newOwner) public override(IHomemadeBroochNFT, Ownable) onlyOwner {
        super._transferOwnership(newOwner);
    }

    // END OWNABLE

    receive() external payable {}
}
