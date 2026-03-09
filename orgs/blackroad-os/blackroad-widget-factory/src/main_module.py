#!/usr/bin/env python3
"""
blackroad-widget-factory: UI Widget configuration system.
Manages widget definitions, layouts, and React prop generation.
"""

import argparse
import json
import sqlite3
import sys
import uuid
from dataclasses import dataclass, field, asdict
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List, Optional, Union

DB_PATH = Path.home() / ".blackroad" / "widget-factory.db"

# Supported widget types
WIDGET_TYPES = {
    "button", "input", "text", "image", "chart", "table",
    "card", "modal", "dropdown", "checkbox", "slider",
    "progress", "badge", "avatar", "tooltip", "tabs",
    "accordion", "navbar", "sidebar", "form",
}

# Config schemas per widget type
_CONFIG_SCHEMAS: Dict[str, Dict[str, type]] = {
    "button":   {"label": str, "variant": str, "disabled": bool},
    "input":    {"placeholder": str, "type": str, "required": bool, "maxLength": int},
    "text":     {"content": str, "size": str, "weight": str, "color": str},
    "image":    {"src": str, "alt": str, "width": int, "height": int},
    "chart":    {"chartType": str, "data": list, "title": str, "showLegend": bool},
    "table":    {"columns": list, "rows": list, "sortable": bool, "paginate": bool},
    "card":     {"title": str, "body": str, "footer": str, "elevation": int},
    "modal":    {"title": str, "content": str, "closable": bool},
    "dropdown": {"options": list, "placeholder": str, "multiple": bool},
    "checkbox": {"label": str, "checked": bool, "indeterminate": bool},
    "slider":   {"min": (int, float), "max": (int, float), "step": (int, float), "value": (int, float)},
    "progress": {"value": (int, float), "max": (int, float), "label": str, "color": str},
    "badge":    {"text": str, "color": str, "size": str},
    "avatar":   {"src": str, "name": str, "size": str},
    "tooltip":  {"content": str, "placement": str},
    "tabs":     {"items": list, "activeIndex": int},
}

# React prop type mappings
_PROP_TYPES = {
    str: "PropTypes.string",
    int: "PropTypes.number",
    float: "PropTypes.number",
    bool: "PropTypes.bool",
    list: "PropTypes.array",
    dict: "PropTypes.object",
}


# ---------------------------------------------------------------------------
# Data structures
# ---------------------------------------------------------------------------

@dataclass
class Position:
    x: int = 0
    y: int = 0
    width: int = 4    # grid columns (1-12)
    height: int = 2   # grid rows


@dataclass
class Widget:
    widget_type: str
    config: Dict[str, Any] = field(default_factory=dict)
    position: Position = field(default_factory=Position)
    widget_id: str = field(default_factory=lambda: str(uuid.uuid4()))
    label: str = ""
    visible: bool = True
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    db_id: Optional[int] = None


@dataclass
class WidgetLayout:
    name: str
    widgets: List[Widget] = field(default_factory=list)
    columns: int = 12
    row_height: int = 60
    layout_id: Optional[int] = None
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


# ---------------------------------------------------------------------------
# Database
# ---------------------------------------------------------------------------

def get_db(db_path: Path = DB_PATH) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    conn.row_factory = sqlite3.Row
    _init_schema(conn)
    return conn


def _init_schema(conn: sqlite3.Connection) -> None:
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS layouts (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            name        TEXT    NOT NULL UNIQUE,
            columns     INTEGER NOT NULL DEFAULT 12,
            row_height  INTEGER NOT NULL DEFAULT 60,
            created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
            updated_at  TEXT    NOT NULL DEFAULT (datetime('now'))
        );

        CREATE TABLE IF NOT EXISTS widgets (
            id          INTEGER PRIMARY KEY AUTOINCREMENT,
            layout_id   INTEGER REFERENCES layouts(id) ON DELETE SET NULL,
            widget_id   TEXT    NOT NULL UNIQUE,
            widget_type TEXT    NOT NULL,
            label       TEXT    NOT NULL DEFAULT '',
            config      TEXT    NOT NULL DEFAULT '{}',
            pos_x       INTEGER NOT NULL DEFAULT 0,
            pos_y       INTEGER NOT NULL DEFAULT 0,
            pos_width   INTEGER NOT NULL DEFAULT 4,
            pos_height  INTEGER NOT NULL DEFAULT 2,
            visible     INTEGER NOT NULL DEFAULT 1,
            created_at  TEXT    NOT NULL DEFAULT (datetime('now'))
        );

        CREATE INDEX IF NOT EXISTS idx_widgets_layout ON widgets(layout_id);
        CREATE INDEX IF NOT EXISTS idx_widgets_type   ON widgets(widget_type);
    """)
    conn.commit()


# ---------------------------------------------------------------------------
# Widget CRUD
# ---------------------------------------------------------------------------

def save_widget(widget: Widget, layout_id: Optional[int] = None,
                conn: Optional[sqlite3.Connection] = None) -> Widget:
    if not conn:
        return widget
    pos = widget.position
    if widget.db_id is None:
        cur = conn.execute(
            "INSERT INTO widgets(widget_id, layout_id, widget_type, label, config, "
            "pos_x, pos_y, pos_width, pos_height, visible) VALUES(?,?,?,?,?,?,?,?,?,?)",
            (widget.widget_id, layout_id, widget.widget_type, widget.label,
             json.dumps(widget.config), pos.x, pos.y, pos.width, pos.height,
             int(widget.visible)),
        )
        widget.db_id = cur.lastrowid
    else:
        conn.execute(
            "UPDATE widgets SET widget_type=?, label=?, config=?, pos_x=?, pos_y=?, "
            "pos_width=?, pos_height=?, visible=? WHERE id=?",
            (widget.widget_type, widget.label, json.dumps(widget.config),
             pos.x, pos.y, pos.width, pos.height, int(widget.visible), widget.db_id),
        )
    conn.commit()
    return widget


def load_widget(widget_id: str, conn: sqlite3.Connection) -> Optional[Widget]:
    row = conn.execute("SELECT * FROM widgets WHERE widget_id=?", (widget_id,)).fetchone()
    if not row:
        return None
    return _row_to_widget(row)


def _row_to_widget(row) -> Widget:
    return Widget(
        widget_id=row["widget_id"],
        widget_type=row["widget_type"],
        label=row["label"],
        config=json.loads(row["config"]),
        position=Position(
            x=row["pos_x"], y=row["pos_y"],
            width=row["pos_width"], height=row["pos_height"],
        ),
        visible=bool(row["visible"]),
        db_id=row["id"],
    )


def delete_widget(widget_id: str, conn: sqlite3.Connection) -> bool:
    cur = conn.execute("DELETE FROM widgets WHERE widget_id=?", (widget_id,))
    conn.commit()
    return cur.rowcount > 0


# ---------------------------------------------------------------------------
# Layout CRUD
# ---------------------------------------------------------------------------

def save_layout(layout: WidgetLayout, conn: sqlite3.Connection) -> WidgetLayout:
    if layout.layout_id is None:
        cur = conn.execute(
            "INSERT INTO layouts(name, columns, row_height) VALUES(?,?,?)",
            (layout.name, layout.columns, layout.row_height),
        )
        layout.layout_id = cur.lastrowid
    else:
        conn.execute(
            "UPDATE layouts SET name=?, columns=?, row_height=?, updated_at=datetime('now') WHERE id=?",
            (layout.name, layout.columns, layout.row_height, layout.layout_id),
        )
    conn.commit()

    for widget in layout.widgets:
        save_widget(widget, layout_id=layout.layout_id, conn=conn)
    return layout


def load_layout(name: str, conn: sqlite3.Connection) -> Optional[WidgetLayout]:
    row = conn.execute("SELECT * FROM layouts WHERE name=?", (name,)).fetchone()
    if not row:
        return None
    layout = WidgetLayout(
        name=row["name"],
        columns=row["columns"],
        row_height=row["row_height"],
        layout_id=row["id"],
    )
    widget_rows = conn.execute(
        "SELECT * FROM widgets WHERE layout_id=? ORDER BY pos_y, pos_x", (layout.layout_id,)
    ).fetchall()
    layout.widgets = [_row_to_widget(r) for r in widget_rows]
    return layout


def list_layouts(conn: sqlite3.Connection) -> list:
    rows = conn.execute(
        "SELECT l.id, l.name, l.columns, l.row_height, l.created_at, "
        "COUNT(w.id) as widget_count FROM layouts l "
        "LEFT JOIN widgets w ON w.layout_id=l.id GROUP BY l.id ORDER BY l.name"
    ).fetchall()
    return [dict(r) for r in rows]


# ---------------------------------------------------------------------------
# Serialization
# ---------------------------------------------------------------------------

def serialize_widget(widget: Widget) -> dict:
    """Serialize Widget to plain dict (JSON-safe)."""
    return {
        "widget_id": widget.widget_id,
        "widget_type": widget.widget_type,
        "label": widget.label,
        "config": widget.config,
        "position": asdict(widget.position),
        "visible": widget.visible,
        "created_at": widget.created_at,
    }


def deserialize_widget(data: Union[dict, str]) -> Widget:
    """Deserialize dict/JSON string back to Widget."""
    if isinstance(data, str):
        data = json.loads(data)
    pos_data = data.get("position", {})
    return Widget(
        widget_id=data.get("widget_id", str(uuid.uuid4())),
        widget_type=data["widget_type"],
        label=data.get("label", ""),
        config=data.get("config", {}),
        position=Position(
            x=pos_data.get("x", 0),
            y=pos_data.get("y", 0),
            width=pos_data.get("width", 4),
            height=pos_data.get("height", 2),
        ),
        visible=data.get("visible", True),
        created_at=data.get("created_at", datetime.utcnow().isoformat()),
    )


# ---------------------------------------------------------------------------
# React prop generation
# ---------------------------------------------------------------------------

def generate_react_props(widget: Widget) -> dict:
    """
    Generate React component props from widget config.
    Returns a dict with:
      - props: the prop values
      - propTypes: PropTypes declarations
      - defaultProps: default values
      - componentName: suggested React component name
    """
    type_map = {
        "button": "Button",
        "input": "Input",
        "text": "Typography",
        "image": "Image",
        "chart": "Chart",
        "table": "DataTable",
        "card": "Card",
        "modal": "Modal",
        "dropdown": "Select",
        "checkbox": "Checkbox",
        "slider": "Slider",
        "progress": "ProgressBar",
        "badge": "Badge",
        "avatar": "Avatar",
        "tooltip": "Tooltip",
        "tabs": "Tabs",
    }

    component_name = type_map.get(widget.widget_type, "Widget")
    props = {**widget.config, "visible": widget.visible, "id": widget.widget_id}
    if widget.label:
        props["aria-label"] = widget.label

    # Build PropTypes string
    schema = _CONFIG_SCHEMAS.get(widget.widget_type, {})
    prop_types: Dict[str, str] = {"id": "PropTypes.string", "visible": "PropTypes.bool"}
    for key, expected_type in schema.items():
        if isinstance(expected_type, tuple):
            pt = " || ".join(_PROP_TYPES.get(t, "PropTypes.any") for t in expected_type)
        else:
            pt = _PROP_TYPES.get(expected_type, "PropTypes.any")
        prop_types[key] = pt

    # Default props
    defaults: Dict[str, Any] = {"visible": True}
    for key, val in widget.config.items():
        if val is not None:
            defaults[key] = val

    return {
        "componentName": component_name,
        "props": props,
        "propTypes": prop_types,
        "defaultProps": defaults,
        "position": asdict(widget.position),
    }


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

def validate_config(widget: Widget) -> list:
    """Return list of validation error strings."""
    errors = []

    if widget.widget_type not in WIDGET_TYPES:
        errors.append(f"Unknown widget type: {widget.widget_type}")
        return errors

    schema = _CONFIG_SCHEMAS.get(widget.widget_type, {})
    for key, expected_type in schema.items():
        if key not in widget.config:
            continue  # optional
        value = widget.config[key]
        if isinstance(expected_type, tuple):
            if not isinstance(value, expected_type):
                errors.append(f"'{key}' must be one of {expected_type}, got {type(value).__name__}")
        elif not isinstance(value, expected_type):
            errors.append(f"'{key}' must be {expected_type.__name__}, got {type(value).__name__}")

    pos = widget.position
    if not (0 <= pos.x <= 12):
        errors.append(f"Position x={pos.x} out of range [0,12]")
    if not (1 <= pos.width <= 12):
        errors.append(f"Width={pos.width} out of range [1,12]")
    if pos.x + pos.width > 12:
        errors.append(f"Widget overflows grid: x({pos.x}) + width({pos.width}) > 12")
    if pos.height < 1:
        errors.append(f"Height must be >= 1, got {pos.height}")

    if not widget.widget_id:
        errors.append("widget_id is required")

    return errors


# ---------------------------------------------------------------------------
# Layout export
# ---------------------------------------------------------------------------

def export_layout(layout: WidgetLayout, fmt: str = "json") -> str:
    """
    Export layout to JSON or CSS Grid representation.
    fmt: 'json' | 'css' | 'html'
    """
    if fmt == "json":
        data = {
            "name": layout.name,
            "columns": layout.columns,
            "row_height": layout.row_height,
            "widgets": [serialize_widget(w) for w in layout.widgets],
        }
        return json.dumps(data, indent=2)

    elif fmt == "css":
        lines = [
            f"/* Layout: {layout.name} */",
            f".layout-{layout.name.replace(' ', '-').lower()} {{",
            f"  display: grid;",
            f"  grid-template-columns: repeat({layout.columns}, 1fr);",
            f"  row-gap: {layout.row_height}px;",
            "}",
            "",
        ]
        for w in layout.widgets:
            p = w.position
            cls = f".widget-{w.widget_id[:8]}"
            lines += [
                f"{cls} {{",
                f"  grid-column: {p.x + 1} / span {p.width};",
                f"  grid-row: {p.y + 1} / span {p.height};",
                "}",
                "",
            ]
        return "\n".join(lines)

    elif fmt == "html":
        rows = [
            f"<!-- Layout: {layout.name} -->",
            f'<div class="grid-layout" data-columns="{layout.columns}">',
        ]
        for w in layout.widgets:
            props = generate_react_props(w)
            style = (
                f"grid-column: {w.position.x + 1} / span {w.position.width}; "
                f"grid-row: {w.position.y + 1} / span {w.position.height};"
            )
            rows.append(
                f'  <div class="widget widget-{w.widget_type}" '
                f'data-id="{w.widget_id}" style="{style}">'
                f'<!-- {props["componentName"]} --></div>'
            )
        rows.append("</div>")
        return "\n".join(rows)

    else:
        raise ValueError(f"Unsupported export format: {fmt}. Use json, css, or html.")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="widget-factory",
        description="Widget Factory — blackroad-widget-factory",
    )
    p.add_argument("--db", default=str(DB_PATH))
    sub = p.add_subparsers(dest="command", required=True)

    # create-widget
    cw = sub.add_parser("create-widget", help="Create a widget")
    cw.add_argument("type", choices=sorted(WIDGET_TYPES))
    cw.add_argument("--label", default="")
    cw.add_argument("--config", default="{}", help="JSON config string")
    cw.add_argument("--x", type=int, default=0)
    cw.add_argument("--y", type=int, default=0)
    cw.add_argument("--width", type=int, default=4)
    cw.add_argument("--height", type=int, default=2)

    # get-widget
    gw = sub.add_parser("get-widget")
    gw.add_argument("widget_id")

    # delete-widget
    dw = sub.add_parser("delete-widget")
    dw.add_argument("widget_id")

    # validate
    val = sub.add_parser("validate")
    val.add_argument("widget_id")

    # react-props
    rp = sub.add_parser("react-props", help="Generate React props for a widget")
    rp.add_argument("widget_id")

    # create-layout
    cl = sub.add_parser("create-layout")
    cl.add_argument("name")
    cl.add_argument("--columns", type=int, default=12)

    # add-to-layout
    al = sub.add_parser("add-to-layout")
    al.add_argument("layout_name")
    al.add_argument("widget_id")

    # export-layout
    el = sub.add_parser("export-layout")
    el.add_argument("layout_name")
    el.add_argument("--format", default="json", choices=["json", "css", "html"])
    el.add_argument("--output", "-o")

    # list-layouts
    sub.add_parser("list-layouts")

    return p


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    conn = get_db(Path(args.db))

    if args.command == "create-widget":
        config = json.loads(args.config)
        w = Widget(
            widget_type=args.type,
            label=args.label,
            config=config,
            position=Position(x=args.x, y=args.y, width=args.width, height=args.height),
        )
        errors = validate_config(w)
        if errors:
            for e in errors:
                print(f"  Error: {e}", file=sys.stderr)
            sys.exit(1)
        save_widget(w, conn=conn)
        print(f"✓ Widget created: {w.widget_id} ({w.widget_type})")

    elif args.command == "get-widget":
        w = load_widget(args.widget_id, conn)
        if not w:
            print(f"Widget not found: {args.widget_id}", file=sys.stderr)
            sys.exit(1)
        print(json.dumps(serialize_widget(w), indent=2))

    elif args.command == "delete-widget":
        if delete_widget(args.widget_id, conn):
            print(f"✓ Deleted widget {args.widget_id}")
        else:
            print(f"Widget not found", file=sys.stderr); sys.exit(1)

    elif args.command == "validate":
        w = load_widget(args.widget_id, conn)
        if not w:
            print(f"Widget not found", file=sys.stderr); sys.exit(1)
        errors = validate_config(w)
        if errors:
            print(f"✗ {len(errors)} issue(s):"); [print(f"  - {e}") for e in errors]; sys.exit(1)
        else:
            print(f"✓ Widget {args.widget_id} is valid")

    elif args.command == "react-props":
        w = load_widget(args.widget_id, conn)
        if not w:
            print(f"Widget not found", file=sys.stderr); sys.exit(1)
        print(json.dumps(generate_react_props(w), indent=2))

    elif args.command == "create-layout":
        layout = WidgetLayout(name=args.name, columns=args.columns)
        save_layout(layout, conn)
        print(f"✓ Layout '{args.name}' created (id={layout.layout_id})")

    elif args.command == "add-to-layout":
        layout = load_layout(args.layout_name, conn)
        if not layout:
            print(f"Layout not found: {args.layout_name}", file=sys.stderr); sys.exit(1)
        w = load_widget(args.widget_id, conn)
        if not w:
            print(f"Widget not found: {args.widget_id}", file=sys.stderr); sys.exit(1)
        conn.execute("UPDATE widgets SET layout_id=? WHERE widget_id=?",
                     (layout.layout_id, args.widget_id))
        conn.commit()
        print(f"✓ Widget {args.widget_id} added to layout '{args.layout_name}'")

    elif args.command == "export-layout":
        layout = load_layout(args.layout_name, conn)
        if not layout:
            print(f"Layout not found", file=sys.stderr); sys.exit(1)
        content = export_layout(layout, fmt=args.format)
        if args.output:
            Path(args.output).write_text(content)
            print(f"✓ Exported to {args.output}")
        else:
            print(content)

    elif args.command == "list-layouts":
        layouts = list_layouts(conn)
        if not layouts:
            print("No layouts found.")
        for l in layouts:
            print(f"  {l['name']:<30} {l['widget_count']:3d} widgets  cols={l['columns']}")


if __name__ == "__main__":
    main()
