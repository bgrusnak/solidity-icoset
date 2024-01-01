# ICOSet

The set of the contracts used to deploy the ICO/IDO/IEO

## Contracts
### Freezable
The simple contact to freeze/unfreeze accounts
Usage:
```
import "@bgrusnak/solidity-icoset/contracts/utils/Freezable.sol";

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
```
