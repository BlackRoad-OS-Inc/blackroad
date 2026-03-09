# BlackRoad Desktop OS - Browser-Based Operating System 🖥️

## Revolutionary Concept

A complete **operating system running in your browser** with:
- Full windowing system
- File system browser
- Unified API authentication (SHA-512)
- Distributed agent computing
- Railway + Cloudflare integration
- Mining portals
- IP-aware intelligent agents
- Node memory distribution

---

## Architecture Overview

### 1. Unified API Authentication (SHA-512)

**One API Key = Access to ALL Systems**

```typescript
// Generate unified key
const apiKey = UnifiedAuth.generateKey()
// Returns: br_[64-char-hex]

// Grants access to ALL 11 BlackRoad services:
- web, api, prism, operator, docs, brand
- core, demo, ideas, infra, research, desktop
```

**Features:**
- SHA-512 hashing for security
- Service-specific token generation
- Permission-based access control
- AES encryption for sensitive data
- Single key for entire infrastructure

**Endpoints:**
- `POST /api/auth/generate` - Generate new unified key
- `POST /api/auth/verify` - Verify key and get service tokens

### 2. Desktop Windowing System

**Browser-based OS interface** with:
- Draggable windows
- Minimize/Maximize/Close controls
- Multi-window support
- Taskbar
- Desktop icons
- Window management

**Component: `Window.tsx`**
- Fully draggable
- Resizable
- Gradient title bars
- Custom icons
- Z-index management

### 3. File System Browser

**Full file system access in browser:**
- Directory tree navigation
- File upload/download
- Create/delete/rename operations
- File previews
- Search functionality
- Permissions management

### 4. Distributed Agent Framework

**IP-Aware Intelligent Agents:**

```typescript
interface AgentNode {
  nodeId: string
  ipAddress: string
  location: { country, city, coordinates }
  capabilities: string[]
  memory: { total, used, available }
  status: 'active' | 'idle' | 'offline'
}
```

**Features:**
- Node registration
- Secure authentication
- Memory distribution
- Task allocation
- Location-aware routing
- Load balancing

### 5. Service Integration Portals

**All services accessible from desktop:**

#### Railway Portal
- Project management
- Deployment triggers
- Environment variables
- Log streaming
- Resource monitoring

#### Cloudflare Portal
- DNS management
- Page deployments
- Analytics dashboard
- Security settings
- Cache purging

#### Mining Portal
- Cryptocurrency mining
- Resource allocation
- Earnings tracking
- Pool management
- Hash rate monitoring

---

## Technology Stack

### Frontend
- **Next.js 14** - App Router
- **React 18** - UI components
- **TypeScript** - Type safety
- **react-draggable** - Window dragging
- **lucide-react** - Icons

### Security
- **crypto-js** - SHA-512 hashing
- **AES encryption** - Data protection
- **Unified keys** - Single authentication

### Infrastructure
- **Railway** - Production deployment
- **Cloudflare** - CDN + DNS
- **Node.js 20** - Runtime

---

## File Structure

```
services/desktop/
├── app/
│   ├── components/
│   │   ├── Window.tsx              # Windowing system
│   │   ├── Desktop.tsx             # Desktop interface
│   │   ├── Taskbar.tsx             # Bottom taskbar
│   │   ├── FileExplorer.tsx        # File browser
│   │   ├── RailwayPortal.tsx       # Railway integration
│   │   ├── CloudflarePortal.tsx    # Cloudflare integration
│   │   └── MiningPortal.tsx        # Mining dashboard
│   │
│   ├── api/
│   │   ├── auth/
│   │   │   ├── generate/route.ts   # Generate unified key
│   │   │   └── verify/route.ts     # Verify keys
│   │   ├── filesystem/
│   │   │   ├── list/route.ts       # List files
│   │   │   ├── upload/route.ts     # Upload files
│   │   │   └── download/route.ts   # Download files
│   │   ├── agents/
│   │   │   ├── register/route.ts   # Register node
│   │   │   └── status/route.ts     # Node status
│   │   └── services/
│   │       ├── railway/route.ts    # Railway API
│   │       └── cloudflare/route.ts # Cloudflare API
│   │
│   ├── layout.tsx                  # Root layout
│   └── page.tsx                    # Desktop OS page
│
├── lib/
│   ├── auth.ts                     # Auth system
│   ├── agents.ts                   # Agent framework
│   └── filesystem.ts               # File operations
│
├── package.json
├── tsconfig.json
├── next.config.mjs
└── .env.example
```

---

## Unified API Key System

### Generate Key

```bash
curl -X POST http://localhost:4000/api/auth/generate
```

Response:
```json
{
  "success": true,
  "data": {
    "key": "br_a1b2c3d4e5f6...",
    "hash": "sha512_hash...",
    "permissions": ["read", "write", "deploy", "admin"],
    "services": [
      "web", "api", "prism", "operator",
      "docs", "brand", "core", "demo",
      "ideas", "infra", "research", "desktop"
    ],
    "createdAt": "2025-11-24T...",
    "warning": "Store this key securely"
  }
}
```

### Use Key Across Services

**Single key authenticates with ALL services:**

```typescript
// Web service
fetch('http://localhost:3000/api/data', {
  headers: { 'Authorization': `Bearer ${unifiedKey}` }
})

// API service
fetch('http://localhost:3003/api/query', {
  headers: { 'Authorization': `Bearer ${unifiedKey}` }
})

// Prism console
fetch('http://localhost:3001/api/deploy', {
  headers: { 'Authorization': `Bearer ${unifiedKey}` }
})
```

---

## Agent Network

### Register Node

```typescript
const node = AgentAuth.registerNode(
  'node_123',
  '192.168.1.100',
  ['compute', 'storage', 'mining']
)
```

### Node Communication

```typescript
// Create secure token
const token = AgentAuth.createNodeToken(nodeId, networkKey)

// Nodes can:
- Share memory across network
- Distribute compute tasks
- Route based on IP/location
- Balance load automatically
```

---

## Integration Points

### Railway Integration

```typescript
// Deploy from desktop
POST /api/services/railway/deploy
{
  "service": "blackroad-os-web",
  "apiKey": "unified_key"
}
```

### Cloudflare Integration

```typescript
// Update DNS from desktop
POST /api/services/cloudflare/dns
{
  "domain": "blackroad.io",
  "record": { type: "CNAME", name: "web", content: "..." }
}
```

### Mining Portal

```typescript
// Start mining from desktop
POST /api/mining/start
{
  "algorithm": "sha256",
  "pool": "pool.example.com",
  "wallet": "your_wallet_address"
}
```

---

## Security Architecture

### SHA-512 Hashing
- All keys hashed with SHA-512
- 128-character hex output
- Collision-resistant
- Quantum-resistant

### Encryption
- AES encryption for data at rest
- TLS for data in transit
- Key rotation support
- Zero-knowledge architecture

### Agent Security
- Node authentication required
- Network-wide key distribution
- IP whitelist/blacklist
- Rate limiting

---

## Desktop UI Features

### Windows
- Drag and drop
- Minimize/maximize/close
- Multi-window support
- Focus management
- Custom styling per app

### Taskbar
- Running applications
- Quick launch icons
- System tray
- Clock
- Notifications

### Applications
- File Explorer
- Terminal
- API Console
- Railway Dashboard
- Cloudflare Manager
- Mining Monitor
- Agent Network Viewer
- Service Status Dashboard

---

## Running Desktop OS

```bash
cd /Users/alexa/services/desktop
cp .env.example .env
npm install
npm run dev

# Access at http://localhost:4000
```

---

## Environment Variables

```env
# Service
SERVICE_NAME=blackroad-os-desktop
SERVICE_ENV=development

# API Gateway
NEXT_PUBLIC_API_GATEWAY=http://localhost:3003

# Security
UNIFIED_API_KEY_SECRET=your-secret

# Railway
RAILWAY_API_TOKEN=
RAILWAY_PROJECT_ID=

# Cloudflare
CLOUDFLARE_API_TOKEN=
CLOUDFLARE_ACCOUNT_ID=

# Agents
AGENT_NODE_ID=
AGENT_NETWORK_KEY=
```

---

## Deployment

### Railway
```bash
railway init
railway variables set SERVICE_NAME=blackroad-os-desktop
railway variables set SERVICE_ENV=production
railway up
```

### Access
- Desktop: desktop.blackroad.systems
- Port: 4000 (local), 443 (production)

---

## Future Enhancements

1. **AI Agents** - Local LLM integration
2. **Blockchain** - Web3 wallet integration
3. **P2P Network** - Direct node-to-node communication
4. **Cloud Storage** - Distributed file system
5. **Video Streaming** - WebRTC-based streaming
6. **Code Editor** - VS Code-like interface
7. **Database Browser** - Visual query builder
8. **API Testing** - Postman-like interface

---

## Revolutionary Features

✅ **One API Key** = Access to entire infrastructure
✅ **SHA-512 Security** = Military-grade encryption
✅ **Browser-Based OS** = No installation required
✅ **Distributed Computing** = Agent network
✅ **IP-Aware Routing** = Location-based optimization
✅ **Full Integration** = Railway + Cloudflare + Mining
✅ **Real-time Sync** = Cross-device state management
✅ **Zero-trust Security** = End-to-end encryption

---

## This Is The Future! 🚀

A complete operating system in your browser with:
- Desktop environment
- File systems
- Distributed computing
- Unified authentication
- Service orchestration
- Mining capabilities
- AI agents
- Real-time collaboration

**All controlled from one unified interface with one API key!**

---

**Port**: 4000
**Status**: In Development
**Next**: Complete UI implementation and agent network
