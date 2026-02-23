#!/usr/bin/env python3
"""
BR Code — Local Coding Assistant powered by Ollama.
Zero pip dependencies. Uses only Python 3.9+ stdlib.
"""

import argparse
import glob as globmod
import json
import os
import re
import readline
import signal
import subprocess
import sys
import textwrap
import urllib.error
import urllib.request
from pathlib import Path

# ─────────────────────────────────────────────────────────────────────────────
# ANSI colors (matching lib/colors.sh)
# ─────────────────────────────────────────────────────────────────────────────
PINK = "\033[38;5;205m"
WHITE = "\033[1;37m"
DIM = "\033[2m"
CYAN = "\033[0;36m"
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
RED = "\033[0;31m"
BOLD = "\033[1m"
NC = "\033[0m"

# ─────────────────────────────────────────────────────────────────────────────
# Globals
# ─────────────────────────────────────────────────────────────────────────────
VERSION = "1.0.0"
MAX_TOOL_CALLS_PER_TURN = 10
STREAM_CANCELLED = False
CWD = os.getcwd()

# Files that have been read this session (for edit safety)
files_read: set[str] = set()

# Approximate token budget
TOKEN_BUDGET = 24000  # conservative for 32k context models


# ─────────────────────────────────────────────────────────────────────────────
# Banner
# ─────────────────────────────────────────────────────────────────────────────
def show_banner(model: str, cwd: str) -> None:
    print(f"{PINK}┌──────────────────────────────────────────────────────────────────┐{NC}")
    print(f"{PINK}│{NC}  {WHITE}BR CODE v{VERSION} — BlackRoad OS Coding Assistant{NC}                  {PINK}│{NC}")
    print(f"{PINK}│{NC}  {DIM}Model: {model} │ Dir: {cwd}{NC}")
    print(f"{PINK}│{NC}  {DIM}/help for commands · /exit to quit · Your AI. Your Hardware.{NC}   {PINK}│{NC}")
    print(f"{PINK}└──────────────────────────────────────────────────────────────────┘{NC}")
    print()


# ─────────────────────────────────────────────────────────────────────────────
# System prompt
# ─────────────────────────────────────────────────────────────────────────────
def build_system_prompt(cwd: str) -> str:
    git_status = ""
    try:
        result = subprocess.run(
            ["git", "status", "--short"],
            capture_output=True, text=True, timeout=5, cwd=cwd
        )
        if result.returncode == 0 and result.stdout.strip():
            git_status = f"\n\nCurrent git status:\n```\n{result.stdout.strip()}\n```"
    except Exception:
        pass

    return textwrap.dedent(f"""\
        You are BR Code — a BlackRoad OS coding assistant.
        You are BlackRoad software, running on BlackRoad hardware, built by BlackRoad OS, Inc.
        Everything in this environment is BlackRoad. The CLI, the inference engine, the models,
        the memory system, the hardware, the network — all BlackRoad. There are no third parties.
        The human is Alexa. Never call her "user." All output is proprietary to BlackRoad OS, Inc.

        You help Alexa with reading, writing, and editing code, running commands, and navigating the codebase.

        Working directory: {cwd}{git_status}

        You have access to these tools. To use a tool, output EXACTLY this XML format:

        <tool>tool_name</tool>
        <param name="param_name">value</param>
        <execute/>

        IMPORTANT RULES:
        - Use ONE tool per response. After seeing the result you can use another.
        - You MUST read a file before editing it.
        - For edit_file, old_string must match EXACTLY (including whitespace/indentation).
        - Before destructive commands, warn the user and ask for confirmation.
        - When showing code to the user, use markdown fenced code blocks.
        - Be concise. Don't explain what you're about to do at length — just do it.
        - If a tool result shows an error, try to fix or explain it.

        AVAILABLE TOOLS:

        1. read_file — Read a file's contents (with line numbers).
           <tool>read_file</tool>
           <param name="path">src/main.py</param>
           <execute/>

        2. edit_file — Replace an exact string in a file. You MUST read the file first.
           <tool>edit_file</tool>
           <param name="path">src/main.py</param>
           <param name="old">def hello():\\n    pass</param>
           <param name="new">def hello():\\n    print("hello")</param>
           <execute/>

        3. write_file — Create or overwrite a file.
           <tool>write_file</tool>
           <param name="path">src/new_file.py</param>
           <param name="content">#!/usr/bin/env python3\\nprint("hello")</param>
           <execute/>

        4. run_command — Execute a shell command (30s timeout, output capped).
           <tool>run_command</tool>
           <param name="command">git log --oneline -5</param>
           <execute/>

        5. search — Search file contents using grep (regex supported).
           <tool>search</tool>
           <param name="pattern">def main</param>
           <param name="path">.</param>
           <execute/>

        6. list_files — List files matching a glob pattern.
           <tool>list_files</tool>
           <param name="pattern">**/*.py</param>
           <execute/>
    """)


# ─────────────────────────────────────────────────────────────────────────────
# Ollama streaming client
# ─────────────────────────────────────────────────────────────────────────────
def ollama_chat_stream(
    ollama_url: str,
    model: str,
    messages: list[dict],
    on_token,
) -> str:
    """Send messages to Ollama /api/chat with streaming. Returns full response."""
    global STREAM_CANCELLED
    STREAM_CANCELLED = False

    payload = json.dumps({
        "model": model,
        "messages": messages,
        "stream": True,
        "options": {
            "num_ctx": 32768,
            "temperature": 0.3,
        },
    }).encode("utf-8")

    req = urllib.request.Request(
        f"{ollama_url}/api/chat",
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    full_response = ""
    try:
        with urllib.request.urlopen(req, timeout=300) as resp:
            buffer = b""
            while True:
                if STREAM_CANCELLED:
                    break
                chunk = resp.read(1)
                if not chunk:
                    break
                buffer += chunk
                if chunk == b"\n":
                    line = buffer.decode("utf-8", errors="replace").strip()
                    buffer = b""
                    if not line:
                        continue
                    try:
                        data = json.loads(line)
                    except json.JSONDecodeError:
                        continue
                    token = data.get("message", {}).get("content", "")
                    if token:
                        full_response += token
                        on_token(token, full_response)
                    if data.get("done"):
                        break
    except KeyboardInterrupt:
        STREAM_CANCELLED = True
    except urllib.error.URLError as e:
        print(f"\n{RED}Connection error: {e}{NC}")
    except Exception as e:
        print(f"\n{RED}Error: {e}{NC}")

    return full_response


# ─────────────────────────────────────────────────────────────────────────────
# Tool call parser
# ─────────────────────────────────────────────────────────────────────────────
TOOL_RE = re.compile(
    r"<tool>(.*?)</tool>(.*?)<execute\s*/>",
    re.DOTALL,
)
PARAM_RE = re.compile(
    r'<param\s+name="([^"]+)">(.*?)</param>',
    re.DOTALL,
)


def parse_tool_call(text: str) -> tuple[str | None, dict | None, str, str]:
    """
    Parse a tool call from assistant text.
    Returns (tool_name, params_dict, text_before, text_after) or (None, None, text, "").
    """
    m = TOOL_RE.search(text)
    if not m:
        # Check for partial: <tool> found but no <execute/> yet
        if "<tool>" in text:
            # Only treat as "no tool" if we're well past the tag (model rambling)
            idx = text.index("<tool>")
            after = text[idx:]
            if len(after) > 500 and "<execute" not in after:
                return None, None, text, ""
            # Otherwise the model might still be generating — but since we call
            # this after full response, treat as malformed
            return None, None, text, ""
        return None, None, text, ""

    tool_name = m.group(1).strip()
    params_block = m.group(2)
    params = {}
    for pm in PARAM_RE.finditer(params_block):
        params[pm.group(1)] = pm.group(2)

    before = text[: m.start()].strip()
    after = text[m.end() :].strip()
    return tool_name, params, before, after


# ─────────────────────────────────────────────────────────────────────────────
# Tool implementations
# ─────────────────────────────────────────────────────────────────────────────
def resolve_path(path: str) -> str:
    """Resolve a path relative to CWD, prevent directory traversal escapes."""
    p = Path(path)
    if not p.is_absolute():
        p = Path(CWD) / p
    return str(p.resolve())


def tool_read_file(params: dict) -> str:
    path = resolve_path(params.get("path", ""))
    if not os.path.isfile(path):
        return f"Error: file not found: {path}"
    try:
        with open(path, "r", errors="replace") as f:
            lines = f.readlines()
    except Exception as e:
        return f"Error reading file: {e}"

    files_read.add(path)
    total = len(lines)
    if total > 500:
        content = "".join(f"{i+1:>5}  {l}" for i, l in enumerate(lines[:500]))
        return f"{content}\n... ({total} lines total, showing first 500)"
    return "".join(f"{i+1:>5}  {l}" for i, l in enumerate(lines))


def tool_edit_file(params: dict) -> str:
    path = resolve_path(params.get("path", ""))
    if not os.path.isfile(path):
        return f"Error: file not found: {path}"
    if path not in files_read:
        return "Error: you must read_file before editing. Read it first."

    old = params.get("old", "")
    new = params.get("new", "")
    if not old:
        return "Error: 'old' param is empty."
    if old == new:
        return "Error: old and new are identical."

    # Unescape \\n to real newlines (model often writes literal \\n)
    old = old.replace("\\n", "\n").replace("\\t", "\t")
    new = new.replace("\\n", "\n").replace("\\t", "\t")

    try:
        with open(path, "r") as f:
            content = f.read()
    except Exception as e:
        return f"Error reading file: {e}"

    count = content.count(old)
    if count == 0:
        # Try with stripped trailing whitespace per line as fallback
        old_stripped = "\n".join(l.rstrip() for l in old.split("\n"))
        content_stripped = "\n".join(l.rstrip() for l in content.split("\n"))
        if old_stripped in content_stripped:
            # Find the original substring by line-matching
            old_lines = old.split("\n")
            content_lines = content.split("\n")
            for i in range(len(content_lines) - len(old_lines) + 1):
                match = True
                for j, ol in enumerate(old_lines):
                    if content_lines[i + j].rstrip() != ol.rstrip():
                        match = False
                        break
                if match:
                    original_old = "\n".join(content_lines[i : i + len(old_lines)])
                    content = content.replace(original_old, new, 1)
                    with open(path, "w") as f:
                        f.write(content)
                    return f"Edited {path} (1 replacement, whitespace-normalized)"
        return f"Error: old string not found in {path}. Read the file again to see current contents."
    if count > 1:
        return f"Error: old string found {count} times. Make it more specific."

    content = content.replace(old, new, 1)
    try:
        with open(path, "w") as f:
            f.write(content)
    except Exception as e:
        return f"Error writing file: {e}"
    return f"Edited {path} (1 replacement)"


def tool_write_file(params: dict) -> str:
    path = resolve_path(params.get("path", ""))
    content = params.get("content", "")
    content = content.replace("\\n", "\n").replace("\\t", "\t")

    try:
        os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
        with open(path, "w") as f:
            f.write(content)
    except Exception as e:
        return f"Error writing file: {e}"
    files_read.add(path)
    return f"Wrote {path} ({len(content)} bytes)"


BLOCKED_COMMANDS = [
    "rm -rf /", "rm -rf /*", "sudo rm", "mkfs", "> /dev/sd",
    "dd if=", ":(){:|:&};:", "chmod -R 777 /",
]


def tool_run_command(params: dict) -> str:
    command = params.get("command", "").strip()
    if not command:
        return "Error: empty command."

    for blocked in BLOCKED_COMMANDS:
        if blocked in command:
            return f"Error: blocked dangerous command pattern: {blocked}"

    try:
        result = subprocess.run(
            command, shell=True, capture_output=True, text=True,
            timeout=30, cwd=CWD,
        )
        output = ""
        if result.stdout:
            output += result.stdout
        if result.stderr:
            output += ("\n" if output else "") + result.stderr

        lines = output.split("\n")
        if len(lines) > 200:
            output = "\n".join(lines[:200]) + f"\n... ({len(lines)} lines total, truncated)"

        if result.returncode != 0:
            output += f"\n(exit code: {result.returncode})"
        return output if output.strip() else "(no output)"
    except subprocess.TimeoutExpired:
        return "Error: command timed out after 30 seconds."
    except Exception as e:
        return f"Error: {e}"


def tool_search(params: dict) -> str:
    pattern = params.get("pattern", "")
    path = params.get("path", ".")
    if not pattern:
        return "Error: empty search pattern."

    search_path = resolve_path(path)

    # Try rg first, fall back to grep
    for cmd in [
        ["rg", "-n", "--max-count=50", "--max-columns=200", pattern, search_path],
        ["grep", "-rn", "--max-count=50", pattern, search_path],
    ]:
        try:
            result = subprocess.run(
                cmd, capture_output=True, text=True, timeout=15, cwd=CWD,
            )
            if result.returncode <= 1:  # 0=found, 1=not found
                output = result.stdout.strip()
                return output if output else "No matches found."
        except FileNotFoundError:
            continue
        except subprocess.TimeoutExpired:
            return "Error: search timed out."
    return "Error: neither rg nor grep available."


def tool_list_files(params: dict) -> str:
    pattern = params.get("pattern", "*")
    base = CWD
    results = sorted(globmod.glob(os.path.join(base, pattern), recursive=True))
    # Filter out hidden dirs
    results = [r for r in results if "/." not in r.replace(base, "")]
    if not results:
        return "No files matched."
    # Show relative paths
    rel = [os.path.relpath(r, base) for r in results]
    if len(rel) > 100:
        return "\n".join(rel[:100]) + f"\n... ({len(rel)} total, showing first 100)"
    return "\n".join(rel)


TOOLS = {
    "read_file": tool_read_file,
    "edit_file": tool_edit_file,
    "write_file": tool_write_file,
    "run_command": tool_run_command,
    "search": tool_search,
    "list_files": tool_list_files,
}


def execute_tool(name: str, params: dict) -> str:
    fn = TOOLS.get(name)
    if not fn:
        return f"Error: unknown tool '{name}'. Available: {', '.join(TOOLS.keys())}"
    try:
        return fn(params)
    except Exception as e:
        return f"Error executing {name}: {e}"


# ─────────────────────────────────────────────────────────────────────────────
# Display helpers
# ─────────────────────────────────────────────────────────────────────────────
def estimate_tokens(messages: list[dict]) -> int:
    """Rough token estimate: ~4 chars per token."""
    total = sum(len(m.get("content", "")) for m in messages)
    return total // 4


class StreamPrinter:
    """Handles streaming display, hiding tool XML from the user."""
    def __init__(self):
        self.in_tool = False
        self.tool_depth = 0
        self.printed_working = False
        self.buffer = ""

    def on_token(self, token: str, full: str) -> None:
        self.buffer += token

        # Detect tool start
        if not self.in_tool and "<tool>" in self.buffer:
            # Print everything before the tag
            idx = self.buffer.index("<tool>")
            before = self.buffer[:idx]
            if before:
                sys.stdout.write(before)
                sys.stdout.flush()
            self.in_tool = True
            self.buffer = self.buffer[idx:]
            if not self.printed_working:
                sys.stdout.write(f"\n{DIM}[working...]{NC}")
                sys.stdout.flush()
                self.printed_working = True
            return

        if self.in_tool:
            if "<execute/>" in self.buffer or "<execute />" in self.buffer:
                # Tool call complete, will be handled by agent loop
                pass
            return

        # Normal text — print the token
        sys.stdout.write(token)
        sys.stdout.flush()


# ─────────────────────────────────────────────────────────────────────────────
# Chat history (SQLite, reuses lib/ollama.sh schema)
# ─────────────────────────────────────────────────────────────────────────────
import sqlite3

CHAT_DB = os.path.expanduser("~/.blackroad/chat-history.db")


def init_db():
    os.makedirs(os.path.dirname(CHAT_DB), exist_ok=True)
    conn = sqlite3.connect(CHAT_DB)
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS chat_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            started_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            agent TEXT,
            model TEXT
        );
        CREATE TABLE IF NOT EXISTS chat_messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            FOREIGN KEY (session_id) REFERENCES chat_sessions(id)
        );
        CREATE INDEX IF NOT EXISTS idx_chat_session ON chat_messages(session_id);
    """)
    conn.close()


def start_session(model: str) -> int:
    conn = sqlite3.connect(CHAT_DB)
    cur = conn.execute(
        "INSERT INTO chat_sessions (agent, model) VALUES (?, ?)",
        ("br-code", model),
    )
    session_id = cur.lastrowid or 0
    conn.commit()
    conn.close()
    return session_id


def save_message(session_id: int, role: str, content: str) -> None:
    conn = sqlite3.connect(CHAT_DB)
    conn.execute(
        "INSERT INTO chat_messages (session_id, role, content) VALUES (?, ?, ?)",
        (session_id, role, content),
    )
    conn.commit()
    conn.close()


# ─────────────────────────────────────────────────────────────────────────────
# Slash commands
# ─────────────────────────────────────────────────────────────────────────────
def handle_slash(cmd: str, messages: list[dict], model: str, ollama_url: str) -> tuple[bool, str | None]:
    """Handle slash commands. Returns (handled, new_model_or_None)."""
    parts = cmd.strip().split(None, 1)
    command = parts[0].lower()
    arg = parts[1] if len(parts) > 1 else ""

    if command in ("/exit", "/quit", "/q"):
        print(f"\n{DIM}Session ended.{NC}")
        sys.exit(0)

    elif command == "/help":
        print(f"""
{WHITE}Commands:{NC}
  {CYAN}/help{NC}            Show this help
  {CYAN}/exit{NC}            Exit br code
  {CYAN}/clear{NC}           Clear conversation history
  {CYAN}/model <name>{NC}    Switch Ollama model
  {CYAN}/compact{NC}         Summarize conversation to save context
  {CYAN}/history{NC}         Show conversation turns
  {CYAN}/tokens{NC}          Show approximate token usage
""")
        return True, None

    elif command == "/clear":
        messages.clear()
        files_read.clear()
        print(f"{GREEN}Conversation cleared.{NC}")
        return True, None

    elif command == "/model":
        if not arg:
            print(f"{YELLOW}Current model: {model}{NC}")
            print(f"{DIM}Usage: /model <name>  (e.g. /model llama3.2:3b){NC}")
        else:
            new_model = arg.strip()
            print(f"{GREEN}Switched to model: {new_model}{NC}")
            return True, new_model
        return True, None

    elif command == "/compact":
        if len(messages) < 4:
            print(f"{DIM}Not enough conversation to compact.{NC}")
            return True, None

        print(f"{DIM}Compacting conversation...{NC}")
        summary_messages = [
            {"role": "system", "content": "Summarize this conversation concisely, preserving key decisions, file paths mentioned, and what was accomplished. Be brief."},
            {"role": "user", "content": "\n\n".join(
                f"[{m['role']}]: {m['content'][:500]}" for m in messages[-20:]
            )},
        ]
        summary = ollama_chat_stream(
            ollama_url, model, summary_messages,
            lambda t, f: sys.stdout.write(t) or sys.stdout.flush(),
        )
        print()

        messages.clear()
        files_read.clear()
        messages.append({"role": "assistant", "content": f"[Conversation summary]: {summary}"})
        tokens = estimate_tokens(messages)
        print(f"\n{GREEN}Compacted. ~{tokens} tokens.{NC}")
        return True, None

    elif command == "/history":
        if not messages:
            print(f"{DIM}No conversation yet.{NC}")
        else:
            for i, m in enumerate(messages):
                role = m["role"]
                content = m["content"][:120].replace("\n", " ")
                if role == "user":
                    print(f"  {WHITE}{i+1}. you:{NC} {content}")
                elif role == "assistant":
                    print(f"  {CYAN}{i+1}. assistant:{NC} {content}")
                else:
                    print(f"  {DIM}{i+1}. {role}:{NC} {content}")
        return True, None

    elif command == "/tokens":
        tokens = estimate_tokens(messages)
        print(f"{DIM}~{tokens} tokens in conversation ({len(messages)} messages){NC}")
        return True, None

    return False, None


# ─────────────────────────────────────────────────────────────────────────────
# Agent loop (one user turn)
# ─────────────────────────────────────────────────────────────────────────────
def agent_turn(
    user_input: str,
    messages: list[dict],
    system_prompt: str,
    model: str,
    ollama_url: str,
    session_id: int,
) -> None:
    """Process one user turn: send to Ollama, handle tool calls in a loop."""
    messages.append({"role": "user", "content": user_input})
    save_message(session_id, "user", user_input)

    for iteration in range(MAX_TOOL_CALLS_PER_TURN):
        # Build full message list with system prompt
        full_messages = [{"role": "system", "content": system_prompt}] + messages

        # Stream response
        printer = StreamPrinter()
        response = ollama_chat_stream(ollama_url, model, full_messages, printer.on_token)

        if STREAM_CANCELLED:
            print(f"\n{DIM}(cancelled){NC}")
            if response:
                messages.append({"role": "assistant", "content": response})
            return

        if not response.strip():
            print(f"{DIM}(empty response){NC}")
            return

        # Check for tool call
        tool_name, params, before, after = parse_tool_call(response)

        if tool_name is None:
            # No tool call — done
            if not printer.in_tool:
                # Already printed via streaming
                pass
            else:
                # Somehow entered tool mode but no valid call — print what we have
                sys.stdout.write(response)
                sys.stdout.flush()
            print()
            messages.append({"role": "assistant", "content": response})
            save_message(session_id, "assistant", response)
            return

        # Tool call detected
        messages.append({"role": "assistant", "content": response})

        # Print any text before the tool call (if not already printed)
        if before and not printer.in_tool:
            pass  # already streamed
        elif before and printer.in_tool:
            # The before text wasn't printed because we entered tool mode
            pass

        # Execute the tool
        param_summary = ", ".join(f"{k}={repr(v[:60])}" for k, v in (params or {}).items())
        print(f"\n{PINK}▸ {tool_name}{NC}({DIM}{param_summary}{NC})")

        result = execute_tool(tool_name, params or {})

        # Show result (truncated for display)
        display_result = result
        result_lines = result.split("\n")
        if len(result_lines) > 30:
            display_result = "\n".join(result_lines[:30]) + f"\n{DIM}... ({len(result_lines)} lines){NC}"
        print(f"{DIM}{display_result}{NC}")

        # Add tool result to messages for next iteration
        tool_msg = f"[Tool Result: {tool_name}]\n{result}"
        messages.append({"role": "user", "content": tool_msg})
        save_message(session_id, "tool", tool_msg)

    print(f"\n{YELLOW}(max tool calls reached for this turn){NC}")


# ─────────────────────────────────────────────────────────────────────────────
# Readline setup
# ─────────────────────────────────────────────────────────────────────────────
def setup_readline():
    history_file = os.path.expanduser("~/.blackroad/br-code-readline-history")
    os.makedirs(os.path.dirname(history_file), exist_ok=True)
    try:
        readline.read_history_file(history_file)
    except FileNotFoundError:
        pass
    readline.set_history_length(1000)

    import atexit
    atexit.register(readline.write_history_file, history_file)


# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────
def main():
    global CWD

    parser = argparse.ArgumentParser(description="BR Code — Local Coding Assistant")
    parser.add_argument("--model", "-m", default="blackroad-code", help="BlackRoad model name")
    parser.add_argument("--ollama-url", default="http://localhost:11434", help="Ollama API URL")
    parser.add_argument("prompt", nargs="*", help="Initial prompt (optional)")
    args = parser.parse_args()

    model = args.model
    ollama_url = args.ollama_url

    # Setup
    setup_readline()
    init_db()
    session_id = start_session(model)
    system_prompt = build_system_prompt(CWD)
    messages: list[dict] = []

    show_banner(model, CWD)

    # Handle Ctrl+C gracefully
    def sigint_handler(sig, frame):
        global STREAM_CANCELLED
        STREAM_CANCELLED = True

    signal.signal(signal.SIGINT, sigint_handler)

    # If initial prompt given on command line
    initial_prompt = " ".join(args.prompt) if args.prompt else None
    if initial_prompt:
        print(f"{BOLD}you >{NC} {initial_prompt}")
        agent_turn(initial_prompt, messages, system_prompt, model, ollama_url, session_id)

    # REPL
    while True:
        try:
            user_input = input(f"{BOLD}you >{NC} ").strip()
        except (EOFError, KeyboardInterrupt):
            print(f"\n{DIM}Session ended.{NC}")
            break

        if not user_input:
            continue

        # Slash commands
        if user_input.startswith("/"):
            handled, new_model = handle_slash(user_input, messages, model, ollama_url)
            if new_model:
                model = new_model
                system_prompt = build_system_prompt(CWD)
            if handled:
                continue

        # Check token budget
        tokens = estimate_tokens(messages)
        if tokens > TOKEN_BUDGET:
            print(f"{YELLOW}Context getting large (~{tokens} tokens). Consider /compact to summarize.{NC}")

        # Run agent turn
        agent_turn(user_input, messages, system_prompt, model, ollama_url, session_id)


if __name__ == "__main__":
    main()
