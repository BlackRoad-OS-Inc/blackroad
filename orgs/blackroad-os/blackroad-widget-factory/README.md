# blackroad-widget-factory

UI widget configuration system for BlackRoad OS dashboards.

## Features
- Widget dataclass (id, type, config, position) for 20+ widget types
- WidgetLayout for grid-based UI composition
- Serialize/deserialize widgets to/from JSON
- Generate React component props + PropTypes declarations
- Config validation with grid overflow detection
- Export layouts as JSON, CSS Grid, or HTML
- SQLite persistence (`widgets` + `layouts` tables)

## Widget Types
button, input, text, image, chart, table, card, modal, dropdown,
checkbox, slider, progress, badge, avatar, tooltip, tabs, accordion,
navbar, sidebar, form

## Usage
```bash
# Create a widget
python src/main_module.py create-widget button --label "Submit" \
  --config '{"label":"Submit","variant":"primary","disabled":false}' \
  --x 0 --y 0 --width 3 --height 1

# Get widget JSON
python src/main_module.py get-widget <widget_id>

# Validate widget config
python src/main_module.py validate <widget_id>

# Generate React props
python src/main_module.py react-props <widget_id>

# Create layout
python src/main_module.py create-layout "dashboard" --columns 12

# Export layout
python src/main_module.py export-layout dashboard --format json
python src/main_module.py export-layout dashboard --format css
python src/main_module.py export-layout dashboard --format html
```

## API
```python
from src.main_module import Widget, Position, WidgetLayout, save_widget, generate_react_props, get_db

conn = get_db()
w = Widget(widget_type="button", config={"label": "OK"}, position=Position(x=0, y=0, width=2))
save_widget(w, conn=conn)
props = generate_react_props(w)
print(props["componentName"])  # "Button"
```

## Testing
```bash
python -m pytest tests/ -v
```
