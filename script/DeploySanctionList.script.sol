// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { Base } from "./Base.script.sol";
import { SanctionList } from "../src/SanctionList.sol";

contract DeploySanctionList is Base {
    SanctionList public list;

    function _run() internal override {
        list = new SanctionList();
        assert(address(list) != address(0));
    }
}
