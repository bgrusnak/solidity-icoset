// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPartialFreezable {
    /**
     * @dev Indicates an error when freezed address called function
     * @param account Address who calls
     */
    error EnforcedFreeze(address account, uint256 amount);

    /**
     * @dev The operation failed because the address is not freezed.
     */
    error ExpectedFreeze(address account, uint256 amount);

    /**
     * @dev Emitted when the freeze is triggered by `account`.
     */
    event Freezed(address indexed account, uint256 amount);

    /**
     * @dev Emitted when the freeze is lifted by `account`.
     */
    event Unfreezed(address indexed account, uint256 amount);

    /**
     * @dev Returns amount of the freezed tokens.
     *
     * Requirements:
     *
     *  @param target The verified address
     */
    function freezed(address target) external view returns (uint256);

    /**
     * @dev Returns amount of the not freezed tokens.
     *
     * Requirements:
     *
     *  @param target The verified address
     */
    function notFreezed(address target) external view returns (uint256);

    /**
     * @dev Freeze the selected amount of the tokens.
     *
     * Requirements:
     *
     *  @param target The freezing address
     *  @param amount The amount of freezing tokens
     */

    function freeze(address target, uint256 amount) external;

    /**
     * @dev Unfreeze the selected amount of the tokens.
     *
     * Requirements:
     *
     *  @param target The unfreezing address
     *  @param amount The amount of unfreezing tokens
     */
    function unfreeze(address target, uint256 amount) external;
}
