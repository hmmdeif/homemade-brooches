// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import {HomemadeBroochNFT} from "src/HomemadeBroochNFT.sol";
import {FactoryRegistry} from "src/FactoryRegistry.sol";
import {DSAuthority} from "src/DS/DSAuthority.sol";
import {DSProxyFactory} from "src/DS/DSProxyFactory.sol";
import {DSProxy} from "src/DS/DSProxy.sol";

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

        DSAuthority authority = new DSAuthority(owner);
        DSProxyFactory proxyFactory = new DSProxyFactory(address(authority));
        registry = new FactoryRegistry(owner, address(nft), address(proxyFactory));
        
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
        nft.mintBatch{ value: 10 ether }(user, ids, values, "");
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

    function test_RevertCreateProxyWhenUserDoesNotOwnBrooch() public {
        _deploy();

        vm.deal(user, 10 ether);
        vm.prank(user);        
        vm.expectRevert("FactoryRegistry: no ruby brooch");
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
        
        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        bytes[] memory data = new bytes[](3);
        data[0] = abi.encodeWithSelector(proxy.setTransaction.selector, 0, address(nft), abi.encodeCall(nft.balanceOf, (user, 1)));
        data[1] = abi.encodeWithSelector(proxy.setTransaction.selector, 1, address(nft), abi.encodeCall(nft.balanceOf, (user, 1)));
        data[2] = abi.encodeWithSelector(proxy.setTransaction.selector, 2, address(nft), abi.encodeCall(nft.balanceOf, (user, 1)));
        
        vm.prank(address(registry));
        proxy.multicall(data);

        vm.prank(user);
        vm.expectCall(address(nft), abi.encodeCall(nft.balanceOf, (user, 1)), uint64(3));
        registry.executeSavedTransactions(address(proxy));
    }

    function test_RevertSetTransactionWhenNotOwner() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();
        
        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(owner);
        vm.expectRevert("FactoryRegistry: not owned proxy");
        registry.setTransaction(address(proxy), 0, address(0), "");
    }

    function test_SetTransaction() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();
        
        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(user);
        registry.setTransaction(address(proxy), 0, address(0), "");
        assertEq(proxy.getTransactionCount(), 1);
    }

    function test_RevertTransferProxyOwnerWhenNotOwner() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();
        
        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        vm.prank(owner);
        vm.expectRevert("FactoryRegistry: not owned proxy");
        registry.transferProxyOwner(address(proxy), address(owner));
    }

    function test_TransferProxyOwner() public {
        _deploy();
        _mintBrooch();

        vm.prank(user);
        registry.createProxy();
        
        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

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
        
        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        DSProxy proxy2 = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 1)));

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
}
