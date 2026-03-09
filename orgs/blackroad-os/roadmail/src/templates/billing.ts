/**
 * RoadMail Billing Email Templates
 *
 * Professional email templates for billing notifications.
 *
 * Features:
 * - Welcome emails
 * - Payment receipts
 * - Payment failure notifications
 * - Trial ending reminders
 * - Subscription changes
 * - Dunning emails
 */

import { Hono } from 'hono';

interface EmailTemplate {
  subject: string;
  html: string;
  text: string;
}

interface TemplateData {
  [key: string]: string | number | boolean | undefined;
}

// BlackRoad design system colors
const COLORS = {
  primary: '#F5A623',
  secondary: '#FF1D6C',
  accent: '#2979FF',
  background: '#000000',
  surface: '#111111',
  text: '#FFFFFF',
  textMuted: '#888888',
  border: '#333333',
  success: '#00C853',
  warning: '#FFB300',
  error: '#FF5252',
};

/**
 * Base email layout
 */
function baseLayout(content: string, companyName: string = 'BlackRoad'): string {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${companyName}</title>
  <style>
    body { margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background-color: ${COLORS.background}; color: ${COLORS.text}; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .card { background: ${COLORS.surface}; border: 1px solid ${COLORS.border}; border-radius: 16px; padding: 32px; margin-bottom: 24px; }
    .logo { text-align: center; margin-bottom: 32px; }
    .logo h1 { color: ${COLORS.primary}; font-size: 28px; margin: 0; }
    .button { display: inline-block; background: linear-gradient(135deg, ${COLORS.primary}, ${COLORS.secondary}); color: white; text-decoration: none; padding: 16px 32px; border-radius: 8px; font-weight: 600; }
    .footer { text-align: center; color: ${COLORS.textMuted}; font-size: 12px; margin-top: 32px; }
    h2 { color: ${COLORS.text}; margin: 0 0 16px; }
    p { color: ${COLORS.textMuted}; line-height: 1.6; margin: 0 0 16px; }
    .highlight { color: ${COLORS.primary}; font-weight: 600; }
    .amount { font-size: 36px; color: ${COLORS.text}; font-weight: 700; }
    .divider { border-top: 1px solid ${COLORS.border}; margin: 24px 0; }
    .alert { background: rgba(255, 82, 82, 0.1); border: 1px solid ${COLORS.error}; border-radius: 8px; padding: 16px; margin-bottom: 16px; }
    .success { background: rgba(0, 200, 83, 0.1); border: 1px solid ${COLORS.success}; }
    .warning { background: rgba(255, 179, 0, 0.1); border: 1px solid ${COLORS.warning}; }
  </style>
</head>
<body>
  <div class="container">
    <div class="logo">
      <h1>🖤 ${companyName}</h1>
    </div>
    ${content}
    <div class="footer">
      <p>&copy; ${new Date().getFullYear()} ${companyName}. All rights reserved.</p>
      <p>Questions? Contact us at support@blackroad.io</p>
    </div>
  </div>
</body>
</html>
`;
}

/**
 * Welcome Email
 */
export function welcomeEmail(data: {
  name: string;
  planName?: string;
  dashboardUrl: string;
  companyName?: string;
}): EmailTemplate {
  const company = data.companyName || 'BlackRoad';

  const html = baseLayout(`
    <div class="card">
      <h2>Welcome to ${company}! 🎉</h2>
      <p>Hey ${data.name},</p>
      <p>Thanks for joining us! ${data.planName ? `You're now on the <span class="highlight">${data.planName}</span> plan.` : ''}</p>
      <p>We're excited to have you on board. Here's what you can do next:</p>
      <ul style="color: ${COLORS.textMuted}; line-height: 2;">
        <li>Set up your account in the dashboard</li>
        <li>Explore our features</li>
        <li>Check out our documentation</li>
      </ul>
      <div style="text-align: center; margin-top: 24px;">
        <a href="${data.dashboardUrl}" class="button">Go to Dashboard</a>
      </div>
    </div>
  `, company);

  const text = `
Welcome to ${company}!

Hey ${data.name},

Thanks for joining us! ${data.planName ? `You're now on the ${data.planName} plan.` : ''}

Visit your dashboard: ${data.dashboardUrl}
`;

  return {
    subject: `Welcome to ${company}! 🎉`,
    html,
    text,
  };
}

/**
 * Payment Receipt
 */
export function receiptEmail(data: {
  name: string;
  amount: number;
  currency: string;
  invoiceNumber: string;
  invoiceDate: string;
  invoiceUrl: string;
  items: Array<{ description: string; amount: number }>;
  companyName?: string;
}): EmailTemplate {
  const company = data.companyName || 'BlackRoad';
  const currencySymbol = data.currency === 'usd' ? '$' : data.currency.toUpperCase() + ' ';
  const formattedAmount = `${currencySymbol}${(data.amount / 100).toFixed(2)}`;

  const itemsHtml = data.items.map(item => `
    <tr>
      <td style="padding: 8px 0; color: ${COLORS.textMuted};">${item.description}</td>
      <td style="padding: 8px 0; text-align: right; color: ${COLORS.text};">${currencySymbol}${(item.amount / 100).toFixed(2)}</td>
    </tr>
  `).join('');

  const html = baseLayout(`
    <div class="card success">
      <div style="text-align: center;">
        <div style="font-size: 48px; margin-bottom: 16px;">✓</div>
        <h2>Payment Received</h2>
        <div class="amount">${formattedAmount}</div>
        <p style="margin-top: 8px;">Invoice #${data.invoiceNumber}</p>
      </div>
    </div>
    <div class="card">
      <h2>Receipt Details</h2>
      <p><strong>Date:</strong> ${data.invoiceDate}</p>
      <div class="divider"></div>
      <table style="width: 100%; border-collapse: collapse;">
        ${itemsHtml}
        <tr>
          <td style="padding: 16px 0 8px; color: ${COLORS.text}; font-weight: 600; border-top: 1px solid ${COLORS.border};">Total</td>
          <td style="padding: 16px 0 8px; text-align: right; color: ${COLORS.primary}; font-weight: 700; font-size: 20px; border-top: 1px solid ${COLORS.border};">${formattedAmount}</td>
        </tr>
      </table>
      <div style="text-align: center; margin-top: 24px;">
        <a href="${data.invoiceUrl}" class="button">View Invoice</a>
      </div>
    </div>
  `, company);

  const text = `
Payment Received

Amount: ${formattedAmount}
Invoice: #${data.invoiceNumber}
Date: ${data.invoiceDate}

View your invoice: ${data.invoiceUrl}
`;

  return {
    subject: `Receipt for your ${formattedAmount} payment`,
    html,
    text,
  };
}

/**
 * Payment Failed
 */
export function paymentFailedEmail(data: {
  name: string;
  amount: number;
  currency: string;
  lastFour?: string;
  updatePaymentUrl: string;
  retryDate?: string;
  companyName?: string;
}): EmailTemplate {
  const company = data.companyName || 'BlackRoad';
  const currencySymbol = data.currency === 'usd' ? '$' : data.currency.toUpperCase() + ' ';
  const formattedAmount = `${currencySymbol}${(data.amount / 100).toFixed(2)}`;

  const html = baseLayout(`
    <div class="card alert">
      <div style="text-align: center;">
        <div style="font-size: 48px; margin-bottom: 16px;">⚠️</div>
        <h2>Payment Failed</h2>
        <p>We couldn't process your payment of <span class="highlight">${formattedAmount}</span>${data.lastFour ? ` using card ending in ${data.lastFour}` : ''}.</p>
      </div>
    </div>
    <div class="card">
      <h2>What's Next?</h2>
      <p>To avoid any interruption to your service, please update your payment method.</p>
      ${data.retryDate ? `<p>We'll automatically retry the payment on <strong>${data.retryDate}</strong>.</p>` : ''}
      <div style="text-align: center; margin-top: 24px;">
        <a href="${data.updatePaymentUrl}" class="button">Update Payment Method</a>
      </div>
    </div>
  `, company);

  const text = `
Payment Failed

We couldn't process your payment of ${formattedAmount}.

Please update your payment method: ${data.updatePaymentUrl}
`;

  return {
    subject: `Action required: Payment of ${formattedAmount} failed`,
    html,
    text,
  };
}

/**
 * Trial Ending
 */
export function trialEndingEmail(data: {
  name: string;
  trialEndDate: string;
  planName: string;
  planAmount: number;
  currency: string;
  upgradeUrl: string;
  companyName?: string;
}): EmailTemplate {
  const company = data.companyName || 'BlackRoad';
  const currencySymbol = data.currency === 'usd' ? '$' : data.currency.toUpperCase() + ' ';
  const formattedAmount = `${currencySymbol}${(data.planAmount / 100).toFixed(2)}`;

  const html = baseLayout(`
    <div class="card warning">
      <div style="text-align: center;">
        <div style="font-size: 48px; margin-bottom: 16px;">⏰</div>
        <h2>Your Trial Ends Soon</h2>
        <p>Your free trial ends on <span class="highlight">${data.trialEndDate}</span>.</p>
      </div>
    </div>
    <div class="card">
      <h2>Keep the Momentum Going</h2>
      <p>Hey ${data.name},</p>
      <p>We hope you've been enjoying ${company}! Your trial is coming to an end, but you don't have to stop here.</p>
      <p>After your trial ends, you'll be automatically enrolled in the <strong>${data.planName}</strong> plan at <span class="highlight">${formattedAmount}/month</span>.</p>
      <p>If you'd like to change your plan or cancel, you can do so anytime before the trial ends.</p>
      <div style="text-align: center; margin-top: 24px;">
        <a href="${data.upgradeUrl}" class="button">Manage Subscription</a>
      </div>
    </div>
  `, company);

  const text = `
Your Trial Ends on ${data.trialEndDate}

Hey ${data.name},

Your free trial is ending soon. After it ends, you'll be enrolled in the ${data.planName} plan at ${formattedAmount}/month.

Manage your subscription: ${data.upgradeUrl}
`;

  return {
    subject: `Your trial ends in 3 days`,
    html,
    text,
  };
}

/**
 * Subscription Cancelled
 */
export function subscriptionCancelledEmail(data: {
  name: string;
  endDate: string;
  feedbackUrl?: string;
  reactivateUrl: string;
  companyName?: string;
}): EmailTemplate {
  const company = data.companyName || 'BlackRoad';

  const html = baseLayout(`
    <div class="card">
      <h2>We're Sad to See You Go 😢</h2>
      <p>Hey ${data.name},</p>
      <p>Your subscription has been cancelled. You'll have access until <span class="highlight">${data.endDate}</span>.</p>
      <p>If you change your mind, you can reactivate your subscription anytime.</p>
      <div style="text-align: center; margin-top: 24px;">
        <a href="${data.reactivateUrl}" class="button">Reactivate Subscription</a>
      </div>
      ${data.feedbackUrl ? `
      <div class="divider"></div>
      <p style="text-align: center;">We'd love to know why you're leaving. <a href="${data.feedbackUrl}" style="color: ${COLORS.primary};">Share feedback</a></p>
      ` : ''}
    </div>
  `, company);

  const text = `
Subscription Cancelled

Hey ${data.name},

Your subscription has been cancelled. You'll have access until ${data.endDate}.

Reactivate anytime: ${data.reactivateUrl}
`;

  return {
    subject: `Your ${company} subscription has been cancelled`,
    html,
    text,
  };
}

/**
 * Upcoming Invoice
 */
export function upcomingInvoiceEmail(data: {
  name: string;
  amount: number;
  currency: string;
  dueDate: string;
  items: Array<{ description: string; amount: number }>;
  manageUrl: string;
  companyName?: string;
}): EmailTemplate {
  const company = data.companyName || 'BlackRoad';
  const currencySymbol = data.currency === 'usd' ? '$' : data.currency.toUpperCase() + ' ';
  const formattedAmount = `${currencySymbol}${(data.amount / 100).toFixed(2)}`;

  const itemsHtml = data.items.map(item => `
    <tr>
      <td style="padding: 8px 0; color: ${COLORS.textMuted};">${item.description}</td>
      <td style="padding: 8px 0; text-align: right; color: ${COLORS.text};">${currencySymbol}${(item.amount / 100).toFixed(2)}</td>
    </tr>
  `).join('');

  const html = baseLayout(`
    <div class="card">
      <h2>Upcoming Invoice</h2>
      <p>Hey ${data.name},</p>
      <p>You have an upcoming payment of <span class="highlight">${formattedAmount}</span> due on <strong>${data.dueDate}</strong>.</p>
      <div class="divider"></div>
      <table style="width: 100%; border-collapse: collapse;">
        ${itemsHtml}
        <tr>
          <td style="padding: 16px 0 8px; color: ${COLORS.text}; font-weight: 600; border-top: 1px solid ${COLORS.border};">Total</td>
          <td style="padding: 16px 0 8px; text-align: right; color: ${COLORS.primary}; font-weight: 700; font-size: 20px; border-top: 1px solid ${COLORS.border};">${formattedAmount}</td>
        </tr>
      </table>
      <div style="text-align: center; margin-top: 24px;">
        <a href="${data.manageUrl}" class="button">Manage Billing</a>
      </div>
    </div>
  `, company);

  const text = `
Upcoming Invoice

Hey ${data.name},

Your payment of ${formattedAmount} is due on ${data.dueDate}.

Manage billing: ${data.manageUrl}
`;

  return {
    subject: `Upcoming payment of ${formattedAmount} on ${data.dueDate}`,
    html,
    text,
  };
}

/**
 * Dunning Email (Final Warning)
 */
export function dunningFinalEmail(data: {
  name: string;
  amount: number;
  currency: string;
  suspensionDate: string;
  updatePaymentUrl: string;
  companyName?: string;
}): EmailTemplate {
  const company = data.companyName || 'BlackRoad';
  const currencySymbol = data.currency === 'usd' ? '$' : data.currency.toUpperCase() + ' ';
  const formattedAmount = `${currencySymbol}${(data.amount / 100).toFixed(2)}`;

  const html = baseLayout(`
    <div class="card alert">
      <div style="text-align: center;">
        <div style="font-size: 48px; margin-bottom: 16px;">🚨</div>
        <h2>Final Notice: Account at Risk</h2>
        <p>We've been unable to collect your payment of <span class="highlight">${formattedAmount}</span>.</p>
      </div>
    </div>
    <div class="card">
      <h2>Action Required Immediately</h2>
      <p>Hey ${data.name},</p>
      <p>Your account will be <strong>suspended on ${data.suspensionDate}</strong> unless we receive payment.</p>
      <p>To keep your account active, please update your payment method now.</p>
      <div style="text-align: center; margin-top: 24px;">
        <a href="${data.updatePaymentUrl}" class="button">Update Payment Now</a>
      </div>
      <div class="divider"></div>
      <p style="text-align: center; font-size: 12px;">If you've already updated your payment method, please disregard this notice. Your next payment will be attempted automatically.</p>
    </div>
  `, company);

  const text = `
FINAL NOTICE: Account at Risk

Hey ${data.name},

We've been unable to collect your payment of ${formattedAmount}.

Your account will be suspended on ${data.suspensionDate} unless payment is received.

Update your payment method: ${data.updatePaymentUrl}
`;

  return {
    subject: `🚨 Final Notice: Your account will be suspended on ${data.suspensionDate}`,
    html,
    text,
  };
}

/**
 * Plan Upgrade Confirmation
 */
export function planUpgradeEmail(data: {
  name: string;
  oldPlan: string;
  newPlan: string;
  newAmount: number;
  currency: string;
  effectiveDate: string;
  dashboardUrl: string;
  companyName?: string;
}): EmailTemplate {
  const company = data.companyName || 'BlackRoad';
  const currencySymbol = data.currency === 'usd' ? '$' : data.currency.toUpperCase() + ' ';
  const formattedAmount = `${currencySymbol}${(data.newAmount / 100).toFixed(2)}`;

  const html = baseLayout(`
    <div class="card success">
      <div style="text-align: center;">
        <div style="font-size: 48px; margin-bottom: 16px;">🚀</div>
        <h2>You've Upgraded!</h2>
        <p>Welcome to the <span class="highlight">${data.newPlan}</span> plan.</p>
      </div>
    </div>
    <div class="card">
      <h2>Your Plan Details</h2>
      <p>Hey ${data.name},</p>
      <p>You've successfully upgraded from <strong>${data.oldPlan}</strong> to <strong>${data.newPlan}</strong>.</p>
      <table style="width: 100%;">
        <tr>
          <td style="padding: 8px 0; color: ${COLORS.textMuted};">New Plan</td>
          <td style="padding: 8px 0; text-align: right; color: ${COLORS.primary}; font-weight: 600;">${data.newPlan}</td>
        </tr>
        <tr>
          <td style="padding: 8px 0; color: ${COLORS.textMuted};">Monthly Price</td>
          <td style="padding: 8px 0; text-align: right; color: ${COLORS.text};">${formattedAmount}/mo</td>
        </tr>
        <tr>
          <td style="padding: 8px 0; color: ${COLORS.textMuted};">Effective Date</td>
          <td style="padding: 8px 0; text-align: right; color: ${COLORS.text};">${data.effectiveDate}</td>
        </tr>
      </table>
      <div style="text-align: center; margin-top: 24px;">
        <a href="${data.dashboardUrl}" class="button">Explore New Features</a>
      </div>
    </div>
  `, company);

  const text = `
You've Upgraded to ${data.newPlan}!

Hey ${data.name},

You've successfully upgraded from ${data.oldPlan} to ${data.newPlan} at ${formattedAmount}/month.

Explore new features: ${data.dashboardUrl}
`;

  return {
    subject: `🚀 Welcome to ${data.newPlan}!`,
    html,
    text,
  };
}

/**
 * Template registry and rendering
 */
export class BillingEmailRenderer {
  private companyName: string;

  constructor(companyName: string = 'BlackRoad') {
    this.companyName = companyName;
  }

  render(template: string, data: TemplateData): EmailTemplate | null {
    const templateData = { ...data, companyName: this.companyName };

    switch (template) {
      case 'welcome':
        return welcomeEmail(templateData as any);
      case 'receipt':
        return receiptEmail(templateData as any);
      case 'payment_failed':
        return paymentFailedEmail(templateData as any);
      case 'trial_ending':
        return trialEndingEmail(templateData as any);
      case 'subscription_cancelled':
        return subscriptionCancelledEmail(templateData as any);
      case 'upcoming_invoice':
        return upcomingInvoiceEmail(templateData as any);
      case 'dunning_final':
        return dunningFinalEmail(templateData as any);
      case 'plan_upgrade':
        return planUpgradeEmail(templateData as any);
      default:
        return null;
    }
  }

  listTemplates(): string[] {
    return [
      'welcome',
      'receipt',
      'payment_failed',
      'trial_ending',
      'subscription_cancelled',
      'upcoming_invoice',
      'dunning_final',
      'plan_upgrade',
    ];
  }
}

/**
 * Create Hono routes for email template preview
 */
export function createTemplateRoutes(): Hono {
  const app = new Hono();
  const renderer = new BillingEmailRenderer();

  app.get('/templates', (c) => {
    return c.json({ templates: renderer.listTemplates() });
  });

  app.get('/templates/:template/preview', (c) => {
    const template = c.req.param('template');

    // Sample data for previews
    const sampleData: Record<string, TemplateData> = {
      welcome: {
        name: 'Alex',
        planName: 'Pro',
        dashboardUrl: 'https://dashboard.blackroad.io',
      },
      receipt: {
        name: 'Alex',
        amount: 4900,
        currency: 'usd',
        invoiceNumber: 'INV-2024-001',
        invoiceDate: 'January 11, 2026',
        invoiceUrl: 'https://dashboard.blackroad.io/invoices/1',
        items: [
          { description: 'Pro Plan - Monthly', amount: 4900 },
        ],
      },
      payment_failed: {
        name: 'Alex',
        amount: 4900,
        currency: 'usd',
        lastFour: '4242',
        updatePaymentUrl: 'https://dashboard.blackroad.io/billing',
        retryDate: 'January 14, 2026',
      },
      trial_ending: {
        name: 'Alex',
        trialEndDate: 'January 14, 2026',
        planName: 'Pro',
        planAmount: 4900,
        currency: 'usd',
        upgradeUrl: 'https://dashboard.blackroad.io/billing',
      },
      subscription_cancelled: {
        name: 'Alex',
        endDate: 'February 11, 2026',
        feedbackUrl: 'https://blackroad.io/feedback',
        reactivateUrl: 'https://dashboard.blackroad.io/reactivate',
      },
      upcoming_invoice: {
        name: 'Alex',
        amount: 4900,
        currency: 'usd',
        dueDate: 'February 11, 2026',
        items: [
          { description: 'Pro Plan - Monthly', amount: 4900 },
        ],
        manageUrl: 'https://dashboard.blackroad.io/billing',
      },
      dunning_final: {
        name: 'Alex',
        amount: 4900,
        currency: 'usd',
        suspensionDate: 'January 18, 2026',
        updatePaymentUrl: 'https://dashboard.blackroad.io/billing',
      },
      plan_upgrade: {
        name: 'Alex',
        oldPlan: 'Starter',
        newPlan: 'Pro',
        newAmount: 4900,
        currency: 'usd',
        effectiveDate: 'January 11, 2026',
        dashboardUrl: 'https://dashboard.blackroad.io',
      },
    };

    const data = sampleData[template];
    if (!data) {
      return c.json({ error: 'Template not found' }, 404);
    }

    const rendered = renderer.render(template, data);
    if (!rendered) {
      return c.json({ error: 'Failed to render template' }, 500);
    }

    // Return HTML for preview
    return c.html(rendered.html);
  });

  app.post('/templates/:template/render', async (c) => {
    const template = c.req.param('template');
    const data = await c.req.json();

    const rendered = renderer.render(template, data);
    if (!rendered) {
      return c.json({ error: 'Template not found or failed to render' }, 404);
    }

    return c.json(rendered);
  });

  return app;
}
