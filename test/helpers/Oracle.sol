// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Oracle is AggregatorV3Interface {
    int256 public val;

    function setVal(uint256 _val) external {
        val = SafeCast.toInt256(_val);
    }

    function decimals() external pure override returns (uint8) {
        return 18;
    }

    function description() external pure override returns (string memory) {
        return "Mock Oracle";
    }

    function version() external view override returns (uint256) {
        return block.number;
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, val, 0, block.timestamp, 0);
    }

    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (0, val, 0, block.timestamp, 0);
    }
}
