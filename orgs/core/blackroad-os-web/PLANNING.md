# BlackRoad OS Web - Planning

> Development planning for the main web application

## Current Sprint

### Sprint 2026-02 (Feb 3 - Feb 17)

#### Goals
- [ ] Implement real-time agent dashboard
- [ ] Add WebSocket support for live updates
- [ ] Improve mobile responsiveness
- [ ] Add dark/light theme toggle

#### Tasks

| Task | Priority | Status | Assignee |
|------|----------|--------|----------|
| Agent status grid component | P0 | 🔄 In Progress | - |
| WebSocket connection manager | P0 | 📋 Planned | - |
| Mobile nav redesign | P1 | 📋 Planned | - |
| Theme context provider | P2 | 📋 Planned | - |

---

## Backlog

### P0 - Critical

1. **Real-time Dashboard**
   - WebSocket connection to agent service
   - Live status updates for 30K agents
   - Aggregated metrics display
   - Alert notifications

2. **Authentication Flow**
   - OAuth2 integration
   - Session management
   - API key generation UI

### P1 - High Priority

3. **Agent Management UI**
   - Create/edit agent configs
   - Task assignment interface
   - Agent logs viewer
   - Performance graphs

4. **Memory Explorer**
   - Search memories
   - Visualize memory graph
   - Edit/delete memories
   - Export functionality

### P2 - Normal Priority

5. **Settings & Preferences**
   - User profile management
   - Notification preferences
   - API key management
   - Theme customization

---

## Technical Decisions

### TD-001: State Management

**Decision:** Use Zustand over Redux

**Rationale:**
- Simpler API, less boilerplate
- Better TypeScript support
- Smaller bundle size
- Works well with React 19

### TD-002: Real-time Updates

**Decision:** WebSocket with fallback to SSE

**Rationale:**
- WebSocket for bidirectional communication
- SSE fallback for restricted environments
- Reconnection handling built-in

### TD-003: Component Library

**Decision:** Build custom components with Radix primitives

**Rationale:**
- Full control over styling
- Accessibility built-in
- Consistent with design system

---

## Architecture Notes

```
src/
├── app/                 # Next.js App Router
│   ├── (auth)/         # Auth-required routes
│   ├── (public)/       # Public routes
│   └── api/            # API routes
├── components/
│   ├── ui/             # Base UI components
│   ├── agents/         # Agent-specific components
│   ├── memory/         # Memory components
│   └── layout/         # Layout components
├── hooks/              # Custom React hooks
├── lib/                # Utilities
├── store/              # Zustand stores
└── types/              # TypeScript types
```

---

## Performance Targets

| Metric | Current | Target |
|--------|---------|--------|
| LCP | 2.1s | <1.5s |
| FID | 45ms | <100ms |
| CLS | 0.05 | <0.1 |
| Bundle Size | 280KB | <200KB |

---

## Dependencies to Update

| Package | Current | Target | Notes |
|---------|---------|--------|-------|
| next | 16.1.1 | 16.2.x | Wait for stable |
| react | 19.2.3 | Latest | Keep updated |
| zustand | 5.0.9 | 5.x | Stable |

---

*Last updated: 2026-02-05*
