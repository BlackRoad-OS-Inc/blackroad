# br-rs — BlackRoad OS CLI (Rust)

Rust rewrite of the BlackRoad OS CLI for performance and portability.

## Commands

| Command | Description |
|---------|-------------|
| `br-rs shell [--agent CECE]` | Interactive agent shell |
| `br-rs tui` | Terminal UI dashboard |
| `br-rs watch [--interval 2]` | Real-time system monitor |
| `br-rs status` | Quick status check |

## Build

```bash
cargo build --release
# Binary at: target/release/br-rs
```

## Run

```bash
cargo run -- shell --agent LUCIDIA
cargo run -- watch --interval 1
cargo run -- tui
```
