// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import "../src/BondingCurve.sol";
contract BondingCurveScript is Script {
    BondingCurve public bondingCurve;
    SuperPull public superPull;
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        superPull = new SuperPull(500 * (10 ** 18));

        // Deploy BondingCurve contract
        bondingCurve = new BondingCurve(0, address(superPull));

        vm.stopBroadcast();
    }
}
