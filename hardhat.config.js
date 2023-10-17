require("@nomicfoundation/hardhat-toolbox");

const ALCHEMY_API_KEY = "iLgXN-KhoVamh8s_75JdPxDfYfJvVCVI";
const SEPOLIA_PRIVATE_KEY =
  "2b0a0ad3ad74930da8dda26e38185b2938781c2d9cd25de51a8e71d521b74f8a";
const ETHERSCAN_API_KEY = "RRR98TP5A3DRMTZXJEIGYKSPF377UTWING";

module.exports = {
  solidity: "0.8.19",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY,
  },
};
