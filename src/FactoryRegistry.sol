// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {UUPSUpgradeable} from "@oz-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import {OwnableUpgradeable} from "@oz-upgradeable/contracts/access/OwnableUpgradeable.sol";
import {MulticallUpgradeable} from "@oz-upgradeable/contracts/utils/MulticallUpgradeable.sol";
import {IHomemadeBroochNFT} from "./interfaces/IHomemadeBroochNFT.sol";
import {EPProxyFactory} from "./proxy/EPProxyFactory.sol";
import {IEPProxy} from "./proxy/IEPProxy.sol";

contract FactoryRegistry is UUPSUpgradeable, OwnableUpgradeable, MulticallUpgradeable {
    IHomemadeBroochNFT private _homemadeBrooch;
    EPProxyFactory private _proxyFactory;

    mapping(address => mapping(uint256 => address)) private _ownedProxyAddresses;
    mapping(address => uint256) private _ownedAddressIndex;
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
        require(_ownedProxyAddresses[msg.sender][index] == proxy, "FactoryRegistry: not owned proxy");
        _;
    }

    function createProxy() public {
        require(_homemadeBrooch.balanceOf(msg.sender, 1) > 0, "FactoryRegistry: no ruby brooch");
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

    fallback() external payable {}

    receive() external payable {}

    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
