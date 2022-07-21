// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import { DataTypes } from "./DataTypes.sol";

library AssetLib{ 

    using SafeMath for uint256;

    function initialize(DataTypes.Asset storage _asset, address _token, address _receipt, address _slp, uint _poolId ) internal {    
        _asset.token = _token;   
        _asset.receipt = _receipt;
        _asset.slp = _slp;
        _asset.poolId = _poolId;
        _asset.initialized = true;
    } 
    function increaseAmount(DataTypes.Asset storage _asset, uint256 _amount ) internal {       
          _asset.totalAmount = _asset.totalAmount.add(_amount);
    }
    
     function decreaseAmount(DataTypes.Asset storage _asset, uint256 _amount ) internal {   

           if( _asset.totalAmount >= _amount) {
                _asset.totalAmount = _asset.totalAmount.sub(_amount);
           } else {
               _asset.totalAmount = 0;
           }
      
    }
}

library UserDepositInfoLib{ 

    using SafeMath for uint256; 
    function increaseAmount(DataTypes.UserDepositInfo storage _deposit, uint256 _amount ) internal {       
          _deposit.totalInvested = _deposit.totalInvested.add(_amount);
    }
    
     function decreaseAmount(DataTypes.UserDepositInfo storage _deposit, uint256 _amount ) internal {   

           if( _deposit.totalInvested >= _amount) {
                _deposit.totalInvested = _deposit.totalInvested.sub(_amount);
           } else {
               _deposit.totalInvested = 0;
           }
      
    }

    function increasePaidFees(DataTypes.UserDepositInfo storage _deposit, uint256 _amount ) internal {       
        _deposit.assetFees = _deposit.assetFees.add(_amount);
    } 
}


 