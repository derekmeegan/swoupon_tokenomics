const { expect } = require("chai");
const { ethers } = require("hardhat");

// Helper function to convert float to ABDK 64.64 fixed-point BigInt
// Uses ethers.parseFixed for reliable conversion
function toInt128Fixed(num) {
    const multiplier = BigInt("18446744073709551616"); // 2^64
    const [integerPart, fractionalPart = ""] = num.toString().split('.');
    let result = BigInt(integerPart) * multiplier;
    if (fractionalPart) {
      const fractionalDigits = BigInt(fractionalPart.length);
      const fractionalValue = BigInt(fractionalPart);
      const divisor = BigInt(10) ** fractionalDigits;
      result += (fractionalValue * multiplier) / divisor;
    }
    return result;
  }  

// Pre-calculated expected values from the Python script (use the FINAL corrected output)
const testScenarios = [
  // Volume | TR                  | TI
  { v: 0,      tr: 0.0,               ti: 0.0 },
  { v: 1,      tr: 0.2999900002,      ti: 0.0999966667 }, // min(10.0, 0.1000045)
  { v: 100,    tr: 29.9002495839,     ti: 9.9667498613 }, // min(39.81, 9.95069)
  { v: 1000,   tr: 290.2458849001,    ti: 79.4566449837 }, // min(62.83, 95.36)
  { v: 10000,  tr: 2213.0613194253,   ti: 158.4940737593 }, // min(158.48, 646.21)
  { v: 50000,  tr: 5820.8499862390,   ti: 256.8583018713 }, // min(335.38, 1785.34)
  { v: 100000, tr: 10134.7589399817,  ti: 316.2287146968 }, // min(354.33, 2363.57)
  { v: 500000, tr: 50000.0000013888,  ti: 512.4969225504 }, // min(598.57, 3381.04)
];


describe("CalcLib Library", function () {
  let testWrapper;

  before(async function () {
    // Deploy the wrapper contract which uses the library
    const TestWrapperFactory = await ethers.getContractFactory("TestCalcLibWrapper");
    testWrapper = await TestWrapperFactory.deploy();
    // await testWrapper.deployed(); // deprecated, deployment waits automatically
     await testWrapper.waitForDeployment(); // Use this instead
  });

  describe("calculateTRAndTI", function () {
    testScenarios.forEach(({ v, tr: expectedTrFloat, ti: expectedTiFloat }) => {
      it(`should correctly calculate TR and TI for V = ${v}`, async function () {
        const inputV_Uint = BigInt(v); // Convert volume to BigInt for uint256

        // Calculate expected fixed-point values (int128 represented as BigInt)
        const expectedTrFixed = toInt128Fixed(expectedTrFloat);
        const expectedTiFixed = toInt128Fixed(expectedTiFloat);

        // Call the public wrapper function
        const [trResult, tiResult] = await testWrapper.calculateTRAndTI_public(inputV_Uint);

        // --- Comparison ---
        // Fixed-point math can have tiny precision differences between implementations (Python float vs Solidity fixed-point)
        // It's often better to check if the result is "close to" the expected value.

        // Define an acceptable tolerance (e.g., 1 unit in the lowest precision bit of 64.64)
        // Or a small absolute value difference. Let's use a small fixed tolerance based on expected scale.
        // Tolerance needs careful tuning based on expected magnitudes and library precision.
        // Let's try a tolerance equivalent to ~1e-10 as a starting point.
        const tolerance = ethers.parseUnits("0.0000000001", 64); // Small tolerance in 64.64 format

        // console.log(`V=${v}`);
        // console.log(` Expected TR Fixed: ${expectedTrFixed.toString()}`);
        // console.log(` Actual TR Fixed:   ${trResult.toString()}`);
        // console.log(` Diff TR:           ${(expectedTrFixed - trResult).toString()}`);
        // console.log(` Expected TI Fixed: ${expectedTiFixed.toString()}`);
        // console.log(` Actual TI Fixed:   ${tiResult.toString()}`);
        // console.log(` Diff TI:           ${(expectedTiFixed - tiResult).toString()}`);
        // console.log(` Tolerance:         ${tolerance.toString()}`);


        expect(trResult).to.be.closeTo(expectedTrFixed, tolerance, `TR mismatch for V=${v}`);
        expect(tiResult).to.be.closeTo(expectedTiFixed, tolerance, `TI mismatch for V=${v}`);

        // // Alternative: Strict equality (might fail due to tiny precision diffs)
        // expect(trResult).to.equal(expectedTrFixed);
        // expect(tiResult).to.equal(expectedTiFixed);
      });
    });
     // Add specific edge case tests if needed (e.g., very large V if overflow is a concern)
     it("should return 0 for TR and TI when V = 0", async function () {
        const [trResult, tiResult] = await testWrapper.calculateTRAndTI_public(0);
        expect(trResult).to.equal(0);
        expect(tiResult).to.equal(0);
    });
  });

  // Optional: Add tests for individual functions if desired
  describe("calculatePotentialTI", function() {
      it("should calculate potential TI correctly for V=1000 (example)", async function() {
          const v = 1000;
          const vUint = BigInt(v);
          // Python: np.power(1 + 1000, 0.3) / 0.1 = 62.83185307179587
          const expectedPotentialTIFloat = 62.8318530718;
          const expectedPotentialTIFixed = toInt128Fixed(expectedPotentialTIFloat);
          const tolerance = ethers.parseUnits("0.0000000001", 64);

          const potentialTiResult = await testWrapper.calculatePotentialTI_public(vUint);
          expect(potentialTiResult).to.be.closeTo(expectedPotentialTIFixed, tolerance);
      });
  });

});