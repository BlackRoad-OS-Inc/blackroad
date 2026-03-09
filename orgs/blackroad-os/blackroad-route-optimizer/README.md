# blackroad-route-optimizer

> Delivery route optimization using nearest-neighbor heuristic + 2-opt improvement + Or-opt.

## Features

- **Nearest-neighbor** greedy construction
- **2-opt local search** improvement
- **Or-opt** single-city relocation
- **Haversine distances** for real-world lat/lon coordinates
- **Multi-vehicle** support with capacity tracking
- **Cost estimation** (fuel cost per km)
- **Algorithm comparison** report

## Quick Start

```bash
pip install -e .

# Setup locations
python src/route_optimizer.py add-location Depot 40.7128 -74.0060 --depot
python src/route_optimizer.py add-location CustomerA 40.730 -74.010
python src/route_optimizer.py add-location CustomerB 40.720 -73.990

# Register vehicle
python src/route_optimizer.py add-vehicle Truck1 1000 --speed 60

# Add deliveries
python src/route_optimizer.py add-delivery CustomerA 50
python src/route_optimizer.py add-delivery CustomerB 30

# Optimize route
python src/route_optimizer.py optimize Truck1

# Compare algorithms
python src/route_optimizer.py compare
```

## CLI Reference

| Command | Description |
|---------|-------------|
| `add-location NAME LAT LON [--depot]` | Register a location |
| `add-delivery LOCATION WEIGHT [--priority]` | Add a delivery |
| `add-vehicle NAME CAPACITY [--speed] [--fuel-cost]` | Register a vehicle |
| `optimize VEHICLE` | Compute optimized route |
| `compare` | Compare NN vs 2-opt distances |
| `stats ROUTE_ID` | Show route statistics |
| `list-routes` | List all computed routes |
| `list-locations` | List all locations |

## Algorithms

- **Nearest-Neighbor** — O(n²) greedy TSP heuristic
- **2-opt** — iterative edge-swap improvement; typically 5–20% reduction
- **Or-opt** — relocates individual stops for further gains
- **Haversine** — spherical earth great-circle distance

## Development

```bash
pytest tests/ -v --cov=src
```
