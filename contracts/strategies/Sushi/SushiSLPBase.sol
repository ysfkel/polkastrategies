// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./base/SushiBase.sol";
import { StrategyBase } from "../base/StrategyBase.sol";
import { DataTypes, SushiSLPBaseDataTypes } from "../../libraries/sushi/DataTypes.sol";
import { AssetLib  } from "../../libraries/sushi/AssetLib.sol";
import "../../tokens/ReceiptToken.sol";
/*
  |Strategy Flow| 
      - User shows up with an ETH/USDT-SLP, ETH/WBTC-SLP or ETH/yUSD-SLP
      - Then we deposit SLPs in MasterChef and we get SUSHI rewards

    - Withdrawal flow does same thing, but backwards. 
*/
abstract contract SushiSLPBase is StrategyBase, SushiBase,  ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AssetLib for DataTypes.Asset;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /**
     * @notice Create a new SushiSLP contract
     * @param _masterChef SushiSwap MasterChef address
     * @param _sushiswapFactory Sushiswap Factory address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _weth WETH address
     * @param _sushi SUSHI address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function __SushiSLPBase_init (
        address _masterChef,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _weth,
        address _sushi,
        address payable _treasuryAddress,
        address payable _feeAddress) internal initializer  {
        __ReentrancyGuard_init();

        __SushiBase_init(
            _masterChef,
            _sushiswapFactory,
            _sushiswapRouter,
            _weth,
            _sushi,
            _treasuryAddress,
            _feeAddress,
            1000 * (10**18));
    }

    /// @notice Event emitted when user withdraws
    event MasterchefWithdrawComplete(
        address indexed user,
        address indexed origin,
        uint256 pid,
        uint256 userSlp,
        uint256 userSushi,
        uint256 treasurySushi,
        uint256 feeSushi
    );

    /**
     * @notice Deposit to this strategy for rewards
     */
    function _deposit(DataTypes.UserDepositInfo storage _user, DataTypes.Asset memory _asset, uint256 slpAmount) internal  {
       
        SushiSLPBaseDataTypes.DepositData memory results; 

        _user.timestamp = block.timestamp;

        ReceiptToken(_asset.receipt).mint(msg.sender, slpAmount);
        
        emit ReceiptMinted(msg.sender, slpAmount);

        // update rewards
        // -----
        (
            _user.amount,
            results.pendingSushiTokens,
            _user.sushiRewardDebt
        ) = _updatePool(_user.amount, _user.sushiRewardDebt, slpAmount, _asset.poolId);

        // -----
        // deposit into master chef
        // -----
        uint256 prevSushiBalance = IERC20(sushi).balanceOf(address(this));
        _increaseAllowance(_asset.slp, address(masterChef), slpAmount);
        masterChef.deposit(_asset.poolId, slpAmount);

        if (results.pendingSushiTokens > 0) {
            uint256 sushiBalance = IERC20(sushi).balanceOf(address(this));
            if (sushiBalance > prevSushiBalance) {
                uint256 actualSushiTokens = sushiBalance.sub(prevSushiBalance);

                if (results.pendingSushiTokens > actualSushiTokens) {
                    _user.userAccumulatedSushi = _user.userAccumulatedSushi.add(
                        actualSushiTokens
                    );
                } else {
                    _user.userAccumulatedSushi = _user.userAccumulatedSushi.add(
                        results.pendingSushiTokens
                    );
                }
             }
        }

         emit Deposit(msg.sender, tx.origin, _asset.poolId, slpAmount);
    }

    /**
     * @notice Withdraw tokens and claim rewards
     * @return Amount of ETH obtained
     */
    function _withdraw(DataTypes.UserDepositInfo storage _user, DataTypes.Asset storage _asset,  uint256 amount) internal  returns (uint256, uint256) {
 
        DataTypes.WithdrawData memory w;
 
        w.oldAmount = _user.amount;

        DataTypes.WithdrawData memory results;
        // -----
        // withdraw from sushi master chef
        // -----
        masterChef.updatePool(_asset.poolId);

        w.pendingSushiTokens =
            w.oldAmount
                .mul(masterChef.poolInfo(_asset.poolId).accSushiPerShare)
                .div(1e12)
                .sub(_user.sushiRewardDebt);

        results.slpAmount = _masterChefWithdraw(amount, _asset.slp, _asset.poolId);
        require(results.slpAmount > 0, "SLP_AMOUNT_0");

        // -----
        // burn parachain auction token
        // -----
        _burnParachainAuctionTokens(_asset.receipt, amount);

        _user.sushiRewardDebt = _user
            .amount
            .mul(masterChef.poolInfo(_asset.poolId).accSushiPerShare)
            .div(1e12);

        w.sushiBalance = IERC20(sushi).balanceOf(address(this));
        if (w.pendingSushiTokens > 0) {
            if (w.pendingSushiTokens > w.sushiBalance) {
                _user.userAccumulatedSushi = _user.userAccumulatedSushi.add(
                    w.sushiBalance
                );
            } else {
                _user.userAccumulatedSushi = _user.userAccumulatedSushi.add(
                    w.pendingSushiTokens
                );
            }
        }

        if (_user.userAccumulatedSushi > w.sushiBalance) {
            results.totalSushi = w.sushiBalance;
        } else {
            results.totalSushi = _user.userAccumulatedSushi;
        }

        results.treasurySushi = results.totalSushi.div(2);
        results.userSushi = results.totalSushi.sub(results.treasurySushi); 

        // -----
        // transfer Sushi to treasury
        // -----
        IERC20(sushi).safeTransfer(treasuryAddress, results.treasurySushi);
        _user.treasurySushi = _user.treasurySushi.add(results.treasurySushi);
        emit RewardsEarned(
            msg.sender,
            treasuryAddress,
            "Sushi",
            results.treasurySushi
        );

        // -----
        // calculate fee, remove liquidity for it and tranfer it to the fee address
        // -----
        w.feeSushi = 0;
        if (fee > 0) {
            //calculate fee 
            w.feeSushi = _calculateFee(results.userSushi);
            results.userSushi = results.userSushi.sub(w.feeSushi);
            IERC20(sushi).safeTransfer(feeAddress, w.feeSushi);
            _user.feeSushi = _user.feeSushi.add(w.feeSushi);
            emit RewardsEarned(msg.sender, feeAddress, "Sushi", w.feeSushi);
        }

        // -----
        // transfer Sushi to the user
        // -----
        IERC20(sushi).safeTransfer(msg.sender, results.userSushi);
        _user.earnedSushi = _user.earnedSushi.add(results.userSushi);
        emit RewardsEarned(msg.sender, msg.sender, "Sushi", results.userSushi);
   
   
        emit MasterchefWithdrawComplete(
            msg.sender,
            tx.origin,
            _asset.poolId,
            results.slpAmount,
            results.userSushi,
            results.treasurySushi,
            w.feeSushi
        );

        _user.userAccumulatedSushi = 0;

        return (results.totalSushi, results.slpAmount);
    }
    
}
