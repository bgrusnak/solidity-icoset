// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBounty.sol";
import "./IVesting.sol";

abstract contract Bounty is IBounty {
    using EnumerableMap for EnumerableMap.AddressToUintMap;
    EnumerableMap.AddressToUintMap private amountsDistributed;
    EnumerableMap.AddressToUintMap private amountsAvailable;
    address private token;
    address private vestingAddress;
    uint256 totalTokens;

    constructor(address _token, address _vesting) {
        if (_token == address(0)) revert EmptyToken();
        token = _token;
        vestingAddress = _vesting;
    }

    function _refuel(address agent, uint256 addAmount) internal {
        (bool exists, uint256 oldAmount) = amountsAvailable.tryGet(agent);
        totalTokens = totalTokens + addAmount;
        if (IERC20(token).balanceOf(address(this)) < totalTokens)
            revert NoFundsAvailable(totalTokens);
        if (!exists) {
            amountsAvailable.set(agent, addAmount);
            return;
        }
        amountsAvailable.set(agent, addAmount + oldAmount);
    }

    function _give(address target, uint256 amount) internal {
        (bool exists, uint256 oldAmount) = amountsAvailable.tryGet(msg.sender);
        if (!exists) revert AgentNotDefined(msg.sender, target);
        if (oldAmount < amount) revert NoFundsPermitted(msg.sender, amount);
        if (IERC20(token).balanceOf(address(this)) < amount)
            revert NoPermittedFundsAvailable(msg.sender, amount);
        totalTokens = totalTokens - amount;
        amountsAvailable.set(msg.sender, oldAmount - amount);
        (bool existsD, uint256 oldAmountD) = amountsDistributed.tryGet(
            msg.sender
        );
        if (vestingAddress != address(0)) {
            if (!IERC20(token).transfer(vestingAddress, amount))
                revert CannotTransferFunds(msg.sender, vestingAddress, amount);
            IVesting(vestingAddress).distribute(target, amount);
        } else {
            if (!IERC20(token).transfer(target, amount))
                revert CannotTransferFunds(msg.sender, target, amount);
        }
        if (!existsD) {
            amountsDistributed.set(msg.sender, amount);
            return;
        }
        amountsDistributed.set(msg.sender, oldAmountD + amount);
    }

    function _empty(address target) internal {
        amountsAvailable.set(target, 0);
    }

    function _clean(address _to) internal {
        IERC20(token).transfer(_to, IERC20(token).balanceOf(address(this)));
    }

    function vesting() external view override returns (address) {
        return vestingAddress;
    }

    function _setVesting(address _vesting) internal {
        vestingAddress = _vesting;
    }

    function balanceOf(address target) external view override returns (uint256) {
        (bool exists, uint256 amount) = amountsAvailable.tryGet(target);
        if (!exists) return 0;
        return amount;
    }

    function isAgent(address target) external view returns (bool) {
        (bool exists, ) = amountsAvailable.tryGet(target);
        return exists;
    }
}
