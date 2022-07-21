// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStrategyAccessControl.sol";
interface IInitializableSushiSLP  is IStrategyAccessControl {

    function initialize(    
        address _masterChef,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _token,
        address _weth,
        address _sushi,
        address payable _treasuryAddress,
        address payable _feeAddress,
        uint256 _poolId,
        address _slp,
        address _receiptToken) external;
}

