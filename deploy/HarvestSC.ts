module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {

  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()  

  await deploy("HarvestSC", {
    from: deployer,
    log: true,
    deterministicDeployment: false
  })  
}
module.exports.tags = ["HarvestSC"] 