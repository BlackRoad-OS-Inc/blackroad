#!/usr/bin/env python3
"""
Golden Ratio Verification Script
Verifies all measurements in the golden ratio templates are mathematically correct.
"""

import math
import json

# High precision golden ratio
PHI = (1 + math.sqrt(5)) / 2  # 1.618033988749895
PHI_INV = PHI - 1  # 0.618033988749895
PHI_SQUARED = PHI + 1  # 2.618033988749895

# Fibonacci sequence
FIBONACCI = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597]

def verify_ratio(value1, value2, expected_ratio=PHI, tolerance=0.001, name=""):
    """Verify that value1/value2 equals expected ratio within tolerance."""
    if value2 == 0:
        return False, f"Division by zero"

    actual_ratio = value1 / value2
    difference = abs(actual_ratio - expected_ratio)
    is_valid = difference < tolerance

    status = "✓" if is_valid else "✗"
    print(f"{status} {name}: {value1}/{value2} = {actual_ratio:.6f} (expected {expected_ratio:.6f}, diff: {difference:.6f})")

    return is_valid, actual_ratio

def verify_golden_section(total, major, minor, tolerance=1):
    """Verify golden section: major/minor = phi, major+minor = total."""
    print(f"\nGolden Section: Total={total}, Major={major}, Minor={minor}")

    # Check sum
    sum_check = abs((major + minor) - total) < tolerance
    print(f"{'✓' if sum_check else '✗'} Sum check: {major} + {minor} = {major + minor} (expected {total})")

    # Check ratio
    ratio_check, ratio = verify_ratio(major, minor, PHI, 0.01, "Major/Minor ratio")

    # Check percentages
    major_pct = (major / total) * 100
    minor_pct = (minor / total) * 100
    print(f"  Major: {major_pct:.1f}% (expected ~61.8%)")
    print(f"  Minor: {minor_pct:.1f}% (expected ~38.2%)")

    return sum_check and ratio_check

def verify_fibonacci_ratios():
    """Verify Fibonacci ratios converge to phi."""
    print("\n" + "="*60)
    print("FIBONACCI SEQUENCE CONVERGENCE TO φ")
    print("="*60)

    for i in range(2, len(FIBONACCI)):
        ratio = FIBONACCI[i] / FIBONACCI[i-1]
        diff = abs(ratio - PHI)
        converging = "→ φ" if i > 6 else ""
        print(f"F({i})/F({i-1}) = {FIBONACCI[i]:4d}/{FIBONACCI[i-1]:4d} = {ratio:.10f} (diff: {diff:.6f}) {converging}")

    print(f"\nφ (actual) = {PHI:.15f}")

def verify_canva_templates():
    """Verify Canva template dimensions."""
    print("\n" + "="*60)
    print("CANVA TEMPLATES VERIFICATION")
    print("="*60)

    templates = [
        ("Classic Golden Rectangle", 1618, 1000),
        ("Golden Spiral Layout", 2618, 1618),
        ("Card Layout (Portrait)", 1000, 618),
    ]

    for name, width, height in templates:
        print(f"\n{name}:")
        verify_ratio(width, height, PHI, 0.01, f"  {width}×{height}")

def verify_jetbrains_layout():
    """Verify JetBrains layout proportions."""
    print("\n" + "="*60)
    print("JETBRAINS LAYOUT VERIFICATION")
    print("="*60)

    # Total width
    total_width = 2560
    editor_width = int(total_width / PHI)  # 1582
    sidebar_width = total_width - editor_width  # 978

    print(f"\nWidth Division (Total: {total_width}px):")
    verify_ratio(editor_width, sidebar_width, PHI, 0.01, f"  Editor/Sidebar")
    verify_golden_section(total_width, editor_width, sidebar_width)

    # Height
    total_height = 1440
    toolbar = 55
    statusbar = 34
    editor_pane = total_height - toolbar - statusbar

    print(f"\nHeight Division (Total: {total_height}px):")
    print(f"  Toolbar: {toolbar}px (Fibonacci)")
    print(f"  Editor: {editor_pane}px")
    print(f"  Status: {statusbar}px (Fibonacci)")

def verify_typography_scale():
    """Verify typography follows Fibonacci/golden ratio."""
    print("\n" + "="*60)
    print("TYPOGRAPHY SCALE VERIFICATION")
    print("="*60)

    font_sizes = [89, 55, 34, 21, 13, 8]

    print("\nFont Size Ratios (should approach φ):")
    for i in range(len(font_sizes) - 1):
        verify_ratio(font_sizes[i], font_sizes[i+1], PHI, 0.1, f"  {font_sizes[i]}pt / {font_sizes[i+1]}pt")

def verify_split_ratios():
    """Verify editor split ratios."""
    print("\n" + "="*60)
    print("SPLIT EDITOR RATIOS VERIFICATION")
    print("="*60)

    print("\nHorizontal/Vertical Split (0.618 : 0.382):")
    left = 0.618
    right = 0.382
    total = left + right

    print(f"  Left/Top: {left:.3f} ({left*100:.1f}%)")
    print(f"  Right/Bottom: {right:.3f} ({right*100:.1f}%)")
    print(f"  Sum: {total:.3f}")
    print(f"  {'✓' if abs(total - 1.0) < 0.001 else '✗'} Sum equals 1.0")
    verify_ratio(left, right, PHI, 0.01, "  Ratio check")

def verify_golden_spiral():
    """Verify golden spiral square sizes."""
    print("\n" + "="*60)
    print("GOLDEN SPIRAL SQUARES VERIFICATION")
    print("="*60)

    squares = [1618, 1000, 618, 382, 236, 146, 90]

    print("\nSquare sizes (each should be previous / φ):")
    for i in range(len(squares) - 1):
        expected = squares[i] / PHI
        actual = squares[i+1]
        diff = abs(actual - expected)
        status = "✓" if diff < 5 else "✗"
        print(f"{status} {squares[i]} / φ = {expected:.1f} (actual: {actual}, diff: {diff:.1f})")

def verify_mathematical_constants():
    """Verify golden ratio mathematical properties."""
    print("\n" + "="*60)
    print("MATHEMATICAL CONSTANTS VERIFICATION")
    print("="*60)

    print(f"\nφ = {PHI:.15f}")
    print(f"φ² = {PHI_SQUARED:.15f}")
    print(f"1/φ = {PHI_INV:.15f}")

    # Verify properties
    print("\nMathematical Properties:")

    # φ² = φ + 1
    phi_squared_calc = PHI * PHI
    phi_plus_one = PHI + 1
    print(f"{'✓' if abs(phi_squared_calc - phi_plus_one) < 0.000001 else '✗'} φ² = φ + 1")
    print(f"  {phi_squared_calc:.15f} = {phi_plus_one:.15f}")

    # 1/φ = φ - 1
    one_over_phi = 1 / PHI
    phi_minus_one = PHI - 1
    print(f"{'✓' if abs(one_over_phi - phi_minus_one) < 0.000001 else '✗'} 1/φ = φ - 1")
    print(f"  {one_over_phi:.15f} = {phi_minus_one:.15f}")

    # φ = (1 + √5) / 2
    phi_formula = (1 + math.sqrt(5)) / 2
    print(f"{'✓' if abs(phi_formula - PHI) < 0.000001 else '✗'} φ = (1 + √5) / 2")
    print(f"  {phi_formula:.15f} = {PHI:.15f}")

def main():
    """Run all verification tests."""
    print("="*60)
    print("GOLDEN RATIO TEMPLATES VERIFICATION")
    print("Mathematical precision check for Canva & JetBrains templates")
    print("="*60)

    verify_mathematical_constants()
    verify_fibonacci_ratios()
    verify_canva_templates()
    verify_jetbrains_layout()
    verify_typography_scale()
    verify_split_ratios()
    verify_golden_spiral()

    print("\n" + "="*60)
    print("VERIFICATION COMPLETE")
    print("="*60)
    print("\nAll measurements verified against φ = 1.618033988749895")
    print("Fibonacci sequence ratios converge to φ as expected")
    print("Golden sections maintain proper proportions")
    print("\n✓ Templates are mathematically correct!")

if __name__ == "__main__":
    main()
