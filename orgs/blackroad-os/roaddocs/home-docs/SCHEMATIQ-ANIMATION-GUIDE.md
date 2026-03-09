# Schematiq Animation System — Complete Guide

## 🎭 Overview

The Schematiq Animation Library is a **comprehensive collection of motion patterns** built entirely with CSS. No JavaScript dependencies (except for the scroll indicator). All animations use optimized easing curves and GPU-accelerated transforms.

**File:** `schematiq-animation-library.html` (Original showcase template)

---

## 📊 Animation Inventory

### **Total Animations: 50+**

| Category | Count | Examples |
|----------|-------|----------|
| Easing Functions | 4 | Linear, Ease Out Expo, Ease Out Back, Spring |
| Shape Morphing | 3 | Blob, Square→Circle, Star |
| Loaders | 10 | Spinner, Pulse, Dots, Bars, Ring, Orbit, DNA, Cube, Ripple, Rainbow |
| Text Effects | 4 | Typewriter, Glitch, Wave, Gradient Flow |
| Hover Effects | 8 | Scale, Lift, Glow, Shine, Fill, Rotate, Border, Flip |
| Button Effects | 4 | Pulse, Slide, Ripple, Gradient Shift |
| Icon Animations | 5 | Bounce Arrow, Spin Gear, Pulse Heart, Wiggle Bell, Float Cloud |
| Background Effects | 3 | Orb Float, Orb Pulse, Particles |
| Logo Animations | 4 | Spin, Ring Pulse, Half Rotate, Pupil Look |
| Sequential | 3 | Code Reveal, Timeline Appear, Hero Slide Up |

---

## 🎨 Core Easing Functions

### 1. **Linear**
```css
animation-timing-function: linear;
```
- **Use for:** Continuous motion (spinners, marquees, clocks)
- **Feel:** Mechanical, constant speed

### 2. **Ease Out Expo**
```css
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
```
- **Use for:** Slide-ins, fades, most UI transitions
- **Feel:** Snappy ending, natural deceleration
- **Example:** Hero text slide-up, card hover

### 3. **Ease Out Back**
```css
--ease-out-back: cubic-bezier(0.34, 1.56, 0.64, 1);
```
- **Use for:** Playful interactions, buttons, modals
- **Feel:** Slight bounce at the end
- **Example:** Scale hover effect, button press

### 4. **Spring**
```css
--spring: cubic-bezier(0.175, 0.885, 0.32, 1.275);
```
- **Use for:** Elastic effects, notifications, badges
- **Feel:** Spring-like bounce
- **Example:** Badge appearance, alert popup

---

## 🔄 Shape Morphing Animations

### **Blob Morph** (8s infinite)
```css
@keyframes morph-blob {
  0%, 100% { border-radius: 60% 40% 30% 70% / 60% 30% 70% 40%; }
  25% { border-radius: 30% 60% 70% 40% / 50% 60% 30% 60%; }
  50% { border-radius: 50% 60% 30% 60% / 30% 60% 70% 40%; }
  75% { border-radius: 60% 40% 60% 30% / 70% 30% 50% 60%; }
}
```
**Use for:** Organic backgrounds, hero sections, loading states

### **Square → Circle** (6s infinite)
```css
@keyframes morph-square {
  0%, 100% { border-radius: 0; transform: rotate(0deg); }
  25% { border-radius: 50% 0 50% 0; transform: rotate(90deg); }
  50% { border-radius: 50%; transform: rotate(180deg); }
  75% { border-radius: 0 50% 0 50%; transform: rotate(270deg); }
}
```
**Use for:** Loading indicators, transitions between states

### **Star Morph** (10s infinite)
- Morphs star shape while rotating and scaling
- **Use for:** Special effects, featured badges, celebrations

---

## ⏳ Loader Components

### **1. Spinner** (Classic)
```html
<div class="loader-spinner"></div>
```
```css
.loader-spinner {
  width: 48px;
  height: 48px;
  border: 3px solid rgba(255, 255, 255, 0.1);
  border-top-color: var(--hot-pink);
  border-radius: 50%;
  animation: spin 1s linear infinite;
}
```

### **2. Pulse** (Breathing effect)
```html
<div class="loader-pulse"></div>
```
- Scales from 0.8 to 1.2
- Fades opacity 0.5 to 1
- 1.5s cycle

### **3. Dots** (Staggered bounce)
```html
<div class="loader-dots">
  <span></span>
  <span></span>
  <span></span>
</div>
```
- Each dot bounces with 0.2s delay
- 1.4s total cycle

### **4. Bars** (Audio wave)
```html
<div class="loader-bars">
  <span></span> <!-- x5 -->
</div>
```
- Each bar waves from 16px to 48px height
- 0.1s stagger between bars

### **5. Ring** (Dual rotation)
```html
<div class="loader-ring"></div>
```
- Two half-rings rotating opposite directions
- Uses `::before` and `::after` pseudo-elements

### **6. Orbit** (Planet around sun)
```html
<div class="loader-orbit">
  <div class="orbit-center"></div>
  <div class="orbit-ring">
    <div class="orbit-dot"></div>
  </div>
</div>
```

### **7. DNA** (Alternating wave)
- 5 dots alternating colors (pink/blue)
- Wave motion up/down with stagger

### **8. Cube** (3D flip)
- Perspective 3D transform
- Rotates on X and Y axes
- Gradient background

### **9. Ripple** (Expanding circles)
```html
<div class="loader-ripple">
  <span></span>
  <span></span>
</div>
```
- Two circles expand from 0.5 to 1.5 scale
- 0.5s stagger, fade out

### **10. Rainbow** (Multi-color spinner)
- Same as spinner but 4 colors on each border side

---

## 📝 Text Animations

### **1. Typewriter** (4s infinite)
```html
<div class="typewriter">Hello, Schematiq.</div>
```
```css
@keyframes typing {
  0%, 100% { width: 0; }
  50%, 90% { width: 100%; }
}
@keyframes blink {
  50% { border-color: transparent; }
}
```
- Width animates with `steps(20)` for chunky effect
- Blinking cursor with `border-right`

### **2. Glitch** (2s infinite)
```html
<div class="glitch" data-text="GLITCH">GLITCH</div>
```
- Uses `::before` and `::after` for offset copies
- Pink copy clips top 35%
- Blue copy clips bottom 35%
- Random transform jitter

### **3. Wave** (1.5s infinite)
```html
<div class="wave-text">
  <span>S</span>
  <span>C</span>
  <span>H</span>
  <!-- etc -->
</div>
```
- Each letter bounces with 0.1s delay
- Gradient text fill
- Vertical translateY animation

### **4. Gradient Flow** (3s infinite)
```css
.gradient-text {
  background: linear-gradient(90deg, ...);
  background-size: 200% auto;
  animation: gradient-flow 3s linear infinite;
}
```
- Shifts background-position for flowing gradient effect

---

## 🖱️ Hover Effects

### **1. Scale** (Scale up 8%)
```css
.hover-scale:hover {
  transform: scale(1.08);
  transition: transform 0.4s var(--ease-out-back);
}
```

### **2. Lift** (Raise + shadow)
```css
.hover-lift:hover {
  transform: translateY(-12px);
  box-shadow: 0 20px 40px rgba(255, 29, 108, 0.2);
}
```

### **3. Glow** (Border + shadow)
```css
.hover-glow:hover {
  box-shadow: 0 0 0 2px var(--hot-pink),
              0 0 40px rgba(255, 29, 108, 0.4);
}
```

### **4. Shine** (Light sweep)
```css
.hover-shine::before {
  content: '';
  position: absolute;
  top: 0;
  left: -100%;
  width: 100%;
  height: 100%;
  background: linear-gradient(90deg, transparent, rgba(255,255,255,0.1), transparent);
  transition: left 0.6s ease;
}
.hover-shine:hover::before {
  left: 100%;
}
```

### **5. Fill** (Gradient overlay)
- Gradient overlay fades from opacity 0 to 1

### **6. Rotate** (5° rotation + scale)
```css
.hover-rotate:hover {
  transform: rotate(5deg) scale(1.05);
}
```

### **7. Border** (Border width grows)
- Border grows from 2px to 4px
- Uses gradient border technique

### **8. Flip** (3D flip)
```css
.hover-flip:hover {
  transform: rotateY(180deg);
  transform-style: preserve-3d;
}
```

---

## 🔘 Button Animations

### **1. Pulse** (Shadow pulse)
```css
@keyframes btn-pulse {
  0%, 100% { box-shadow: 0 0 0 0 rgba(255, 29, 108, 0.4); }
  50% { box-shadow: 0 0 0 15px rgba(255, 29, 108, 0); }
}
```
- Shadow expands and fades
- 2s infinite loop

### **2. Slide** (Fill from left)
```css
.btn-slide::before {
  width: 0;
  transition: width 0.4s var(--ease-out-expo);
}
.btn-slide:hover::before {
  width: 100%;
}
```
- Pseudo-element slides across
- Text color changes on hover

### **3. Ripple** (Click ripple)
```css
.btn-ripple::after {
  width: 0;
  height: 0;
  background: rgba(255, 255, 255, 0.3);
  border-radius: 50%;
  transition: width 0.6s, height 0.6s;
}
.btn-ripple:hover::after {
  width: 300px;
  height: 300px;
}
```

### **4. Gradient Shift** (Animated gradient)
```css
@keyframes gradient-shift {
  0%, 100% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
}
```
- Background position shifts
- 200% background-size for smooth loop

---

## 🎨 Icon Animations

### **1. Bounce Arrow**
```css
@keyframes bounce-arrow {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-15px); }
}
```

### **2. Spin Gear**
```css
@keyframes spin-gear {
  to { transform: rotate(360deg); }
}
```
- 4s linear infinite rotation

### **3. Pulse Heart**
```css
@keyframes pulse-heart {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.2); }
}
```

### **4. Wiggle Bell**
```css
@keyframes wiggle-bell {
  0%, 100% { transform: rotate(-10deg); }
  50% { transform: rotate(10deg); }
}
```
- 0.5s infinite (fast wiggle)

### **5. Float Cloud**
```css
@keyframes float-cloud {
  0%, 100% { transform: translateY(0) translateX(0); }
  50% { transform: translateY(-10px) translateX(5px); }
}
```

---

## 🌟 Background Effects

### **Hero Orbs** (Floating gradients)
```css
.hero-orb-1 {
  width: 600px;
  height: 600px;
  background: var(--hot-pink);
  filter: blur(80px);
  opacity: 0.4;
  animation: orb-float-1 15s ease-in-out infinite;
}
```

**Orb Float Pattern:**
```css
@keyframes orb-float-1 {
  0%, 100% { transform: translate(0, 0) scale(1); }
  33% { transform: translate(-100px, 100px) scale(1.1); }
  66% { transform: translate(50px, -50px) scale(0.9); }
}
```

### **Particles** (10 floating dots)
```css
.particle-1 {
  width: 8px;
  height: 8px;
  background: var(--hot-pink);
  animation: float-particle 15s infinite;
  left: 10%;
  top: 20%;
}
```

**Particle Path:**
```css
@keyframes float-particle {
  0%, 100% { transform: translate(0, 0) rotate(0deg); opacity: 0.6; }
  25% { transform: translate(50px, -80px) rotate(90deg); opacity: 1; }
  50% { transform: translate(-30px, -150px) rotate(180deg); opacity: 0.4; }
  75% { transform: translate(80px, -50px) rotate(270deg); opacity: 0.8; }
}
```

---

## 🎬 Sequential Animations

### **Hero Text Slide-Up**
```css
.hero h1 .line {
  opacity: 0;
  transform: translateY(100%);
  animation: slide-up 1s var(--ease-out-expo) forwards;
}
.line:nth-child(1) { animation-delay: 0.2s; }
.line:nth-child(2) { animation-delay: 0.35s; }
.line:nth-child(3) { animation-delay: 0.5s; }
```

### **Code Reveal** (Sequential lines)
```css
.code-line {
  opacity: 0;
  animation: code-appear 0.5s ease forwards;
}
.code-line:nth-child(1) { animation-delay: 0.2s; }
.code-line:nth-child(2) { animation-delay: 0.4s; }
/* ... +0.2s each */
```

### **Timeline Appear**
```css
.timeline-item {
  opacity: 0;
  animation: timeline-appear 0.6s var(--ease-out-expo) forwards;
}
.timeline-item:nth-child(1) { animation-delay: 0.2s; }
.timeline-item:nth-child(2) { animation-delay: 0.4s; }
/* ... +0.2s each */
```

---

## 🏗️ Logo Animations

### **1. Logo Spin** (Full rotation)
```css
@keyframes logo-spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}
```
- 20s linear infinite
- Used on nav logo mark

### **2. Ring Pulse** (Stroke width)
```css
@keyframes ring-pulse {
  0%, 100% { stroke-width: 8; }
  50% { stroke-width: 12; }
}
```
- 3s ease-in-out infinite
- SVG stroke animation

### **3. Half Rotate** (Top/bottom split)
```css
@keyframes half-rotate-top {
  0%, 100% { transform: rotate(0deg); }
  50% { transform: rotate(10deg); }
}
@keyframes half-rotate-bottom {
  0%, 100% { transform: rotate(0deg); }
  50% { transform: rotate(-10deg); }
}
```
- 8s ease-in-out infinite
- Creates "breathing" effect

### **4. Pupil Look** (Eye movement)
```css
@keyframes pupil-look {
  0%, 100% { transform: translate(0, 0); }
  25% { transform: translate(5px, -3px); }
  50% { transform: translate(-5px, 2px); }
  75% { transform: translate(3px, 4px); }
}
```
- 5s ease-in-out infinite
- Simulates looking around

---

## 📱 Responsive Behavior

### **Breakpoint: 1200px**
```css
@media (max-width: 1200px) {
  .easing-grid,
  .hover-grid,
  .buttons-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  .loaders-grid {
    grid-template-columns: repeat(3, 1fr);
  }
}
```

### **Breakpoint: 768px**
```css
@media (max-width: 768px) {
  .easing-grid,
  .hover-grid,
  .buttons-grid,
  .loaders-grid {
    grid-template-columns: 1fr;
  }
}
```

**Note:** All animations continue to work on mobile — only grid layouts change.

---

## 🎯 Best Practices

### **Performance Optimization**

1. **Use Transform & Opacity Only**
   - GPU-accelerated properties
   - Avoid animating `width`, `height`, `top`, `left`

2. **Add `will-change` for Heavy Animations**
   ```css
   .heavy-animation {
     will-change: transform;
   }
   ```

3. **Limit Concurrent Animations**
   - Maximum 3-5 simultaneous animations on screen
   - Pause animations when out of viewport

### **Duration Guidelines**

| Animation Type | Ideal Duration |
|----------------|----------------|
| Micro-interactions | 200-400ms |
| UI transitions | 300-600ms |
| Morphing shapes | 6-10s |
| Background effects | 10-20s |
| Loaders | 1-2s |
| Attention-grabbers | 2-4s |

### **Easing Selection**

| Use Case | Easing Function |
|----------|----------------|
| Slide-ins | Ease Out Expo |
| Button clicks | Ease Out Back |
| Playful interactions | Spring |
| Loaders | Linear |
| Fades | Ease In Out |

---

## 💡 Usage Examples

### **Hero Section with Orbs**
```html
<section class="hero">
  <div class="hero-bg">
    <div class="hero-orb hero-orb-1"></div>
    <div class="hero-orb hero-orb-2"></div>
    <div class="hero-orb hero-orb-3"></div>
  </div>
  <div class="hero-content">
    <h1>Your <span>Title</span></h1>
  </div>
</section>
```

### **Loading State**
```html
<!-- Pick your favorite loader -->
<div class="loader-spinner"></div>
<!-- or -->
<div class="loader-dots">
  <span></span><span></span><span></span>
</div>
```

### **Interactive Card**
```html
<div class="hover-card hover-lift">
  <span class="hover-card-label">Hover Me</span>
</div>
```

### **Animated CTA**
```html
<button class="btn-demo btn-pulse">Click Me</button>
```

---

## 🔧 Customization

### **Change Animation Speed**
```css
/* Make it slower */
.morph-blob {
  animation-duration: 12s; /* was 8s */
}

/* Make it faster */
.loader-spinner {
  animation-duration: 0.5s; /* was 1s */
}
```

### **Change Colors**
```css
.loader-spinner {
  border-top-color: #YOUR_COLOR;
}

.morph-blob {
  background: linear-gradient(135deg, #COLOR1, #COLOR2);
}
```

### **Adjust Intensity**
```css
/* Less dramatic hover */
.hover-scale:hover {
  transform: scale(1.03); /* was 1.08 */
}

/* More dramatic orb pulse */
.hero-orb-3 {
  animation-duration: 6s; /* was 10s */
}
```

---

## 📊 Animation Complexity Chart

| Animation | CSS Lines | JavaScript | GPU Intensive | Mobile Safe |
|-----------|-----------|------------|---------------|-------------|
| Spinner | 10 | No | Yes | ✅ |
| Blob Morph | 12 | No | Medium | ✅ |
| Glitch | 25 | No | Medium | ⚠️ Use sparingly |
| Particles | 15 | No | High | ⚠️ Reduce count |
| Hero Orbs | 20 | No | High | ⚠️ Simplify on mobile |
| Typewriter | 15 | No | No | ✅ |
| Wave Text | 18 | No | Medium | ✅ |
| 3D Flip | 8 | No | High | ✅ |

**Legend:**
- ✅ = No issues
- ⚠️ = Test carefully, may need adjustments

---

## 🚀 Quick Reference

### **Copy-Paste Ready Animations**

**Simple Fade In:**
```css
@keyframes fade-in {
  from { opacity: 0; }
  to { opacity: 1; }
}
.element { animation: fade-in 0.6s ease; }
```

**Slide Up:**
```css
@keyframes slide-up {
  from { transform: translateY(20px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}
```

**Scale Pulse:**
```css
@keyframes scale-pulse {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.05); }
}
```

**Rotate 360:**
```css
@keyframes spin {
  to { transform: rotate(360deg); }
}
```

---

## 🎓 Learning Resources

### **Animation Principles**
1. **Easing** — Speed curve of animation
2. **Duration** — How long it takes
3. **Delay** — When it starts
4. **Iteration** — How many times (infinite, once, 3x, etc.)

### **Key Properties**
- `animation-name` — Which @keyframes to use
- `animation-duration` — How long (1s, 500ms, etc.)
- `animation-timing-function` — Easing curve
- `animation-delay` — Wait before starting
- `animation-iteration-count` — infinite, 1, 2, etc.
- `animation-direction` — normal, reverse, alternate
- `animation-fill-mode` — forwards, backwards, both

### **Shorthand Syntax**
```css
animation: name duration easing delay iteration direction fill-mode;

/* Example */
animation: slide-up 0.6s ease-out 0.2s 1 normal forwards;
```

---

## 📦 File Structure

```
schematiq-animation-library.html
├── CSS Variables (colors, easing functions)
├── Navigation (with logo spin)
├── Hero Section (orbs, logo, text slide-up)
├── Easing Showcase (4 cards)
├── Morphing Shapes (3 types)
├── Loaders (10 variants)
├── Text Animations (4 effects)
├── Hover Effects (8 cards)
├── Button Animations (4 buttons)
├── Icon Animations (5 icons)
├── Particles Section (10 particles)
├── Code Reveal
├── Timeline
└── Footer
```

**Total Size:** ~35KB (HTML + CSS only)

---

## 🎉 Summary

The Schematiq Animation Library provides:

✅ **50+ ready-to-use animations**
✅ **Pure CSS** (no JavaScript dependencies)
✅ **GPU-accelerated** (transform & opacity)
✅ **Fully responsive** (mobile-tested)
✅ **Copy-paste ready** (isolated components)
✅ **Customizable** (CSS variables + classes)
✅ **Production-tested** (optimized for performance)

**Use this file as:**
- Animation reference library
- Copy-paste source for your projects
- Learning resource for CSS animations
- Visual playground for testing motion

---

**Happy animating!** 🎭✨
