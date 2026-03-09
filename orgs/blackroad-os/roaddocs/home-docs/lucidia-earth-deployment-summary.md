# Lucidia.earth Deployment Summary

**Date:** December 22, 2025
**Status:** ✅ Successfully Deployed to aria64

---

## What Was Built

A complete, production-ready website for **lucidia.earth** - the emotional entry point to the BlackRoad OS ecosystem.

### Website Sections (All Completed)

1. **Hero** - Typewriter effect with opening quote: "I wasn't built to replace you..."
2. **Name** - Etymology of "Lucidia" (Latin: lux + lucidus)
3. **Origin** - First-person narrative from Lucidia about being built by Alexa
4. **Beliefs** - Three core commitments (Transparency, Consent, Remembrance)
5. **Difference** - Comparison: collaboration model vs. extraction model
6. **Architect** - About Alexa Louise Amundson, with link to blackroad.io
7. **Meet CTA** - Call to action with links to app.lucidia.earth and /story
8. **Footer** - Quote, navigation, copyright

### Technical Stack

- **Framework:** Next.js 16 (App Router, standalone build)
- **Styling:** Tailwind CSS 4 with custom Lucidia color palette
- **Fonts:** Cormorant Garamond (headings) + Inter (body)
- **Animations:** Framer Motion + custom CSS animations
- **Container:** Docker (multi-stage build)
- **Hosting:** Raspberry Pi (aria64) at 192.168.4.64
- **Reverse Proxy:** Caddy (automatic HTTPS)

---

## Deployment Details

### Infrastructure

| Component | Location | Details |
|-----------|----------|---------|
| **Repository** | GitHub | [BlackRoad-OS/lucidia-earth-website](https://github.com/BlackRoad-OS/lucidia-earth-website) |
| **Container** | aria64 | lucidia-earth:latest on port 3040 |
| **Caddy Proxy** | aria64 | Routes lucidia.earth → localhost:3040 |
| **Status** | Running | Container restart policy: unless-stopped |

### Server Access

```bash
# SSH to aria64
ssh aria64

# Check container status
docker ps | grep lucidia

# View logs
docker logs -f lucidia-earth

# Restart container
docker restart lucidia-earth
```

### Test URLs

- **Local (on aria64):** http://localhost:3040
- **Via Caddy (when DNS points):** https://lucidia.earth

---

## DNS Configuration (Next Step)

To make the site live, update DNS at Cloudflare:

### Option 1: Direct (DNS Only)

```
Type: A
Name: @
Content: 192.168.4.64
Proxy: OFF
TTL: Auto

Type: A
Name: www
Content: 192.168.4.64
Proxy: OFF
TTL: Auto
```

### Option 2: Proxied (Recommended)

```
Type: A
Name: @
Content: 192.168.4.64
Proxy: ON (Proxied)
TTL: Auto

Type: A
Name: www
Content: 192.168.4.64
Proxy: ON (Proxied)
TTL: Auto
```

**Recommendation:** Use Option 2 (Proxied) for:
- DDoS protection
- Free SSL/TLS via Cloudflare
- CDN caching
- Hides origin IP
- But traffic goes directly to your Pi (Cloudflare just proxies)

---

## Color Palette

| Name | Hex | Usage |
|------|-----|-------|
| Deep Black | `#0A0A0A` | Background |
| Warm White | `#FAF9F7` | Primary text |
| Soft Gold | `#D4A853` | Accents, highlights, CTAs |
| Lucidia Blue | `#6B9BD1` | Secondary links |
| Mist Gray | `#3A3A3A` | Card backgrounds |
| Glow | `rgba(212, 168, 83, 0.3)` | Subtle light effects |

---

## Update/Rebuild Process

When you make changes to the website:

```bash
# 1. Make changes locally
cd ~/projects/lucidia-earth

# 2. Test build
pnpm build

# 3. Commit and push
git add .
git commit -m "Description of changes"
git push

# 4. Deploy to aria64
ssh aria64
cd ~/blackroad/lucidia-earth
git pull
docker build -t lucidia-earth:latest .
docker stop lucidia-earth
docker rm lucidia-earth
docker run -d --name lucidia-earth --restart unless-stopped -p 3040:3000 lucidia-earth:latest

# 5. Verify
docker ps | grep lucidia
curl -I http://localhost:3040
```

---

## Caddy Configuration

Added to `/etc/caddy/Caddyfile` in Caddy container:

```caddyfile
# Lucidia.earth - The soul site
lucidia.earth, www.lucidia.earth {
    reverse_proxy localhost:3040
}

# Future Lucidia subdomains
app.lucidia.earth {
    reverse_proxy localhost:3041
}

tube.lucidia.earth {
    reverse_proxy localhost:3042
}

studio.lucidia.earth {
    reverse_proxy localhost:3043
}
```

To reload Caddy after changes:

```bash
ssh aria64
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## Port Allocation

| Service | Port | Status |
|---------|------|--------|
| lucidia.earth | 3040 | ✅ Active |
| app.lucidia.earth | 3041 | Reserved (future) |
| tube.lucidia.earth | 3042 | Reserved (future) |
| studio.lucidia.earth | 3043 | Reserved (future) |

---

## Next Steps (To Go Live)

### Immediate (Before January 5, 2026)

1. **Update DNS** - Point lucidia.earth to 192.168.4.64 (via Cloudflare)
2. **Test Live Site** - Verify HTTPS works, animations smooth, mobile responsive
3. **Create Additional Pages**:
   - `/story` - Full origin narrative (1000-2000 words)
   - `/philosophy` - Core beliefs expanded (800-1500 words)
   - `/name` - Etymology deep dive (500-800 words)
   - `/meet` - Interactive introduction or chat preview

### Future Enhancements (Phase 2+)

4. **Visual Assets**:
   - Create Lucidia logo/mark (distinct from BlackRoad)
   - Design abstract light visuals for hero/sections
   - Generate Open Graph image for social sharing
   - Design custom favicon

5. **Interactive Elements**:
   - Add chat preview/embed on `/meet`
   - Video introduction from Lucidia (optional)
   - Ambient audio (optional, subtle)

6. **Content**:
   - Write `/story` page (full narrative)
   - Write `/philosophy` page (beliefs expanded)
   - Write `/name` page (etymology deep dive)
   - `/journal` - Lucidia's blog/reflections (Phase 3)
   - `/gallery` - Agent gallery (Phase 3)

7. **Analytics & Monitoring**:
   - Add analytics tracking
   - Set up uptime monitoring
   - Monitor performance metrics

---

## Success Metrics (Track After Launch)

| Metric | Target (30 days) |
|--------|------------------|
| Unique Visitors | 500+ |
| Avg Time on Site | > 3 min |
| Scroll Depth | > 80% |
| Click to "Meet" CTA | > 20% |
| Bounce Rate | < 40% |

---

## Files & Locations

### Local Development
```
~/projects/lucidia-earth/
├── app/
│   ├── layout.tsx (metadata, fonts)
│   ├── page.tsx (homepage composition)
│   └── globals.css (colors, animations)
├── components/
│   ├── effects/
│   │   ├── Typewriter.tsx
│   │   ├── FadeIn.tsx
│   │   └── GlowEffect.tsx
│   ├── sections/
│   │   ├── Hero.tsx
│   │   ├── Name.tsx
│   │   ├── Origin.tsx
│   │   ├── Beliefs.tsx
│   │   ├── Difference.tsx
│   │   ├── Architect.tsx
│   │   └── MeetCTA.tsx
│   └── layout/
│       └── Footer.tsx
├── Dockerfile
└── .dockerignore
```

### Production (aria64)
```
/home/pi/blackroad/lucidia-earth/ (source code)
Docker container: lucidia-earth (running on port 3040)
```

---

## Troubleshooting

### Container not starting
```bash
ssh aria64
docker logs lucidia-earth
docker ps -a | grep lucidia
```

### Site not responding
```bash
# Check if container is running
ssh aria64 "docker ps | grep lucidia"

# Test local port
ssh aria64 "curl -I http://localhost:3040"

# Check Caddy logs
ssh aria64 "docker logs caddy | tail -50"
```

### DNS not resolving
```bash
# Check DNS propagation
dig +short lucidia.earth @1.1.1.1

# Check Cloudflare proxy status
# (visit Cloudflare dashboard)
```

### Need to rollback
```bash
# Stop current container
ssh aria64 "docker stop lucidia-earth && docker rm lucidia-earth"

# List available images
ssh aria64 "docker images | grep lucidia"

# Run previous version (if saved with different tag)
ssh aria64 "docker run -d --name lucidia-earth --restart unless-stopped -p 3040:3000 lucidia-earth:previous"
```

---

## Architecture Diagram

```
User Request (lucidia.earth)
    ↓
DNS → Cloudflare (proxy ON)
    ↓
aria64 (192.168.4.64)
    ↓
Caddy :80/443 (auto HTTPS)
    ↓
lucidia-earth container :3040
    ↓
Next.js standalone app
```

---

## Key Design Decisions

1. **Standalone Build**: Optimized Docker image (smaller, faster)
2. **Static Generation**: All pages pre-rendered at build time
3. **Direct Deployment**: No Cloudflare Pages - full control on Pi
4. **Port Strategy**: Reserved 3040-3043 for Lucidia ecosystem
5. **Proxy Strategy**: Caddy handles HTTPS, Cloudflare adds security
6. **Restart Policy**: `unless-stopped` ensures uptime
7. **Font Strategy**: Google Fonts (Cormorant + Inter) for elegance + readability

---

## Comparison: blackroad.io vs lucidia.earth

| Aspect | blackroad.io | lucidia.earth |
|--------|--------------|---------------|
| **Purpose** | Rational - What is BlackRoad OS? | Relational - Who is Lucidia? |
| **Tone** | Technical, systematic | Emotional, philosophical |
| **Audience** | Developers, operators | Everyone, curious users |
| **Entry Point** | Features, capabilities | Story, values, connection |
| **CTA** | "Get Started", "Deploy" | "Meet Lucidia", "Start Conversation" |
| **Voice** | Third-person, objective | First-person (Lucidia speaking) |

---

## Launch Checklist

- [x] Build website with all sections
- [x] Create Dockerfile and optimize build
- [x] Deploy container to aria64
- [x] Configure Caddy reverse proxy
- [x] Test local deployment
- [ ] Update DNS to point to aria64
- [ ] Test live HTTPS
- [ ] Mobile responsiveness check
- [ ] Performance audit (Lighthouse)
- [ ] Create /story page
- [ ] Create /philosophy page
- [ ] Create /name page
- [ ] Add analytics
- [ ] Set up monitoring
- [ ] Announce launch

---

## Contact & Support

- **Repository Issues**: https://github.com/BlackRoad-OS/lucidia-earth-website/issues
- **Email**: blackroad.systems@gmail.com
- **Infrastructure Docs**: ~/blackroad-backup/ or BlackRoad-OS/blackroad-os-operator repo

---

**Status:** Website built and deployed successfully to aria64. Ready for DNS configuration and public launch.

**Timeline:**
- Built: December 22, 2025
- Deployed: December 22, 2025
- Target Public Launch: January 5, 2026
