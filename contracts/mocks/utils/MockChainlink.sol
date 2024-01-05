//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract MockChainlink {
  int256 private value;
  uint8 decimalValue;

  constructor(int256 _value, uint8 _decimals) {
    value = _value;
    decimalValue = _decimals;
  }

  function latestAnswer() external view returns (int256) {
    return value;
  }

  function decimals() external view returns (uint8) {
    return decimalValue;
  }
}
