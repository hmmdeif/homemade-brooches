// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EPAuthority is Ownable {
    event LogSetAuthority(address indexed authority, bool authorized);

    error AccessDenied();

    mapping(address addr => bool isAuthorized) private _authorized;

    constructor(address owner) Ownable(owner) {}

    function isAuthorized(address addr) public view returns (bool) {
        return _authorized[addr];
    }

    function setAuthority(address authority, bool authorized) public onlyOwner {
        _authorized[authority] = authorized;
        emit LogSetAuthority(authority, authorized);
    }

    function giveAuthority(address authority) public onlyAuthority {
        _authorized[authority] = true;
    }

    function removeAuthority(address authority) public onlyAuthority {
        _authorized[authority] = false;
    }

    modifier onlyAuthority() {
        if (!isAuthorized(msg.sender)) {
            revert AccessDenied();
        }
        _;
    }
}
