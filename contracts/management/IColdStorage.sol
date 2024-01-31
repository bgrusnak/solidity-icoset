// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../structures/KPI.sol";

interface IColdStorage {
    /**
     * @dev Indicates an error when empty token is provided.
     */
    error ColdStorageEmptyToken();

    /**
     * @dev Indicates an error when empty airdrop is provided.
     */
    error ColdStorageEmptyAirdrop();
    /**
     * @dev Indicates an error when unathorized person calls airdrop only function
     * @param account Address who calls
     */
    error ColdStorageUnauthorizedAccount(address account);
    /**
     * @dev Indicates an error when no tokens can be redeemed.
     */
    error ColdStorageEmptyRedeem();
    /**
     * @dev Indicates an error when distributed tokens more than given to the contract
     * @param amount Total distributed amount
     */
    error ColdStorageAmountOutOfLimits(uint256 amount);
    /**
     * @dev Indicates an error when enabled tokens for user more than distributed
     * @param amount Total enabled amount
     */
    error ColdStorageAmountOutOfDistribution(uint256 amount);

    error ColdStorageIncorrectAmount(bytes32 code, uint16 amount);
    event Redeem(address indexed account, uint256 amount);
    event Distribute(address indexed account, uint256 amount);
    event Enable(address indexed account, uint256 amount);

    /// @notice Update token address
    /// @param _token New token address.
    function updateToken(address _token) external;

    /// @notice Update token address
    /// @param _airdrop New token address.
    function updateAirdrop(address _airdrop) external;

    /// @notice Distribute the new ColdStorage amount
    /// @param _to Receiver address.
    /// @param _amount Distributed amount.
    function distribute(address _to, uint256 _amount) external;

    /// @notice Get the distributed amount
    /// @param _to Receiver address.
    function distributed(address _to) external view returns (uint256); 

    /// @notice Take the current unlocked amount
    function redeem(address _to) external returns (uint256);

    /// @notice Get the current unlocked amount
    function unlocked(address _to) external view returns (uint256);
}
