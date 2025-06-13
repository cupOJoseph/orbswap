// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library RootLib {

    //Precompiled roots.
   //uint256[][] constant ROOTS = new uint256[][](100);

    //nRoot
    function nRoot(uint256 x, uint256 n) internal pure returns (uint256) {
        return x ** (1 / n);
    }


}