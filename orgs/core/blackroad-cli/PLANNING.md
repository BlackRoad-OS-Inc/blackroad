# BlackRoad CLI - Planning

> Development planning for the command-line interface

## Vision

Rewrite the CLI in Rust for:
- Sub-millisecond startup time
- Native binary distribution
- Cross-platform support
- Interactive TUI mode

---

## Current Sprint

### Sprint 2026-02

#### Goals
- [ ] Design Rust architecture
- [ ] Port core commands
- [ ] Implement TUI framework
- [ ] Add auto-update mechanism

#### Tasks

| Task | Priority | Status | Est. |
|------|----------|--------|------|
| Rust project setup | P0 | ✅ Done | 1d |
| Clap CLI framework | P0 | 🔄 In Progress | 2d |
| TUI with ratatui | P1 | 📋 Planned | 3d |
| API client port | P0 | 📋 Planned | 2d |

---

## Command Inventory

### To Port (Node.js → Rust)

| Command | Priority | Complexity |
|---------|----------|------------|
| `br status` | P0 | Low |
| `br agents` | P0 | Medium |
| `br tasks` | P0 | Medium |
| `br memory` | P1 | High |
| `br deploy` | P1 | High |
| `br config` | P2 | Low |

### New Commands

| Command | Description | Priority |
|---------|-------------|----------|
| `br tui` | Interactive terminal UI | P0 |
| `br watch` | Real-time monitoring | P1 |
| `br logs` | Stream service logs | P1 |
| `br shell` | Interactive agent shell | P2 |

---

## Architecture (Rust)

```
src/
├── main.rs           # Entry point
├── cli/
│   ├── mod.rs       # CLI module
│   ├── commands/    # Command implementations
│   │   ├── status.rs
│   │   ├── agents.rs
│   │   ├── tasks.rs
│   │   └── ...
│   └── args.rs      # Argument parsing
├── tui/
│   ├── mod.rs       # TUI module
│   ├── app.rs       # Application state
│   ├── ui.rs        # UI rendering
│   └── events.rs    # Event handling
├── api/
│   ├── mod.rs       # API client
│   ├── client.rs    # HTTP client
│   └── models.rs    # Data models
├── config/
│   ├── mod.rs       # Configuration
│   └── settings.rs  # User settings
└── utils/
    ├── mod.rs
    └── ...
```

---

## TUI Design

```
┌─────────────────────────────────────────────────────────────┐
│ BlackRoad CLI v2.0.0                           [?] Help     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ AGENTS                                    [1000/30K] │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ ● LUCIDIA    Active   847 tasks   2.3s avg         │   │
│  │ ● ALICE      Active   12,453 tasks   0.1s avg      │   │
│  │ ● OCTAVIA    Active   3,291 tasks   1.8s avg       │   │
│  │ ○ PRISM      Idle     2,104 tasks   0.5s avg       │   │
│  │ ● ECHO       Active   1,876 tasks   0.3s avg       │   │
│  │ ● CIPHER     Active   8,932 tasks   0.05s avg      │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ RECENT TASKS                                         │   │
│  ├─────────────────────────────────────────────────────┤   │
│  │ ✓ Deploy worker-api        ALICE     2m ago         │   │
│  │ ✓ Memory consolidation     ECHO      5m ago         │   │
│  │ ⟳ Security scan           CIPHER    running...      │   │
│  │ ✓ Pattern analysis         PRISM     12m ago        │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│ > _                                                         │
└─────────────────────────────────────────────────────────────┘
```

---

## Dependencies (Rust)

```toml
[dependencies]
clap = { version = "4.5", features = ["derive"] }
tokio = { version = "1.36", features = ["full"] }
reqwest = { version = "0.12", features = ["json"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
ratatui = "0.26"
crossterm = "0.27"
dirs = "5.0"
toml = "0.8"
```

---

## Release Plan

| Version | Features | ETA |
|---------|----------|-----|
| v2.0.0-alpha | Core commands, basic TUI | Feb 2026 |
| v2.0.0-beta | All commands, full TUI | Mar 2026 |
| v2.0.0 | Stable release | Apr 2026 |

---

*Last updated: 2026-02-05*
