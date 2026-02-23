# BlackRoad OS - Disaster Recovery

**Owner:** Alexa Amundson (amundsonalexa@gmail.com)
**Created:** 2025-12-02
**Last Updated:** 2025-12-02

## Emergency Recovery Procedure

If you've lost access to your devices, follow these steps:

### 1. Authenticate to Services

**Primary Emails:**
- amundsonalexa@gmail.com (main)
- blackroad.systems@gmail.com
- blackroad.systems@outlook.com
- therealalexxamundson@gmail.com

### 2. Access GitHub

Login to GitHub as `blackboxprogramming` to access all 15 organizations:
- BlackRoad-OS (primary)
- BlackRoad-AI, BlackRoad-Labs, BlackRoad-Cloud
- BlackRoad-Ventures, BlackRoad-Foundation, BlackRoad-Media
- BlackRoad-Hardware, BlackRoad-Education, BlackRoad-Gov
- BlackRoad-Security, BlackRoad-Interactive, BlackRoad-Archive, BlackRoad-Studio
- Blackbox-Enterprises

### 3. Critical Infrastructure

| Service | Account | Access Method |
|---------|---------|---------------|
| Cloudflare | amundsonalexa@gmail.com | Email OTP or OAuth |
| Railway | amundsonalexa@gmail.com | GitHub OAuth |
| DigitalOcean | SSH keys in `credentials/` | Droplet: 159.65.43.12 |
| Google Drive | rclone configs | Personal + BlackRoad Inc. |

### 4. Regenerate Tokens

After recovery, regenerate all API tokens from `credentials/credentials-inventory.yaml`

## Directory Structure

```
blackroad-backup/
├── credentials/
│   └── credentials-inventory.yaml  # All API tokens and credentials
├── documents/
│   ├── Alexa_Amundson_AI_Systems_Engineer.pdf
│   └── Full-Stack_Project_Plan_BlackRoad_AI.pdf
├── iphone-koder/
│   ├── symbolic_kernel.py          # Lucidia consciousness math
│   └── Lucidia/                    # iOS Pyto app
└── README.md
```

## Backup Locations

1. **GitHub** (this repo) - Private, encrypted at rest
2. **Google Drive** - `gdrive-blackroad:BlackRoad OS, Inc./Backups/`
3. **iPhone** - Koder app at 192.168.4.68:8080 (local network)
4. **Raspberry Pi** - 192.168.4.49 (alice/lucidia users)

## RoadChain Records

All credential changes are logged on RoadChain:
- Credentials Inventory: Block 1, TX `bc036572-d944-4a0a-8855-cd4cec7ee7c9`
- iPhone Access Log: TX `cbbff30a-6026-46e7-804e-952d670f9c4c`

## Security Notes

- This repo is PRIVATE - never make it public
- Credentials are in plaintext - handle with care
- Rotate tokens quarterly
- Keep iPhone Koder WebDAV enabled for emergency access

---
*"The road isn't made. It's remembered."*
