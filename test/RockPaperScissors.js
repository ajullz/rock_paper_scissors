// I think this is already globally included but I like to be explicit
const { ethers } = require("hardhat");

// This is a JavaScript assertion library 
const { expect } = require("chai");

// Allows for re-use of setup code
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("RockPaperScissors contract", function () {
    async function deployTokenFixture() {
        const RockPaperScissorsFactory = await ethers.getContractFactory("RockPaperScissors");
        const gameContract = await RockPaperScissorsFactory.deploy();
        const [owner, addr1, addr2] = await ethers.getSigners();
        
        await gameContract.deployed();
        
        // connect is to "set" msg.sender
        const commitment1 = await gameContract.connect(addr1).getCommitmentHash(1, 10);
        const commitment2 = await gameContract.connect(addr2).getCommitmentHash(2, 20);
        const commitment3 = await gameContract.getCommitmentHash(3, 30);

        // fee to pay
        feeAsStr = await gameContract.PLAYER_FEE();
        
        // Fixtures can return anything you consider useful for your tests
        return { gameContract, owner, addr1, addr2, commitment1, commitment2, commitment3, feeAsStr };
    }
  
    it("Should not allow more than 2 players to commit", async function () {
        // load setup
        const { gameContract, feeAsStr, addr1, addr2, commitment1, commitment2, commitment3 } = await loadFixture(deployTokenFixture);

        await gameContract.connect(addr1).play(commitment1, {value: feeAsStr});
        await gameContract.connect(addr2).play(commitment2, {value: feeAsStr});

        await expect(gameContract.play(commitment3, {value: feeAsStr})).to.be.reverted;
    });
      
    it("Should not allow any player to reveal their commitment before both players have commited", async function () {
        // load setup
        const { gameContract, feeAsStr, addr1, commitment1 } = await loadFixture(deployTokenFixture);

        await gameContract.connect(addr1).play(commitment1, {value: feeAsStr});
        await expect(gameContract.connect(addr1).reveal(1, 10)).to.be.reverted;
    });

    it("Should ignore any player that is not playing in the current round (is not player1 nor player2)", async function () {
        // load setup
        const { gameContract, feeAsStr, addr1, addr2, commitment1, commitment2 } = await loadFixture(deployTokenFixture);

        await gameContract.connect(addr1).play(commitment1, {value: feeAsStr});
        await gameContract.connect(addr2).play(commitment2, {value: feeAsStr});
        await expect(gameContract.reveal(1, 2)).to.be.reverted;
    });

    it("Should not allow a player to reveal the wrong commitment", async function () {
        // load setup
        const { gameContract, feeAsStr, addr1, addr2, commitment1, commitment2 } = await loadFixture(deployTokenFixture);

        await gameContract.connect(addr1).play(commitment1, {value: feeAsStr});
        await gameContract.connect(addr2).play(commitment2, {value: feeAsStr});
        await expect(gameContract.connect(addr1).reveal(100, 200)).to.be.reverted;
    });
    
    it("Should not allow to check the winner if not all players have revealed their commitment", async function () {
        // load setup
        const { gameContract, feeAsStr, addr1, addr2, commitment1, commitment2 } = await loadFixture(deployTokenFixture);

        await gameContract.connect(addr1).play(commitment1, {value: feeAsStr});
        await gameContract.connect(addr2).play(commitment2, {value: feeAsStr});
        await expect(gameContract.connect(addr1).didIWin()).to.be.reverted;
    });

    it("Player2 wins", async function () {
        // load setup
        const { gameContract, feeAsStr, addr1, addr2, commitment1, commitment2 } = await loadFixture(deployTokenFixture);

        await gameContract.connect(addr1).play(commitment1, {value: feeAsStr});
        await gameContract.connect(addr2).play(commitment2, {value: feeAsStr});

        await gameContract.connect(addr1).reveal(1, 10);
        await gameContract.connect(addr2).reveal(2, 20);

        expect(await gameContract.connect(addr1).didIWin()).to.equal("You lose");
        expect(await gameContract.connect(addr2).didIWin()).to.equal("You win");
    });

    it("It is a draw", async function () {
        // load setup
        const { gameContract, feeAsStr, addr1, addr2, commitment1 } = await loadFixture(deployTokenFixture);

        await gameContract.connect(addr1).play(commitment1, {value: feeAsStr});
        await gameContract.connect(addr2).play(commitment1, {value: feeAsStr});

        await gameContract.connect(addr1).reveal(1, 10);
        await gameContract.connect(addr2).reveal(1, 10);

        expect(await gameContract.connect(addr1).didIWin()).to.equal("It is a draw");
        expect(await gameContract.connect(addr2).didIWin()).to.equal("It is a draw");
    });

    it("Invalid choice", async function () {
        // load setup
        const { gameContract, feeAsStr, addr1, addr2, commitment1 } = await loadFixture(deployTokenFixture);

        await gameContract.connect(addr1).play(commitment1, {value: feeAsStr});
        await gameContract.connect(addr2).play(commitment1, {value: feeAsStr});

        await expect(gameContract.connect(addr1).reveal(8, 10)).to.be.revertedWith("Invalid Choice");
    });
});