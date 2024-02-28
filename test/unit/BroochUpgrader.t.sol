// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {HomemadeBroochNFT} from "src/HomemadeBroochNFT.sol";
import {BroochUpgrader} from "src/BroochUpgrader.sol";

contract BroochUpgraderTest is Test {
    uint256 public userKey = 1;
    uint256 public ownerKey = 2;
    address public user = vm.addr(userKey);
    address public owner = vm.addr(ownerKey);

    HomemadeBroochNFT public nft;
    BroochUpgrader public upgrader;

    function _deploy() internal {
        nft = new HomemadeBroochNFT(owner, "");
        upgrader = new BroochUpgrader(owner, address(nft));

        vm.prank(owner);
        nft.setTokenUnlock(1, true, 10 ether);

        vm.prank(owner);
        nft.transferOwnership(address(upgrader));
    }

    function test_RevertWithdrawWhenNotOwner() public {
        _deploy();

        vm.deal(address(upgrader), 1 ether);
        vm.prank(user);
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, user));
        upgrader.withdraw(user);
    }

    function test_Withdraw() public {
        _deploy();

        vm.deal(address(upgrader), 1 ether);
        vm.prank(owner);
        upgrader.withdraw(owner);
        assertEq(address(upgrader).balance, 0);
        assertEq(address(owner).balance, 1 ether);
    }

    function test_WithdrawFromNFT() public {
        _deploy();

        vm.deal(address(nft), 1 ether);
        vm.prank(owner);
        upgrader.withdraw(owner);
        assertEq(address(upgrader).balance, 0);
        assertEq(address(owner).balance, 1 ether);
    }

    function test_RevertTransferBroochOwnershipWhenNotOwner() public {
        _deploy();

        vm.prank(user);
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, user));
        upgrader.transferBroochOwnership(user);
    }

    function test_TransferBroochOwnership() public {
        _deploy();

        vm.prank(owner);
        upgrader.transferBroochOwnership(owner);
        assertEq(nft.owner(), owner);
    }

    function test_RevertSetTokenUpgradePriceWhenNotOwner() public {
        _deploy();

        vm.prank(user);
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, user));
        upgrader.setTokenUpgradePrice(1, true, 10 ether);
    }

    function test_SetTokenUpgradePrice() public {
        _deploy();

        vm.prank(owner);
        upgrader.setTokenUpgradePrice(1, true, 10 ether);
        assertEq(upgrader.tokenUnlocked(1), true);
        assertEq(upgrader.tokenUnlocked(2), false);
    }

    function test_RevertUpgradeWhenTokenLocked() public {
        _deploy();

        vm.deal(user, 10 ether);
        bytes4 selector = bytes4(keccak256("TokenLocked(uint256,bool)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 1, false));
        vm.prank(user);
        upgrader.upgradeBrooch{value: 10 ether}(1);
    }

    function test_RevertUpgradeWhenIncorrectAmount() public {
        _deploy();

        vm.deal(user, 10 ether);
        vm.prank(owner);
        upgrader.setTokenUpgradePrice(2, true, 10 ether);
        bytes4 selector = bytes4(keccak256("WrongMsgValue(uint256,uint256)"));
        vm.expectRevert(abi.encodeWithSelector(selector, 1 ether, 10 ether));
        vm.prank(user);
        upgrader.upgradeBrooch{value: 1 ether}(2);
    }

    function test_RevertUpgradeTokenWhenUserDoesNotOwnOriginal() public {
        _deploy();

        vm.deal(user, 10 ether);
        vm.prank(owner);
        upgrader.setTokenUpgradePrice(2, true, 10 ether);

        vm.prank(user);
        nft.setApprovalForAll(address(upgrader), true);

        vm.expectRevert();
        vm.prank(user);
        upgrader.upgradeBrooch{value: 10 ether}(2);
    }

    function test_UpgradeToken() public {
        _deploy();

        vm.deal(user, 31 ether);
        vm.prank(owner);
        upgrader.setTokenUpgradePrice(2, true, 10 ether);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 2;

        vm.prank(user);
        nft.mintBatch{value: 21 ether}(user, ids, values, "");
        vm.prank(user);
        nft.setApprovalForAll(address(upgrader), true);
        vm.prank(user);
        upgrader.upgradeBrooch{value: 10 ether}(2);
        assertEq(nft.balanceOf(user, 1), 1); // had 2, now 1
        assertEq(nft.balanceOf(user, 2), 1);
        assertEq(nft.balanceOf(address(upgrader), 1), 1);
        assertEq(address(nft).balance, 31 ether);
    }

    function test_UpgradeTokenPriceIncreases() public {
        _deploy();

        vm.deal(user, 42 ether);
        vm.prank(owner);
        upgrader.setTokenUpgradePrice(2, true, 10 ether);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 2;

        vm.prank(user);
        nft.mintBatch{value: 21 ether}(user, ids, values, "");
        vm.prank(user);
        nft.setApprovalForAll(address(upgrader), true);
        vm.prank(user);
        upgrader.upgradeBrooch{value: 10 ether}(2);
        vm.prank(user);
        upgrader.upgradeBrooch{value: 11 ether}(2);
        assertEq(nft.balanceOf(user, 1), 0); // had 2, now 0
        assertEq(nft.balanceOf(user, 2), 2);
        assertEq(nft.balanceOf(address(upgrader), 1), 2);
        assertEq(address(nft).balance, 42 ether);
    }

    function test_RevertSetURIWhenNotOwner() public {
        _deploy();

        vm.prank(user);
        bytes4 selector = bytes4(keccak256("OwnableUnauthorizedAccount(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, user));
        upgrader.setURI("");
    }

    function test_SetURI() public {
        _deploy();

        vm.prank(owner);
        upgrader.setURI("test");
        assertEq(nft.uri(0), "test");
    }
}
