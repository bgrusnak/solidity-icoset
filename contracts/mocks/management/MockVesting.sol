//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../../management/Vesting.sol";


contract MockVesting is Vesting {
    constructor(IERC20 _token, IAirdrop _airdrop) Vesting(_token, _airdrop) {}

    function updateToken(address _token) external override {
        _updateToken(_token);
    }

    function updateAirdrop(address _airdrop) external override {
        _updateAirdrop(_airdrop);
    }

    function distribute(address _to, uint256 _amount) external override {
        _distribute(_to, _amount);
    }

    function addKPI(
        bytes32 _code,
        uint256 _time,
        KPITimeStatus _timeStatus,
        uint16 _weight
    ) external override {
        _addKPI(_code, _time, _timeStatus, _weight);
    }

    function modifyKPI(
        bytes32 _code,
        uint256 _time,
        KPITimeStatus _timeStatus,
        uint16 _weight
    ) external override {
        _modifyKPI(_code, _time, _timeStatus, _weight);
    }

    function updateKPI(bytes32 _code, uint16 _amount) external override {
        _updateKPI(_code, _amount);
    }

    function increaseKPI(bytes32 _code, uint16 _amount) external override {
        _increaseKPI(_code, _amount);
    }

    function removeKPI(bytes32 _code) external override {
        _removeKPI(_code);
    }

    function redeem(address _to) external returns (uint256) {
        return _redeem(_to);
    }
}
