// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Test } from "forge-std/Test.sol";
import { Token } from "../src/Token.sol";
import { SanctionList } from "../src/SanctionList.sol";
import { Oracle } from "./helpers/Oracle.sol";

contract TokenTest is Test {
    using SafeERC20 for Token;

    SanctionList public immutable sanctionList;
    Oracle public immutable oracle;
    Token public immutable token;

    address public constant USER1 = address(uint160(uint(keccak256(abi.encodePacked("USER1")))));
    address public constant USER2 = address(uint160(uint(keccak256(abi.encodePacked("USER2")))));
    address public constant USER3 = address(uint160(uint(keccak256(abi.encodePacked("USER3")))));

    constructor() {
        sanctionList = new SanctionList();
        oracle = new Oracle();
        token = new Token("Test", "TST", 10, address(0), address(sanctionList), address(oracle));
    }

    function testTransfer(uint256 amount) public {
        token.mint(USER1, amount);
        assertTrue(token.balanceOf(USER1) == amount);

        vm.prank(USER1);
        token.safeTransfer(USER2, amount);

        assertTrue(token.balanceOf(USER1) == 0);
        assertTrue(token.balanceOf(USER2) == amount);
    }

    function testTransferToSanctionedAddress() public {
        uint256 amount = 1e18;
        token.mint(USER1, amount);

        sanctionList.toggleBlacklist(USER2);

        vm.startPrank(USER1);
        vm.expectRevert(abi.encodeWithSelector(Token.Blacklisted.selector, USER2));
        token.transfer(USER2, amount);

        token.safeTransfer(USER3, amount);
        vm.stopPrank();

        assertTrue(token.balanceOf(USER2) == 0);
        assertTrue(token.balanceOf(USER3) == amount);
    }

    function testTransferFromSanctionedAddress() public {
        uint256 amount = 1e18;
        token.mint(USER1, amount);

        sanctionList.toggleBlacklist(USER1);

        vm.prank(USER1);
        vm.expectRevert(abi.encodeWithSelector(Token.Blacklisted.selector, USER1));
        token.transfer(USER2, amount);
    }

    function testInitialCollateralisationRatio() public {
        (uint256 cR, , ) = token.collateralisationRatio();
        assertTrue(cR == 0);
    }

    function testCollateralisationRatio(uint128 amount, uint16 dx) public {
        vm.assume(uint256(amount) + dx < type(uint128).max);
        token.mint(USER1, amount);
        oracle.setVal(amount + dx);

        (uint256 cR, , ) = token.collateralisationRatio();

        if (amount == 0) assertTrue(cR == 0);
        else if (dx == 0) assertTrue(cR == 1);
        else assertTrue(cR < 1);
    }

    function testMinting(uint128 amount, uint16 dx) public {
        vm.assume(uint256(amount) + dx < type(uint128).max);

        oracle.setVal(amount);
        token.mint(USER1, amount);

        if (dx > 0) vm.expectRevert(Token.CollateralRatioImbalance.selector);
        token.mint(USER1, dx);

        (uint256 cR, , ) = token.collateralisationRatio();

        oracle.setVal(amount + dx);
        token.mint(USER1, dx);

        (uint256 newCr, , ) = token.collateralisationRatio();

        assertTrue(newCr >= cR);
    }

    function testBurning(uint128 amount, uint16 dx) public {
        vm.assume(uint256(amount) + dx < type(uint128).max);
        token.mint(USER1, amount);
        oracle.setVal(amount);

        if (dx > 0) vm.expectRevert(Token.CollateralRatioImbalance.selector);
        token.burn(USER1, amount);

        (uint256 cR, , ) = token.collateralisationRatio();

        oracle.setVal(amount + dx);
        if (amount == 0) vm.expectRevert();
        token.burn(USER1, amount);

        (uint256 newCr, , ) = token.collateralisationRatio();

        assertTrue(newCr <= cR);
    }
}
