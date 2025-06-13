// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IOrbPool} from "./Interface/IOrbPool.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {RootLib} from "./RootLib.sol";

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

contract OrbPool is IOrbPool, ERC20{

    address public owner;

    mapping(address => bool) public tokenAddressListed;
    IERC20[] tokens;

    //Super-Elliptical Orb Curve params
    int C = 3.141592653589793238 * 10 ** 18; // VasiliConstant
    int L; // L * VasiliConstant = constant K
    int uc = 1.28599569685 * 10 ** 18; 
    int flipped_uc = 0.77639320225 * 10 ** 18; // 1 / uc

    int constant ln2 = 0.6931 * 10 ** 18; // ln(2)
    //WAD = 1e18


    constructor(address _owner) ERC20("ORB LP", "ORBLP") {
        owner = _owner;
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
        uint amountOut = 0;
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(msg.sender, amountOut);

        //check slippage.
        if(amountOut < minimumAmountOut) {
            revert("Slippage is too high.");
        }

        //TODO add fee handling here.
        L = L + int(amountIn) - int(amountOut); //update total tokens in the pool

    }

    function updateVasiliConstant(int _c) external {
        require(msg.sender == owner, "Only owner can update C");
        C = _c;
        uc = calculateVasiliVariant(C);
    }

    function updateFlippedUc(int _flipped_uc) external {
        require(msg.sender == owner, "Only owner can update flipped_uc");
        flipped_uc = _flipped_uc;
    }

    function getln(int x) public pure returns (int) {
        return FixedPointMathLib.lnWad(int(x));
    }

    function calculateVasiliVariant(int x) internal pure returns (int) {
       //u(x) = ln(2) / ln(x/ x - 1)
       int u = ln2;
       u = u / (getln(x) - getln(x - 1));

       return u;
    }

    function calculateInvariant(int x) internal view returns (int) {
        int chunk = (x / C * L) - 1;

        if(chunk < 0) {
            chunk = chunk * -1;
        }

        int box = chunk ** uc;

        int vr = getVasiliRoot(1 - box);
        
        int I = -1 * C * (vr - 1) * L;
        return I;
    }

    function getVasiliRoot(int x) internal view returns (int) {
        return FixedPointMathLib.powWad(x, flipped_uc);
    }

    function getExecutionPrice(int amount) internal view returns (int) {
        int d = amount + L;
        int q = L;

        
    }



}