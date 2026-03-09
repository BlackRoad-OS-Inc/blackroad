# blackroad-zero-trust

Zero-trust security engine for the BlackRoad system. Policy engine, access tokens, device posture checks, network segmentation rules, and audit logging.

## Install

pip install -e .

## Usage

python src/zero_trust.py policy
python src/zero_trust.py policy --create allow --name "Agent Access" --subject "agent:*" --resource "gateway:*"
python src/zero_trust.py token --issue agent:lucidia --scope read,write
python src/zero_trust.py token --revoke tok1234567890
python src/zero_trust.py device
python src/zero_trust.py device dev-octavia
python src/zero_trust.py segment
python src/zero_trust.py verify agent:lucidia gateway:inference
python src/zero_trust.py audit --limit 20 --result deny

## Architecture

- SQLite: policies, access_tokens, device_posture, network_segments, audit_logs
- Dataclasses: Policy, AccessToken, DevicePosture, NetworkSegment, AuditLog
- Token hashed with SHA-256; device posture scoring: managed(25)+encrypted(25)+antivirus(20)+patches(30)
- Policy evaluation: priority-ordered, condition matching, default-deny

## Development

pip install pytest pytest-cov flake8
pytest tests/ -v --cov=src
