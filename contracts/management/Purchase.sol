// SPDX-License-Identifier: Private
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/access/manager/AccessManaged.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableMap.sol';
import '@openzeppelin/contracts/access/manager/IAccessManaged.sol';
import '../utils/IFreezable.sol';
import './IPurchase.sol';

/**
 * @title Purchase
 * @author Ilya A. Shlyakhovoy
 * @notice The simple contract for purchase tokens during presale using stablecoins.
 * If the vesting contract is defined, purchased tokens will be transferred to the
 * vesting contract
 */

contract Purchase is IPurchase, AccessManaged, Pausable {
  using EnumerableMap for EnumerableMap.AddressToUintMap;
 
  address tokenContract;
  address vestingContract;
  uint256 bonusPercent;
  uint256 refCashPercent;
  uint256 refTokenPercent;
  EnumerableMap.AddressToUintMap private currencies;
  mapping(address => mapping(address => uint256)) referralsCash;
  mapping(address => uint256) referralsTokens;

  constructor(
    address initialAuthority,
    address _token,
    uint256 _bonus
  ) AccessManaged(initialAuthority) {
    bonusPercent = 100 + _bonus;
    tokenContract = _token; 
  }

  function pause() external override restricted {
    _pause();
  }

  function unpause() external override restricted {
    _unpause();
  }
 
  function setToken(address _token) external override restricted {
    if (_token == address(0)) revert EmptyToken();
    tokenContract = _token;
  }

  function token() external override view returns (address) {
    return tokenContract;
  }

  function setVesting(address _vesting) external override restricted {
    vestingContract = _vesting;
  }

  function vesting() external override view returns (address) {
    return vestingContract;
  }

  /**
   * Define or change new allowed currency with rate. Rate cannot be more than 100
   *  tokens for the 1 currency unit. Rate is nominated in token decimals
   *
   * @param currency  the address of the currency token
   * @param _rate the exchange rate to token
   */

  function setRate(
    address currency,
    uint256 _rate
  ) external override restricted returns (bool) {
    if (currency == address(0)) revert EmptyCurrency();
    if (_rate == 0) revert EmptyRate();
    if (tokenContract == address(0)) revert EmptyToken();
    if (_rate > uint256(10 ** (IERC20Metadata(tokenContract).decimals() + 2)))
      revert TooBigRate(_rate);
    return currencies.set(currency, _rate);
  }

  function rate(address currency) external override view returns (uint256) {
    if (currency == address(0)) revert EmptyCurrency();
    if (!currencies.contains(currency)) return 0;
    return currencies.get(currency);
  }

  function at(uint256 ratePos) external override view returns (address, uint256) {
    if (ratePos >= currencies.length()) revert IncorrectPosition();
    return currencies.at(ratePos);
  }

  function length() external override view returns (uint256) {
    return currencies.length();
  }

  function hasRate(
    address currency
  ) external override view whenNotPaused returns (bool) {
    if (currency == address(0)) revert EmptyCurrency();
    return currencies.contains(currency);
  }

  function setBonus(uint8 _bonus) external override restricted {
    bonusPercent = 100 + uint256(_bonus);
  }

  function bonus() external override view returns (uint8) {
    return uint8(bonusPercent - 100);
  }

  function setCashPercent(uint8 percent) external override restricted {
    refCashPercent = uint256(percent);
  }

  function cashPercent() external override view returns (uint8) {
    return uint8(refCashPercent);
  }

  function setTokenPercent(uint8 percent) external override restricted {
    refTokenPercent = uint256(percent);
  }

  function tokenPercent() external override view returns (uint8) {
    return uint8(refTokenPercent);
  }
 
  function calculateAmount(
    address currency,
    uint256 value
  ) external override view returns (uint256) {
    if (currency == address(0)) revert EmptyCurrency();
    if (value == 0) revert EmptyValue();
    if (tokenContract == address(0)) revert EmptyToken();
    // get the source decimals and add 2 because it will be multiplied by bonus percentage
    uint256 decimals = IERC20Metadata(currency).decimals() + 2;
    uint256 _rate = this.rate(currency);
    return (_rate * value * bonusPercent) / (10 ** decimals);
  }

  function buy(
    address currency,
    uint256 value,
    address referral
  ) external override whenNotPaused returns (bool) {
    uint256 amount = this.calculateAmount(currency, value);
    uint256 buyerBalance = IERC20(currency).balanceOf(msg.sender);
    uint256 managerBalance = IERC20(tokenContract).balanceOf(address(this));
    if (buyerBalance < value)
      revert UnsufficientBalance(msg.sender, currency, buyerBalance, value);
    if (managerBalance < amount) revert UnsufficientPurchaseBalance(amount);
    uint256 refCashAmount;
    if (referral != address(0) && refCashPercent > 0) {
      refCashAmount = (value * refCashPercent) / 100;
      if (!IERC20(currency).transferFrom(msg.sender, address(this), value))
        revert CannotMakeTransfers(msg.sender, address(this), currency, value);
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
    } else {
      if (!IERC20(currency).transferFrom(msg.sender, address(this), value))
        revert CannotMakeTransfers(msg.sender, address(this), currency, value);
    }
    if (!IERC20(tokenContract).transfer(msg.sender, amount))
      revert CannotMakeTransfers(
        address(this),
        msg.sender,
        tokenContract,
        amount
      );
    uint256 refTokenAmount;
    if (referral != address(0) && refTokenPercent > 0) {
      refTokenAmount = (this.rate(currency) * value * refTokenPercent) / 100;
      if (!IERC20(tokenContract).transfer(referral, refTokenAmount))
        revert CannotMakeTransfers(
          address(this),
          referral,
          tokenContract,
          refTokenAmount
        );
      referralsTokens[referral] = referralsTokens[referral] + refTokenAmount;
    }
    if (refCashAmount > 0 || refTokenAmount > 0) {
      emit ReferralsProvided(
        msg.sender,
        referral,
        currency,
        value,
        refCashAmount,
        refTokenAmount
      );
    }
    emit BoughtTokens(msg.sender, currency, value, amount);
    return true;
  }

  function balanceOf(address currency) external override view returns (uint256) {
    if (!this.hasRate(currency)) return 0;
    return IERC20(currency).balanceOf(address(this));
  }

  function redeem(address currency, address _to) external override restricted whenPaused {
    if (
      !IERC20(currency).transfer(_to, IERC20(currency).balanceOf(address(this)))
    ) revert CannotRedeem(currency);
  }

  function clean(
    address payable _to,
    address newOwner
  ) external override restricted whenPaused {
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
        revert CannotTransfer(currency);
    }
  }
}
