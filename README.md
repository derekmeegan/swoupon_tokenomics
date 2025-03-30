# Swoupon Tokenomics Calculation Module

This repository contains the Solidity library and reference calculations for the Swoupon tokenomics framework. Swoupon is a liquidity pool rewards system designed to incentivize swappers and liquidity providers.

## Overview

The core idea is to issue reward tokens (`TI`) and charge cost tokens (`TR`) based on the volume (`V`) of a swap. This module provides the functions to calculate `TR` and `TI` for a given `V`. It also implements a dynamic fee mechanism (implicit in the `TR` calculation) that can benefit large volume swaps.

The calculations are performed using 64.64 fixed-point arithmetic via the [ABDKMath64x64](https://github.com/abdk-consulting/abdk-libraries-solidity) library to maintain precision on-chain.

## Calculations

The primary calculations implemented in `contracts/CalcLib.sol` are:

1.  **Factor F(V):** A volume-dependent factor used in cost calculation.
    `F(V) = 0.01 + (0.02 * exp(-0.00005 * V))`

2.  **Swoupon Cost TR(V):** The cost charged for a swap of volume `V`.
    `TR(V) = F(V) * V / 0.1`

3.  **Potential Swoupon Reward potential_TI(V):** The potential reward before capping.
    *Note: Due to limitations in the fixed-point library (no direct fractional powers), the Solidity implementation uses `sqrt(1+V)` which approximates the original model's target of `(1 + V)^0.3`.*
    `potential_TI(V) = sqrt(1 + V) / 0.1`

4.  **Final Swoupon Reward TI(V):** The actual reward issued, capped at a fraction of the cost.
    `TI(V) = min(potential_TI(V), TR(V) / 3)`

## Implementation

-   **Solidity:** `contracts/CalcLib.sol` contains the library with the core calculation logic using `ABDKMath64x64`.
-   **Tests:** `test/CalcLib.test.js` provides Hardhat tests for the Solidity library.
-   **Python Reference:** `python/swoupon_calc.py` is intended for reference implementations or simulations of the formulas (currently empty).

## Visualization (Example)

*(Add a brief description of what the image shows if applicable)*

![Calculation Visualization](./assets/Untitled.png)

## Development

This project uses Hardhat.

-   Compile: `npx hardhat compile`
-   Test: `npx hardhat test`
