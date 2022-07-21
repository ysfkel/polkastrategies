require('dotenv').config({ path: __dirname + '/../.env' });
module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {

    const { deploy } = deployments
    const {
      MASTER_CHEF, 
      SUSHI_SWAP_ROUTER,
      SUSHI_SWAP_FACTORY,
      SUSHI,
      WETH,

    } = process.env;
     
    const { deployer } = await getNamedAccounts() 
    const STRATEGY_BEACON = await ethers.getContract("SushiStableCoinStrategyBeacon")

    await deploy("SushiStableCoinFactory", {
      from: deployer,
      args: [
              MASTER_CHEF, 
              SUSHI_SWAP_ROUTER, 
              SUSHI_SWAP_FACTORY,
              SUSHI,
              WETH, 
              STRATEGY_BEACON.address],
      log: true,
      deterministicDeployment: false
    })

  }
  
  module.exports.tags = ["SushiStableCoinFactory"]
  module.exports.dependencies = ["SushiStableCoinStrategyBeacon"]