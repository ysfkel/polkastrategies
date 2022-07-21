import { task  } from 'hardhat/config' 
const dotenv = require('dotenv')
dotenv.config({ path: __dirname + '/../.env.keys' });

const { MASTER_CHEF, SUSHI_SWAP_ROUTER, SUSHI_SWAP_FACTORY,SUSHI, WETH} = process.env;

const verify = async (address: string, args: Array<string>) => {

    const  run = require('hardhat').run;

    await run("verify:verify", {
        address: address,
        constructorArguments: args,
    });
}
 
task('verify-all').setAction(async ({}, {  ethers, getNamedAccounts }) => {
    // hh verify-all network <network-name>

    console.log('..initializing contracts')

    const { name } = await ethers.provider.getNetwork()
   
    const ReceiptToken =  require(`../deployments/${name}/ReceiptToken`)
    const ReceiptTokenFactory =  require(`../deployments/${name}/ReceiptTokenFactory`)
    const SushiStableCoin =  require(`../deployments/${name}/SushiStableCoin`)
    const StrategyRouter =  require(`../deployments/${name}/StrategyRouter`)
    const HarvestEthFactory =  require(`../deployments/${name}/HarvestEthFactory`)
    const HarvestSCFactory =  require(`../deployments/${name}/HarvestSCFactory`)
    const SushiSLPFactory =  require(`../deployments/${name}/SushiSLPFactory`)
    const SushiStableCoinStrategyBeacon = require(`../deployments/${name}/SushiStableCoinStrategyBeacon`)
    const SushiStableCoinFactory =  require(`../deployments/${name}/SushiStableCoinFactory`)
    
    await verify(ReceiptTokenFactory.address, [ReceiptToken.address]);
    await verify(SushiStableCoinStrategyBeacon.address, [SushiStableCoin.address]); // beacon 
    await verify(StrategyRouter.address, [HarvestEthFactory.address, HarvestSCFactory.address, SushiSLPFactory.address, SushiStableCoinFactory.address ]);
    await verify(SushiStableCoinFactory.address, [MASTER_CHEF, SUSHI_SWAP_ROUTER, SUSHI_SWAP_FACTORY,SUSHI, WETH, SushiStableCoinStrategyBeacon.address]);
})
  