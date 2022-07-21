// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStrategyAccessControl.sol";
interface IInitializableHarvestETH is IStrategyAccessControl   {
    function initialize(    
         address _harvestRewardVault,
        address _harvestRewardPool,
        address _sushiswapRouter,
        address _harvestfToken,
        address _farmToken,
        address _token,
        address _weth,
        address payable _treasuryAddress,
        address payable _feeAddress,
        address _receiptToken) external;
}

