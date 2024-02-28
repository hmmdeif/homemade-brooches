// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {EPAuthority} from "./EPAuthority.sol";

abstract contract EPAuth {
    event LogSetOwner(address indexed owner);

    error AccessDenied();

    address public owner;
    EPAuthority public authority;

    function setOwner(address owner_) public auth {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    modifier auth() {
        if (!isAuthorized(msg.sender)) {
            revert AccessDenied();
        }
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
