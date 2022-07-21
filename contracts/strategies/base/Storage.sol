// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../../tokens/ReceiptToken.sol";
import "../../interfaces/sushiswap/IUniswapRouter.sol";

contract Storage{
    address public weth;
    address payable public treasuryAddress;
    address payable public feeAddress;
    // address public token;
    IUniswapRouter public sushiswapRouter;
    uint256 internal _minSlippage = 10; //0.1%
    uint256 public lockTime = 1;
    uint256 public fee = uint256(100);
    uint256 constant feeFactor = uint256(10000);
    uint256 public cap;
    bytes32 public constant OWNER_ROLE = keccak256("STRATEGY.OWNER");

}

