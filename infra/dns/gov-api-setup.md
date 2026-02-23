# gov.api.blackroad.io DNS Setup

## Route via CF Worker

In the subdomain-router worker, add:
```javascript
"gov-api": { name: "Gov API", handler: handleGovApi, description: "CECE governance API" }
```

Handler proxies to Pi tunnel:
```javascript
function handleGovApi(request) {
  // Proxy to alice:8012 (gov api)
  return Response.redirect("https://gov.blackroad.io", 302);
}
```

## Alice Pi Setup (when ready)
```bash
# Start gov API on alice
pm2 start 'zsh ~/blackroad/tools/gov-api/br-gov-api.sh serve' --name gov-api
# Listens on :8012
```

Add to /etc/cloudflared/config.yml:
```yaml
- hostname: gov.api.blackroad.io
  service: http://localhost:8012
```
