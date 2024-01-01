// SPDX-License-Identifier: Private
pragma solidity ^0.8.20;
import '@openzeppelin/contracts/access/manager/AccessManager.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableMap.sol';
import '@openzeppelin/contracts/access/manager/IAccessManaged.sol';
import '../utils/IFreezable.sol';

/**
 * @title PresaleManager
 * @author Ilya A. Shlyakhovoy
 * @notice The simple Manager contract for presale phase during the
 * mature Manager contract in development
 * Only confirms execution of token functions if owner called it and
 * receives the funds in the stablecoins
 */

contract PresaleManager is Ownable, AccessManager, Pausable {
  uint256 public immutable SALT;
  using EnumerableMap for EnumerableMap.AddressToUintMap;

  error EmptyToken();
  error EmptyCurrency();
  error EmptyRate();
  error TooBigRate(uint256 rate);
  error EmptyValue();
  error CannotRedeem(address currency);
  error CannotTransfer(address currency);
  error NotOwned(address target);
  error EmptyNewToken();
  error IncorrectPosition();
  error UnsufficientBalance(
    address buyer,
    address currency,
    uint256 balance,
    uint256 amount
  );
  error UnsufficientManagerBalance(uint256 amount);

  error CannotMakeTransfers(
    address buyer,
    address target,
    address currency,
    uint256 amount
  );

  event BoughtTokens(
    address indexed sender,
    address indexed currency,
    uint256 indexed value,
    uint256 amount
  );

  event ReferralsProvided(
    address indexed sender,
    address indexed referral,
    address indexed currency,
    uint256 amount,
    uint256 cashAmount,
    uint256 tokenAmount
  );
  // address owner;
  address tokenContract;
  address vestingContract;
  uint256 bonusPercent;
  uint256 refCashPercent;
  uint256 refTokenPercent;
  EnumerableMap.AddressToUintMap private currencies;
  mapping(address => mapping(address => uint256)) referralsCash;
  mapping(address => uint256) referralsTokens;

  constructor(
    address initialOwner,
    address _token,
    uint256 _bonus
  ) Ownable(initialOwner) AccessManager(initialOwner) {
    bonusPercent = 100 + _bonus;
    tokenContract = _token;
    SALT = 1544799;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function freeze(address target) external onlyOwner {
    if (tokenContract == address(0)) revert EmptyToken();
    IFreezable(tokenContract).freeze(target);
  }

  function unfreeze(address target) external onlyOwner {
    if (tokenContract == address(0)) revert EmptyToken();
    IFreezable(tokenContract).unfreeze(target);
  }

  function setToken(address _token) external onlyOwner {
    if (_token == address(0)) revert EmptyToken();
    tokenContract = _token;
  }

  function token() external view returns (address) {
    return tokenContract;
  }

  function setVesting(address _vesting) external onlyOwner {
    vestingContract = _vesting;
  }

  function vesting() external view returns (address) {
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
  ) external onlyOwner returns (bool) {
    if (currency == address(0)) revert EmptyCurrency();
    if (_rate == 0) revert EmptyRate();
    if (tokenContract == address(0)) revert EmptyToken();
    if (_rate > uint256(10 ** (IERC20Metadata(tokenContract).decimals() + 2)))
      revert TooBigRate(_rate);
    return currencies.set(currency, _rate);
  }

  function rate(address currency) external view returns (uint256) {
    if (currency == address(0)) revert EmptyCurrency();
    if (!currencies.contains(currency)) return 0;
    return currencies.get(currency);
  }

  function at(uint256 ratePos) external view returns (address, uint256) {
    if (ratePos >= currencies.length()) revert IncorrectPosition();
    return currencies.at(ratePos);
  }

  function length() external view returns (uint256) {
    return currencies.length();
  }

  function hasRate(
    address currency
  ) external view whenNotPaused returns (bool) {
    if (currency == address(0)) revert EmptyCurrency();
    return currencies.contains(currency);
  }

  function setBonus(uint8 _bonus) external onlyOwner {
    bonusPercent = 100 + uint256(_bonus);
  }

  function bonus() external view returns (uint8) {
    return uint8(bonusPercent - 100);
  }

  function setCashPercent(uint8 percent) external onlyOwner {
    refCashPercent = uint256(percent);
  }

  function cashPercent() external view returns (uint8) {
    return uint8(refCashPercent);
  }

  function setTokenPercent(uint8 percent) external onlyOwner {
    refTokenPercent = uint256(percent);
  }

  function tokenPercent() external view returns (uint8) {
    return uint8(refTokenPercent);
  }

  function canCall(
    address caller,
    address /* target */,
    bytes4 /* selector */
  ) public view virtual override returns (bool immediate, uint32 delay) {
    if (caller == owner()) return (true, 0);
    (bool found, ) = hasRole(ADMIN_ROLE, caller);
    return (found, 0);
  }

  function getResultAmount(
    address currency,
    uint256 value
  ) external view returns (uint256) {
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
  ) external whenNotPaused returns (bool) {
    uint256 amount = this.getResultAmount(currency, value);
    uint256 buyerBalance = IERC20(currency).balanceOf(msg.sender);
    uint256 managerBalance = IERC20(tokenContract).balanceOf(address(this));
    if (buyerBalance < value)
      revert UnsufficientBalance(msg.sender, currency, buyerBalance, value);
    if (managerBalance < amount) revert UnsufficientManagerBalance(amount);
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

  function balanceOf(address currency) external view returns (uint256) {
    if (!this.hasRate(currency)) return 0;
    return IERC20(currency).balanceOf(address(this));
  }

  function redeem(address currency, address _to) external onlyOwner whenPaused {
    if (
      !IERC20(currency).transfer(_to, IERC20(currency).balanceOf(address(this)))
    ) revert CannotRedeem(currency);
  }

  function transferAuthority(
    address newAuthority
  ) external onlyOwner whenPaused {
    if (tokenContract == address(0)) revert EmptyToken();
    IAccessManaged(tokenContract).setAuthority(newAuthority);
  }

  function destroy(
    address payable _to,
    address newAuthority
  ) external onlyOwner whenPaused {
    if (tokenContract == address(0)) revert EmptyToken();
    IAccessManaged(tokenContract).setAuthority(newAuthority);
    if (
      !IERC20(tokenContract).transfer(
        newAuthority,
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
    selfdestruct(_to);
  }
}
