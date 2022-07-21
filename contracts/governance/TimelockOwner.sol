// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/strategy/IHarvest.sol";
import "../interfaces/strategy/ISushi.sol";
import "../interfaces/strategy/ISushiSLP.sol";
import "../interfaces/strategy/IStrategy.sol";
import "../interfaces/strategy/IStrategyBase.sol";

/*
    A contract to which ownership of the strategies should be transferred to 
*/
contract TimelockOwner is Ownable {
    uint256 public gracePeriod = 172800; //48 hours
    uint256 public constant minGracePeriod = 86400; //24 hours
    uint256 public constant maxGracePeriod = 604800; //7 days
    mapping(address => Info) public timestamps;
    address public newAddress;

    struct Info {
        uint256 moment;
        uint256 newValue;
        address newAddress;
    }

    event AddressChanged(
        address indexed strategy,
        string addrType,
        address newVal
    );
    event ValueChanged(
        address indexed strategy,
        string addrType,
        uint256 newVal
    );
    event ActionTaken(address indexed strategy, string action);
    event GracePeriodChanged(address user, uint256 oldVal, uint256 newVal);

    constructor()  {}

    function updateGradePeriod(uint256 _gracePeriod) external onlyOwner {
        require(_gracePeriod >= minGracePeriod, "MIN_ERROR");
        require(_gracePeriod <= maxGracePeriod, "MAX_ERROR");

        emit GracePeriodChanged(msg.sender, gracePeriod, _gracePeriod);
        gracePeriod = _gracePeriod;
    }

    function startUpdate(
        address _strategy,
        address _newAddress,
        uint256 _newValue
    ) external onlyOwner {
        Info storage details = timestamps[_strategy];
        details.newAddress = _newAddress;
        details.newValue = _newValue;
        details.moment = block.timestamp;
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Generic -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//

    function setSushiswapRouter(IStrategy strategy, address _sushiswapRouter)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), _sushiswapRouter, 0, true);
        emit AddressChanged(
            address(strategy),
            "SushiswapRouter",
            _sushiswapRouter
        );
        strategy.setSushiswapRouter(_sushiswapRouter);
    }

    function setTreasury(IStrategy strategy, address payable _feeAddress)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), _feeAddress, 0, true);
        emit AddressChanged(address(strategy), "Treasury", _feeAddress);
        strategy.setTreasury(_feeAddress);
    }

    function blacklistAddress(IStrategy strategy, address account)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), account, 0, true);
        emit AddressChanged(address(strategy), "AddToBlacklist", account);
    }

    function removeFromBlacklist(IStrategy strategy, address account)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), account, 0, true);
        emit AddressChanged(address(strategy), "RemoveFromBlacklist", account);
    }

    function setCap(IStrategy strategy, uint256 _cap) external onlyOwner {
        emit ValueChanged(address(strategy), "Cap", _cap);
        strategy.setCap(_cap);
    }

    function setLockTime(IStrategy strategy, uint256 _lockTime)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(
            address(strategy),
            address(0),
            _lockTime,
            false
        );
        emit ValueChanged(address(strategy), "LockTime", _lockTime);
        strategy.setLockTime(_lockTime);
    }

    function setFeeAddress(IStrategy strategy, address payable _feeAddress)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), _feeAddress, 0, true);
        emit AddressChanged(address(strategy), "FeeAddress", _feeAddress);
        strategy.setFeeAddress(_feeAddress);
    }

    function setFee(IStrategy strategy, uint256 _fee) external onlyOwner {
        _checkAndResetGracePeriod(address(strategy), address(0), _fee, false);
        emit ValueChanged(address(strategy), "Fee", _fee);
        strategy.setFee(_fee);
    }

    function rescueDust(IStrategy strategy) external onlyOwner {
        emit ActionTaken(address(strategy), "RescueDust");
        strategy.rescueDust();
    }

    function rescueAirdroppedTokens(
        IStrategy strategy,
        address _token,
        address to
    ) external onlyOwner {
        emit ActionTaken(address(strategy), "RescueTokens");
        strategy.rescueAirdroppedTokens(_token, to);
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Harvest -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//

    function setHarvestRewardVault(
        IHarvest strategy,
        address _harvestRewardVault
    ) external onlyOwner {
        _checkAndResetGracePeriod(
            address(strategy),
            _harvestRewardVault,
            0,
            true
        );
        emit AddressChanged(
            address(strategy),
            "HarvestRewardVault",
            _harvestRewardVault
        );
        strategy.setHarvestRewardVault(_harvestRewardVault);
    }

    function setHarvestRewardPool(IHarvest strategy, address _harvestRewardPool)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(
            address(strategy),
            _harvestRewardPool,
            0,
            true
        );
        emit AddressChanged(
            address(strategy),
            "HarvestRewardPool",
            _harvestRewardPool
        );
        strategy.setHarvestRewardPool(_harvestRewardPool);
    }

    function setHarvestPoolToken(IHarvest strategy, address _harvestfToken)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), _harvestfToken, 0, true);
        emit AddressChanged(
            address(strategy),
            "HarvestPoolToken",
            _harvestfToken
        );
        strategy.setHarvestPoolToken(_harvestfToken);
    }

    function setFarmToken(IHarvest strategy, address _farmToken)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), _farmToken, 0, true);
        emit AddressChanged(address(strategy), "FarmToken", _farmToken);
        strategy.setFarmToken(_farmToken);
    }

    //no timelock
    function updateReward(IHarvest strategy) external onlyOwner {
        strategy.updateReward();
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Sushi-------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
 
    function setWethAddress(IStrategyBase strategy, address _weth) external onlyOwner {
        _checkAndResetGracePeriod(address(strategy), _weth, 0, true);
        emit AddressChanged(address(strategy), "WETH", _weth);
        strategy.setWethAddress(_weth);
    }

    function setSushiAddress(ISushi strategy, address _sushi)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), _sushi, 0, true);
        emit AddressChanged(address(strategy), "Sushi", _sushi);
        strategy.setSushiAddress(_sushi);
    }

    function setSushiswapFactory(ISushi strategy, address _sushiswapFactory)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(
            address(strategy),
            _sushiswapFactory,
            0,
            true
        );
        emit AddressChanged(
            address(strategy),
            "SushiswapFactory",
            _sushiswapFactory
        );
        strategy.setSushiswapFactory(_sushiswapFactory);
    }

    function setMasterChef(ISushi strategy, address _masterChef)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), _masterChef, 0, true);
        emit AddressChanged(
            address(strategy),
            "SushiswapMasterChef",
            _masterChef
        );
        strategy.setMasterChef(_masterChef);
    }

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Sushi SLP-------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    function updateTokenAddress(ISushiSLP strategy, address _token)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), _token, 0, true);
        emit AddressChanged(address(strategy), "TokenForSushi", _token);
        strategy.updateTokenAddress(_token);
    }

    function updateReceipt(ISushiSLP strategy, address _receipt)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), _receipt, 0, true);
        emit AddressChanged(address(strategy), "Receipttoken", _receipt);
        strategy.updateReceipt(_receipt);
    }

    function updateSLP(ISushiSLP strategy, address _slp) external  {
        _checkAndResetGracePeriod(address(strategy),  _slp, 0, false);
        emit AddressChanged(address(strategy), "slp address", _slp);
        strategy.updateSLP(_slp);
    }

    function updatePoolId(ISushiSLP strategy,uint256 _pid) external  {
         _checkAndResetGracePeriod(address(strategy),  address(0), _pid, false);
        emit ValueChanged(address(strategy), "_pid address", _pid);
        strategy.updatePoolId(_pid);
    }

    function initAsset(ISushiSLP strategy, address _asset, address _receipt, address _slp, uint256 _poolId)
        external
        onlyOwner
    {
        _checkAndResetGracePeriod(address(strategy), _receipt, 0, true);
        emit AddressChanged(address(strategy), "Receipttoken", _receipt);
        strategy.initAsset(_asset, _receipt, _slp, _poolId);
    }
 

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ private -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    function _checkAndResetGracePeriod(
        address _addr,
        address _newAddress,
        uint256 _newVal,
        bool _isAddressChange
    ) private {
        Info storage details = timestamps[_addr];

        require(details.moment > 0, "TimelockOwner: Update not initiated");
        require(
            block.timestamp >= (details.moment + gracePeriod),
            "TimelockOwner: Cannot update yet"
        );
        if (_isAddressChange) {
            require(details.newAddress == _newAddress, "Addresses do not match");
        } else {
            require(details.newValue == _newVal, "Values do not match");
        }

        details.newAddress = address(0);
        details.newValue = 0;
        details.moment = 0;
    }
}
