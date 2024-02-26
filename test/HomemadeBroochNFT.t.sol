// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import {HomemadeBroochNFT} from "src/HomemadeBroochNFT.sol";

contract HomemadeBroochNFTTest is Test {
    uint256 public userKey = 1;
    uint256 public ownerKey = 2;
    address public user = vm.addr(userKey);
    address public owner = vm.addr(ownerKey);

    HomemadeBroochNFT public nft;

    function _deploy() internal {
        nft = new HomemadeBroochNFT(owner, "");
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

    function test_RevertWithdrawWhenNotOwner() public {
        _deploy();

        vm.deal(address(nft), 1 ether);
        vm.prank(user);        
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, user));
        nft.withdraw(user);
    }

    function test_Withdraw() public {
        _deploy();

        vm.deal(address(nft), 1 ether);
        vm.prank(owner);
        nft.withdraw(owner);
        assertEq(address(nft).balance, 0);
        assertEq(owner.balance, 1 ether);
    }

    function test_RevertSetURIWhenNotOwner() public {
        _deploy();

        vm.prank(user);        
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, user));
        nft.setURI("");
    }

    function test_SetURI() public {
        _deploy();

        vm.prank(owner);        
        nft.setURI("test");
        assertEq(nft.uri(0), "test");
    }

    function test_RevertMintBatchWhenZeroAddress() public {
        _deploy();

        vm.prank(user);        
        vm.expectRevert("Mint: zero address");
        nft.mintBatch(address(0), new uint256[](0), new uint256[](0), "");
    }

    function test_RevertMintBatchWhenIdLengthZero() public {
        _deploy();

        vm.prank(user);        
        vm.expectRevert("Mint: too little");
        nft.mintBatch(user, new uint256[](0), new uint256[](0), "");
    }

    function test_RevertMintBatchWhenIdLengthMismatch() public {
        _deploy();

        vm.prank(user);        
        vm.expectRevert("Mint: length mismatch");
        nft.mintBatch(user, new uint256[](1), new uint256[](0), "");
    }

    function test_RevertMintBatchWhenTokenLocked() public {
        _deploy();

        vm.prank(user);        
        vm.expectRevert("Mint: token locked");

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 1;

        nft.mintBatch(user, ids, values, "");
    }

    function test_RevertSetTokenLockWhenNotOwner() public {
        _deploy();

        vm.prank(user);        
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, user));
        nft.setTokenUnlock(1, true, 10 ether);
    }

    function test_SetTokenLock() public {
        _deploy();

        vm.prank(owner);        
        nft.setTokenUnlock(1, true, 10 ether);
        assertEq(nft.tokenUnlocked(1), true);
        assertEq(nft.tokenUnlocked(2), false);
    }

    function test_RevertMintBatchWhenValueWrong() public {
        _deploy();

        vm.prank(owner);        
        nft.setTokenUnlock(1, true, 10 ether);

        vm.deal(user, 10 ether);
        vm.prank(user);        
        vm.expectRevert("Mint: wrong msg.value");

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 1;

        nft.mintBatch{ value: 1 ether }(user, ids, values, "");
    }

    function test_MintBatchOne() public {
        _deploy();

        vm.prank(owner);        
        nft.setTokenUnlock(1, true, 10 ether);

        vm.deal(user, 10 ether);
        vm.prank(user);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 1;

        nft.mintBatch{ value: 10 ether }(user, ids, values, "");
        assertEq(nft.balanceOf(user, 1), 1);
    }

    function test_RevertMintBatchWhenValueWrongMultipleValue() public {
        _deploy();

        vm.prank(owner);        
        nft.setTokenUnlock(1, true, 10 ether);

        vm.deal(user, 10 ether);
        vm.prank(user);        
        vm.expectRevert("Mint: wrong msg.value");

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 3;

        nft.mintBatch{ value: 10 ether }(user, ids, values, "");
    }

    function test_MintBatchMultipleValue() public {
        _deploy();

        vm.prank(owner);        
        nft.setTokenUnlock(1, true, 10 ether);

        vm.deal(user, 33 ether); // 10 + 11 + 12
        vm.prank(user);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 3;

        nft.mintBatch{ value: 33 ether }(user, ids, values, "");
        assertEq(nft.balanceOf(user, 1), 3);
    }

    function test_RevertMintBatchWhenValueWrongMultipleTokens() public {
        _deploy();

        vm.prank(owner);        
        nft.setTokenUnlock(1, true, 10 ether);

        vm.prank(owner);        
        nft.setTokenUnlock(2, true, 20 ether);

        vm.deal(user, 20 ether);
        vm.prank(user);        
        vm.expectRevert("Mint: wrong msg.value");

        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 1;
        values[1] = 1;

        nft.mintBatch{ value: 20 ether }(user, ids, values, "");
    }

    function test_MintBatchMultipleTokens() public {
        _deploy();

        vm.prank(owner);        
        nft.setTokenUnlock(1, true, 10 ether);

        vm.prank(owner);        
        nft.setTokenUnlock(2, true, 20 ether);

        vm.deal(user, 74 ether); // 10 + 11 + 12 + 20 + 21
        vm.prank(user);

        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;

        uint256[] memory values = new uint256[](2);
        values[0] = 3;
        values[1] = 2;

        nft.mintBatch{ value: 74 ether }(user, ids, values, "");
        assertEq(nft.balanceOf(user, 1), 3);
        assertEq(nft.balanceOf(user, 2), 2);
    }

    function test_MintBatchMultipleTokensTwice() public {
        _deploy();

        vm.prank(owner);        
        nft.setTokenUnlock(1, true, 10 ether);

        vm.prank(owner);        
        nft.setTokenUnlock(2, true, 20 ether);

        {
            vm.deal(user, 74 ether); // 10 + 11 + 12 + 20 + 21
            vm.prank(user);

            uint256[] memory ids = new uint256[](2);
            ids[0] = 1;
            ids[1] = 2;

            uint256[] memory values = new uint256[](2);
            values[0] = 3;
            values[1] = 2;

            nft.mintBatch{ value: 74 ether }(user, ids, values, "");
            assertEq(nft.balanceOf(user, 1), 3);
            assertEq(nft.balanceOf(user, 2), 2);
        }

        {
            vm.deal(user, 49 ether); // 13 + 14 + 22
            vm.prank(user);

            uint256[] memory ids = new uint256[](2);
            ids[0] = 1;
            ids[1] = 2;

            uint256[] memory values = new uint256[](2);
            values[0] = 2;
            values[1] = 1;

            nft.mintBatch{ value: 49 ether }(user, ids, values, "");
            assertEq(nft.balanceOf(user, 1), 5);
            assertEq(nft.balanceOf(user, 2), 3);
        }
    }
}
