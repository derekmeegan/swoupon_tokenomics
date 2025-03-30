// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./CalcLib.sol"; // Import your library

contract TestCalcLibWrapper {
    // Use the library directly without 'using for' for clarity here
    // Alternatively, use 'using CalcLib for uint256;' and call v.calculate...

    function calculateTR_public(uint256 vUint) public pure returns (int128 tr) {
        return CalcLib.calculateTR(vUint);
    }

    function calculatePotentialTI_public(uint256 vUint) public pure returns (int128 potential_ti) {
        return CalcLib.calculatePotentialTI(vUint);
    }

    function calculateTI_public(uint256 vUint) public pure returns (int128 ti) {
        return CalcLib.calculateTI(vUint);
    }

    function calculateTRAndTI_public(uint256 vUint) public pure returns (int128 tr, int128 ti) {
        return CalcLib.calculateTRAndTI(vUint);
    }

    function calculateF_public(uint256 vUint) public pure returns (int128 f_v) {
        return CalcLib.calculateF(vUint);
    }
}