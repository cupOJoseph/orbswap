// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {OrbPool} from "../src/OrbPool.sol";
import {MockERC20} from "./MockERC20.sol";

contract OrbTest is Test {
    OrbPool public orbPool;
    MockERC20 public token1;
    MockERC20 public token2;

    function setUp() public {
        orbPool = new OrbPool(msg.sender);
        token1 = new MockERC20("Token1", "TK1");
        token2 = new MockERC20("Token2", "TK2");
    }

    function test_addToken() public {
        // Mint tokens to the admin
        token1.mint(msg.sender, 1000);
        token2.mint(msg.sender, 1000);

        // Approve the pool to spend tokens
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);

        // Add tokens to the pool
        orbPool.addToken(address(token1), 100);

        // Check that the token is added
        assertEq(orbPool.tokenAddressListed(address(token1)), true);
        assertEq(orbPool.tokens(0), address(token1));

        // Check that the balance of the token is 100
        assertEq(token1.balanceOf(address(orbPool)), 100);
    }

    function test_deposit() public {
        // Mint tokens to the test contract
        token1.mint(address(this), 1000);
        token2.mint(address(this), 1000);

        // Add tokens to the pool first
        vm.prank(msg.sender);
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);
        vm.prank(msg.sender);
        orbPool.addToken(address(token1), 100);
        vm.prank(msg.sender);
        orbPool.addToken(address(token2), 100);

        // Approve the pool to spend our tokens
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);

        address[] memory tokens = new address[](2);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        int256[] memory amounts = new int256[](2);
        amounts[0] = 100;
        amounts[1] = 100;
        orbPool.deposit(tokens, amounts);
    }

    function test_withdraw() public {
        // Mint tokens to the test contract
        token1.mint(address(this), 1000);
        token2.mint(address(this), 1000);

        // Add tokens to the pool first
        vm.prank(msg.sender);
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);
        vm.prank(msg.sender);
        orbPool.addToken(address(token1), 100);
        vm.prank(msg.sender);
        orbPool.addToken(address(token2), 100);

        // Approve the pool to spend our tokens
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);

        address[] memory tokens = new address[](2);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        int256[] memory amounts = new int256[](2);
        amounts[0] = 100;
        amounts[1] = 100;
        orbPool.deposit(tokens, amounts);

        address[] memory tokensToWithdraw = new address[](2);
        tokensToWithdraw[0] = address(token1);
        tokensToWithdraw[1] = address(token2);
        orbPool.withdraw(100, tokensToWithdraw);
    }

    function test_swap() public {
        // Mint tokens to the test contract
        token1.mint(address(this), 1000);
        token2.mint(address(this), 1000);

        // Add tokens to the pool first
        vm.prank(msg.sender);
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);
        vm.prank(msg.sender);
        orbPool.addToken(address(token1), 100);
        vm.prank(msg.sender);
        orbPool.addToken(address(token2), 100);

        // Approve the pool to spend our tokens
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);

        address[] memory tokens = new address[](2);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        int256[] memory amounts = new int256[](2);
        amounts[0] = 100;
        amounts[1] = 100;
        orbPool.deposit(tokens, amounts);

        // Approve for swap
        token1.approve(address(orbPool), 1000);
        orbPool.swap(address(token1), address(token2), 100, 100);
    }

    function test_emergencyAdminReset() public {
        // Mint tokens to the test contract
        token1.mint(address(this), 1000);

        // Add token to the pool first
        vm.prank(msg.sender);
        token1.approve(address(orbPool), 1000);
        vm.prank(msg.sender);
        orbPool.addToken(address(token1), 100);

        vm.prank(msg.sender);
        orbPool.emergencyAdminResetL(address(token1), 100, address(this));
    }
}
