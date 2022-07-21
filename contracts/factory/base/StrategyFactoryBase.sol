// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../receipt/ReceiptTokenFactory.sol";
import "../../interfaces/strategy/IStrategyBase.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
contract StrategyFactoryBase is AccessControl  {
    address public strategyBeacon;
    address public sushiswapRouter;
    address public weth;

    bytes32 public constant ROUTER_ROLE = keccak256("STRATEGY.ROUTER.ROLE");

    mapping(address => address[]) public userStrategies;

    constructor(
            address _sushiswapRouter,
            address _weth,
            address _strategyBeacon) { 
         require(_sushiswapRouter != address(0), "!address__sushiswapRouter");
         require(_weth != address(0), "!address__weth");
         require(_strategyBeacon != address(0), "!address__strategyBeacon");

         _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

         sushiswapRouter = _sushiswapRouter;
         weth = _weth;
         strategyBeacon = _strategyBeacon;

    }
    function _addStrategy(address account, address strategy)  internal {
         userStrategies[account].push(strategy);
    }

    function getStrategies(address _user) view external returns(address[] memory) {
          return _getStrategies(_user);
    }

    function _getStrategies(address account) view private returns(address[] memory) {
          return userStrategies[account];
    }

    modifier requireBeacon() {
         require(strategyBeacon != address(0), "BEACON_UNSET_0x0");
         _;
    }
    //SETTERS
    function setSushiswapRouter(address _sushiswapRouter) external onlyAdmin {
        require(address(_sushiswapRouter) != address(0), "ADDRESS_0x0");
           sushiswapRouter= _sushiswapRouter;
     }
     function setWETH(address _weth) external onlyAdmin {
        require(address(_weth) != address(0), "ADDRESS_0x0");
           weth= _weth;
     }

     function setStrategyBeacon(address _strategyBeacon) external onlyAdmin {
       require(_strategyBeacon != address(0), "ADDRESS_0x0");
       strategyBeacon = _strategyBeacon;
     }

      function grantRouterRole(address addr) external onlyAdmin {
         grantRole(ROUTER_ROLE, addr);
      }

      modifier onlyRouter() {
            require(hasRole(ROUTER_ROLE, _msgSender()), "!router");
            _;
      }

      modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not admin");
        _;
      }
 
  
}