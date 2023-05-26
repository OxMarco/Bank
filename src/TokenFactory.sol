// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Token } from "./Token.sol";

/**
 * @notice A token factory is a contract that creates Tokens
 */
contract TokenFactory is Ownable {
    address public accountFactory;
    address public sanctionList;
    address public reserveFeed;

    event NewTokenCreated(address indexed token, string indexed name, string indexed symbol, uint16 isoCode);

    constructor(address _accountFactory, address _sanctionList, address _reserveFeed) {
        accountFactory = _accountFactory;
        sanctionList = _sanctionList;
        reserveFeed = _reserveFeed;
    }

    function setAccountFactory(address _accountFactory) external onlyOwner {
        accountFactory = _accountFactory;
    }

    function setSanctionList(address _sanctionList) external onlyOwner {
        sanctionList = _sanctionList;
    }

    function setReserveFeed(address _reserveFeed) external onlyOwner {
        reserveFeed = _reserveFeed;
    }

    function createToken(
        string memory name,
        string memory symbol,
        uint16 isoCode
    ) external onlyOwner returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(name, symbol, isoCode));
        address token = address(
            new Token{ salt: salt }(name, symbol, isoCode, accountFactory, sanctionList, reserveFeed)
        );

        emit NewTokenCreated(token, name, symbol, isoCode);

        return (token);
    }
}
