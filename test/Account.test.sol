// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Test } from "forge-std/Test.sol";
import { IAccount, Account } from "../src/Account.sol";
import { IAccountFactory, AccountFactory } from "../src/AccountFactory.sol";

contract AccountTest is Test {
    AccountFactory public immutable factory;
    Account public immutable userAccount;
    Account public immutable businessAccount;

    address public constant USER = address(uint160(uint(keccak256(abi.encodePacked("USER")))));
    address public constant BUSINESS_OWNER = address(uint160(uint(keccak256(abi.encodePacked("BUSINESS_OWNER")))));
    address public constant OPERATOR1 = address(uint160(uint(keccak256(abi.encodePacked("OPERATOR1")))));
    address public constant OPERATOR2 = address(uint160(uint(keccak256(abi.encodePacked("OPERATOR2")))));

    constructor() {
        factory = new AccountFactory();
        userAccount = Account(payable(factory.createAccount(0, IAccount.Type.PERSONAL, USER)));
        businessAccount = Account(payable(factory.createAccount(1, IAccount.Type.BUSINESS, BUSINESS_OWNER)));
    }

    function testAccountCreation() public {
        address accountContract = factory.createAccount(2, IAccount.Type.BUSINESS, BUSINESS_OWNER);
        assertTrue(accountContract != address(0));

        IAccount account = IAccount(accountContract);
        assertTrue(account.id() == 2);
        assertTrue(account.accountType() == IAccount.Type.BUSINESS);
        assertTrue(account.status() == IAccount.Status.ACTIVE);
        assertTrue(account.numConfirmationsRequired() == 1);
    }

    function testSameIDAccountCreationFails() public {
        uint256 id = 5;

        factory.createAccount(id, IAccount.Type.BUSINESS, address(this));
        vm.expectRevert(IAccountFactory.AlreadyExists.selector);
        factory.createAccount(id, IAccount.Type.PERSONAL, address(this));
    }

    function testAccountValueTransfer() public {
        vm.deal(address(this), 1 ether);

        (bool success, ) = address(userAccount).call{ value: 1 ether }("");
        assertTrue(success);
        assertTrue(address(userAccount).balance == 1 ether);
    }

    function testAccountName() public {
        uint256 userAccountId = userAccount.id();
        string memory userAccountName = string.concat("Account #", Strings.toString(userAccountId));
        assertTrue(Strings.equal(userAccount.name(), userAccountName));

        uint256 businessAccountId = businessAccount.id();
        string memory businessAccountName = string.concat("Business Account #", Strings.toString(businessAccountId));
        assertTrue(Strings.equal(businessAccount.name(), businessAccountName));
    }

    function testAccountModifiers() public {
        vm.expectRevert(IAccount.RequiresSelfCall.selector);
        businessAccount.setConfirmationsRequired(2);

        vm.startPrank(BUSINESS_OWNER);
        vm.expectRevert(IAccount.RestrictedToOwner.selector);
        businessAccount.updateStatus(IAccount.Status.BANNED);
        vm.stopPrank();
    }

    function testAccountSendETH() public {
        vm.startPrank(BUSINESS_OWNER);
        _createTransaction(businessAccount, address(OPERATOR1), 1 ether, "0x");
        vm.stopPrank();

        assertTrue(address(OPERATOR1).balance == 1 ether);
    }

    function testAccountChangeOperators() public {
        bytes memory transaction1 = abi.encodeWithSignature("addOperator(address)", OPERATOR1);
        bytes memory transaction2 = abi.encodeWithSignature("addOperator(address)", OPERATOR2);
        bytes memory transaction3 = abi.encodeWithSignature("setConfirmationsRequired(uint256)", 3);

        vm.startPrank(BUSINESS_OWNER);
        _createTransaction(businessAccount, address(businessAccount), 0, transaction1);
        _createTransaction(businessAccount, address(businessAccount), 0, transaction2);
        _createTransaction(businessAccount, address(businessAccount), 0, transaction3);
        vm.stopPrank();

        assertTrue(businessAccount.numConfirmationsRequired() == 3);
    }

    function testAccountCannotTransactWhenInactive() public {
        businessAccount.updateStatus(IAccount.Status.BANNED);

        vm.startPrank(BUSINESS_OWNER);
        vm.expectRevert(IAccount.Inactive.selector);
        businessAccount.createTransaction(address(this), 0, "0x");
        vm.stopPrank();
    }

    function testAccountTransactionRequiringQuorum(uint8 n) public {
        address[] memory operators = new address[](n);
        for (uint64 i = 1; i <= n; i++) operators[i - 1] = address(uint160(uint256(keccak256(abi.encodePacked(i)))));

        address sink = address(uint160(uint256(keccak256(abi.encodePacked("SINK")))));
        assertTrue(sink.balance == 0);

        vm.startPrank(BUSINESS_OWNER);
        _updateConfirmations(businessAccount, operators, operators.length + 1);
        uint256 txId = _createTransaction(businessAccount, sink, 1 ether, "0x");
        vm.stopPrank();

        for (uint256 i = 0; i < operators.length; i++) {
            vm.prank(operators[i]);
            businessAccount.confirmTransaction(txId);
        }

        assertTrue(sink.balance == 1 ether);
        assertTrue(businessAccount.numConfirmationsRequired() == operators.length + 1);
        (address to, , , , uint256 confirmations) = businessAccount.transactions(txId);
        assertTrue(to == sink);
        assertTrue(confirmations == operators.length + 1);
    }

    function _createTransaction(
        Account account,
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (uint256) {
        vm.deal(address(account), value);
        uint256 txId = account.createTransaction(to, value, data);
        account.confirmTransaction(txId);

        return txId;
    }

    function _updateConfirmations(Account account, address[] memory operators, uint256 quorum) internal {
        for (uint8 i = 0; i < operators.length; i++) {
            bytes memory operatorTx = abi.encodeWithSignature("addOperator(address)", operators[i]);
            _createTransaction(account, address(account), 0, operatorTx);
        }

        bytes memory quorumTx = abi.encodeWithSignature("setConfirmationsRequired(uint256)", quorum);
        _createTransaction(account, address(account), 0, quorumTx);
    }
}
