"""Tests for BlackRoad Warehouse Robot Coordinator."""
import pytest
import os
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))
from warehouse_robot import RobotCoordinator, optimize_pick_sequence, pick_distance


@pytest.fixture
def coord():
    with tempfile.TemporaryDirectory() as d:
        db = os.path.join(d, "test.db")
        c = RobotCoordinator(db_path=db)
        c.add_zone("ZoneA", 1, 5, 1, 20)
        yield c


def test_pick_distance():
    d = pick_distance(1, 1, 3, 5)
    expected = abs(3-1)*3.0 + abs(5-1)*1.5
    assert abs(d - expected) < 1e-9


def test_add_zone(coord):
    z = coord.add_zone("ZoneB", 6, 10, 1, 20)
    assert z.name == "ZoneB"
    assert z.aisle_start == 6


def test_add_robot(coord):
    r = coord.add_robot("R001", "ZoneA")
    assert r.name == "R001"
    assert r.status == "idle"


def test_add_item(coord):
    item = coord.add_item("SKU001", "Widget A", "ZoneA", 2, 5, "A1", 100, 0.5)
    assert item.sku == "SKU001"
    assert item.aisle == 2


def test_create_pick_list(coord):
    coord.add_item("SKU001","Widget","ZoneA",1,1,"A1",50)
    coord.add_item("SKU002","Gadget","ZoneA",2,3,"B2",30)
    pl = coord.create_pick_list("ORD-001", [("SKU001",2),("SKU002",1)])
    assert pl.order_ref == "ORD-001"
    assert pl.total_items == 2


def test_assign_pick_list(coord):
    coord.add_item("SKU001","WidgetX","ZoneA",1,1,"A1",50)
    coord.add_item("SKU002","GadgetY","ZoneA",3,5,"C5",30)
    coord.add_robot("R001","ZoneA")
    pl = coord.create_pick_list("ORD-002",[("SKU001",1),("SKU002",1)])
    result = coord.assign_pick_list(pl.id)
    assert result is not None
    assert result.assigned_tasks == 2
    assert len(result.robots_used) >= 1


def test_complete_task(coord):
    coord.add_item("SKU003","ItemZ","ZoneA",2,2,"D3",20)
    coord.add_robot("R002","ZoneA")
    pl = coord.create_pick_list("ORD-003",[("SKU003",1)])
    coord.assign_pick_list(pl.id)
    # get the task id
    import sqlite3
    with sqlite3.connect(coord.db_path) as c:
        c.row_factory = sqlite3.Row
        task = c.execute("SELECT id FROM pick_tasks WHERE pick_list_id=?", (pl.id,)).fetchone()
    assert coord.complete_task(task["id"])


def test_optimize_sequence():
    tasks = [
        {"id":"t1","aisle":3,"shelf":5,"sku":"A"},
        {"id":"t2","aisle":1,"shelf":2,"sku":"B"},
        {"id":"t3","aisle":1,"shelf":8,"sku":"C"},
        {"id":"t4","aisle":2,"shelf":3,"sku":"D"},
    ]
    seq = optimize_pick_sequence(tasks, 1, 1)
    # Should be sorted by aisle first
    aisles = [t["aisle"] for t in seq]
    assert aisles == sorted(aisles)


def test_robot_status(coord):
    coord.add_robot("R003","ZoneA")
    rows = coord.robot_status()
    assert any(r["name"]=="R003" for r in rows)
    assert rows[0]["status"] == "idle"
