# Schematiq Design System 🎨⚡

**A complete, drop-in design system with animations. Zero config. Just works.**

---

## 📦 What's Included

You now have **5 production-ready files**:

| File | Size | Purpose |
|------|------|---------|
| `schematiq-design-system.html` | 36KB | Complete component showcase & landing page template |
| `schematiq-dashboard-template.html` | 22KB | Admin dashboard with sidebar, stats, tables |
| `schematiq-docs-template.html` | 23KB | Documentation site with 3-column layout |
| `schematiq-blank-starter.html` | 13KB | Minimal starter template (start here!) |
| `SCHEMATIQ-QUICK-REFERENCE.md` | 11KB | Complete reference guide with all components |

**Total: 105KB of ready-to-use templates**

---

## 🚀 Quick Start (30 seconds)

### Option 1: Start Fresh
1. Open `schematiq-blank-starter.html`
2. Replace the example content with yours
3. Save and open in browser
4. Done! 🎉

### Option 2: Use a Template
1. Pick a template (landing, dashboard, or docs)
2. Copy the HTML file
3. Swap the content with yours
4. Customize colors if needed (see below)

### Option 3: Copy Just the Stylesheet
1. Open any HTML file
2. Copy the entire `<style>` block (lines 8-200)
3. Paste into your project's CSS
4. Use the component classes

---

## 🎨 Color Palette

```
Brand Colors:
  #F5A623 — Amber (warm accent)
  #FF1D6C — Hot Pink (primary brand)
  #2979FF — Electric Blue (cool accent)
  #9C27B0 — Violet (secondary brand)

Semantic Colors:
  #00E676 — Success (green)
  #F5A623 — Warning (amber)
  #FF1D6C — Error (hot pink)
  #2979FF — Info (electric blue)

Gradients:
  Sunset: Amber → Hot Pink → Violet
  Ocean: Violet → Blue → Amber
  Aurora: Orange → Pink → Violet → Blue
```

### Using the Colors

```html
<!-- Buttons -->
<button class="btn btn-primary">Gradient button</button>

<!-- Text -->
<h1>Regular <span class="text-gradient">Gradient</span></h1>

<!-- Cards -->
<div class="card card-gradient">Full gradient background</div>

<!-- Badges -->
<span class="badge badge-primary">Hot pink</span>
<span class="badge badge-success">Green</span>
```

---

## 🧱 Core Components

### Buttons (3 variants)
```html
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary"><span>Secondary</span></button>
<button class="btn btn-ghost">Ghost</button>

<!-- Sizes -->
<button class="btn btn-primary btn-sm">Small</button>
<button class="btn btn-primary btn-lg">Large</button>
```

### Cards (3 variants)
```html
<div class="card">Standard card</div>
<div class="card card-glass">Frosted glass</div>
<div class="card card-gradient">Gradient background</div>
```

### Form Inputs
```html
<div class="input-group">
  <label class="label">Label</label>
  <input type="text" class="input" placeholder="Enter text">
</div>
```

### Badges
```html
<span class="badge badge-primary">Primary</span>
<span class="badge badge-success">Success</span>
<span class="badge badge-warning">Warning</span>
<span class="badge badge-error">Error</span>
```

### Alerts
```html
<div class="alert alert-success">Success message</div>
<div class="alert alert-warning">Warning message</div>
<div class="alert alert-error">Error message</div>
<div class="alert alert-info">Info message</div>
```

### Loaders
```html
<!-- Spinner -->
<div class="loader-spinner"></div>

<!-- Dots -->
<div class="loader-dots">
  <span></span><span></span><span></span>
</div>
```

---

## 📐 Layout System

### Grid (Auto-responsive)
```html
<div class="grid grid-2">Two columns</div>
<div class="grid grid-3">Three columns</div>
<div class="grid grid-4">Four columns</div>
```

Breakpoints:
- **1200px:** 4-col → 2-col, 3-col → 2-col
- **768px:** All grids → 1-col

### Flexbox Utilities
```html
<div class="flex items-center justify-between gap-lg">
  <div>Left</div>
  <div>Right</div>
</div>
```

Classes:
- `.flex` `.flex-col`
- `.items-center` `.justify-center` `.justify-between`
- `.gap-sm` `.gap-md` `.gap-lg` `.gap-xl`

### Sections
```html
<section class="section">
  <div class="container">
    <!-- Content auto-centered, max-width 1200px -->
  </div>
</section>
```

---

## 🎭 Animation System

### Built-in Easing Functions

All components use optimized easing curves:

```css
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1)
--ease-out-back: cubic-bezier(0.34, 1.56, 0.64, 1)  /* Slight bounce */
--spring: cubic-bezier(0.175, 0.885, 0.32, 1.275)   /* Spring effect */
```

### Using Animations

```css
.your-element {
  transition: all 0.3s var(--ease-out-expo);
}

.your-element:hover {
  transform: translateY(-4px);
}
```

**All components have hover states built-in!**

---

## 🎯 Common Patterns

### Hero Section
```html
<section class="hero">
  <div class="hero-content">
    <h1 class="hero-title">
      Title <span class="text-gradient">Gradient</span>
    </h1>
    <p class="hero-subtitle">Subtitle text</p>
    <div class="hero-cta">
      <button class="btn btn-primary btn-lg">CTA</button>
    </div>
  </div>
</section>
```

### Feature Grid
```html
<div class="grid grid-3">
  <div class="feature">
    <div class="feature-icon">🎨</div>
    <h3 class="feature-title">Title</h3>
    <p class="feature-desc">Description</p>
  </div>
  <!-- Repeat -->
</div>
```

### Pricing Table
```html
<div class="grid grid-3">
  <div class="pricing-card">
    <h3 class="pricing-title">Plan Name</h3>
    <div class="pricing-price">$49<span>/mo</span></div>
    <ul class="pricing-features">
      <li>Feature 1</li>
      <li>Feature 2</li>
    </ul>
    <button class="btn btn-primary">Subscribe</button>
  </div>
</div>
```

---

## 🔧 Customization

### Change Colors

Override CSS variables in your own stylesheet:

```css
:root {
  /* Change brand colors */
  --hot-pink: #FF0066;
  --electric-blue: #0099FF;

  /* Adjust spacing */
  --space-lg: 32px;

  /* Customize animations */
  --ease-out-expo: cubic-bezier(0.19, 1, 0.22, 1);
}
```

### Dark/Light Mode

Currently dark by default. To add light mode:

```css
body.light-mode {
  --black: #FFFFFF;
  --white: #000000;
  --gray-50: rgba(0, 0, 0, 0.04);
  --gray-100: rgba(0, 0, 0, 0.06);
  /* etc. */
}
```

---

## 📱 Responsive Design

All components are **mobile-first** and automatically responsive:

- Grids collapse to single column on mobile
- Buttons stack vertically when needed
- Text sizes use `clamp()` for fluid scaling
- Padding/spacing adjusts per breakpoint

**Test on mobile first, then desktop!**

---

## 💡 Best Practices

### ✅ DO
- Use `.container` to center content with max-width
- Use `.section` for consistent vertical spacing
- Combine utility classes instead of custom CSS
- Leverage CSS variables for theming
- Let hover states happen automatically

### ❌ DON'T
- Add manual padding/margins when utilities exist
- Override component styles directly
- Use fixed pixel widths for layout
- Write custom animation code
- Fight the system — it's designed to work!

---

## 🛠️ Tech Stack

- **Pure HTML + CSS** (no build tools required)
- **JetBrains Mono** font (monospace, loaded from Google Fonts)
- **CSS Grid + Flexbox** for layout
- **CSS Custom Properties** for theming
- **Cubic Bezier curves** for smooth animations
- **Mobile-first responsive** design

**No JavaScript. No frameworks. No dependencies.**

---

## 📚 File Overview

### 1. schematiq-design-system.html
**Landing page template with full component showcase**
- Hero section with animated gradient orbs
- Feature grid (6 cards)
- Component demos (buttons, cards, forms, badges, alerts, loaders)
- Pricing table (3 plans)
- CTA section
- Footer

**Use for:** Marketing sites, product launches, portfolios

---

### 2. schematiq-dashboard-template.html
**Admin dashboard with sidebar navigation**
- Fixed sidebar with icon nav
- User profile card in sidebar
- Top bar with page title + actions
- 4 stat cards with trend indicators
- Recent orders table (sortable)
- Activity feed (real-time style)
- Chart placeholder section

**Use for:** SaaS dashboards, admin panels, analytics tools

---

### 3. schematiq-docs-template.html
**Documentation site with 3-column layout**
- Fixed top navigation
- Left sidebar (collapsible sections)
- Main content area (centered, max-width)
- Right sidebar (table of contents)
- Breadcrumbs
- Code blocks with syntax highlighting
- Callout boxes (info, warning, success, error)
- Prev/Next navigation

**Use for:** Documentation, wikis, knowledge bases, API docs

---

### 4. schematiq-blank-starter.html
**Minimal template with full system ready**
- Complete stylesheet embedded
- Example of buttons, cards, alerts
- Container + section structure
- Clean slate to build on

**Use for:** Starting any new project from scratch

---

### 5. SCHEMATIQ-QUICK-REFERENCE.md
**Complete component reference guide**
- All components with code examples
- Color system documentation
- Layout utilities
- Animation patterns
- Customization guide
- Best practices

**Use for:** Quick lookup while building

---

## 🎓 Learning Path

### Beginner
1. Open `schematiq-blank-starter.html`
2. Edit the example content
3. Add a few buttons and cards
4. Deploy!

### Intermediate
1. Pick a template (landing/dashboard/docs)
2. Understand the structure
3. Replace content section by section
4. Customize colors via CSS variables

### Advanced
1. Extract just the stylesheet
2. Build your own layouts
3. Create custom components using the design tokens
4. Extend with JavaScript for interactivity

---

## 🚀 Deployment

### Works Everywhere
- ✅ Static hosting (Netlify, Vercel, GitHub Pages)
- ✅ WordPress (paste into custom HTML)
- ✅ React/Vue (import stylesheet)
- ✅ Any CMS or framework

### Steps
1. Copy your chosen HTML file
2. Customize the content
3. Upload to your host
4. Done!

**Single file = easy deployment.**

---

## 🔗 Integration

### With React
```jsx
// Import the stylesheet
import './schematiq.css';

function App() {
  return (
    <button className="btn btn-primary">
      Click me
    </button>
  );
}
```

### With WordPress
1. Go to Appearance → Customize → Additional CSS
2. Paste the entire `<style>` block
3. Use classes in page builder or custom HTML blocks

### With Vanilla HTML
```html
<!DOCTYPE html>
<html>
<head>
  <link rel="stylesheet" href="schematiq.css">
</head>
<body>
  <button class="btn btn-primary">Button</button>
</body>
</html>
```

---

## 📊 Performance

- **Stylesheet size:** ~13KB compressed
- **No JavaScript:** Zero JS overhead
- **Google Fonts:** 1 request for JetBrains Mono
- **Animation:** CSS transforms (GPU-accelerated)
- **Images:** None (pure CSS)

**Fast. Lightweight. Efficient.**

---

## 🎨 Design Decisions

### Why Monospace Font?
- Modern, technical aesthetic
- Great readability at all sizes
- Pairs well with gradients and bold colors
- Unique personality

### Why Dark Mode Only?
- Easier to add light mode later than remove dark mode
- Gradients pop more on dark backgrounds
- Modern, professional look
- Reduce eye strain for developers

### Why No JavaScript?
- Faster load times
- Better accessibility
- Easier to maintain
- CSS animations are smooth and hardware-accelerated

---

## ✨ Next Steps

1. **Start with blank starter** — Get your feet wet
2. **Copy a template** — Use as-is or customize
3. **Read the quick reference** — Learn all components
4. **Customize colors** — Make it yours
5. **Build and ship** — Deploy your project!

---

## 📞 Support

- **Questions?** Check `SCHEMATIQ-QUICK-REFERENCE.md`
- **Need a component?** Browse the templates
- **Want to customize?** Override CSS variables

**Everything you need is in these 5 files.**

---

## 🎉 You're Ready!

You now have a **production-ready design system** that requires **zero configuration**.

Pick a template, swap the content, and ship.

**Happy building!** ⚡🎨

---

*Built with care for developers who want beautiful UIs without the complexity.*

*— Schematiq Design System v1.0*
