"""Tests for blackroad-zone-manager."""
import json
import os
import sqlite3
import tempfile
from pathlib import Path

import pytest

# Ensure src is importable
import sys
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from main_module import (
    Zone, DnsRecord, get_db, save_zone, load_zone, list_zones, delete_zone,
    add_record, remove_record, validate_record, validate_zone,
    export_bind_format, import_zone_file, sync_with_provider, zone_checksum,
)


@pytest.fixture
def tmp_db(tmp_path):
    return get_db(tmp_path / "test.db")


@pytest.fixture
def sample_zone(tmp_db):
    zone = Zone(name="test.example.com", ttl=3600)
    save_zone(zone, tmp_db)
    return zone, tmp_db


def test_create_and_load_zone(tmp_db):
    zone = Zone(name="alpha.test", ttl=1800)
    save_zone(zone, tmp_db)
    assert zone.zone_id is not None

    loaded = load_zone("alpha.test", tmp_db)
    assert loaded is not None
    assert loaded.name == "alpha.test"
    assert loaded.ttl == 1800


def test_add_and_retrieve_record(sample_zone):
    zone, conn = sample_zone
    rec = add_record(zone, "A", "www", "93.184.216.34", ttl=300, conn=conn)
    assert rec.record_id is not None
    assert rec.record_type == "A"

    reloaded = load_zone(zone.name, conn)
    assert any(r.name == "www" and r.value == "93.184.216.34" for r in reloaded.records)


def test_validate_record_bad_ip():
    rec = DnsRecord(record_type="A", name="bad", value="999.999.999.999")
    errors = validate_record(rec)
    assert any("invalid" in e.lower() or "A" in e for e in errors)


def test_validate_record_missing_priority():
    rec = DnsRecord(record_type="MX", name="@", value="mail.example.com")
    errors = validate_record(rec)
    assert any("priority" in e.lower() for e in errors)


def test_validate_zone_missing_soa_ns(sample_zone):
    zone, _ = sample_zone
    errors = validate_zone(zone)
    assert any("SOA" in e for e in errors)
    assert any("NS" in e for e in errors)


def test_export_bind_format(sample_zone):
    zone, conn = sample_zone
    add_record(zone, "A", "@", "1.2.3.4", conn=conn)
    add_record(zone, "MX", "@", "mail.test.example.com.", priority=10, conn=conn)
    bind_text = export_bind_format(zone)
    assert "$ORIGIN" in bind_text
    assert "$TTL" in bind_text
    assert "1.2.3.4" in bind_text
    assert "MX" in bind_text


def test_import_zone_file(tmp_path, tmp_db):
    zone_content = """;; zone file
$ORIGIN importzone.example.
$TTL 3600
@ IN NS ns1.importzone.example.
@ IN A 10.0.0.1
www IN A 10.0.0.2
mail IN MX 10 smtp.importzone.example.
"""
    zone_file = tmp_path / "importzone.example.zone"
    zone_file.write_text(zone_content)
    zone = import_zone_file(str(zone_file))
    assert zone.name == "importzone.example"
    assert any(r.record_type == "A" for r in zone.records)


def test_sync_with_provider(sample_zone):
    zone, conn = sample_zone
    add_record(zone, "A", "web", "5.6.7.8", conn=conn)
    result = sync_with_provider(zone, provider="cloudflare", dry_run=True)
    assert result["provider"] == "cloudflare"
    assert result["dry_run"] is True
    assert "total_changes" in result


def test_zone_checksum_deterministic(sample_zone):
    zone, conn = sample_zone
    add_record(zone, "TXT", "@", "v=spf1 include:blackroad.io ~all", conn=conn)
    cs1 = zone_checksum(zone)
    cs2 = zone_checksum(zone)
    assert cs1 == cs2
    assert len(cs1) == 64  # SHA-256 hex


def test_delete_zone(tmp_db):
    zone = Zone(name="deleteme.test")
    save_zone(zone, tmp_db)
    assert load_zone("deleteme.test", tmp_db) is not None
    assert delete_zone("deleteme.test", tmp_db) is True
    assert load_zone("deleteme.test", tmp_db) is None


def test_remove_record(sample_zone):
    zone, conn = sample_zone
    rec = add_record(zone, "A", "sub", "192.168.1.1", conn=conn)
    assert any(r.record_id == rec.record_id for r in zone.records)
    removed = remove_record(zone, rec.record_id, conn=conn)
    assert removed is True
    assert not any(r.record_id == rec.record_id for r in zone.records)


def test_list_zones(tmp_db):
    Zone_a = Zone(name="aaaa.test"); save_zone(Zone_a, tmp_db)
    Zone_b = Zone(name="bbbb.test"); save_zone(Zone_b, tmp_db)
    zones = list_zones(tmp_db)
    names = [z["name"] for z in zones]
    assert "aaaa.test" in names
    assert "bbbb.test" in names
