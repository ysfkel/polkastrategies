// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.1;

// Interface declarations
/* solhint-disable func-order */

interface IForceVault {
    function underlyingBalanceInVault() external view returns (uint256);

    function underlyingBalanceWithInvestment() external view returns (uint256);

    function governance() external view returns (address);

    function controller() external view returns (address);

    function underlying() external view returns (address);

    function strategy() external view returns (address);

    function setStrategy(address _strategy) external;

    function setVaultFractionToInvest(uint256 numerator, uint256 denominator)
        external;

    function deposit(uint256 amountWei) external;

    function depositFor(uint256 amountWei, address holder) external;

    function withdrawAll() external;

    function withdraw(uint256 numberOfShares) external;

    function getPricePerFullShare() external view returns (uint256);

    function underlyingBalanceWithInvestmentForHolder(address holder)
        external
        view
        returns (uint256);

    // force unleash should be callable only by the controller (by the force unleasher) or by governance
    function forceUnleashed() external;

    function rebalance() external;
}
