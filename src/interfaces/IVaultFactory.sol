// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

interface IVaultFactory {
    function vaults(address user, uint index) external view returns (address);

    function createVault(string memory name, address[] memory operators) external returns (address);
}
