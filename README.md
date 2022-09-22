# Rock Paper Scissors Game

**Simple solidity game where 2 players can play at a time**

1. each player will have to commit a choice with a secret number, and pay a fee (0.01 ETH/MATIC/OTHER NATIVE EVM COIN)
    - the contract provides the function `getCommitmentHash(choice, secret)` so that each player can compute the commitment locally
2. once both players have committed their choice, they will then have to reveal their choice
    - internally, the contract checks weather your revealed choice and secret match your commitment, and reject the operation if not.
3. the users can call `didIWin` to know if they won
4. the owner of the contract or one of the current players can call `payWinnersReward` to send the reward to the winner (0.015 ETH/MATIC/OTHER NATIVE EVM COIN)
5. the owner can then reset the game, and 2 other players can play

**It is a simple contract where I could learn about**
- the basics of the data structures in solidity
- some gas efficiency tips (constants & immutable)
- modifiers (owner, re-entrancy)
- events
- hardhat
- ethers
- testing
- deploying

**TODO**
- web interface
    - you can play on remix by copying the contract
    - or, you can go deploy it to a testnet using `scripts/deploy.js`
        - you would need to provide your own RPC and WALLET_KEY values
