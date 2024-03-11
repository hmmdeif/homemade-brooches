// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {FactoryRegistryV2} from "src/FactoryRegistryV2.sol";

contract DeployFactoryRegistryV2 is Script {
    function run() public {
        // private key for deployment
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        console.log("Deploying contracts with address", vm.addr(pk));

        vm.startBroadcast(pk);

        address proxy = address(0xF9A66F8C569D23f1fA1A63950c3CA822Cf26355e);

        Upgrades.upgradeProxy(proxy, "FactoryRegistryV2.sol", "");
        FactoryRegistryV2(payable(proxy)).transferOwnership(owner);

        vm.stopBroadcast();
        console.log("Contracts deployed");
    }
}
