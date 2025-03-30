// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19; // Use a recent Solidity version

// Assume ABDKMath64x64.sol is in the specified path relative to this file
// Example path: import "./abdk-libraries-solidity/ABDKMath64x64.sol";
import "../abdk-libraries-solidity/ABDKMath64x64.sol"; // Example using npm package import path

/**
 * @title CalcLib
 * @notice A library for calculating Swoupon costs (TR) and rewards (TI)
 * based on a volume V, using 64.64 fixed-point arithmetic.
 * @dev Uses ABDKMath64x64 library for mathematical operations.
 * Note: Potential TI calculation uses sqrt due to ABDK limitations,
 * approximating the original Python's power(0.5) rather than power(0.3).
 */
library CalcLib {
    using ABDKMath64x64 for int128;

    // --- Constants ---
    // Pre-calculate fixed-point representations (value * 2^64)

    // 0.01 * 2^64 = 184467440737095516
    int128 private constant C_0_01 = 184467440737095520;
    // 0.02 * 2^64 = 368934881474191032
    int128 private constant C_0_02 = 368934881474191040;
    // -0.00005 * 2^64 = -922337203685477
    int128 private constant C_NEG_0_00005 = -922337203685477;
     // 0.1 * 2^64 = 1844674407370955161 (approx)
    int128 private constant C_0_1 = 1844674407370955264;
    // 1/3 * 2^64 = 6148914691236517205 (approx)
    int128 private constant MAX_TI_FRACTION = 6148914691236516864; // 1/3
    // 1 * 2^64 = 18446744073709551616
    int128 private constant C_ONE = 18446744073709551616;


    // --- Helper Functions ---

    /**
     * @notice Returns the minimum of two int128 numbers.
     */
    function _min(int128 a, int128 b) internal pure returns (int128) {
        return a < b ? a : b;
    }

    // --- Core Calculation Functions ---

    /**
     * @notice Calculates the factor F(V) = 0.01 + (0.02 * exp(-0.00005 * V)).
     * @param vUint The input volume V as an unsigned integer.
     * @return f_v The calculated factor F(V) as a 64.64 fixed-point number.
     */
    function calculateF(uint256 vUint) internal pure returns (int128 f_v) {
        // Convert V from uint256 to 64.64 fixed-point
        int128 v = ABDKMath64x64.fromUInt(vUint);

        // Calculate the exponent: -0.00005 * v
        int128 expArg = v.mul(C_NEG_0_00005);

        // Calculate e^expArg
        int128 expVal = ABDKMath64x64.exp(expArg);

        // Calculate the second term: 0.02 * expVal
        int128 term2 = C_0_02.mul(expVal);

        // Calculate F(V): 0.01 + term2
        f_v = C_0_01.add(term2);
    }

    /**
     * @notice Calculates the Swoupon Cost TR(V) = F(V) * V / 0.1.
     * @param vUint The input volume V as an unsigned integer.
     * @return tr The calculated cost TR(V) as a 64.64 fixed-point number.
     */
    function calculateTR(uint256 vUint) internal pure returns (int128 tr) {
        // Calculate F(V)
        int128 f_v = calculateF(vUint);
        // Convert V from uint256 to 64.64 fixed-point
        int128 v = ABDKMath64x64.fromUInt(vUint);

        // Calculate F(V) * V
        int128 fv_mul_v = f_v.mul(v);

        // Calculate TR(V) = (F(V) * V) / 0.1
        // Ensure C_0_1 is not zero (it's a constant, so safe, but good practice)
        require(C_0_1 != 0, "CalcLib: Division by zero constant");
        tr = fv_mul_v.div(C_0_1);
    }

    /**
     * @notice Calculates the *potential* Swoupon Reward potential_TI(V) = sqrt(1 + V) / 0.1.
     * @dev Uses sqrt(1+V) as ABDKMath64x64 does not support fractional powers directly.
     * @param vUint The input volume V as an unsigned integer.
     * @return potential_ti The potential reward TI(V) as a 64.64 fixed-point number.
     */
    function calculatePotentialTI(uint256 vUint) internal pure returns (int128 potential_ti) {
         // Convert V from uint256 to 64.64 fixed-point
        int128 v = ABDKMath64x64.fromUInt(vUint);

        // Calculate 1 + V
        int128 one_plus_v = C_ONE.add(v);

        // Ensure argument for sqrt is non-negative.
        // Since vUint is uint, v is non-negative, so 1+v is positive.
        // Adding check for robustness against potential negative C_ONE definition issues.
        require(one_plus_v >= 0, "CalcLib: Sqrt argument must be non-negative");

        // Calculate sqrt(1 + V)
        int128 sqrt_val = ABDKMath64x64.sqrt(one_plus_v);

        // Calculate potential_TI = sqrt(1 + V) / 0.1
        require(C_0_1 != 0, "CalcLib: Division by zero constant");
        potential_ti = sqrt_val.div(C_0_1);
    }

    /**
     * @notice Calculates the final Swoupon Reward TI(V), capped at (1/3) * TR(V).
     * @param vUint The input volume V as an unsigned integer.
     * @return ti The final capped reward TI(V) as a 64.64 fixed-point number.
     */
    function calculateTI(uint256 vUint) internal pure returns (int128 ti) {
        // Calculate the cost TR(V)
        int128 tr = calculateTR(vUint);

        // Calculate the potential reward TI(V)
        int128 potentialTi = calculatePotentialTI(vUint);

        // Calculate the upper bound cap: (1/3) * TR(V)
        int128 tiUpperBound = tr.mul(MAX_TI_FRACTION);

        // Determine the final TI: min(potential TI, upper bound)
        ti = _min(potentialTi, tiUpperBound);
    }

    /**
     * @notice Calculates both TR(V) and the final capped TI(V) efficiently.
     * @param vUint The input volume V as an unsigned integer.
     * @return tr The calculated cost TR(V) as a 64.64 fixed-point number.
     * @return ti The final capped reward TI(V) as a 64.64 fixed-point number.
     */
    function calculateTRAndTI(uint256 vUint) internal pure returns (int128 tr, int128 ti) {
        // Calculate TR only once
        tr = calculateTR(vUint);

        // Calculate potential reward
        int128 potentialTi = calculatePotentialTI(vUint);

        // Calculate the upper bound cap
        int128 tiUpperBound = tr.mul(MAX_TI_FRACTION);

        // Determine the final TI
        ti = _min(potentialTi, tiUpperBound);

        // Returns tr, ti
    }
}