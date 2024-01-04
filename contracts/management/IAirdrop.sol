// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Defines the contract for the airdrop with the optional attach to the vesting
 * If the vesting contract address is set, tokens will be transferred to the vesting contract,
 * othervise to the airdrop target
 */

interface IAirdrop {
    /**
     * @dev Indicates an error related to the already redeemed amount. Used in redeem.
     * @param target Address who calls redeem..
     */
    error AlreadyRedeemed(address target);

    /**
     * @dev Indicates an error related to the wrong tree validation. Used in redeem.
     * @param target Address who calls redeem.
     * @param amount Amount redeemed.
     * @param proof The proof provided.
     */
    error WrongPath(address target, uint256 amount, bytes32[] proof);

    /**
     * @dev Indicates an error related to the end of the airdrop
     */
    error AirdropIsFinished();

    /**
     * @dev Indicates an error when empty token is provided.
     */
    error EmptyToken();

    /**
     * @dev Indicates an error when no tokens are distributed to the airdrop.
     */
    error NotEnoughFunds(uint256 redeemAmount);

    error CannotReturnFunds();

    event Redeem(address indexed account, uint256 amount);
    event Vesting(address indexed account, uint256 amount);

    /// @notice Addresses can redeem their tokens.
    /// @param proof Proof path.
    function redeem(
        address target,
        bytes32[] memory proof,
        uint256 redeemAmount
    ) external;

    /// @notice Update merkle root
    /// @param _root Merkle root of the addresses white list.
    function updateMerkleRoot(bytes32 _root) external;

    /// @notice Update token address
    /// @param _token New token address.
    function updateToken(address _token) external;

    /// @notice Update vesting address
    /// @param _vesting New vesting address.
    function updateVesting(address _vesting) external;

    /// @notice It cancels the Air Drop availability and sends the tokens to the manager provided address.
    /// @param _to The receiving address.
    /// @dev Only manager can perform this transaction. It selfdestructs the contract.
    function cancelAirDrop(address payable _to) external;
}
