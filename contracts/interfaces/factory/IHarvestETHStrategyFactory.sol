// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IHarvestETHStrategyFactory {
     function createStrategy(
        address _harvestfToken,
        address _token,
        address payable _treasuryAddress,
        address payable _feeAddress,
        address _ownerAccount) external returns(address _strategyProxy);
}