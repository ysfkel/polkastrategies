

const dotenv = require('dotenv')
dotenv.config({ path: __dirname + '/../.env' });

export const mainnet_rpc = `${process.env.MAINNET}/${process.env.INFURA_API_KEY}`
export const kovan_rpc = `${process.env.KOVAN}/${process.env.INFURA_API_KEY}`
export const rinkeby_rpc = `${process.env.RINKEBY}/${process.env.INFURA_API_KEY}`
export const polygon_rpc = process.env.POLYGON
export const ganache_rpc = process.env.GANACHE

export const mainnet = {
    harvestVault: '0xab7FA2B2985BCcfC13c6D86b1D5A17486ab1e04C',
    harvestPool: process.env.HARVEST_REWARD_POOL,
    sushiswapRouter: process.env.SUSHI_SWAP_ROUTER,
    farmAddress: '0xa0246c9032bC3A600820415aE600c6388619A14D',
    sushiAddress: '0x6B3595068778DD592e39A122f4f5a5cF09C90fE2',
    wethAddress: process.env.WETH,
    sushiswapFactory: process.env.SUSHI_SWAP_FACTORY,
    masterChef: '0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd',
    usdtwethSLP:'0x06da0fd433C1A5d7a4faa01111c044910A184553',
    ethDaiSlpAddress:'0xC3D03e4F041Fd4cD388c549Ee2A29a9E5075882f',
    wbtcwethSLP: '0xCEfF51756c56CeFFCA006cD410B03FFC46dd3a58',
    usdtAddress: '0xdAC17F958D2ee523a2206206994597C13D831ec7',
    daiAddress: '0x6B175474E89094C44Da98b954EedeAC495271d0F'
} 