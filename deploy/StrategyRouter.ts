require('dotenv').config({ path: __dirname + '/../.env' })

const _harvestAbi = require('../abi/HarvestEthFactory.json')
const _harvestSCAbi = require('../abi/HarvestSCFactory.json')
const _sushiSLP = require('../abi/SushiSLPFactory.json')

module.exports = async function ({ ethers, getNamedAccounts, deployments }: any) {
    const { deploy } = deployments
    const { deployer } = await getNamedAccounts()

    const _harvestEthFactoryAddress = (await ethers.getContract("HarvestEthFactory")).address
    const _harvestSCFactoryAddress = (await ethers.getContract("HarvestSCFactory")).address
    const _sushiSLPFactoryAddress = (await ethers.getContract("SushiSLPFactory")).address
    const _sushiStableCoinFactoryAddress = (await ethers.getContract("SushiStableCoinFactory")).address

    const { address } = await deploy("StrategyRouter", {
      from: deployer,
      args: [
        _harvestEthFactoryAddress, 
        _harvestSCFactoryAddress, 
        _sushiSLPFactoryAddress,
        _sushiStableCoinFactoryAddress],
      log: true,
      deterministicDeployment: false
    })

    const admin = await ethers.getSigner(deployer);
    const _harvestFactory = new ethers.Contract(_harvestEthFactoryAddress, _harvestAbi, ethers.provider);
    const _harvestSCFactory = new ethers.Contract(_harvestSCFactoryAddress, _harvestSCAbi, ethers.provider);
    const _sushiFactory = new ethers.Contract(_sushiSLPFactoryAddress, _sushiSLP, ethers.provider);
    // grant router role on factories
    let receipt = await _harvestFactory.connect(admin).grantRouterRole(address);
    console.log('[GRANT_ROLE]harvestFactory grant router role ', receipt.hash)

    receipt = await _harvestSCFactory.connect(admin).grantRouterRole(address);
    console.log('[GRANT_ROLE]harvestSCFactory grant router role ', receipt.hash)

    receipt = await _sushiFactory.connect(admin).grantRouterRole(address);
    console.log('[GRANT_ROLE]sushiFactory grant router role ', receipt.hash)
  }
  
  module.exports.tags = ["StrategyRouter"]
  module.exports.dependencies = ["HarvestEthFactory", "HarvestSCFactory", 'SushiSLPFactory', 'SushiStableCoinFactory']