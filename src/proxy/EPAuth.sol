// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {EPAuthority} from "./EPAuthority.sol";

abstract contract EPAuth {
    event LogSetOwner(address indexed owner);

    address public owner;
    EPAuthority public authority;

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    modifier auth() {
        require(isAuthorized(msg.sender), "EPAuth: access denied");
        _;
    }

    function isAuthorized(address src) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority.isAuthorized(src)) {
            return true;
        }
        return false;
    }
}
