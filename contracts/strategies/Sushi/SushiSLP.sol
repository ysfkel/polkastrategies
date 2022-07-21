// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
pragma experimental ABIEncoderV2; 
import {SushiSLPBase } from "./SushiSLPBase.sol"; 
import { DataTypes } from "../../libraries/sushi/DataTypes.sol";
import { AssetLib, UserDepositInfoLib  } from "../../libraries/sushi/AssetLib.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/strategy/IInitializableSushiSLP.sol";

import {ReceiptToken} from "../../tokens/ReceiptToken.sol";

contract SushiSLP is SushiSLPBase, IInitializableSushiSLP {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using AssetLib for DataTypes.Asset;
    using UserDepositInfoLib for DataTypes.UserDepositInfo;

    DataTypes.Asset public asset; 
    mapping(address => DataTypes.UserDepositInfo) public userInfo;
     function initialize (
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
        address _receiptToken
       ) external override initializer {
          require(_slp != address(0), "!address_slp");
          require(_token != address(0), "!address_token");
          require(_receiptToken != address(0), "!address_receiptToken");
          
          __SushiSLPBase_init(
            _masterChef,
            _sushiswapFactory,
            _sushiswapRouter,
            _weth,
            _sushi,
            _treasuryAddress,
            _feeAddress);

        _initAsset(_token, _receiptToken, _slp, _poolId);
     }

    /// @notice Event emitted when user withdraws
    event WithdrawComplete(
        address indexed user,
        address indexed origin,
        uint256 userSlp, 
        uint256 feeSlp
    );

    /**
     * @notice Deposit to this strategy for rewards
     * @param amount slp token amount
     */
    function deposit(uint256 amount) external nonReentrant {
        // -----
        // validate
        // ----- 
        require(amount > 0, "AMOUNT_0"); 
        if(cap > 0) {
            require(asset.totalAmount.add(amount) <= cap, "CAP_REACHED");
        }

        DataTypes.UserDepositInfo storage user = userInfo[msg.sender];

        asset.increaseAmount(amount); 

        user.increaseAmount(amount); 

        IERC20(asset.slp).safeTransferFrom(msg.sender, address(this), amount);

        _deposit(user, asset, amount);
    }

    function withdraw(uint256 amount) external nonReentrant returns (uint256)   {
        require(asset.initialized, "!asset");
        require(amount > 0, "!amount_0");

        DataTypes.UserDepositInfo storage user = userInfo[msg.sender];

        require(user.amount >= amount, "insuffient_balance");
        require(ReceiptToken(asset.receipt).balanceOf(msg.sender) >= amount, "insuffient_receipt_balance");

        if (lockTime > 0) {
            require(user.timestamp.add(lockTime) <= block.timestamp, "!locktime");
        }

        userInfo[msg.sender].decreaseAmount(amount);

        asset.decreaseAmount(amount); 

        (uint256 totalSushi,  uint256 slpAmount)  =  _withdraw(user, asset, amount);

        // -----
        // calculate slp fee
        // -----
        uint256 _feeSLP = 0;
        if (fee > 0) {
            //calculate fee
            _feeSLP = _calculateFee(slpAmount);
            slpAmount = slpAmount.sub(_feeSLP);
            IERC20(asset.slp).safeTransfer(feeAddress, _feeSLP);
             user.increasePaidFees(_feeSLP);  
        }

        // -----
        // transfer SLP & Sushi to the user
        // -----
        IERC20(asset.slp).safeTransfer(msg.sender, slpAmount);   

        emit WithdrawComplete(
            msg.sender,
            tx.origin,  
            slpAmount, 
            _feeSLP
        );  

        return totalSushi;
    }

    /**
     * @notice Update the pool id
     * @dev Can only be called by the owner
     * @param _pid pool id
     */
    function updatePoolId(uint256 _pid) external onlyOwner {
        require(asset.initialized, "!initialized_asset_call_initAsset");
        emit ChangedValue("POOLID", asset.poolId, _pid);
        asset.poolId = _pid;
    }

    /**
     * @notice Update the address of TOKEN
     * @dev Can only be called by the owner
     * @param _token Address of TOKEN
     */
    function updateTokenAddress(address _token) external onlyOwner {
        require(_token != address(0), "0x0");
        require(asset.initialized, "!initialized_asset_call_initAsset");
        emit ChangedAddress("TOKEN", address(asset.token), address(_token));
        asset.token = _token;
    }

    /**
     * @notice Update the address of TOKEN
     * @dev Can only be called by the owner
     * @param _slp Address of TOKEN
     */
    function updateSLP(address _slp) external onlyOwner {
        require(_slp != address(0), "0x0");
        require(asset.initialized, "!initialized_asset_call_initAsset");
        emit ChangedAddress("TOKEN", address(asset.slp), address(_slp));
        asset.slp = _slp;
    }

    /**
     * @notice Update the address of TOKEN
     * @dev Can only be called by the owner
     * @param _receipt Address of TOKEN
     */
    function updateReceipt(address _receipt) external onlyOwner {
        require(_receipt != address(0), "0x0");
        require(asset.initialized, "!initialized_asset_call_initAsset");
        emit ChangedAddress("TOKEN", address(asset.receipt), address(_receipt));
        asset.receipt = _receipt;
    }

    /**
     @dev returns token address - token to be deposited by users
     */
    function token() external view returns(address) {
        return asset.token;
    }

    /**
     @dev returns sushiswap pool id
     */
    function poolId() external view returns(uint256) {
        return asset.poolId;
    }

    /**
     @dev returns slp addres
     */
    function slp() external view returns(address) {
        return asset.slp;
    }
    
    /**
     @dev returns receipt token addres
     */
    function receipt() external view returns(address) {
        return asset.receipt;
    }

    /**
    * @dev initializes an asset. i.e a supported stable coin which may be deposited
    * @param _asset address of the stable coin
    * @param _receipt address of receipt token
    * @param _slp address of slp token <_asset>-ETH
    * @param _poolId the masterchef pool id  
    */
    function initAsset(address _asset, address _receipt, address _slp, uint256 _poolId) external onlyOwner {
          _initAsset(_asset, _receipt, _slp, _poolId);
    }

    /**
    * @dev initializes an asset. i.e a supported stable coin which may be deposited
    * @param _asset address of the stable coin
    * @param _receipt address of receipt token
    * @param _slp address of slp token <_asset>-ETH
    * @param _poolId the masterchef pool id  
    */
    function _initAsset(address _asset, address _receipt, address _slp, uint256 _poolId) private {
          asset.initialize(_asset, _receipt, _slp, _poolId);
    }

    function totalInvested() external view returns(uint256) {
        return asset.totalAmount;
    }
}