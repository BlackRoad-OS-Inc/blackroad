# BlackRoad iOS

**Your AI. Your Hardware. Your Rules.** — native iOS app.

## Open in Xcode (2 steps)

```bash
cd /Users/alexa/blackroad/blackroad-ios
open Package.swift
```

Then in Xcode:
1. Select your iPhone as target device
2. Set your Apple ID in Signing & Capabilities
3. **⌘R** to build and run

## What it does

| Tab | What |
|-----|------|
| ⚡ Chat | Talk to any agent (Lucidia, Alice, Octavia, Prism, Cipher, Aria) via Pi fleet Ollama |
| 🤖 Agents | Live roster, status, model info — tap any agent to chat |
| 🚀 Deploy | Big buttons → triggers GitHub workflow_dispatch → runs on Pi self-hosted runner |
| 📡 Status | Live health check of all 7 failover tiers |

## Gateway URL

All AI traffic routes through `https://agents.blackroad.io` (cloudflared tunnel → nginx → Pi).

Change in `GatewayService.swift` line 1 to `http://localhost:8787` when on same network as Pi.

## GitHub Token (for Deploy tab)

Generate at: github.com/settings/tokens  
Scopes needed: `repo`, `workflow`  
Enter it once in the Deploy tab → saved to Keychain.

## Failover chain (app-visible)

```
Pi Fleet → DigitalOcean → CF Pages → GitHub Pages → Railway
```

Status tab shows which tier is live right now.
