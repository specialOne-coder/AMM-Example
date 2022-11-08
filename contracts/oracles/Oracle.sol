// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;
    uint256 betIds = 0;

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
    constructor() {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
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

    function getHistoricalPrice(uint80 roundId) public view returns (int256) {
        (, int price, , , ) = priceFeed.getRoundData(roundId);
        return price;
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
