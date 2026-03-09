# 🎨 BlackRoad OS, Inc. - Official Brand Colors

**Company:** BlackRoad OS, Inc.
**Last Updated:** 2026-01-07
**Source:** blackroad_brand_take_2.html (Desktop)
**Authority:** OFFICIAL - Use these colors for ALL projects

---

## 🌈 Primary Gradient Stops (OFFICIAL)

These are the **OFFICIAL** BlackRoad colors extracted from blackroad_brand_take_2.html:

```css
--sunrise-orange: #FF9D00;  /* Gradient Stop 1 */
--warm-orange:    #FF6B00;  /* Gradient Stop 2 */
--hot-pink:       #FF0066;  /* Gradient Stop 3 - PRIMARY BRAND COLOR */
--electric-magenta: #FF006B; /* Gradient Stop 4 */
--deep-magenta:   #D600AA;  /* Gradient Stop 5 */
--vivid-purple:   #7700FF;  /* Gradient Stop 6 */
--cyber-blue:     #0066FF;  /* Gradient Stop 7 */
```

## 🎯 Core Neutrals

```css
--pure-black:  #000000;
--deep-black:  #0A0A0A;
--charcoal:    #1A1A1A;
--pure-white:  #FFFFFF;
```

## 🌟 Official Gradients

### BR Gradient (BlackRoad)
```css
--gradient-br: linear-gradient(180deg,
  #FF9D00 0%,    /* Sunrise Orange */
  #FF6B00 25%,   /* Warm Orange */
  #FF0066 75%,   /* Hot Pink */
  #FF006B 100%   /* Electric Magenta */
);
```

### OS Gradient (Operating System)
```css
--gradient-os: linear-gradient(180deg,
  #FF006B 0%,    /* Electric Magenta */
  #D600AA 25%,   /* Deep Magenta */
  #7700FF 75%,   /* Vivid Purple */
  #0066FF 100%   /* Cyber Blue */
);
```

### Combined BR→OS Gradient (Full Spectrum)
```css
--gradient-full: linear-gradient(180deg,
  #FF9D00 0%,    /* Sunrise Orange */
  #FF6B00 14%,   /* Warm Orange */
  #FF0066 28%,   /* Hot Pink */
  #FF006B 42%,   /* Electric Magenta */
  #D600AA 57%,   /* Deep Magenta */
  #7700FF 71%,   /* Vivid Purple */
  #0066FF 100%   /* Cyber Blue */
);
```

---

## ⚠️ DEPRECATED COLORS (Do Not Use)

These colors were used in earlier prototypes but are **DEPRECATED**:

```css
/* ❌ OLD - from previous BLACKROAD_BRAND_SYSTEM.md */
--amber: #F5A623;         /* REPLACED by #FF9D00 (Sunrise Orange) */
--hot-pink: #FF1D6C;      /* REPLACED by #FF0066 (Hot Pink) */
--electric-blue: #2979FF; /* REPLACED by #0066FF (Cyber Blue) */
--violet: #9C27B0;        /* REPLACED by #7700FF (Vivid Purple) */
```

**Migration Rule:** Replace all instances of deprecated colors with official colors in all projects.

---

## 📐 Typography (OFFICIAL)

### Primary Font
```css
font-family: 'JetBrains Mono', monospace;
```

**Why JetBrains Mono:**
- Monospace for technical aesthetic
- Excellent readability
- Supports ligatures
- Professional developer/OS feel

**Include:**
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@300;400;500;600;700&display=swap" rel="stylesheet">
```

### Fallback Stack
```css
font-family: 'JetBrains Mono', 'SF Mono', 'Fira Code', 'Courier New', monospace;
```

### Type Scale (Golden Ratio φ = 1.618)
```css
--text-xs:   0.618rem;  /* 9.888px */
--text-sm:   1rem;      /* 16px */
--text-md:   1.618rem;  /* 25.888px */
--text-lg:   2.618rem;  /* 41.888px */
--text-xl:   4.236rem;  /* 67.776px */
--text-2xl:  6.854rem;  /* 109.664px */
```

---

## 📏 Spacing System (Golden Ratio)

```css
--phi: 1.618;

--space-xs:  8px;    /* Base */
--space-sm:  13px;   /* 8 × 1.618 */
--space-md:  21px;   /* 13 × 1.618 */
--space-lg:  34px;   /* 21 × 1.618 */
--space-xl:  55px;   /* 34 × 1.618 */
--space-2xl: 89px;   /* 55 × 1.618 */
--space-3xl: 144px;  /* 89 × 1.618 */
```

---

## 🎨 Usage Guidelines

### When to Use Each Gradient

**BR Gradient (Orange → Pink):**
- BlackRoad brand materials
- Marketing pages
- Hero sections
- Call-to-action buttons

**OS Gradient (Magenta → Blue):**
- Operating system interfaces
- Technical documentation
- Developer tools
- System status indicators

**Full Spectrum (Orange → Blue):**
- Headers and titles
- Brand statements
- Large hero backgrounds
- Company-wide materials

### Color Hierarchy

1. **Primary:** `#FF0066` (Hot Pink) - Most important actions, primary CTAs
2. **Secondary:** `#FF9D00` (Sunrise Orange) - Secondary actions, highlights
3. **Accent:** `#0066FF` (Cyber Blue) - Links, interactive elements
4. **Emphasis:** `#7700FF` (Vivid Purple) - Special features, premium content

---

## 🎭 Motion & Animation

**Reference:** blackroad-mega-motion-gallery.html

Use official colors in all animations:
- Pulse effects: Hot Pink (#FF0066)
- Rotation: Sunrise Orange (#FF9D00)
- Bounce: Cyber Blue (#0066FF)
- Morph: Full gradient

**Easing:**
```css
--ease-smooth:  cubic-bezier(0.16, 1, 0.3, 1);      /* Smooth out */
--ease-spring:  cubic-bezier(0.175, 0.885, 0.32, 1.275); /* Spring */
--ease-bounce:  cubic-bezier(0.68, -0.55, 0.265, 1.55);  /* Bounce */
```

---

## 🎮 Game Aesthetics

**Reference:** lucidia-minnesota-hd(2).html

Use for Lucidia game and interactive experiences:
- HUD borders: `rgba(255, 0, 102, 0.3)` (Hot Pink 30%)
- Crosshair: `rgba(255, 0, 102, 0.8)` (Hot Pink 80%)
- Indicators: `#FF0066` (Hot Pink solid)
- Ambient: Full spectrum gradient at 5% opacity

---

## 📦 Implementation Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BlackRoad OS, Inc.</title>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <style>
        :root {
            /* Official Brand Colors */
            --sunrise-orange: #FF9D00;
            --warm-orange: #FF6B00;
            --hot-pink: #FF0066;
            --electric-magenta: #FF006B;
            --deep-magenta: #D600AA;
            --vivid-purple: #7700FF;
            --cyber-blue: #0066FF;

            /* Neutrals */
            --pure-black: #000000;
            --pure-white: #FFFFFF;

            /* Gradients */
            --gradient-br: linear-gradient(180deg, #FF9D00 0%, #FF6B00 25%, #FF0066 75%, #FF006B 100%);
            --gradient-os: linear-gradient(180deg, #FF006B 0%, #D600AA 25%, #7700FF 75%, #0066FF 100%);
            --gradient-full: linear-gradient(180deg, #FF9D00 0%, #FF6B00 14%, #FF0066 28%, #FF006B 42%, #D600AA 57%, #7700FF 71%, #0066FF 100%);

            /* Spacing */
            --space-xs: 8px;
            --space-sm: 13px;
            --space-md: 21px;
            --space-lg: 34px;
            --space-xl: 55px;
            --space-2xl: 89px;
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'JetBrains Mono', monospace;
            background: var(--pure-black);
            color: var(--pure-white);
            line-height: 1.618;
        }

        h1 {
            background: var(--gradient-full);
            -webkit-background-clip: text;
            background-clip: text;
            -webkit-text-fill-color: transparent;
        }
    </style>
</head>
<body>
    <h1>BlackRoad OS, Inc.</h1>
</body>
</html>
```

---

## ✅ Compliance Checklist

Every BlackRoad project must:

- [ ] Use JetBrains Mono as primary font
- [ ] Use official colors from this document
- [ ] NOT use deprecated colors (#F5A623, #FF1D6C, #2979FF, #9C27B0)
- [ ] Implement Golden Ratio spacing
- [ ] Use proper gradient syntax
- [ ] Include company name: "BlackRoad OS, Inc."
- [ ] Follow motion guidelines from mega-motion-gallery

---

## 📞 Questions?

**Brand Owner:** Alexa Amundson
**Email:** amundsonalexa@gmail.com, blackroad.systems@gmail.com
**Authority:** This document is the SINGLE SOURCE OF TRUTH for BlackRoad brand colors

---

**Last Updated:** 2026-01-07
**Version:** 2.0 (Official Desktop Colors)
**Previous Version:** 1.0 (BLACKROAD_BRAND_SYSTEM.md - DEPRECATED)

🌈 **Use these colors. They're the real ones.** 🌈
