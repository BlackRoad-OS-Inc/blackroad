# blackroad-workflow-builder

**BlackRoad Workflow Builder** — A DAG-based visual workflow execution engine with step dependencies, cycle detection, run history, and a full CLI.

## Features

- 📊 **DAG Validation** — DFS cycle detection + Kahn's topological sort
- ⚡ **Execution Engine** — Runs steps in dependency order with context propagation
- 🔄 **Step Types** — `task`, `condition`, `transform`, `notify`, `delay`, `parallel`
- 🧮 **Condition Evaluation** — Expression-based branching with operators: `eq`, `ne`, `gt`, `lt`, `contains`
- 📜 **Run History** — Full audit trail per workflow with duration and step results
- 🔀 **Critical Path** — Longest path analysis for performance optimization
- 💾 **SQLite persistence** — 5-table schema with foreign keys and indexes
- 🎨 **ANSI CLI** — 8 subcommands with color-coded output

## Install

```bash
pip install -r requirements.txt
```

## Usage

```bash
# Create workflow
python src/workflow_builder.py create my-pipeline --description "CI/CD pipeline" --tags "ci,deploy"

# Add steps
python src/workflow_builder.py add-step my-pipeline checkout --type task --config '{"command":"git pull"}'
python src/workflow_builder.py add-step my-pipeline build --type task --depends-on <step_id>
python src/workflow_builder.py add-step my-pipeline test --type condition --config '{"expression":"exit_code eq 0"}'
python src/workflow_builder.py add-step my-pipeline notify --type notify --config '{"channel":"slack","message":"Done!"}'

# Validate DAG
python src/workflow_builder.py validate my-pipeline

# Run workflow
python src/workflow_builder.py run my-pipeline --context '{"env":"prod"}'

# View history
python src/workflow_builder.py history my-pipeline --limit 5

# List all workflows
python src/workflow_builder.py list

# Export to JSON
python src/workflow_builder.py export my-pipeline --output workflow.json

# Delete
python src/workflow_builder.py delete my-pipeline
```

## Architecture

```
WorkflowEngine
├── DAGValidator        ← DFS + Kahn's algorithm
│   ├── detect_cycle()
│   ├── topological_sort()
│   └── critical_path()
├── WorkflowDB          ← SQLite (5 tables)
│   ├── workflows
│   ├── steps
│   ├── conditions
│   ├── triggers
│   └── runs
└── CLI (8 subcommands)
```

## Testing

```bash
pytest tests/ -v --cov=src --cov-report=term-missing
```

## License

Proprietary — BlackRoad OS, Inc.
