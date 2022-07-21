// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../libraries/datatypes/HarvestDataTypes.sol";
import "./base/HarvestBase.sol";
import "../../interfaces/strategy/IInitializableHarvestETH.sol"; 
/*
  |Strategy Flow| 
      - User shows up with ETH. 
      - We swap his ETH to Token and then we deposit it in Havest's Token Vault. 
      - After this we have fToken that we add in Harvest's Reward Pool which gives FARM as rewards

    - Withdrawal flow does same thing, but backwards. 
*/
contract Harvest is  HarvestBase, IInitializableHarvestETH, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    /// @notice Event emitted when rewards are exchanged to ETH or to a specific Token
    event RewardsExchanged(address indexed user,uint256 rewardsAmount,uint256 obtainedEth);
    /// @notice Event emitted when user makes a deposit
    event Deposit(address indexed user, address indexed origin,uint256 amountEth,uint256 amountToken,uint256 amountfToken);
    /// @notice Event emitted when user withdraws
    event Withdraw(address indexed user,address indexed origin,uint256 amountEth,uint256 amountToken,uint256 amountfToken, uint256 treasuryAmountEth);
    /**
     * @notice Create a new HarvestDAI contract
     * @param _harvestRewardVault VaultToken  address
     * @param _harvestRewardPool NoMintRewardPool address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _harvestfToken Pool's underlying token address
     * @param _farmToken Farm address
     * @param _token Token address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     * @param _receiptToken receipt token address
     */
    function initialize( 
        address _harvestRewardVault,
        address _harvestRewardPool,
        address _sushiswapRouter,
        address _harvestfToken,
        address _farmToken,
        address _token,
        address _weth,
        address payable _treasuryAddress, 
        address payable _feeAddress,
        address _receiptToken) external override initializer { 
       __ReentrancyGuard_init();
       __HarvestBase_init(
           _harvestRewardVault, 
           _harvestRewardPool,
           _sushiswapRouter,
           _harvestfToken,
           _farmToken,
           _token, 
           _weth, 
           _treasuryAddress, 
           _feeAddress, 
           _receiptToken,
            cap = 2000 * (10**18));
    }
    /**
     * @notice Deposit to this strategy for rewards
     * @param deadline Number of blocks until transaction expires
     * @return Amount of fToken
     */
    function deposit( uint256 deadline,uint256 slippage,uint256 tokensPerEth ) public payable  nonReentrant returns (uint256) {
        _validateDeposit(deadline, msg.value, totalInvested, slippage);
        _updateRewards(msg.sender);
        HarvestDataTypes.DepositData memory results;
        HarvestDataTypes.UserInfo storage user = userInfo[msg.sender];
        if (user.timestamp == 0) {
            user.timestamp = block.timestamp;
        }
        uint256 sentEth = msg.value;
        user.amountEth = user.amountEth.add(sentEth);
        totalInvested = totalInvested.add(sentEth);
        
        // -----
        // obtain Token from received ETH
        // -----
        results.swapPath = new address[](2);
        results.swapPath[0] = weth;
        results.swapPath[1] = token;

        results.obtainedToken = _swapEthToToken(
            results.swapPath,
            sentEth,
            deadline,
            slippage,
            tokensPerEth
        );

        user.amountToken = user.amountToken.add(results.obtainedToken);

        // -----
        // deposit Token into harvest and get fToken
        // -----
        results.obtainedfToken = _depositTokenToHarvestVault(
            results.obtainedToken
        );

        // -----
        // stake fToken into the NoMintRewardPool
        // -----
        _stakefTokenToHarvestPool(results.obtainedfToken);
        user.amountfToken = user.amountfToken.add(results.obtainedfToken);

        // -----
        // mint parachain tokens
        // -----
        _mintParachainAuctionTokens(address(receiptToken),results.obtainedfToken);

        emit Deposit(
            msg.sender,
            tx.origin,
            sentEth,
            results.obtainedToken,
            results.obtainedfToken
        );


        user.underlyingRatio = _getRatio(
            user.amountfToken,
            user.amountToken,
            18
        );

        return results.obtainedfToken;
    }
    /**
     * @notice Withdraw tokens and claim rewards
     * @param deadline Number of blocks until transaction expires
     * @return Amount of ETH obtained
     */
    function withdraw(uint256 amount,uint256 deadline,uint256 slippage,uint256 ethPerToken,uint256 ethPerFarm ) public nonReentrant returns (uint256) {
        // validation
        HarvestDataTypes.UserInfo storage user = userInfo[msg.sender];
        uint256 receiptBalance = receiptToken.balanceOf(msg.sender);
       
        _validateWithdraw(  deadline,  amount,  user.amountfToken,  receiptBalance, user.timestamp,  slippage );
        _updateRewards(msg.sender);
        
        HarvestDataTypes.WithdrawData memory results;
        results.initialAmountfToken = user.amountfToken;
        results.prevDustEthBalance = address(this).balance;
        
        // -----
        // withdraw from HarvestRewardPool (get fToken back)
        // -----
        results.obtainedfToken = _unstakefTokenFromHarvestPool(amount);

        // -----
        // get rewards
        // -----
        harvestRewardPool.getReward(); //transfers FARM to this contract

        // -----
        // calculate rewards and do the accounting for fTokens
        // -----
        uint256 transferableRewards =
            _calculateRewards(msg.sender, amount, results.initialAmountfToken);

        (user.amountfToken, results.burnAmount) = _calculatefTokenRemainings(
            amount,
            results.initialAmountfToken
        );
        _burnParachainAuctionTokens(address(receiptToken), results.burnAmount);

        // -----
        // withdraw from HarvestRewardVault (return fToken and get Token back)
        // -----
        results.obtainedToken = _withdrawTokenFromHarvestVault(
            results.obtainedfToken
        );
        emit ObtainedInfo(
            msg.sender,
            results.obtainedToken,
            results.obtainedfToken
        );

        // -----
        // calculate feeable tokens (extra Token obtained by returning fToken)
        // -----
        (results.feeableToken, results.earnedTokens) = _calculateFeeableTokens(
            results.initialAmountfToken,
            results.obtainedToken,
            user.amountToken,
            results.obtainedfToken,
            user.underlyingRatio
        );
        user.earnedTokens = user.earnedTokens.add(results.earnedTokens);
        results.calculatedTokenAmount = (amount.mul(10**18)).div(
            user.underlyingRatio
        );
        if (user.amountfToken == 0) {
            user.amountToken = 0;
            user.amountEth = 0;
        } else {
            if (results.calculatedTokenAmount <= user.amountToken) {
                user.amountToken = user.amountToken.sub(
                    results.calculatedTokenAmount
                );
            } else {
                user.amountToken = 0;
            }
        }
        results.obtainedToken = results.obtainedToken.sub(results.feeableToken);

        // -----
        // swap Token to ETH (initial investment)
        // -----
        address[] memory swapPath = new address[](2);
        swapPath[0] = token;
        swapPath[1] = weth;

        if (results.obtainedToken > 0) {
            results.totalEth.add(
                _swapTokenToEth(
                    swapPath,
                    results.obtainedToken,
                    deadline,
                    slippage,
                    ethPerToken
                )
            );
        }

        // -----
        // swap extra Token to ETH (rewards)
        // -----
        if (results.feeableToken > 0) {
            uint256 swapFeeableTokenResult =
                _swapTokenToEth(
                    swapPath,
                    results.feeableToken,
                    deadline,
                    slippage,
                    ethPerToken
                );
            results.feeableEth.add(swapFeeableTokenResult);

            emit ExtraTokensExchanged(
                msg.sender,
                results.feeableToken,
                swapFeeableTokenResult
            );
        }

        // -----
        // check & swap FARM rewards to ETH (rewards - part 2)
        // -----
        if (transferableRewards > 0) {
            emit RewardsEarned(msg.sender, transferableRewards);
            user.earnedRewards = user.earnedRewards.add(transferableRewards);

            swapPath[0] = farmToken;

            uint256 rewardsExchangedResult =
                _swapTokenToEth(
                    swapPath,
                    transferableRewards,
                    deadline,
                    slippage,
                    ethPerFarm
                );

            emit RewardsExchanged(
                msg.sender,
                transferableRewards,
                rewardsExchangedResult
            );

            results.feeableEth = results.feeableEth.add(rewardsExchangedResult);
        }
        user.rewards = user.rewards.sub(transferableRewards);

        // -----
        // calculate ETH amounts & do the accounting
        // -----
        results.auctionedEth = results.feeableEth.div(2);
        results.feeableEth = results.feeableEth.sub(results.auctionedEth);
        results.totalEth = results.totalEth.add(results.feeableEth);

        if (results.totalEth < totalInvested) {
            totalInvested = totalInvested.sub(results.totalEth);
        } else {
            totalInvested = 0;
        }

        user.underlyingRatio = _getRatio(
            user.amountfToken,
            user.amountToken,
            18
        );

        // -----
        // transfer ETH to user, to fee address and to the treasury address
        // -----
        if (fee > 0) {
            uint256 feeEth = _calculateFee(results.totalEth);
            results.totalEth = results.totalEth.sub(feeEth);

            safeTransferETH(feeAddress, feeEth);
            user.userCollectedFees = user.userCollectedFees.add(feeEth);
        }

        safeTransferETH(msg.sender, results.totalEth);

        safeTransferETH(treasuryAddress, results.auctionedEth);
        user.userTreasuryEth = user.userTreasuryEth.add(results.auctionedEth);

        emit Withdraw(
            msg.sender,
            tx.origin,
            results.totalEth,
            results.obtainedToken,
            results.obtainedfToken,
            results.auctionedEth
        );

        // -----
        // dust check
        // -----
        if (address(this).balance > results.prevDustEthBalance) {
            ethDust = ethDust.add(
                address(this).balance.sub(results.prevDustEthBalance)
            );
        }

        return results.totalEth;
    }
}
