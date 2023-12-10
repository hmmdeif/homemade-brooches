// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {EstforBroochNFT} from "src/EstforBroochNFT.sol";

contract DeployBrooches is Script {

    EstforBroochNFT public nft;

    function run() public {
        // private key for deployment
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        console.log("Deploying contracts with address", vm.addr(pk));

        vm.startBroadcast(pk);

        nft = new EstforBroochNFT(owner, "https://estfor.com/brooches/{id}.json");

        vm.stopBroadcast();

        console.log("Contracts deployed");
    }
}
