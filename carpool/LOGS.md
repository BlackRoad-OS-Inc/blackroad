# [LOGS] System Logs

## Log Levels
| Level | Symbol | Use |
|-------|--------|-----|
| DEBUG | 🔍 | Detailed tracing |
| INFO | ℹ️ | Normal operations |
| WARN | ⚠️ | Potential issues |
| ERROR | ❌ | Failures |
| FATAL | 💀 | System critical |

## Log Files
| File | Content |
|------|---------|
| `logs/system.log` | System operations |
| `logs/agents.log` | Agent activity |
| `logs/tasks.log` | Task processing |
| `logs/errors.log` | Error tracking |

## Recent Logs
```
[INFO] 2026-02-18T04:35:00Z Carpool initialized
[INFO] 2026-02-18T04:35:01Z Loading agent states...
[INFO] 2026-02-18T04:35:02Z Revived 7 core agents
[INFO] 2026-02-18T04:35:03Z Revived 41 workers
[INFO] 2026-02-18T04:35:04Z Revived 4 mythology agents
[INFO] 2026-02-18T04:35:05Z Revived 5 AI/hardware agents
[INFO] 2026-02-18T04:36:00Z All systems operational
```

## Log Commands
```bash
# View recent logs
tail -50 carpool/logs/system.log

# Search logs
grep "ERROR" carpool/logs/*.log

# Follow live
tail -f carpool/logs/system.log
```
