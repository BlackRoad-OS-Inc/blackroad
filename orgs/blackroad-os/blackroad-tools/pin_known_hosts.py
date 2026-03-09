#!/usr/bin/env python3
"""
Validates remote host keys against expected SHA256 fingerprints
and writes a pinned secrets/known_hosts file for strict SSH.
"""
import subprocess, sys, json
from pathlib import Path

HOSTS = json.loads(Path("secrets/hosts.json").read_text())
OUT   = Path("secrets/known_hosts")
OUT.parent.mkdir(parents=True, exist_ok=True)

def ssh_keyscan(host):
    # scan common key types; quiet; 5s timeout
    cmd = ["ssh-keyscan","-T","5","-t","rsa,ecdsa,ed25519",host]
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.stdout.strip().splitlines()

def fp_of_line(line):
    # compute SHA256 fingerprint of a known_hosts-format line
    p = subprocess.run(["ssh-keygen","-lf","-"], input=line+"\n",
                       capture_output=True, text=True)
    if p.returncode != 0: return None
    # Example output: "256 SHA256:abcdef... host (ED25519)"
    parts = p.stdout.strip().split()
    return parts[1] if len(parts) >= 2 else None

valid_lines = []
errors = []

for host, expected in HOSTS.items():
    lines = ssh_keyscan(host)
    matched = False
    for line in lines:
        fp = fp_of_line(line)
        if fp == expected:
            valid_lines.append(line)
            matched = True
    if not matched:
        errors.append(f"{host}: no scanned key matched expected fingerprint {expected}")

if errors:
    print("ERROR: Host pinning failed:\n- " + "\n- ".join(errors))
    sys.exit(1)

OUT.write_text("\n".join(valid_lines) + "\n")
print(f"\u2714 Wrote pinned known_hosts -> {OUT}")
