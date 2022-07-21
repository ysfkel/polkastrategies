// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../interfaces/sushiswap/IUniswapRouter.sol";
import "../../interfaces/strategy/IStrategyBase.sol";
import { ReceiptToken } from "../../tokens/ReceiptToken.sol";
import "./Storage.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
abstract contract StrategyBase is Storage, IStrategyBase, AccessControlUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    /// @notice Event emitted when user makes a deposit and receipt token is minted
    event ReceiptMinted(address indexed user, uint256 amount);
    /// @notice Event emitted when user withdraws and receipt token is burned
    event ReceiptBurned(address indexed user, uint256 amount);
    /// @notice Event emitted when owner changes any contract address
    event ChangedAddress(string indexed addressType,address indexed oldAddress,address indexed newAddress );
    /// @notice Event emitted when owner changes any contract address
    event ChangedValue(string indexed valueType,uint256 indexed oldValue,uint256 indexed newValue);
    /// @notice Event emitted when Owner changes 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @notice Create a new HarvestDAI contract
     * @param _sushiswapRouter Sushiswap Router address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function __StrategyBase_init(
      address _sushiswapRouter, 
      address _weth,
      address payable _treasuryAddress, 
      address payable _feeAddress,
      uint256 _cap )  internal initializer {
        require(_sushiswapRouter != address(0), "ROUTER_0x0");
        require(_weth != address(0), "WETH_0x0");
        require(_treasuryAddress != address(0), "TREASURY_0x0");
        require(_feeAddress != address(0), "FEE_0x0");
         _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
        weth = _weth;
        treasuryAddress = _treasuryAddress;
        feeAddress = _feeAddress; 
        cap = _cap;
    }

    function _validateCommon(uint256 deadline,uint256 amount, uint256 _slippage) internal view {
        require(deadline >= block.timestamp, "DEADLINE_ERROR");
        require(amount > 0, "AMOUNT_0");
        require(_slippage >= _minSlippage, "SLIPPAGE_ERROR");
        require(_slippage <= feeFactor, "MAX_SLIPPAGE_ERROR");
    }
    function _validateDeposit(uint256 deadline, uint256 amount,uint256 total,uint256 slippage ) internal view {
        _validateCommon(deadline, amount, slippage);
        if(cap > 0) {
            require(total.add(amount) <= cap, "CAP_REACHED");
        }
    }
    function _mintParachainAuctionTokens(address _receiptToken,uint256 _amount) internal {
         ReceiptToken(_receiptToken).mint(msg.sender, _amount);
        emit ReceiptMinted(msg.sender, _amount);
    }
    function _burnParachainAuctionTokens(address _receiptToken, uint256 _amount) internal {
        ReceiptToken(_receiptToken).burn(msg.sender, _amount);
        emit ReceiptBurned(msg.sender, _amount);
    }
    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        return _calculatePortion(_amount, fee);
    }
    function _getBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }
    function _increaseAllowance(address _token,address _contract,uint256 _amount) internal {
        IERC20(_token).safeIncreaseAllowance(_contract, _amount);
    }
    function _getRatio(uint256 numerator,uint256 denominator,uint256 precision) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function _swapTokenToEth(
        address[] memory swapPath,
        uint256 exchangeAmount,
        uint256 deadline,
        uint256 slippage,
        uint256 ethPerToken
    ) internal returns (uint256) {
        uint256[] memory amounts =
            sushiswapRouter.getAmountsOut(exchangeAmount, swapPath);
        uint256 sushiAmount = amounts[amounts.length - 1]; //amount of ETH
        uint256 portion = _calculatePortion(sushiAmount, slippage);
        uint256 calculatedPrice = (exchangeAmount.mul(ethPerToken)).div(10**18);
        uint256 decimals = ERC20(swapPath[0]).decimals();
        if (decimals < 18) {
            calculatedPrice = calculatedPrice.mul(10**(18 - decimals));
        }
        if (sushiAmount > calculatedPrice) {
            require(
                sushiAmount.sub(calculatedPrice) <= portion,
                "PRICE_ERROR_1"
            );
        } else {
            require(
                calculatedPrice.sub(sushiAmount) <= portion,
                "PRICE_ERROR_2"
            );
        }

        _increaseAllowance(
            swapPath[0],
            address(sushiswapRouter),
            exchangeAmount
        );
        uint256[] memory tokenSwapAmounts =
            sushiswapRouter.swapExactTokensForETH(
                exchangeAmount,
                _getMinAmount(sushiAmount, slippage),
                swapPath,
                address(this),
                deadline
            );
        return tokenSwapAmounts[tokenSwapAmounts.length - 1];
    }

    function _swapEthToToken(
        address[] memory swapPath,
        uint256 exchangeAmount,
        uint256 deadline,
        uint256 slippage,
        uint256 tokensPerEth
    ) internal returns (uint256) {
        uint256[] memory amounts =
            sushiswapRouter.getAmountsOut(exchangeAmount, swapPath);
        uint256 sushiAmount = amounts[amounts.length - 1];
        uint256 portion = _calculatePortion(sushiAmount, slippage);
        uint256 calculatedPrice =
            (exchangeAmount.mul(tokensPerEth)).div(10**18);
        uint256 decimals = ERC20(swapPath[0]).decimals();
        if (decimals < 18) {
            calculatedPrice = calculatedPrice.mul(10**(18 - decimals));
        }
        if (sushiAmount > calculatedPrice) {
            require(
                sushiAmount.sub(calculatedPrice) <= portion,
                "PRICE_ERROR_1"
            );
        } else {
            require(
                calculatedPrice.sub(sushiAmount) <= portion,
                "PRICE_ERROR_2"
            );
        }

        uint256[] memory swapResult =
            sushiswapRouter.swapExactETHForTokens{value: exchangeAmount}(
                _getMinAmount(sushiAmount, slippage),
                swapPath,
                address(this),
                deadline
            );

        return swapResult[swapResult.length - 1];
    }

    function _getMinAmount(uint256 amount, uint256 slippage) private pure returns (uint256) {
        uint256 portion = _calculatePortion(amount, slippage);
        return amount.sub(portion);
    }

    function _calculatePortion(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        return (_amount.mul(_fee)).div(feeFactor);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
    function setFee(uint256 _fee) external override  onlyOwner  {
        require(_fee <= uint256(9000), "FEE_TOO_HIGH");
        fee = _fee;
        emit ChangedValue("FEE", fee, _fee);
    }
    function setFeeAddress(address payable _feeAddress)external override onlyOwner {
        require(_feeAddress != address(0), "0x0");
        emit ChangedAddress("FEE", address(feeAddress), address(_feeAddress));
        feeAddress = _feeAddress;
    }
    /**
     * @notice Update the address for fees
     * @dev Can only be called by the owner
     * @param _treasuryAddress Treasury's address
     */
    function setTreasury(address payable _treasuryAddress) external override onlyOwner{
        require(_treasuryAddress != address(0), "0x0");
        emit ChangedAddress("TREASURY", address(treasuryAddress), address(_treasuryAddress));
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice Update the address of WETH
     * @dev Can only be called by the owner
     * @param _weth Address of WETH
     */
    function setWethAddress(address _weth) external override onlyOwner {
        require(_weth != address(0), "0x0");
        emit ChangedAddress("WETH", address(weth), address(_weth));
        weth = _weth;
    }
    /**
     * @notice Set max ETH cap for this strategy
     * @dev Can only be called by the owner
     * @param _cap ETH amount
     */
    function setCap(uint256 _cap) external override onlyOwner {
        emit ChangedValue("CAP", cap, _cap);
        cap = _cap;
    }

     /**
     * @notice Set lock time
     * @dev Can only be called by the owner
     * @param _lockTime lock time in seconds
     */
    function setLockTime(uint256 _lockTime) external override onlyOwner {
        require(_lockTime > 0, "TIME_0");
        emit ChangedValue("LOCKTIME", lockTime, _lockTime);
        lockTime = _lockTime;
    }
    /**
     * @notice Update the address of Sushiswap Router
     * @dev Can only be called by the owner
     * @param _sushiswapRouter Address of Sushiswap Router
     */
    function setSushiswapRouter(address _sushiswapRouter)external override onlyOwner{
        require(_sushiswapRouter != address(0), "0x0");
        emit ChangedAddress("SUSHISWAP_ROUTER",address(sushiswapRouter), address(_sushiswapRouter));
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "!address_newOwner");
        emit OwnershipTransferred(_msgSender(), newOwner);
        revokeRole(OWNER_ROLE, _msgSender());
        grantRole(OWNER_ROLE, newOwner);
    }

    function grantOwnerRole(address account) onlyAdmin override external  {
        grantRole(OWNER_ROLE, account);
    }
    

    modifier onlyOwner(){
        require(hasRole(OWNER_ROLE, _msgSender()), "Caller is not Owner");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not admin");
        _;
    }
}