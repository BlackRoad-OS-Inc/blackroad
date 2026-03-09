# blackroad-zip-service

ZIP/archive utility with operation history for BlackRoad OS.

## Features
- Create ZIP, TAR, TAR.GZ, TAR.BZ2, TAR.XZ archives
- Extract archives to directory
- List archive contents with size/date info
- Add files to existing ZIP archives
- SHA-256 checksum verification
- Streaming extraction for memory-efficient processing
- SQLite operation history (`archive_history` table)

## Usage
```bash
# Create ZIP
python src/main_module.py create output.zip file1.txt dir/

# Create TAR.GZ
python src/main_module.py create output.tar.gz src/ --format tar.gz

# Extract
python src/main_module.py extract archive.zip ./output/

# List contents
python src/main_module.py list archive.zip

# Add file to zip
python src/main_module.py add archive.zip newfile.txt

# Verify integrity
python src/main_module.py verify archive.zip
python src/main_module.py verify archive.zip --expected <sha256>

# Compute checksum
python src/main_module.py checksum archive.zip

# View history
python src/main_module.py history --limit 20
```

## API
```python
from src.main_module import create_archive, extract_archive, checksum_verify, get_db

conn = get_db()
info = create_archive(["file1.txt", "dir/"], "output.zip", compression="zip", conn=conn)
print(f"Created: {info.checksum}")

result = checksum_verify("output.zip", expected=info.checksum)
assert result["valid"]
```

## Testing
```bash
python -m pytest tests/ -v
```
