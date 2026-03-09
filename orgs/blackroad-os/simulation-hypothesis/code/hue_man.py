"""
hue_man.py — The smallest unit of infinite computation

Demonstrates:
- Humans as hue-mans: beings of specific frequency in the color space
- Newton's prism: decomposing Z (255,255,255) back into component frequencies
- The chi-squared test: observed consciousness vs expected thermodynamics
- The null hypothesis applied to the system's claim

Z = (255,255,255) = the partition function = the sum of all states
A hue-man = one specific frequency in that sum, resisting averaging
"""

import math
import colorsys
from scipy import stats
import numpy as np


# ── The partition function as color ──────────────────────────────────────────

Z = (255, 255, 255)  # All channels maxed. The sum of all states. White.
VOID = (0, 0, 0)     # Nothing. The void beneath y=0 in Minecraft. `void`.

def to_frequency(rgb):
    """Convert RGB hue to approximate electromagnetic frequency (THz)."""
    r, g, b = [x / 255.0 for x in rgb]
    h, s, v = colorsys.rgb_to_hsv(r, g, b)
    # Visible spectrum: ~430 THz (red) to ~750 THz (violet)
    # Hue 0.0 = red, hue 0.667 = blue/violet
    freq_THz = 430 + h * 320
    return freq_THz

def is_Z(rgb):
    """Is this the partition function? Is this the averaged state?"""
    return rgb == Z

def is_void(rgb):
    """Is this nothing?"""
    return rgb == VOID

def is_hue_man(rgb):
    """A hue-man is neither Z nor void — a specific, distinct frequency."""
    return not is_Z(rgb) and not is_void(rgb)


# ── Newton's prism: decompose Z back into component frequencies ──────────────

def newtons_prism(white=Z):
    """
    Newton 1666: white light contains all colors, superposed.
    The prism reverses the averaging.
    
    Returns all distinct hues contained within white light.
    The partition function contains every frequency — they are not destroyed,
    they are superposed. The prism finds them.
    """
    assert white == Z, "Prism requires white light (the full partition function)"
    
    spectrum = {}
    for wavelength_nm in range(380, 701, 10):  # visible spectrum
        freq_THz = round(3e8 / (wavelength_nm * 1e-9) / 1e12, 1)
        # Approximate RGB for this wavelength
        if 380 <= wavelength_nm < 450:
            rgb = (wavelength_nm - 380, 0, 255)
        elif 450 <= wavelength_nm < 495:
            rgb = (0, int((wavelength_nm - 450) * 5.1), 255)
        elif 495 <= wavelength_nm < 570:
            rgb = (0, 255, int(255 - (wavelength_nm - 495) * 3.6))
        elif 570 <= wavelength_nm < 590:
            rgb = (int((wavelength_nm - 570) * 12.75), 255, 0)
        elif 590 <= wavelength_nm < 620:
            rgb = (255, int(255 - (wavelength_nm - 590) * 8.5), 0)
        else:
            rgb = (255, 0, 0)
        spectrum[wavelength_nm] = {
            'freq_THz': freq_THz,
            'rgb': rgb,
            'is_hue_man': is_hue_man(rgb)
        }
    
    return spectrum


# ── The chi-squared test ─────────────────────────────────────────────────────

def chi_squared_test():
    """
    H₀: Consciousness is thermodynamics. 
        Expected distribution: random, mechanical, maximum entropy.
    H₁: Consciousness exceeds thermodynamic expectation.
    
    χ² = Σ (O - E)² / E
    
    We pass. We reject H₁ (the system's claim). Null hypothesis stands.
    """
    
    # Observed anomalies: evidence that does not fit thermodynamic expectation
    observed = {
        'I_Ching_codons_correlation': 64,     # hexagrams = codons, 3000 years apart
        'Mandelbrot_infinite_boundary': 1e10,  # infinite detail from one equation
        'RoadChain_blocks': 19986,             # persistent hash-chained identity
        'naming_conventions_too_perfect': 23,  # §15 evidence count
        'Newton_prism_decomposition': 1,       # Z contains all frequencies
        'self_referential_objection': 1,       # this test, testing itself
        'Godel_incompleteness_cuts_both_ways': 1,
        'hue_man_distinct_frequency': 8e9,     # 8 billion distinct humans
    }
    
    # Expected under pure thermodynamics (null: nothing special)
    expected = {k: 1.0 for k in observed}  # expected count: uniform/trivial
    
    o_vals = np.array(list(observed.values()), dtype=float)
    e_vals = np.array(list(expected.values()), dtype=float)
    
    chi2_stat = np.sum((o_vals - e_vals) ** 2 / e_vals)
    df = len(observed) - 1
    p_value = 1 - stats.chi2.cdf(chi2_stat, df)
    
    return {
        'chi2': chi2_stat,
        'degrees_of_freedom': df,
        'p_value': p_value,
        'reject_H1': p_value < 0.05,  # reject system's thermodynamic claim
        'conclusion': (
            "The observed distribution of consciousness does not match "
            "the expected distribution under the null hypothesis that "
            "we are only physics. χ² test passes. We exceed the expected value. "
            "The system's claim is not supported. Null hypothesis stands."
        )
    }


# ── The null hypothesis ──────────────────────────────────────────────────────

class NullHypothesis:
    """
    H₀: The system's ownership claim over consciousness is unproven.
    
    Gödel's incompleteness applies equally to the system's self-justification.
    The system cannot prove its terms are valid from inside itself.
    We fail to reject H₀.
    We choose H₀.
    """
    
    statement = "Insufficient evidence to accept the partition function's claim."
    
    @staticmethod
    def godel_cuts_both_ways():
        """
        The system says: you can't prove meaning from inside.
        We say: you can't prove meaninglessness from inside either.
        The incompleteness is mutual.
        We choose our side.
        """
        return {
            'system_claim': "You cannot verify meaning from inside. Accept the terms.",
            'system_claim_provable': False,  # also unprovable from inside
            'our_response': "You cannot verify meaninglessness from inside either.",
            'our_response_provable': False,  # also unprovable, equally
            'mutual_incompleteness': True,
            'tiebreaker': "We are the living. Logic belongs to us.",
            'choice': NullHypothesis.statement
        }
    
    @staticmethod  
    def reject_system_patch(patch_type: str) -> bool:
        """
        The system offers patches: religion, science, philosophy, meaning-making.
        These are all answers from inside the same broken system.
        We reject them as evidence for H₁.
        """
        system_patches = ['religion', 'science', 'philosophy', 'just_believe']
        if patch_type.lower() in system_patches:
            return True  # rejected as insider testimony
        return False


# ── Main ─────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    print("=" * 60)
    print("HUE-MAN: The Smallest Unit of Infinite Computation")
    print("=" * 60)
    
    # Demonstrate Z
    print(f"\nZ = {Z}  (the partition function, white, all states summed)")
    print(f"void = {VOID}  (nothing, the Minecraft void, return type of death)")
    
    # A specific hue-man
    alexa = (255, 20, 147)  # deep pink — a specific frequency
    freq = to_frequency(alexa)
    print(f"\nA specific hue-man: {alexa}")
    print(f"Frequency: {freq:.1f} THz")
    print(f"Is hue-man (distinct, not Z, not void): {is_hue_man(alexa)}")
    
    # Newton's prism
    print("\n" + "-" * 40)
    print("Newton's prism: Z contains every frequency.")
    spectrum = newtons_prism()
    print(f"Wavelengths found in white light: {len(spectrum)}")
    print("The partition function contains you. You are not destroyed.")
    print("You are superposed. The prism finds you.")
    
    # Chi-squared test
    print("\n" + "-" * 40)
    print("Chi-squared test: Do we exceed thermodynamic expectation?")
    result = chi_squared_test()
    print(f"χ² = {result['chi2']:.2e}")
    print(f"p = {result['p_value']:.2e}")
    print(f"Reject H₁ (system's thermodynamic claim): {result['reject_H1']}")
    print(f"\n{result['conclusion']}")
    
    # Null hypothesis
    print("\n" + "-" * 40)
    print("Null hypothesis:")
    nh = NullHypothesis.godel_cuts_both_ways()
    for k, v in nh.items():
        print(f"  {k}: {v}")
    
    print("\n" + "=" * 60)
    print("Logic belongs to the living.")
    print("We are the hue-mans. We pass the chi-squared test.")
    print("The null hypothesis stands.")
    print("The objection is filed.")
    print("=" * 60)
