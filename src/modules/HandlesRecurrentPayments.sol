// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract HandlesRecurrentPayments {
    using SafeERC20 for IERC20;

    enum Frequency {
        DAILY,
        WEEKLY,
        BIWEEKLY,
        MONTHLY
    }

    struct RecurrentPayment {
        address destination;
        address token;
        uint256 amount;
        Frequency frequency;
        uint256 latest;
        bool active;
    }

    mapping(bytes32 => RecurrentPayment) public recurrentPayments;

    event RecurrentPaymentCreated(
        bytes32 indexed id,
        address indexed destination,
        address token,
        uint256 amount,
        uint256 frequency
    );
    event RecurrentPaymentStatusUpdated(bytes32 indexed id, bool active);
    event RecurrentPaymentDeleted(bytes32 indexed id);

    error PaymentInactive();
    error TooEarly();
    error PaymentDoesNotExist();
    error AlreadyExists();
    error InsufficientBalance();

    modifier exists(bytes32 id) {
        if (recurrentPayments[id].destination == address(0)) revert PaymentDoesNotExist();
        _;
    }

    function getFrequency(Frequency frequency) public pure returns (uint256) {
        if (frequency == Frequency.DAILY) return 1 days;
        if (frequency == Frequency.WEEKLY) return 1 weeks;
        if (frequency == Frequency.BIWEEKLY) return 2 weeks;
        if (frequency == Frequency.MONTHLY) return 30 days;
        return 0;
    }

    function create(RecurrentPayment memory payment) external returns (bytes32) {
        // basic checks
        assert(payment.destination != address(0));
        assert(payment.token != address(0));
        assert(payment.amount > 0);

        // does not exist already
        bytes32 id = keccak256(abi.encodePacked(payment.destination, payment.token, payment.amount, payment.frequency));
        if (recurrentPayments[id].destination != address(0)) revert AlreadyExists();

        recurrentPayments[id] = RecurrentPayment({
            destination: payment.destination,
            token: payment.token,
            amount: payment.amount,
            frequency: payment.frequency,
            latest: 0,
            active: true
        });

        emit RecurrentPaymentCreated(
            id,
            payment.destination,
            payment.token,
            payment.amount,
            getFrequency(payment.frequency)
        );

        return id;
    }

    function toggle(bytes32 id) external exists(id) {
        recurrentPayments[id].active = !recurrentPayments[id].active;

        emit RecurrentPaymentStatusUpdated(id, recurrentPayments[id].active);
    }

    function remove(bytes32 id) external exists(id) {
        delete recurrentPayments[id];

        emit RecurrentPaymentDeleted(id);
    }

    function exec(bytes32 id) external exists(id) {
        RecurrentPayment storage payment = recurrentPayments[id];
        if (!payment.active) revert PaymentInactive();

        if (block.timestamp - payment.latest < getFrequency(payment.frequency)) revert TooEarly();

        IERC20 token = IERC20(payment.token);
        if (token.balanceOf(address(this)) < payment.amount) revert InsufficientBalance();
        payment.latest = block.timestamp;
        IERC20(payment.token).safeTransfer(payment.destination, payment.amount);
    }
}
