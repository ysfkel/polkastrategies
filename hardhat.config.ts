import { task, HardhatUserConfig,  } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "hardhat-abi-exporter";
import "dotenv/config";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-gas-reporter";
import { getAddressKey } from './scripts/keys';
import "@nomiclabs/hardhat-etherscan";
import './tasks'
require('dotenv').config({ path: __dirname + '/.env.keys' });

const { ETHERCAN_API_KEY,  PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3, INFURA_API_KEY, ALCHEMY_API_KEY } = process.env; 

const PUBLIC_KEY_1 = getAddressKey(PRIVATE_KEY_1 as string)
const PUBLIC_KEY_2 = getAddressKey(PRIVATE_KEY_2 as string)
const PUBLIC_KEY_3 = getAddressKey(PRIVATE_KEY_3 as string)

const { ALCHEMY_MAINNET, INFURA_MAINNET,
   ALCHEMY_KOVAN, RINKEBY, POLYGON, MUMBAI, GANACHE } = process.env;
 
const test_eth =  '1000000000000000000000000'
const accounts = [
  {
    privateKey: PRIVATE_KEY_1,
    balance: test_eth
  },{
    privateKey:PRIVATE_KEY_2,
    balance: test_eth
  },{
    privateKey: PRIVATE_KEY_3,
    balance: test_eth
  }
]
//  export default config;
module.exports = {
  namedAccounts: {
    deployer: {
      default: 0,
      "mainnet": PUBLIC_KEY_1,
      "kovan": PUBLIC_KEY_1,
      "rinkeby": PUBLIC_KEY_1,
      "mumbai": PUBLIC_KEY_1,
      "polygon": PUBLIC_KEY_1,
      "ganache": PUBLIC_KEY_1,
    },
    user1: {
      default: 1, // second account in signers list
      "mainnet": PUBLIC_KEY_2,
      "kovan": PUBLIC_KEY_2,
      "rinkeby": PUBLIC_KEY_2,
      "mumbai": PUBLIC_KEY_2,
      "polygon": PUBLIC_KEY_2,
      "ganache": PUBLIC_KEY_2
    },
    user2: {
      default: 2, // 3rd account in signers list
      "mainnet": PUBLIC_KEY_3,
      "kovan": PUBLIC_KEY_3, 
      "rinkeby": PUBLIC_KEY_3,
      "mumbai": PUBLIC_KEY_3,
      "polygon": PUBLIC_KEY_3,
      "ganache": PUBLIC_KEY_3,
    },
    dev: {
      default: 1,
    },
  }, //
  abiExporter: {
    path: "./abi",
    clear: false,
    flat: true
  }, 
  throwOnTransactionFailures: true,
  throwOnCallFailures: true,
  allowUnlimitedContractSize: true,
  blockGasLimit: 0x1fffffffffffff,
  accounts:accounts, 
  solidity: {
    version: "0.8.1",
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000
      }
    }
  },
  networks: {
    hardhat:{
      forking: {
      //   url: 'http://127.0.0.1:8545' 
       url: 'https://eth-kovan.alchemyapi.io/v2/ja8a2K5vpOW7aZqCLAD2oIs60ecXiYXQ'
        
       // url: `${ALCHEMY_MAINNET}/${ALCHEMY_API_KEY}`,
       //blockNumber:12000000// 12999289 //11095000
       // url: `${INFURA_MAINNET}/${INFURA_API_KEY}`
      },
       accounts:accounts,
        gas: 12000000,
        blockGasLimit: 0x1fffffffffffff,
        allowUnlimitedContractSize: true,
        timeout: 1800000,
        gasPrice: 9000000
    },
    kovan:{
      //url:`${ALCHEMY_KOVAN}/${ALCHEMY_API_KEY}`,
      url: 'https://eth-kovan.alchemyapi.io/v2/ja8a2K5vpOW7aZqCLAD2oIs60ecXiYXQ',
      // saveDeployments: true,
      accounts:[PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3 ],
    },
 
    rinkeby:{
      url:`${RINKEBY}/${INFURA_API_KEY}`,
      accounts:[PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3 ]
    },
    mumbai: {
      url: `${MUMBAI}/`,
      saveDeployments: true,
      accounts:[PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3 ]
    },polygon: {
      url: `${POLYGON}`,
      saveDeployments: true,
      accounts:[PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3 ]
    },    ganache:{
      url:`${GANACHE}`,
      accounts:[PRIVATE_KEY_1, PRIVATE_KEY_2, PRIVATE_KEY_3 ],
      gas: 18000000,
      blockGasLimit: 0x1fffffffffffff,
      allowUnlimitedContractSize: true,
      timeout: 1800000,
      gasPrice: 9000000
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: ETHERCAN_API_KEY
  }, paths: {
    artifacts: "artifacts", 
    cache: "cache",
    deploy: "deploy",
    deployments: "deployments",
    imports: "imports",
    sources: "contracts",
    tests: "test",
  },
  gasReporter: {
    enabled: true,
    noColors: false,
    currency: 'USD',
    gasPrice: 21,
  }
};

