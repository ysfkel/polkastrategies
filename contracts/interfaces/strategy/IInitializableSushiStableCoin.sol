// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStrategyAccessControl.sol";
interface IInitializableSushiStableCoin  is IStrategyAccessControl {

    function initialize(    
        address _masterChef,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _weth,
        address _sushi,
        address payable _treasuryAddress,
        address payable _feeAddress) external;
}

