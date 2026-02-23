# Google Drive Setup

Run this ONCE interactively to configure rclone:

```bash
brew install rclone  # if not installed
rclone config
# Choose: n (new remote)
# Name: gdrive
# Type: drive  (Google Drive)
# Follow OAuth flow in browser
# Scope: drive (full access)
```

Then run first sync:
```bash
./scripts/gdrive-sync.sh
```

Cron (already set if sync script was run):
```
0 3 * * * /Users/alexa/blackroad/scripts/gdrive-sync.sh >> /Users/alexa/blackroad/logs/gdrive-sync.log 2>&1
```
