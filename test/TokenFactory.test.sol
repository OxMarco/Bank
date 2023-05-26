// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";
import { Token } from "../src/Token.sol";
import { TokenFactory } from "../src/TokenFactory.sol";

contract TokenFactoryTest is Test {
    TokenFactory public immutable factory;

    constructor() {
        factory = new TokenFactory(address(0), address(0), address(0));
    }

    function testTokenCreation(string memory name, string memory symbol, uint16 isoCode) public {
        address tokenContract = factory.createToken(name, symbol, isoCode);
        assertTrue(tokenContract != address(0));

        Token token = Token(tokenContract);
        assertTrue(Strings.equal(token.name(), name));
        assertTrue(Strings.equal(token.symbol(), symbol));
        assertTrue(token.isoCode() == isoCode);
        assertTrue(token.totalSupply() == 0);
    }
}
