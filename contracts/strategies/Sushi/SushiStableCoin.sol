// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { DataTypes, StableCoinsDataTypes as SCDataTypes } from "../../libraries/sushi/DataTypes.sol";
import { AssetLib , UserDepositInfoLib } from "../../libraries/sushi/AssetLib.sol";
import {SushiSLPBase, IERC20  } from "./SushiSLPBase.sol"; 
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReceiptToken} from "../../tokens/ReceiptToken.sol";

contract SushiStableCoin is SushiSLPBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using AssetLib for DataTypes.Asset;
    using UserDepositInfoLib for DataTypes.UserDepositInfo;
    
    mapping(address => DataTypes.Asset) public assets;
    // user => token
    mapping(address => mapping(address => DataTypes.UserDepositInfo)) public userInfo;
    function initialize (
        address _masterChef,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _weth,
        address _sushi,
        address payable _treasuryAddress,
        address payable _feeAddress
       ) external initializer {
          
          __SushiSLPBase_init(
            _masterChef,
            _sushiswapFactory,
            _sushiswapRouter,
            _weth,
            _sushi,
            _treasuryAddress,
            _feeAddress);
     }

    /**
     * @notice Deposit to this strategy for rewards
     * @param deadline Number of blocks until transaction expires
     */
    function deposit(address _asset, uint256 _amount,  uint256 slippage, uint256 ethPerToken, uint256 deadline) external nonReentrant {
        require(_asset != address(0), "!address__asset");
        require(assets[_asset].initialized, "!asset_initialized"); 

        _validateDeposit(deadline, _amount, assets[_asset].totalAmount, slippage);

        SCDataTypes.DepositData memory _data;
        // ----
        // swap half token to ETH 
        // ---
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
       
        uint256 _halfAmount = _amount.div(2);   
        address[] memory swapPath = new address[](2);
        swapPath[0] = _asset; 
        swapPath[1] =  weth;

        uint256 _obtainedEth = _swapTokenToEth(swapPath, _halfAmount, deadline, slippage, ethPerToken);   

        (
            _data.liquidityTokenAmount,
            _data.liquidityEthAmount,
            _data.liquidity
        ) = _addLiquidity(
            _asset,
            _obtainedEth,
            _halfAmount,
            deadline
        );

        DataTypes.UserDepositInfo storage _depositInfo = userInfo[msg.sender][_asset];

        assets[_asset].increaseAmount(_amount); 

        _depositInfo.increaseAmount(_amount);

        _deposit(_depositInfo, assets[_asset], _data.liquidity);
 
    }

    function withdraw(address  _asset, uint256 amount, uint256 tokensPerEth, uint256 slippage, uint256 deadline) external nonReentrant returns(uint256) {
        require(assets[_asset].initialized, "!asset");
        
        SCDataTypes.WithdrawData memory w;
        
        DataTypes.UserDepositInfo storage _depositInfo = userInfo[msg.sender][_asset];

        _validateWithdraw(
            deadline,
            amount,
            _depositInfo.amount,
            ReceiptToken(assets[_asset].receipt).balanceOf(msg.sender),
            _depositInfo.timestamp
        );


        (uint256 totalSushi, uint256 slpAmount)  =  _withdraw(_depositInfo, assets[_asset], amount);
               
        // remove liquidity & convert everything to deposited asset
        
        w.pair = sushiswapFactory.getPair(_asset, weth);
       
        (
            w.tokenLiquidityAmount,
            w.ethLiquidityAmount
        ) = _removeLiquidity(_asset, w.pair, slpAmount, deadline);

        require(w.tokenLiquidityAmount > 0, "TOKEN_LIQUIDITY_0");
        require(w.ethLiquidityAmount > 0, "ETH_LIQUIDITY_0");

        // -----
        // swap eth obtained from removing liquidity with token
        // -----
        if (w.ethLiquidityAmount > 0) { 
            w.swapPath[0] = weth;
            w.swapPath[1] = _asset; 
            w.obtainedToken = _swapEthToToken(w.swapPath, w.ethLiquidityAmount, deadline, slippage, tokensPerEth);
        }

         w.totalTokenAmount = w.tokenLiquidityAmount.add(w.obtainedToken);

        _depositInfo.decreaseAmount(w.totalTokenAmount);

         assets[_asset].decreaseAmount(w.totalTokenAmount); 

        // -----
        // calculate asset fee
        // -----
        uint256 _feeToken = 0;

        if (fee > 0) {
            //calculate fee
            _feeToken = _calculateFee(w.totalTokenAmount);
            w.totalTokenAmount = w.totalTokenAmount.sub(_feeToken);
            IERC20(_asset).safeTransfer(feeAddress, _feeToken);
            _depositInfo.increasePaidFees(_feeToken); 
        }

        IERC20(_asset).safeTransfer(msg.sender, w.totalTokenAmount);

        return totalSushi;
    }

    function totalAssetInvested(address _asset) external view returns(uint256) {
        return assets[_asset].totalAmount;
    }

    /**
     * @notice Update the pool id
     * @dev Can only be called by the owner
     * @param _pid pool id
     */
    function updatePoolId(address _asset, uint256 _pid) external onlyOwner {
        require(assets[_asset].initialized, "!initialized_asset_call_initAsset");
        emit ChangedValue("POOLID", assets[_asset].poolId, _pid);
        assets[_asset].poolId = _pid;
    }

    /**
     * @notice Update the address of TOKEN
     * @dev Can only be called by the owner
     * @param _asset Address of TOKEN
     */
    function updateTokenAddress(address _asset) external onlyOwner {
        require(_asset != address(0), "0x0");
        require(assets[_asset].initialized, "!initialized_asset_call_initAsset");
        emit ChangedAddress("TOKEN", address(assets[_asset].token), address(_asset));
        assets[_asset].token = _asset;
    }

    /**
     * @notice Update the address of TOKEN
     * @dev Can only be called by the owner
     * @param _slp Address of TOKEN
     */
    function updateSLP(address _asset, address _slp) external onlyOwner {
        require(_slp != address(0), "0x0");
        require(assets[_asset].initialized, "!initialized_asset_call_initAsset");
        emit ChangedAddress("TOKEN", address(assets[_asset].slp), address(_slp));
        assets[_asset].slp = _slp;
    }

    /**
     * @notice Update the address of TOKEN
     * @dev Can only be called by the owner
     * @param _receipt Address of TOKEN
     */
    function updateReceipt(address _asset, address _receipt) external onlyOwner {
        require(_receipt != address(0), "0x0");
        require(assets[_asset].initialized, "!initialized_asset_call_initAsset");
        emit ChangedAddress("TOKEN", address(assets[_asset].receipt), address(_receipt));
        assets[_asset].receipt = _receipt;
    }

    /**
    * @dev initializes an asset. i.e a supported stable coin which may be deposited
    * @param _asset address of the stable coin
    * @param _receipt address of receipt token
    * @param _slp address of slp token <_asset>-ETH
    * @param _poolId the masterchef pool id  
    */
    function initAsset(address _asset, address _receipt, address _slp, uint256 _poolId ) external onlyOwner{
        require(_asset != address(0), "!address__asset");
        require(_receipt != address(0), "!address__receipt");
        require(_slp != address(0), "!address_slp");
        
        assets[_asset].initialize(_asset, _receipt, _slp, _poolId);
    } 
 
    function receipt(address _asset) external view returns(address) {
        return assets[_asset].receipt;
    }

    receive() external payable {}
}
