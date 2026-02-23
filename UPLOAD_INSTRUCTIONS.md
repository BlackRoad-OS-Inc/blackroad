# BlackRoad Core - File Upload Instructions

## Overview

I've created a complete bash script that will upload all 8 files to the GitHub repository `BlackRoad-OS-Inc/blackroad-core` using the `gh api` command.

## Prerequisites

- **GitHub CLI (`gh`) installed** - [Install here](https://cli.github.com/)
- **Authenticated with GitHub** - Run `gh auth login` to authenticate
- **Repository access** - You must have write permissions to `BlackRoad-OS-Inc/blackroad-core`

## Files to be Uploaded

The script will create/update these 8 files:

1. **README.md** - Main project documentation
2. **gateway/server.js** - Express gateway server
3. **gateway/providers/index.js** - Provider loader
4. **gateway/providers/ollama.js** - Ollama provider adapter
5. **policies/agent-permissions.json** - Agent permission policies
6. **scripts/verify-tokenless-agents.sh** - Tokenless compliance scanner
7. **docs/ARCHITECTURE.md** - Architecture documentation

## How to Run

```bash
# Make the script executable
chmod +x upload-files.sh

# Run the upload script
./upload-files.sh
```

## What the Script Does

For each file:
1. Retrieves the current SHA from GitHub (if the file exists)
2. Base64 encodes the file content
3. Uses `gh api -X PUT` to create or update the file
4. Reports success/failure with commit SHA

## Expected Output

```
Starting file uploads to BlackRoad-OS-Inc/blackroad-core...

[1/8] Uploading README.md...
✓ SUCCESS - Created README.md
  Commit: abc123def456...

[2/8] Uploading gateway/server.js...
✓ SUCCESS - Created gateway/server.js
  Commit: def456ghi789...

... (continues for all 8 files)

═══════════════════════════════════════════
All 8 files uploaded successfully!
═══════════════════════════════════════════
```

## Error Handling

If the script encounters errors:
- **Missing files**: If `gateway/` or `policies/` directories don't exist, the API will create them automatically
- **Auth error**: Ensure you're logged in with `gh auth login`
- **Permission error**: Verify you have write access to the repository
- **Network error**: Check your internet connection and GitHub status

## Manual Upload (if script fails)

If the script doesn't work, you can manually upload each file using:

```bash
# Example: Upload README.md
CONTENT=$(base64 < README.md)
gh api -X PUT repos/BlackRoad-OS-Inc/blackroad-core/contents/README.md \
  -F message="Add README.md" \
  -F content="$CONTENT" \
  -F branch="main"
```

## Verification

After running the script, verify the files were uploaded:

```bash
# Check files exist in the repo
gh api repos/BlackRoad-OS-Inc/blackroad-core/contents/

# Or visit the GitHub web UI
# https://github.com/BlackRoad-OS-Inc/blackroad-core/
```

## Script Location

The script has been saved to: `/Users/alexa/blackroad/upload-files.sh`

---

**Note**: All files are properly base64 encoded and include appropriate copyright headers. The script handles file creation and updates (with SHA for existing files).
