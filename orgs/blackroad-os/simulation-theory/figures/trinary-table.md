# Trinary Logic Tables (§165, §170)

> She derived it herself. ELSE=REAL=37. UNKNOWN=3×REAL=111.

## Value System

```
+1  =  TRUE   =  YES  =  HIGH  =  "it is"
 0  =  UNKNOWN =  ?   =  MID   =  "we don't know"
−1  =  FALSE  =  NO   =  LOW   =  "it is not"
```

REAL = ELSE = 37 prime.  
UNKNOWN = 3×REAL = 111 = EXTENSION.

## Trinary NOT (TNEG)

```
 a  │ TNEG(a)
────┼─────────
+1  │   −1
 0  │    0
−1  │   +1
```

TNEG = ZSH = SPHERE = SELF = SVD = 48.

## Trinary AND (TAND)

```
TAND(a,b) = min(a,b)

    b: −1   0  +1
a: ────────────────
−1 │  −1  −1  −1
 0 │  −1   0   0
+1 │  −1   0  +1
```

TAND = HOME = EIGEN = 54.

## Trinary XOR (TXOR)

```
TXOR(a,b) = (a + b) mod 3, balanced to {−1, 0, +1}

    b: −1   0  +1
a: ────────────────
−1 │  +1  −1   0
 0 │  −1   0  +1
+1 │   0  +1  −1
```

TXOR = ROOTS = WAVE = 39.

## Trinary MUL (TMUL)

```
TMUL(a,b) = a × b

    b: −1   0  +1
a: ────────────────
−1 │  +1   0  −1
 0 │   0   0   0
+1 │  −1   0  +1
```

TMUL = TANH = GAUSS = 57 = RADIX = FIELD.  
Multiplication = Gaussian activation. The fundamental operation = the activation function.

## Concentration-State Mapping (§173)

Physical concentrations map to trinary states:

```
C ≤ C_low              →  x = −1  (FALSE)
C_low < C ≤ C_high     →  x =  0  (UNKNOWN)
C ≥ C_high             →  x = +1  (TRUE)
```

Every cell already computes in trinary.

## Ternary Wave Function (§170)

```
|Ψ⟩ = α|0⟩ + β|1⟩ + γ|?⟩
```

Three basis states: known false, known true, and **unknown**.  
The unknown is a first-class basis state. Not a superposition — a state.
