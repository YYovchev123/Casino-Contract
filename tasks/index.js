const { Contract } = require("ethers");
const { task } = require("hardhat/config");

task("deploy", "deploy instance of Casino contract").setAction(
  async (taskArgs, hre) => {
    const account = (await hre.ethers.getSigners())[0];
    const initialAmount = hre.ethers.parseEther("0.001");
    const casino = await hre.ethers.deployContract(
      "Casino",
      {
        value: initialAmount,
      },
      account
    );
    await casino.waitForDeployment();
    console.log(`Casino deployed to ${casino.target}`);
  }
);

// Create tasks for all the functions

// task("enter", "enter a game with a specific number").addParam("prediction", "guess the random number").addParam("address", "the address of the contract").setAction(
//     async (taskArgs, hre) => {
//         const casino = await ethers
//     }
// )
