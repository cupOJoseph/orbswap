// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
These smart contracts and testing suite are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of anything provided herein or through related user interfaces. This repository and related code have not been audited and as such there can be no assurance anything will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk.
*/

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
    int public C = 3.141592653589793238 * 10 ** 18; // VasilyConstant
    int public L = 0; // L * VasilyConstant = constant K
    int public uc = 1.28599569685 * 10 ** 18;
    int public flipped_uc = 0.77639320225 * 10 ** 18; // 1 / uc

    int constant public ln2 = 0.6931 * 10 ** 18; // ln(2)
    //WAD = 1e18

    constructor(address _owner) ERC20("ORB LP Shares", "ORBLP") {
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

    // =============== Core functions ===============
    //Deposit LP
    //Withdraw LP
    //Swap

    //batch deposit
    //batch withdraw
    //@dev deposits tokens into the pool.
    //@param token1 the first token to deposit.
    //@param token2 the second token to deposit.
    //@param amount1 the amount of the first token to deposit.
    //@param amount2 the amount of the second token to deposit.
    function deposit(address token1, address token2, int amount1, int amount2) external {
        require(tokenAddressListed[token1], "Token not listed");
        require(tokenAddressListed[token2], "Token not listed");
        require(amount1 > 0 && amount2 > 0, "Invalid amount, cannot be 0.");

        //get the current ratio of the tokens in the pool.
        //TODO: this will always round up, and maybe it should round down or be handled another way. Fix this Later.
        int w1 =  FixedPointMathLib.sDivWad(int(IERC20(token1).balanceOf(address(this))), int(IERC20(token2).balanceOf(address(this))));
        int w2 =  10**18 - w1;

        int inputRatio = FixedPointMathLib.sDivWad(amount1, amount2); // 10^15 

        //check ratios are within .1% of each other.
        //TODO: enforce more rules here related balancing and rounding up in favor of the pool.
        if(inputRatio > w1) {
            require(inputRatio - w1 < 10**15, "Invalid ratio, ratio of deposit tokens must match the pool.");
        }else{
            //input ratio is smaller.
            require(w1 - inputRatio < 10**15, "Invalid ratio, ratio of deposit tokens must match the pool.");
        }

        //transfer tokens to the pool.
        IERC20(token1).transferFrom(msg.sender, address(this), uint(amount1));
        IERC20(token2).transferFrom(msg.sender, address(this), uint(amount2));

        //use the actual balances to compute new L.
        L = L + int(IERC20(token1).balanceOf(address(this))) + int(IERC20(token2).balanceOf(address(this)));
        
        _mint(msg.sender, uint(w2 * amount1 + w1 * amount2)); // mint LP tokens to the user proportional to the inverse of their weight in the pool.
    }

    //@dev withdraws tokens from the pool, 
    //@notice: burns all the shares so you better send the addresses of all the available tokens or you will lose money.
    //@param sharesToBurn the number of shares to burn.
    //@param tokens the tokens to withdraw.
    function withdraw(uint sharesToBurn, address[] memory tokensToWithdraw) external {

        int weight = FixedPointMathLib.sDivWad(int(sharesToBurn), int(totalSupply()));
        _burn(msg.sender, sharesToBurn); // burn LP tokens from the user

        //TODO is this super inefficient. This can be fixed by letting a use choose less tokens
        for(uint i = 0; i < tokensToWithdraw.length;) {
            require(tokenAddressListed[tokensToWithdraw[i]], "Token not listed.");
            int amount = weight * int(IERC20(tokensToWithdraw[i]).balanceOf(address(this)));
            IERC20(tokensToWithdraw[i]).transfer(msg.sender, uint(amount));

            ++i;
        }
    }

    function updateVasilyConstant(int _c) external {
        require(msg.sender == owner, "Only owner can update C");
        C = _c;
        uc = calculateVasilyVariant(C);
    }

    function updateFlippedUc(int _flipped_uc) external {
        require(msg.sender == owner, "Only owner can update flipped_uc");
        flipped_uc = _flipped_uc;
    }

    function getln(int x) public pure returns (int) {
        return FixedPointMathLib.lnWad(int(x));
    }

    function calculateVasilyVariant(int x) internal pure returns (int) {
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

        int box = FixedPointMathLib.powWad(chunk, uc);

        int vr = getVasilyRoot(1 - box);
        
        int I = -1 * C * (vr - 1) * L;
        return I;
    }

    function getVasilyRoot(int x) internal view returns (int) {
        return FixedPointMathLib.powWad(x, flipped_uc);
    }

    function getExecutionPrice(int amount) internal view returns (int) {
        int d = amount + L;
        int q = L;
    }

    function swap(address tokenIn, address tokenOut, int amountIn, int minimumAmountOut) external returns (int) {
        require(tokenAddressListed[tokenIn], "Token not listed");
        require(tokenAddressListed[tokenOut], "Token not listed");

        //TODO get price of deposit token in LP token
        int amountOut = 0;
        blah blah blah
        
        
        IERC20(tokenIn).transferFrom(msg.sender, address(this), uint(amountIn));
        

        //check slippage.
        if(amountOut < minimumAmountOut) {
            revert("Slippage is too high.");
        }

        //TODO add fee handling here. V0.1 will have fees.
        L = L + amountIn - amountOut; //update total tokens in the pool
        IERC20(tokenOut).transfer(msg.sender, uint(amountOut));

        return amountOut;
    }

    //This emergency function will be removed in v1.
    function emergencyAdminResetL(address token, uint amount, address _to) external {
        require(msg.sender == owner, "Only owner can reset");
        IERC20(token).transfer(_to, amount);
        L = 0;
    }

}