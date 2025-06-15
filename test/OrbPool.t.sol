// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OrbPool} from "../src/OrbPool.sol";

contract OrbTest is Test {
    OrbPool public orbPool;

    function setUp() public {
        orbPool = new OrbPool(msg.sender);
    }

    function test_deposit() public {
        orbPool.deposit(address(0), address(0), 100, 100);
    }

    function test_withdraw() public {
        orbPool.deposit(address(0), address(2), 100, 100);
        address[] memory tokensToWithdraw = new address[](2);
        tokensToWithdraw[0] = address(0);
        tokensToWithdraw[1] = address(2);
        orbPool.withdraw(100, tokensToWithdraw);
    }

    function test_swap() public {
        orbPool.deposit(address(0), address(0), 100, 100);
        orbPool.swap(address(0), address(0), 100, 100);
    }

    function test_emergencyAdminReset() public {
        orbPool.emergencyAdminReset(address(0), 100, address(0));
    }
}
