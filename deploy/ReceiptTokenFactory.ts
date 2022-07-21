require('dotenv').config({ path: __dirname + '/../.env' });

module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {
    const { deploy } = deployments

    const { deployer } = await getNamedAccounts()
    const RECEIPT_TOKEN = await ethers.getContract("ReceiptToken") 

    await deploy("ReceiptTokenFactory", {
      from: deployer,
      args: [RECEIPT_TOKEN.address],
      log: true,
      deterministicDeployment: false
    })
  }
  
  module.exports.tags = ["ReceiptTokenFactory"]
  module.exports.dependencies = ["ReceiptToken"]