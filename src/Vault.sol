// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IVault } from "./interfaces/IVault.sol";

/**
 * @notice A vault is a contract that holds funds on behalf of a subset of users.
 * @dev A vault is created by an account and can have multiple operators
 */
contract Vault is IVault {
    using SafeERC20 for IERC20;

    string public override name;
    mapping(address => bool) public override operators;

    constructor(string memory _name, address[] memory _operators) {
        name = _name;

        for (uint256 i = 0; i < _operators.length; i++) {
            operators[_operators[i]] = true;
        }
    }

    modifier onlyOperators() {
        if (!operators[msg.sender]) revert RestrictedToOperators();
        _;
    }

    function send(address token, address to, uint256 amount) external onlyOperators {
        IERC20(token).safeTransfer(to, amount);
    }
}
