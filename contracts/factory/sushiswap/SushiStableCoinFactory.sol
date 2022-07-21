// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../interfaces/strategy/IInitializableSushiStableCoin.sol";
import "../../proxy/StrategyProxy.sol";
import "./SushiFactoryBase.sol";
import "../../interfaces/factory/ISushiStableCoinStrategyFactory.sol";

contract SushiStableCoinFactory is SushiFactoryBase, ISushiStableCoinStrategyFactory {
 
    constructor(
            address _masterChef,
            address _sushiswapRouter,
            address _sushiswapFactory,
            address _sushi,
            address _weth,
            address _strategyBeacon) 
            SushiFactoryBase(_masterChef, _sushiswapRouter,_sushiswapFactory, _sushi, _weth, _strategyBeacon) {    
    }

    event StrategyCreated(address _owner, address _proxy);

    function createStrategy(  
        address payable _treasuryAddress,
        address payable _feeAddress,
        address _ownerAccount) external requireBeacon onlyRouter override returns(address _strategyProxy)  {

        StrategyProxy _proxy = new StrategyProxy(strategyBeacon);  
            
        IInitializableSushiStableCoin(address(_proxy)).initialize(
            masterChef,
            sushiswapFactory,
            sushiswapRouter,
            weth,
            sushi,
            _treasuryAddress,
            _feeAddress);

        IInitializableSushiStableCoin(address(_proxy)).grantOwnerRole(_ownerAccount);
         
        _addStrategy(_ownerAccount, address(_proxy)); 

        emit StrategyCreated(_ownerAccount, address(_proxy));

        return address(_proxy);
    }
 
}