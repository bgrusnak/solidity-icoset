// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";
import "../utils/IFreezable.sol";
import "./IPurchase.sol";
import "./IVesting.sol";

/**
 * @title Purchase
 * @author Ilya A. Shlyakhovoy
 * @notice The simple contract for purchase tokens during presale using stablecoins
 * or native coin.
 * If the vesting contract is defined, purchased tokens will be transferred to the
 * vesting contract
 */

abstract contract Purchase is IPurchase {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    address tokenContract;
    address vestingContract;
    AggregatorV2V3Interface internal chainLink;
    uint256 bonusPercent;
    uint256 refCashPercent;
    uint256 refTokenPercent;
    uint256 nativeToUsd;
    EnumerableMap.AddressToUintMap private currencies;
    mapping(address => mapping(address => uint256)) referralsCash;
    mapping(address => uint256) referralsTokens;

    constructor(
        address _token,
        address _chainlink,
        uint256 _native,
        uint256 _bonus
    ) payable {
        if (_native == 0) revert EmptyNativeRate();
        bonusPercent = 100 + _bonus;
        tokenContract = _token;
        chainLink = AggregatorV2V3Interface(_chainlink);
        nativeToUsd = _native;
    }

    function _setToken(address _token) internal {
        if (_token == address(0)) revert EmptyToken();
        tokenContract = _token;
    }

    function token() external view override returns (address) {
        return tokenContract;
    }

    function _setChainLinkInterface(address _chainlink) internal {
        if (_chainlink == address(0)) revert EmptyChainLink();
        chainLink = AggregatorV2V3Interface(_chainlink);
    }

    function chainLinkInterface() external view override returns (address) {
        return address(chainLink);
    }

    function _setNativeRate(uint256 _native) internal {
        if (_native == 0) revert EmptyNativeRate();
        nativeToUsd = _native;
    }

    function nativeRate() external view override returns (uint256) {
        return nativeToUsd;
    }

    function _setVesting(address _vesting) internal {
        vestingContract = _vesting;
    }

    function vesting() external view override returns (address) {
        return vestingContract;
    }

    function _setRate(address currency, uint256 _rate) internal returns (bool) {
        if (currency == address(0)) revert EmptyCurrency();
        if (_rate == 0) revert EmptyRate();
        if (tokenContract == address(0)) revert EmptyToken();
        if (
            _rate >
            uint256(10 ** (IERC20Metadata(tokenContract).decimals() + 2))
        ) revert TooBigRate(_rate);
        return currencies.set(currency, _rate);
    }

    function rate(address currency) external view override returns (uint256) {
        if (currency == address(0)) revert EmptyCurrency();
        if (!currencies.contains(currency)) return 0;
        return currencies.get(currency);
    }

    function at(
        uint256 ratePos
    ) external view override returns (address, uint256) {
        if (ratePos >= currencies.length()) revert IncorrectPosition();
        return currencies.at(ratePos);
    }

    function length() external view override returns (uint256) {
        return currencies.length();
    }

    function hasRate(address currency) external view override returns (bool) {
        if (currency == address(0)) revert EmptyCurrency();
        return currencies.contains(currency);
    }

    function _setBonus(uint8 _bonus) internal {
        bonusPercent = 100 + uint256(_bonus);
    }

    function bonus() external view override returns (uint8) {
        return uint8(bonusPercent - 100);
    }

    function _setCashPercent(uint8 percent) internal {
        refCashPercent = uint256(percent);
    }

    function cashPercent() external view override returns (uint8) {
        return uint8(refCashPercent);
    }

    function _setTokenPercent(uint8 percent) internal {
        refTokenPercent = uint256(percent);
    }

    function tokenPercent() external view override returns (uint8) {
        return uint8(refTokenPercent);
    }

    function _calculateNativeAmount(
        uint256 value
    ) internal view returns (uint256) {
        if (address(chainLink) == address(0)) revert EmptyChainLink();
        // get the source decimals and add 2 because it will be multiplied by bonus percentage
        uint256 decimals = chainLink.decimals() + 2;
        int256 currentRate = chainLink.latestAnswer();
        if (currentRate <= 0) revert LowRate();
        return (uint256(currentRate) * value * bonusPercent) / (10 ** decimals);
    }

    function _calculateAmount(
        address currency,
        uint256 value
    ) internal view returns (uint256) {
        // 0 address treating as native coin
        if (currency == address(0)) {
            return _calculateNativeAmount(value);
        }
        if (value == 0) revert EmptyValue();
        if (tokenContract == address(0)) revert EmptyToken();
        // get the source decimals and add 2 because it will be multiplied by bonus percentage
        uint256 decimals = IERC20Metadata(currency).decimals() + 2;
        uint256 currentRate = this.rate(currency);
        return (currentRate * value * bonusPercent) / (10 ** decimals);
    }

    function _buy(
        address buyer,
        address currency,
        uint256 value,
        uint256 amount,
        address referral
    ) internal returns (bool) {
        if (buyer == address(0)) revert NoBuyerProvided();
        if (buyer == referral) revert BadReferrer();
        if (amount == 0) revert ZeroAmount(currency, value);
        if (currency != address(0)) {
            uint256 buyerBalance = IERC20(currency).balanceOf(buyer);
            if (buyerBalance < value)
                revert UnsufficientBalance(
                    buyer,
                    currency,
                    buyerBalance,
                    value
                );
        }
        uint256 managerBalance = IERC20(tokenContract).balanceOf(address(this));
        if (managerBalance < amount) revert UnsufficientPurchaseBalance(amount);
        uint256 refCashAmount;

        if (referral != address(0) && refCashPercent > 0) {
            refCashAmount = (value * refCashPercent) / 100;
            if (currency == address(0)) {
                (bool success, ) = referral.call{value: refCashAmount}("");
                if (!success)
                    revert CannotWithdraw(address(0), referral, refCashAmount);
            } else {
                if (!IERC20(currency).transferFrom(buyer, address(this), value))
                    revert CannotMakeTransfers(
                        buyer,
                        address(this),
                        currency,
                        value
                    );
                if (!IERC20(currency).transfer(referral, refCashAmount))
                    revert CannotMakeTransfers(
                        address(this),
                        referral,
                        currency,
                        refCashAmount
                    );
                referralsCash[referral][currency] =
                    referralsCash[referral][currency] +
                    refCashAmount;
            }
        } else {
            if (currency != address(0)) {
                if (!IERC20(currency).transferFrom(buyer, address(this), value))
                    revert CannotMakeTransfers(
                        buyer,
                        address(this),
                        currency,
                        value
                    );
            }
        }
        uint256 refTokenAmount;
        if (referral != address(0) && refTokenPercent > 0) {
            refTokenAmount =
                (this.rate(currency) * value * refTokenPercent) /
                (10 ** (IERC20Metadata(tokenContract).decimals() + 2));
        }
        if (vestingContract == address(0)) {
            if (!IERC20(tokenContract).transfer(buyer, amount))
                revert CannotMakeTransfers(
                    address(this),
                    buyer,
                    tokenContract,
                    amount
                );
            if (refTokenAmount > 0) {
                if (!IERC20(tokenContract).transfer(referral, refTokenAmount))
                    revert CannotMakeTransfers(
                        address(this),
                        referral,
                        tokenContract,
                        refTokenAmount
                    );
                referralsTokens[referral] =
                    referralsTokens[referral] +
                    refTokenAmount;
            }
        } else {
            if (
                !IERC20(tokenContract).transfer(
                    vestingContract,
                    amount + refTokenAmount
                )
            )
                revert CannotMakeTransfers(
                    address(this),
                    vestingContract,
                    tokenContract,
                    amount + refTokenAmount
                );
            IVesting(vestingContract).distribute(buyer, amount);
            if (refTokenAmount > 0)
                IVesting(vestingContract).distribute(referral, refTokenAmount);
        }
        if (refCashAmount > 0 || refTokenAmount > 0) {
            emit ReferralsProvided(
                buyer,
                referral,
                currency,
                value,
                refCashAmount,
                refTokenAmount
            );
        }
        emit BoughtTokens(buyer, currency, value, amount);
        return true;
    }

    function balanceOf(
        address currency
    ) external view override returns (uint256) {
        if (!this.hasRate(currency)) return 0;
        return IERC20(currency).balanceOf(address(this));
    }

    function _withdraw(address payable _to) internal {
        uint256 amount = address(this).balance;
        (bool success, ) = _to.call{value: amount}("");
        if (!success) revert CannotWithdraw(address(0), _to, amount);
    }

    function _withdraw(address currency, address _to) internal {
        if (
            !IERC20(currency).transfer(
                _to,
                IERC20(currency).balanceOf(address(this))
            )
        )
            revert CannotWithdraw(
                currency,
                _to,
                IERC20(currency).balanceOf(address(this))
            );
    }

    function _clean(address payable _to, address newOwner) internal {
        if (tokenContract == address(0)) revert EmptyToken();
        if (
            !IERC20(tokenContract).transfer(
                newOwner,
                IERC20(tokenContract).balanceOf(address(this))
            )
        ) revert CannotTransfer(tokenContract);

        uint256 i;
        uint256 balance;
        for (i = 0; i < currencies.length(); i++) {
            (address currency, ) = currencies.at(i);
            balance = IERC20(currency).balanceOf(address(this));
            if (balance > 0 && !IERC20(currency).transfer(_to, balance))
                revert CannotWithdraw(currency, _to, balance);
        }
        uint256 amount = address(this).balance;
        (bool success, ) = _to.call{value: amount}("");
        if (!success) revert CannotWithdraw(address(0), _to, amount);
    }
}
