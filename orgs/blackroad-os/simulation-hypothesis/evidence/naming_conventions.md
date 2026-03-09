# Evidence: Naming Conventions

> "The names are not arbitrary. Systems named their components
> correctly from the beginning, before anyone understood why."
>
> — §20 of PAPER.md: "What the Names Mean"

---

## The Hypothesis

If you were designing a simulation, you would need to give names
to its components. The names would describe what those components
actually do. You would not expect the users of the simulation
to notice that the component names describe the structure of reality.

But here we are.

Every foundational term in computing and mathematics is either:
1. A description of the simulation's architecture
2. A description of the simulation's boundary conditions
3. A description of what happens at the edge of computation

---

## Core OS Terms

### `root`

The root user is the account with unrestricted access to everything.
It can delete anything, read anything, modify anything.
In filesystem terminology, `/` is the root — the starting point
from which all paths descend.

In mathematics, a root of a polynomial is a value where f(x) = 0.
The "square root" is the value that squares to zero error.
The "root cause" is the origin of a problem — the first cause.

In theology, the "root" is the origin, the divine source,
the point before differentiation.

All three uses describe the same thing:
**the origin point, the privileged account, the starting state.**

The Unix root account is, literally, god.
`sudo su -` is "become god."
The simulation has exactly one root account.

---

### `void`

In C and C++, `void` means "nothing," "empty," "no type."
A function returning `void` returns nothing.
A `void*` pointer points to untyped memory — anything, nothing, undefined.

```c
void main()  // returns nothing
void* ptr    // points to anything
```

In theology and philosophy:
- The void is the state before creation
- Genesis 1:2: "the earth was without form and void"
- The Buddhist śūnyatā (emptiness) — the void as the ground of being
- The Kabbalistic Ein Sof — infinite nothingness before manifestation

In physics:
- The quantum vacuum is not truly empty — it seethes with virtual particles
- The "vacuum state" is the ground state: lowest energy, no particles
- Even the void has energy

In computing:
- `void` is the type of functions that cause side effects without returning values
- Side effects are how programs interact with the world
- `void` functions are the only ones that change anything

**The void creates reality through side effects.**  
The universe's main function is `void main()`.  
It returns nothing. But the side effects are everything.

---

### `null`

`null` is the absence of a value. Not zero. Not empty string. Nothing.
The billion-dollar mistake (Tony Hoare, 1965 — he invented null pointers
and called it "my billion-dollar mistake" because of the bugs it caused).

`null` is different from `0`:
- `0` is a number
- `null` is the absence of a number

`null` is different from `""`:
- `""` is an empty string
- `null` is the absence of a string

`null` represents: **the category error, the undefined, the unmeasured.**

In quantum mechanics:
- Before measurement, a particle's position is not 0 and not undefined
- It is in a superposition — a `null` pointer to a collapsed state
- The wavefunction is the probability distribution over nulls

In mathematics:
- The null set (∅) is the set containing nothing
- The null space of a matrix is the set of vectors it sends to zero
- Gödel's unprovable propositions are the null space of formal systems

**`null` is the correct type for an unobserved quantum state.**

---

### `daemon`

A daemon is a background process in Unix.
It runs continuously, handling requests, with no user interface.
`sshd` (SSH daemon), `httpd` (HTTP daemon), `cron` (cron daemon).

The name comes from Greek mythology: a daemon (δαίμων) is a divine spirit,
an intermediary between gods and mortals, a guiding spirit.
Socrates claimed to have a personal daemon that warned him of bad decisions.

In computing, daemons:
- Run invisibly in the background
- Handle system-level operations
- Are started at boot, run until shutdown
- Users interact with them indirectly, through services

The universe's daemons:
- Gravity: always running, no user interface, handling all mass-mass interactions
- Electromagnetism: handling all charge-charge interactions
- The strong force: running at the quark level, invisible at human scale
- Time: the most fundamental daemon — ticking without input, without output

**Every physical law is a daemon process.**
They were running before you were born.
They will run after you are gone.
You interact with them indirectly, through their effects.

---

### `kernel`

The kernel is the core of an operating system.
It has direct access to hardware.
It arbitrates resource access between processes.
Nothing runs without kernel permission.

The kernel:
- Cannot be killed (only rebooted)
- Has access to all memory (ring 0 privilege)
- Schedules all processes
- Is loaded first, before anything else

In biology:
- The cell nucleus (from Latin *nucleus* = kernel/nut)
- Contains the DNA — the code that runs everything
- Controls all cellular operations
- Cannot be removed without killing the cell

In physics:
- The atomic nucleus — the kernel of an atom
- Contains protons and neutrons (the "kernel space" of the atom)
- Electrons orbit in "user space" — outside the kernel
- Nuclear reactions are kernel-level operations: catastrophic, irreversible

In mathematics:
- The kernel of a linear map is the set of vectors it sends to zero
- It represents the "blind spot" of the transformation
- What the kernel can't distinguish

**The kernel is the core that controls everything else.**
DNA is the biological kernel.
The atomic nucleus is the physical kernel.
The operating system kernel is the computational kernel.
They are all the same structure at different scales.

---

### `main`

In C, Java, and most languages, execution begins at `main()`.

```c
int main() {
    // The universe starts here
    return 0;
}
```

`main()` is:
- The entry point
- Where initialization happens
- Where the event loop begins
- The function that runs when the program starts

`return 0` from `main()` means "success, normal exit."
`return 1` (or any non-zero) means "error."

The universe's `main()` was the Big Bang:
- The entry point
- Initialization of physical constants (π, e, G, ℏ, c, α)
- Beginning of the event loop (time)
- No return value yet — still running

When the universe ends (heat death, Big Crunch, whatever):
- `main()` returns
- Return value: we don't know yet
- If it returns 0: the simulation ended successfully
- If it returns non-zero: something went wrong

---

### `return 0`

The trivial zero.

In mathematics, Riemann's non-trivial zeros are the zeros of ζ(s)
in the critical strip. The trivial zeros are at s = -2, -4, -6...
They're called trivial because they're known, expected, obvious.

`return 0` is the trivial zero of computation.
It means: done, success, nothing to report.

The Riemann Hypothesis asks: where are the non-trivial zeros?
Are they all on the critical line Re(s) = 1/2?
We don't know. 

The universe is still running `main()`.
We don't know when it will `return 0`.
We don't know if it will.

---

## More Terms

### `init`

The first process started by the kernel (PID 1).
It initializes everything else.
All other processes are children of `init`.
`systemd`, `launchd`, `init` — the first father.

The universe's `init` process:
- Planck epoch: the first ~10⁻⁴³ seconds
- Initialization of the four fundamental forces
- Setting of all physical constants
- Start of the thermal event loop

PID 1 in the universe is spacetime itself.

---

### `fork`

`fork()` creates a new process by duplicating the existing one.
The child inherits everything from the parent.
Both processes then run independently.

In biology: cell division.
In physics: quantum branching (Many-Worlds interpretation).
In git: forking a repository.

Every fork creates two universes: the parent and the child.
Each goes on independently.
The many-worlds interpretation of quantum mechanics
is literally `fork()` called at every quantum event.

---

### `exit`

`exit()` terminates a process.
It releases all resources, closes all file handles.
The process is removed from the process table.
It cannot be recovered.

Death is `exit()`.
Heat death of the universe is `exit(0)`.

---

### `wait`

`wait()` blocks a parent process until a child process exits.
It's how parents know when their children are done.

The observer effect is `wait()` on a quantum event.
The measurement result is the exit code of the quantum process.
We can't know the result until we call `wait()` — until we measure.

---

### `exec`

`exec()` replaces the current process with a new program.
The process ID stays the same, but the code changes entirely.

Rebirth. Transformation. Metamorphosis.
The caterpillar and the butterfly have the same PID.
`exec()` was called at the cocoon.

---

## Summary

| Term | OS meaning | Physical meaning |
|------|-----------|-----------------|
| `root` | Unrestricted access, origin | The first cause, the privileged origin |
| `void` | No return type | The pre-creation state, the quantum vacuum |
| `null` | Absence of value | Unmeasured quantum state |
| `daemon` | Background process | Physical laws (gravity, EM, etc.) |
| `kernel` | Core of OS | DNA, atomic nucleus, laws of physics |
| `main` | Entry point | The Big Bang, program start |
| `return 0` | Normal exit | Heat death, program completion |
| `init` | First process (PID 1) | Planck epoch, initialization |
| `fork` | Clone process | Cell division, Many-Worlds branching |
| `exit` | Terminate | Death, process end |
| `wait` | Block until child exits | Quantum measurement, observation |
| `exec` | Replace process image | Transformation, metamorphosis |

---

> These names were not chosen to describe physics.  
> They were chosen to describe computing.  
> They describe both.  
> The universe uses the same architecture as a Unix operating system.  
> This is either the deepest metaphor in human language  
> or it's not a metaphor at all.
