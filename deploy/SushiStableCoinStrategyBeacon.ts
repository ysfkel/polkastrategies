module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {
    const { deploy } = deployments    
    const { deployer } = await getNamedAccounts()

    const SushiStableCoin = await ethers.getContract("SushiStableCoin") 
    
    await deploy("SushiStableCoinStrategyBeacon", {
      from: deployer,
      args: [ SushiStableCoin.address ],
      log: true,
      deterministicDeployment: false
    })
  }
  
  module.exports.tags = ["SushiSLPStrategyBeacon"]
  module.exports.dependencies = ["SushiStableCoin"]