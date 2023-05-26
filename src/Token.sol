// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.19;

import { ERC20, ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IAccountFactory } from "./interfaces/IAccountFactory.sol";
import { ISanctionList } from "./interfaces/ISanctionList.sol";

/**
 * @notice A token represents a fiat currency and is backed by off-chain reserves
 * @dev Chainlink is used to get the amount of the reserves and collateralisation ratio
 *      is enforced on minting and burning
 */
contract Token is ERC20Permit, Ownable {
    uint256 public constant THRESHOLD = 1 days;
    uint16 public immutable isoCode;
    IAccountFactory public immutable accountFactory;
    ISanctionList public immutable sanctionList;
    AggregatorV3Interface public immutable reserveFeed;

    error Blacklisted(address account);
    error CollateralRatioImbalance();

    constructor(
        string memory name,
        string memory symbol,
        uint16 _isoCode,
        address _accountFactory,
        address _sanctionList,
        address _reserveFeed
    ) ERC20(name, symbol) ERC20Permit(name) {
        isoCode = _isoCode;
        accountFactory = IAccountFactory(_accountFactory);
        sanctionList = ISanctionList(_sanctionList);
        reserveFeed = AggregatorV3Interface(_reserveFeed);
    }

    function collateralisationRatio() public view returns (uint256, uint256, uint256) {
        (
            ,
            /*uint80 roundID*/ int256 price,
            ,
            /*uint256 startedAt*/ uint256 timestamp /*uint80 answeredInRound*/,

        ) = reserveFeed.latestRoundData();

        uint256 reserve = SafeCast.toUint256(price);
        // prevent division by zero
        if (reserve == 0) return (0, 0, timestamp);

        return (totalSupply() / reserve, reserve, timestamp);
    }

    ////////// ADMIN //////////

    function mint(address to, uint256 amount) external onlyOwner {
        (uint256 cR, uint256 reserve, uint256 timestamp) = collateralisationRatio();

        if (block.timestamp - timestamp < THRESHOLD && totalSupply() > 0) {
            // check if minting preserves overcollateralisation ratio
            if (cR + amount / reserve > 1) revert CollateralRatioImbalance();
            _mint(to, amount);
        } else {
            // feed has been offline for a while or total supply is zero, allow unchecked minting
            _mint(to, amount);
        }
    }

    function burn(address from, uint256 amount) external onlyOwner {
        // prevent division by zero
        assert(totalSupply() > 0);

        (uint256 cR, uint256 reserve, uint256 timestamp) = collateralisationRatio();

        if (block.timestamp - timestamp < THRESHOLD) {
            // check if burning preserves overcollateralisation ratio
            if (cR - amount / reserve > 1) revert CollateralRatioImbalance();
            _burn(from, amount);
        } else {
            // feed has been offline for a while, allow unchecked burning
            _burn(from, amount);
        }
    }

    ////////// TRANSFERS //////////

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from != address(0) && to != address(0)) {
            if (sanctionList.blacklisted(from)) revert Blacklisted(from);
            if (sanctionList.blacklisted(to)) revert Blacklisted(to);

            /*if(accountFactory.isAccount(from)) {
                if(!IAccount(to).checkLimits(from, amount)) revert ExceedsAccountLimits(from);
            }

            if(accountFactory.isAccount(to)) {
                if(!IAccount(to).checkLimits(to, amount)) revert ExceedsAccountLimits(to);
            }*/
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount) internal override {
        /*if(from != address(0) && to != address(0)) {
            if(accountFactory.isAccount(from)) {
                IAccount(from).increaseLimit(from, amount);
            }

            if(accountFactory.isAccount(to)) {
                IAccount(from).increaseLimit(from, amount);
            }
        }*/

        super._afterTokenTransfer(from, to, amount);
    }
}
