// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
 
import "@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol";
 
contract Casino is VRFV2WrapperConsumerBase {
 
    uint256 public result;
    uint256 public balance;
    uint256 public winningAmount;
    uint256 public currentGameBalance;
    // Make owner private.
    address public owner;
    address public winner;
    bool public isFull;
    bool public isStarted;
    bool public isFinnished;
    // Tracks how many times an address has played.
    mapping(address => uint256) public players;
    // Tracks how many times an address has won. Implement a function that mints an NFT on X wins. With the NFT you can enter a specific game.
    mapping(address => uint256) public playerWins;
    // Tracks the predictions of the players in the current game
    mapping(address => uint256) public playerPrediction;
    mapping(uint256 => GameStatus) public statuses;
    // Mapping to track who is the closest to the given number
    mapping(int256 => address) public differencePlayers;
    // The winning amount that the player has to withdraw
    mapping(address => uint256) public playerWonAmount;
    address[] public currentPlayers;
    uint256[] public predictions;
    uint128 constant entryFees = 0.00001 ether;
    uint32 constant callbackGasLimit = 1_000_000;
    uint32 constant numWords = 1;
    uint16 constant requestConfirmations = 3;
 
    address constant linkAddress = 0x779877A7B0D9E8603169DdbD7836e478b4624789;
    address constant vrfWrapperAddress = 0xab18414CD93297B0d12ac29E63Ca20f515b3DB46;

    event PlayerPrediction(address, uint256);
    event Winner(address winnerAdr, uint256 winningNumber);
 
    struct GameStatus {
        uint256 fees;
        uint256 randomNumber;
        address winner;
        uint256 winnerGuess;
        bool fulfilled;
    }
 
   constructor() payable VRFV2WrapperConsumerBase(linkAddress, vrfWrapperAddress) {
    owner = msg.sender;
 
}
 
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
 
    function enterGame(uint256 prediction) external payable {  
        require(msg.value == entryFees, "0.1 ether required");
        require(!isFull, "Lobby is full");
        require(prediction <= 100, "100 is the max guess");
        require(playerPrediction[msg.sender] == 0, "Player has already entered");
         for(uint256 i = 0; i < predictions.length; i++) {
            if(predictions[i] == prediction) {
                revert("Number already predicted");
            }
        }
        predictions.push(prediction);
        balance += entryFees;
        currentGameBalance += entryFees;
        playerPrediction[msg.sender] = prediction;
        players[msg.sender]++;
        currentPlayers.push(msg.sender);
        emit PlayerPrediction(msg.sender, prediction);
        if(currentPlayers.length == 4) {
            isFull = true;
        }
    }
 
    function startGame() external onlyOwner returns(uint256) {
        require(isFull, "Lobby isn't filled");
         require(!isStarted, "Game already started");
        uint256 requestId = requestRandomness(
            callbackGasLimit,
            requestConfirmations,
            numWords
        );
        statuses[requestId] = GameStatus({
            fees: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
            randomNumber: 0,
            winner: address(0),
            winnerGuess: 0,
            fulfilled: false
        });
        uint256 commissionPercentage = 90;
        winningAmount = currentGameBalance * commissionPercentage / 100;
        isStarted = true;
        return requestId;
    }
 
    // Find the address that bet the closest to the given number and then give him the option to withdraw the money
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        require(statuses[requestId].fees > 0, "Request not found");
        require(isStarted, "Game has not started");

        uint256 randomNumber = randomWords[0] % 100;
        result = randomNumber; 

        statuses[requestId].fulfilled = true;
        statuses[requestId].randomNumber = result;
 
        int256 currentLowestNumber;
        int256 lowestNumber = 100;
        fillArray();

        for(uint256 i = 0; i < currentPlayers.length - 1; i++) {
 
            int256 differenceOne = int256(result) - int256(playerPrediction[currentPlayers[i]]);
            int256 differenceTwo = int256(result) - int256(playerPrediction[currentPlayers[i + 1]]);
            if(differenceOne < 0) {
                differenceOne = differenceOne -(differenceOne) -(differenceOne);
            }
            if(differenceTwo < 0) {
                differenceTwo = differenceTwo -(differenceTwo) -(differenceTwo);
            }
 
            if(differenceOne > differenceTwo) {
                winner = currentPlayers[i + 1];
                currentLowestNumber = differenceTwo;
            }
            if(differenceOne < differenceTwo) {
                winner = currentPlayers[i];
                currentLowestNumber = differenceOne;

            if(currentLowestNumber < lowestNumber) {
                lowestNumber = currentLowestNumber;
            }
        }
        winner = differencePlayers[lowestNumber];
        statuses[requestId].winner = winner;
        statuses[requestId].winnerGuess = playerPrediction[winner];
        statuses[requestId].randomNumber = randomNumber;
        playerWonAmount[winner] += winningAmount;
        playerWins[winner]++;
        isFinnished = true;
        emit Winner(winner, result);
        }
    }

    function withdrawMoney() public {
        uint256 amount = playerWonAmount[msg.sender];
        require(amount > 0, "Nothing to withdraw");
        balance -= amount;
        playerWonAmount[msg.sender] = 0;
        (bool success,) = payable(winner).call{value: amount}(""); 
        require(success, "Not successful");
    }

    function resetGame() onlyOwner public {
        require(isFinnished, "Game is not finnished");
        result = 0;
        currentGameBalance = 0;
        winningAmount = 0;
        winner = address(0);
        isFull = false;
        isStarted = false;
        isFinnished = false;
        for(uint256 i = 0; i < 4; i++) {
            delete playerPrediction[currentPlayers[i]];
            delete differencePlayers[int(i)];
        }
        delete currentPlayers;
    }

    function fillArray() internal {
        for(uint256 i = 0; i < currentPlayers.length - 1; i++) {
            int256 differenceOne = int256(result) - int256(playerPrediction[currentPlayers[i]]);
            int256 differenceTwo = int256(result) - int256(playerPrediction[currentPlayers[i + 1]]);
             if(differenceOne < 0) {
                differenceOne = differenceOne -(differenceOne) -(differenceOne);
            }
            if(differenceTwo < 0) {
                differenceTwo = differenceTwo -(differenceTwo) -(differenceTwo);
            }
            differencePlayers[differenceOne] = currentPlayers[i];
            differencePlayers[differenceTwo] = currentPlayers[i + 1];
        }
    }
 
    function getStatus(uint256 requestId) public view returns(GameStatus memory) {
        return statuses[requestId];
    } 

    function getPlayerInArr(uint256 _i) public view returns(address) {
        return currentPlayers[_i];
    }
    
    function getCurrentPlayersArrLength() public view returns(uint256) {
        return currentPlayers.length;
    }

    receive() external payable {
        balance += msg.value;
    }
}
      
