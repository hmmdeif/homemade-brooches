// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {HomemadeBroochNFT} from "src/HomemadeBroochNFT.sol";
import {FactoryRegistry} from "src/FactoryRegistry.sol";
import {EPAuthority} from "src/proxy/EPAuthority.sol";
import {EPProxyFactory} from "src/proxy/EPProxyFactory.sol";
import {EPProxy} from "src/proxy/EPProxy.sol";
import {Addresses} from "src/Addresses.sol";

contract EPProxyTest is Addresses, Test {
    uint256 public userKey = 1;
    uint256 public ownerKey = 2;
    uint256 public unauthUserKey = 3;
    address public user = vm.addr(userKey);
    address public owner = vm.addr(ownerKey);
    address public unauthUser = vm.addr(unauthUserKey);

    HomemadeBroochNFT public nft;
    FactoryRegistry public registry;

    function _deploy() internal {
        nft = new HomemadeBroochNFT(owner, "");

        vm.prank(owner);
        nft.setTokenUnlock(1, true, 10 ether);

        EPAuthority authority = new EPAuthority(owner);
        EPProxy beaconImpl = new EPProxy();
        UpgradeableBeacon beacon = new UpgradeableBeacon(address(beaconImpl), owner);
        EPProxyFactory proxyFactory = new EPProxyFactory(address(authority), address(beacon));
        FactoryRegistry impl = new FactoryRegistry();
        ERC1967Proxy registryProxy = new ERC1967Proxy(payable(impl), "");
        registry = FactoryRegistry(payable(registryProxy));
        registry.initialize(owner, address(nft), address(proxyFactory));

        vm.prank(owner);
        authority.setAuthority(user, true);
        vm.prank(owner);
        authority.setAuthority(address(registry), true);
    }

    function _mintBroochAndCreateProxy() internal {
        vm.deal(user, 21 ether);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 1;

        vm.prank(user);
        nft.mintBatch{value: 10 ether}(user, ids, values, "");

        vm.prank(user);
        registry.createProxy();
    }

    function test_RevertExecuteNotAuthority() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(unauthUser);
        bytes4 selector = bytes4(keccak256("AccessDenied()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        proxy.execute(address(20), "");
    }

    function test_Execute() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(user);
        vm.expectCall(address(nft), abi.encodeCall(nft.balanceOf, (user, 1)));
        proxy.execute(address(nft), abi.encodeCall(nft.balanceOf, (user, 1))); // delegate calls can't return varlable length data so don't check
    }

    function test_RevertSetTransactionWhenNotOwner() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(unauthUser);
        bytes4 selector = bytes4(keccak256("AccessDenied()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        proxy.setTransaction(0, address(0), "");
    }

    function test_SetTransaction() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(user);
        proxy.setTransaction(0, address(0), "");
        EPProxy.Transaction[] memory transactions = proxy.getAllSavedTransactions();
        assertEq(transactions.length, 1);
        assertEq(proxy.getTransactionCount(), 1);
    }

    function test_SetMultipleTransactions() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(proxy.setTransaction.selector, 0, address(0), "");
        data[1] = abi.encodeWithSelector(proxy.setTransaction.selector, 1, address(0), "");

        vm.prank(user);
        proxy.multicall(data);
        EPProxy.Transaction[] memory transactions = proxy.getAllSavedTransactions();
        assertEq(transactions.length, 2);
        assertEq(proxy.getTransactionCount(), 2);
    }

    function test_SetTransactionOverwritesExisting() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(user);
        proxy.setTransaction(0, address(0), "");
        vm.prank(user);
        proxy.setTransaction(1, address(1), "");
        vm.prank(user);
        proxy.setTransaction(0, address(2), "");
        EPProxy.Transaction[] memory transactions = proxy.getAllSavedTransactions();
        assertEq(transactions.length, 2);
        assertEq(proxy.getTransactionCount(), 2);
        assertEq(transactions[0].to, address(2));
    }

    function test_RevertSetPausedWhenNotOwner() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(unauthUser);
        bytes4 selector = bytes4(keccak256("AccessDenied()"));
        vm.expectRevert(abi.encodeWithSelector(selector));
        proxy.setPaused(false);
    }

    function test_SetPaused() public {
        _deploy();
        _mintBroochAndCreateProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        assertEq(proxy.isPaused(), true); // default
        vm.prank(user);
        proxy.setPaused(false);
        assertEq(proxy.isPaused(), false);
    }
}
