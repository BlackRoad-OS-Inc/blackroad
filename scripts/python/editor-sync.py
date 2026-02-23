#!/usr/bin/env python3
"""
BLACKROAD EDITOR SYNC
Sync state between Claude Code, Cursor, Copilot, and other editors

This daemon maintains shared state so all editors know:
- What files are being worked on
- Recent commands and actions
- Memory journal entries
- Project context
"""

import os
import sys
import json
import time
import hashlib
from pathlib import Path
from datetime import datetime
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

# BlackRoad colors
PINK = '\033[38;5;205m'
AMBER = '\033[38;5;214m'
RESET = '\033[0m'

# State file locations
MEMORY_DIR = Path.home() / '.blackroad' / 'memory'
STATE_FILE = MEMORY_DIR / 'editor-state.json'
SYNC_LOG = MEMORY_DIR / 'editor-sync.log'

# Watched directories
WATCH_DIRS = [
    Path.home() / '.cursor',           # Cursor state
    Path.home() / '.vscode',           # VS Code state
    Path.home() / '.claude',           # Claude Code state
    Path.home() / '.copilot',          # GitHub Copilot state
]

class EditorState:
    """Shared editor state"""

    def __init__(self):
        self.state = {
            'last_editor': None,
            'last_sync': None,
            'current_file': None,
            'current_project': os.getcwd(),
            'editors': {},
            'recent_actions': [],
            'conflicts': []
        }
        self.load()

    def load(self):
        """Load state from file"""
        if STATE_FILE.exists():
            try:
                with open(STATE_FILE) as f:
                    self.state.update(json.load(f))
            except:
                pass

    def save(self):
        """Save state to file"""
        MEMORY_DIR.mkdir(parents=True, exist_ok=True)
        self.state['last_sync'] = datetime.now().isoformat()
        with open(STATE_FILE, 'w') as f:
            json.dump(self.state, f, indent=2)

    def update_editor(self, editor_name, data):
        """Update state for a specific editor"""
        self.state['last_editor'] = editor_name
        self.state['editors'][editor_name] = {
            'last_seen': datetime.now().isoformat(),
            **data
        }
        self.save()

    def add_action(self, editor, action, detail=None):
        """Record an action"""
        entry = {
            'timestamp': datetime.now().isoformat(),
            'editor': editor,
            'action': action,
            'detail': detail
        }
        self.state['recent_actions'].append(entry)
        # Keep last 50 actions
        self.state['recent_actions'] = self.state['recent_actions'][-50:]
        self.save()

    def check_conflicts(self, editor, file_path):
        """Check if another editor is working on the same file"""
        for name, data in self.state['editors'].items():
            if name == editor:
                continue
            if data.get('current_file') == file_path:
                # Potential conflict
                last_seen = data.get('last_seen', '')
                # If seen in last 5 minutes, flag as conflict
                if last_seen:
                    try:
                        seen_time = datetime.fromisoformat(last_seen)
                        if (datetime.now() - seen_time).seconds < 300:
                            return {
                                'other_editor': name,
                                'file': file_path,
                                'last_seen': last_seen
                            }
                    except:
                        pass
        return None


class EditorWatcher(FileSystemEventHandler):
    """Watch for editor activity"""

    def __init__(self, state):
        self.state = state

    def on_modified(self, event):
        if event.is_directory:
            return

        path = Path(event.src_path)

        # Detect which editor
        editor = None
        if '.cursor' in str(path):
            editor = 'cursor'
        elif '.vscode' in str(path):
            editor = 'vscode'
        elif '.claude' in str(path):
            editor = 'claude-code'
        elif '.copilot' in str(path):
            editor = 'copilot'

        if editor:
            self.state.add_action(editor, 'file_modified', str(path))
            print(f"{AMBER}[SYNC]{RESET} {editor} activity: {path.name}")


def detect_cursor():
    """Check if Cursor is running"""
    cursor_pid = Path('/tmp/cursor.pid')
    if cursor_pid.exists():
        return True
    # Check process list
    import subprocess
    result = subprocess.run(['pgrep', '-f', 'Cursor'], capture_output=True)
    return result.returncode == 0


def detect_claude_code():
    """Check if Claude Code is running"""
    import subprocess
    result = subprocess.run(['pgrep', '-f', 'claude'], capture_output=True)
    return result.returncode == 0


def main():
    print(f"{PINK}{'='*50}{RESET}")
    print(f"{PINK}  BLACKROAD EDITOR SYNC{RESET}")
    print(f"{PINK}  Keeping all editors in harmony{RESET}")
    print(f"{PINK}{'='*50}{RESET}")
    print()

    MEMORY_DIR.mkdir(parents=True, exist_ok=True)

    state = EditorState()
    watcher = EditorWatcher(state)
    observer = Observer()

    # Watch editor directories
    watched = 0
    for dir_path in WATCH_DIRS:
        if dir_path.exists():
            observer.schedule(watcher, str(dir_path), recursive=True)
            print(f"{AMBER}[WATCH]{RESET} {dir_path}")
            watched += 1

    if watched == 0:
        print(f"{AMBER}[WARN]{RESET} No editor directories found to watch")
        print(f"Creating: {STATE_FILE}")
        state.save()

    observer.start()
    print()
    print(f"{PINK}[SYNC]{RESET} Running... (Ctrl+C to stop)")
    print(f"{PINK}[SYNC]{RESET} State file: {STATE_FILE}")
    print()

    try:
        while True:
            # Periodic checks
            state.state['editors']['claude-code'] = {
                'running': detect_claude_code(),
                'last_check': datetime.now().isoformat()
            }
            state.state['editors']['cursor'] = {
                'running': detect_cursor(),
                'last_check': datetime.now().isoformat()
            }
            state.save()

            time.sleep(10)  # Check every 10 seconds
    except KeyboardInterrupt:
        observer.stop()
        print(f"\n{PINK}[SYNC]{RESET} Shutting down")

    observer.join()


if __name__ == '__main__':
    main()
