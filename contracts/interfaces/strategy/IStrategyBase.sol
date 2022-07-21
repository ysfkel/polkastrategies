// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStrategyAccessControl.sol";
interface IStrategyBase is IStrategyAccessControl {

    function setCap(uint256 _cap) external;

    function setTreasury(address payable _feeAddress) external;

    function setFeeAddress(address payable _feeAddress) external;

    function setFee(uint256 _fee) external; 

    function setWethAddress(address _weth) external;

    function setLockTime(uint256 _lockTime) external;

    function setSushiswapRouter(address _sushiswapRouter) external;
}
