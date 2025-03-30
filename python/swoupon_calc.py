# swoupon_calc.py
import numpy as np

# --- Constants ---
C_0_01 = 0.01
C_0_02 = 0.02
C_NEG_0_00005 = -0.00005
C_0_1 = 0.1
POWER_EXPONENT = 0.3 # Exponent for potential TI calculation (was 0.5 for sqrt)
MAX_TI_FRACTION_OF_TR = 1/3 # Maximum TI relative to TR

# --- Core Calculation Functions ---

def _F(v: float) -> float:
    """
    Calculates the intermediate factor F(V).
    F(V) = 0.01 + (0.02 * exp(-0.00005 * V))
    """
    if v < 0:
        raise ValueError("Volume (v) cannot be negative")
    return C_0_01 + (C_0_02 * np.exp(C_NEG_0_00005 * v))

def calculate_TR(v: float) -> float:
    """
    Calculates the Swoupon Cost TR(V).
    TR(V) = F(V) * V / 0.1
    """
    if v < 0:
        raise ValueError("Volume (v) cannot be negative")
    if v == 0:
        return 0.0 # TR(0) is 0
    if C_0_1 == 0:
        raise ZeroDivisionError("Constant C_0_1 cannot be zero")

    f_v = _F(v)
    return f_v * v / C_0_1

def calculate_potential_TI(v: float) -> float:
    """
    Calculates the potential Swoupon Reward potential_TI(V).
    potential_TI(V) = (1 + V)^POWER_EXPONENT / 0.1
    """
    if v < 0:
        raise ValueError("Volume (v) cannot be negative")
    if C_0_1 == 0:
        raise ZeroDivisionError("Constant C_0_1 cannot be zero")

    base = 1 + v
    # np.power handles potential floating point issues with negative bases better
    # but since v >= 0, base >= 1, this is safe.
    pow_val = np.power(base, POWER_EXPONENT)
    return pow_val / C_0_1

def calculate_TR_and_TI(v: float) -> tuple[float, float]:
    """
    Calculates both the final TR (Cost) and the capped TI (Reward).

    Args:
        v (float): The input volume V (non-negative).

    Returns:
        tuple[float, float]: A tuple containing (TR, TI).
    """
    if v < 0:
        raise ValueError("Volume (v) cannot be negative")

    # 1. Calculate TR (Cost)
    tr_value = calculate_TR(v)

    # 2. Calculate potential TI (Reward)
    potential_ti_value = calculate_potential_TI(v)

    # 3. Calculate the upper bound cap for TI based on TR
    ti_upper_bound = MAX_TI_FRACTION_OF_TR * tr_value

    # 4. Determine final TI: minimum of potential TI and the cap
    ti_value = min(potential_ti_value, ti_upper_bound)

    # Ensure TI is not negative (shouldn't happen with these formulas, but good practice)
    ti_value = max(0.0, ti_value)

    return tr_value, ti_value

# --- Main execution block for testing ---
if __name__ == "__main__":
    test_volumes = [0, 1, 100, 1000, 10_000, 50_000, 100_000, 500_000]

    print("--- Python Calculation Scenarios ---")
    print(f"{'Volume (V)':<12} | {'TR (Cost)':<25} | {'TI (Reward)':<25}")
    print("-" * 67)

    for volume in test_volumes:
        try:
            tr, ti = calculate_TR_and_TI(volume)
            print(f"{volume:<12} | {tr:<25.10f} | {ti:<25.10f}")
        except Exception as e:
            print(f"{volume:<12} | {'Error':<25} | {'Error':<25} ({e})")

    print("-" * 67)

    # Example of checking where capping occurs
    print("\nChecking potential vs capped TI for V=100,000:")
    v_example = 100_000
    tr_ex = calculate_TR(v_example)
    pot_ti_ex = calculate_potential_TI(v_example)
    cap_ex = MAX_TI_FRACTION_OF_TR * tr_ex
    final_ti_ex = min(pot_ti_ex, cap_ex)
    print(f"  V = {v_example}")
    print(f"  TR = {tr_ex:.6f}")
    print(f"  Potential TI = {pot_ti_ex:.6f}")
    print(f"  TI Cap (TR/3) = {cap_ex:.6f}")
    print(f"  Final TI = {final_ti_ex:.6f} (Capped: {pot_ti_ex > cap_ex})")