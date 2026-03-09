#!/usr/bin/env python3
"""BlackRoad YAML Config Manager — multi-env configs, secret injection, schema validation, diff, merge."""

import sqlite3
import json
import uuid
import os
import sys
import argparse
import re
import hashlib
import copy
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List, Dict, Any, Tuple, Union
from enum import Enum

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
BLUE = "\033[94m"
CYAN = "\033[96m"
MAGENTA = "\033[95m"
BOLD = "\033[1m"
DIM = "\033[2m"
RESET = "\033[0m"

DB_PATH = os.environ.get("YAML_CONFIG_DB", os.path.expanduser("~/.blackroad/yaml_config.db"))

try:
    import yaml
    HAS_YAML = True
except ImportError:
    HAS_YAML = False


class MergeStrategy(str, Enum):
    DEEP = "deep"
    SHALLOW = "shallow"
    OVERRIDE = "override"
    APPEND = "append"


class SchemaType(str, Enum):
    STRING = "string"
    INTEGER = "integer"
    FLOAT = "float"
    BOOLEAN = "boolean"
    LIST = "list"
    DICT = "dict"
    ANY = "any"


@dataclass
class ConfigVersion:
    id: str
    config_id: str
    version: int
    content: Dict[str, Any]
    content_hash: str
    environment: str
    comment: str = ""
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    author: str = ""


@dataclass
class ConfigEntry:
    id: str
    name: str
    environment: str
    content: Dict[str, Any]
    version: int
    content_hash: str
    tags: List[str]
    description: str = ""
    base_config_id: Optional[str] = None
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())
    updated_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


@dataclass
class SchemaField:
    id: str
    schema_name: str
    field_path: str
    field_type: SchemaType
    required: bool
    default: Optional[Any]
    description: str
    validators: List[str]
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


@dataclass
class SecretRef:
    id: str
    config_id: str
    key_path: str
    secret_name: str
    provider: str
    encrypted_value: str
    injected: bool = False
    created_at: str = field(default_factory=lambda: datetime.utcnow().isoformat())


@dataclass
class DiffEntry:
    path: str
    change_type: str
    old_value: Any
    new_value: Any

    def display(self) -> str:
        if self.change_type == "added":
            return f"+ {self.path}: {self.new_value}"
        elif self.change_type == "removed":
            return f"- {self.path}: {self.old_value}"
        else:
            return f"~ {self.path}: {self.old_value!r} → {self.new_value!r}"


class YAMLConfigDB:
    def __init__(self, db_path: str = DB_PATH):
        os.makedirs(os.path.dirname(db_path) or ".", exist_ok=True)
        self.conn = sqlite3.connect(db_path)
        self.conn.row_factory = sqlite3.Row
        self.conn.execute("PRAGMA foreign_keys = ON")
        self._init_schema()

    def _init_schema(self):
        self.conn.executescript("""
            CREATE TABLE IF NOT EXISTS configs (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                environment TEXT NOT NULL,
                content TEXT NOT NULL,
                version INTEGER DEFAULT 1,
                content_hash TEXT NOT NULL,
                tags TEXT DEFAULT '[]',
                description TEXT DEFAULT '',
                base_config_id TEXT,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL,
                UNIQUE(name, environment)
            );
            CREATE TABLE IF NOT EXISTS config_versions (
                id TEXT PRIMARY KEY,
                config_id TEXT NOT NULL REFERENCES configs(id),
                version INTEGER NOT NULL,
                content TEXT NOT NULL,
                content_hash TEXT NOT NULL,
                environment TEXT NOT NULL,
                comment TEXT DEFAULT '',
                author TEXT DEFAULT '',
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS schema_fields (
                id TEXT PRIMARY KEY,
                schema_name TEXT NOT NULL,
                field_path TEXT NOT NULL,
                field_type TEXT NOT NULL,
                required INTEGER DEFAULT 1,
                default_val TEXT,
                description TEXT DEFAULT '',
                validators TEXT DEFAULT '[]',
                created_at TEXT NOT NULL
            );
            CREATE TABLE IF NOT EXISTS secret_refs (
                id TEXT PRIMARY KEY,
                config_id TEXT NOT NULL REFERENCES configs(id),
                key_path TEXT NOT NULL,
                secret_name TEXT NOT NULL,
                provider TEXT DEFAULT 'env',
                encrypted_value TEXT NOT NULL,
                injected INTEGER DEFAULT 0,
                created_at TEXT NOT NULL
            );
            CREATE INDEX IF NOT EXISTS idx_cfg_name_env ON configs(name, environment);
            CREATE INDEX IF NOT EXISTS idx_versions_cfg ON config_versions(config_id, version DESC);
            CREATE INDEX IF NOT EXISTS idx_schema_name ON schema_fields(schema_name, field_path);
        """)
        self.conn.commit()


def _simple_encrypt(value: str, key: str = "blackroad") -> str:
    k = hashlib.sha256(key.encode()).digest()
    return "ENC:" + "".join(hex(ord(c) ^ k[i % 32])[2:].zfill(2) for i, c in enumerate(value))


def _simple_decrypt(enc: str, key: str = "blackroad") -> str:
    if not enc.startswith("ENC:"):
        return enc
    k = hashlib.sha256(key.encode()).digest()
    hexstr = enc[4:]
    return "".join(chr(int(hexstr[i:i+2], 16) ^ k[(i//2) % 32]) for i in range(0, len(hexstr), 2))


def _parse_yaml_or_json(text: str) -> Dict[str, Any]:
    if HAS_YAML:
        return yaml.safe_load(text) or {}
    text = text.strip()
    if text.startswith("{") or text.startswith("["):
        return json.loads(text)
    result: Dict[str, Any] = {}
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" in line:
            key, _, val = line.partition(":")
            val = val.strip()
            if val.lower() == "true":
                result[key.strip()] = True
            elif val.lower() == "false":
                result[key.strip()] = False
            elif val.isdigit():
                result[key.strip()] = int(val)
            else:
                try:
                    result[key.strip()] = float(val)
                except ValueError:
                    result[key.strip()] = val.strip('"\'')
    return result


def _content_hash(content: Dict) -> str:
    return hashlib.sha256(json.dumps(content, sort_keys=True).encode()).hexdigest()[:16]


def _get_nested(d: Dict, path: str, sep: str = ".") -> Any:
    keys = path.split(sep)
    cur = d
    for k in keys:
        if isinstance(cur, dict) and k in cur:
            cur = cur[k]
        else:
            return None
    return cur


def _set_nested(d: Dict, path: str, value: Any, sep: str = "."):
    keys = path.split(sep)
    cur = d
    for k in keys[:-1]:
        cur = cur.setdefault(k, {})
    cur[keys[-1]] = value


def _flatten_dict(d: Dict, prefix: str = "", sep: str = ".") -> Dict[str, Any]:
    result = {}
    for k, v in d.items():
        full_key = f"{prefix}{sep}{k}" if prefix else k
        if isinstance(v, dict):
            result.update(_flatten_dict(v, full_key, sep))
        else:
            result[full_key] = v
    return result


class YAMLConfigManager:
    def __init__(self, db: YAMLConfigDB, secret_key: str = "blackroad"):
        self.db = db
        self._key = secret_key

    # ── Config CRUD ────────────────────────────────────────────────────────

    def load_config(self, name: str, environment: str,
                    content: Union[Dict, str],
                    description: str = "", tags: List[str] = None,
                    author: str = "", base_config_id: str = None) -> ConfigEntry:
        if isinstance(content, str):
            content = _parse_yaml_or_json(content)
        ch = _content_hash(content)
        tags = tags or []
        now = datetime.utcnow().isoformat()
        existing = self.db.conn.execute(
            "SELECT id, version FROM configs WHERE name=? AND environment=?",
            (name, environment)
        ).fetchone()
        if existing:
            cfg_id = existing["id"]
            new_version = existing["version"] + 1
            self.db.conn.execute(
                "UPDATE configs SET content=?, version=?, content_hash=?, "
                "description=?, tags=?, updated_at=? WHERE id=?",
                (json.dumps(content), new_version, ch,
                 description, json.dumps(tags), now, cfg_id)
            )
        else:
            cfg_id = str(uuid.uuid4())
            new_version = 1
            self.db.conn.execute(
                "INSERT INTO configs VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                (cfg_id, name, environment, json.dumps(content),
                 new_version, ch, json.dumps(tags), description,
                 base_config_id, now, now)
            )
        self.db.conn.execute(
            "INSERT INTO config_versions VALUES (?,?,?,?,?,?,?,?,?)",
            (str(uuid.uuid4()), cfg_id, new_version,
             json.dumps(content), ch, environment, "", author, now)
        )
        self.db.conn.commit()
        return ConfigEntry(id=cfg_id, name=name, environment=environment,
                           content=content, version=new_version,
                           content_hash=ch, tags=tags, description=description)

    def get_config(self, name: str, environment: str) -> Optional[Dict]:
        row = self.db.conn.execute(
            "SELECT * FROM configs WHERE name=? AND environment=?",
            (name, environment)
        ).fetchone()
        if not row:
            return None
        d = dict(row)
        d["content"] = json.loads(d["content"])
        d["tags"] = json.loads(d.get("tags", "[]"))
        return d

    def get_version(self, config_id: str, version: int) -> Optional[Dict]:
        row = self.db.conn.execute(
            "SELECT * FROM config_versions WHERE config_id=? AND version=?",
            (config_id, version)
        ).fetchone()
        if not row:
            return None
        d = dict(row)
        d["content"] = json.loads(d["content"])
        return d

    # ── Merge strategies ───────────────────────────────────────────────────

    def merge_configs(self, base_name: str, override_name: str,
                      environment: str, strategy: str = "deep",
                      result_name: str = None) -> ConfigEntry:
        base = self.get_config(base_name, environment)
        override = self.get_config(override_name, environment)
        if not base or not override:
            raise ValueError("One or both configs not found")

        base_content = base["content"]
        override_content = override["content"]

        if strategy == MergeStrategy.DEEP.value:
            merged = self._deep_merge(copy.deepcopy(base_content), override_content)
        elif strategy == MergeStrategy.SHALLOW.value:
            merged = {**base_content, **override_content}
        elif strategy == MergeStrategy.OVERRIDE.value:
            merged = copy.deepcopy(override_content)
        elif strategy == MergeStrategy.APPEND.value:
            merged = copy.deepcopy(base_content)
            for k, v in override_content.items():
                if k in merged and isinstance(merged[k], list) and isinstance(v, list):
                    merged[k] = merged[k] + v
                else:
                    merged[k] = v
        else:
            merged = self._deep_merge(copy.deepcopy(base_content), override_content)

        name = result_name or f"{base_name}__{override_name}__merged"
        return self.load_config(name, environment, merged,
                                description=f"Merged {base_name}+{override_name} via {strategy}")

    def _deep_merge(self, base: Dict, override: Dict) -> Dict:
        for k, v in override.items():
            if k in base and isinstance(base[k], dict) and isinstance(v, dict):
                self._deep_merge(base[k], v)
            else:
                base[k] = v
        return base

    # ── Schema validation ──────────────────────────────────────────────────

    def add_schema_field(self, schema_name: str, path: str,
                          field_type: str, required: bool = True,
                          default: Any = None, description: str = "",
                          validators: List[str] = None) -> SchemaField:
        field = SchemaField(
            id=str(uuid.uuid4()), schema_name=schema_name,
            field_path=path, field_type=SchemaType(field_type),
            required=required, default=default,
            description=description, validators=validators or []
        )
        default_str = json.dumps(default) if default is not None else None
        self.db.conn.execute(
            "INSERT INTO schema_fields VALUES (?,?,?,?,?,?,?,?,?)",
            (field.id, field.schema_name, field.field_path,
             field.field_type.value, int(field.required),
             default_str, field.description,
             json.dumps(field.validators), field.created_at)
        )
        self.db.conn.commit()
        return field

    def validate_schema(self, config_name: str, environment: str,
                         schema_name: str) -> Dict[str, Any]:
        cfg = self.get_config(config_name, environment)
        if not cfg:
            return {"valid": False, "error": "config not found"}

        fields = self.db.conn.execute(
            "SELECT * FROM schema_fields WHERE schema_name=?", (schema_name,)
        ).fetchall()

        content = cfg["content"]
        flat = _flatten_dict(content)
        errors = []
        warnings = []
        passed = 0

        for f in fields:
            path = f["field_path"]
            ftype = f["field_type"]
            required = bool(f["required"])
            default = json.loads(f["default_val"]) if f["default_val"] else None
            validators = json.loads(f["validators"]) if f["validators"] else []

            value = _get_nested(content, path)
            if value is None:
                value = flat.get(path)

            if value is None:
                if required:
                    errors.append({"field": path, "error": "required field missing"})
                else:
                    warnings.append({"field": path, "warning": f"optional field missing (default: {default})"})
                continue

            type_checks = {
                SchemaType.STRING.value: str,
                SchemaType.INTEGER.value: int,
                SchemaType.FLOAT.value: (int, float),
                SchemaType.BOOLEAN.value: bool,
                SchemaType.LIST.value: list,
                SchemaType.DICT.value: dict,
            }
            expected = type_checks.get(ftype)
            if expected and not isinstance(value, expected):
                errors.append({"field": path, "error": f"expected {ftype}, got {type(value).__name__}"})
                continue

            for validator in validators:
                if validator.startswith("min:"):
                    min_val = float(validator.split(":")[1])
                    if isinstance(value, (int, float)) and value < min_val:
                        errors.append({"field": path, "error": f"value {value} < min {min_val}"})
                elif validator.startswith("max:"):
                    max_val = float(validator.split(":")[1])
                    if isinstance(value, (int, float)) and value > max_val:
                        errors.append({"field": path, "error": f"value {value} > max {max_val}"})
                elif validator.startswith("regex:"):
                    pattern = validator.split(":", 1)[1]
                    if isinstance(value, str) and not re.match(pattern, value):
                        errors.append({"field": path, "error": f"does not match pattern {pattern}"})
                elif validator.startswith("enum:"):
                    options = validator.split(":", 1)[1].split(",")
                    if str(value) not in options:
                        errors.append({"field": path, "error": f"value '{value}' not in {options}"})

            passed += 1

        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "warnings": warnings,
            "fields_checked": len(fields),
            "fields_passed": passed,
            "config": config_name,
            "environment": environment,
            "schema": schema_name,
        }

    # ── Secret injection ───────────────────────────────────────────────────

    def register_secret(self, config_id: str, key_path: str,
                         secret_name: str, value: str,
                         provider: str = "env") -> SecretRef:
        enc = _simple_encrypt(value, self._key)
        ref = SecretRef(
            id=str(uuid.uuid4()), config_id=config_id,
            key_path=key_path, secret_name=secret_name,
            provider=provider, encrypted_value=enc
        )
        self.db.conn.execute(
            "INSERT INTO secret_refs VALUES (?,?,?,?,?,?,?,?)",
            (ref.id, ref.config_id, ref.key_path, ref.secret_name,
             ref.provider, ref.encrypted_value, int(ref.injected), ref.created_at)
        )
        self.db.conn.commit()
        return ref

    def inject_secrets(self, config_name: str, environment: str,
                        extra_env: Dict[str, str] = None) -> Dict[str, Any]:
        cfg = self.get_config(config_name, environment)
        if not cfg:
            raise ValueError(f"Config '{config_name}/{environment}' not found")

        refs = self.db.conn.execute(
            "SELECT * FROM secret_refs WHERE config_id=?", (cfg["id"],)
        ).fetchall()

        content = copy.deepcopy(cfg["content"])
        injected_count = 0

        for ref in refs:
            key_path = ref["key_path"]
            provider = ref["provider"]
            secret_name = ref["secret_name"]

            if provider == "env":
                env_val = (extra_env or {}).get(secret_name) or os.environ.get(secret_name)
                value = env_val if env_val else _simple_decrypt(ref["encrypted_value"], self._key)
            else:
                value = _simple_decrypt(ref["encrypted_value"], self._key)

            _set_nested(content, key_path, value)
            injected_count += 1
            self.db.conn.execute(
                "UPDATE secret_refs SET injected=1 WHERE id=?", (ref["id"],)
            )

        self.db.conn.commit()
        return {"content": content, "injected": injected_count, "config": config_name}

    # ── Diff ───────────────────────────────────────────────────────────────

    def diff_configs(self, name_a: str, env_a: str,
                     name_b: str, env_b: str) -> List[DiffEntry]:
        cfg_a = self.get_config(name_a, env_a)
        cfg_b = self.get_config(name_b, env_b)
        if not cfg_a or not cfg_b:
            raise ValueError("One or both configs not found")

        flat_a = _flatten_dict(cfg_a["content"])
        flat_b = _flatten_dict(cfg_b["content"])
        keys_a = set(flat_a.keys())
        keys_b = set(flat_b.keys())

        diffs = []
        for k in keys_b - keys_a:
            diffs.append(DiffEntry(k, "added", None, flat_b[k]))
        for k in keys_a - keys_b:
            diffs.append(DiffEntry(k, "removed", flat_a[k], None))
        for k in keys_a & keys_b:
            if flat_a[k] != flat_b[k]:
                diffs.append(DiffEntry(k, "modified", flat_a[k], flat_b[k]))

        return sorted(diffs, key=lambda d: (d.change_type, d.path))

    # ── Utilities ──────────────────────────────────────────────────────────

    def list_configs(self, environment: str = None) -> List[Dict]:
        if environment:
            rows = self.db.conn.execute(
                "SELECT c.*, COUNT(v.id) as version_count "
                "FROM configs c LEFT JOIN config_versions v ON v.config_id=c.id "
                "WHERE c.environment=? GROUP BY c.id ORDER BY c.updated_at DESC",
                (environment,)
            ).fetchall()
        else:
            rows = self.db.conn.execute(
                "SELECT c.*, COUNT(v.id) as version_count "
                "FROM configs c LEFT JOIN config_versions v ON v.config_id=c.id "
                "GROUP BY c.id ORDER BY c.updated_at DESC"
            ).fetchall()
        result = []
        for r in rows:
            d = dict(r)
            d["tags"] = json.loads(d.get("tags", "[]"))
            result.append(d)
        return result

    def list_versions(self, config_name: str, environment: str) -> List[Dict]:
        cfg = self.get_config(config_name, environment)
        if not cfg:
            return []
        rows = self.db.conn.execute(
            "SELECT * FROM config_versions WHERE config_id=? ORDER BY version DESC",
            (cfg["id"],)
        ).fetchall()
        return [dict(r) for r in rows]

    def export_config(self, config_name: str, environment: str,
                       fmt: str = "json") -> str:
        cfg = self.get_config(config_name, environment)
        if not cfg:
            raise ValueError("Config not found")
        if fmt == "json":
            return json.dumps(cfg["content"], indent=2)
        if fmt == "env":
            flat = _flatten_dict(cfg["content"])
            return "\n".join(f"{k.upper().replace('.','_')}={v}" for k, v in flat.items())
        if fmt == "yaml" and HAS_YAML:
            return yaml.dump(cfg["content"], default_flow_style=False)
        return json.dumps(cfg["content"], indent=2)


# ── CLI ───────────────────────────────────────────────────────────────────────

def _banner():
    print(f"\n{BOLD}{YELLOW}╔══════════════════════════════════════════╗{RESET}")
    print(f"{BOLD}{YELLOW}║   BlackRoad YAML Config Manager v1.0.0   ║{RESET}")
    print(f"{BOLD}{YELLOW}╚══════════════════════════════════════════╝{RESET}\n")


def _get_manager() -> YAMLConfigManager:
    key = os.environ.get("CONFIG_SECRET_KEY", "blackroad")
    return YAMLConfigManager(YAMLConfigDB(), key)


def cmd_load(args):
    mgr = _get_manager()
    if args.file:
        with open(args.file) as f:
            raw = f.read()
    else:
        raw = args.content
    tags = [t.strip() for t in args.tags.split(",")] if args.tags else []
    cfg = mgr.load_config(args.name, args.env, raw, args.description, tags, args.author)
    print(f"{GREEN}✓ Config loaded{RESET}")
    print(f"  {DIM}ID:{RESET}      {CYAN}{cfg.id[:12]}…{RESET}")
    print(f"  {DIM}Name:{RESET}    {cfg.name}/{cfg.environment}")
    print(f"  {DIM}Version:{RESET} v{cfg.version}")
    print(f"  {DIM}Hash:{RESET}    {cfg.content_hash}")
    print(f"  {DIM}Keys:{RESET}    {len(_flatten_dict(cfg.content))}")


def cmd_merge(args):
    mgr = _get_manager()
    try:
        result = mgr.merge_configs(args.base, args.override, args.env,
                                    args.strategy, args.output_name)
    except ValueError as e:
        print(f"{RED}✗ Merge failed: {e}{RESET}")
        sys.exit(1)
    print(f"{GREEN}✓ Configs merged → '{result.name}'{RESET}")
    print(f"  {DIM}Strategy:{RESET} {args.strategy}")
    print(f"  {DIM}Keys:{RESET}     {len(_flatten_dict(result.content))}")
    print(f"  {DIM}Version:{RESET}  v{result.version}")


def cmd_validate(args):
    mgr = _get_manager()
    result = mgr.validate_schema(args.config, args.env, args.schema)
    icon = f"{GREEN}✓ VALID{RESET}" if result["valid"] else f"{RED}✗ INVALID{RESET}"
    print(f"\n{BOLD}Schema Validation — {args.config}/{args.env}: {icon}{RESET}")
    print(f"  Fields checked: {result['fields_checked']}  Passed: {result['fields_passed']}")
    for err in result.get("errors", []):
        print(f"  {RED}✗ {err['field']}: {err['error']}{RESET}")
    for warn in result.get("warnings", []):
        print(f"  {YELLOW}⚠ {warn['field']}: {warn['warning']}{RESET}")
    if not result["valid"]:
        sys.exit(1)


def cmd_diff(args):
    mgr = _get_manager()
    try:
        diffs = mgr.diff_configs(args.config_a, args.env_a, args.config_b, args.env_b)
    except ValueError as e:
        print(f"{RED}✗ Diff failed: {e}{RESET}")
        sys.exit(1)

    added = [d for d in diffs if d.change_type == "added"]
    removed = [d for d in diffs if d.change_type == "removed"]
    modified = [d for d in diffs if d.change_type == "modified"]

    print(f"\n{BOLD}Config Diff: {args.config_a}/{args.env_a} ↔ {args.config_b}/{args.env_b}{RESET}")
    print(f"  {GREEN}+{len(added)} added{RESET}  "
          f"{RED}-{len(removed)} removed{RESET}  "
          f"{YELLOW}~{len(modified)} modified{RESET}")

    limit = args.limit
    for d in added[:limit]:
        print(f"  {GREEN}+ {d.path}: {d.new_value}{RESET}")
    for d in removed[:limit]:
        print(f"  {RED}- {d.path}: {d.old_value}{RESET}")
    for d in modified[:limit]:
        print(f"  {YELLOW}~ {d.path}: {d.old_value!r} → {d.new_value!r}{RESET}")


def cmd_inject(args):
    mgr = _get_manager()
    extra = {}
    if args.secrets:
        for pair in args.secrets.split(","):
            k, _, v = pair.partition("=")
            extra[k.strip()] = v.strip()
    try:
        result = mgr.inject_secrets(args.config, args.env, extra)
    except ValueError as e:
        print(f"{RED}✗ Inject failed: {e}{RESET}")
        sys.exit(1)
    if args.output:
        with open(args.output, "w") as f:
            json.dump(result["content"], f, indent=2)
        print(f"{GREEN}✓ Injected {result['injected']} secret(s) → {args.output}{RESET}")
    else:
        print(json.dumps(result["content"], indent=2))


def cmd_export(args):
    mgr = _get_manager()
    try:
        output = mgr.export_config(args.config, args.env, args.format)
    except ValueError as e:
        print(f"{RED}✗ Export failed: {e}{RESET}")
        sys.exit(1)
    if args.output:
        with open(args.output, "w") as f:
            f.write(output)
        print(f"{GREEN}✓ Exported → {args.output}{RESET}")
    else:
        print(output)


def cmd_list(args):
    mgr = _get_manager()
    configs = mgr.list_configs(args.env)
    print(f"\n{BOLD}Configs ({len(configs)}){RESET}")
    print(f"  {'Name':<25} {'Env':<12} {'Version':>8} {'Keys':>6}  {'Hash':<16}  Updated")
    print(f"  {'─'*25} {'─'*12} {'─'*8} {'─'*6}  {'─'*16}  {'─'*10}")
    for c in configs:
        content = json.loads(c["content"]) if isinstance(c["content"], str) else c["content"]
        keys = len(_flatten_dict(content))
        env_col = CYAN if c["environment"] == "production" else (GREEN if c["environment"] == "development" else YELLOW)
        print(f"  {BOLD}{c['name']:<25}{RESET} {env_col}{c['environment']:<12}{RESET} "
              f"v{c['version']:>7} {keys:>6}  {DIM}{c['content_hash']:<16}{RESET}  {c['updated_at'][:10]}")


def main():
    _banner()
    parser = argparse.ArgumentParser(prog="yaml-config", description="BlackRoad YAML Config Manager")
    sub = parser.add_subparsers(dest="command", required=True)

    p = sub.add_parser("load", help="Load a YAML/JSON config")
    p.add_argument("name")
    p.add_argument("--env", default="development")
    p.add_argument("--content", default="{}")
    p.add_argument("--file", default=None)
    p.add_argument("--description", default="")
    p.add_argument("--tags", default="")
    p.add_argument("--author", default="")

    p = sub.add_parser("merge", help="Merge two configs")
    p.add_argument("base")
    p.add_argument("override")
    p.add_argument("--env", default="development")
    p.add_argument("--strategy", default="deep",
                   choices=["deep", "shallow", "override", "append"])
    p.add_argument("--output-name", default=None)

    p = sub.add_parser("validate", help="Validate config against schema")
    p.add_argument("config")
    p.add_argument("schema")
    p.add_argument("--env", default="development")

    p = sub.add_parser("diff", help="Diff two configs")
    p.add_argument("config_a")
    p.add_argument("config_b")
    p.add_argument("--env-a", default="development")
    p.add_argument("--env-b", default="production")
    p.add_argument("--limit", type=int, default=20)

    p = sub.add_parser("inject", help="Inject secrets into config")
    p.add_argument("config")
    p.add_argument("--env", default="development")
    p.add_argument("--secrets", default="", help="KEY=VALUE,KEY2=VALUE2")
    p.add_argument("--output", default=None)

    p = sub.add_parser("export", help="Export config to file")
    p.add_argument("config")
    p.add_argument("--env", default="development")
    p.add_argument("--format", default="json", choices=["json", "env", "yaml"])
    p.add_argument("--output", default=None)

    p = sub.add_parser("list", help="List all configs")
    p.add_argument("--env", default=None)

    args = parser.parse_args()
    cmds = {
        "load": cmd_load, "merge": cmd_merge, "validate": cmd_validate,
        "diff": cmd_diff, "inject": cmd_inject, "export": cmd_export, "list": cmd_list,
    }
    cmds[args.command](args)


if __name__ == "__main__":
    main()
