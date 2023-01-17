// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";


contract Bets is ChainlinkClient, ConfirmedOwner{
    AggregatorV3Interface internal priceFeed;
    uint256 betIds = 0;

    bytes32 private jobId;
    uint256 private fee;

    struct Bet {
        uint256 betAmount;
        int256 futurePrice;
        uint256 time;
    }

    struct Player {
        address payable player;
        int256 pricePrediction;
        uint256 depositAmount;
    }

    // app bet and players
    mapping(uint256 => Bet) public bets;
    mapping(uint256 => Player[]) public players;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */
    constructor() ConfirmedOwner(msg.sender){
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0xCC79157eb46F5624204f47AB42b3906cAA40eaB7);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) 
    }

    // increment
    function _incrementBetId() private {
        betIds++;
    }

    // abs
    function _abs(int x) private pure returns (int) {
        return x >= 0 ? x : -x;
    }

    // closest number
    function _closest(int feed, int[] memory arr) private pure returns (int) {
        int curr = arr[0];
        int diff = _abs(feed - curr);
        for (uint val = 0; val < arr.length; val++) {
            int newdiff = _abs(feed - arr[val]);
            if (newdiff < diff) {
                diff = newdiff;
                curr = arr[val];
            }
        }
        return curr;
    }

    // Return the latest price
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/
            int price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

     function timestampToDate(uint timestamp) public view returns (string memory) {
        uint year = timestamp / (365 * 24 * 60 * 60);
        uint month = timestamp % (365 * 24 * 60 * 60) / (30 * 24 * 60 * 60);
        uint day = timestamp % (30 * 24 * 60 * 60) / (24 * 60 * 60);
        return format("%02d-%02d-%04d",day,month,year);
    }

     function requestVolumeData(uint timestamp) public returns (bytes32 requestId) {
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfill.selector
        );
        

        // Set the URL to perform the GET request on
        req.add(
            "get",
            "https://api.coingecko.com/api/v3/coins/ethereum/history?date=" + timestamp
        );

        // Set the path to find the desired data in the API response, where the response format is:
        // {"RAW":
        //   {"ETH":
        //    {"USD":
        //     {
        //      "VOLUME24HOUR": xxx.xxx,
        //     }
        //    }
        //   }
        //  }
        // request.add("path", "RAW.ETH.USD.VOLUME24HOUR"); // Chainlink nodes prior to 1.0.0 support this format
        req.add("path", "market_data,current_price,ust"); // Chainlink nodes 1.0.0 and later support this format

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10 ** 18;
        req.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    function getHistoricalPrice(uint80 roundId) public view returns (int256,uint) {
        (, int price, ,uint timestamp , ) = priceFeed.getRoundData(roundId);
        require(timestamp > 0, "Round not complete");
        return (price,timestamp);
    }

    // bet on token price
    function createBet(uint time, int256 _pricePrediction) external payable {
        require(
            msg.value > 0 && _pricePrediction > 0,
            "You must send some ETH and predict price"
        );
        Bet memory userBet = Bet(msg.value, _pricePrediction, time);
        bets[betIds] = userBet;
        players[betIds].push(
            Player(payable(msg.sender), _pricePrediction, msg.value)
        );
        _incrementBetId();
    }

    // join bet
    function bet(uint256 _betId, int256 _pricePrediction) external payable {
        require(
            msg.value >= bets[_betId].betAmount,
            "You must bet the same or more amount"
        );
        for (uint i = 0; i < players[_betId].length; i++) {
            require(
                players[_betId][i].player != msg.sender,
                "You already joined this bet"
            );
            require(
                players[_betId][i].pricePrediction != _pricePrediction,
                "You can't bet on the same price"
            );
        }
        players[betIds].push(
            Player(payable(msg.sender), _pricePrediction, msg.value)
        );
    }

    // check bet and claim reward
    function rewards(uint256 _betId) external {
        require(block.timestamp >= bets[_betId].time, "Time is not due yet");
        uint256 reward = 0;
        uint256 length = players[_betId].length;
        int256[] memory _playersBets;
        for (uint256 i = 0; i < length; i++) {
            reward += players[_betId][i].depositAmount;
            _playersBets[i] = players[_betId][i].pricePrediction;
        }
        int clos = _closest(getLatestPrice(), _playersBets);
        for (uint256 i = 0; i < players[_betId].length; i++) {
            if (players[_betId][i].pricePrediction == clos) {
                players[_betId][i].player.transfer(reward);
            }
        }
    }
}
