//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../../management/ColdStorage.sol";


contract MockColdStorage is ColdStorage {
    constructor(
        IERC20 _token,
        IAirdrop _airdrop
    ) ColdStorage(_token, _airdrop) {}

    /// @notice Update token address
    /// @param _token New token address.
    function updateToken(address _token) public {
        _updateToken(_token);
    }

    /// @notice Update token address
    /// @param _airdrop New token address.
    function updateAirdrop(address _airdrop) public {
        _updateAirdrop(_airdrop);
    }

    /// @notice Distribute the new amount
    /// @param _to Receiver address.
    /// @param _amount Distributed amount.
    function distribute(address _to, uint256 _amount) public {
        _distribute(_to, _amount);
    }

    /// @notice Enable the amount
    /// @param _to Receiver address.
    /// @param _amount Distributed amount.
    function enable(address _to, uint256 _amount) public {
        _enable(_to, _amount);
    }

    /// @notice Take the current unlocked amount
    function redeem(address _to) public returns (uint256) {
        return _redeem(_to);
    }
 
}
