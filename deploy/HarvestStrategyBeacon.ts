require('dotenv').config({ path: __dirname + '/../.env' });

module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {
    const { deploy } = deployments    
    const { deployer } = await getNamedAccounts()

    const Harvest = await ethers.getContract("Harvest") 
    
    await deploy("HarvestStrategyBeacon", {
      from: deployer,
      args: [ Harvest.address ],
      log: true,
      deterministicDeployment: false
    })
 
  }
  
  module.exports.tags = ["HarvestStrategyBeacon"]
  module.exports.dependencies = ["Harvest"]