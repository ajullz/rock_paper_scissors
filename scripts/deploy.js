async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const RockPaperScissorsFactory = await ethers.getContractFactory("RockPaperScissors");
    const gameContract = await RockPaperScissorsFactory.deploy();
  
    console.log("Game contract address:", gameContract.address);
}
  
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });