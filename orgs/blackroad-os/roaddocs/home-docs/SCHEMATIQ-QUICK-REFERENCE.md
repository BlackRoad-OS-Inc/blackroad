# Schematiq Design System — Quick Reference

## 📦 What You Got

I've created a complete, drop-in design system with **3 production-ready templates**:

### 1. **schematiq-design-system.html** — Main Component Library
- Complete landing page showcasing all components
- Hero section with animated gradient orbs
- Full component demos (buttons, cards, forms, alerts, loaders)
- Pricing table layout
- Feature grids
- Call-to-action sections

### 2. **schematiq-dashboard-template.html** — Admin Dashboard
- Sidebar navigation with sections
- Stats cards with trend indicators
- Data tables with hover effects
- Activity feed
- Responsive layout
- User profile card

### 3. **schematiq-docs-template.html** — Documentation Site
- Three-column layout (sidebar, content, table of contents)
- Breadcrumb navigation
- Code syntax highlighting
- Callout boxes (info, warning, success, error)
- Data tables
- Previous/Next page navigation

---

## 🎨 Color System

```css
/* Primary Colors */
--black: #000000
--white: #FFFFFF

/* Brand Colors */
--amber: #F5A623
--orange: #F26522
--hot-pink: #FF1D6C
--magenta: #E91E63
--electric-blue: #2979FF
--sky-blue: #448AFF
--violet: #9C27B0
--deep-purple: #5E35B1

/* Semantic Colors */
--success: #00E676
--warning: #F5A623 (amber)
--error: #FF1D6C (hot-pink)
--info: #2979FF (electric-blue)

/* Gradients */
--gradient-sunset: linear-gradient(135deg, #F5A623 0%, #FF1D6C 50%, #9C27B0 100%)
--gradient-ocean: linear-gradient(135deg, #9C27B0 0%, #2979FF 50%, #F5A623 100%)
--gradient-aurora: linear-gradient(180deg, #F26522 0%, #FF1D6C 33%, #9C27B0 66%, #2979FF 100%)
```

---

## 🔤 Typography

```html
<!-- Headings -->
<h1>72px — Hero titles</h1>
<h2>56px — Section titles</h2>
<h3>48px — Subsections</h3>
<h4>32px — Card titles</h4>
<h5>24px — Small headings</h5>
<h6>18px — Labels</h6>

<!-- Text sizes -->
--text-xs: 11px
--text-sm: 13px
--text-base: 16px
--text-lg: 18px
--text-xl: 24px
--text-2xl: 32px
--text-3xl: 48px
--text-4xl: 56px
--text-5xl: 72px

<!-- Special text -->
<span class="text-gradient">Gradient text</span>
<span class="text-glow">Glowing text</span>
```

---

## 🧱 Components

### Buttons

```html
<!-- Primary (gradient background) -->
<button class="btn btn-primary">Primary</button>

<!-- Secondary (outline with fill on hover) -->
<button class="btn btn-secondary"><span>Secondary</span></button>

<!-- Ghost (subtle background) -->
<button class="btn btn-ghost">Ghost</button>

<!-- Sizes -->
<button class="btn btn-primary btn-sm">Small</button>
<button class="btn btn-primary">Default</button>
<button class="btn btn-primary btn-lg">Large</button>
```

### Cards

```html
<!-- Standard card -->
<div class="card">
  <div class="card-header">
    <h4 class="card-title">Title</h4>
    <p class="card-subtitle">Subtitle</p>
  </div>
  <div class="card-body">
    <p>Content here</p>
  </div>
  <div class="card-footer">
    <button class="btn btn-primary">Action</button>
  </div>
</div>

<!-- Glass card (frosted glass effect) -->
<div class="card card-glass">...</div>

<!-- Gradient card (full gradient background) -->
<div class="card card-gradient">...</div>
```

### Forms

```html
<div class="input-group">
  <label class="label">Email Address</label>
  <input type="email" class="input" placeholder="you@example.com">
</div>

<div class="input-group">
  <label class="label">Message</label>
  <textarea class="input textarea" placeholder="Your message..."></textarea>
</div>

<div class="input-group">
  <label class="label">Choose Option</label>
  <select class="input select">
    <option>Option 1</option>
    <option>Option 2</option>
  </select>
</div>
```

### Badges

```html
<span class="badge badge-primary">Primary</span>
<span class="badge badge-secondary">Secondary</span>
<span class="badge badge-outline">Outline</span>
<span class="badge badge-success">Success</span>
<span class="badge badge-warning">Warning</span>
<span class="badge badge-error">Error</span>
```

### Alerts

```html
<div class="alert alert-success">
  <strong>Success!</strong> Your changes have been saved.
</div>

<div class="alert alert-warning">
  <strong>Warning!</strong> Please review before proceeding.
</div>

<div class="alert alert-error">
  <strong>Error!</strong> Something went wrong.
</div>

<div class="alert alert-info">
  <strong>Info:</strong> New updates available.
</div>
```

### Loaders

```html
<!-- Spinner -->
<div class="loader-spinner"></div>

<!-- Dots -->
<div class="loader-dots">
  <span></span>
  <span></span>
  <span></span>
</div>
```

### Progress Bar

```html
<div class="progress">
  <div class="progress-bar" style="width: 75%;"></div>
</div>
```

---

## 📐 Layout Utilities

### Grid System

```html
<!-- 2 columns -->
<div class="grid grid-2">
  <div>Column 1</div>
  <div>Column 2</div>
</div>

<!-- 3 columns -->
<div class="grid grid-3">...</div>

<!-- 4 columns -->
<div class="grid grid-4">...</div>

<!-- Custom gap -->
<div class="grid grid-3" style="gap: 48px;">...</div>
```

### Flexbox

```html
<div class="flex items-center justify-between gap-lg">
  <div>Left</div>
  <div>Right</div>
</div>

<!-- Flex direction -->
<div class="flex flex-col gap-md">...</div>

<!-- Alignment -->
<div class="flex items-center">...</div>
<div class="flex justify-center">...</div>
<div class="flex justify-between">...</div>

<!-- Gaps -->
<div class="flex gap-sm">...</div>  <!-- 8px -->
<div class="flex gap-md">...</div>  <!-- 16px -->
<div class="flex gap-lg">...</div>  <!-- 24px -->
<div class="flex gap-xl">...</div>  <!-- 32px -->
```

### Spacing

```html
<!-- Margin -->
<div class="mt-sm">...</div>  <!-- margin-top: 8px -->
<div class="mt-md">...</div>  <!-- margin-top: 16px -->
<div class="mt-lg">...</div>  <!-- margin-top: 24px -->
<div class="mt-xl">...</div>  <!-- margin-top: 32px -->

<div class="mb-sm">...</div>  <!-- margin-bottom -->
<div class="mb-md">...</div>
<div class="mb-lg">...</div>
<div class="mb-xl">...</div>
```

### Sections

```html
<!-- Standard section -->
<section class="section">
  <div class="container">
    <div class="section-header">
      <span class="section-label">Section Label</span>
      <h2 class="section-title">Section Title</h2>
      <p class="section-desc">Description text</p>
    </div>
    <!-- Content -->
  </div>
</section>

<!-- Smaller/larger padding -->
<section class="section-sm">...</section>
<section class="section-lg">...</section>
```

---

## 🎭 Animation Classes

### Easing Functions

```css
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1)
--ease-out-back: cubic-bezier(0.34, 1.56, 0.64, 1)
--ease-in-out-circ: cubic-bezier(0.85, 0, 0.15, 1)
--spring: cubic-bezier(0.175, 0.885, 0.32, 1.275)
```

### Usage

```css
/* Apply to any element */
.my-element {
  transition: all 0.3s var(--ease-out-expo);
}

.my-element:hover {
  transform: translateY(-4px);
}
```

---

## 🏗️ Common Layouts

### Hero Section

```html
<section class="hero">
  <div class="hero-bg">
    <div class="hero-orb hero-orb-1"></div>
    <div class="hero-orb hero-orb-2"></div>
  </div>
  <div class="hero-content">
    <h1 class="hero-title">
      Your <span class="text-gradient">Headline</span>
    </h1>
    <p class="hero-subtitle">Subtitle text</p>
    <div class="hero-cta">
      <button class="btn btn-primary btn-lg">Get Started</button>
      <button class="btn btn-secondary btn-lg"><span>Learn More</span></button>
    </div>
  </div>
</section>
```

### Feature Grid

```html
<div class="grid grid-3">
  <div class="feature">
    <div class="feature-icon">🎨</div>
    <h3 class="feature-title">Feature Title</h3>
    <p class="feature-desc">Feature description</p>
  </div>
  <!-- Repeat for more features -->
</div>
```

### Pricing Table

```html
<div class="grid grid-3">
  <div class="pricing-card">
    <h3 class="pricing-title">Starter</h3>
    <div class="pricing-price">$0<span>/month</span></div>
    <ul class="pricing-features">
      <li>Feature 1</li>
      <li>Feature 2</li>
      <li>Feature 3</li>
    </ul>
    <button class="btn btn-secondary" style="width: 100%;"><span>Get Started</span></button>
  </div>

  <!-- Featured plan -->
  <div class="pricing-card featured">
    <div class="badge badge-primary mb-md">Most Popular</div>
    <h3 class="pricing-title">Pro</h3>
    <div class="pricing-price">$49<span>/month</span></div>
    <ul class="pricing-features">
      <li>Everything in Starter</li>
      <li>Feature 4</li>
      <li>Feature 5</li>
    </ul>
    <button class="btn btn-primary" style="width: 100%;">Get Started</button>
  </div>
</div>
```

---

## 🚀 How to Use

### Option 1: Copy Entire Template
1. Open any of the 3 HTML files
2. Copy the entire `<style>` block
3. Paste into your project's `<head>` or external CSS file
4. Copy the HTML structure you need

### Option 2: Extract Just What You Need
1. Open `schematiq-design-system.html`
2. Copy only the CSS variables and components you want
3. Build your own layout using the component classes

### Option 3: Use as Reference
1. Keep these files as a component library reference
2. Browse to find the component you need
3. Copy the HTML structure and it'll work instantly

---

## 🎯 Best Practices

1. **Always wrap content in `.container`** for consistent max-width
2. **Use `.section` for vertical spacing** instead of manual padding
3. **Combine utility classes** instead of writing custom CSS
4. **Use CSS variables** for consistent theming
5. **Leverage built-in animations** — all components have hover states

---

## 🔧 Customization

Override any CSS variable in your own stylesheet:

```css
:root {
  /* Change brand colors */
  --hot-pink: #your-color;
  --electric-blue: #your-color;

  /* Adjust spacing scale */
  --space-md: 20px;

  /* Customize animations */
  --ease-out-expo: cubic-bezier(your, custom, easing, curve);
}
```

---

## 📱 Responsive Breakpoints

```css
/* Automatically responsive at: */
- 1200px: 4-column grids become 2-column
- 1024px: 3-column grids become 2-column
- 768px: All grids become single column
- 768px: Sidebar navigation hidden on mobile
```

---

## ✨ Next Steps

1. **Pick a template** (landing page, dashboard, or docs)
2. **Copy the HTML** into your project
3. **Swap the content** with your own
4. **Customize colors** via CSS variables if needed
5. **Deploy and ship** 🚀

---

## 💡 Pro Tips

- All components work independently — mix and match freely
- No JavaScript required for animations (pure CSS)
- Works with any backend (static, React, Vue, WordPress, etc.)
- Mobile-first design — always test on small screens first
- Use gradient backgrounds sparingly for maximum impact

---

**You now have a production-ready design system. Just drop it in and start building!** 🎉
