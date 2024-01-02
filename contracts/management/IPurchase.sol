// SPDX-License-Identifier: Private
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import "../utils/IFreezable.sol";

/**
 * @title IPurchase
 * @author Ilya A. Shlyakhovoy
 * @notice INterface of the simple contract for purchase tokens during presale using stablecoins.
 */

interface IPurchase {
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
    error UnsufficientPurchaseBalance(uint256 amount);

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

    function pause() external;

    function unpause() external;

    function setToken(address _token) external;

    function token() external view returns (address);

    function setVesting(address _vesting) external;

    function vesting() external view returns (address);

    /**
     * Define or change new allowed currency with rate. Rate cannot be more than 100
     *  tokens for the 1 currency unit. Rate is nominated in token decimals
     *
     * @param currency  the address of the currency token
     * @param _rate the exchange rate to token
     */

    function setRate(address currency, uint256 _rate) external returns (bool);

    function rate(address currency) external view returns (uint256);

    function at(uint256 ratePos) external view returns (address, uint256);

    function length() external view returns (uint256);

    function hasRate(address currency) external view returns (bool);

    function setBonus(uint8 _bonus) external;

    function bonus() external view returns (uint8);

    function setCashPercent(uint8 percent) external;

    function cashPercent() external view returns (uint8);

    function setTokenPercent(uint8 percent) external;

    function tokenPercent() external view returns (uint8);

    function calculateAmount(
        address currency,
        uint256 value
    ) external view returns (uint256);

    function buy(
        address currency,
        uint256 value,
        address referral
    ) external returns (bool);

    function balanceOf(address currency) external view returns (uint256);

    function redeem(address currency, address _to) external;

    function clean(address payable _to, address newOwner) external;
}