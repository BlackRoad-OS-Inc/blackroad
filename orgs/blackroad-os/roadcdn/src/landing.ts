/**
 * RoadCDN Landing Page Components
 *
 * Pre-built, high-converting landing page components served from edge.
 *
 * Features:
 * - Hero sections
 * - Feature grids
 * - Pricing tables
 * - Testimonials
 * - CTA sections
 * - Analytics tracking
 */

import { Hono } from 'hono';

// BlackRoad Design System
const COLORS = {
  primary: '#F5A623',
  secondary: '#FF1D6C',
  accent: '#2979FF',
  violet: '#9C27B0',
  background: '#000000',
  surface: '#111111',
  text: '#FFFFFF',
  textMuted: '#888888',
  border: '#333333',
};

interface HeroConfig {
  headline: string;
  subheadline: string;
  ctaText: string;
  ctaUrl: string;
  secondaryCtaText?: string;
  secondaryCtaUrl?: string;
  image?: string;
  video?: string;
  badge?: string;
  stats?: Array<{ value: string; label: string }>;
}

interface FeatureConfig {
  title: string;
  description: string;
  icon: string;
  highlight?: boolean;
}

interface PricingPlan {
  name: string;
  description: string;
  price: number;
  interval: 'month' | 'year';
  features: string[];
  ctaText: string;
  ctaUrl: string;
  popular?: boolean;
  badge?: string;
}

interface Testimonial {
  quote: string;
  author: string;
  title: string;
  company: string;
  avatar?: string;
  rating?: number;
}

interface LandingPageConfig {
  hero: HeroConfig;
  features?: FeatureConfig[];
  pricing?: PricingPlan[];
  testimonials?: Testimonial[];
  cta?: {
    headline: string;
    subheadline: string;
    ctaText: string;
    ctaUrl: string;
  };
  analytics?: {
    trackClicks: boolean;
    trackScrollDepth: boolean;
    endpoint?: string;
  };
}

/**
 * Generate CSS styles
 */
function generateStyles(): string {
  return `
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      background: ${COLORS.background};
      color: ${COLORS.text};
      line-height: 1.6;
    }
    .container { max-width: 1200px; margin: 0 auto; padding: 0 24px; }

    /* Hero Section */
    .hero {
      padding: 120px 0 80px;
      text-align: center;
      background: radial-gradient(ellipse at top, rgba(245, 166, 35, 0.1) 0%, transparent 50%);
    }
    .hero-badge {
      display: inline-block;
      background: linear-gradient(135deg, ${COLORS.primary}, ${COLORS.secondary});
      color: white;
      padding: 6px 16px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
      margin-bottom: 24px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .hero h1 {
      font-size: clamp(40px, 8vw, 72px);
      font-weight: 800;
      background: linear-gradient(135deg, ${COLORS.text} 0%, ${COLORS.primary} 100%);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      margin-bottom: 24px;
      line-height: 1.1;
    }
    .hero p {
      font-size: 20px;
      color: ${COLORS.textMuted};
      max-width: 600px;
      margin: 0 auto 40px;
    }
    .hero-cta { display: flex; gap: 16px; justify-content: center; flex-wrap: wrap; }
    .btn {
      display: inline-block;
      padding: 16px 32px;
      border-radius: 8px;
      font-weight: 600;
      text-decoration: none;
      transition: all 0.2s;
      cursor: pointer;
    }
    .btn-primary {
      background: linear-gradient(135deg, ${COLORS.primary}, ${COLORS.secondary});
      color: white;
      box-shadow: 0 4px 24px rgba(245, 166, 35, 0.3);
    }
    .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 8px 32px rgba(245, 166, 35, 0.4); }
    .btn-secondary {
      background: transparent;
      color: ${COLORS.text};
      border: 1px solid ${COLORS.border};
    }
    .btn-secondary:hover { border-color: ${COLORS.primary}; }
    .hero-stats {
      display: flex;
      justify-content: center;
      gap: 48px;
      margin-top: 60px;
      padding-top: 40px;
      border-top: 1px solid ${COLORS.border};
    }
    .hero-stat { text-align: center; }
    .hero-stat-value {
      font-size: 36px;
      font-weight: 700;
      color: ${COLORS.primary};
    }
    .hero-stat-label {
      font-size: 14px;
      color: ${COLORS.textMuted};
    }

    /* Features Section */
    .features {
      padding: 100px 0;
      background: ${COLORS.surface};
    }
    .features h2 {
      text-align: center;
      font-size: 40px;
      margin-bottom: 60px;
    }
    .features-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
      gap: 32px;
    }
    .feature-card {
      background: ${COLORS.background};
      border: 1px solid ${COLORS.border};
      border-radius: 16px;
      padding: 32px;
      transition: all 0.2s;
    }
    .feature-card:hover {
      border-color: ${COLORS.primary};
      transform: translateY(-4px);
    }
    .feature-card.highlight {
      border-color: ${COLORS.primary};
      box-shadow: 0 0 40px rgba(245, 166, 35, 0.1);
    }
    .feature-icon {
      font-size: 32px;
      margin-bottom: 16px;
    }
    .feature-card h3 {
      font-size: 20px;
      margin-bottom: 12px;
      color: ${COLORS.text};
    }
    .feature-card p {
      color: ${COLORS.textMuted};
      font-size: 15px;
    }

    /* Pricing Section */
    .pricing {
      padding: 100px 0;
    }
    .pricing h2 {
      text-align: center;
      font-size: 40px;
      margin-bottom: 60px;
    }
    .pricing-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
      gap: 24px;
      max-width: 1000px;
      margin: 0 auto;
    }
    .pricing-card {
      background: ${COLORS.surface};
      border: 1px solid ${COLORS.border};
      border-radius: 16px;
      padding: 32px;
      position: relative;
    }
    .pricing-card.popular {
      border-color: ${COLORS.primary};
      transform: scale(1.05);
    }
    .pricing-badge {
      position: absolute;
      top: -12px;
      left: 50%;
      transform: translateX(-50%);
      background: linear-gradient(135deg, ${COLORS.primary}, ${COLORS.secondary});
      color: white;
      padding: 4px 16px;
      border-radius: 20px;
      font-size: 12px;
      font-weight: 600;
    }
    .pricing-card h3 {
      font-size: 24px;
      margin-bottom: 8px;
      color: ${COLORS.primary};
    }
    .pricing-card .description {
      color: ${COLORS.textMuted};
      font-size: 14px;
      margin-bottom: 24px;
    }
    .pricing-price {
      font-size: 48px;
      font-weight: 700;
      margin-bottom: 8px;
    }
    .pricing-interval {
      color: ${COLORS.textMuted};
      font-size: 14px;
      margin-bottom: 24px;
    }
    .pricing-features {
      list-style: none;
      margin-bottom: 32px;
    }
    .pricing-features li {
      padding: 8px 0;
      color: ${COLORS.textMuted};
      border-bottom: 1px solid ${COLORS.border};
    }
    .pricing-features li::before {
      content: '✓';
      color: ${COLORS.primary};
      margin-right: 8px;
    }

    /* Testimonials Section */
    .testimonials {
      padding: 100px 0;
      background: ${COLORS.surface};
    }
    .testimonials h2 {
      text-align: center;
      font-size: 40px;
      margin-bottom: 60px;
    }
    .testimonials-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
      gap: 24px;
    }
    .testimonial-card {
      background: ${COLORS.background};
      border: 1px solid ${COLORS.border};
      border-radius: 16px;
      padding: 32px;
    }
    .testimonial-quote {
      font-size: 18px;
      font-style: italic;
      margin-bottom: 24px;
      color: ${COLORS.text};
    }
    .testimonial-author {
      display: flex;
      align-items: center;
      gap: 16px;
    }
    .testimonial-avatar {
      width: 48px;
      height: 48px;
      border-radius: 50%;
      background: linear-gradient(135deg, ${COLORS.primary}, ${COLORS.secondary});
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 600;
      color: white;
    }
    .testimonial-info h4 {
      font-size: 16px;
      margin-bottom: 4px;
    }
    .testimonial-info p {
      font-size: 14px;
      color: ${COLORS.textMuted};
    }
    .testimonial-rating {
      color: ${COLORS.primary};
      font-size: 14px;
      margin-top: 8px;
    }

    /* CTA Section */
    .cta {
      padding: 100px 0;
      text-align: center;
      background: radial-gradient(ellipse at bottom, rgba(255, 29, 108, 0.1) 0%, transparent 50%);
    }
    .cta h2 {
      font-size: 48px;
      margin-bottom: 16px;
    }
    .cta p {
      font-size: 20px;
      color: ${COLORS.textMuted};
      max-width: 600px;
      margin: 0 auto 40px;
    }

    /* Responsive */
    @media (max-width: 768px) {
      .hero { padding: 80px 0 60px; }
      .hero h1 { font-size: 36px; }
      .hero-stats { flex-direction: column; gap: 24px; }
      .pricing-card.popular { transform: none; }
      .features-grid, .pricing-grid, .testimonials-grid {
        grid-template-columns: 1fr;
      }
    }
  `;
}

/**
 * Generate Hero Section HTML
 */
function generateHero(config: HeroConfig): string {
  const badgeHtml = config.badge
    ? `<div class="hero-badge">${config.badge}</div>`
    : '';

  const secondaryCta = config.secondaryCtaText && config.secondaryCtaUrl
    ? `<a href="${config.secondaryCtaUrl}" class="btn btn-secondary" data-track="hero-secondary">${config.secondaryCtaText}</a>`
    : '';

  const statsHtml = config.stats && config.stats.length > 0
    ? `<div class="hero-stats">${config.stats.map(stat => `
        <div class="hero-stat">
          <div class="hero-stat-value">${stat.value}</div>
          <div class="hero-stat-label">${stat.label}</div>
        </div>
      `).join('')}</div>`
    : '';

  return `
    <section class="hero">
      <div class="container">
        ${badgeHtml}
        <h1>${config.headline}</h1>
        <p>${config.subheadline}</p>
        <div class="hero-cta">
          <a href="${config.ctaUrl}" class="btn btn-primary" data-track="hero-primary">${config.ctaText}</a>
          ${secondaryCta}
        </div>
        ${statsHtml}
      </div>
    </section>
  `;
}

/**
 * Generate Features Section HTML
 */
function generateFeatures(features: FeatureConfig[]): string {
  if (!features || features.length === 0) return '';

  const featureCards = features.map(feature => `
    <div class="feature-card ${feature.highlight ? 'highlight' : ''}">
      <div class="feature-icon">${feature.icon}</div>
      <h3>${feature.title}</h3>
      <p>${feature.description}</p>
    </div>
  `).join('');

  return `
    <section class="features">
      <div class="container">
        <h2>Features</h2>
        <div class="features-grid">
          ${featureCards}
        </div>
      </div>
    </section>
  `;
}

/**
 * Generate Pricing Section HTML
 */
function generatePricing(plans: PricingPlan[]): string {
  if (!plans || plans.length === 0) return '';

  const planCards = plans.map(plan => {
    const badge = plan.popular
      ? '<div class="pricing-badge">Most Popular</div>'
      : plan.badge
        ? `<div class="pricing-badge">${plan.badge}</div>`
        : '';

    const features = plan.features.map(f => `<li>${f}</li>`).join('');

    return `
      <div class="pricing-card ${plan.popular ? 'popular' : ''}">
        ${badge}
        <h3>${plan.name}</h3>
        <p class="description">${plan.description}</p>
        <div class="pricing-price">$${plan.price}</div>
        <div class="pricing-interval">per ${plan.interval}</div>
        <ul class="pricing-features">${features}</ul>
        <a href="${plan.ctaUrl}" class="btn btn-primary" style="width: 100%; text-align: center;" data-track="pricing-${plan.name.toLowerCase()}">${plan.ctaText}</a>
      </div>
    `;
  }).join('');

  return `
    <section class="pricing">
      <div class="container">
        <h2>Pricing</h2>
        <div class="pricing-grid">
          ${planCards}
        </div>
      </div>
    </section>
  `;
}

/**
 * Generate Testimonials Section HTML
 */
function generateTestimonials(testimonials: Testimonial[]): string {
  if (!testimonials || testimonials.length === 0) return '';

  const cards = testimonials.map(t => {
    const avatar = t.avatar
      ? `<img src="${t.avatar}" alt="${t.author}" class="testimonial-avatar">`
      : `<div class="testimonial-avatar">${t.author.charAt(0)}</div>`;

    const rating = t.rating
      ? `<div class="testimonial-rating">${'★'.repeat(t.rating)}${'☆'.repeat(5 - t.rating)}</div>`
      : '';

    return `
      <div class="testimonial-card">
        <p class="testimonial-quote">"${t.quote}"</p>
        <div class="testimonial-author">
          ${avatar}
          <div class="testimonial-info">
            <h4>${t.author}</h4>
            <p>${t.title}, ${t.company}</p>
            ${rating}
          </div>
        </div>
      </div>
    `;
  }).join('');

  return `
    <section class="testimonials">
      <div class="container">
        <h2>What Our Customers Say</h2>
        <div class="testimonials-grid">
          ${cards}
        </div>
      </div>
    </section>
  `;
}

/**
 * Generate CTA Section HTML
 */
function generateCTA(cta: LandingPageConfig['cta']): string {
  if (!cta) return '';

  return `
    <section class="cta">
      <div class="container">
        <h2>${cta.headline}</h2>
        <p>${cta.subheadline}</p>
        <a href="${cta.ctaUrl}" class="btn btn-primary" data-track="cta-final">${cta.ctaText}</a>
      </div>
    </section>
  `;
}

/**
 * Generate Analytics Script
 */
function generateAnalytics(config: LandingPageConfig['analytics']): string {
  if (!config) return '';

  return `
    <script>
      (function() {
        const endpoint = '${config.endpoint || '/api/analytics'}';

        ${config.trackClicks ? `
        // Track clicks
        document.addEventListener('click', function(e) {
          const tracked = e.target.closest('[data-track]');
          if (tracked) {
            const event = tracked.dataset.track;
            fetch(endpoint, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                type: 'click',
                event: event,
                url: window.location.href,
                timestamp: Date.now()
              })
            }).catch(() => {});
          }
        });
        ` : ''}

        ${config.trackScrollDepth ? `
        // Track scroll depth
        let maxScroll = 0;
        let scrollReported = [25, 50, 75, 100];
        window.addEventListener('scroll', function() {
          const scrolled = Math.round((window.scrollY / (document.body.scrollHeight - window.innerHeight)) * 100);
          if (scrolled > maxScroll) {
            maxScroll = scrolled;
            scrollReported.forEach(function(threshold) {
              if (scrolled >= threshold && scrollReported.includes(threshold)) {
                scrollReported = scrollReported.filter(t => t !== threshold);
                fetch(endpoint, {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({
                    type: 'scroll',
                    depth: threshold,
                    url: window.location.href,
                    timestamp: Date.now()
                  })
                }).catch(() => {});
              }
            });
          }
        });
        ` : ''}
      })();
    </script>
  `;
}

/**
 * Generate complete landing page
 */
export function generateLandingPage(config: LandingPageConfig): string {
  const styles = generateStyles();
  const hero = generateHero(config.hero);
  const features = generateFeatures(config.features || []);
  const pricing = generatePricing(config.pricing || []);
  const testimonials = generateTestimonials(config.testimonials || []);
  const cta = generateCTA(config.cta);
  const analytics = generateAnalytics(config.analytics);

  return `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${config.hero.headline}</title>
  <meta name="description" content="${config.hero.subheadline}">
  <style>${styles}</style>
</head>
<body>
  ${hero}
  ${features}
  ${pricing}
  ${testimonials}
  ${cta}
  ${analytics}
</body>
</html>
  `;
}

/**
 * Landing Page API Routes
 */
export function createLandingRoutes(): Hono {
  const app = new Hono();

  // Generate landing page from config
  app.post('/landing/generate', async (c) => {
    const config: LandingPageConfig = await c.req.json();
    const html = generateLandingPage(config);
    return c.html(html);
  });

  // Serve landing page from KV config
  app.get('/landing/:slug', async (c) => {
    const slug = c.req.param('slug');
    const kv = c.env?.KV as KVNamespace | undefined;

    if (!kv) {
      return c.json({ error: 'KV not configured' }, 500);
    }

    const config = await kv.get(`landing:${slug}`, 'json') as LandingPageConfig | null;
    if (!config) {
      return c.json({ error: 'Landing page not found' }, 404);
    }

    const html = generateLandingPage(config);
    return c.html(html);
  });

  // Save landing page config
  app.put('/landing/:slug', async (c) => {
    const slug = c.req.param('slug');
    const config: LandingPageConfig = await c.req.json();
    const kv = c.env?.KV as KVNamespace | undefined;

    if (!kv) {
      return c.json({ error: 'KV not configured' }, 500);
    }

    await kv.put(`landing:${slug}`, JSON.stringify(config));
    return c.json({ success: true, slug });
  });

  // Preview endpoint with sample data
  app.get('/landing/preview', (c) => {
    const sampleConfig: LandingPageConfig = {
      hero: {
        headline: 'Build Faster. Ship Smarter.',
        subheadline: 'The complete platform for building modern applications. Get from idea to production in minutes.',
        ctaText: 'Start Free Trial',
        ctaUrl: '/signup',
        secondaryCtaText: 'View Demo',
        secondaryCtaUrl: '/demo',
        badge: 'New: AI Features',
        stats: [
          { value: '10K+', label: 'Developers' },
          { value: '99.9%', label: 'Uptime' },
          { value: '50ms', label: 'Avg Response' },
        ],
      },
      features: [
        { icon: '🚀', title: 'Lightning Fast', description: 'Edge-first architecture delivers sub-50ms response times globally.', highlight: true },
        { icon: '🔒', title: 'Secure by Default', description: 'Enterprise-grade security with zero-trust architecture built in.' },
        { icon: '📊', title: 'Real-time Analytics', description: 'Monitor everything with beautiful dashboards and instant alerts.' },
        { icon: '🔄', title: 'Auto Scaling', description: 'Scale from zero to millions without changing a line of code.' },
        { icon: '🛠️', title: 'Developer First', description: 'APIs, SDKs, and CLI tools designed by developers, for developers.' },
        { icon: '💬', title: '24/7 Support', description: 'Expert support team ready to help whenever you need it.' },
      ],
      pricing: [
        {
          name: 'Starter',
          description: 'Perfect for side projects',
          price: 0,
          interval: 'month',
          features: ['1,000 requests/day', '1 project', 'Community support', 'Basic analytics'],
          ctaText: 'Get Started',
          ctaUrl: '/signup?plan=starter',
        },
        {
          name: 'Pro',
          description: 'For growing teams',
          price: 49,
          interval: 'month',
          features: ['100,000 requests/day', 'Unlimited projects', 'Priority support', 'Advanced analytics', 'Team collaboration', 'Custom domains'],
          ctaText: 'Start Trial',
          ctaUrl: '/signup?plan=pro',
          popular: true,
        },
        {
          name: 'Enterprise',
          description: 'For large organizations',
          price: 199,
          interval: 'month',
          features: ['Unlimited requests', 'Unlimited everything', 'Dedicated support', 'Custom analytics', 'SLA guarantee', 'SSO/SAML', 'Audit logs'],
          ctaText: 'Contact Sales',
          ctaUrl: '/contact',
        },
      ],
      testimonials: [
        { quote: 'This platform cut our development time in half. The DX is incredible.', author: 'Sarah Chen', title: 'CTO', company: 'TechCorp', rating: 5 },
        { quote: 'Finally, infrastructure that just works. We shipped 3x faster after switching.', author: 'Marcus Johnson', title: 'Lead Engineer', company: 'StartupXYZ', rating: 5 },
        { quote: 'The support team is phenomenal. They helped us migrate in one weekend.', author: 'Emily Rodriguez', title: 'VP Engineering', company: 'ScaleUp Inc', rating: 5 },
      ],
      cta: {
        headline: 'Ready to Get Started?',
        subheadline: 'Join thousands of developers building the future. Start your free trial today.',
        ctaText: 'Start Building for Free',
        ctaUrl: '/signup',
      },
      analytics: {
        trackClicks: true,
        trackScrollDepth: true,
        endpoint: '/api/analytics',
      },
    };

    const html = generateLandingPage(sampleConfig);
    return c.html(html);
  });

  return app;
}

export default createLandingRoutes;
