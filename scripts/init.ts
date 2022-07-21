const dotenv = require('dotenv')


// dotenv.config({ path: __dirname + '/../.env' });
 
const __init = async (hre: any ) => {

    const { ethers , getNamedAccounts} = hre;

    console.log('..initializing contracts')

    const { name } = await ethers.provider.getNetwork()
    console.log(name)

    const { deployer }  = await getNamedAccounts()
    console.log(deployer)

    const {
        HARVEST_REWARD_VAULT, 
        HARVEST_REWARD_POOL, 
        SUSHI_SWAP_ROUTER,
        FARM_TOKEN,
        DAI,
        WETH, 
        MASTER_CHEF, 
        SUSHI_SWAP_FACTORY,  
        USDT, 
        SUSHI,
        TREASURY_ADDRESS,
        FEE_ADDRESS,
        USDT_WETH_SLP
    } = process.env;

    const ReceiptTokenABI = require('../abi/ReceiptToken.json');
    const HarvestABI = require('../abi/Harvest.json')
    const HarvestSCABI = require('../abi/HarvestSC.json')
    const SushiSLPABI = require('../abi/SushiSLP.json')
    const SushiStableCoinABI = require('../abi/SushiStableCoin.json')
     
    const ReceiptToken =  require(`../deployments/${name}/ReceiptToken`)
    const Harvest =  require(`../deployments/${name}/Harvest`)
    const HarvestSC =  require(`../deployments/${name}/HarvestSC`)
    const SushiSLP =  require(`../deployments/${name}/SushiSLP`)
    const SushiStableCoin =  require(`../deployments/${name}/SushiStableCoin`)
    
    const ReceiptTokenContract = new ethers.Contract(ReceiptToken.address, ReceiptTokenABI, ethers.provider);
    const HarvestContract = new ethers.Contract(Harvest.address, HarvestABI, ethers.provider);
    const HarvestSCContract = new ethers.Contract(HarvestSC.address, HarvestSCABI, ethers.provider);
    const SushiSLPContract = new ethers.Contract(SushiSLP.address, SushiSLPABI, ethers.provider);
    const SushiStableCoinContract = new ethers.Contract(SushiStableCoin.address, SushiStableCoinABI, ethers.provider);

    const admin = await ethers.getSigner(deployer);
    let res;
//      res = await HarvestContract.connect(admin).initialize(
//       HARVEST_REWARD_VAULT,
//       HARVEST_REWARD_POOL,
//       SUSHI_SWAP_ROUTER,
//       FARM_TOKEN,
//       FARM_TOKEN,
//       DAI,
//       WETH,
//       TREASURY_ADDRESS,
//       FEE_ADDRESS,
//       ReceiptToken.address)
//      console.log('[IMPLEMENTATION_INITIALIZATION_COMPLETED]::Harvest',res.hash)
  
//    res = await HarvestSCContract.connect(admin).initialize(
//       HARVEST_REWARD_VAULT,
//       HARVEST_REWARD_POOL,
//       SUSHI_SWAP_ROUTER,
//       FARM_TOKEN,
//       FARM_TOKEN,
//       DAI,
//       WETH,
//       TREASURY_ADDRESS,
//       FEE_ADDRESS,
//       ReceiptToken.address)
//       console.log('[IMPLEMENTATION_INITIALIZATION_COMPLETED]::HarvestSC',res.hash)
  
   // res = await SushiSLPContract.connect(admin).initialize(
    //       MASTER_CHEF,
    //       SUSHI_SWAP_FACTORY, 
    //       SUSHI_SWAP_ROUTER,
    //       USDT,  
    //       WETH,
    //       SUSHI,
    //       TREASURY_ADDRESS,
    //       FEE_ADDRESS,
    //       0,
    //       USDT_WETH_SLP,
    //       ReceiptToken.address)
    // console.log('[IMPLEMENTATION_INITIALIZATION_COMPLETED]::SushiSLP',res.hash)
  
//    res = await SushiStableCoinContract.connect(admin).initialize(
//             MASTER_CHEF,
//             SUSHI_SWAP_FACTORY, 
//             SUSHI_SWAP_ROUTER,
//             WETH,
//             SUSHI,
//             TREASURY_ADDRESS,
//             FEE_ADDRESS)
//   console.log('[IMPLEMENTATION_INITIALIZATION_COMPLETED]::SushiStableCoin',res.hash)
  
    res = await ReceiptTokenContract.connect(admin).initialize(
              USDT,
              SushiStableCoin.address)
    console.log('[IMPLEMENTATION_INITIALIZATION_COMPLETED]::ReceiptToken',res.hash)
}
  
const runTasks = async () => {

   await __init(require("hardhat"))
}

runTasks()