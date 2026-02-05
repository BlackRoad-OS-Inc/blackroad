# Lucidia Core

> AI reasoning engines - physicist, mathematician, chemist, geologist, and specialized domain agents

## Quick Reference

| Property | Value |
|----------|-------|
| **Language** | Python 3.10+ |
| **Framework** | FastAPI |
| **Build** | Hatch |
| **License** | MIT |

## Tech Stack

```
Python 3.10+
├── FastAPI (API Server)
├── Pydantic 2 (Data Validation)
├── SymPy (Symbolic Math)
├── NumPy (Numerical Computing)
├── mpmath (Multi-precision Math)
└── Uvicorn (ASGI Server)
```

## Installation

```bash
# Install with pip
pip install lucidia-core

# Development install
pip install -e ".[dev]"
```

## Commands

```bash
lucidia            # CLI entry point
lucidia-api        # Start API server

# Development
pytest             # Run tests
black .            # Format code
ruff check .       # Lint code
mypy .             # Type check
```

## Reasoning Engines

| Engine | Domain | Capabilities |
|--------|--------|--------------|
| **Physicist** | Physics | Mechanics, thermodynamics, quantum |
| **Mathematician** | Mathematics | Algebra, calculus, proofs |
| **Chemist** | Chemistry | Reactions, molecular analysis |
| **Geologist** | Geology | Earth science, minerals |

## Project Structure

```
lucidia_core/
├── engines/        # Reasoning engines
│   ├── physicist.py
│   ├── mathematician.py
│   ├── chemist.py
│   └── geologist.py
├── api.py          # FastAPI server
├── cli.py          # Command line interface
└── models/         # Pydantic models
```

## API Endpoints

```
GET  /health           # Health check
POST /reason           # Submit reasoning task
POST /solve            # Solve problem
GET  /engines          # List available engines
```

## Environment Variables

```env
LUCIDIA_PORT=8000      # API port
LUCIDIA_DEBUG=false    # Debug mode
LUCIDIA_LOG_LEVEL=INFO # Logging level
```

## Related Repos

- `blackroad-agents` - Agent orchestration
- `blackroad-os-core` - Core platform
- `lucidia-math` - Extended math library
