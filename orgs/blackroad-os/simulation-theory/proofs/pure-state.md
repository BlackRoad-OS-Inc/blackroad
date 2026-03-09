# Proof: The Density Matrix Is a Pure State

> From page 24 (§178): SVD yields one nonzero singular value.

## Statement

The density matrix ρ computed from the qutrit state |ψ⟩ on page 24 is a **pure state** — it has rank 1 and exactly one nonzero singular value.

## The State

```
|ψ⟩ = [ 0.4711,  0.7708,  0.8620 ]ᵀ
```

## The Density Matrix

```
ρ = |ψ⟩⟨ψ| = [ 0.2219  0.3629  0.4062 ]
              [ 0.3629  0.5941  0.6639 ]
              [ 0.4062  0.6639  0.7401 ]
```

## Proof of Pure State

**Definition:** A density matrix ρ is a pure state iff ρ² = ρ (idempotent) iff rank(ρ) = 1.

**For ρ = |ψ⟩⟨ψ|:**
```
ρ² = (|ψ⟩⟨ψ|)(|ψ⟩⟨ψ|) = |ψ⟩⟨ψ|ψ⟩⟨ψ| = |ψ⟩ · ‖ψ‖² · ⟨ψ|
```

If |ψ⟩ is normalized (‖ψ‖² = 1), then ρ² = ρ.  
If |ψ⟩ is unnormalized (‖ψ‖² = Tr(ρ) ≈ 1.559), then ρ is proportional to a projector.

**SVD result:**
```
Singular values: σ₁ ≈ 1.559,  σ₂ ≈ 2.5×10⁻¹⁶,  σ₃ ≈ 6.5×10⁻¹⁷
```

σ₂ and σ₃ are machine epsilon — numerically zero. **Rank = 1. □**

## The Single Nonzero Singular Value

```
σ₁ = Tr(ρ) = ‖ψ‖² = 0.4711² + 0.7708² + 0.8620²
            = 0.2219 + 0.5941 + 0.7430
            ≈ 1.559
```

The one singular value = the norm squared of the state. One degree of freedom.

## QWERTY

```
SVD   = SELF = SPHERE = ZSH  = 48  = 2×PURE
PURE  = 4!              = 24
TRACE = QUBIT = SUM     = 45   (Tr(ρ) = 45 in QWERTY; ρ is the qubit generalized)
VALUE = TRINARY = LIGHT = 63   (the singular value = ternary = light)
```

SVD = 2×PURE.  
The decomposition reveals twice the pure state.  
She is a pure state. Rank 1. One eigenvalue.  
The universe she describes has one degree of freedom: her.
