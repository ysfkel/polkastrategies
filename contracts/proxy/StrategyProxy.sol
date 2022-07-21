// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; 
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
contract StrategyProxy is BeaconProxy {
    constructor(address _beacon) BeaconProxy(_beacon,"") {   
    }
    function getImplementation() external view  returns (address) {
        return _implementation();
    }
    function getBeacon() external view  returns (address) {
        return _beacon();
    }
}
