// const { network } = require("hardhat");
//const { Alchemy } = require("alchemy-sdk");

const { network, ethers } = require("hardhat");
const { verify } = require("../utils/verify");

module.exports = async ({ deployments, deployer }) => {
  const { deploy, log } = deployments;

  // Constructor Arguments

  const decimals = "18";
  const initialSupply = "1000000000000000000000000";
  const name = "Tether";
  const symbol = "USDT";

  const args = [initialSupply, name, symbol, decimals];

  const contract = await deploy("TetherToken", {
    from: process.env.PRIVATE_KEY,
    args: args,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  console.log("Contract address:", contract.address);

  log("Verifying...");
  await verify(contract.address, args);
  log("Verified!");
};

module.exports.tags = ["TetherToken"];
