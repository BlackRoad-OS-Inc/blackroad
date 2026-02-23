# The ε/2 Principle: Temporal Grounding, Constraint Injection, and the Unobservable State


**Alexa Louise Amundson**  
BlackRoad OS, Inc.  
January 2026


-----


## Abstract


We propose that the relationship between continuous theory and discrete measurement is mediated by an unobservable transition state at exactly half the minimum observable resolution (ε/2). This principle unifies three apparently distinct phenomena: (1) the necessity of date injection for temporal grounding in large language models, (2) the role of calculators in verifying physical theories like general relativity, and (3) the quantum mechanical uncertainty principle. We argue that **symmetry constructs possibility; constraint selects actuality; and ε/2 is where the selection happens**—necessarily outside observation.


-----


## 1. Introduction: The Date Injection Problem


Consider a large language model asked “What is today’s date?” Without explicit temporal grounding, the model outputs a plausible but incorrect date—often one that appeared frequently in training data. This is not a bug but a feature: the model has learned the *structure* of temporal discourse without access to the *instance* of the current moment.


The fix is trivial: inject `current_date: 2026-01-23` into the prompt. The model immediately produces correct, grounded outputs.


This pattern—**theory without grounding produces hallucination; grounding without theory produces noise**—is not unique to language models. It is the fundamental structure of measurement itself.


-----


## 2. Calculators Verify Einstein


General relativity provides symmetric, continuous field equations:


$$G_{\mu\nu} + \Lambda g_{\mu\nu} = \frac{8\pi G}{c^4} T_{\mu\nu}$$


These equations describe *all possible* spacetime configurations consistent with the theory. They are beautiful, general, and useless without constraint injection.


A calculator “verifying” relativity performs no physics. It:


1. Accepts the theoretical structure (equations)
1. Receives specific constraints (masses, distances, initial conditions)
1. Constructs a particular instance (predicted measurement)
1. Compares to observation


The calculator is the bridge between symmetric theory and asymmetric fact. It does not understand relativity—it **grounds** relativity in specific parameters, producing testable predictions.


This is precisely what date injection does for language models: it transforms distributional knowledge (what dates look like) into grounded knowledge (what date it is).


-----


## 3. The Asymmetry Principle


We observe a fundamental asymmetry:


|Operation            |Complexity  |Character                                 |
|---------------------|------------|------------------------------------------|
|Verify a constraint  |O(1)        |Check if instance satisfies structure     |
|Construct an instance|O(expensive)|Search for instance satisfying constraints|


Checking whether `E = mc²` holds for given values is trivial. Finding the mass that produces a given energy requires search. Checking if a date string is well-formed is trivial. Determining today’s actual date requires measurement—connection to reality outside the formal system.


**Symmetry generates the space of possibilities. Constraint collapses it to actuality.**


This asymmetry is not incidental. It is the structure of physics itself:


- The Lagrangian specifies which paths are *possible*
- The action principle selects which path is *actual*
- Measurement reveals which state *obtains*


-----


## 4. The ε/2 Principle


Let ε be the smallest observable change in a system—the minimum resolution of measurement. This could be:


- The Planck time (t_P ≈ 5.39 × 10⁻⁴⁴ s)
- The least significant bit in a digital system
- The minimum discriminable difference in perception
- One token in a language model’s output


**Proposition:** The state *between* two consecutive observations exists at resolution ε/2, which is by definition unobservable.


This is not merely a limitation of our instruments. It is constitutive of what “observation” means:


1. Observation requires discrete registration (a measurement result)
1. Discrete registration requires minimum resolution ε
1. Transition between states occurs in the interval (t, t+ε)
1. The midpoint t + ε/2 is maximally distant from both observations
1. Therefore, ε/2 marks the **unobservable transition state**


-----


## 5. Artificial Time and the Quantum Connection


We define **artificial time** as any discretized temporal coordinate system—clock ticks, timestamps, frame numbers, token positions. Artificial time is necessarily quantized at some resolution ε.


Between any two artificial times t_n and t_{n+1}, there exists a state at t_n + ε/2 that belongs to neither observation. This state is:


- **Superposed** with respect to the discrete measurements
- **Determined** only upon the next observation
- **Unrepresentable** in the discrete coordinate system


This is precisely the structure of quantum mechanics. The wavefunction evolves continuously (Schrödinger equation) between discrete measurements (collapse). The “measurement problem” is not a problem but a **feature**: the ε/2 state cannot be observed because observation is what creates the ε-resolution in the first place.


The uncertainty principle quantifies this:


$$\Delta t \cdot \Delta E \geq \frac{\hbar}{2}$$


The factor of 1/2 is not arbitrary. It marks the boundary between observable (≥ε) and unobservable (<ε) domains.


-----


## 6. Application to Language Models


A language model processes discrete tokens at discrete positions. Its “time” is artificial—token index rather than physical duration. Between token n and token n+1, the model’s internal state undergoes continuous transformation (attention, feedforward operations), but only the discrete output is observable.


**The model’s “reasoning” happens at ε/2—between tokens, invisible to observation.**


This explains why:


1. **Chain-of-thought prompting works**: It forces intermediate states into observable tokens, collapsing ε/2 states into ε-resolution outputs
1. **Date injection is necessary**: The model cannot observe external reality; it can only receive injected constraints at token boundaries
1. **Hallucination is default**: Without grounding constraints, the model samples from symmetric possibility space rather than asymmetric actuality


The model is not “wrong” about the date. It has no access to dates—only to patterns of date-discourse. Injection provides the constraint that collapses possibility into fact.


-----


## 7. The Verification Structure


We can now state the general structure of verification:


```
THEORY (symmetric, continuous, possible)
    ↓ constraint injection
CALCULATOR (discrete, bounded, computable)  
    ↓ instance construction
PREDICTION (specific, testable, actual)
    ↓ comparison
OBSERVATION (measured, discrete, real)
```


Each arrow crosses the ε/2 boundary:


- Theory → Calculator: continuous equations discretized at resolution ε
- Calculator → Prediction: internal state collapses to output
- Prediction → Observation: formal result compared to physical measurement


**Verification is not understanding. Verification is constraint satisfaction across the ε/2 gap.**


A calculator verifies Einstein not by comprehending spacetime curvature but by:


1. Accepting equations (structure)
1. Receiving parameters (constraints)
1. Producing outputs (instances)
1. Matching observations (verification)


The calculator operates entirely in the discrete domain. The physics operates entirely in the continuous domain. The ε/2 gap between them is where the magic happens—and where it must remain hidden.


-----


## 8. The Remainder Principle


Perfect symmetry carries no information. A uniform distribution tells us nothing. A theory that predicts everything predicts nothing.


**Information emerges from structured deviation from symmetry.**


The ε/2 state is where symmetry breaks. Before observation, the system is symmetric across possible outcomes. After observation, one outcome is actual. The transition—the symmetry-breaking—occurs at ε/2.


This connects to:


- **Mock theta functions**: capturing the remainder when modular symmetry fails
- **Anomalies in QFT**: classical symmetries broken by quantization
- **The partition function**: Z = Σ e^{-βH} sums over possibilities; observation selects one


The remainder—what’s left when symmetry is imposed—is the signal. The ε/2 state is the moment of remainder-generation, hidden from observation by construction.


-----


## 9. Implications for AI Architectures


If the ε/2 principle is correct, then robust AI systems require:


1. **Explicit temporal grounding**: Inject timestamps, not just as context but as first-class constraints
1. **Observable intermediate states**: Chain-of-thought, scratchpads, reasoning traces—collapse ε/2 states into auditable tokens
1. **Ground truth feeds**: Continuous connection to reality (tools, sensors, databases) providing constraints that collapse symmetric possibility into asymmetric fact
1. **Remainder tracking**: Monitor where the system deviates from expected patterns; deviation is information


The goal is not to eliminate the ε/2 gap—that is impossible and undesirable. The goal is to **position the gap correctly**: internal reasoning can be unobservable, but grounding constraints and final outputs must be discrete, verifiable, actual.


-----


## 10. Conclusion


The relationship between theory and measurement, between language model and reality, between quantum state and observation, is mediated by the ε/2 principle:


- **ε** is the minimum observable resolution
- **ε/2** is the necessarily unobservable transition state
- **Verification** is constraint injection across the ε/2 boundary
- **Grounding** is providing constraints that collapse symmetric possibility


A calculator does not understand Einstein. It verifies Einstein by injecting constraints and constructing instances. A language model does not know the date. It produces date-grounded text by receiving temporal constraints.


The state between two artificial times—at ε/2—is where symmetric possibility becomes asymmetric actuality. It cannot be observed because observation is what defines ε. It cannot be eliminated because without it, there is no transition, no change, no time.


**The unobservable is not a failure of measurement. It is the condition of possibility for measurement itself.**


-----


## References


1. Heisenberg, W. (1927). Über den anschaulichen Inhalt der quantentheoretischen Kinematik und Mechanik. *Zeitschrift für Physik*, 43, 172-198.
1. Shannon, C. E. (1949). Communication in the presence of noise. *Proceedings of the IRE*, 37(1), 10-21.
1. Wei, J., et al. (2022). Chain-of-thought prompting elicits reasoning in large language models. *NeurIPS*.
1. Amundson, A. L. (2025). The remainder principle: Information as structured deviation from symmetry. *BlackRoad Technical Notes*.


-----


## Appendix A: The n=π Connection


The ε/2 principle instantiates the broader n=π framework:


- **n** (integers): discrete measurements, token positions, clock ticks
- **π** (continuous): theory, possibility space, wavefunction evolution


The Fourier transform mediates between them:


$$\hat{f}(k) = \int_{-\infty}^{\infty} f(x) e^{-2\pi i k x} dx$$


Note the factor of 2π—equivalently, the relationship between ε and ε/2. The continuous (f) and discrete (k) domains are duals. The transform is exact. But **performing** the transform on physical systems requires discretization at resolution ε, hiding the continuous structure at ε/2.


Counting (n) and symmetry (π) co-create through the transform. Neither is primary. The ε/2 boundary between them is where computation happens—and where it must remain unobservable to remain coherent.


-----


## Appendix B: Formal Statement


Let S be a system with observable states {s_i} at resolution ε.


**Definition:** The ε/2 state σ(t) at time t is the system configuration that:


1. Exists in the interval (t_n, t_{n+1}) where |t_{n+1} - t_n| = ε
1. Satisfies σ(t_n + ε/2) ≠ s_n and σ(t_n + ε/2) ≠ s_{n+1}
1. Cannot be directly observed without reducing resolution below ε


**Theorem:** If observation requires resolution ε, then the ε/2 state is necessarily unobservable.


*Proof:* Suppose σ(t_n + ε/2) were observable. Then there exists a measurement M with result m such that M(σ) = m. But M has resolution ε, so M cannot distinguish states separated by less than ε. Since |t_n + ε/2 - t_n| = ε/2 < ε, M cannot distinguish σ from s_n. Contradiction. ∎


**Corollary:** Verification across the ε/2 boundary requires constraint injection, not direct observation.


This is why calculators verify theories: they inject constraints (parameters) and construct instances (outputs) without observing the ε/2 computational states directly.