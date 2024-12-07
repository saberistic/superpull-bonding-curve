// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract BondingCurve {
    uint256 public fee;

    function setFee(uint256 newFee) public {
        fee = newFee;
    }
}
