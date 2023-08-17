require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();
require("hardhat-deploy");

module.exports = {
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },

  solidity: {
    compilers: [
      {
        version: "0.8.7",
      },
      {
        version: "0.8.12",
      },
      {
        version: "0.8.4",
      },
      {
        version: "0.8.0",
      },
      {
        version: "0.4.17",
      },
      {
        version: "0.4.18",
      },
    ],
  },
};
