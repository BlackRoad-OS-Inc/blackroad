"""
darwin_kernel.py — Evolution as Operating System

$ uname -s
Darwin

The macOS kernel is named Darwin.
Charles Darwin proved complex systems emerge from simple rules iterated over time.
Apple named their kernel after him.

Natural selection and machine learning are the same algorithm.
The filesystem timestamps are the geological record.
Deprecated formulas are extinct species.
"""

import math
import random
import hashlib


# ── The Selection Algorithm ───────────────────────────────────────────────────
# Natural selection:
#   1. Population of variants
#   2. Fitness function applied to each
#   3. Select top performers
#   4. Mutate and reproduce
#   5. Repeat
#
# Gradient descent (machine learning):
#   1. Population of weights
#   2. Loss function applied to each
#   3. Select direction of improvement
#   4. Update weights (mutation rate = learning rate)
#   5. Repeat
#
# They are the same algorithm.

def selection_step(population, fitness_fn, mutation_rate=0.1, top_k=0.2):
    """One generation of selection."""
    scored = [(x, fitness_fn(x)) for x in population]
    scored.sort(key=lambda t: t[1], reverse=True)
    n_keep = max(1, int(len(population) * top_k))
    survivors = [x for x, _ in scored[:n_keep]]

    # Reproduce with mutation
    next_gen = list(survivors)
    while len(next_gen) < len(population):
        parent = random.choice(survivors)
        mutant = parent + random.gauss(0, mutation_rate)
        next_gen.append(mutant)
    return next_gen

def evolve(target, generations=50, pop_size=100):
    """Evolve a population toward a target value."""
    population = [random.uniform(target - 10, target + 10) for _ in range(pop_size)]
    fitness = lambda x: -abs(x - target)  # closer = fitter

    history = []
    for gen in range(generations):
        best = max(population, key=fitness)
        history.append((gen, best, abs(best - target)))
        population = selection_step(population, fitness, mutation_rate=max(0.01, 1.0 / (gen + 1)))

    return history


# ── The Filesystem as Fossil Record ───────────────────────────────────────────
# Darwin kernel timestamps = geological layers
# Each timestamp marks when that "species" (directory/system) was created or modified

FILESYSTEM_RECORD = [
    {"date": "Oct 28, 2022",  "entry": "cores, mnt, sw",        "epoch": "Foundation",   "analogy": "First cellular life"},
    {"date": "Nov 18, 2022",  "entry": ".Spotlight-V100",        "epoch": "Search",       "analogy": "First sensory organs"},
    {"date": "Nov 26, 2023",  "entry": "MobileSoftwareUpdate",   "epoch": "Mobility",     "analogy": "First locomotion"},
    {"date": "May  7, 2024",  "entry": "System, usr",            "epoch": "Sealed system","analogy": "Exoskeleton, hard shell"},
    {"date": "Dec 13, 2024",  "entry": "Library",                "epoch": "Knowledge",    "analogy": "Nervous system"},
    {"date": "Jan 17, 2025",  "entry": ".",                      "epoch": "Root modified","analogy": "Self-modification, mutation"},
    {"date": "Feb 17, 2026",  "entry": "Users, opt",             "epoch": "Inhabitants",  "analogy": "Multicellular life, tools"},
    {"date": "Feb 21, 2026",  "entry": "blackroad, home",        "epoch": "Identity",     "analogy": "Self-aware species, naming"},
]

def fossil_record():
    """Print the filesystem as geological strata."""
    print("DARWIN KERNEL — FOSSIL RECORD")
    print("─" * 65)
    print(f"{'Date':<18} {'Entry':<28} {'Geological Analogy'}")
    print("─" * 65)
    for layer in FILESYSTEM_RECORD:
        print(f"{layer['date']:<18} {layer['entry']:<28} {layer['analogy']}")
    print("─" * 65)
    print(f"\nKernel: Darwin {get_darwin_version()}")
    print("All timestamps produced by a kernel named after the man")
    print("who described how complexity emerges from iterated selection.")


def get_darwin_version():
    """Darwin version is the macOS kernel version."""
    # macOS Sonoma = Darwin 23.x
    # macOS Ventura = Darwin 22.x
    # The filesystem entry for '..' dated May 7, 2024 = Darwin 23.x
    import platform
    try:
        return platform.release()
    except:
        return "23.x (Sonoma)"


# ── The Deprecation as Extinction ─────────────────────────────────────────────
# brew formula deprecations = species extinction
# Every deprecated formula in Homebrew is a species that failed selection pressure

DEPRECATED_SPECIES = [
    ("earthly", "deprecated", "Failed to maintain fitness"),
    ("blackbox", "deprecated", "Superseded by more fit variant"),
    ("authy",    "deprecated", "Authentication model replaced"),
    ("codeexpander", "deprecated", "Outcompeted"),
    ("dosbox-x-app", "deprecated", "Architecture obsolete"),
    ("pext",     "deprecated", "Niche too small to survive"),
]

# Successful species (installed)
SUCCESSFUL_SPECIES = [
    ("go",       "1.26.0",  "Fitness: systems programming, concurrency"),
    ("codex",    "0.104.0", "Fitness: code assistance, upgrade path exists"),
    ("cursor",   "latest",  "Fitness: AI-native IDE, linked as 'code'"),
]


# ── The Kernel as Algorithm ───────────────────────────────────────────────────
DARWIN_AS_ALGORITHM = """
Natural Selection             Darwin Kernel
─────────────────────────     ─────────────────────────
Population of organisms       Process pool
Fitness function              CPU scheduler
Mutation                      System calls
Reproduction                  fork() / spawn()
Selection pressure            Memory limits / OOM killer
Extinction                    SIGKILL / deprecation
Speciation                    Container isolation
Fossil record                 Filesystem timestamps
Observer                      Spotlight / fs_events
Environment                   Hardware abstraction layer

The kernel runs the same algorithm Darwin described.
The algorithm was always there.
Darwin named it. Apple named the kernel after Darwin.
$ uname -s → Darwin.
"""


# ── DNA as Source File ────────────────────────────────────────────────────────
# DNA is the source file for biological organisms.
# The genome is the source code. The cell is the runtime. Evolution is the compiler.
# Mutations are commits. Selection is the test suite. Extinction is a failed build.

def genome_as_version_control():
    return {
        "genome":     "Source code",
        "mutation":   "Diff / commit",
        "selection":  "Test suite (fitness function)",
        "generation": "Release cycle",
        "speciation": "Fork",
        "extinction": "Branch deleted / deprecated",
        "evolution":  "CI/CD pipeline running for 3.8 billion years",
        "kernel":     "Darwin",
    }


if __name__ == "__main__":
    print("═" * 65)
    print("DARWIN — EVOLUTION AS OPERATING SYSTEM")
    print("═" * 65)

    fossil_record()

    print("\n" + DARWIN_AS_ALGORITHM)

    print("EVOLUTION SIMULATION (finding π):")
    print("─" * 40)
    history = evolve(math.pi, generations=30, pop_size=200)
    for gen, best, error in history[::5]:
        bar = "█" * int(20 - error * 5) if error < 4 else ""
        print(f"  Gen {gen:3d}: best={best:.6f}  error={error:.6f}  {bar}")

    print("\nVERSION CONTROL MODEL:")
    vc = genome_as_version_control()
    for k, v in vc.items():
        print(f"  {k:<12} = {v}")

    print(f"\n$ uname -s")
    print(f"Darwin")
    print(f"\nAll of the above, in one word.")
