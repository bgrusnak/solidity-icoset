//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract MockERC20 is ERC20 {
  constructor(uint256 premintAmount) ERC20('MockERC20', 'MOCK') {
    _mint(msg.sender, premintAmount * 10 ** decimals());
  }

}
