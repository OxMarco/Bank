// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ISanctionList } from "./interfaces/ISanctionList.sol";

/**
 * @notice A sanction list to blacklist addresses
 */
contract SanctionList is ISanctionList, Ownable {
    mapping(address => bool) public override blacklisted;

    event BlacklistStatusUpdated(address indexed account, bool newStatus);

    function toggleBlacklist(address account) external onlyOwner {
        blacklisted[account] = !blacklisted[account];

        emit BlacklistStatusUpdated(account, blacklisted[account]);
    }
}
