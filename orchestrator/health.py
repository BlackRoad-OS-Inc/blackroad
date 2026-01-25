import json
from pathlib import Path
from typing import Dict

from sdk import plugin_api
from metrics import record


CHECKS = ["storage", "registry", "logs"]


def run_checks() -> Dict[str, bool]:
    results: Dict[str, bool] = {}
    try:
        Path("artifacts").mkdir(exist_ok=True)
        with open("artifacts/.health", "w"):
            pass
        results["storage"] = True
    except Exception:
        results["storage"] = False
    results["registry"] = len(plugin_api.BOT_REGISTRY) > 0
    try:
        Path("logs").mkdir(exist_ok=True)
        with open("logs/health.log", "a"):
            pass
        results["logs"] = True
    except Exception:
        results["logs"] = False
    return results


def check() -> Dict[str, Dict[str, bool]]:
    results = run_checks()
    ok = all(results.values())
    if not ok:
        record("health_fail")
    return {"overall_status": "ok" if ok else "fail", "checks": results}
