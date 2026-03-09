"""Tests for BlackRoad Vehicle Maintenance."""
import pytest
import os
import sys
import tempfile
from datetime import datetime, timedelta

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'src'))
from vehicle_maintenance import MaintenanceManager, ServiceAlert


@pytest.fixture
def mgr():
    with tempfile.TemporaryDirectory() as d:
        db = os.path.join(d, "test.db")
        yield MaintenanceManager(db_path=db)


def test_add_vehicle(mgr):
    v = mgr.add_vehicle("TruckAlpha","Ford","Transit",2020,"VIN123",50000.0,"diesel")
    assert v.name == "TruckAlpha"
    assert v.year == 2020
    vlist = mgr.list_vehicles()
    assert len(vlist) == 1


def test_record_service(mgr):
    mgr.add_vehicle("VanBeta","Mercedes","Sprinter",2019,"VIN456",80000.0)
    rec = mgr.record_service("VanBeta","Oil Change",80500.0,85.0,"Bob","Routine","Filter")
    assert rec.cost == 85.0
    hist = mgr.service_history("VanBeta")
    assert len(hist) == 1
    assert hist[0]["service"] == "Oil Change"


def test_odometer_update(mgr):
    mgr.add_vehicle("CarGamma","Toyota","Corolla",2022,"VIN789",10000.0)
    mgr.update_odometer("CarGamma", 15000.0)
    vlist = mgr.list_vehicles()
    v = next(x for x in vlist if x["name"]=="CarGamma")
    assert v["odometer_km"] == 15000.0


def test_alerts_overdue(mgr):
    mgr.add_vehicle("TruckDelta","Volvo","FH",2018,"VIN101",200000.0)
    # Record oil change far in the past (odometer 100k below current)
    mgr.record_service("TruckDelta","Oil Change",190000.0,90.0)
    # now at 200k → 10k since last change, interval is 10k → exactly due
    alerts = mgr.get_alerts("TruckDelta")
    oil_alert = next((a for a in alerts if a.service_type=="Oil Change"), None)
    assert oil_alert is not None


def test_cost_analysis(mgr):
    mgr.add_vehicle("BusEpsilon","Scania","Citywide",2017,"VIN202",300000.0)
    mgr.record_service("BusEpsilon","Oil Change",295000.0,80.0)
    mgr.record_service("BusEpsilon","Brake Inspection",296000.0,150.0)
    ca = mgr.cost_analysis("BusEpsilon")
    assert ca.total_services == 2
    assert ca.total_cost == 230.0
    assert ca.most_expensive_service == "Brake Inspection"


def test_schedule_forecast(mgr):
    mgr.add_vehicle("VanZeta","VW","Transporter",2021,"VIN303",40000.0)
    # No service yet → all services upcoming within 20k km
    forecasts = mgr.schedule_forecast("VanZeta", horizon_km=20000)
    assert isinstance(forecasts, list)
    # At 40k km, oil change (interval 10k) should show as overdue / due
    oil = next((f for f in forecasts if f["service"]=="Oil Change"), None)
    assert oil is not None


def test_multiple_vehicles_alerts(mgr):
    mgr.add_vehicle("V1","Ford","F150",2020,"V1VIN",50000.0)
    mgr.add_vehicle("V2","GM","Sierra",2019,"V2VIN",80000.0)
    alerts = mgr.get_alerts()
    vehicle_names = {a.vehicle_name for a in alerts}
    assert "V1" in vehicle_names
    assert "V2" in vehicle_names
