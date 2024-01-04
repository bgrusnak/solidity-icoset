//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import '../../management/Airdrop.sol';




contract MockAirdrop is Airdrop {

     constructor(IERC20 _token, IVesting _vesting, bytes32 _root)
    Airdrop(_token, _vesting, _root)
     {

     }

    function redeem(
        address target,
        bytes32[] memory proof,
        uint256 redeemAmount
    ) external override {
        _redeem(target, proof, redeemAmount);
    }

    function updateMerkleRoot(bytes32 _root) external override {
        _updateMerkleRoot(_root);
    }

    function updateToken(address _token) external override {
        _updateToken(_token);
    }

    function updateVesting(address _vesting) external override {
        _updateVesting(_vesting);
    }

    function cancelAirDrop(address payable _to) external override {
        _cancelAirDrop(_to);
    }
}