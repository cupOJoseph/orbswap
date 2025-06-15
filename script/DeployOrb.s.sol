//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {OrbPool} from "../src/OrbPool.sol";

contract DeployOrb is Script {
    function run() public {
        vm.startBroadcast();
        OrbPool orbPool = deployOrbPool();
        vm.stopBroadcast();
    }

    function deployOrbPool() public returns (OrbPool) {
        OrbPool orbPool = new OrbPool(msg.sender);
        return orbPool;
    }
}