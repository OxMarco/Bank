// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { IAccountFactory } from "./interfaces/IAccountFactory.sol";
import { IAccount } from "./interfaces/IAccount.sol";

/**
 * @notice An account is a contract that can hold funds and execute transactions
 */
contract Account is IAccount {
    using EnumerableSet for EnumerableSet.AddressSet;

    IAccountFactory public immutable factory;
    uint256 public immutable override id;
    Type public immutable override accountType;

    Status public override status;
    uint256 public override numConfirmationsRequired;
    Transaction[] public override transactions;

    // mapping from tx index => owner => bool
    mapping(uint256 => mapping(address => bool)) internal _isConfirmed;
    EnumerableSet.AddressSet internal _operators;

    constructor(uint256 _id, Type _type, address _user) {
        factory = IAccountFactory(msg.sender);
        id = _id;
        accountType = _type;
        status = Status.ACTIVE;
        numConfirmationsRequired = 1;

        _operators.add(_user);

        emit OperatorAdded(_user);
    }

    modifier onlyOwner() {
        if (msg.sender != factory.owner()) revert RestrictedToOwner();
        _;
    }

    modifier onlyOperator() {
        if (!_operators.contains(msg.sender)) revert RestrictedToOperator();
        _;
    }

    modifier whenActive() {
        if (status != Status.ACTIVE) revert Inactive();
        _;
    }

    modifier selfInvoked() {
        if (msg.sender != address(this)) revert RequiresSelfCall();
        _;
    }

    receive() external payable {
        emit ValueReceived(msg.sender, msg.value);
    }

    function name() external view returns (string memory) {
        string memory buffer = string(abi.encodePacked("Account #", Strings.toString(id)));

        if (accountType == Type.BUSINESS) {
            buffer = string(abi.encodePacked("Business ", buffer));
        }

        return buffer;
    }

    /////////// ADMIN FUNCTIONS ///////////

    function updateStatus(Status newStatus) external onlyOwner {
        status = newStatus;

        emit AccountStatusUpdated(id, newStatus);
    }

    /////////// MANAGEMENT FUNCTIONS ///////////

    function setConfirmationsRequired(uint256 confirmations) external selfInvoked {
        assert(confirmations > 0 && confirmations <= _operators.length());

        numConfirmationsRequired = confirmations;

        emit QuorumUpdated(confirmations);
    }

    function addOperator(address operator) external selfInvoked {
        assert(!_operators.contains(operator));

        _operators.add(operator);

        emit OperatorAdded(operator);
    }

    function removeOperator(address operator) external selfInvoked {
        assert(_operators.contains(operator));

        _operators.remove(operator);

        emit OperatorRemoved(operator);
    }

    /////////// MULTISIG FUNCTIONS ///////////

    function createTransaction(
        address to,
        uint256 value,
        bytes memory data
    ) external onlyOperator whenActive returns (uint256) {
        uint256 txIndex = transactions.length;

        transactions.push(Transaction({ to: to, value: value, data: data, executed: false, numConfirmations: 0 }));

        emit TransactionCreated(msg.sender, txIndex, to, value, data);

        return txIndex;
    }

    function confirmTransaction(uint256 txIndex) external onlyOperator whenActive {
        if (txIndex > transactions.length) revert InvalidTransaction();
        if (transactions[txIndex].executed) revert TransactionAlreadyExecuted();
        if (_isConfirmed[txIndex][msg.sender]) revert TransactionAlreadyConfirmed();

        Transaction storage transaction = transactions[txIndex];
        transaction.numConfirmations += 1;
        _isConfirmed[txIndex][msg.sender] = true;

        if (transaction.numConfirmations >= numConfirmationsRequired) {
            transaction.executed = true;
            (bool success, bytes memory data) = _executeTransaction(transaction);
            if (!success) {
                emit TransactionFailed(txIndex, data);
            } else {
                emit TransactionExecuted(txIndex, data);
            }
        } else {
            emit TransactionConfirmed(msg.sender, txIndex);
        }
    }

    function _executeTransaction(Transaction memory transaction) internal returns (bool, bytes memory) {
        return transaction.to.call{ value: transaction.value }(transaction.data);
    }
}
