require('dotenv').config({ path: __dirname + '/../.env' })

module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {
 
  const { deploy } = deployments
  const { deployer } = await getNamedAccounts()  

  await deploy("SushiSLP", {
    from: deployer,
    log: true,
    deterministicDeployment: false
  })  
}
module.exports.tags = ["SushiSLP"] 