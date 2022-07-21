// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import "../../tokens/ReceiptToken.sol"; 

contract ReceiptTokenFactory {
    
    address public implementation; 
    constructor(address _implementation) {
         implementation = _implementation; 
    }

    event ReactiptTokenCreated(address sender, address proxy);

    function createReceiptToken(address underlyingAddress, address strategy) external returns(address) {
         address _proxy = ClonesUpgradeable.clone(implementation);
         ReceiptToken(_proxy).initialize(underlyingAddress, strategy);
         emit ReactiptTokenCreated(msg.sender, _proxy);
         return _proxy;
    } 
}