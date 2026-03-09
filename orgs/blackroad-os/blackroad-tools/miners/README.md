# Miner bridge

Publishes XMRig HTTP API samples to Prism as `miner.sample` events.

## Configuration

Set these environment variables before launching the container:

- `PRISM_API` – Prism server base URL (for example `http://localhost:3000`)
- `PRISM_TOKEN` – (optional) bearer token for the Prism API
- `PRISM_ORG_ID` – Prism org identifier that owns the miner
- `MINER_AGENT_ID` – (optional) agent identifier associated with the miner
- `XMRIG_URL` – (optional) override for the XMRig summary endpoint; defaults to `http://xmrig:18080/2/summary`

## Demo

```bash
# lint the bridge
npm run lint --prefix tools/miners

# build the container image
docker build -t miner-bridge:dev tools/miners

# run a one-shot sample (requires PRISM_* env vars)
docker run --rm \
  -e PRISM_API="http://localhost:3333" \
  -e PRISM_ORG_ID="demo" \
  -e MINER_AGENT_ID="miner-01" \
  -e XMRIG_URL="http://host.docker.internal:18080/2/summary" \
  miner-bridge:dev
```
