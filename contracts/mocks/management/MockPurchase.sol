//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '../../management/Purchase.sol';

contract MockPurchase is Purchase {
    constructor(
        address _token,
        address _chainlink,
        uint256 _native,
        uint256 _bonus
    ) Purchase(_token, _chainlink, _native, _bonus) {}

    function setToken(address _token) external override {
        _setToken(_token);
    }

    function setChainLinkInterface(address _chainlink) external override {
        _setChainLinkInterface(_chainlink);
    }

    function setNativeRate(uint256 _native) external override {
        _setNativeRate(_native);
    }

    function setVesting(address _vesting) external override {
        _setVesting(_vesting);
    }

    function setRate(
        address currency,
        uint256 _rate
    ) external override returns (bool) {
       return _setRate(currency, _rate);
    }

    function setBonus(uint8 _bonus) external override {
        _setBonus(_bonus);
    }

    function setCashPercent(uint8 percent) external override {
        _setCashPercent(percent);
    }

    function setTokenPercent(uint8 percent) external override {
        _setTokenPercent(percent);
    }

    function calculateAmount(
        address currency,
        uint256 value
    ) external view override returns (uint256) {
        return _calculateAmount(currency, value);
    }

    function buy(
        address currency,
        uint256 value,
        address referral
    ) external override returns (bool) {
        return
            _buy(currency, value, _calculateAmount(currency, value), referral);
    }

    function redeem(address currency, address _to) external override {
        _redeem(currency, _to);
    }

    function clean(address payable _to, address newOwner) external override {
        _clean(_to, newOwner);
    }

}
