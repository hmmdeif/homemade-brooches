// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC2981, IERC165} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IHomemadeBroochNFT} from "./interfaces/IHomemadeBroochNFT.sol";

contract HomemadeBroochNFT is ERC1155, Ownable, IERC2981, IHomemadeBroochNFT {

    address private _royaltyReceiver;
    uint8 private _royaltyFee;

    mapping(uint256 => uint256) public tokenSupply;
    mapping(uint256 => bool) public tokenUnlocked;
    mapping(uint256 => uint256) public baseTokenPrice;

    constructor(address _owner, string memory _uri) ERC1155(_uri) Ownable(_owner) {
        _royaltyFee = 30; // 3%
        _royaltyReceiver = _owner;

        tokenUnlocked[0] = true;
        baseTokenPrice[0] = 10e18; // 10 whole FTM
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC1155)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    function mintBatch(address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) public payable {
        require(to != address(0), "Mint: zero address");
        require(ids.length > 0, "Mint: too little");
        require(ids.length == values.length, "Mint: length mismatch");

        uint256 total = 0;
        for (uint256 i = 0; i < ids.length; ++i) {
            require(tokenUnlocked[ids[i]], "Mint: token locked");            
            for (uint256 j = 0; j < values[i]; ++j) {
                total += tokenSupply[ids[i]] + (j * 1e18) + baseTokenPrice[ids[i]];
            }         
            tokenSupply[ids[i]] += values[i];
        }
        require(total == msg.value, "Mint: wrong msg.value");

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

    // END OWNABLE

    receive() external payable {}

    fallback() external payable {}
}
