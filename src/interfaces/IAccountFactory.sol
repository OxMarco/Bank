// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

interface IAccountFactory {
    struct Limit {
        uint256 transactional;
        uint256 card;
    }

    function owner() external view returns (address);

    function accounts(uint256 id) external view returns (address);

    event LimitsUpdated(address indexed token, Limit newLimit);
    event NewAccountCreated(uint256 indexed id, address indexed account);
    error AlreadyExists();
}
