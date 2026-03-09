"""Wallet webhook reflex example."""

from __future__ import annotations

import datetime as _dt
import json
import os
import subprocess
from typing import Any, Dict

from lucidia.reflex.core import BUS, start

WALLET_LOG = os.environ.get("LUCIDIA_WALLET_LOG", "/var/log/lucidia/wallet-events.log")


@BUS.on("wallet:credit")
def on_credit(evt: Dict[str, Any]) -> None:
    os.makedirs(os.path.dirname(WALLET_LOG), exist_ok=True)
    record = {"at": _dt.datetime.utcnow().isoformat() + "Z", **evt}
    with open(WALLET_LOG, "a", encoding="utf-8") as f:
        f.write(json.dumps(record) + "\n")
    try:
        subprocess.Popen(["paplay", "/usr/share/sounds/freedesktop/stereo/complete.oga"])
    except Exception:
        pass


def http_wallet_webhook(data: Dict[str, Any]) -> None:
    if data.get("delta_sats", 0) > 0:
        BUS.emit("wallet:credit", data)


if __name__ == "__main__":  # pragma: no cover - manual wiring
    start()
    http_wallet_webhook({"txid": "abc", "delta_sats": 12345})

