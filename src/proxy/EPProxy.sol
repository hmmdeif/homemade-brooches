// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.23;

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
    mapping(uint256 => Transaction) private _transactions; // owner set transactions to be executed by any keeper
    uint256 private _transactionCount;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _owner, address _authority) external override initializer {
        owner = _owner;
        authority = EPAuthority(_authority);
    }

    function execute(address _target, bytes memory _data) public payable override auth {
        require(_target != address(0x0), "0A");

        (bool success, bytes memory response) = _target.call(_data);
        require(success, string(response));
    }

    // use if you need to call an action contract
    function executeDelegate(address _target, bytes memory _data) public payable override auth {
        require(_target != address(0x0), "0A");

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

    function getTransactionCount() public view override returns (uint256) {
        return _transactionCount;
    }

    fallback() external payable {}

    receive() external payable {}
}