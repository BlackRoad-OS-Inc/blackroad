# blackroad-ai-platform - Pi Deployment

**Description:** AI Platform API
**Target Pi:** lucidia (192.168.4.38)
**Port:** 3000

## Deployment Instructions

1. Copy files to Pi:
```bash
scp -r /Users/alexa/blackroad-ai-platform-pi-deploy pi@192.168.4.38:~/
```

2. SSH into Pi:
```bash
ssh pi@192.168.4.38
```

3. Deploy:
```bash
cd blackroad-ai-platform-pi-deploy
./deploy.sh
```

4. Verify:
```bash
curl http://localhost:3000
curl http://localhost:3000/health
```

5. Monitor:
```bash
docker logs -f blackroad-ai-platform
```

## Management

- Stop: `docker-compose down`
- Restart: `docker-compose restart`
- Logs: `docker-compose logs -f`
- Status: `docker-compose ps`
