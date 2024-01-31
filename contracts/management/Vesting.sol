// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../structures/KPI.sol";
import "./IAirdrop.sol";
import "./IVesting.sol";

abstract contract Vesting is IVesting {
    using EnumerableMap for EnumerableMap.Bytes32ToUintMap;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    IERC20 private token;
    IAirdrop private airdrop;
    uint256 totalDistributed;
    uint256 totalRedeemed;
    uint256 totalKPI;
    KPI[] kpi;
    EnumerableMap.Bytes32ToUintMap private kpiMap;
    EnumerableMap.Bytes32ToUintMap private kpiCodes;
    EnumerableMap.AddressToUintMap private amountsDistributed;
    EnumerableMap.AddressToUintMap private amountsRedeemed;

    /**
     * @dev Throws if called by any account other than the airdrop.
     */
    modifier onlyAirdrop() {
        if (address(airdrop) != msg.sender) {
            revert VestingUnauthorizedAccount(msg.sender);
        }
        _;
    }

    constructor(IERC20 _token, IAirdrop _airdrop) {
        if (address(_token) == address(0)) {
            revert VestingEmptyToken();
        }
        if (address(_airdrop) == address(0)) {
            revert VestingEmptyAirdrop();
        }
        token = _token;
        airdrop = _airdrop;
        totalDistributed = 0;
        totalRedeemed = 0;
        totalKPI = 0;
    }

    /// @notice Update token address
    /// @param _token New token address.
    function _updateToken(address _token) internal virtual {
        if (address(_token) == address(0)) {
            revert VestingEmptyToken();
        }
        token = IERC20(_token);
    }

    /// @notice Update token address
    /// @param _airdrop New token address.
    function _updateAirdrop(address _airdrop) internal virtual {
        if (address(_airdrop) == address(0)) {
            revert VestingEmptyAirdrop();
        }
        airdrop = IAirdrop(_airdrop);
    }

    /// @notice Distribute the new vesting amount
    /// @param _to Receiver address.
    /// @param _amount Distributed amount.
    function _distribute(address _to, uint256 _amount) internal virtual {
        totalDistributed = totalDistributed + _amount;
        (bool found, uint256 oldAmount) = amountsDistributed.tryGet(_to);
        if (found) {
            amountsDistributed.set(_to, oldAmount + _amount);
        } else {
            amountsDistributed.set(_to, _amount);
        }
        emit Distribute(_to, _amount);
    }

    function distributed(
        address _to
    ) external view virtual override returns (uint256) {
        (bool found, uint256 oldAmount) = amountsDistributed.tryGet(_to);
        if (found) return oldAmount;
        return 0;
    }

    /// @notice Take the current unlocked amount
    function _redeem(address _to) internal virtual returns (uint256) {
        (bool found, uint256 oldAmount) = amountsDistributed.tryGet(_to);
        if (!found) revert VestingEmptyRedeem();
        uint256 free = (oldAmount * totalKPI) / 1000;
        if (free <= oldAmount) revert VestingEmptyRedeem();
        (bool foundR, uint256 amountRedeemed) = amountsRedeemed.tryGet(_to);
        uint256 redeemAmount = free;
        if (foundR) {
            redeemAmount = free - amountRedeemed;
        }
        amountsRedeemed.set(_to, amountRedeemed + redeemAmount);
        token.transfer(_to, redeemAmount);
        emit Redeem(_to, redeemAmount);
        return redeemAmount;
    }

    function unlocked(
        address _to
    ) external view virtual override returns (uint256) {
        (bool found, uint256 oldAmount) = amountsDistributed.tryGet(_to);
        if (!found) return 0;
        uint256 free = (oldAmount * totalKPI) / 1000;
        if (free <= oldAmount) return 0;
        return free - amountsRedeemed.get(_to);
    }

    /// @notice Set the new KPI
    /// @param _code The KPI id code
    /// @param _time timestamp
    /// @param _timeStatus status of the time
    /// @param _weight weight of the KPI parameter in the total KPI
    function _addKPI(
        bytes32 _code,
        uint256 _time,
        KPITimeStatus _timeStatus,
        uint16 _weight
    ) internal virtual {
        if (kpiMap.contains(_code)) revert VestingKPIAlreadyDefined(_code);
        uint256 pos = kpi.length;
        kpi.push(KPI(_time, _timeStatus, 0, _weight));
        kpiMap.set(_code, pos);
        _computeKPI();
        emit KPIAdded(_code, _time, _timeStatus, _weight);
    }

    /// @notice Modify the KPI properties
    /// @param _code The KPI id code
    /// @param _time timestamp
    /// @param _timeStatus status of the time
    /// @param _weight weight of the KPI parameter in the total KPI
    function _modifyKPI(
        bytes32 _code,
        uint256 _time,
        KPITimeStatus _timeStatus,
        uint16 _weight
    ) internal virtual {
        if (!kpiMap.contains(_code)) revert VestingKPINotDefined(_code);
        if (_weight > 1000) revert VestingIncorrectWeight(_code, _weight);
        uint256 pos = kpiMap.get(_code);
        kpi[pos].time = _time;
        kpi[pos].timeStatus = _timeStatus;
        kpi[pos].weight = _weight;
        emit KPIModified(_code, _time, _timeStatus, _weight);
        _computeKPI();
    }

    /// @notice Update the  KPI value
    /// @param _code The KPI id code
    /// @param _amount the current value of KPI
    function _updateKPI(bytes32 _code, uint16 _amount) internal virtual {
        if (!kpiMap.contains(_code)) revert VestingKPINotDefined(_code);
        if (_amount > 1000) revert VestingIncorrectAmount(_code, _amount);
        uint256 pos = kpiMap.get(_code);
        kpi[pos].current = _amount;
        emit KPIUpdated(_code, _amount);
        _computeKPI();
    }

    /// @notice Increase the  KPI value
    /// @param _code The KPI id code
    /// @param _amount the added value of KPI
    function _increaseKPI(bytes32 _code, uint16 _amount) internal virtual {
        if (!kpiMap.contains(_code)) revert VestingKPINotDefined(_code);
        if (_amount > 1000) revert VestingIncorrectAmount(_code, _amount);
        uint256 pos = kpiMap.get(_code);
        uint32 newVal = _amount + kpi[pos].current;
        if (newVal > 1000) newVal = 1000;
        kpi[pos].current = uint16(newVal);
        emit KPIUpdated(_code, kpi[pos].current);
        _computeKPI();
    }

    /// @notice Remove the KPI from the list
    /// @param _code The KPI id code
    function _removeKPI(bytes32 _code) internal virtual {
        if (!kpiMap.contains(_code)) revert VestingKPINotDefined(_code);
        kpiMap.remove(_code);
        emit KPIRemoved(_code);
        _computeKPI();
    }

    /// @notice Get the KPI from the list
    /// @param _code The KPI id code
    function getKPI(bytes32 _code) external view virtual returns (KPI memory) {
        return _getKPI(_code);
    }

    function _getKPI(bytes32 _code) internal view virtual returns (KPI memory) {
        if (!kpiMap.contains(_code)) revert VestingKPINotDefined(_code);
        return kpi[kpiMap.get(_code)];
    }

    function _computeKPI() internal {
        uint256 kpiLength = kpiMap.length();
        uint256 kpiTotal = 0;
        uint256 pos;
        for (uint256 i = 0; i < kpiLength; i++) {
            (, pos) = kpiMap.at(i);
            if (
                kpi[pos].timeStatus == KPITimeStatus.NotBefore &&
                block.timestamp < kpi[pos].time
            ) continue;
            if (
                kpi[pos].timeStatus == KPITimeStatus.AlwaysAfter &&
                block.timestamp > kpi[pos].time
            ) {
                kpiTotal = kpiTotal + kpi[pos].weight;
                continue;
            }
            kpiTotal = kpiTotal + (kpi[pos].current * kpi[pos].weight) / 1000;
        }
        totalKPI = kpiTotal;
    }
}
