// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHarvestVault {
    function deposit(uint256 amount) external;

    function withdraw(uint256 numberOfShares) external;
}
