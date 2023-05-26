// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

interface IAccount {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    enum Status {
        ACTIVE,
        SUSPENDED,
        BANNED
    }

    enum Type {
        PERSONAL,
        BUSINESS
    }

    function id() external view returns (uint256);

    function name() external view returns (string memory);

    function accountType() external view returns (Type);

    function status() external view returns (Status);

    function transactions(uint256 txId) external view returns (address, uint256, bytes memory, bool, uint256);

    function numConfirmationsRequired() external view returns (uint256);

    event OperatorAdded(address indexed operator);
    event OperatorRemoved(address indexed operator);
    event AccountStatusUpdated(uint256 indexed id, Status newStatus);
    event QuorumUpdated(uint256 confirmations);
    event ValueReceived(address indexed sender, uint256 amount);
    event TransactionCreated(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event TransactionConfirmed(address indexed owner, uint256 indexed txIndex);
    event TransactionExecuted(uint256 indexed txIndex, bytes data);
    event TransactionFailed(uint256 indexed txIndex, bytes data);
    error RestrictedToOwner();
    error RestrictedToOperator();
    error Inactive();
    error RequiresSelfCall();
    error InvalidTransaction();
    error TransactionAlreadyExecuted();
    error TransactionAlreadyConfirmed();
}
