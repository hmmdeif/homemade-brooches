// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IFactoryRegistryV2 {
    function createProxy() external;
    function executeSavedTransactions(address proxy) external payable;
    function execute(address proxy, address target, bytes memory data) external payable;
    function setTransaction(address proxy, uint256 order, address to, bytes memory data) external;
    function setPaused(address proxy, bool paused) external;
    function proxyAddressOfOwnerByIndex(address owner, uint256 index) external view returns (address);
    function indexOfProxy(address proxy) external view returns (uint256);
    function totalAddressCount() external view returns (uint256);
    function transferProxyOwner(address proxy, address newOwner) external;
}
