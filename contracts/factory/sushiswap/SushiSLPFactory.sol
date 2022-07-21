// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../../interfaces/strategy/IInitializableSushiSLP.sol";
import "../../proxy/StrategyProxy.sol";
import "./SushiFactoryBase.sol";
import "../../interfaces/factory/ISushiSLPStrategyFactory.sol";

contract SushiSLPFactory is SushiFactoryBase, ISushiSLPStrategyFactory {

    ReceiptTokenFactory public receiptTokenFactory;
    constructor(
            address _masterChef,
            address _sushiswapRouter,
            address _sushiswapFactory,
            address _sushi,
            address _weth,
            address _receiptTokenFactory,
            address _strategyBeacon) 
            SushiFactoryBase(_masterChef, _sushiswapRouter,_sushiswapFactory, _sushi, _weth, _strategyBeacon) {  
            
            require(_receiptTokenFactory != address(0), "!address__receiptTokenFactory");  
        
        receiptTokenFactory = ReceiptTokenFactory(_receiptTokenFactory);
    }

    event StrategyCreated(address _owner, address _receiptToken, address _proxy);

    function createStrategy(  
        address _token,
        address payable _treasuryAddress,
        address payable _feeAddress,
        uint256 _poolId,
        address _slp,
        address _ownerAccount) external requireBeacon() onlyRouter override returns(address _strategyProxy)  {

        StrategyProxy _proxy = new StrategyProxy(strategyBeacon); 

        address _receiptToken = receiptTokenFactory.createReceiptToken(_slp, address(_proxy));
            
        IInitializableSushiSLP(address(_proxy)).initialize(
            masterChef,
            sushiswapFactory,
            sushiswapRouter,
            _token, 
            weth,
            sushi,
            _treasuryAddress,
            _feeAddress,
            _poolId,
            _slp,
            _receiptToken);

         IInitializableSushiSLP(address(_proxy)).grantOwnerRole(_ownerAccount);
         
        _addStrategy(_ownerAccount, address(_proxy)); 

        emit StrategyCreated(_ownerAccount,_receiptToken, address(_proxy));

        return address(_proxy);
    }

    function setReceiptTokenFactory(address _receiptTokenFactory) external onlyAdmin {
         require(_receiptTokenFactory != address(0), "ADDRESS_0x0");
           receiptTokenFactory = ReceiptTokenFactory(_receiptTokenFactory);
     }
 
}