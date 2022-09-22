// SPDX-License-Identifier: GPL-3.0

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.9;

contract RockPaperScissors {

    /*********************************************
    *    Internal Data Structures and Members
    **********************************************/

    // each player only has these options to play
    enum Choice { None, Rock, Paper, Scissors }

    // address of players (I guess that using a fixed-size array would require less gas)
    address[2] private _players;

    // current player count
    uint256 private _nPlayers;

    // contract deployer/owner
    address private _owner;

    // re-entrancy guard flag
    bool private _locked;

    // map from player to its choice which is hidden in a commitment (hash)
    // the reason for the commitment is that everything is public in most chains
    // we need to find a way to keep the choice of one player hidden from the other one
    // the commitment is gonna be a hash between the player's choice and some secret/keyword
    mapping(address => bytes32) private _commitments;

    // after both players have commited their choice, they will have to provide them again (publicly)
    mapping(address => Choice) private _choices;

    // constant variables are copied to where they are used and its value is fixed at compile time
    // immutable variables are copied to where they are used and its value is set in the constructor
    
    // the amoung of native token to be paid in wei for each player
    uint256 public constant PLAYER_FEE = 1 ether / 100; // 0.01 Eth

    // the winner gets 50% more than what he paid
    // are there floating point types in solidity?
    uint256 public constant WINNERS_REWARD = 3 * PLAYER_FEE / 2; // 0.015 Eth
    
    /*********************************************
    *                   Events
    **********************************************/

    event Committed(address player, bytes32 commitment);
    event Revealed(address player, Choice choice);
    event Winner(address winner);

    /*********************************************
    *                 Modifiers
    **********************************************/

    // only owner modifier
    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the owner can reset the game");
        _;
    }

    // check that the choice lies in the correct range
    modifier validChoice(uint256 choice) {
        require(choice != 0 && choice <= uint256(Choice.Scissors), "Invalid Choice");
        _;
    }

    // check that the fee is right
    modifier feeCheck() {
        require(msg.value == PLAYER_FEE, "You need to pay a fee in order to play");
        _;
    }

    // re entrancy guard
    modifier noReentrant() {
        require(!_locked, "No re-entrancy");
        _locked = true;
        _;
        _locked = false;
    }

    /*********************************************
    *          Entry Point (Constructor)
    **********************************************/

    // the constructor just sets the number of players to zero
    constructor() {
        _nPlayers = 0;
        _locked = false;
        _owner = msg.sender;
    }

    /*********************************************
    *                  Methods
    **********************************************/

    // since this is public pure, it can run on client side without the opponent knowing about it
    function getCommitmentHash(uint256 choice, uint256 secret) public pure validChoice(choice) returns (bytes32) {
        return keccak256(abi.encodePacked(choice, secret));
    }

    // the player "plays" by providing a commitment (use getCommitmentHash)
    function play(bytes32 commitment) external payable feeCheck {
        require(_nPlayers < 2, "There are alrady 2 players playing. Please wait");

        _commitments[msg.sender] = commitment;
        _players[_nPlayers++] = msg.sender;
        _choices[msg.sender] = Choice.None;

        emit Committed(msg.sender, commitment);
    }

    // once both players have played, the can reveal their commitments
    function reveal(uint256 choice, uint256 secret) public validChoice(choice) {
        require(_nPlayers == 2, "Not all players have provided their commitment yet. Please wait.");
        require(msg.sender == _players[0] || msg.sender == _players[1], "You are not a player in the current round");
        require(getCommitmentHash(choice, secret) == _commitments[msg.sender], "That was not the choice or secret you commited");

        _choices[msg.sender] = Choice(choice);

        emit Revealed(msg.sender, _choices[msg.sender]);
    }

    // once both players have revealed their commitments, each player can ask if they won 
    function didIWin() public view returns(string memory) {
        require(msg.sender == _players[0] || msg.sender == _players[1], "You are not a player in the current round");
        require(_choices[_players[0]] != Choice.None && _choices[_players[1]] != Choice.None, "One of the players hasn't revealed yet their commitment");

        string memory returnValue = "It is a draw";

        if (_choices[_players[0]] != _choices[_players[1]]) {
            
            if (isWinner(msg.sender)) {
                returnValue = "You win";
            }
            else {
                returnValue = "You lose";
            }
        }


        return returnValue;
    }

    function payWinnersReward() external noReentrant {
        require(msg.sender == _owner || msg.sender == _players[0] || msg.sender == _players[1], "Only the owner OR the current players can call this function");
        require(_choices[_players[0]] != Choice.None && _choices[_players[1]] != Choice.None, "One of the players hasn't revealed yet their commitment");

        address winner = address(0);

        if (_choices[_players[0]] != _choices[_players[1]]) {
            
            if (isWinner(_players[0])) {
                winner = _players[0];
            }
            else {
                winner = _players[1];
            }

            // This is the current recommended method to use.
            // Call returns a boolean value indicating success or failure.
            (bool sent, ) = winner.call{value: WINNERS_REWARD}("");
            require(sent, "Failed to send Ether");

            emit Winner(winner);
        }
    }

    // shall only be called by the dapp (with owner access)
    function reset() external onlyOwner {

        // it is not possible to just clear the mappings (remove all its elements), as far as I understand
        for (uint256 i = 0; i < 2; i++) {
            _commitments[_players[i]] = bytes32(0);
            _choices[_players[i]] = Choice.None;
            _players[i] = address(0);
        }
        _nPlayers = 0;
    }

    // internal logic
    function isWinner(address caller) internal view returns(bool) {
        
        uint256 opponent = 0;
        if (caller == _players[0]) {
            opponent = 1;
        }

        bool callerWins = false;

        if (_choices[_players[0]] != _choices[_players[1]]) {
            
            callerWins = isCallerTheWinner(_choices[caller], _choices[_players[opponent]]);
        }

        return callerWins;
    }

    // internal logic
    function isCallerTheWinner(Choice a, Choice b) private pure returns(bool) {

        bool youWin = false;
        
        if (a == Choice.Rock && b == Choice.Paper) {
            
            // do I safe more gas if I return immediately?
            //return false;
            youWin = false;
        }
        else if (a == Choice.Rock && b == Choice.Scissors) {
            youWin = true;
        }
        else if (a == Choice.Paper && b == Choice.Scissors) {
            youWin = false;
        }
        else if (a == Choice.Paper && b == Choice.Rock) {
            youWin = true;
        }
        else if (a == Choice.Scissors && b == Choice.Rock) {
            youWin = false;
        }
        else if (a == Choice.Scissors && b == Choice.Paper) {
            youWin = true;
        }

        return youWin;
    }

    // function to receive Ether. msg.data must be empty
    receive() external payable {
        // do I need to do something here? 
    }

    // fallback function is called when msg.data is not empty
    fallback() external payable {
        // do I need to do something here? 
    }
}