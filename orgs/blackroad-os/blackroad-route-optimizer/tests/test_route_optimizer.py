"""Tests for BlackRoad Route Optimizer."""
import pytest
import math
import os
import sys
import tempfile

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))
from route_optimizer import (
    RouteOptimizer, Location, nearest_neighbor,
    two_opt, tour_distance, build_matrix, or_opt
)


@pytest.fixture
def tmp_opt():
    with tempfile.TemporaryDirectory() as d:
        db = os.path.join(d, "test.db")
        yield RouteOptimizer(db_path=db)


def test_location_haversine():
    nyc = Location(id="nyc", name="NYC", lat=40.7128, lon=-74.0060)
    la  = Location(id="la",  name="LA",  lat=34.0522, lon=-118.2437)
    dist = nyc.dist_km(la)
    # ~3940 km; allow 5% tolerance
    assert 3700 < dist < 4200


def test_location_same_point():
    loc = Location(id="a", name="A", lat=10.0, lon=20.0)
    assert loc.dist_km(loc) < 0.001


def test_build_matrix():
    locs = [
        Location("a","A",0.0,0.0), Location("b","B",0.0,1.0), Location("c","C",1.0,0.0)
    ]
    m = build_matrix(locs)
    assert len(m) == 3
    assert m[0][0] == 0.0
    assert m[0][1] == m[1][0]  # symmetric


def test_nearest_neighbor():
    locs = [
        Location("d","Depot",0.0,0.0),
        Location("a","A",1.0,0.0),
        Location("b","B",2.0,0.0),
    ]
    m = build_matrix(locs)
    tour = nearest_neighbor(0, [1,2], m)
    assert tour[0] == 0
    assert tour[-1] == 0
    assert set(tour[1:-1]) == {1, 2}


def test_two_opt_improves_or_equal():
    locs = [Location(f"l{i}",f"L{i}",float(i),float((i*37)%10)) for i in range(6)]
    m = build_matrix(locs)
    nn = nearest_neighbor(0, list(range(1,6)), m)
    d_before = tour_distance(nn, m)
    optimized, _ = two_opt(nn, m)
    d_after = tour_distance(optimized, m)
    assert d_after <= d_before + 1e-9


def test_or_opt_does_not_worsen():
    locs = [Location(f"l{i}",f"L{i}",float(i%3),float(i//3)) for i in range(5)]
    m = build_matrix(locs)
    nn = nearest_neighbor(0, [1,2,3,4], m)
    d_before = tour_distance(nn, m)
    improved = or_opt(nn, m)
    d_after = tour_distance(improved, m)
    assert d_after <= d_before + 1e-9


def test_add_location(tmp_opt):
    loc = tmp_opt.add_location("Warehouse", 40.7128, -74.0060, is_depot=True)
    assert loc.name == "Warehouse"
    assert loc.is_depot
    locs = tmp_opt.list_locations()
    assert len(locs) == 1


def test_optimize_full_pipeline(tmp_opt):
    tmp_opt.add_location("Depot", 40.7128, -74.0060, is_depot=True)
    tmp_opt.add_location("Stop1", 40.73, -74.01)
    tmp_opt.add_location("Stop2", 40.72, -73.99)
    tmp_opt.add_location("Stop3", 40.71, -74.02)
    tmp_opt.add_vehicle("Truck1", 1000.0)
    tmp_opt.add_delivery("Stop1", 50.0)
    tmp_opt.add_delivery("Stop2", 30.0)
    tmp_opt.add_delivery("Stop3", 40.0)
    result = tmp_opt.optimize("Truck1")
    assert result is not None
    assert result.stops == 3
    assert result.distance_after_km > 0
    assert result.improvement_pct >= 0


def test_compare_algorithms(tmp_opt):
    tmp_opt.add_location("Depot", 0.0, 0.0, is_depot=True)
    for i in range(5):
        tmp_opt.add_location(f"S{i}", float(i)*0.1, float(i)*0.05)
    r = tmp_opt.compare_algorithms()
    assert "nn_distance_km" in r
    assert "2opt_distance_km" in r
    assert r["2opt_distance_km"] <= r["nn_distance_km"] + 0.001
