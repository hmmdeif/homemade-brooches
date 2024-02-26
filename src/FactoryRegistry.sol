// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {IHomemadeBroochNFT} from "./interfaces/IHomemadeBroochNFT.sol";
import {DSProxyFactory} from "./DS/DSProxyFactory.sol";
import {IDSProxy} from "./DS/IDSProxy.sol";

contract FactoryRegistry is Ownable, Multicall {

    IHomemadeBroochNFT private _homemadeBrooch;
    DSProxyFactory private _proxyFactory;   

    mapping(address => mapping(uint256 => address)) private _ownedProxyAddresses;
    mapping(address => uint256) private _ownedAddressIndex;
    uint256 private _addressCount;

    constructor(address _owner, address homemadeBrooch, address proxyFactory) Ownable(_owner) {
        _homemadeBrooch = IHomemadeBroochNFT(homemadeBrooch);
        _proxyFactory = DSProxyFactory(proxyFactory);
    }

    function createProxy() public {
        require(_homemadeBrooch.balanceOf(msg.sender, 1) > 0, "FactoryRegistry: no ruby brooch");
        IDSProxy proxy = _proxyFactory.build(address(this));

        _ownedProxyAddresses[msg.sender][_addressCount] = address(proxy);
        _ownedAddressIndex[address(proxy)] = _addressCount;
        _addressCount++;
    }

    function executeSavedTransactions(address proxy) public payable {
        IDSProxy dsProxy = IDSProxy(proxy);
        IDSProxy.Transaction[] memory transactions = dsProxy.getAllSavedTransactions();
        uint256 count = dsProxy.getTransactionCount();
        for (uint256 i = 0; i < count; i++) {
           dsProxy.execute{ value: msg.value }(transactions[i].to, transactions[i].data);
        }
    }

    function setTransaction(address proxy, uint256 order, address to, bytes memory data) public {
        uint256 index = _ownedAddressIndex[proxy];
        require(_ownedProxyAddresses[msg.sender][index] == proxy, "FactoryRegistry: not owned proxy");
        IDSProxy(proxy).setTransaction(order, to, data);
    }

    function proxyAddressOfOwnerByIndex(address owner, uint256 index) public view returns (address) {
        return _ownedProxyAddresses[owner][index];
    }

    function totalAddressCount() public view returns (uint256) {
        return _addressCount;
    }

    function transferProxyOwner(address proxy, address newOwner) public {
        uint256 index = _ownedAddressIndex[proxy];
        require(_ownedProxyAddresses[msg.sender][index] == proxy, "FactoryRegistry: not owned proxy");
        _ownedProxyAddresses[newOwner][index] = proxy;
        _ownedProxyAddresses[msg.sender][index] = address(0);
    }

    fallback() external payable {}

    receive() external payable {}
}