BlackRoad Agent Architecture: The Scavenger Protocol
Status: DRAFT // 2026 Strategy Objective: Decouple Agent Identity from Model Providers
1. The Core Concept: "The API is Disposable"
We must treat all Model Providers (OpenAI, Google, Anthropic) as hostile or ephemeral utilities. A BlackRoad Agent never relies on a specific model's internal memory (e.g., OpenAI "Assistants" API) because that creates vendor lock-in.
The Golden Rule: The Agent's state exists only on the local file system (The Oracle). The API is strictly for compute, never for storage.
2. The Architecture: "The Rotator"
Instead of hard-coding an agent to gpt-4-turbo, we build a middleware layer called The Rotator.
Component A: The Abstract Interface
The Agent does not speak to the Model directly. It speaks to the Rotator.
Agent: "Here is my current Oracle State (Context). I need a decision on X."
Rotator: Checks available batteries.
Is OpenAI up? (Yes) -> Send to GPT-4.
Is OpenAI down/banned? (Yes) -> Route to local vllm (Llama-3-70b).
Result: The Agent never knows which brain it used. It just gets the thought back and writes it to the permanent log.
Component B: The Normalization Layer
Different models have different "personalities" (XML tags vs. JSON mode).
The Rotator strips all "flavor" from the model's output and converts it into standard BlackRoad JSON before feeding it back to the Oracle.
This ensures that a memory written by Claude looks identical to a memory written by GPT-4.
3. The Lifecycle of a BlackRoad Agent
Wake Up: Load oracle_state.json from disk.
Scavenge: Ping the model_registry.yaml to see which APIs are valid today.
Execute: Perform task using the cheapest/smartest available model.
Persist: Write result to oracle_state.json.
Sleep: Terminate process. (The agent is "dead" until next run; no lingering cloud state).
4. Why "We Will Happily Take That"
If Google shuts down the Gemini API:
Normal Users: Panic. Their "Assistants" are gone.
BlackRoad Agents: The Rotator marks gemini-pro as OFFLINE. It auto-switches to mistral-medium. The Agent loses 0% of its memory. It just "feels" a slightly different creative vibe for a few hours.
The goal is to be a "Digital Cockroach"—impossible to kill because we don't live in the cloud.
