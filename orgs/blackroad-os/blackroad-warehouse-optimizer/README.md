# blackroad-warehouse-optimizer

> Warehouse layout optimization with ABC velocity analysis, slot scoring, and placement recommendations.

## Features

- **ABC analysis** — Pareto 80/15/5 velocity classification
- **Slot scoring engine** — considers aisle proximity, level, product weight, volume fit, category match
- **Placement recommendations** ranked by score
- **Optimization report** — identifies misplaced items and generates MOVE / REPLENISH actions
- **Utilization heatmap** — ASCII visualization by aisle × row
- **Bulk slot creation** for rapid warehouse setup
- **Low-stock alerts** integrated into optimization

## Quick Start

```bash
pip install -e .

# Create warehouse layout
python src/warehouse_optimizer.py bulk-slots 10 20 --levels 4 --zone A

# Add products
python src/warehouse_optimizer.py add-product SKU-001 "FastWidget" electronics 2.5 --picks 200
python src/warehouse_optimizer.py add-product SKU-002 "SlowWidget" general 1.0 --picks 5

# Get placement recommendation
python src/warehouse_optimizer.py recommend SKU-001

# Place product
python src/warehouse_optimizer.py place SKU-001 s010101 --qty 50

# Run ABC classification
python src/warehouse_optimizer.py analyze

# Optimize layout
python src/warehouse_optimizer.py optimize

# Utilization report + heatmap
python src/warehouse_optimizer.py report
python src/warehouse_optimizer.py heatmap
```

## CLI Reference

| Command | Description |
|---------|-------------|
| `add-slot AISLE ROW LEVEL [--zone] [--type]` | Add single slot |
| `bulk-slots AISLES ROWS [--levels] [--zone]` | Bulk create |
| `add-product SKU NAME CAT WEIGHT [--picks]` | Add product |
| `place SKU SLOT_ID [--qty]` | Place product in slot |
| `recommend SKU [--top N]` | Suggest best slots |
| `analyze` | ABC velocity analysis |
| `optimize` | Layout recommendations |
| `report` | Utilization statistics |
| `heatmap` | ASCII utilization map |
| `list-products` | All products with velocity |

## Slot Scoring Formula

Score is influenced by:
1. **Aisle proximity** (A-items favour aisles 1–3, C-items prefer far aisles)
2. **Level suitability** (heavy items penalised above level 1)
3. **Volume fit** (ratio of product volume to slot volume)
4. **Category match** (refrigerated/hazmat slots match product category)

## Development

```bash
pytest tests/ -v --cov=src
```
