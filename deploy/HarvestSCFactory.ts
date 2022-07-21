require('dotenv').config({ path: __dirname + '/../.env' });

module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {
  const receiptFactoryABI = require('../abi/ReceiptTokenFactory.json');

    const { deploy } = deployments
    const {
      HARVEST_REWARD_VAULT, 
      HARVEST_REWARD_POOL, 
      SUSHI_SWAP_ROUTER,
      FARM_TOKEN,
      WETH
    } = process.env;
     
    const { deployer } = await getNamedAccounts()

    const RECEIPT_TOKEN_FACTORY = await ethers.getContract("ReceiptTokenFactory")
    const STRATEGY_BEACON = await ethers.getContract("HarvestSCStrategyBeacon")

   const { address } = await deploy("HarvestSCFactory", {
      from: deployer,
      args: [
              HARVEST_REWARD_VAULT, 
              HARVEST_REWARD_POOL, 
              SUSHI_SWAP_ROUTER,
              FARM_TOKEN,
              WETH,
              RECEIPT_TOKEN_FACTORY.address,
              STRATEGY_BEACON.address],
      log: true,
      deterministicDeployment: false
    })

    const admin = await ethers.getSigner(deployer);
    const receiptFactory = new ethers.Contract(RECEIPT_TOKEN_FACTORY.address, receiptFactoryABI, ethers.provider);
    // grant role
    // let receipt = await receiptFactory.connect(admin).grantTokenCreatorRole(address);
    // console.log('[GRANT_ROLE:HarvestSCFactory] receiptFactory grant token creator ', receipt.hash)
 
  }
  
  module.exports.tags = ["HarvestSCFactory"]
  module.exports.dependencies = ["ReceiptTokenFactory", "HarvestSCStrategyBeacon"]