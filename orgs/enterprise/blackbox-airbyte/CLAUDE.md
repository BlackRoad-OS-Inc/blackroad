# BlackBox Airbyte

> Open source data integration platform (Fork)

## Quick Reference

| Property | Value |
|----------|-------|
| **Upstream** | airbytehq/airbyte |
| **Type** | Data Integration |
| **Stack** | Python + Java |
| **License** | ELv2/MIT |

## Tech Stack

```
Connectors: Python
Platform: Java + Kotlin
Frontend: React + TypeScript
Database: PostgreSQL
Queue: Temporal
```

## Commands

```bash
./gradlew build     # Build platform
python -m pytest    # Test connectors
docker compose up   # Start locally
```

## BlackRoad Integration

Sovereign fork for:
- Custom data connectors
- BlackRoad memory ingestion
- Analytics pipelines

## Key Components

- **Sources**: Data extraction connectors
- **Destinations**: Data loading connectors
- **Normalization**: Schema transformation
- **Scheduling**: Sync orchestration

## Connector Development

```python
from airbyte_cdk.sources import Source

class MySource(Source):
    def check(self, logger, config):
        # Validate connection
        pass

    def streams(self, config):
        # Return available streams
        pass
```

## Related Repos

- `blackbox-prefect` - Workflow orchestration
- `blackbox-temporal` - Durable execution
- `blackroad-tools` - DevOps utilities
