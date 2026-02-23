# Docs — From Google Drive

> Recovered from amundsonalexa@gmail.com Drive · February 2026

These are foundational BlackRoad OS documents sourced from Google Drive and converted to markdown for the repo.

---

## Documents

| File | Origin | Description |
|---|---|---|
| [OWNER-MANUAL.md](./OWNER-MANUAL.md) | PLAN? FINALLY?.docx (Nov 2025) | BlackRoad OS Owner's Manual v1.0 — deployment, monetization, architecture boot order |
| [AGENT-ECOSYSTEM-ARCHITECTURE.md](./AGENT-ECOSYSTEM-ARCHITECTURE.md) | Building the Agent Ecosystem.docx | Section 6 of the RoadChain whitepaper — edge compute topology, DLT governance, agent DIDs |
| [AMUNDSON-FRAMEWORK.md](./AMUNDSON-FRAMEWORK.md) | A Framework.docx | The 1-2-3-4 ontological framework — theoretical foundation for QI layer and trinary logic |
| [NEW-AGE-MANIFESTO.md](./NEW-AGE-MANIFESTO.md) | THE NEW AGE.docx (Nov 2025) | Full catalog of legacy tech pain points + BlackRoad OS solutions |

---

## Google Drive Access

Two drives are configured via rclone:

| Remote | Account | Status |
|---|---|---|
| `gdrive:` | amundsonalexa@gmail.com | ✅ Active |
| `gdrive-blackroad:` | alexa@blackroad.io | ⚠️ Needs re-auth |

### Re-auth blackroad drive:
```bash
chmod u+w ~/.config/rclone ~/.config/rclone/rclone.conf
rclone config reconnect gdrive-blackroad:
```

### Browse drives:
```bash
rclone lsd gdrive:              # List folders
rclone ls gdrive: --max-depth 1 # List files at root
rclone cat "gdrive:filename.docx" | strings  # Read a doc
```
