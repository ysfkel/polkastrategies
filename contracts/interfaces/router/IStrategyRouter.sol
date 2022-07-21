// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
interface IStrategyRouter {  
    function createHarvestEthStrategy( address _harvestfToken, address _token, address payable _treasuryAddress,address payable _feeAddress) external returns(address _strategyProxy);

    function createHarvestSCStrategy(address _harvestfToken,address _token,  address payable _treasuryAddress, address payable _feeAddress) external returns(address _strategyProxy);

    function createSushiSLPStrategy(address _token,address payable _treasuryAddress, address payable _feeAddress,  uint256 _poolId, address _slp) external returns(address _strategyProxy);

    function createSushiStableCoinStrategy(address payable _treasuryAddress, address payable _feeAddress) external returns(address _strategyProxy);
 
}