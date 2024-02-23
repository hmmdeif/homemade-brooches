// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {BroochUpgrader} from "src/BroochUpgrader.sol";

contract DeployBroochUpgrader is Script {

    BroochUpgrader public upgrader;

    function run() public {
        // private key for deployment
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        console.log("Deploying contracts with address", vm.addr(pk));

        vm.startBroadcast(pk);

        upgrader = new BroochUpgrader(owner, address(0x1849Ae65742D9d64599b3780e11F3E22D02dd350));

        vm.stopBroadcast();

        console.log("Contracts deployed");
    }
}
