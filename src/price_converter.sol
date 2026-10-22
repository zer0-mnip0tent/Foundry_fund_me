// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library priceconverter {
    function getprice(AggregatorV3Interface pricefeed) internal view returns (uint256) {
        (, int256 price,,,) = pricefeed.latestRoundData();
        // price of eth in terms of usd
        return uint256(price * 1e10);
    }

    function getconversionrate(uint256 ethamount, AggregatorV3Interface pricefeed) internal view returns (uint256) {
        uint256 ethprice = getprice(pricefeed);
        uint256 ethamountinusd = (ethprice * ethamount) / 1e18;
        return ethamountinusd;
    }
}
