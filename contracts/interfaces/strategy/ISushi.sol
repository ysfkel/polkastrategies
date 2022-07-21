// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
interface ISushi {

    function setSushiAddress(address _sushi) external;

    function setSushiswapFactory(address _sushiswapFactory) external;

    function setMasterChef(address _masterChef) external;
}
