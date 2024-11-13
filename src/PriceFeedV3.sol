// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";


/**
 * THIS IS AN EXAMPLE CONTRACT THAT USES HARDCODED
 * VALUES FOR CLARITY.
 * THIS IS AN EXAMPLE CONTRACT THAT USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

/**W
 * If you are reading data feeds on L2 networks, you must
 * check the latest answer from the L2 Sequencer Uptime
 * Feed to ensure that the data is accurate in the event
 * of an L2 sequencer outage. See the
 * https://docs.chain.link/data-feeds/l2-sequencer-feeds
 * page for details.
 */
 
contract PriceFeedV3 {
    AggregatorV3Interface internal immutable DATAFEED;
    //Need to calculate

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43
     */
    constructor(address ethUsdPairAddress) {
        DATAFEED = AggregatorV3Interface(
            ethUsdPairAddress
        );
    }

    /**
     * Returns the latest answer.
     */
    function getChainlinkDataFeedLatestAnswer() internal view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = DATAFEED.latestRoundData();
        return answer;
    }
    
    function amountToWei(uint256 amount) public view returns (uint256) {
        int256 price = getChainlinkDataFeedLatestAnswer();    
        /**
            Price is aritifically inflated to 10^8, so parameter amount is also inflated
            to 10^8, 
            10^26 = 10^8 + 10^18(Base Wei) 
        */
        uint256 weiValue = ( (amount * (10**26))/uint(price) );

        return weiValue;
    }
}
