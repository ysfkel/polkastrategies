// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../base/StrategyFactoryBase.sol";
contract SushiFactoryBase is StrategyFactoryBase {
 
    address public masterChef;
    address public sushiswapFactory;
    address public sushi;

    constructor(
            address _masterChef,
            address _sushiswapRouter,
            address _sushiswapFactory,
            address _sushi,
            address _weth,
            address _strategyBeacon) StrategyFactoryBase(_sushiswapRouter, _weth, _strategyBeacon) { 
            
            require(_masterChef != address(0), "!address__masterChef");
            require(_sushiswapFactory != address(0), "!address__sushiswapFactory");
            require(_sushi != address(0), "!address__sushi"); 

         masterChef = _masterChef;
         sushiswapFactory = _sushiswapFactory;
         sushi = _sushi;
    }

    function setMasterChef(address _masterChef) external onlyAdmin {
        require(address(_masterChef) != address(0), "ADDRESS_0x0");
           masterChef= _masterChef;
    }
    function setSushiswapFactory(address _sushiswapFactory) external onlyAdmin {
        require(address(_sushiswapFactory) != address(0), "ADDRESS_0x0");
           sushiswapFactory= _sushiswapFactory;
    }
    function setSushi(address _sushi) external onlyAdmin {
        require(address(_sushi) != address(0), "ADDRESS_0x0");
           sushi= _sushi;
    }

}