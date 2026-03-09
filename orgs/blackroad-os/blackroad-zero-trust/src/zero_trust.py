#!/usr/bin/env python3
"""BlackRoad Zero-Trust Security — policy engine, access tokens, device posture checks, network segmentation, audit log."""

from __future__ import annotations
import argparse, base64, hashlib, hmac, json, os, random, re, secrets, sqlite3, sys, time
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional

R="\033[0;31m"; G="\033[0;32m"; Y="\033[1;33m"; C="\033[0;36m"
B="\033[0;34m"; M="\033[0;35m"; W="\033[1;37m"; DIM="\033[2m"; NC="\033[0m"; BOLD="\033[1m"

DB_PATH = Path(os.environ.get("ZT_DB", Path.home() / ".blackroad" / "zero_trust.db"))

TOKEN_EXPIRY_SECONDS = 3600
POSTURE_SCORE_THRESHOLD = 60
POLICY_ACTIONS = ["allow", "deny", "mfa", "audit"]
RISK_LEVELS = ["low", "medium", "high", "critical"]

@dataclass
class Policy:
    policy_id: str
    name: str
    description: str
    subject: str
    resource: str
    action: str
    conditions: str
    effect: str
    priority: int
    enabled: bool
    created_at: str
    updated_at: str

    def conditions_dict(self):
        try: return json.loads(self.conditions)
        except: return {}

    def evaluate(self, context: dict) -> bool:
        if not self.enabled: return False
        conds = self.conditions_dict()
        for k, v in conds.items():
            if context.get(k) != v: return False
        return True

@dataclass
class AccessToken:
    token_id: str
    subject: str
    audience: str
    scope: str
    issued_at: str
    expires_at: str
    token_hash: str
    revoked: bool
    device_id: str
    risk_level: str

    def is_valid(self) -> bool:
        if self.revoked: return False
        try:
            exp = datetime.fromisoformat(self.expires_at)
            return datetime.utcnow() < exp
        except: return False

    def ttl_seconds(self) -> float:
        try:
            exp = datetime.fromisoformat(self.expires_at)
            return max(0.0, (exp - datetime.utcnow()).total_seconds())
        except: return 0.0

@dataclass
class DevicePosture:
    device_id: str
    hostname: str
    os_type: str
    os_version: str
    managed: bool
    encrypted: bool
    antivirus: bool
    patch_level: str
    last_checked: str
    posture_score: int
    compliance_tags: str

    def is_compliant(self) -> bool:
        return self.posture_score >= POSTURE_SCORE_THRESHOLD

    def risk_level(self) -> str:
        s = self.posture_score
        if s >= 90: return "low"
        if s >= 70: return "medium"
        if s >= 50: return "high"
        return "critical"

    def compute_score(self) -> int:
        score = 0
        if self.managed:   score += 25
        if self.encrypted: score += 25
        if self.antivirus: score += 20
        if self.patch_level == "current": score += 30
        elif self.patch_level == "minor":  score += 15
        return min(100, score)

@dataclass
class NetworkSegment:
    segment_id: str
    name: str
    cidr: str
    zone: str
    trust_level: int
    allowed_protocols: str
    allowed_ports: str
    ingress_rules: str
    egress_rules: str
    created_at: str
    active: bool

    def protocol_list(self): return [p.strip() for p in self.allowed_protocols.split(",") if p.strip()]
    def port_list(self): return [int(p) for p in self.allowed_ports.split(",") if p.strip().isdigit()]

    def allows_traffic(self, protocol: str, port: int) -> bool:
        if protocol not in self.protocol_list(): return False
        ports = self.port_list()
        return port in ports if ports else True

@dataclass
class AuditLog:
    log_id: str
    timestamp: str
    subject: str
    action: str
    resource: str
    result: str
    policy_id: str
    device_id: str
    ip_address: str
    risk_score: int
    details: str

def get_conn():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(DB_PATH))
    conn.row_factory = sqlite3.Row
    _init_db(conn)
    return conn

def _init_db(conn):
    conn.executescript("""
    CREATE TABLE IF NOT EXISTS policies (
        policy_id   TEXT PRIMARY KEY,
        name        TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        subject     TEXT NOT NULL DEFAULT '*',
        resource    TEXT NOT NULL DEFAULT '*',
        action      TEXT NOT NULL DEFAULT 'allow',
        conditions  TEXT NOT NULL DEFAULT '{}',
        effect      TEXT NOT NULL DEFAULT 'allow',
        priority    INTEGER NOT NULL DEFAULT 50,
        enabled     INTEGER NOT NULL DEFAULT 1,
        created_at  TEXT NOT NULL,
        updated_at  TEXT NOT NULL
    );
    CREATE TABLE IF NOT EXISTS access_tokens (
        token_id   TEXT PRIMARY KEY,
        subject    TEXT NOT NULL,
        audience   TEXT NOT NULL DEFAULT '',
        scope      TEXT NOT NULL DEFAULT '',
        issued_at  TEXT NOT NULL,
        expires_at TEXT NOT NULL,
        token_hash TEXT NOT NULL,
        revoked    INTEGER NOT NULL DEFAULT 0,
        device_id  TEXT NOT NULL DEFAULT '',
        risk_level TEXT NOT NULL DEFAULT 'low'
    );
    CREATE TABLE IF NOT EXISTS device_posture (
        device_id       TEXT PRIMARY KEY,
        hostname        TEXT NOT NULL,
        os_type         TEXT NOT NULL DEFAULT 'unknown',
        os_version      TEXT NOT NULL DEFAULT 'unknown',
        managed         INTEGER NOT NULL DEFAULT 0,
        encrypted       INTEGER NOT NULL DEFAULT 0,
        antivirus       INTEGER NOT NULL DEFAULT 0,
        patch_level     TEXT NOT NULL DEFAULT 'unknown',
        last_checked    TEXT NOT NULL,
        posture_score   INTEGER NOT NULL DEFAULT 0,
        compliance_tags TEXT NOT NULL DEFAULT ''
    );
    CREATE TABLE IF NOT EXISTS network_segments (
        segment_id         TEXT PRIMARY KEY,
        name               TEXT NOT NULL,
        cidr               TEXT NOT NULL,
        zone               TEXT NOT NULL DEFAULT 'untrusted',
        trust_level        INTEGER NOT NULL DEFAULT 0,
        allowed_protocols  TEXT NOT NULL DEFAULT 'tcp',
        allowed_ports      TEXT NOT NULL DEFAULT '',
        ingress_rules      TEXT NOT NULL DEFAULT '[]',
        egress_rules       TEXT NOT NULL DEFAULT '[]',
        created_at         TEXT NOT NULL,
        active             INTEGER NOT NULL DEFAULT 1
    );
    CREATE TABLE IF NOT EXISTS audit_logs (
        log_id     TEXT PRIMARY KEY,
        timestamp  TEXT NOT NULL,
        subject    TEXT NOT NULL,
        action     TEXT NOT NULL,
        resource   TEXT NOT NULL,
        result     TEXT NOT NULL DEFAULT 'deny',
        policy_id  TEXT NOT NULL DEFAULT '',
        device_id  TEXT NOT NULL DEFAULT '',
        ip_address TEXT NOT NULL DEFAULT '',
        risk_score INTEGER NOT NULL DEFAULT 0,
        details    TEXT NOT NULL DEFAULT ''
    );
    """)
    conn.commit()

def _now(): return datetime.utcnow().isoformat(timespec="seconds")
def _uid(p=""): return p + hashlib.sha1(f"{p}{time.time_ns()}{random.random()}".encode()).hexdigest()[:10]

def _hash_token(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()

def seed_demo(conn):
    if conn.execute("SELECT COUNT(*) FROM policies").fetchone()[0] > 0:
        return
    now = _now()
    for pid, name, subj, res, effect, prio, conds in [
        ("pol-allow-agents",  "Allow Agent Traffic",     "agent:*",    "gateway:*",  "allow",  90, '{"verified": true}'),
        ("pol-deny-external", "Deny External Untrusted", "external:*", "*",          "deny",   95, '{"zone": "untrusted"}'),
        ("pol-audit-admin",   "Audit Admin Actions",     "admin:*",    "config:*",   "audit",  80, '{}'),
        ("pol-mfa-billing",   "MFA for Billing",         "*",          "billing:*",  "mfa",    85, '{}'),
        ("pol-allow-internal","Allow Internal Services", "service:*",  "internal:*", "allow",  70, '{"managed": true}'),
    ]:
        conn.execute("INSERT INTO policies VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                     (pid, name, "", subj, res, effect, conds, effect, prio, 1, now, now))
    for did, host, ost, enc, av, pl, tags in [
        ("dev-octavia",  "octavia-pi",    "linux", True,  True,  "current", "managed,encrypted"),
        ("dev-lucidia",  "lucidia-pi",    "linux", True,  False, "minor",   "managed"),
        ("dev-shellfish","shellfish-drop","linux", False, True,  "outdated",""),
        ("dev-alice",    "alice-cloud",   "linux", True,  True,  "current", "managed,encrypted,antivirus"),
    ]:
        score = DevicePosture(did, host, ost, "22.04", True, enc, av, pl,
                              now, 0, tags).compute_score()
        conn.execute("INSERT INTO device_posture VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                     (did, host, ost, "22.04", 1, int(enc), int(av), pl, now, score, tags))
    for sid, name, cidr, zone, trust, protos, ports in [
        ("seg-internal",  "Internal Network",  "10.0.0.0/8",     "trusted",   90, "tcp,udp",  "80,443,8080,8787"),
        ("seg-pi-lan",    "Pi Local Network",  "192.168.4.0/24", "trusted",   85, "tcp,udp",  "22,80,443,8787"),
        ("seg-dmz",       "DMZ",               "172.16.0.0/12",  "restricted",40, "tcp",       "80,443"),
        ("seg-external",  "External Internet", "0.0.0.0/0",      "untrusted", 0,  "tcp",       "443"),
    ]:
        conn.execute("INSERT INTO network_segments VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                     (sid, name, cidr, zone, trust, protos, ports, "[]", "[]", now, 1))
    for i in range(10):
        result = random.choice(["allow","deny","deny","audit"])
        conn.execute("INSERT INTO audit_logs VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                     (_uid("al"), now, f"agent-{i:03d}", random.choice(["read","write","exec"]),
                      random.choice(["gateway","config","billing"]), result,
                      "pol-allow-agents", f"dev-{i:03d}", f"10.0.{i}.1",
                      random.randint(0, 80), json.dumps({"attempt": i})))
    conn.commit()

def create_policy(conn, name, subject, resource, effect, conditions=None, priority=50):
    if effect not in POLICY_ACTIONS:
        raise ValueError(f"Effect must be one of {POLICY_ACTIONS}")
    now = _now(); pid = _uid("pol")
    p = Policy(policy_id=pid, name=name, description="", subject=subject, resource=resource,
               action=effect, conditions=json.dumps(conditions or {}), effect=effect,
               priority=priority, enabled=True, created_at=now, updated_at=now)
    conn.execute("INSERT INTO policies VALUES (?,?,?,?,?,?,?,?,?,?,?,?)",
                 (p.policy_id, p.name, p.description, p.subject, p.resource, p.action,
                  p.conditions, p.effect, p.priority, int(p.enabled), p.created_at, p.updated_at))
    conn.commit(); return p

def issue_token(conn, subject, audience="", scope="", device_id="", risk_level="low") -> tuple[str, AccessToken]:
    now = _now()
    raw = secrets.token_urlsafe(32)
    exp = (datetime.utcnow() + timedelta(seconds=TOKEN_EXPIRY_SECONDS)).isoformat(timespec="seconds")
    thash = _hash_token(raw)
    tid = _uid("tok")
    t = AccessToken(token_id=tid, subject=subject, audience=audience, scope=scope,
                    issued_at=now, expires_at=exp, token_hash=thash,
                    revoked=False, device_id=device_id, risk_level=risk_level)
    conn.execute("INSERT INTO access_tokens VALUES (?,?,?,?,?,?,?,?,?,?)",
                 (t.token_id, t.subject, t.audience, t.scope, t.issued_at, t.expires_at,
                  t.token_hash, int(t.revoked), t.device_id, t.risk_level))
    conn.commit()
    _write_audit(conn, subject, "issue_token", "access_tokens", "allow", "", device_id, "", 0)
    return raw, t

def check_device(conn, device_id) -> Optional[DevicePosture]:
    row = conn.execute("SELECT * FROM device_posture WHERE device_id=?", (device_id,)).fetchone()
    if not row: return None
    return DevicePosture(**dict(row))

def verify_access(conn, subject, resource, device_id="", context=None) -> dict:
    ctx = context or {}
    if device_id:
        dp = check_device(conn, device_id)
        if dp:
            ctx["managed"] = bool(dp.managed)
            ctx["posture_score"] = dp.posture_score
            ctx["zone"] = "trusted" if dp.is_compliant() else "untrusted"

    rows = conn.execute("""
        SELECT * FROM policies WHERE enabled=1
        AND (subject='*' OR subject=? OR subject LIKE ?)
        ORDER BY priority DESC
    """, (subject, f"{subject.split(':')[0]}:*")).fetchall()

    for row in rows:
        p = Policy(**dict(row))
        res_match = (p.resource == "*" or p.resource == resource
                     or resource.startswith(p.resource.rstrip("*")))
        if res_match and p.evaluate(ctx):
            result = p.effect
            _write_audit(conn, subject, "access", resource, result, p.policy_id, device_id, "", 0, ctx)
            return {"result": result, "policy": p.policy_id, "policy_name": p.name}

    _write_audit(conn, subject, "access", resource, "deny", "", device_id, "", 50, ctx)
    return {"result": "deny", "policy": None, "policy_name": "default-deny"}

def get_segments(conn) -> list[NetworkSegment]:
    rows = conn.execute("SELECT * FROM network_segments WHERE active=1 ORDER BY trust_level DESC").fetchall()
    return [NetworkSegment(**dict(r)) for r in rows]

def get_audit_log(conn, limit=50, subject=None, result=None) -> list[AuditLog]:
    q = "SELECT * FROM audit_logs WHERE 1=1"
    params = []
    if subject: q += " AND subject=?"; params.append(subject)
    if result:  q += " AND result=?";  params.append(result)
    q += " ORDER BY timestamp DESC LIMIT ?"; params.append(limit)
    rows = conn.execute(q, params).fetchall()
    return [AuditLog(**dict(r)) for r in rows]

def _write_audit(conn, subject, action, resource, result, policy_id="", device_id="",
                 ip="", risk_score=0, details=None):
    conn.execute("INSERT INTO audit_logs VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                 (_uid("al"), _now(), subject, action, resource, result,
                  policy_id, device_id, ip, risk_score, json.dumps(details or {})))
    conn.commit()

def _header(title):
    print(f"\n{B}{'─'*64}{NC}\n{W}{BOLD}  {title}{NC}\n{B}{'─'*64}{NC}")

EFFECT_COL = {"allow":G, "deny":R, "mfa":Y, "audit":C}
RISK_COL   = {"low":G, "medium":Y, "high":R, "critical":M}

def cmd_policy(args):
    conn = get_conn(); seed_demo(conn)
    if args.create:
        try:
            p = create_policy(conn, args.name or "New Policy", args.subject or "*",
                              args.resource or "*", args.create, priority=args.priority or 50)
            _header("Policy Created")
            print(f"  {G}✓{NC} {W}{p.policy_id}{NC}  {p.name}")
            print(f"  {C}→{NC} Effect:{EFFECT_COL.get(p.effect,NC)}{p.effect}{NC}  Subject:{p.subject}  Resource:{p.resource}")
        except ValueError as e:
            print(f"{R}✗ {e}{NC}", file=sys.stderr); sys.exit(1)
    else:
        rows = conn.execute("SELECT * FROM policies WHERE enabled=1 ORDER BY priority DESC").fetchall()
        _header(f"Policies  [{len(rows)} active]")
        for r in rows:
            ec = EFFECT_COL.get(r["effect"], NC)
            print(f"  {ec}●{NC} p={r['priority']:>3}  {r['name']:<30}  "
                  f"{ec}{r['effect']:<6}{NC}  {DIM}{r['subject']} → {r['resource']}{NC}")
    print()

def cmd_token(args):
    conn = get_conn(); seed_demo(conn)
    if args.issue:
        raw, t = issue_token(conn, args.issue, audience=args.audience or "",
                             scope=args.scope or "", device_id=args.device or "")
        _header("Token Issued")
        print(f"  {G}✓{NC} Token ID : {W}{t.token_id}{NC}")
        print(f"  {C}→{NC} Subject  : {t.subject}")
        print(f"  {C}→{NC} Expires  : {t.expires_at}  (TTL {t.ttl_seconds():.0f}s)")
        print(f"  {C}→{NC} Raw Token: {Y}{raw[:20]}...{NC}  (store securely!)")
    elif args.revoke:
        conn.execute("UPDATE access_tokens SET revoked=1 WHERE token_id=?", (args.revoke,))
        conn.commit()
        print(f"{G}✓{NC} Token {args.revoke} revoked.")
    else:
        rows = conn.execute("SELECT * FROM access_tokens WHERE revoked=0 ORDER BY issued_at DESC LIMIT 20").fetchall()
        _header(f"Active Tokens  [{len(rows)}]")
        for r in rows:
            t = AccessToken(**dict(r)); valid = t.is_valid()
            vc = G if valid else R
            print(f"  {vc}●{NC} {r['token_id']:<14}  {r['subject']:<16}  "
                  f"ttl:{t.ttl_seconds():.0f}s  risk:{RISK_COL.get(r['risk_level'],NC)}{r['risk_level']}{NC}")
    print()

def cmd_device(args):
    conn = get_conn(); seed_demo(conn)
    if args.device_id:
        dp = check_device(conn, args.device_id)
        if not dp: print(f"{R}✗ Device '{args.device_id}' not found{NC}"); sys.exit(1)
        _header(f"Device Posture — {dp.hostname}")
        sc = G if dp.is_compliant() else R
        print(f"  Hostname   : {W}{dp.hostname}{NC}")
        print(f"  OS         : {dp.os_type} {dp.os_version}")
        print(f"  Score      : {sc}{dp.posture_score}/100{NC}  risk:{RISK_COL.get(dp.risk_level(),NC)}{dp.risk_level()}{NC}")
        print(f"  Compliant  : {G+'yes' if dp.is_compliant() else R+'NO'}{NC}")
        print(f"  Managed    : {G+'yes' if dp.managed else R+'no'}{NC}")
        print(f"  Encrypted  : {G+'yes' if dp.encrypted else R+'no'}{NC}")
        print(f"  Antivirus  : {G+'yes' if dp.antivirus else R+'no'}{NC}")
        print(f"  Patch Level: {dp.patch_level}")
    else:
        rows = conn.execute("SELECT * FROM device_posture ORDER BY posture_score DESC").fetchall()
        _header(f"Devices  [{len(rows)}]")
        for r in rows:
            dp = DevicePosture(**dict(r))
            sc = G if dp.is_compliant() else R
            print(f"  {sc}●{NC} {r['device_id']:<16}  {r['hostname']:<18}  "
                  f"score:{sc}{r['posture_score']:>3}{NC}  {RISK_COL.get(dp.risk_level(),NC)}{dp.risk_level()}{NC}")
    print()

def cmd_segment(args):
    conn = get_conn(); seed_demo(conn)
    segs = get_segments(conn)
    _header(f"Network Segments  [{len(segs)}]")
    for s in segs:
        tc = G if s.trust_level >= 80 else Y if s.trust_level >= 40 else R
        print(f"  {tc}●{NC} {s.name:<22}  {s.cidr:<18}  zone:{s.zone:<12}  "
              f"trust:{tc}{s.trust_level:>3}{NC}  protos:{s.allowed_protocols}")
    print()

def cmd_verify(args):
    conn = get_conn(); seed_demo(conn)
    result = verify_access(conn, args.subject, args.resource,
                           device_id=args.device or "", context={})
    rc = EFFECT_COL.get(result["result"], NC)
    _header("Access Verification")
    print(f"  Subject  : {W}{args.subject}{NC}")
    print(f"  Resource : {args.resource}")
    print(f"  Decision : {rc}{BOLD}{result['result'].upper()}{NC}")
    if result["policy"]:
        print(f"  Policy   : {result['policy']}  ({result['policy_name']})")
    print()

def cmd_audit(args):
    conn = get_conn(); seed_demo(conn)
    entries = get_audit_log(conn, limit=args.limit, subject=args.subject, result=args.result)
    _header(f"Audit Log  [{len(entries)} entries]")
    for e in entries:
        rc = EFFECT_COL.get(e.result, NC)
        print(f"  {DIM}{e.timestamp}{NC}  {W}{e.subject:<14}{NC}  {e.action:<10}  "
              f"{e.resource:<14}  {rc}{e.result:<6}{NC}  risk:{e.risk_score:>2}")
    print()

def build_parser():
    p = argparse.ArgumentParser(prog="zero-trust", description=f"{W}BlackRoad Zero-Trust Security{NC}")
    sub = p.add_subparsers(dest="command", required=True)
    pp = sub.add_parser("policy", help="Manage policies")
    pp.add_argument("--create", choices=POLICY_ACTIONS); pp.add_argument("--name")
    pp.add_argument("--subject"); pp.add_argument("--resource"); pp.add_argument("--priority", type=int)
    pp.set_defaults(func=cmd_policy)
    pt = sub.add_parser("token", help="Manage access tokens")
    pt.add_argument("--issue"); pt.add_argument("--revoke"); pt.add_argument("--audience")
    pt.add_argument("--scope"); pt.add_argument("--device")
    pt.set_defaults(func=cmd_token)
    pd = sub.add_parser("device", help="Device posture checks")
    pd.add_argument("device_id", nargs="?")
    pd.set_defaults(func=cmd_device)
    sub.add_parser("segment", help="Network segments").set_defaults(func=cmd_segment)
    pv = sub.add_parser("verify", help="Verify access request")
    pv.add_argument("subject"); pv.add_argument("resource"); pv.add_argument("--device")
    pv.set_defaults(func=cmd_verify)
    pa = sub.add_parser("audit", help="View audit log")
    pa.add_argument("--subject"); pa.add_argument("--result"); pa.add_argument("--limit", type=int, default=50)
    pa.set_defaults(func=cmd_audit)
    return p

def main():
    args = build_parser().parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
