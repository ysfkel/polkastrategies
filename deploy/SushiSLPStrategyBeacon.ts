module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {
    const { deploy } = deployments    
    const { deployer } = await getNamedAccounts()

    const SushiSLP = await ethers.getContract("SushiSLP") 
    
    await deploy("SushiSLPStrategyBeacon", {
      from: deployer,
      args: [ SushiSLP.address ],
      log: true,
      deterministicDeployment: false
    })
  }
  
  module.exports.tags = ["SushiSLPStrategyBeacon"]
  module.exports.dependencies = ["SushiSLP"]