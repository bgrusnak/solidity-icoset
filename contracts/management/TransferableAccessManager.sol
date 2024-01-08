// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/manager/AccessManager.sol";
import "@openzeppelin/contracts/access/manager/IAccessManaged.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title TransferableAccessManager
 * @author Ilya A. Shlyakhovoy
 * @notice The extension of the AccessManager contract with ability
 * to transfer rights for many contracts
 */

abstract contract TransferableAccessManager is AccessManager {
    using EnumerableSet for EnumerableSet.AddressSet;
    error EmptyAddress();
    error EmptyAuthority();
    error OutOfBounds(uint256 i);

    EnumerableSet.AddressSet private workers;

    constructor(
        address initialOwner,
        address[] memory _workers
    ) AccessManager(initialOwner) {
        for (uint256 i = 0; i < _workers.length; i++) workers.add(_workers[i]);
    }

    function haveWorker(address _worker) external virtual view returns (bool) {
        if (_worker == address(0)) revert EmptyAddress();
        return workers.contains(_worker);
    }

    function _addWorker(address _worker) internal returns (bool) {
        if (_worker == address(0)) revert EmptyAddress();
        if (workers.contains(_worker)) return false;
        workers.add(_worker);
        return true;
    }

    function addWorker(address _worker) external virtual returns (bool) {
        return _addWorker(_worker);
    }

    function values() external view virtual returns (address[] memory) {
        return workers.values();
    }

    function total() external view virtual returns (uint256) {
        return workers.length();
    }

    function at(uint256 i) external virtual returns (address) {
        if (i >= workers.length()) revert OutOfBounds(i);
        return workers.at(i);
    }

    function _removeAt(uint256 i) internal virtual {
        if (i >= workers.length()) revert OutOfBounds(i);
        workers.remove(workers.at(i));
    }

    function removeAt(uint256 i) external virtual {
        _removeAt(i);
    }

    function _remove(address _worker) internal virtual {
        if (workers.contains(_worker)) workers.remove(_worker);
    }

    function remove(address _worker) external virtual {
        _remove(_worker);
    }

    function _transferAuthority(address newAuthority) internal virtual {
        if (newAuthority == address(0)) revert EmptyAuthority();
        uint256 len = workers.length();
        for (uint256 i = 0; i < len; i++)
            IAccessManaged(workers.at(i)).setAuthority(newAuthority);
    }

    function transferAuthority(address newAuthority) external virtual {
        _transferAuthority(newAuthority);
    }
}
