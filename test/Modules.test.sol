// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { ERC20PresetMinterPauser } from "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import { Test } from "forge-std/Test.sol";
import { HandlesRecurrentPayments } from "../src/modules/HandlesRecurrentPayments.sol";

contract ModulesTest is Test {
    HandlesRecurrentPayments public immutable module;
    ERC20PresetMinterPauser public immutable token;
    address public constant PAYEE = address(uint160(uint(keccak256(abi.encodePacked("PAYEE")))));
    uint256 public constant CURRENT_TIMESTAMP = 1684980348;

    constructor() {
        module = new HandlesRecurrentPayments();
        token = new ERC20PresetMinterPauser("Token", "TKN");
    }

    function testRecurrentPaymentFlow() public {
        uint256 amount = 1e18;
        token.mint(address(module), 2 * amount);

        vm.warp(CURRENT_TIMESTAMP);

        HandlesRecurrentPayments.RecurrentPayment memory payment = HandlesRecurrentPayments.RecurrentPayment({
            destination: PAYEE,
            token: address(token),
            amount: amount,
            frequency: HandlesRecurrentPayments.Frequency.MONTHLY,
            latest: 0,
            active: true
        });
        bytes32 id = module.create(payment);

        module.exec(id);
        assertTrue(token.balanceOf(PAYEE) == amount);

        vm.expectRevert(HandlesRecurrentPayments.TooEarly.selector);
        module.exec(id);

        module.toggle(id);
        vm.expectRevert(HandlesRecurrentPayments.PaymentInactive.selector);
        module.exec(id);

        vm.warp(CURRENT_TIMESTAMP + 30 days);
        module.toggle(id);
        module.exec(id);
        assertTrue(token.balanceOf(PAYEE) == 2 * amount);
    }
}
