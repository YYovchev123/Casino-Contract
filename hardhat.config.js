require("@nomicfoundation/hardhat-toolbox");

module.exports = {
  solidity: "0.8.19",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY],
      gas: 30_000_000,
      //@ts-ignore
      gasLimit: 30_000_000,
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};
