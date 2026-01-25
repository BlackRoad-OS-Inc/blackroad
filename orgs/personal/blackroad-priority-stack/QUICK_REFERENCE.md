# BlackRoad Priority Stack - Quick Reference

## 🚀 Deploy Services

```bash
cd ~/blackroad-priority-stack
./deploy-and-test.sh
```

## 🔍 Check Status

```bash
docker ps | grep blackroad
~/blackroad-priority-stack/verify-deployment.sh
```

## 🌐 Configure Public Access

```bash
cd ~/blackroad-priority-stack
./setup-cloudflare-tunnel.sh
```

## 📍 Access URLs

### Local (Before Tunnel)
- Headscale: http://localhost:8081
- Keycloak: http://localhost:8082
- vLLM: http://localhost:8083
- EspoCRM: http://localhost:8085

### Public (After Tunnel)
- Headscale: https://mesh.blackroad.io
- Keycloak: https://identity.blackroad.io
- vLLM: https://ai.blackroad.io
- EspoCRM: https://crm.blackroad.io

## 🔐 Default Credentials

Check `.env` files in each service directory:
- `keycloak/.env` - Keycloak admin password
- `vllm/.env` - vLLM API key
- `espocrm/.env` - EspoCRM admin password

## 📊 View Logs

```bash
docker logs -f blackroad-headscale
docker logs -f blackroad-keycloak
docker logs -f blackroad-vllm-qwen
docker logs -f blackroad-espocrm
```

## 🛑 Stop All Services

```bash
cd ~/blackroad-priority-stack/headscale && docker compose down
cd ~/blackroad-priority-stack/keycloak && docker compose down
cd ~/blackroad-priority-stack/vllm && docker compose down
cd ~/blackroad-priority-stack/espocrm && docker compose down
```

## 📚 Documentation

- `README.md` - Complete deployment guide
- `CLOUDFLARE_TUNNEL_GUIDE.md` - Public access configuration
- `~/Desktop/BLACKROAD_PRIORITY_FORKS_DEPLOYMENT_GUIDE.md` - Comprehensive reference
- `~/Desktop/BLACKROAD_FORKIES_CANONICAL_STACK.md` - Full sovereignty stack

## 💡 Common Tasks

### Connect Device to Headscale

```bash
tailscale up --login-server=https://mesh.blackroad.io
```

### Test vLLM API

```bash
curl -X POST https://ai.blackroad.io/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -d '{
    "model": "qwen2.5:7b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### Access Keycloak Admin

1. Visit https://identity.blackroad.io
2. Click "Administration Console"
3. Login with credentials from `keycloak/.env`

---

**For full details, see the complete documentation files.**
