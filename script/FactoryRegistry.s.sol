// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {FactoryRegistry} from "src/FactoryRegistry.sol";
import {EPAuthority} from "src/proxy/EPAuthority.sol";
import {EPProxyFactory} from "src/proxy/EPProxyFactory.sol";

contract DeployFactoryRegistry is Script {

    function run() public {
        // private key for deployment
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        console.log("Deploying contracts with address", vm.addr(pk));

        vm.startBroadcast(pk);

        address nft = address(0x1849Ae65742D9d64599b3780e11F3E22D02dd350);

        EPAuthority authority = new EPAuthority(owner);
        address beacon = Upgrades.deployBeacon("EPProxy.sol", owner);
        EPProxyFactory proxyFactory = new EPProxyFactory(address(authority), address(beacon));

        Upgrades.deployUUPSProxy(
            "FactoryRegistry.sol",
            abi.encodeCall(FactoryRegistry.initialize, (owner, nft, address(proxyFactory)))
        );

        vm.stopBroadcast();
        console.log("Contracts deployed");
    }
}
