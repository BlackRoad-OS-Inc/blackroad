# blackroad-vehicle-maintenance

> Fleet vehicle maintenance scheduler with predictive service alerts, cost tracking, and full service history.

## Features

- **8 built-in service types** (oil, brakes, timing belt, etc.) seeded on first run
- **Predictive alerts** — CRITICAL / OVERDUE / DUE_SOON / OK based on both km and days
- **Cost analysis** per vehicle with breakdown by service type
- **Service history** with technician and parts tracking
- **Schedule forecast** — upcoming services within a km horizon
- **ABC criticality levels** — routine / important / critical

## Quick Start

```bash
pip install -e .

# Register a vehicle
python src/vehicle_maintenance.py add-vehicle "Truck01" Ford Transit 2021 VIN123 --odometer 45000

# Record a service
python src/vehicle_maintenance.py record-service "Truck01" "Oil Change" 45500 85.00 --tech "Alice"

# Check what's due now
python src/vehicle_maintenance.py due-now

# Cost report
python src/vehicle_maintenance.py cost-report Truck01

# Service history
python src/vehicle_maintenance.py history Truck01

# Upcoming in next 20,000 km
python src/vehicle_maintenance.py schedule Truck01 --horizon 20000
```

## CLI Reference

| Command | Description |
|---------|-------------|
| `add-vehicle NAME MAKE MODEL YEAR VIN` | Register vehicle |
| `record-service VEHICLE SERVICE ODOMETER COST` | Log a service |
| `update-odometer VEHICLE KM` | Update current odometer |
| `due-now [--vehicle]` | Show alerts |
| `cost-report VEHICLE` | Cost breakdown |
| `history VEHICLE` | Service history |
| `schedule VEHICLE [--horizon]` | Forecast upcoming services |
| `list-vehicles` | List all vehicles |

## Development

```bash
pytest tests/ -v --cov=src
```
