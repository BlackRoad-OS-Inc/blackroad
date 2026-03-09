# Google Drive Archive Plan

## Files to Upload

### 1. Documents Folder (~400MB)
- ~/Documents/Zoom (321MB) - Meeting recordings
- ~/Documents/Arduino (33MB) - Arduino projects/sketches
- ~/Documents/BlackRoad (27MB) - Company documents
- ~/Documents/*.pdf - Large PDF files

### 2. Pi Transfer Archive
- ~/pi-transfer-archive.tar.gz (1.7GB)
  - The Devil Wears Prada.mp4
  - Chat GPT folder

## Google Drive Structure

```
BlackRoad-Archive/
├── Documents/
│   ├── Zoom/
│   ├── Arduino/
│   ├── BlackRoad/
│   └── PDFs/
├── Media/
│   └── pi-transfer-archive.tar.gz
└── Cleanup-Reports/
    └── 2026-01-10-cleanup-summary.md
```

## Steps

1. Open Google Drive in browser
2. Create folder: `BlackRoad-Archive`
3. Upload all ~/Documents/* (except working files)
4. Upload ~/pi-transfer-archive.tar.gz
5. Upload ~/CLEANUP_SUMMARY.md
6. Verify all uploads complete
7. Delete local copies after verification

## After Upload

```bash
# After verifying uploads:
rm -rf ~/Documents/Zoom
rm -rf ~/Documents/Arduino
rm ~/pi-transfer-archive.tar.gz

# Will free ~2.1GB additional space
```

## Google Drive Account
- Email: amundsonalexa@gmail.com (primary)
- Backup: blackroad.systems@gmail.com

