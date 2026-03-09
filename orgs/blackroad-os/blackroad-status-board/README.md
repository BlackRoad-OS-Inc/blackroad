# blackroad-status-board

A lightweight, self-hosted service-health monitor that tracks HTTP endpoints, records response times, calculates uptime percentages, and fires alerts when services degrade or go down. All data lives in a local SQLite database — no external dependencies, no cloud account required.

The monitoring engine makes real HTTP requests using Python's standard `urllib` library. Each check records status, response time, and HTTP status code. Uptime is recalculated on every check using a rolling window of the last 100 results, giving an accurate picture without unbounded storage growth.

Part of the **BlackRoad OS** developer toolchain — drop it into any CI pipeline or cron job for always-on uptime visibility.

## Features

- **HTTP health checks** — validates status code, measures response time, classifies `operational` / `degraded` / `down`
- **Rolling uptime** — percentage calculated from the last 100 checks per service
- **Automatic alerting** — writes an alert record whenever a service transitions to `down`
- **Multi-service batch check** — check all registered services with one command
- **JSON report export** — full service list + recent alerts in a single file
- **SQLite persistence** — zero-config database at `~/.blackroad/status_board.db`
- **CLI interface** — `list`, `add`, `check`, `export`

## Installation

```bash
git clone https://github.com/BlackRoad-OS/blackroad-status-board.git
cd blackroad-status-board
python3 src/status_board.py
```

Run the test suite:

```bash
pip install pytest
pytest tests/ -v
```

## Usage

```bash
# Add a service to monitor
python3 src/status_board.py add "GitHub API" "https://api.github.com"
python3 src/status_board.py add "My API" "https://api.myapp.com" 200

# Check a specific service right now
python3 src/status_board.py check "GitHub API"

# Check all registered services
python3 src/status_board.py check

# List current status of all services
python3 src/status_board.py list

# Export a JSON report
python3 src/status_board.py export /tmp/status_report.json
```

### Example output

```
=== Service Status (2) ===
  ✓ GitHub API  | https://api.github.com          | operational | 142ms | Uptime: 100.0%
  ✗ My API      | https://api.myapp.com           | down        | 10023ms | Uptime: 72.0%
```

## API

### `Service`
Dataclass for a monitored endpoint:

| Field | Type | Description |
|---|---|---|
| `name` | `str` | Unique service name |
| `url` | `str` | Full URL to check |
| `status` | `str` | `operational`, `degraded`, or `down` |
| `response_time_ms` | `float` | Last response time in milliseconds |
| `uptime_pct` | `float` | Rolling uptime percentage (0–100) |
| `expected_status_code` | `int` | HTTP code considered healthy (default 200) |

### `StatusBoardManager`

| Method | Description |
|---|---|
| `add_service(s)` | Register a new service |
| `check_service(name)` | Run a live HTTP check, persist result |
| `check_all()` | Check every registered service |
| `get_status()` | Return current status for all services |
| `export_report(path)` | Write JSON report with services + alerts |

## License

MIT © BlackRoad OS, Inc.
