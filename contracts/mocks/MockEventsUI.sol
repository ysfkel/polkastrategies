// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MockEventsUI {
    using SafeMath for uint256;

    constructor()  {
        cap = 1;
    }

    uint256 public totalDeposits;
    uint256 public cap;
    uint256 public feeFactor = 10000;

    event ChangedValue(
        string indexed valueType,
        uint256 indexed oldValue,
        uint256 indexed newValue
    );

    event Deposit(
        address indexed user,
        address indexed origin,
        uint256 amountToken,
        uint256 amountfToken
    );

    /// @notice Event emitted when user withdraws
    event Withdraw(
        address indexed user,
        address indexed origin,
        uint256 amountToken,
        uint256 amountfToken,
        uint256 treasuryAmountEth
    );

    /// @notice Info of each user.
    struct UserInfo {
        uint256 amountEth; //how much ETH the user entered with; should be 0 for HarvestSC
        uint256 amountToken; //how much Token was obtained by swapping user's ETH
        uint256 amountfToken; //how much fToken was obtained after deposit to vault
        uint256 amountReceiptToken; //receipt tokens printed for user; should be equal to amountfToken
        uint256 underlyingRatio; //ratio between obtained fToken and token
        uint256 userTreasuryEth; //how much eth the user sent to treasury
        uint256 userCollectedFees; //how much eth the user sent to fee address
        bool wasUserBlacklisted; //if user was blacklist at deposit time, he is not receiving receipt tokens
        uint256 timestamp; //first deposit timestamp; used for withdrawal lock time check
        uint256 earnedTokens;
        uint256 earnedRewards; //before fees
        //----
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }
    mapping(address => UserInfo) public userInfo;

    function setCap(uint256 _cap) public {
        emit ChangedValue("CAP", cap, _cap);
        cap = _cap;
    }

    function _calculatePortion(uint256 _amount, uint256 _fee)
        private
        view
        returns (uint256)
    {
        return (_amount.mul(_fee)).div(feeFactor);
    }

    function deposit(
        uint256 tokenAmount,
        uint256 deadline,
        uint256 slippage
    ) public returns (uint256) {
        UserInfo storage user = userInfo[msg.sender];
        totalDeposits = totalDeposits.add(tokenAmount);
        uint256 portion = _calculatePortion(tokenAmount, 500);
        uint256 fToken = tokenAmount.sub(portion);
        user.amountfToken = user.amountfToken.add(fToken);

        emit Deposit(msg.sender, tx.origin, tokenAmount, fToken);

        deadline=slippage;
        return fToken;
    }

    function withdraw(
        uint256 amount,
        uint256 deadline,
        uint256 slippage,
        uint256 ethPerToken,
        uint256 ethPerFarm,
        uint256 tokensPerEth
    ) public returns (uint256) {
        deadline = slippage;
        ethPerFarm = ethPerToken;
        ethPerFarm = tokensPerEth;
        if (amount > totalDeposits) {
            totalDeposits = 0;
        } else {
            totalDeposits = totalDeposits - amount;
        }

        UserInfo storage user = userInfo[msg.sender];
        uint256 eth = amount.div(100);
        user.userTreasuryEth = user.userTreasuryEth.add(eth);
        uint256 token = (amount.mul(100)).div(95);
        if (amount > user.amountfToken) {
            user.amountfToken = 0;
        } else {
            user.amountfToken = user.amountfToken.sub(amount);
        }
        emit Withdraw(msg.sender, tx.origin, token, amount, eth);
        return eth.mul(3);
    }
}
