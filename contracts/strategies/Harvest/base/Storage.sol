// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
import "../../../libraries/datatypes/HarvestDataTypes.sol";
import "../../../interfaces/strategy/IMintNoRewardPool.sol";
import "../../../interfaces/strategy/IHarvestVault.sol";
import { ReceiptToken } from "../../../tokens/ReceiptToken.sol";
contract Storage {
    address public farmToken;
    address public harvestfToken;
    uint256 public ethDust;
    uint256 public treasueryEthDust; 
    address public token;
    IMintNoRewardPool public harvestRewardPool;
    IHarvestVault public harvestRewardVault;
    mapping(address => HarvestDataTypes.UserInfo) public userInfo;
    uint256 public totalInvested; //total invested 
    ReceiptToken public receiptToken;
}