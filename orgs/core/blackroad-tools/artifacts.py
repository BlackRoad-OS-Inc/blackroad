import argparse
import hashlib
import json
import subprocess
import hashlib
import json
from typing import Any

from . import storage

try:
    import jsonschema
except Exception:  # pragma: no cover
    jsonschema = None


def validate_and_write(path: str, data: Any, schema_path: str | None = None) -> None:
    if schema_path and jsonschema:
        schema = json.loads(storage.read(schema_path))
        jsonschema.validate(data, schema)
    content = json.dumps(data, sort_keys=True) if not isinstance(data, str) else data
    storage.write(path, content)
    sig = hashlib.sha256(content.encode("utf-8")).hexdigest()
    storage.write(path + ".sig", sig)


def hash_and_release(path: str, schema_path: str | None = None, tag: bool = False) -> str:
    data = json.loads(storage.read(path))
    validate_and_write(path, data, schema_path)
    sig = storage.read(path + ".sig")
    if tag:
        subprocess.run(["git", "tag", f"rel-{sig[:12]}"])
    return sig


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("path")
    parser.add_argument("--schema", dest="schema", default=None)
    parser.add_argument("--tag", action="store_true")
    args = parser.parse_args()
    hash_and_release(args.path, args.schema, args.tag)


if __name__ == "__main__":  # pragma: no cover
    main()
