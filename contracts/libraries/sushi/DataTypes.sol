// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
     struct Asset {
        address token; // token address
        address receipt; // receipt token address
        uint256 totalAmount;
        address slp; // slp token address for the token asset and eth pair <token>-eth
        uint256 poolId; 
        bool initialized;
    } 

    struct Balance {
      uint256 initialBalance;
      uint256 newBalance;
    }
    /// @notice Info of each user. 
 
    struct WithdrawData {
        address pair;
        uint256 slpAmount;
        uint256 totalSushi;
        uint256 treasurySushi;
        uint256 userSushi;
        //
        uint256 oldAmount;
        uint256 pendingSushiTokens;
        uint256 sushiBalance;
        uint256 feeSLP;
        uint256 feeSushi;
        uint256 receiptBalance;
    }
 
    struct UserDepositInfo {
        uint totalInvested;
        uint256 amount; // How many SLP tokens the user has provided.
        uint256 sushiRewardDebt; // Reward debt for Sushi rewards. See explanation below.
        uint256 userAccumulatedSushi; //how many rewards this user has
        uint256 timestamp; //first deposit timestamp; used for withdrawal lock time check 
        uint256 treasurySushi; //how much Sushi the user sent to treasury
        uint256 feeSushi; //how much Sushi the user sent to fee address 
        uint256 assetFees; // fees paid for the deposited asset
        uint256 earnedSushi; //how much Sushi the user earned so far
    }

}
 

library SushiSLPBaseDataTypes {
    struct DepositData {
        uint256 liquidity;
        uint256 pendingSushiTokens;
    } 
}

library SushiSLPDataTypes {       

   
}

library StableCoinsDataTypes {    

   
    struct DepositData {
        uint256 toSwapAmount;
        address[] swapPath;
        uint256[] swapAmounts;
        uint256 obtainedToken;
        uint256 liquidityTokenAmount;
        uint256 liquidityEthAmount;
        address pair;
        uint256 liquidity;
        uint256 pendingSushiTokens;
    }

    struct WithdrawData {
        uint256 toSwapAmount;
        address[] swapPath;
        uint256[] swapAmounts;
        uint256 obtainedToken;
        uint256 tokenLiquidityAmount;
        uint256 ethLiquidityAmount;
        address pair;
        uint256 liquidity;
        uint256 pendingSushiTokens;
        uint256 totalTokenAmount;
    }
   
}

