// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {MulticallUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";
import {IHomemadeBroochNFT} from "./interfaces/IHomemadeBroochNFT.sol";
import {IFactoryRegistryV2} from "./interfaces/IFactoryRegistryV2.sol";
import {EPProxyFactory} from "./proxy/EPProxyFactory.sol";
import {IEPProxy} from "./proxy/IEPProxy.sol";

/// @custom:oz-upgrades-from FactoryRegistryV2
contract FactoryRegistryV3 is UUPSUpgradeable, OwnableUpgradeable, MulticallUpgradeable, IFactoryRegistryV2 {
    error NotProxyOwner(address, address);
    error NoRubyBrooch(address);
    error ProxyPaused(address);

    event Created(address indexed sender, address indexed owner, address proxy, uint256 proxyId);

    IHomemadeBroochNFT private _homemadeBrooch;
    EPProxyFactory private _proxyFactory;

    mapping(address owner => mapping(uint256 proxyId => address proxy)) private _ownedProxyAddresses;
    mapping(address proxy => uint256 proxyId) private _ownedAddressIndex;
    uint256 private _addressCount;

    /// @custom:oz-upgrades-unsafe-allow constructor
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
        if (_ownedProxyAddresses[msg.sender][index] != proxy) {
            revert NotProxyOwner(msg.sender, proxy);
        }
        _;
    }

    function createProxy() public override {
        if (_homemadeBrooch.balanceOf(msg.sender, 1) == 0) {
            revert NoRubyBrooch(msg.sender);
        }
        IEPProxy proxy = IEPProxy(_proxyFactory.build(address(this)));

        _ownedProxyAddresses[msg.sender][_addressCount] = address(proxy);
        _ownedAddressIndex[address(proxy)] = _addressCount;
        emit Created(msg.sender, msg.sender, address(proxy), _addressCount);
        _addressCount++;        
    }

    function executeSavedTransactions(address proxy) public payable override {
        IEPProxy EPProxy = IEPProxy(proxy);
        if (EPProxy.isPaused()) {
            revert ProxyPaused(proxy);
        }
        IEPProxy.Transaction[] memory transactions = EPProxy.getAllSavedTransactions();
        uint256 count = EPProxy.getTransactionCount();
        for (uint256 i = 0; i < count; i++) {
            EPProxy.execute{value: msg.value}(transactions[i].to, transactions[i].data);
        }
    }

    function execute(address proxy, address target, bytes memory data) public payable override proxyOwner(proxy) {
        IEPProxy(proxy).execute{value: msg.value}(target, data);
    }

    function setTransaction(address proxy, uint256 order, address to, bytes memory data)
        public
        override
        proxyOwner(proxy)
    {
        IEPProxy(proxy).setTransaction(order, to, data);
    }

    function setPaused(address proxy, bool paused) public proxyOwner(proxy) {
        IEPProxy(proxy).setPaused(paused);
    }

    function proxyAddressOfOwnerByIndex(address owner, uint256 index) public view override returns (address) {
        return _ownedProxyAddresses[owner][index];
    }

    function indexOfProxy(address proxy) public view override returns (uint256) {
        return _ownedAddressIndex[proxy];
    }

    function totalAddressCount() public view override returns (uint256) {
        return _addressCount;
    }

    function transferProxyOwner(address proxy, address newOwner) public override proxyOwner(proxy) {
        uint256 index = _ownedAddressIndex[proxy];
        _ownedProxyAddresses[newOwner][index] = proxy;
        _ownedProxyAddresses[msg.sender][index] = address(0);
    }

    receive() external payable {}

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
