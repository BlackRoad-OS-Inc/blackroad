"""Tests for blackroad-widget-factory."""
import json
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from main_module import (
    Widget, WidgetLayout, Position, get_db,
    save_widget, load_widget, delete_widget,
    save_layout, load_layout, list_layouts,
    serialize_widget, deserialize_widget,
    generate_react_props, validate_config, export_layout,
)


@pytest.fixture
def tmp_db(tmp_path):
    return get_db(tmp_path / "widgets_test.db")


@pytest.fixture
def button_widget():
    return Widget(
        widget_type="button",
        label="Submit",
        config={"label": "Submit", "variant": "primary", "disabled": False},
        position=Position(x=0, y=0, width=3, height=1),
    )


def test_create_and_load_widget(tmp_db, button_widget):
    save_widget(button_widget, conn=tmp_db)
    assert button_widget.db_id is not None

    loaded = load_widget(button_widget.widget_id, tmp_db)
    assert loaded is not None
    assert loaded.widget_type == "button"
    assert loaded.config["label"] == "Submit"


def test_serialize_deserialize(button_widget):
    data = serialize_widget(button_widget)
    assert data["widget_type"] == "button"
    assert "position" in data
    assert data["position"]["width"] == 3

    restored = deserialize_widget(data)
    assert restored.widget_id == button_widget.widget_id
    assert restored.position.width == 3


def test_deserialize_from_json_string(button_widget):
    json_str = json.dumps(serialize_widget(button_widget))
    restored = deserialize_widget(json_str)
    assert restored.widget_type == "button"


def test_validate_config_valid(button_widget):
    errors = validate_config(button_widget)
    assert errors == []


def test_validate_config_unknown_type():
    w = Widget(widget_type="nonexistent", config={})
    errors = validate_config(w)
    assert any("Unknown widget type" in e for e in errors)


def test_validate_config_overflow():
    w = Widget(widget_type="button", config={}, position=Position(x=10, y=0, width=5, height=1))
    errors = validate_config(w)
    assert any("overflows" in e for e in errors)


def test_generate_react_props(button_widget):
    props = generate_react_props(button_widget)
    assert props["componentName"] == "Button"
    assert "props" in props
    assert "propTypes" in props
    assert "defaultProps" in props
    assert props["props"]["id"] == button_widget.widget_id


def test_generate_react_props_chart():
    w = Widget(
        widget_type="chart",
        config={"chartType": "bar", "data": [], "title": "Sales", "showLegend": True},
    )
    props = generate_react_props(w)
    assert props["componentName"] == "Chart"
    assert "propTypes" in props


def test_create_layout_and_add_widget(tmp_db, button_widget):
    layout = WidgetLayout(name="dashboard", columns=12)
    save_layout(layout, tmp_db)
    assert layout.layout_id is not None

    layout.widgets.append(button_widget)
    save_layout(layout, tmp_db)

    loaded = load_layout("dashboard", tmp_db)
    assert loaded is not None
    assert len(loaded.widgets) == 1
    assert loaded.widgets[0].widget_type == "button"


def test_export_layout_json(tmp_db, button_widget):
    layout = WidgetLayout(name="json_layout", widgets=[button_widget])
    save_layout(layout, tmp_db)
    output = export_layout(layout, fmt="json")
    data = json.loads(output)
    assert data["name"] == "json_layout"
    assert len(data["widgets"]) == 1


def test_export_layout_css(tmp_db, button_widget):
    layout = WidgetLayout(name="css_layout", widgets=[button_widget])
    output = export_layout(layout, fmt="css")
    assert "grid-template-columns" in output
    assert "grid-column" in output


def test_export_layout_html(tmp_db, button_widget):
    layout = WidgetLayout(name="html_layout", widgets=[button_widget])
    output = export_layout(layout, fmt="html")
    assert "<div" in output
    assert "grid-layout" in output


def test_delete_widget(tmp_db, button_widget):
    save_widget(button_widget, conn=tmp_db)
    assert load_widget(button_widget.widget_id, tmp_db) is not None
    delete_widget(button_widget.widget_id, tmp_db)
    assert load_widget(button_widget.widget_id, tmp_db) is None


def test_list_layouts(tmp_db):
    for name in ["layout_a", "layout_b"]:
        save_layout(WidgetLayout(name=name), tmp_db)
    layouts = list_layouts(tmp_db)
    names = [l["name"] for l in layouts]
    assert "layout_a" in names and "layout_b" in names
