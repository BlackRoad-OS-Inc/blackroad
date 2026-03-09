"""Tests for BlackRoad Zero-Trust Security."""
import os, sys, pytest, json
from pathlib import Path
from datetime import datetime, timedelta

os.environ["ZT_DB"] = "/tmp/test_zt.db"
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))
from zero_trust import (
    get_conn, seed_demo, create_policy, issue_token, check_device,
    verify_access, get_segments, get_audit_log,
    Policy, AccessToken, DevicePosture, NetworkSegment, _now,
)

@pytest.fixture(autouse=True)
def fresh_db(tmp_path, monkeypatch):
    db = tmp_path / "zt.db"
    monkeypatch.setenv("ZT_DB", str(db))
    import zero_trust
    zero_trust.DB_PATH = db
    yield

def test_seed_creates_policies():
    conn = get_conn(); seed_demo(conn)
    rows = conn.execute("SELECT COUNT(*) FROM policies").fetchone()[0]
    assert rows == 5

def test_create_policy():
    conn = get_conn()
    p = create_policy(conn, "Test Policy", "agent:*", "resource:*", "allow", priority=60)
    assert p.policy_id.startswith("pol")
    assert p.effect == "allow"

def test_create_policy_invalid_effect():
    conn = get_conn()
    with pytest.raises(ValueError):
        create_policy(conn, "Bad", "*", "*", "invalid_action")

def test_issue_and_validate_token():
    conn = get_conn()
    raw, t = issue_token(conn, "agent:lucidia", scope="read,write")
    assert t.is_valid() is True
    assert t.ttl_seconds() > 0
    assert len(raw) > 10

def test_token_revocation():
    conn = get_conn()
    raw, t = issue_token(conn, "agent:test")
    conn.execute("UPDATE access_tokens SET revoked=1 WHERE token_id=?", (t.token_id,))
    conn.commit()
    row = conn.execute("SELECT * FROM access_tokens WHERE token_id=?", (t.token_id,)).fetchone()
    tok = AccessToken(**dict(row))
    assert tok.is_valid() is False

def test_device_posture_score():
    dp = DevicePosture(device_id="x", hostname="h", os_type="linux", os_version="22.04",
                       managed=True, encrypted=True, antivirus=True, patch_level="current",
                       last_checked=_now(), posture_score=0, compliance_tags="managed")
    assert dp.compute_score() == 100
    assert dp.risk_level() == "low"

def test_device_posture_non_compliant():
    dp = DevicePosture(device_id="x", hostname="h", os_type="linux", os_version="20.04",
                       managed=False, encrypted=False, antivirus=False, patch_level="outdated",
                       last_checked=_now(), posture_score=0, compliance_tags="")
    assert dp.compute_score() == 0
    assert dp.is_compliant() is False
    assert dp.risk_level() == "critical"

def test_network_segment_allows_traffic():
    s = NetworkSegment(segment_id="x", name="Internal", cidr="10.0.0.0/8", zone="trusted",
                       trust_level=90, allowed_protocols="tcp,udp", allowed_ports="80,443,8080",
                       ingress_rules="[]", egress_rules="[]", created_at=_now(), active=True)
    assert s.allows_traffic("tcp", 443) is True
    assert s.allows_traffic("tcp", 9999) is False
    assert s.allows_traffic("icmp", 443) is False

def test_verify_access_default_deny():
    conn = get_conn()
    result = verify_access(conn, "unknown:user", "secret:resource")
    assert result["result"] == "deny"

def test_audit_log_populated_on_verify():
    conn = get_conn(); seed_demo(conn)
    verify_access(conn, "agent:test", "gateway:test")
    logs = get_audit_log(conn, subject="agent:test")
    assert len(logs) >= 1
