// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../interfaces/sushiswap/IUniswapFactory.sol";
import "../../../interfaces/sushiswap/IMasterChef.sol";
import "../../../interfaces/strategy/IStrategy.sol";
import "../../../interfaces/strategy/ISushi.sol";
import { StrategyBase } from "../../base/StrategyBase.sol";
import "./Storage.sol";

abstract contract SushiBase is Storage,  StrategyBase, ISushi, IStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Events -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    event RewardsExchanged(
        address indexed user,
        uint256 rewardsAmount,
        uint256 obtainedEth
    );
     event RewardsEarned(
        address indexed user,
        address indexed to,
        string indexed rewardType,
        uint256 amount
    );
    /// @notice Event emitted when owner changes the master chef pool id
    event PoolIdChanged(address indexed sender, uint256 oldPid, uint256 newPid);

    /// @notice Event emitted when user makes a deposit
    event Deposit(
        address indexed user,
        address indexed origin,
        uint256 pid,
        uint256 amount
    );

    /// @notice Event emitted when owner makes a rescue dust request
    event RescuedDust(string indexed dustType, uint256 amount);

      /**
     * @notice Create a new SushiETHSLP contract
     * @param _weth WETH address
     * @param _sushi SUSHI address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _sushiswapFactory Sushiswap Factory address
     * @param _masterChef SushiSwap MasterChef address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function __SushiBase_init(
        address _masterChef,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _weth,
        address _sushi,
        address payable _treasuryAddress,
        address payable _feeAddress,
        uint256 _cap) internal initializer {
       
        require(_masterChef != address(0), "CHEF_0x0");
        require(_sushiswapFactory != address(0), "FACTORY_0x0");
        require(_sushi != address(0), "SUSHI_0x0");
        require(_treasuryAddress != address(0), "TREASURY_0x0");
        require(_feeAddress != address(0), "FEE_0x0");

        __StrategyBase_init(_sushiswapRouter,  _weth, _treasuryAddress,  _feeAddress,_cap);

        sushi = _sushi;
        sushiswapFactory = IUniswapFactory(_sushiswapFactory);
        masterChef = IMasterChef(_masterChef);
        // masterChefPoolId = _poolId;
        // slp = _slp;
    }

    /**
     * @notice Update the address of Sushi
     * @dev Can only be called by the owner
     * @param _sushi Address of Sushi
     */
    function setSushiAddress(address _sushi) external override onlyOwner {
        require(_sushi != address(0), "0x0");
        emit ChangedAddress("SUSHI", address(sushi), address(_sushi));
        sushi = _sushi;
    }

    /**
     * @notice Update the address of Sushiswap Factory
     * @dev Can only be called by the owner
     * @param _sushiswapFactory Address of Sushiswap Factory
     */
    function setSushiswapFactory(address _sushiswapFactory)
        external
        override
        onlyOwner
    {
        require(_sushiswapFactory != address(0), "0x0");
        emit ChangedAddress(
            "SUSHISWAP_FACTORY",
            address(sushiswapFactory),
            address(_sushiswapFactory)
        );
        sushiswapFactory = IUniswapFactory(_sushiswapFactory);
    }

    /**
     * @notice Update the address of Sushiswap Masterchef
     * @dev Can only be called by the owner
     * @param _masterChef Address of Sushiswap Masterchef
     */
    function setMasterChef(address _masterChef) external override onlyOwner {
        require(_masterChef != address(0), "0x0");
        emit ChangedAddress(
            "MASTER_CHEF",
            address(masterChef),
            address(_masterChef)
        );
        masterChef = IMasterChef(_masterChef);
    }

    /**
     * @notice Rescue dust resulted from swaps/liquidity
     * @dev Can only be called by the owner
     */
    function rescueDust() external override onlyOwner {
        if (ethDust > 0) {
            safeTransferETH(treasuryAddress, ethDust);
            treasueryEthDust = treasueryEthDust.add(ethDust);
            emit RescuedDust("ETH", ethDust);
            ethDust = 0;
        } 
    }

    /**
     * @notice Rescue tiken dust resulted from swaps/liquidity
     * @dev Can only be called by the owner
     */
    function rescueTokenDust(address token) external onlyOwner {
        if (tokenDust > 0) {
            IERC20(token).safeTransfer(treasuryAddress, tokenDust);
            treasuryTokenDust = treasuryTokenDust.add(tokenDust);
            emit RescuedDust("TOKEN", tokenDust);
            tokenDust = 0;
        }
    }

    /**
     * @notice Rescue any non-reward token that was airdropped to this contract
     * @dev Can only be called by the owner
     */
    function rescueAirdroppedTokens(address _token, address to)
        external
        override
        onlyOwner
    {
        require(_token != address(0), "token_0x0");
        require(to != address(0), "to_0x0");
        require(_token != sushi, "rescue_reward_error");

        uint256 balanceOfToken = IERC20(_token).balanceOf(address(this));
        require(balanceOfToken > 0, "balance_0");

        require(IERC20(_token).transfer(to, balanceOfToken), "rescue_failed");
    }
    

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Internal methods -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    function _validateWithdraw(
        uint256 deadline,
        uint256 amount,
        uint256 userAmount,
        uint256 receiptBalance,
        uint256 timestamp
    ) internal view {
        _validateCommon(deadline, amount, 1000);

        require(userAmount >= amount, "AMOUNT_GREATER_THAN_BALANCE");
 
        require(receiptBalance >= amount, "RECEIPT_AMOUNT");

        if (lockTime > 0) {
            require(timestamp.add(lockTime) <= block.timestamp, "LOCK_TIME");
        }
    }

    function _addLiquidity(
        address _token,
        uint256 amountEth,
        uint256 amount,
        uint256 deadline
    )
        internal
        returns (
            uint256 liquidityTokenAmount,
            uint256 liquidityEthAmount,
            uint256 liquidity
        )
    {
        _increaseAllowance(_token, address(sushiswapRouter), amount);
        
        (liquidityTokenAmount, liquidityEthAmount, liquidity) = sushiswapRouter
            .addLiquidityETH{value: amountEth}(
            _token,
            amount,
            uint256(0),
            uint256(0),
            address(this),
            deadline
        );
    }

    function _removeLiquidity(
        address _token,
        address _pair,
        uint256 slpAmount,
        uint256 deadline
    )
        internal
        returns (uint256 tokenLiquidityAmount, uint256 ethLiquidityAmount)
    {
        _increaseAllowance(_pair, address(sushiswapRouter), slpAmount);

        (tokenLiquidityAmount, ethLiquidityAmount) = sushiswapRouter
            .removeLiquidityETH(
            _token,
            slpAmount,
            uint256(0),
            uint256(0),
            address(this),
            deadline
        );
    }

    function _updatePool(
        uint256 amount,
        uint256 sushiRewardDebt,
        uint256 liquidity,
        uint256 masterChefPoolId
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        masterChef.updatePool(masterChefPoolId);
        uint256 pendingSushiTokens =
            amount
                .mul(masterChef.poolInfo(masterChefPoolId).accSushiPerShare)
                .div(1e12)
                .sub(sushiRewardDebt);

        amount = amount.add(liquidity);

        masterChef.updatePool(masterChefPoolId);
        sushiRewardDebt = amount
            .mul(masterChef.poolInfo(masterChefPoolId).accSushiPerShare)
            .div(1e12);

        return (amount, pendingSushiTokens, sushiRewardDebt);
    }

    function _masterChefWithdraw(uint256 amount, address slp, uint256 masterChefPoolId) internal returns (uint256) {
        uint256 prevSlpAmount = IERC20(slp).balanceOf(address(this));

        masterChef.updatePool(masterChefPoolId);
        masterChef.withdraw(masterChefPoolId, amount);

        uint256 currentSlpAmount = IERC20(slp).balanceOf(address(this));
        if (currentSlpAmount <= prevSlpAmount) {
            return 0;
        }

        return currentSlpAmount.sub(prevSlpAmount);
    }

}
