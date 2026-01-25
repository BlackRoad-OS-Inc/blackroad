# Lucidia Core

**AI reasoning engines for specialized domains - physics, mathematics, chemistry, geology, and more.**

```bash
pip install lucidia-core
```

## What is this?

Lucidia is a collection of specialized AI reasoning agents, each modeled after a domain expert:

| Agent | Domain | Capabilities |
|-------|--------|--------------|
| **Physicist** | Physics | Energy modeling, force calculations, feedback systems |
| **Mathematician** | Mathematics | Symbolic computation, proofs, numerical analysis |
| **Chemist** | Chemistry | Molecular analysis, reactions, compound properties |
| **Geologist** | Geology | Terrain modeling, stratigraphy, resource mapping |
| **Analyst** | Data Science | Pattern recognition, insights, statistical analysis |
| **Architect** | Systems | Design blueprints, architecture planning |
| **Engineer** | Engineering | Structural analysis, calculations, optimization |
| **Painter** | Visual | Graphics generation, artistic rendering |
| **Poet** | Creative | Poetry, lyrical composition, narrative |
| **Speaker** | NLP | Speech synthesis, communication, translation |

## Quick Start

### CLI Usage

```bash
# List available agents
lucidia list

# Run the physicist agent
lucidia run physicist --query "Model energy flow in a thermal system"

# Start the API server
lucidia api --port 8000
```

### API Usage

```bash
# Start the server
lucidia-api

# Or with Python
python -m lucidia_core.api
```

Then query the agents:

```bash
# Check health
curl http://localhost:8000/health

# Physicist analysis
curl -X POST http://localhost:8000/physicist/analyze \
  -H "Content-Type: application/json" \
  -d '{"query": "Calculate the energy required to heat 1kg of water from 20C to 100C"}'

# Mathematician computation
curl -X POST http://localhost:8000/mathematician/compute \
  -H "Content-Type: application/json" \
  -d '{"query": "Solve x^2 - 5x + 6 = 0"}'
```

### Python Usage

```python
from lucidia_core import get_physicist, get_mathematician

# Load the physicist
PhysicistSeed, load_seed = get_physicist()
seed = load_seed("codex21.yaml")

# Load the mathematician
MathematicianSeed, load_seed = get_mathematician()
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/health` | GET | Health check and agent list |
| `/physicist/analyze` | POST | Physics analysis |
| `/physicist/energy-flow` | POST | Energy flow modeling |
| `/mathematician/compute` | POST | Mathematical computation |
| `/mathematician/prove` | POST | Proof assistance |
| `/chemist/analyze` | POST | Chemical analysis |
| `/geologist/terrain` | POST | Terrain analysis |
| `/analyst/insights` | POST | Data insights |
| `/architect/design` | POST | System design |

## Architecture

```
lucidia-core/
├── lucidia_core/       # Package module
│   ├── api.py          # FastAPI endpoints
│   └── cli.py          # CLI entry point
├── physicist.py        # Physics reasoning engine (867 lines)
├── mathematician.py    # Math reasoning engine (760 lines)
├── chemist.py          # Chemistry engine (569 lines)
├── geologist.py        # Geology engine (654 lines)
├── analyst.py          # Data analysis (505 lines)
├── architect.py        # System design (392 lines)
├── engineer.py         # Engineering (599 lines)
├── painter.py          # Visual generation (583 lines)
├── poet.py             # Creative text (250 lines)
├── speaker.py          # Speech/NLP (302 lines)
├── codex*.yaml         # Agent seed configurations
└── quantum_engine/     # Quantum computing extensions
```

## Configuration

Each agent is configured via a YAML "seed" file (e.g., `codex21.yaml` for Physicist):

```yaml
system_charter:
  agent_name: "Physicist"
  generation: "2024"
  domain: ["physics", "energy", "dynamics"]
  moral_constant: "preserve momentum gently"
  core_principle: "ground every run on measured observations"
```

## License

MIT - See [LICENSE](LICENSE) for details.

---

Built by [BlackRoad OS](https://blackroad.io)

---

## 📜 License & Copyright

**Copyright © 2026 BlackRoad OS, Inc. All Rights Reserved.**

**CEO:** Alexa Amundson | **PROPRIETARY AND CONFIDENTIAL**

This software is NOT for commercial resale. Testing purposes only.

### 🏢 Enterprise Scale:
- 30,000 AI Agents
- 30,000 Human Employees
- CEO: Alexa Amundson

**Contact:** blackroad.systems@gmail.com

See [LICENSE](LICENSE) for complete terms.
