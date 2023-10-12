const hre = require("hardhat");

async function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(() => resolve(), ms);
  });
}

async function main() {
  const initialAmount = hre.ethers.parseEther("0.001");

  const casino = await hre.ethers.deployContract("Casino", {
    value: initialAmount,
  });

  await casino.waitForDeployment();

  console.log(`Casino deployed to ${casino.target}`);

  await sleep(45 * 1000);

  await hre.run("verify:verify", {
    address: casino.target,
    constructorArguments: [],
  });
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
