// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/manager/AccessManaged.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./IAirdrop.sol";
import "./IVesting.sol";

abstract contract Airdrop is IAirdrop {
    using BitMaps for BitMaps.BitMap;

    bytes32 public root;
    bool public airdropFinished;
    IERC20 private token;
    IVesting private vesting;
    BitMaps.BitMap private redeemed;

    /**
     * @dev Modifier to make a function callable only while aidrop working
     *
     */
    modifier notFinished() {
        if (airdropFinished) revert AirdropIsFinished();
        _;
    }

    constructor(IERC20 _token, IVesting _vesting, bytes32 _root) {
        if (address(_token) == address(0)) {
            revert EmptyToken();
        }
        if (address(_token) == address(0)) revert EmptyToken();
        root = _root;
        token = _token;
        vesting = _vesting;
    }

    /// @notice Addresses can redeem their tokens.
    /// @param proof Proof path.
    function _redeem(
        address target,
        bytes32[] memory proof,
        uint256 redeemAmount
    ) internal virtual notFinished {
        uint256 redeemPos = uint256(uint160(target));
        if (redeemed.get(redeemPos)) {
            revert AlreadyRedeemed(target);
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(target, redeemAmount)))
        );
        if (!MerkleProof.verify(proof, root, leaf)) {
            revert WrongPath(target, redeemAmount, proof);
        }
        redeemed.set(redeemPos);
        if (address(vesting) == address(0)) {
            token.transfer(target, redeemAmount);
            emit Redeem(target, redeemAmount);
            return;
        }
        token.transfer(address(vesting), redeemAmount);
        vesting.distribute(target, redeemAmount);
        emit Vesting(target, redeemAmount);
    }

    /// @notice Update merkle root
    /// @param _root Merkle root of the addresses white list.
    function _updateMerkleRoot(bytes32 _root) internal virtual {
        root = _root;
    }

    /// @notice Update token address
    /// @param _token New token address.
    function _updateToken(address _token) internal virtual {
        if (address(_token) == address(0)) {
            revert EmptyToken();
        }
        token = IERC20(_token);
    }

    /// @notice Update vesting address
    /// @param _vesting New vesting address.
    function _updateVesting(address _vesting) internal virtual {
        vesting = IVesting(_vesting);
    }

    /// @notice It cancels the Air Drop availability and sends the tokens to the manager provided address.
    /// @param _to The receiving address.
    /// @dev Only manager can perform this transaction. It selfdestructs the contract.
    function _cancelAirDrop(address payable _to) internal virtual {
        uint256 contractBalance = token.balanceOf(address(this));
        if (token.transfer(_to, contractBalance)) airdropFinished = true;
    }
}
