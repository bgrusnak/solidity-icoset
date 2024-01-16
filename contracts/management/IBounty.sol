// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Defines the contract for the bounty management using vesting option
 * If the vesting contract address is set, tokens will be transferred to the vesting contract,
 * othervise directly to the address
 */

interface IBounty {
    /**
     * @dev Indicates an error when empty token is provided.
     */
    error EmptyToken();

    error NoFundsAvailable(uint256 amount);

    error AgentNotDefined(address agent, address target);

    error NoFundsPermitted(address agent, uint256 amount);

    error NoPermittedFundsAvailable(address agent, uint256 amount);

    error CannotTransferFunds(address agent, address target, uint256 amount);

    function refuel(address agent, uint256 addAmount) external;

    function give(address target, uint256 amount) external;

    function empty(address target) external;

    function clean(address _to) external;

    function vesting() external view returns (address);

    function setVesting(address _vesting) external;

    function balanceOf(address target) external view returns (uint256);

    function isAgent(address target) external view returns (bool);
}
