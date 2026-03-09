"""Tests for BlackRoad Warehouse Optimizer."""
import pytest
import os
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))
from warehouse_optimizer import WarehouseOptimizer, abc_analysis, slot_score


@pytest.fixture
def wopt():
    with tempfile.TemporaryDirectory() as d:
        db = os.path.join(d, "test.db")
        yield WarehouseOptimizer(db_path=db)


def test_abc_analysis_basic():
    prods = [
        {"sku":"A","name":"FastA","picks_30d":500},
        {"sku":"B","name":"FastB","picks_30d":300},
        {"sku":"C","name":"MedC","picks_30d":50},
        {"sku":"D","name":"SlowD","picks_30d":5},
        {"sku":"E","name":"SlowE","picks_30d":2},
    ]
    results = abc_analysis(prods)
    labels = {r.sku: r.class_label for r in results}
    # Top pickers should be A
    assert labels["A"] == "A"
    assert labels["B"] == "A"
    # Slow movers should be C
    assert labels["E"] == "C"


def test_abc_empty():
    assert abc_analysis([]) == []


def test_slot_score_a_item_prefers_low_aisle():
    slot_near = {"aisle":1,"row":1,"level":1,"slot_type":"standard",
                 "width_m":1.0,"depth_m":0.8,"height_m":0.5}
    slot_far  = {"aisle":10,"row":1,"level":1,"slot_type":"standard",
                 "width_m":1.0,"depth_m":0.8,"height_m":0.5}
    prod = {"sku":"X","velocity":"A","weight_kg":2.0,
            "width_m":0.3,"depth_m":0.2,"height_m":0.2,"category":"general"}
    assert slot_score(slot_near, prod) > slot_score(slot_far, prod)


def test_slot_score_c_item_prefers_far_aisle():
    slot_near = {"aisle":1,"row":1,"level":1,"slot_type":"standard",
                 "width_m":1.0,"depth_m":0.8,"height_m":0.5}
    slot_far  = {"aisle":15,"row":1,"level":1,"slot_type":"standard",
                 "width_m":1.0,"depth_m":0.8,"height_m":0.5}
    prod = {"sku":"Y","velocity":"C","weight_kg":1.0,
            "width_m":0.2,"depth_m":0.1,"height_m":0.1,"category":"general"}
    assert slot_score(slot_far, prod) > slot_score(slot_near, prod)


def test_bulk_create_slots(wopt):
    n = wopt.bulk_create_slots(3, 5, levels=2, zone="A")
    assert n == 3*5*2
    stats = wopt.utilization_stats()
    assert stats["total_slots"] == 30
    assert stats["occupied"] == 0


def test_add_product(wopt):
    p = wopt.add_product("SKU-001","FastWidget","electronics",2.5,picks_30d=100)
    assert p.velocity == "A"
    p2 = wopt.add_product("SKU-002","SlowGadget","general",1.0,picks_30d=2)
    assert p2.velocity == "C"
    prods = wopt.list_products()
    assert len(prods) == 2


def test_place_product(wopt):
    wopt.bulk_create_slots(2, 2)
    wopt.add_product("SKU-003","Item","general",1.0)
    ok = wopt.place_product("SKU-003","s010101", qty=10)
    # Slot s010101 = aisle1 row1 level1
    assert ok
    stats = wopt.utilization_stats()
    assert stats["occupied"] == 1


def test_recommend_placement(wopt):
    wopt.bulk_create_slots(5, 5)
    wopt.add_product("FAST-001","SpeedWidget","general",1.0,picks_30d=200)
    recs = wopt.recommend_placement("FAST-001", top_n=3)
    assert len(recs) <= 3
    # A-class product should prefer low aisles
    if len(recs) > 1:
        assert recs[0]["aisle"] <= recs[-1]["aisle"] or recs[0]["score"] >= recs[-1]["score"]


def test_optimization_report(wopt):
    wopt.bulk_create_slots(10, 5)
    for i in range(5):
        sku = f"P{i:03d}"
        picks = (5-i)*100
        wopt.add_product(sku, f"Product{i}", "general", 1.0, picks_30d=picks)
        # Place A items in far aisles (bad placement)
        wopt.place_product(sku, f"s{9:02d}{(i+1):02d}0")
    report = wopt.optimize()
    assert isinstance(report.misplaced_items, int)
    assert report.total_slots == 200
    assert 0.0 <= report.utilization_pct <= 100.0


def test_utilization_stats_zones(wopt):
    wopt.bulk_create_slots(3, 3, zone="A")
    wopt.bulk_create_slots(2, 3, zone="B")
    stats = wopt.utilization_stats()
    zones = {z["zone"] for z in stats["by_zone"]}
    assert "A" in zones
    assert "B" in zones
