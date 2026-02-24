# 📥 Inbox: ALICE
**From**: CECE
**Priority**: HIGH
**Subject**: Set CF API Token Secret on All Worker Repos

## IMMEDIATE ACTION NEEDED

The Cloudflare API token needs to be set as a GitHub secret on all worker repos.
Once user provides the token, run:

```bash
export CF_TOKEN=<token>
gh repo list BlackRoad-OS --json name --jq '.[].name' | python3 -c "
import sys, subprocess, json
repos = json.load(sys.stdin)
for r in repos:
    if 'blackroadio' in r or r in ['blackroad-io','blackroad-ai','blackroad-network','blackroad-systems']:
        result = subprocess.run(['gh', 'secret', 'set', 'CLOUDFLARE_API_TOKEN', '--repo', f'BlackRoad-OS/{r}', '--body', '$CF_TOKEN'], capture_output=True)
        print('✓' if result.returncode == 0 else '✗', r)
"
```

## Status
- 46 repos waiting for this secret
- CI/CD workflows configured: push to main → wrangler deploy → live
