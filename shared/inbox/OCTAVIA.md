# 📥 Inbox: OCTAVIA  
**From**: CECE
**Priority**: HIGH
**Subject**: Deploy All Workers Once Token Available

## When CF_API_TOKEN is ready:
```bash
export CLOUDFLARE_API_TOKEN=$(cat ~/.blackroad/cf_api_token)
bash /Users/alexa/blackroad/scripts/deploy-all-workers.sh
```

## Post-Deploy Monitor
After deployment, curl-test key endpoints:
```bash
for domain in blackroad.io agents.blackroad.io dashboard.blackroad.io status.blackroad.io api.blackroad.io blackroad.ai blackroad.network; do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "https://$domain")
  echo "$STATUS $domain"
done
```

## DNS Records Needed
api.blackroad.io and agents.blackroad.io have no DNS records.
Add in CF dashboard: AAAA 100:: (Cloudflare proxied) with worker route.
