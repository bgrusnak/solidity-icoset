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

contract Airdrop is IAirdrop {
    using BitMaps for BitMaps.BitMap;

    bytes32 public root;
    IERC20 private token;
    IVesting private vesting;
    BitMaps.BitMap private redeemed;

    constructor(IERC20 _token, IVesting _vesting, bytes32 _root) {
        if (address(_token) == address(0)) {
            revert AirdropEmptyToken();
        }
        if (address(_token) == address(0)) revert AirdropEmptyToken();
        root = _root;
        token = _token;
        vesting = _vesting;
    }

    /// @notice Addresses can redeem their tokens.
    /// @param proof Proof path.
    function redeem(
        address target,
        bytes32[] memory proof,
        uint256 redeemAmount
    ) external virtual {
        uint256 redeemPos = uint256(uint160(target));
        if (redeemed.get(redeemPos)) {
            revert AirdropAlreadyRedeemed(target);
        }
        bytes32 leaf = keccak256(
            bytes.concat(keccak256(abi.encode(target, redeemAmount)))
        );
        if (!MerkleProof.verify(proof, root, leaf)) {
            revert AirdropWrongPath(target, redeemAmount, proof);
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
    function updateMerkleRoot(bytes32 _root) external virtual {
        root = _root;
    }

    /// @notice Update token address
    /// @param _token New token address.
    function updateToken(address _token) external virtual {
        if (address(_token) == address(0)) {
            revert AirdropEmptyToken();
        }
        token = IERC20(_token);
    }

    /// @notice Update vesting address
    /// @param _vesting New vesting address.
    function updateVesting(address _vesting) external virtual {
        vesting = IVesting(_vesting);
    }

    /// @notice It cancels the Air Drop availability and sends the tokens to the manager provided address.
    /// @param _to The receiving address.
    /// @dev Only manager can perform this transaction. It selfdestructs the contract.
    function cancelAirDrop(address payable _to) external virtual {
        uint256 contractBalance = token.balanceOf(address(this));
        token.transfer(_to, contractBalance);
        selfdestruct(_to);
    }
}
