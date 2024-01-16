//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../../management/Bounty.sol";

contract MockBounty is Bounty {
    constructor(address _token, address _vesting) Bounty(_token, _vesting) {}

    function refuel(address agent, uint256 addAmount) external override {
        _refuel(agent, addAmount);
    }

    function give(address target, uint256 amount) external override {
        _give(target, amount);
    }

    function empty(address target) external override {
        _empty(target);
    }

    function clean(address _to) external override {
        _clean(_to);
    }

    function setVesting(address _vesting) external override {
        _setVesting(_vesting);
    }
}
