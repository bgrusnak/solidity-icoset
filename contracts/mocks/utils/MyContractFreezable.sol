// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../../utils/Freezable.sol";

contract MyContractFreezable is Freezable {
    uint256 value;

    function onlyFreezed(uint256 newValue) external whenFreezed(msg.sender) {
        value = newValue;
    }

    function onlyMelted(uint256 newValue) external whenNotFreezed(msg.sender) {
        value = newValue;
    }

    function freeze(address target) external {
        _freeze(target);
    }

    function unfreeze(address target) external{
        _unfreeze(target);
    }
}
