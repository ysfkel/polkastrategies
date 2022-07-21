// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface ISushiSLPStrategyFactory {
     function createStrategy(  
        address _token,
        address payable _treasuryAddress,
        address payable _feeAddress,
        uint256 _poolId,
        address _slp,
        address _ownerAccount) external returns(address _strategyProxy);
}