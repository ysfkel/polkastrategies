// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "../base/StrategyFactoryBase.sol";
import "../../tokens/ReceiptToken.sol";

contract HarvestFactoryBase is StrategyFactoryBase {
    
    address public harvestRewardVault;
    address public harvestRewardPool;
    address public farmToken;

    ReceiptTokenFactory public receiptTokenFactory;
    constructor(
            address _harvestRewardVault,
            address _harvestRewardPool,
            address _sushiswapRouter,
            address _farmToken,
            address _weth,
            address _receiptTokenFactory,
            address _strategyBeacon
            ) StrategyFactoryBase(_sushiswapRouter, _weth, _strategyBeacon)  { 

            require(_harvestRewardVault != address(0), "!address__harvestRewardVault");
            require(_harvestRewardPool != address(0), "!address__harvestRewardPool");
            require(_farmToken != address(0), "!address__farmToken");
            require(_receiptTokenFactory != address(0), "!address__receiptTokenFactory");
            

         harvestRewardVault = _harvestRewardVault;
         harvestRewardPool = _harvestRewardPool;
         farmToken = _farmToken;
        receiptTokenFactory = ReceiptTokenFactory(_receiptTokenFactory);
    } 

    event StrategyCreated(address _owner, address _receiptToken, address _proxy);
    function setHarvestRewardVault(address _harvestRewardVault) external onlyAdmin {
        require(address(_harvestRewardVault) != address(0), "ADDRESS_0x0");
           harvestRewardVault= _harvestRewardVault;
    }
    function setHarvestRewardPool(address _harvestRewardPool) external onlyAdmin {
        require(address(_harvestRewardPool) != address(0), "ADDRESS_0x0");
           harvestRewardPool= _harvestRewardPool;
    }
    function setFarmToken(address _farmToken) external onlyAdmin {
        require(address(_farmToken) != address(0), "ADDRESS_0x0");
           farmToken= _farmToken;
    }

    function setReceiptTokenFactory(address _receiptTokenFactory) external onlyAdmin {
         require(_receiptTokenFactory != address(0), "ADDRESS_0x0");
           receiptTokenFactory = ReceiptTokenFactory(_receiptTokenFactory);
     }
  
}