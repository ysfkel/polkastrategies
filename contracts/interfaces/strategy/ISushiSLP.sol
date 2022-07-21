// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "./ISushi.sol";
interface ISushiSLP is ISushi {

    function updateTokenAddress(address _token) external;
 
    function updateSLP(address _slp) external;
 
    function updateReceipt(address _receipt) external;

    function updatePoolId(uint256 _pid) external;

    function initAsset(address _asset, address _receipt, address _slp, uint256 _poolId) external;
}
