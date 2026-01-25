# Lucidia Autotester

Lucidia Autotester provides a lightweight nightly test harness for Lucidia/BlackRoad
services. It discovers registered services, runs minimal sanity tests, and opens or
updates issues when failures are detected.

## Features
- Vendor-neutral service discovery via static JSON registry or internal Service Graph
- Async HTTP tests with correlation IDs and short-lived tokens
- Minimal test suites for service health, authz, and read paths
- Structured failure sink for issue management and telemetry

## Usage
```bash
# run tests against staging services
make test ENV=staging
```

## Adding a Service
1. Add service definition to `bin/service_mapping.<env>.json`
2. Create a test module under `tests/services/<service_slug>/`
3. Include service requirements referencing `tests/common_requirements.txt`
4. Run `pre-commit run --files <changed files>`

_Last updated on 2025-09-11_
