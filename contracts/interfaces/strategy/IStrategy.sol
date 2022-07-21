// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStrategyBase.sol";
interface IStrategy is IStrategyBase {

    function rescueDust() external;

    function rescueAirdroppedTokens(address _token, address to) external;
}
