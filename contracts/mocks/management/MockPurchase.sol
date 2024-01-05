//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../../management/Purchase.sol";

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

    function deposit() external payable override {
        this.deposit(address(0));
    }

    function deposit(address referral) external payable override {
        uint256 amount = _calculateAmount(address(0), msg.value);
        _buy(msg.sender, address(0), msg.value, amount, referral);
    }

    function buy(
        address currency,
        uint256 value,
        address referral
    ) external override returns (bool) {
        return this.buy(msg.sender, currency, value, referral);
    }

    function buy(
        address buyer,
        address currency,
        uint256 value,
        address referral
    ) external override returns (bool) {
        uint256 amount = _calculateAmount(currency, value);
        return _buy(buyer, currency, value, amount, referral);
    }

    function withdraw(address payable _to) external virtual override {
        _withdraw(_to);
    }

    function withdraw(address currency, address _to) external override {
        _withdraw(currency, _to);
    }

    function clean(address payable _to, address newOwner) external override {
        _clean(_to, newOwner);
    }
}
