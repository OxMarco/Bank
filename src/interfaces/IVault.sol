// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

interface IVault {
    function name() external view returns (string memory);

    function operators(address user) external view returns (bool);

    error RestrictedToOperators();
}
