// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";

enum GameState {
    CHALLENGED,
    STARTED,
    CANCELED,
    CHALLENGER_WON,
    CHALLENGEE_WON,
    ABORTED,
    DRAWN
}

struct Game {
    uint verificationBond;
    uint prize;
    address challenger;
    address challengee;
    GameState state;
    bytes data;
}

contract GamingHub {
    mapping(address => uint) public balances;
    mapping(uint => Game) public games;
    uint nextGame = 0;

    constructor() {}

    function challenge(
        address challengee,
        bytes calldata data,
        uint verificationBond,
        uint prize
    ) public payable {
        balances[msg.sender] += msg.value;
        uint cost = verificationBond + prize;

        require(
            balances[msg.sender] >= cost,
            "Insufficient funds"
        );

        balances[msg.sender] -= cost;

        games[nextGame] = Game(
            verificationBond,
            prize,
            msg.sender,
            challengee,
            GameState.CHALLENGED,
            data
        );

        nextGame += 1;
    }

    function accept(uint gameIndex) public payable {
        balances[msg.sender] += msg.value;

        Game memory game = games[gameIndex];

        require(game.challengee == msg.sender);
        require(game.state == GameState.CHALLENGED);

        uint cost = game.verificationBond + game.prize;

        require(balances[msg.sender] >= cost);
        balances[msg.sender] -= cost;

        game.state = GameState.STARTED;
    }

    function cancel(uint gameIndex) public {
        Game memory game = games[gameIndex];

        require(game.challenger == msg.sender);
        require(game.state == GameState.CHALLENGED);

        game.state = GameState.CANCELED;

        payable(msg.sender).transfer(game.verificationBond + game.prize);
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}
