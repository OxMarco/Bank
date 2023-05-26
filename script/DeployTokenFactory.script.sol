// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { Base } from "./Base.script.sol";
import { TokenFactory } from "../src/TokenFactory.sol";

contract DeployTokenFactory is Base {
    TokenFactory public factory;
    address public accountFactory = vm.envAddress("ACCOUNT_FACTORY");
    address public sanctionList = vm.envAddress("SANCTION_LIST");
    address public reserveFeed = vm.envAddress("RESERVE_FEED");

    function _run() internal override {
        factory = new TokenFactory(accountFactory, sanctionList, reserveFeed);
        assert(address(factory) != address(0));
    }
}
