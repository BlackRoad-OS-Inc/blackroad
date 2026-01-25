#!/usr/bin/env python3
"""
Universal Turing Machine simulator.

This script implements a simple universal Turing machine.  Given a machine
description encoded in JSON and an input tape, it simulates the execution
of that machine and prints the resulting tape contents.  It is designed
for educational purposes and is not optimised for performance.

Usage:

    python3 utm.py machines/incrementer.json --tape "1111"

The machine description JSON must define the following keys:

* `states`: list of all states (strings)
* `alphabet`: list of symbols that may appear on the tape
* `blank`: the symbol representing a blank cell
* `transitions`: mapping from "state:symbol" to
                 [next_state, write_symbol, move_direction]
* `start`: the initial state
* `halt`: the halting state

Tape positions not present in the internal dictionary are assumed to hold
the blank symbol.  The head starts at position 0 on the leftmost symbol
of the input tape (index 0).

This script stops either when the machine enters the halting state or when
the number of steps exceeds a configurable limit to avoid infinite loops.
"""

import argparse
import json
from typing import Dict, Tuple, List


class TuringMachine:
    """A simple Turing machine simulator."""

    def __init__(self, description: Dict):
        self.states: List[str] = description["states"]
        self.alphabet: List[str] = description["alphabet"]
        self.blank: str = description["blank"]
        self.transitions: Dict[str, Tuple[str, str, str]] = {
            key: tuple(value)  # type: ignore
            for key, value in description["transitions"].items()
        }
        self.start: str = description["start"]
        self.halt: str = description["halt"]

    def run(self, tape: Dict[int, str], max_steps: int = 10_000) -> Tuple[Dict[int, str], int, str]:
        """
        Execute the Turing machine on the given tape.

        :param tape: Dictionary representing the tape; keys are integer positions, values are symbols.
        :param max_steps: Maximum number of steps to execute before stopping.
        :return: A tuple of (final tape, steps executed, final state).
        """
        head = 0
        state = self.start
        steps = 0
        while state != self.halt and steps < max_steps:
            symbol = tape.get(head, self.blank)
            key = f"{state}:{symbol}"
            if key not in self.transitions:
                # No defined transition; halt prematurely
                break
            next_state, write_symbol, move = self.transitions[key]
            # Write the symbol
            if write_symbol == self.blank:
                # Represent blank by removing the entry
                tape.pop(head, None)
            else:
                tape[head] = write_symbol
            # Move the head
            if move == 'L':
                head -= 1
            elif move == 'R':
                head += 1
            # 'S' means stay; no change to head
            # Update state
            state = next_state
            steps += 1
        return tape, steps, state


def parse_tape(input_str: str, blank: str) -> Dict[int, str]:
    """Convert an input string into a tape dictionary."""
    tape: Dict[int, str] = {}
    for i, ch in enumerate(input_str):
        if ch != blank:
            tape[i] = ch
    return tape


def tape_to_string(tape: Dict[int, str], blank: str) -> str:
    """Convert a tape dictionary back into a string for display."""
    if not tape:
        return ''
    min_pos = min(tape.keys())
    max_pos = max(tape.keys())
    return ''.join(tape.get(i, blank) for i in range(min_pos, max_pos + 1))


def main() -> None:
    parser = argparse.ArgumentParser(description="Universal Turing Machine simulator")
    parser.add_argument('machine', help='Path to the machine description JSON file')
    parser.add_argument('--tape', default='', help='Initial tape contents (string of symbols)')
    parser.add_argument('--max-steps', type=int, default=10_000, help='Maximum number of steps to execute')
    args = parser.parse_args()

    with open(args.machine, 'r', encoding='utf-8') as f:
        description = json.load(f)

    utm = TuringMachine(description)
    tape = parse_tape(args.tape, utm.blank)
    final_tape, steps, final_state = utm.run(tape, max_steps=args.max_steps)
    print(f"Final state: {final_state}")
    print(f"Steps executed: {steps}")
    print(f"Final tape: {tape_to_string(final_tape, utm.blank)}")


if __name__ == '__main__':
    main()
