// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
 
import { IUniswapFactory } from "../../../interfaces/sushiswap/IUniswapFactory.sol";
import { IMasterChef } from "../../../interfaces/sushiswap/IMasterChef.sol"; 

contract Storage { 
    address public sushi;
    uint256 public ethDust;
    uint256 public tokenDust;
    uint256 public treasueryEthDust;
    uint256 public treasuryTokenDust; 
    IUniswapFactory public sushiswapFactory;
    IMasterChef public masterChef; 
}