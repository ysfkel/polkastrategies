# Launchpad - Parachain Auction Strategies 


Parachains are parallel processing chains on Polkadot (usually, blockchains) that allow for transactions to be scalably fulfilled between different blockchains and/or blockchain layers.

To receive and maintain a Polkadot Parachain, it must be purchased in an auction with the chain’s native DOT token, and maintained with continued DOT stakings. We implement strategies to ensure that we obtain enough DOT to complete these objectives.

Users will be able to invest ETH or LPs that we are going to use in underlying yield services like Sushi MasterChef, Harvest, Force and others. 50% of the obtained rewards are collected as part of the fund raising for the Polkadot Parachain auction.
A problem with staking DOTs into parachain auctions is the problem of opportunity cost. When you stake DOTs into a parachain, you lose out on the staking rewards. We want users with ERC-20 tokens to be able to deposit into ETH vaults that route to yield farming strategies, and collect a portion of this yield to a treasury that is then used to purchase DOT. 

## Strategies

Repo consists of the following contracts (as of March 25th):
 - [**Harvest.sol**](https://github.com/cryptotechmaker/polkastrategies/blob/feature/launch-pad/contracts/strategies/Harvest/Harvest.sol)(deposit flow: user joins with ETH, we swap ETH for ERC20 stablecoin,  we deposit token into harvest vault and earn ftoken , then we stake the received ftoken)
 - [**HarvestSC.sol**](https://github.com/cryptotechmaker/polkastrategies/blob/feature/launch-pad/contracts/strategies/Harvest/HarvestSC.sol)  (deposit flow: user joins with ERC20 stablecoin,  we deposit token into harvest vault and earn ftoken , then we stake the received ftoken)
 - [**SushiSLP.sol**](https://github.com/cryptotechmaker/polkastrategies/blob/feature/launch-pad/contracts/strategies/Sushi/SushiSLP.sol) (deposit flow: user joins with SLP token, we deposit the slp token to masterchef)

 ## Factories
  - [**SushiSLPFactory.sol**](https://github.com/cryptotechmaker/polkastrategies/blob/feature/launch-pad/contracts/factory/sushiswap/SushiSLPFactory.sol) Factory contract for deployment of SushiSLP.sol strategy contract
  - [**HarvestEthFactory.sol**](https://github.com/cryptotechmaker/polkastrategies/blob/feature/launch-pad/contracts/factory/harvest/HarvestEthFactory.sol) Factory contract for deployment of Harvest.sol strategy contract
  - [**HarvestSCFactory.sol**](https://github.com/cryptotechmaker/polkastrategies/blob/feature/launch-pad/contracts/factory/harvest/HarvestSCFactory.sol) Factory contract for deployment of HarvestSC.sol strategy contract
## Router
  - [**StrategyRouter.sol**](https://github.com/cryptotechmaker/polkastrategies/blob/feature/launch-pad/contracts/router/StrategyRouter.sol) Interacts with Factory contracts to deploy strategies.

## Proxy
  - [**StrategyBeacon.sol**](https://github.com/cryptotechmaker/polkastrategies/blob/feature/launch-pad/contracts/proxy/StrategyBeacon.sol) This contract is used in conjunction with one or more instances of {StrategyProxy} to determine their implementation contract, which is where they will delegate all function calls
  - [**StrategyProxy.sol**](https://github.com/cryptotechmaker/polkastrategies/blob/feature/launch-pad/contracts/proxy/StrategyProxy.sol)  Proxy contract, delegates calls to strategy implementation (Strategies section above) contract. A proxy is deployed for each strategy implementation, retrieves implementation address from StrategyBeacon.

## Run tests
  To run unit tests 
  ```
  hardhat test
  ```

## Deployment 
  Create .env.keys file at project repository root and provide values for the following keys
  ```
  INFURA_API_KEY = 
  PRIVATE_KEY_1 = 
  PRIVATE_KEY_2 = 
  PRIVATE_KEY_3 = 
  ```
  Deploy to mainnet 
  ```
    hardhat deploy:mainnet
  ```
  Deploy to polygon 
  ```
    hardhat deploy:polygon
  ```
  Deploy to polygon testnet 
  ```
    hardhat deploy:mumbai
  ```
  Deploy to kovan 
  ```
    hardhat deploy:kovan
  ```
  Deploy to rinkeby 
  ```
    hardhat deploy:rinkeby
  ```
  Deploy to ganache 
  ```
    hardhat deploy:ganache
  ```
   