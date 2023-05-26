// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { IVaultFactory } from "./interfaces/IVaultFactory.sol";
import { Vault } from "./Vault.sol";

/**
 * @notice A vault factory is a contract that creates Vaults
 */
contract VaultFactory is IVaultFactory {
    mapping(address => address[]) public override vaults;

    event VaultCreated(address indexed vault, string name, address creator);

    function createVault(string memory name, address[] memory operators) external override returns (address) {
        address vault = address(new Vault(name, operators));
        vaults[msg.sender].push(vault);

        emit VaultCreated(vault, name, msg.sender);

        return vault;
    }
}
