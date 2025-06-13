// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IOrbPool} from "./Interface/IOrbPool.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract OrbPool is IOrbPool, ERC20{

    address public owner;

    mapping(address => bool) public tokenAddressListed;
    IERC20[] tokens;

    //swap function params


    constructor(address owner) ERC20("ORB LP", "ORBLP") {
        owner = owner;
    }

    function addToken(address token) external {
        require(msg.sender == owner, "Only owner can add tokens");
        tokenAddressListed[token] = true;
        tokens.push(IERC20(token));
    }

    function removeToken(address token) external {
        require(msg.sender == owner, "Only owner can remove tokens");
        tokenAddressListed[token] = false;
    }

    //Core functions
    //Deposit LP
    //Withdraw LP
    //Swap

    //batch deposit
    //batch withdraw

    function deposit(address token, uint amount) external {
        require(tokenAddressListed[token], "Token not listed");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        
        //TODO get price of deposit token in LP token
        _mint(msg.sender, amount); // mint LP tokens to the user
    }


    function withdraw(address token, uint amount) external {
        require(tokenAddressListed[token], "Token not listed");

        //TODO get price of deposit token in LP token
        _burn(msg.sender, amount); // burn LP tokens from the user
        IERC20(token).transfer(msg.sender, amount);
    }

    function swap(address tokenIn, address tokenOut, uint amountIn, uint minimumAmountOut) external {
        require(tokenAddressListed[tokenIn], "Token not listed");
        require(tokenAddressListed[tokenOut], "Token not listed");

        //TODO get price of deposit token in LP token
        amountOut = 0;
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        //TODO check slippage.
        if(amountOut < minimumAmountOut) {
            revert("Slippage is too high.");
        }

    }

    
}