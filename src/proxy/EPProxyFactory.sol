// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IEPProxy} from "./IEPProxy.sol";
import {EPAuthority} from "./EPAuthority.sol";

// EPProxyFactory
// This factory deploys new proxy instances through build()
contract EPProxyFactory {
    event Created(address indexed sender, address indexed owner, address proxy);

    mapping(address => bool) public isProxy;

    EPAuthority public authority;
    address public beacon;

    constructor(address authority_, address beacon_) {
        authority = EPAuthority(authority_);
        beacon = beacon_;
    }

    // deploys a new proxy instance
    // sets custom owner of proxy
    function build(address owner) public returns (address proxy) {
        proxy = address(
            new BeaconProxy(beacon, abi.encodeWithSelector(IEPProxy.initialize.selector, owner, address(authority)))
        );
        emit Created(msg.sender, owner, address(proxy));
        isProxy[address(proxy)] = true;
    }
}
