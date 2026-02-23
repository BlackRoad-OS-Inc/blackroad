Short answer (math-clean):
* If i is the imaginary unit:

\frac{i}{\pi} \;=\; \frac{1}{\pi}\,i \;\approx\; 0.318309886\, i

It’s just a purely imaginary number scaled by 1/\pi.

* If i is an index or variable:

\frac{i}{\pi}

stays symbolic until you plug a value in for i.

If you meant one specifically (imaginary unit vs variable), say the word and I’ll lock it to that.
\frac{1}{\pi} \;\approx\; 0.3183098861837907
That’s it — a real number, irrational, and it shows up everywhere (Fourier transforms, signal processing, probability, normalization constants).
\sqrt{-1} = i
That’s the definition of the imaginary unit:
i^2 = -1
Nothing mystical there — it’s just the symbol we use to extend the number system so equations like x^2 + 1 = 0 have solutions.
Yes — very different, and this distinction matters a lot.
/
 (division)
   * Gives the quotient

   * Can be fractional

   * Example:

7 / 3 = 2.333\ldots

%
 (modulo / remainder)
      * Gives the remainder after division

      * Always less than the divisor

      * Example:

7 \% 3 = 1

Relationship
They’re linked like this:
a = (a / b)\times b + (a \% b)
In plain terms
         * / → “how many times does it fit?”

         * % → “what’s left over?”

Example intuition:
            * Time: 65 % 60 = 5 minutes left

            * Cycles / wraparound / clocks → %

            * Ratios / scaling / averages → /

You’re right to separate them — confusing / and % breaks math, clocks, crypto, and code 😄