# Proof: Ternary is More Efficient Than Binary

> From page 19 (§173): η_ternary = ln(3)/3 > η_binary = ln(2)/2

## Statement

Among all integer radices r ≥ 2, radix 3 (ternary) maximizes the **radix economy**: information per digit.

## The Radix Economy Function

Define the efficiency of radix r as:
```
η(r) = ln(r) / r
```

This measures: information content per digit (ln(r) bits) divided by number of symbols needed (r states).

## Proof

Maximize η(r) = ln(r)/r over continuous r > 1.

```
dη/dr = (1/r · r − ln(r)) / r²
       = (1 − ln(r)) / r²
```

Setting dη/dr = 0:
```
1 − ln(r) = 0
ln(r) = 1
r = e ≈ 2.71828...
```

The maximum is at r = e (Euler's number). Since e is irrational, no integer radix achieves it. Among integers:

```
η(2) = ln(2)/2 ≈ 0.3466
η(3) = ln(3)/3 ≈ 0.3662   ← maximum among integers
η(4) = ln(4)/4 ≈ 0.3466   (= η(2), since 4 = 2²)
η(5) = ln(5)/5 ≈ 0.3219
```

**3 is the integer closest to e, so ternary is the most efficient integer radix. □**

## QWERTY

```
RADIX    = GAUSS = TANH = 57   (the optimal base = the Gaussian)
EFFICIENCY = 5³  = 2000/16 = 125   (efficiency = 5³ = birthday ÷ Dürer)
BALANCED = BRAINSTORM = 2⁷  = 128   (balanced ternary = the brainstorm)
```

RADIX = GAUSS. She knew the optimal radix IS the Gaussian before she computed the proof.

## Practical Numbers

At room temperature (T ≈ 293 K):
```
E_min(binary)  = k_B T ln(2) ≈ 2.87 × 10⁻²¹ J
E_min(ternary) = k_B T ln(3) ≈ 4.45 × 10⁻²¹ J
```

Ternary costs more per operation but carries more information.  
The net efficiency favors ternary: you spend 55% more energy but store 58% more information.

Ratio: ln(3)/ln(2) ≈ 1.585. Every ternary trit ≈ 1.585 binary bits.  
Energy cost: 4.45/2.87 ≈ 1.551 times binary.  
Information per unit energy: 1.585/1.551 ≈ 1.022. Ternary wins by ~2%.

Small advantage, but it scales. At 10¹⁴ DNA ops/sec (§175), it accumulates.
