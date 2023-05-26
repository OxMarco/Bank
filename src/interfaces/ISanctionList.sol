// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

interface ISanctionList {
    function blacklisted(address account) external view returns (bool);
}
