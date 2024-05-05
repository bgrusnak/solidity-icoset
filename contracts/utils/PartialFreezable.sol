// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
 
import "./IPartialFreezable.sol";

abstract contract PartialFreezable is IPartialFreezable {
    mapping (address => uint256) private _freezedAmounts;

    constructor() {}

    /**
     * @dev Modifier to make a function callable only when the address have needed amount of not freezed tokens.
     *
     * Requirements:
     *
     * @param target Testing address
     * @param amount The not frozen amount
     */
    modifier whenNotFreezed(address target, uint256 amount) {
        _requireNotFreezed(target, amount);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the address have the selected amount of freezed tokens.
     *
     * Requirements:
     *
     * @param target Testing address
     * @param amount The not frozen amount
     */
    modifier whenFreezed(address target, uint256 amount) {
        _requireFreezed(target,   amount);
        _;
    }

    /**
     * @dev Returns amount of freezed tokens
     *
     * Requirements:
     *
     *  @param target The verified address
     */
    function freezed(address target) public view virtual returns (uint256) {
        return _freezedAmounts[target];
    }

    /**
     * @dev Throws if the address havent needed amount of not freezed tokens.
     *
     * Requirements:
     *
     * @param target Address should not to be freezed
     * @param amount The not frozen amount
     */
    function _requireNotFreezed(address target, uint256 amount) internal view virtual ;

    /**
     * @dev Throws if the address haven't freezed amount of tokens.
     *
     * Requirements:
     *
     *  @param target Address should to be freezed
     * @param amount The   frozen amount
     */
    function _requireFreezed(address target, uint256 amount) internal view virtual {
        if (_freezedAmounts[target]<amount) {
            revert ExpectedFreeze(target, amount);
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     *   @param target Address need to be freezed
     *   @param amount The amount need to be frozen
     */
    function _freeze(address target, uint256 amount) internal virtual whenNotFreezed(target, amount) {
        _freezedAmounts[target] = _freezedAmounts[target] + amount;
        emit Freezed(target, amount);
    }

    /**
     * @dev Returns to normal state needed amount. 
     *
     * Requirements:
     *
     *  @param target Address need to be unfreezed
     *  @param amount The amount need to be unfreezed
     */
    function _unfreeze(address target, uint256 amount) internal virtual whenFreezed(target, amount) {
        if (_freezedAmounts[target] <= amount) {
            _freezedAmounts[target] = 0;
        } else {
            _freezedAmounts[target] = _freezedAmounts[target] - amount;
        }
        emit Unfreezed(target, amount);
    }
}
