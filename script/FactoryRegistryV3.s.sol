// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";

import {Upgrades} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {FactoryRegistryV3} from "src/factory/FactoryRegistryV3.sol";

contract DeployFactoryRegistryV3 is Script {
    function run() public {
        // private key for deployment
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        console.log("Deploying contracts with address", vm.addr(pk));

        vm.startBroadcast(pk);

        address proxy = address(0xF9A66F8C569D23f1fA1A63950c3CA822Cf26355e);

        Upgrades.upgradeProxy(proxy, "FactoryRegistryV3.sol", "");
        FactoryRegistryV3(payable(proxy)).transferOwnership(owner);

        vm.stopBroadcast();
        console.log("Contracts deployed");
    }
}
