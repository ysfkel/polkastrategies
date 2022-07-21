require('dotenv').config({ path: __dirname + '/../.env' });

module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {
    const { deploy } = deployments    
    const { deployer } = await getNamedAccounts()

    const HarvestSC = await ethers.getContract("HarvestSC") 
   
    await deploy("HarvestSCStrategyBeacon", {
      from: deployer,
      args: [ HarvestSC.address ],
      log: true,
      deterministicDeployment: false
    })
 
  }
  
  module.exports.tags = ["HarvestSCStrategyBeacon"]
  module.exports.dependencies = ["HarvestSC"]