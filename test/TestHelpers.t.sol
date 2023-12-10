// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import {EstforBroochNFT} from "src/EstforBroochNFT.sol";

contract TestHelpers is Test {
    string public MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");   

    uint256 public userKey = 1;
    uint256 public ownerKey = 2;
    address public user = vm.addr(userKey);
    address public owner = vm.addr(ownerKey);

    EstforBroochNFT public nft;

    function _deploy() internal {
        nft = new EstforBroochNFT(owner, "");
    }

    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}
