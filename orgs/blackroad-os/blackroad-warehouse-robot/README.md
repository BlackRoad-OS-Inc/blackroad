# blackroad-warehouse-robot

> Warehouse robot task coordination, pick list management, zone assignment, and S-shape route optimization.

## Features

- **Zone management** with configurable aisles/shelves
- **Pick list creation** from SKU:quantity pairs
- **Automatic task assignment** to idle robots
- **S-shape + nearest-pick sequencing** to minimize travel distance
- **Task completion tracking** with automatic robot status updates
- **ASCII warehouse map** showing zones and robot positions
- **Battery and payload tracking** per robot

## Quick Start

```bash
pip install -e .

# Setup zones and inventory
python src/warehouse_robot.py add-zone ZoneA 1 5 1 20
python src/warehouse_robot.py add-item SKU001 "Widget" ZoneA 2 5 "A1" 100
python src/warehouse_robot.py add-item SKU002 "Gadget" ZoneA 3 8 "B3" 50

# Register robot
python src/warehouse_robot.py add-robot R001 ZoneA --speed 1.5 --payload 30

# Create and assign a pick list
python src/warehouse_robot.py create-picklist ORD-001 --items "SKU001:3,SKU002:2"
python src/warehouse_robot.py assign <pick_list_id>

# Monitor status
python src/warehouse_robot.py status
python src/warehouse_robot.py map
```

## CLI Reference

| Command | Description |
|---------|-------------|
| `add-zone NAME AISLE_S AISLE_E SHELF_S SHELF_E` | Create zone |
| `add-robot NAME ZONE [--speed] [--payload]` | Register robot |
| `add-item SKU NAME ZONE AISLE SHELF BIN QTY` | Register item |
| `create-picklist ORDER --items SKU:QTY,...` | Create pick list |
| `assign PICK_LIST_ID` | Assign to robots |
| `complete TASK_ID` | Mark task done |
| `status` | Robot fleet status |
| `list-picklists` | All pick lists |
| `map` | ASCII warehouse map |

## Development

```bash
pytest tests/ -v --cov=src
```
