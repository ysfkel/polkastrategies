// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./HarvestFactoryBase.sol";
import "../../proxy/StrategyProxy.sol";
import "../../interfaces/strategy/IInitializableHarvestETH.sol"; 
import "../../interfaces/factory/IHarvestETHStrategyFactory.sol";

contract HarvestEthFactory is  HarvestFactoryBase, IHarvestETHStrategyFactory {
    constructor(
            address _harvestRewardVault,
            address _harvestRewardPool,
            address _sushiswapRouter,
            address _farmToken,
            address _weth,
            address _receiptTokenFactory,
            address _strategyBeacon) HarvestFactoryBase(
                _harvestRewardVault, 
                _harvestRewardPool,
                _sushiswapRouter,
                _farmToken,
                _weth,
                _receiptTokenFactory,
                _strategyBeacon)  {  
    } 
    function createStrategy(
        address _harvestfToken,
        address _token,
        address payable _treasuryAddress,
        address payable _feeAddress, 
        address _ownerAccount) external requireBeacon onlyRouter override returns(address _strategyProxy) {
        
        StrategyProxy _proxy = new StrategyProxy(strategyBeacon); 
        
        address _receiptToken = receiptTokenFactory.createReceiptToken(_token, address(_proxy));

        IInitializableHarvestETH(address(_proxy)).initialize(
            harvestRewardVault,
             harvestRewardPool,
            sushiswapRouter,
            _harvestfToken, 
            farmToken,
            _token,
            weth,
            _treasuryAddress,
            _feeAddress,
            _receiptToken
        ); 

        IInitializableHarvestETH(address(_proxy)).grantOwnerRole(_ownerAccount);

        _addStrategy(_ownerAccount, address(_proxy)); 

        emit StrategyCreated(_ownerAccount,_receiptToken, address(_proxy));

        return address(_proxy);
    } 

}