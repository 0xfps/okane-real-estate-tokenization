// const { network } = require("hardhat");
//const { Alchemy } = require("alchemy-sdk");

const { network, ethers } = require("hardhat");
const { verify } = require("../utils/verify");

module.exports = async ({ deployments, deployer }) => {
  const { deploy, log } = deployments;

  const contract = await deploy("RealEstateV1", {
    from: process.env.PRIVATE_KEY,
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  console.log("Contract address:", contract.address);

  log("Verifying...");
  await verify(contract.address);

  log("Verified!");

  // IPFS link for the first property to sell --> ipfs://bafybeiayv5orjjzv3pss3yq5k4jlbmjgwswsssbohqm2s3yhq37rjzrpgy/
};

module.exports.tags = ["RealEstateV1"];
