// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAccountFactory } from "./interfaces/IAccountFactory.sol";
import { Account } from "./Account.sol";

/**
 * @notice A factory contract to create Accounts
 */
contract AccountFactory is IAccountFactory, Ownable {
    mapping(address => Limit) public defaultLimits;
    mapping(uint256 => address) public override accounts;

    function owner() public view override(IAccountFactory, Ownable) returns (address) {
        return Ownable.owner();
    }

    function setLimits(address token, Limit memory newLimit) external onlyOwner {
        defaultLimits[token] = newLimit;

        emit LimitsUpdated(token, newLimit);
    }

    function createAccount(uint256 id, Account.Type accountType, address user) external onlyOwner returns (address) {
        if (accounts[id] != address(0)) revert AlreadyExists();

        address account = address(new Account{ salt: keccak256(abi.encodePacked(id)) }(id, accountType, user));
        accounts[id] = account;

        emit NewAccountCreated(id, account);

        return (account);
    }
}
