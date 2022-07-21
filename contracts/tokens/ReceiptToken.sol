// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import { ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// This contract is used for printing receipt tokens
// Whenever someone joins a pool, a receipt token will be printed for that person
contract ReceiptToken is ERC20, AccessControlUpgradeable {
    ERC20 public underlyingToken;
    address public underlyingStrategy;

    bytes32 public constant MINTER_ROLE = keccak256("Strategy.ReceiptToken.Minter");
    bytes32 public constant ADMIN_ROLE = keccak256("Strategy.ReceiptToken.Admin");

    function initialize (address underlyingAddress, address strategy) external initializer {
         __ERC20_init(
                string(abi.encodePacked("pAT-", ERC20(underlyingAddress).name())),
                string(abi.encodePacked("pAT-", ERC20(underlyingAddress).symbol()))
         );

           underlyingToken = ERC20(underlyingAddress);
           underlyingStrategy = strategy;

           _setupRole(MINTER_ROLE, strategy);
    }
    
    /**
     * @notice Mint new receipt tokens to some user
     * @param to Address of the user that gets the receipt tokens
     * @param amount Amount of receipt tokens that will get minted
     */
    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    /**
     * @notice Burn receipt tokens from some user
     * @param from Address of the user that gets the receipt tokens burne
     * @param amount Amount of receipt tokens that will get burned
     */
    function burn(address from, uint256 amount) public onlyMinter {
        _burn(from, amount);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERROR::REQUIRES_MINTER_ROLE");
        _;
    }
}
