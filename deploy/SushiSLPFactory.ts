require('dotenv').config({ path: __dirname + '/../.env' });
module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {
    const receiptFactoryABI = require('../abi/ReceiptTokenFactory.json');

    const { deploy } = deployments
    const {
      MASTER_CHEF, 
      SUSHI_SWAP_ROUTER,
      SUSHI_SWAP_FACTORY,
      SUSHI,
      WETH,

    } = process.env;
     
    const { deployer } = await getNamedAccounts()

    const RECEIPT_TOKEN_FACTORY = await ethers.getContract("ReceiptTokenFactory")
    const STRATEGY_BEACON = await ethers.getContract("SushiSLPStrategyBeacon")

   const { address } = await deploy("SushiSLPFactory", {
      from: deployer,
      args: [
              MASTER_CHEF, 
              SUSHI_SWAP_ROUTER, 
              SUSHI_SWAP_FACTORY,
              SUSHI,
              WETH,
              RECEIPT_TOKEN_FACTORY.address,
              STRATEGY_BEACON.address],
      log: true,
      deterministicDeployment: false
    })
  }
  
  module.exports.tags = ["SushiSLPFactory"]
  module.exports.dependencies = ["ReceiptTokenFactory", "SushiSLPStrategyBeacon"]