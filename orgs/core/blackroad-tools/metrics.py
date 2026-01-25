import time
from . import storage

def emit(name: str, value: float = 1.0) -> None:
    record = {"metric": name, "value": value, "ts": int(time.time() * 1000)}
    storage.write("artifacts/metrics.jsonl", record)
