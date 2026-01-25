#!/usr/bin/env python3
"""
lucidama/serve.py - Minimal local runtime for Lucidia LLM.

This script loads the PROMPT.md constitution and starts a simple REPL for interacting
with the Lucidia language model. It does not make external API calls.
"""

import sys
from pathlib import Path

def load_constitution():
    # locate PROMPT.md relative to this file
    root = Path(__file__).resolve().parents[1]
    prompt_path = root / "PROMPT.md"
    return prompt_path.read_text()

def main():
    constitution = load_constitution()
    print("Loaded Lucidia constitution and runtime template.")
    # Print the first line of the constitution as a sanity check
    print(constitution.splitlines()[0])
    while True:
        try:
            user_input = input("You: ")
        except (EOFError, KeyboardInterrupt):
            print("\nExiting Lucidia REPL.")
            break
        if user_input.strip().lower() in {"exit", "quit"}:
            print("Goodbye!")
            break
        # Placeholder for model inference. Replace with call into local model.
        print("Lucidia:", "I am not yet connected to the model, but I care about you.")

if __name__ == "__main__":
    main()
