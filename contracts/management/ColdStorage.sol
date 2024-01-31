// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../structures/KPI.sol";
import "./IAirdrop.sol";
import "./IColdStorage.sol";

abstract contract ColdStorage is IColdStorage {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    IERC20 private token;
    IAirdrop private airdrop;
    uint256 totalDistributed;
    uint256 totalRedeemed;
    uint256 totalEnabled;
    EnumerableMap.AddressToUintMap private amountsDistributed;
    EnumerableMap.AddressToUintMap private amountsEnabled;
    EnumerableMap.AddressToUintMap private amountsRedeemed;

    /**
     * @dev Throws if called by any account other than the airdrop.
     */
    modifier onlyAirdrop() {
        if (address(airdrop) != msg.sender) {
            revert ColdStorageUnauthorizedAccount(msg.sender);
        }
        _;
    }

    constructor(IERC20 _token, IAirdrop _airdrop) {
        if (address(_token) == address(0)) {
            revert ColdStorageEmptyToken();
        }
        if (address(_airdrop) == address(0)) {
            revert ColdStorageEmptyAirdrop();
        }
        token = _token;
        airdrop = _airdrop;
        totalDistributed = 0;
        totalRedeemed = 0;
        totalEnabled = 0;
    }

    /// @notice Update token address
    /// @param _token New token address.
    function _updateToken(address _token) internal virtual {
        if (address(_token) == address(0)) {
            revert ColdStorageEmptyToken();
        }
        token = IERC20(_token);
    }

    /// @notice Update token address
    /// @param _airdrop New token address.
    function _updateAirdrop(address _airdrop) internal virtual {
        if (address(_airdrop) == address(0)) {
            revert ColdStorageEmptyAirdrop();
        }
        airdrop = IAirdrop(_airdrop);
    }

    /// @notice Distribute the new ColdStorage amount
    /// @param _to Receiver address.
    /// @param _amount Distributed amount.
    function _distribute(address _to, uint256 _amount) internal virtual {
        if (totalDistributed + _amount > token.balanceOf(address(this))) {
            revert ColdStorageAmountOutOfLimits(totalDistributed + _amount);
        }
        totalDistributed = totalDistributed + _amount;
        (bool found, uint256 oldAmount) = amountsDistributed.tryGet(_to);
        if (found) {
            amountsDistributed.set(_to, oldAmount + _amount);
        } else {
            amountsDistributed.set(_to, _amount);
        }
        emit Distribute(_to, _amount);
    }

    /// @notice Enable the new possible amount
    /// @param _to Receiver address.
    /// @param _amount Distributed amount.
    function _enable(address _to, uint256 _amount) internal virtual {
        if (totalEnabled + _amount > totalDistributed) {
            revert ColdStorageAmountOutOfDistribution(totalEnabled + _amount);
        }
        totalEnabled = totalEnabled + _amount;
        (bool foundD, uint256 distributedAmount) = amountsDistributed.tryGet(
            _to
        );
        (bool foundE, uint256 enabledAmount) = amountsEnabled.tryGet(_to);
        if (!foundD || distributedAmount < enabledAmount + _amount) {
            revert ColdStorageAmountOutOfDistribution(_amount);
        }
        if (foundE) {
            amountsEnabled.set(_to, enabledAmount + _amount);
        } else {
            amountsEnabled.set(_to, _amount);
        }
        emit Enable(_to, _amount);
    }

    function distributed(
        address _to
    ) external view virtual override returns (uint256) {
        (bool found, uint256 oldAmount) = amountsDistributed.tryGet(_to);
        if (found) return oldAmount;
        return 0;
    }

    function unlocked(
        address _to
    ) external view virtual override returns (uint256) {
        (bool found, uint256 oldAmount) = amountsEnabled.tryGet(_to);
        if (found) return oldAmount;
        return 0;
    }

    /// @notice Take the current unlocked amount
    function _redeem(address _to) internal virtual returns (uint256) {
        (bool foundD, uint256 distributedAmount) = amountsDistributed.tryGet(
            _to
        );
        (bool foundE, uint256 enabledAmount) = amountsEnabled.tryGet(_to);
        if (!foundD || distributedAmount == 0) revert ColdStorageEmptyRedeem();
        if (!foundE || enabledAmount == 0) revert ColdStorageEmptyRedeem();
        (, uint256 amountRedeemed) = amountsRedeemed.tryGet(_to);
        amountsRedeemed.set(_to, amountRedeemed + enabledAmount);
        amountsEnabled.set(_to, 0);
        token.transfer(_to, enabledAmount);
        emit Redeem(_to, enabledAmount);
        return enabledAmount;
    }
}
