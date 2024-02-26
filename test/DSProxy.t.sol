// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Test.sol";

import {HomemadeBroochNFT} from "src/HomemadeBroochNFT.sol";
import {FactoryRegistry} from "src/FactoryRegistry.sol";
import {DSAuthority} from "src/DS/DSAuthority.sol";
import {DSProxyFactory} from "src/DS/DSProxyFactory.sol";
import {DSProxy} from "src/DS/DSProxy.sol";

contract DSProxyTest is Test {
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

        DSAuthority authority = new DSAuthority(owner);
        DSProxyFactory proxyFactory = new DSProxyFactory(address(authority));
        registry = new FactoryRegistry(owner, address(nft), address(proxyFactory));

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
        nft.mintBatch{ value: 10 ether }(user, ids, values, "");

        vm.prank(user);
        registry.createProxy();
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

    function test_RevertExecuteNotAuthority() public {
        _deploy();
        _mintBroochAndCreateProxy();

        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(unauthUser);
        vm.expectRevert("DSAuth: access denied");
        proxy.execute(address(20), "");
    }

    function test_Execute() public {
        _deploy();
        _mintBroochAndCreateProxy();

        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(user);
        vm.expectCall(address(nft), abi.encodeCall(nft.balanceOf, (user, 1)));
        proxy.execute(address(nft), abi.encodeCall(nft.balanceOf, (user, 1))); // delegate calls can't return varlable length data so don't check
    }

    function test_RevertSetTransactionWhenNotOwner() public {
        _deploy();
        _mintBroochAndCreateProxy();

        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(unauthUser);
        vm.expectRevert("DSAuth: access denied");
        proxy.setTransaction(0, address(0), "");
    }

    function test_SetTransaction() public {
        _deploy();
        _mintBroochAndCreateProxy();

        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(user);
        proxy.setTransaction(0, address(0), "");
        DSProxy.Transaction[] memory transactions = proxy.getAllSavedTransactions();
        assertEq(transactions.length, 1);
        assertEq(proxy.getTransactionCount(), 1);
    }

    function test_SetMultipleTransactions() public {
        _deploy();
        _mintBroochAndCreateProxy();

        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));

        bytes[] memory data = new bytes[](2);
        data[0] = abi.encodeWithSelector(proxy.setTransaction.selector, 0, address(0), "");
        data[1] = abi.encodeWithSelector(proxy.setTransaction.selector, 1, address(0), "");
        
        vm.prank(user);
        proxy.multicall(data);
        DSProxy.Transaction[] memory transactions = proxy.getAllSavedTransactions();
        assertEq(transactions.length, 2);
        assertEq(proxy.getTransactionCount(), 2);
    }

    function test_SetTransactionOverwritesExisting() public {
        _deploy();
        _mintBroochAndCreateProxy();

        DSProxy proxy = DSProxy(payable(registry.proxyAddressOfOwnerByIndex(user, 0)));
        vm.prank(user);
        proxy.setTransaction(0, address(0), "");
        vm.prank(user);
        proxy.setTransaction(1, address(1), "");
        vm.prank(user);
        proxy.setTransaction(0, address(2), "");
        DSProxy.Transaction[] memory transactions = proxy.getAllSavedTransactions();
        assertEq(transactions.length, 2);
        assertEq(proxy.getTransactionCount(), 2);
        assertEq(transactions[0].to, address(2));
    }
}
