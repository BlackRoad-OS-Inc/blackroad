"""Network discovery helpers for locating the Jetson on the LAN."""

from __future__ import annotations

import ipaddress
import json
import os
import subprocess
from typing import Dict, Iterable, Optional, Tuple

PREFERRED_IFACE_PREFIXES = ("en", "eth")


def _run(cmd: Iterable[str]) -> str:
    try:
        return subprocess.check_output(list(cmd), text=True).strip()
    except Exception:
        return ""


def _interfaces() -> Iterable[Tuple[str, ipaddress.IPv4Interface]]:
    """Yield IPv4 interfaces that are up and usable for discovery."""

    raw = _run(["ip", "-json", "-4", "addr"])
    if not raw:
        return []
    data = json.loads(raw)
    for entry in data:
        if entry.get("ifname") == "lo":
            continue
        if entry.get("operstate") not in {"UP", "UNKNOWN"}:
            continue
        for info in entry.get("addr_info", []):
            if info.get("family") != "inet":
                continue
            address = f"{info['local']}/{info['prefixlen']}"
            yield entry["ifname"], ipaddress.ip_interface(address)


def _bounded_network(interface: ipaddress.IPv4Interface) -> ipaddress.IPv4Network:
    """Clamp very large networks to a /24 to keep scans fast."""

    if interface.network.prefixlen >= 24:
        return interface.network
    return ipaddress.ip_network(f"{interface.ip}/24", strict=False)


def _subnet() -> Optional[Tuple[ipaddress.IPv4Network, ipaddress.IPv4Address]]:
    """Return the network to scan and the local address on that network."""

    override = os.getenv("BLACKROAD_DISCOVER_IFACE")
    interfaces = list(_interfaces())
    if not interfaces:
        return None

    if override:
        for name, iface in interfaces:
            if name == override:
                return _bounded_network(iface), iface.ip

    for name, iface in interfaces:
        if name.startswith(PREFERRED_IFACE_PREFIXES):
            return _bounded_network(iface), iface.ip

    name, iface = interfaces[0]
    return _bounded_network(iface), iface.ip


def _ping(ip: str) -> bool:
    try:
        subprocess.check_output(
            ["ping", "-c", "1", "-W", "1", ip], stderr=subprocess.DEVNULL
        )
        return True
    except Exception:
        return False


def _mdns_name(ip: str) -> str:
    out = _run(["avahi-resolve", "-a", ip])
    if out and " " in out:
        return out.split(" ", 1)[1].strip()
    return ""


def _ssh_ok(ip: str, user: str = "jetson") -> bool:
    try:
        subprocess.check_output(
            [
                "ssh",
                "-o",
                "ConnectTimeout=1",
                "-o",
                "BatchMode=yes",
                f"{user}@{ip}",
                "true",
            ],
            stderr=subprocess.DEVNULL,
        )
        return True
    except Exception:
        return False


def _is_jetson(ip: str, user: str) -> bool:
    try:
        out = subprocess.check_output(
            [
                "ssh",
                "-o",
                "ConnectTimeout=2",
                f"{user}@{ip}",
                "uname -a && command -v nvidia-smi >/dev/null && "
                "nvidia-smi --query-gpu=name --format=csv,noheader || echo no-gpu",
            ],
            text=True,
            stderr=subprocess.DEVNULL,
        )
        return "no-gpu" not in out
    except Exception:
        return False


def scan() -> Dict[str, object]:
    """Probe the local network for reachable hosts and flag Jetsons."""

    result = _subnet()
    if not result:
        return {"error": "no subnet"}

    network, local_ip = result
    hosts = []
    for ip in network.hosts():
        if ip == local_ip:
            continue
        ip_s = str(ip)
        if not _ping(ip_s):
            continue

        name = _mdns_name(ip_s)
        ssh_attempts = {
            "jetson": _ssh_ok(ip_s, "jetson"),
            "ubuntu": _ssh_ok(ip_s, "ubuntu"),
            "nvidia": _ssh_ok(ip_s, "nvidia"),
        }
        ssh = any(ssh_attempts.values())
        kind = "unknown"

        if ssh:
            for user, ok in ssh_attempts.items():
                if ok and _is_jetson(ip_s, user):
                    kind = "jetson"
                    break
            else:
                kind = "ssh"

        hosts.append({"ip": ip_s, "name": name, "ssh": ssh, "kind": kind})

    return {"network": str(network), "hosts": hosts}


def _main() -> None:
    print(json.dumps(scan(), indent=2))


if __name__ == "__main__":
    _main()
