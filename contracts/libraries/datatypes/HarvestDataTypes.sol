// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library HarvestDataTypes {

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amountEth; //how much ETH the user entered with; should be 0 for HarvestSC
        uint256 amountToken; //how much Token was obtained by swapping user's ETH
        uint256 amountfToken; //how much fToken was obtained after deposit to vault
        uint256 amountReceiptToken; //receipt tokens printed for user; should be equal to amountfToken
        uint256 underlyingRatio; //ratio between obtained fToken and token
        uint256 userTreasuryEth; //how much eth the user sent to treasury
        uint256 userCollectedFees; //how much eth the user sent to fee address
        uint256 timestamp; //first deposit timestamp; used for withdrawal lock time check
        uint256 earnedTokens;
        uint256 earnedRewards; //before fees
        //----
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }
     
    // @notice Used internally for avoiding "stack-too-deep" error when withdrawing
    struct WithdrawData {
        uint256 prevDustEthBalance;
        uint256 prevfTokenBalance;
        uint256 prevTokenBalance;
        uint256 obtainedfToken;
        uint256 obtainedToken;
        uint256 feeableToken;
        uint256 feeableEth;
        uint256 totalEth;
        uint256 totalToken;
        uint256 auctionedEth;
        uint256 auctionedToken;
        uint256 rewards;
        uint256 farmBalance;
        uint256 burnAmount;
        uint256 earnedTokens;
        uint256 rewardsInEth;
        uint256 auctionedRewardsInEth;
        uint256 userRewardsInEth;
        uint256 initialAmountfToken;
        uint256 calculatedTokenAmount;
    }

    struct UserDeposits {
        uint256 timestamp;
        uint256 amountfToken;
    }
    /// @notice Used internally for avoiding "stack-too-deep" error when depositing
    struct DepositData {
        address[] swapPath;
        uint256[] swapAmounts;
        uint256 obtainedToken;
        uint256 obtainedfToken;
        uint256 prevfTokenBalance;
    }
}