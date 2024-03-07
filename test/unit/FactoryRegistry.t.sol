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

contract FactoryRegistryTest is Test {
    uint256 public userKey = 1;
    uint256 public ownerKey = 2;
    address public user = vm.addr(userKey);
    address public owner = vm.addr(ownerKey);

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
        vm.prank(owner);
        ERC1967Proxy registryProxy = new ERC1967Proxy(payable(impl), "");
        registry = FactoryRegistry(payable(registryProxy));
        registry.initialize(owner, address(nft), address(proxyFactory));

        vm.prank(owner);
        authority.setAuthority(address(registry), true);
    }

    function _mintBrooch() internal {
        vm.deal(user, 10 ether);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;

        uint256[] memory values = new uint256[](1);
        values[0] = 1;

        vm.prank(user);
        nft.mintBatch{value: 10 ether}(user, ids, values, "");
    }

    function test_RevertCreateProxyWhenUserDoesNotOwnBrooch() public {
        _deploy();

        vm.deal(user, 10 ether);
        vm.prank(user);
        bytes4 selector = bytes4(keccak256("NoRubyBrooch(address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, user));
        registry.createProxy();
    }

    function test_CreateProxy() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();
        assertEq(registry.totalAddressCount(), 1);
    }

    function test_CreateMultipleProxies() public {
        _deploy();
        _mintBrooch();

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(registry.createProxy.selector);
        data[1] = abi.encodeWithSelector(registry.createProxy.selector);

        vm.prank(user);
        registry.multicall(data);
        assertEq(registry.totalAddressCount(), 2);
    }

    function test_ExecuteSavedTransactions() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSelector(
            proxy.setTransaction.selector, 0, address(nft), abi.encodeCall(nft.balanceOf, (user, 1))
        );
        data[1] = abi.encodeWithSelector(
            proxy.setTransaction.selector, 1, address(nft), abi.encodeCall(nft.balanceOf, (user, 1))
        );
        data[2] = abi.encodeWithSelector(
            proxy.setTransaction.selector, 2, address(nft), abi.encodeCall(nft.balanceOf, (user, 1))
        );

        vm.prank(address(registry));
        proxy.multicall(data);

        vm.prank(user);
        registry.setPaused(address(proxy), false);

        vm.prank(user);
        vm.expectCall(address(nft), abi.encodeCall(nft.balanceOf, (user, 1)), uint64(3));
        registry.executeSavedTransactions(address(proxy));
    }

    function test_RevertSetTransactionWhenNotOwner() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(owner);
        bytes4 selector = bytes4(keccak256("NotProxyOwner(address,address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, owner, address(proxy)));
        registry.setTransaction(address(proxy), 0, address(0), "");
    }

    function test_SetTransaction() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(user);
        registry.setTransaction(address(proxy), 0, address(0), "");
        assertEq(proxy.getTransactionCount(), 1);
    }

    function test_RevertTransferProxyOwnerWhenNotOwner() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(owner);
        bytes4 selector = bytes4(keccak256("NotProxyOwner(address,address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, owner, address(proxy)));
        registry.transferProxyOwner(address(proxy), address(owner));
    }

    function test_TransferProxyOwner() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(user);
        registry.transferProxyOwner(address(proxy), address(owner));
        assertEq(registry.proxyAddressOfOwnerByIndex(owner, 0), address(proxy));
        assertEq(registry.proxyAddressOfOwnerByIndex(user, 0), address(0));
    }

    function test_TransferMultipleProxiesToNewOwner() public {
        _deploy();
        _mintBrooch();

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(registry.createProxy.selector);
        data[1] = abi.encodeWithSelector(registry.createProxy.selector);

        vm.prank(user);
        registry.multicall(data);

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        EPProxy proxy2 = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 1)));

        bytes[] memory data2 = new bytes[](2);
        data2[0] = abi.encodeWithSelector(registry.transferProxyOwner.selector, address(proxy), address(owner));
        data2[1] = abi.encodeWithSelector(registry.transferProxyOwner.selector, address(proxy2), address(owner));

        vm.prank(user);
        registry.multicall(data2);

        assertEq(registry.proxyAddressOfOwnerByIndex(owner, 0), address(proxy));
        assertEq(registry.proxyAddressOfOwnerByIndex(user, 0), address(0));
        assertEq(registry.proxyAddressOfOwnerByIndex(owner, 1), address(proxy2));
        assertEq(registry.proxyAddressOfOwnerByIndex(user, 1), address(0));
    }

    function test_RevertExecuteWhenNotOwner() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(owner);
        bytes4 selector = bytes4(keccak256("NotProxyOwner(address,address)"));
        vm.expectRevert(abi.encodeWithSelector(selector, owner, address(proxy)));
        registry.execute(address(proxy), address(nft), abi.encodeCall(nft.balanceOf, (user, 1)));
    }

    function test_Execute() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(user);
        vm.expectCall(address(nft), abi.encodeCall(nft.balanceOf, (user, 1)));
        registry.execute(address(proxy), address(nft), abi.encodeCall(nft.balanceOf, (user, 1)));
    }

    function test_RegistryUpgrade() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();

        EPProxy proxy = EPProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        FactoryRegistry impl = new FactoryRegistry();
        vm.prank(owner);
        registry.upgradeToAndCall(address(impl), "");
        assertEq(registry.totalAddressCount(), 1);

        vm.prank(user);
        registry.transferProxyOwner(address(proxy), address(owner));
        assertEq(registry.proxyAddressOfOwnerByIndex(owner, 0), address(proxy));
        assertEq(registry.proxyAddressOfOwnerByIndex(user, 0), address(0));
    }
}
