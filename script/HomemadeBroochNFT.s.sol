// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";

import {HomemadeBroochNFT} from "src/HomemadeBroochNFT.sol";

contract DeployBrooches is Script {

    HomemadeBroochNFT public nft;

    function run() public {
        // private key for deployment
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address owner = vm.envAddress("OWNER");
        console.log("Deploying contracts with address", vm.addr(pk));

        vm.startBroadcast(pk);

        nft = new HomemadeBroochNFT(owner, "ipfs://Qmeb6LJ57G4emTcRagxwEakgvwvSrqv6693mkBx7F9aaWA/assets/brooches/{id}.json");

        vm.stopBroadcast();

        console.log("Contracts deployed");
    }
}
