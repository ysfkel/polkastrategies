module.exports = [
    '0x80C7DD17B01855a6D2347444a0FCC36136a314de', //HarvestEthFactory
    '0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506', //HarvestSCFactory
    '0xc35DADB65012eC5796536bD9864eD8773aBc74C4', // SushiSLPFactory
    '0x0769fd68dFb93167989C6f7254cd0D766Fb2841F',  // SushiStableCoinFactory
    '0xd0a1e359811322d97991e03f863a0c30c2cf029c', // WETH
    '0xB1480CF0C27001886Ab219C624c98900aDD87b5d' // SushiStableCoinStrategyBeacon
  ];
 
  
  // npx hardhat verify --constructor-args arguments.js DEPLOYED_CONTRACT_ADDRESS
// npx hardhat verify --network kovan --constructor-args scripts/verification/sushis-stablecoin-factory.js 0xc350A3d1268078aF0C8925EF192952d2160d403D