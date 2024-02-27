// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

interface IEPProxy {
    struct Transaction {
        address to;
        bytes data;
    }

    function initialize(address _owner, address _authority) external;
    function execute(address _target, bytes memory _data) external payable;
    function executeDelegate(address _target, bytes memory _data) external payable;
    function getAllSavedTransactions() external view returns (Transaction[] memory);
    function setTransaction(uint256 _order, address _to, bytes memory _data) external;
    function getTransactionCount() external view returns (uint256);
}
