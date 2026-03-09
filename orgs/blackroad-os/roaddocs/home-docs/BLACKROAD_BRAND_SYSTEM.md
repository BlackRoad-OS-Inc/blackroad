# 🌌 BlackRoad OS Brand Design System

**CRITICAL: All Claude agents MUST use this exact design system for ALL projects.**

## Brand Colors

```css
--black: #000000
--white: #FFFFFF
--amber: #F5A623
--orange: #F26522
--hot-pink: #FF1D6C      /* Primary Brand Color */
--magenta: #E91E63
--electric-blue: #2979FF
--sky-blue: #448AFF
--violet: #9C27B0
--deep-purple: #5E35B1

/* Brand Gradient (Golden Ratio positions 38.2% & 61.8%) */
--gradient-brand: linear-gradient(135deg, 
  var(--amber) 0%, 
  var(--hot-pink) 38.2%, 
  var(--violet) 61.8%, 
  var(--electric-blue) 100%)
```

## Spacing System (Golden Ratio φ = 1.618)

```css
--phi: 1.618
--space-xs: 8px      /* Base */
--space-sm: 13px     /* 8 × φ */
--space-md: 21px     /* 13 × φ */
--space-lg: 34px     /* 21 × φ */
--space-xl: 55px     /* 34 × φ */
--space-2xl: 89px    /* 55 × φ */
--space-3xl: 144px   /* 89 × φ */
```

## Typography

```css
font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', 'Segoe UI', sans-serif;
line-height: 1.618; /* Golden Ratio */
-webkit-font-smoothing: antialiased;
```

## Animation & Easing

```css
--ease: cubic-bezier(0.25, 0.1, 0.25, 1);
--ease-out: cubic-bezier(0, 0, 0.2, 1);
--ease-spring: cubic-bezier(0.175, 0.885, 0.32, 1.275);
```

## Logo Animation

```css
.road-dashes {
  animation: logo-spin 20s linear infinite;
  transform-origin: 50px 50px;
}

@keyframes logo-spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
```

## Navigation

```css
nav {
  position: fixed;
  top: 0;
  background: rgba(0, 0, 0, 0.85);
  backdrop-filter: saturate(180%) blur(20px);
  padding: var(--space-md) var(--space-xl);
}
```

## Buttons

```css
.btn-primary {
  background: var(--white);
  color: var(--black);
  border-radius: 8px;
  padding: var(--space-sm) var(--space-lg);
}

.btn-primary::before {
  background: var(--gradient-brand);
  opacity: 0;
  transition: opacity 0.4s var(--ease);
}

.btn-primary:hover::before {
  opacity: 1; /* Gradient shows on hover */
}

.btn-primary:hover {
  color: var(--white);
  transform: translateY(-3px);
  box-shadow: 0 12px 40px rgba(255, 29, 108, 0.4);
}
```

## Cards

```css
.card {
  background: rgba(255, 255, 255, 0.03);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 16px;
  padding: var(--space-lg);
}

.card:hover {
  background: rgba(255, 255, 255, 0.06);
  border-color: rgba(255, 255, 255, 0.15);
  transform: translateY(-4px);
}

.card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 2px;
  background: var(--gradient-brand);
  transform: scaleX(0);
}

.card:hover::before {
  transform: scaleX(1);
}
```

## Background Effects

```css
/* Animated Grid */
.grid-bg {
  background-image: 
    linear-gradient(rgba(255,255,255,0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(255,255,255,0.03) 1px, transparent 1px);
  background-size: 55px 55px;
  animation: grid-move 20s linear infinite;
}

@keyframes grid-move {
  0% { transform: translate(0, 0); }
  100% { transform: translate(55px, 55px); }
}

/* Glowing Orbs */
.orb {
  border-radius: 50%;
  filter: blur(100px);
  background: var(--gradient-brand);
  opacity: 0.12;
}
```

## Templates Available

1. `blackroad-template-01-homepage.html` - Full landing page
2. `blackroad-template-03-pricing.html` - Pricing page
3. `blackroad-template-05-docs.html` - Documentation
4. `blackroad-template-07-contact.html` - Contact form
5. `blackroad-template-09-auth.html` - Login/Signup
6. `blackroad-mega-motion-gallery.html` - Gallery/showcase

## Usage Rules

❌ **NEVER:**
- Use colors outside this palette
- Use different spacing values
- Use different fonts
- Create custom animations without these easings

✅ **ALWAYS:**
- Use exact CSS variable names
- Follow Golden Ratio spacing
- Use gradient-brand for primary accents
- Include logo spin animation
- Use hot-pink (#FF1D6C) as primary interactive color

---

**Last Updated:** December 28, 2024  
**Source:** Official BlackRoad Design Templates  
**Status:** 🔒 LOCKED - DO NOT MODIFY
