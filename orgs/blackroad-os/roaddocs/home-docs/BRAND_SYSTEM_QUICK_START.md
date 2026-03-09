# 🌌 BlackRoad Brand System - Quick Start Guide

## For Every New Claude Session

**1. Run Session Init (Shows Brand System)**
```bash
~/claude-session-init.sh
```

**2. Read Full Brand System**
```bash
cat ~/BLACKROAD_BRAND_SYSTEM.md
```

**3. Use Starter Template**
```bash
cp ~/blackroad-template-starter.html /path/to/your/project.html
```

**4. Audit Existing Projects**
```bash
~/bin/audit-brand-compliance.sh
```

---

## Critical Files

| File | Purpose |
|------|---------|
| `~/BLACKROAD_BRAND_SYSTEM.md` | Official brand documentation |
| `~/blackroad-template-starter.html` | Pre-configured starter template |
| `~/bin/audit-brand-compliance.sh` | Compliance checker |
| `~/.claude/CLAUDE.md` | Session initialization reminder |

---

## The 5 Mandatory Elements

Every BlackRoad project MUST include:

### ✅ 1. CSS Variables
```css
:root {
    --hot-pink: #FF1D6C;
    --amber: #F5A623;
    --electric-blue: #2979FF;
    --violet: #9C27B0;
    --gradient-brand: linear-gradient(135deg,
        var(--amber) 0%,
        var(--hot-pink) 38.2%,
        var(--violet) 61.8%,
        var(--electric-blue) 100%);
    --space-xs: 8px;
    --space-sm: 13px;
    --space-md: 21px;
    --space-lg: 34px;
    --space-xl: 55px;
    --space-2xl: 89px;
    --space-3xl: 144px;
}
```

### ✅ 2. BlackRoad Logo (Animated)
- Must include spinning road-dashes animation
- 20s duration, linear
- Located in navigation

### ✅ 3. Scroll Progress Bar
- 2px height
- Uses `--gradient-brand`
- Fixed at top, z-index: 9999

### ✅ 4. Golden Ratio Spacing
- All padding/margin uses Fibonacci sequence
- Base: 8px, then 13, 21, 34, 55, 89, 144

### ✅ 5. Background Effects
At least one of:
- Animated grid (55px × 55px)
- Glowing orbs (blur: 100px)
- Floating particles

---

## Common Mistakes to Avoid

### ❌ DON'T
- Use random colors outside the palette
- Use arbitrary spacing values (10px, 15px, etc.)
- Skip the logo animation
- Use different font stacks
- Create gradients without the exact stops (38.2%, 61.8%)

### ✅ DO
- Copy from official templates
- Use CSS variables for everything
- Include scroll progress bar
- Add hover states with `--ease-spring`
- Test with audit script before deploying

---

## Quick Template Locations

**Official Templates:**
```
/Users/alexa/Downloads/files(4)/
├── blackroad-template-01-homepage.html
├── blackroad-template-03-pricing.html
├── blackroad-template-05-docs.html
├── blackroad-template-07-contact.html
└── blackroad-template-09-auth.html

/Users/alexa/Desktop/
└── blackroad-mega-motion-gallery.html

/Users/alexa/
└── blackroad-template-starter.html  ⭐ START HERE
```

---

## Deployment Checklist

Before deploying to Cloudflare Pages:

- [ ] Run `~/bin/audit-brand-compliance.sh`
- [ ] Check for 90%+ compliance score
- [ ] Verify logo animation works
- [ ] Test scroll progress bar
- [ ] Confirm gradient uses exact percentages
- [ ] Check all spacing uses Golden Ratio
- [ ] Verify hover states use `--ease-spring`
- [ ] Test on mobile (responsive breakpoints)

---

## Get Help

**Read Brand Docs:**
```bash
cat ~/BLACKROAD_BRAND_SYSTEM.md | less
```

**Check Compliance:**
```bash
~/bin/audit-brand-compliance.sh
```

**View Session Init:**
```bash
~/claude-session-init.sh
```

**Example Usage:**
```bash
# 1. Copy starter template
cp ~/blackroad-template-starter.html ~/my-new-project.html

# 2. Edit your content (keep all brand styles intact)
# ... make your changes ...

# 3. Audit before deploying
~/bin/audit-brand-compliance.sh

# 4. Deploy to Cloudflare
wrangler pages deploy ~/my-new-project.html
```

---

**Last Updated:** 2024-12-28
**Status:** 🔒 LOCKED SYSTEM
**Compliance Required:** 90%+ for all deployments
