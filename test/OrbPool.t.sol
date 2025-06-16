// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {OrbPool} from "../src/OrbPool.sol";
import {MockERC20} from "./MockERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract OrbTest is Test {
    OrbPool public orbPool;
    MockERC20 public token1;
    MockERC20 public token2;
    MockERC20 public token3;
    MockERC20 public token4;
    MockERC20 public token5;
    MockERC20 public token6;
    MockERC20 public token7;

    address public admin;

    function setUp() public {
        admin = makeAddr("admin");
        orbPool = new OrbPool(admin);
        token1 = new MockERC20("Token1", "TK1");
        token2 = new MockERC20("Token2", "TK2");
        token3 = new MockERC20("Token3", "TK3");
        token4 = new MockERC20("Token4", "TK4");
        token5 = new MockERC20("Token5", "TK5");
        token6 = new MockERC20("Token6", "TK6");
        token7 = new MockERC20("Token7", "TK7");

        //log owner
        console2.log("Owner:", orbPool.owner());
    }

    function test_initiatePool() public {
        address[] memory tokens = new address[](7);
        tokens[0] = address(token1);
        tokens[1] = address(token2);
        tokens[2] = address(token3);
        tokens[3] = address(token4);
        tokens[4] = address(token5);
        tokens[5] = address(token6);
        tokens[6] = address(token7);
        
        //give the admin some tokens
        vm.deal(admin, 1000000000000000000000000000000000000000);
        for(uint i = 0; i < tokens.length; i++) {
            deal(tokens[i], admin, 10000);
            vm.prank(admin);
            IERC20(tokens[i]).approve(address(orbPool), 10000);
        }
        vm.prank(admin);
        orbPool.initiatePool(tokens, 20);
    }

    function test_addToken() public {
        // Mint tokens to the admin
        vm.prank(admin);
        token1.mint(admin, 1000);
        token2.mint(admin, 1000);

        // Approve the pool to spend tokens
        vm.prank(admin);
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);

        // Add tokens to the pool
        vm.prank(admin);
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
        vm.prank(admin);
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);
        vm.prank(admin);
        orbPool.addToken(address(token1), 100);
        vm.prank(admin);
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
        vm.prank(admin);
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);
        vm.prank(admin);
        orbPool.addToken(address(token1), 100);
        vm.prank(admin);
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
        vm.prank(admin);
        token1.approve(address(orbPool), 1000);
        token2.approve(address(orbPool), 1000);
        vm.prank(admin);
        orbPool.addToken(address(token1), 100);
        vm.prank(admin);
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
        vm.prank(admin);
        token1.approve(address(orbPool), 1000);
        vm.prank(admin);
        orbPool.addToken(address(token1), 100);

        vm.prank(admin);
        orbPool.emergencyAdminResetL(address(token1), 100, address(this));
    }
}
