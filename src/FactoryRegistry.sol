// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import {IHomemadeBroochNFT} from "./interfaces/IHomemadeBroochNFT.sol";
import {EPProxyFactory} from "./proxy/EPProxyFactory.sol";
import {IEPProxy} from "./proxy/IEPProxy.sol";

contract FactoryRegistry is UUPSUpgradeable, OwnableUpgradeable, MulticallUpgradeable {

    error NotProxyOwner(address, address);
    error NoRubyBrooch(address);

    IHomemadeBroochNFT private _homemadeBrooch;
    EPProxyFactory private _proxyFactory;

    mapping(address owner => mapping(uint256 proxyId => address proxy)) private _ownedProxyAddresses;
    mapping(address proxy => uint256 proxyId) private _ownedAddressIndex;
    uint256 private _addressCount;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address homemadeBrooch, address proxyFactory) external initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(_owner);
        __Multicall_init();

        _homemadeBrooch = IHomemadeBroochNFT(homemadeBrooch);
        _proxyFactory = EPProxyFactory(proxyFactory);
    }

    modifier proxyOwner(address proxy) {
        uint256 index = _ownedAddressIndex[proxy];
        if(_ownedProxyAddresses[msg.sender][index] != proxy) {
            revert NotProxyOwner(msg.sender, proxy);
        }
        _;
    }

    function createProxy() public {
        if(_homemadeBrooch.balanceOf(msg.sender, 1) == 0) {
            revert NoRubyBrooch(msg.sender);
        }
        IEPProxy proxy = IEPProxy(_proxyFactory.build(address(this)));

        _ownedProxyAddresses[msg.sender][_addressCount] = address(proxy);
        _ownedAddressIndex[address(proxy)] = _addressCount;
        _addressCount++;
    }

    function executeSavedTransactions(address proxy) public payable {
        IEPProxy EPProxy = IEPProxy(proxy);
        IEPProxy.Transaction[] memory transactions = EPProxy.getAllSavedTransactions();
        uint256 count = EPProxy.getTransactionCount();
        for (uint256 i = 0; i < count; i++) {
            EPProxy.execute{value: msg.value}(transactions[i].to, transactions[i].data);
        }
    }

    function execute(address proxy, address target, bytes memory data) public payable proxyOwner(proxy) {
        IEPProxy(proxy).execute{value: msg.value}(target, data);
    }

    function setTransaction(address proxy, uint256 order, address to, bytes memory data) public proxyOwner(proxy) {
        IEPProxy(proxy).setTransaction(order, to, data);
    }

    function proxyAddressOfOwnerByIndex(address owner, uint256 index) public view returns (address) {
        return _ownedProxyAddresses[owner][index];
    }

    function totalAddressCount() public view returns (uint256) {
        return _addressCount;
    }

    function transferProxyOwner(address proxy, address newOwner) public proxyOwner(proxy) {
        uint256 index = _ownedAddressIndex[proxy];
        _ownedProxyAddresses[newOwner][index] = proxy;
        _ownedProxyAddresses[msg.sender][index] = address(0);
    }

    receive() external payable {}

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
