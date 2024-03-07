// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import {EPAuth} from "./EPAuth.sol";
import {EPAuthority} from "./EPAuthority.sol";
import {IEPProxy} from "./IEPProxy.sol";

// EPProxy
// Allows code execution using a persistant identity This can be very
// useful to execute a sequence of atomic actions. Since the owner of
// the proxy can be changed, this allows for dynamic ownership models
// i.e. a multisig
contract EPProxy is EPAuth, ERC1155Holder, Multicall, IEPProxy, Initializable {

    error ZeroAddress();

    mapping(uint256 order => Transaction transaction) private _transactions; // owner set transactions to be executed by any keeper
    uint256 private _transactionCount;
    bool private _paused;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address _authority) external override initializer {
        owner = _owner;
        _paused = true;
        authority = EPAuthority(_authority);
    }

    function execute(address _target, bytes memory _data) public payable override auth {
        if (_target == address(0x0)) {
            revert ZeroAddress();
        }

        (bool success, bytes memory response) = _target.call(_data);
        require(success, string(response));
    }

    // use if you need to call an action contract
    function executeDelegate(address _target, bytes memory _data) public payable override auth {
        if (_target == address(0x0)) {
            revert ZeroAddress();
        }

        (bool success, bytes memory response) = _target.delegatecall(_data);
        require(success, string(response));
    }

    // can be called by the owner to add a transaction to the execution array (use multicall to add multiple transactions)
    function setTransaction(uint256 _order, address _to, bytes memory _data) public override auth {
        _transactions[_order] = Transaction(_to, _data);
        if (_order + 1 > _transactionCount) {
            _transactionCount = _order + 1;
        }
    }

    function getAllSavedTransactions() public view override returns (Transaction[] memory) {
        Transaction[] memory transactions = new Transaction[](_transactionCount);
        for (uint256 i = 0; i < _transactionCount; i++) {
            transactions[i] = _transactions[i];
        }
        return transactions;
    }

    function setPaused(bool paused) public override auth {
        _paused = paused;
    }

    function getTransactionCount() public view override returns (uint256) {
        return _transactionCount;
    }

    function isPaused() public view override returns (bool) {
        return _paused;
    }

    receive() external payable {}
}
