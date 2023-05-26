// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { Base } from "./Base.script.sol";
import { AccountFactory } from "../src/AccountFactory.sol";

contract DeployAccountFactory is Base {
    AccountFactory public factory;

    function _run() internal override {
        factory = new AccountFactory();
        assert(address(factory) != address(0));
    }
}
