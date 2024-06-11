// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; 

library PriceConverter{

    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {
        // ETH/USDT 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // ABI 
        (, int256 price ,,,) = priceFeed.latestRoundData();
        // price of ETH in terms of USD, ETH has 8 decimal
        return uint256(price) * 1e10; //adding 10 decimal to comprehend the 18 decimal point on ETH to Wei
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns(uint256) {
        // 1 ETH let's say around 2000.000000000000000000
        uint256 ethPrice = getPrice(priceFeed);
        // ( 2000_000000000000000000 * 1_000000000000000000 ) / 1e18
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18; // ALWAYS MULTIPLY BEFORE DIVIDING IN SOLIDITY
        return ethAmountInUsd;
    }

}