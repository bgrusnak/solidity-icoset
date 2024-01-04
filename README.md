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
### Bounty
The contract to manage the bounty using agents. Each agent have the amount of the tokens to distribute according the internal rules. 
 
Usage:
```
import "@bgrusnak/solidity-icoset/contracts/management/Bounty.sol";

contract MyBounty is Bounty {
    constructor(IERC20 _token, IVesting _vesting) Bounty(_token, _vesting) {}
...
}
```
### Airdrop
The typical airdrop contract to manage the airdrop using the Merrkle Tree with different (probably) amounts.

Usage:
```
import "@bgrusnak/solidity-icoset/contracts/management/Airdrop.sol";

contract MyAirdrop is Airdrop {
    constructor(IERC20 _token, IVesting _vesting, bytes32 _root)
    Airdrop(_token, _vesting, _root) { }
...
}
```
### Vesting
The vesting contract that unlocks tokens and transfers them to user addresses if certain KPIs are met. KPIs can have minimum and maximum validity time, as well as be partially met. 

Usage:
```
import "@bgrusnak/solidity-icoset/contracts/management/Vesting.sol";

contract MyVesting is Vesting {
   constructor(IERC20 _token, IAirdrop _airdrop) Vesting(_token, _airdrop) {}
...
}
```
### Purchase
The contract giving ability to buy tokens using the native network coin/token or the stable tokens. The price of the native coin is taking from the Chainlink oracle contract.
Usage:
```
import "@bgrusnak/solidity-icoset/contracts/management/Purchase.sol";

contract MyPurchase is Purchase {
    constructor(
        address _token,
        address _chainlink,
        uint256 _native,
        uint256 _bonus
    ) Purchase(_token, _chainlink, _native, _bonus) {}
...
}
```

### TransferableAccessManager

The extension of the AccessManager contract with processing of many contracts and the ability to transfer rights to the another AccessManager contract simultaneously.