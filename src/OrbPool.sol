// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/*
These smart contracts and testing suite are being provided as is. No guarantee, representation or warranty is being made, express or implied, as to the safety or correctness of anything provided herein or through related user interfaces. This repository and related code have not been audited and as such there can be no assurance anything will work as intended, and users may experience delays, failures, errors, omissions, loss of transmitted information or loss of funds. The creators are not liable for any of the foregoing. Users should proceed with caution and use at their own risk.
*/

import {IOrbPool} from "./Interface/IOrbPool.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol"; 
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {FixedPointMathLib} from "solady/utils/FixedPointMathLib.sol";

contract OrbPool is IOrbPool, ERC20{

    address public owner;

    mapping(address => bool) public tokenAddressListed;
    address[] public tokens;

    bool public poolInitiated = false;

    //Super-Elliptical Orb Curve params
    int public C = 3.414 * 10 ** 18; // (2 + sqrt(2)) todo: split C into alpha and beta for asymmetric liquidity
    int public L = 0; // L * C = constant K
    int public uc = 2;
    int public flipped_uc_18 = 0.5 * 10 ** 18; // 1 / uc

    int constant public ln2 = 0.6931 * 10 ** 18; // ln(2)
    //WAD = 1e18

    constructor(address _owner) ERC20("ORB LP Shares", "ORBLP") {
        owner = _owner; 
    }

    function addToken(address token, int _amount) external {
        require(msg.sender == owner, "Only owner can add new tokens");
        tokenAddressListed[token] = true;
        tokens.push(token);
        IERC20(token).transferFrom(msg.sender, address(this), uint(_amount));

        if(L ==0){
            L = _amount;
        }
    }

    function initiatePool(address[] calldata depositTokens, int _L) external {
        require(msg.sender == owner, "Only owner can initiate pool.");
        require(L == 0, "Pool already initiated.");
        require(_L > 0, "L must be greater than 0.");

        L = _L;

        for(uint i = 0; i < depositTokens.length;) {
            IERC20(depositTokens[i]).transferFrom(msg.sender, address(this), uint(_L));
            tokenAddressListed[depositTokens[i]] = true;
            tokens.push(depositTokens[i]);
            ++i;
        }
        

        poolInitiated = true;
    }

    function removeToken(address token, uint index) external {
        require(msg.sender == owner, "Only owner can remove tokens");
        tokenAddressListed[token] = false;
        tokens[index] = tokens[tokens.length - 1];
        tokens.pop();
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
    function deposit(address[] calldata depositTokens, int[] calldata amounts) external {
        require(depositTokens.length == amounts.length, "Invalid input");

        uint length = depositTokens.length;
        int[] memory weights = new int[](length); // each weight it that token's % of the pool. larger = less valuable. TODO: make this less linear.

        int totalAddedTokens = 0;


        for(uint i = 0; i < length;) {
            totalAddedTokens += amounts[i];
            require(tokenAddressListed[depositTokens[i]], "Token not listed");
            require(amounts[i] > 0, "Invalid amount, cannot be 0.");

            ++i;
        }

        uint L_delta = uint(totalAddedTokens)/length;

        for(uint i = 0; i < length;) {
            uint optimizedAmount = uint(L * amounts[i]) / IERC20(depositTokens[i]).balanceOf(address(this));
            //optimized amount must be within 0.1% of L_delta
            if(optimizedAmount > L_delta * 1001 / 1000 || optimizedAmount < L_delta * 999 / 1000) {
                revert("Invalid amount, must be within 0.1% of L_delta");
            }
            //weight is stored as a number between 0 and 1 then times 10^18.

            //transfer tokens to the pool.
            IERC20(depositTokens[i]).transferFrom(msg.sender, address(this), uint(amounts[i]));

            ++i;
        }

        //get the current ratio of the tokens in the pool.
        //TODO: this will always round up, and maybe it should round down or be handled another way. Fix this Later.
        int w1 =  FixedPointMathLib.sDivWad(int(IERC20(depositTokens[0]).balanceOf(address(this))), int(IERC20(depositTokens[1]).balanceOf(address(this))));
        int w2 =  10**18 - w1;

        int inputRatio = FixedPointMathLib.sDivWad(amounts[0], amounts[1]); // 10^15 

        //check ratios are within .1% of each other.
         
        if(inputRatio > w1) {
            require(inputRatio - w1 < 10**15, "Invalid ratio, ratio of deposit tokens must match the pool.");
        }else{
            //input ratio is smaller.
            require(w1 - inputRatio < 10**15, "Invalid ratio, ratio of deposit tokens must match the pool.");
        }

        //use the actual balances to compute new L.
        L = L + int(L_delta);
        require(L > 0, "L cannot be 0 or negative. Sanity check.");
        _mint(msg.sender, L_delta); //this surprisingly works because we enforce that the ratio of the tokens is the same as the pool.
    }

    //@dev withdraws tokens from the pool, 
    //@notice: burns all the shares so you better send the addresses of all the available tokens or you will lose money.
    //@param sharesToBurn the number of shares to burn.
    //@param tokens the tokens to withdraw.
    function withdraw(uint sharesToBurn, address[] memory tokensToWithdraw) external {

        int weight = FixedPointMathLib.sDivWad(int(sharesToBurn), int(totalSupply()));
        _burn(msg.sender, sharesToBurn); // burn LP tokens from the user

        //TODO is this super inefficient. This can be fixed by letting a user choose less tokens.
        // We could calculate the weight of each token in the pool to get its value, 
        // decide the value of shares, and then withdraw that value in any token combo.
        for(uint i = 0; i < tokensToWithdraw.length;) {
            require(tokenAddressListed[tokensToWithdraw[i]], "Token not listed.");
            int amount = weight * int(IERC20(tokensToWithdraw[i]).balanceOf(address(this)));
            IERC20(tokensToWithdraw[i]).transfer(msg.sender, uint(amount));

            ++i;
        }
    }

    function updateVasilyConstant(int _c, int _uc, int _flipped_uc_18) external {
        require(msg.sender == owner, "Only owner can update C");
        C = _c;
        uc = _uc;
        flipped_uc_18 = _flipped_uc_18;
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
        }else if(chunk == 0) {
            revert("Chunk is 0, this should never happen.");
        }

        int box = FixedPointMathLib.powWad(chunk, uc);

        int vr = getVasilyRoot(1 - box);
        
        int I = -1 * C * (vr - 1) * L;
        return I;
    }

    function getVasilyRoot(int x) internal view returns (int) {
        return FixedPointMathLib.powWad(x, flipped_uc_18 / 10 ** 18);
    }

    //@dev swaps tokens in the pool.
    //@param tokenIn the token to swap in. (x)
    //@param tokenOut the token to swap out.
    //@param amountIn the amount of tokens to swap in.
    //@param minimumAmountOut the minimum amount of tokens to swap out.
    //@return the amount of tokens swapped out.
    function swap(address tokenIn, address tokenOut, int amountIn, int minimumAmountOut) external returns (int) {
        require(tokenAddressListed[tokenIn], "Token not listed");
        require(tokenAddressListed[tokenOut], "Token not listed");

        int l_start = L;

        //TODO: verify L * C is not too big, and exceeds the curve.

        int amountOut = 0;
        //get execution price
        //TODO: may be vulnerable to inflation attacks.
        int q_x = int(IERC20(tokenIn).balanceOf(address(this))); //x before swap.

        int d_x = amountIn + q_x;        
        
        //execution price of x in y
        int execution_price = (calculateInvariant(d_x) - calculateInvariant(q_x)) / (d_x - q_x);
        amountOut = amountIn * execution_price;
        
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
