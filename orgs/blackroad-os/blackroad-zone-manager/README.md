# blackroad-zone-manager

DNS zone management library and CLI for BlackRoad OS.

## Features
- Zone struct with records, TTL, serial management
- Add/remove/validate DNS records (A, AAAA, CNAME, MX, TXT, NS, SOA, SRV, PTR, CAA)
- Export to BIND zone file format
- Import existing BIND zone files
- Sync with DNS providers (Cloudflare, Route53, DigitalOcean)
- SQLite persistence (`zones` + `records` tables)
- SHA-256 zone checksums

## Installation
```bash
pip install pytest  # for tests only
```

## Usage
```bash
# Create a zone
python src/main_module.py create example.com --ttl 3600

# Add records
python src/main_module.py add-record example.com A www 93.184.216.34
python src/main_module.py add-record example.com MX @ mail.example.com --priority 10

# Validate
python src/main_module.py validate example.com

# Export BIND format
python src/main_module.py export example.com -o example.com.zone

# Import zone file
python src/main_module.py import /path/to/zone.file

# Sync with provider (dry run)
python src/main_module.py sync example.com --provider cloudflare

# List all zones
python src/main_module.py list
```

## API
```python
from src.main_module import Zone, add_record, validate_zone, export_bind_format, get_db

conn = get_db()
zone = Zone(name="example.com", ttl=3600)
save_zone(zone, conn)
add_record(zone, "A", "www", "1.2.3.4", conn=conn)
print(export_bind_format(zone))
```

## Testing
```bash
python -m pytest tests/ -v
```
