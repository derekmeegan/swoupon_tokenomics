# Swoupon Tokenomics Calculation Library

This repository contains the Solidity implementation and reference calculations for the Swoupon tokenomics framework. Swoupon is a liquidity pool rewards system designed to incentivize swappers in decentralized exchanges.

## Overview

Swoupon introduces an innovative approach to liquidity pool incentives by creating a balanced economic system where:

- Swappers pay a dynamic fee (`TR`) based on their swap volume
- Swappers receive reward tokens (`TI`, or "Swoupons") that can be used to pay for future swap fees
- Swoupons are only issued for transactions that are not already paid with Swoupons
- The system automatically adjusts to market conditions through volume-dependent calculations

The core principle is to create a sustainable economic model where users are incentivized to continue using the protocol by earning Swoupons on one swap that they can redeem on future swaps, creating a virtuous cycle of engagement.

## Key Features

- **Dynamic Fee Structure**: Fees decrease as volume increases, incentivizing larger swaps
- **Swoupon Rewards**: Users earn Swoupons on regular swaps that they can redeem for future swap fees
- **Reward Cycle**: Only swaps paid with regular fees (not with Swoupons) generate new Swoupon rewards
- **Fixed-Point Math**: All calculations use 64.64 fixed-point arithmetic for precise on-chain execution
- **Gas Optimized**: Calculations are designed to be efficient for on-chain execution

## Mathematical Model

The Swoupon system is built on several key mathematical functions:

### 1. Fee Factor Function F(V)

This function calculates a dynamic fee factor that decreases as volume increases:

$$F(V) = 0.01 + (0.02 \cdot e^{-0.00005 \cdot V})$$

Where:
- $V$ is the swap volume
- The fee factor ranges from 0.03 (at $V=0$) to 0.01 (as $V$ approaches infinity)

### 2. Swoupon Cost TR(V)

This function calculates the cost charged for a swap of volume $V$:

$$TR(V) = \frac{F(V) \cdot V}{0.1}$$

This represents the amount of fees a user would pay for a swap, or alternatively, the amount of Swoupons they would need to spend if using Swoupons for the transaction.

### 3. Potential Swoupon Reward TI(V)

This function calculates the potential Swoupon reward a user would receive when making a swap paid with regular fees (not with Swoupons):

$$potential\_TI(V) = \frac{(1 + V)^{0.3}}{0.1}$$

### 4. Final Swoupon Reward TI(V)

The actual Swoupon reward issued, capped at a fraction of the cost:

$$TI(V) = \min(potential\_TI(V), \frac{TR(V)}{3})$$

This ensures that rewards never exceed one-third of the fees collected, maintaining economic sustainability. These Swoupons can then be used to pay for future swap fees.

## Implementation Details

### Solidity Implementation

The core calculations are implemented in `contracts/CalcLib.sol` using the [ABDKMath64x64](https://github.com/abdk-consulting/abdk-libraries-solidity) library for fixed-point arithmetic. The implementation includes:

- Fixed-point constants for all mathematical parameters
- Helper functions for min/max operations
- Core calculation functions for F(V), TR(V), and TI(V)
- Combined calculation function for efficiency

### Fixed-Point Constants

```solidity
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
```

## Python Reference Implementation

A Python reference implementation is provided in `python/swoupon_calc.py` for simulation and testing purposes. This implementation:

- Uses NumPy for mathematical operations
- Provides the same core functions as the Solidity implementation
- Includes test cases and verification logic
- Uses the exact $(1 + V)^{0.3}$ formula for potential TI calculation

## Testing

The Solidity implementation is thoroughly tested using Hardhat:

- Unit tests for all calculation functions
- Comparison against pre-calculated values from the Python implementation
- Edge case testing for V=0 and other boundary conditions
- Precision testing with appropriate tolerances

## Visualization

The following chart illustrates how TR and TI scale with volume:

![Calculation Visualization](./assets/charts.png)

## Development

This project uses Hardhat for Solidity development:

- **Setup**: `npm install`
- **Compile**: `npx hardhat compile`
- **Test**: `npx hardhat test`

## Integration

To integrate this library into your project:

1. Import the `CalcLib.sol` contract
2. Use the calculation functions to determine fees and rewards based on swap volume
3. Ensure your contract has access to the ABDKMath64x64 library

## License

MIT License

Copyright (c) 2025 Swoupon

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
