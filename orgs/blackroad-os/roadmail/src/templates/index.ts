/**
 * RoadMail Email Templates
 *
 * Pre-built, customizable email templates with:
 * - Responsive design
 * - Dark mode support
 * - Personalization
 * - Localization ready
 */

interface TemplateVariables {
  [key: string]: string | number | boolean | undefined;
}

interface EmailTemplate {
  id: string;
  name: string;
  subject: string;
  html: string;
  text?: string;
  variables: string[];
  category: 'transactional' | 'marketing' | 'notification';
}

/**
 * Base email styles (BlackRoad design system)
 */
const baseStyles = `
  <style>
    @media (prefers-color-scheme: dark) {
      .email-body { background-color: #000 !important; }
      .email-container { background-color: #111 !important; }
      .text-primary { color: #fff !important; }
      .text-secondary { color: #888 !important; }
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
    .email-body { background-color: #f5f5f5; padding: 40px 20px; }
    .email-container { max-width: 600px; margin: 0 auto; background: #fff; border-radius: 12px; overflow: hidden; }
    .email-header { background: linear-gradient(135deg, #F5A623, #FF1D6C); padding: 30px; text-align: center; }
    .email-header h1 { color: #fff; font-size: 24px; margin: 0; }
    .email-content { padding: 40px 30px; }
    .email-footer { padding: 20px 30px; background: #f9f9f9; text-align: center; font-size: 12px; color: #666; }
    .btn { display: inline-block; padding: 14px 28px; background: linear-gradient(135deg, #F5A623, #FF1D6C); color: #fff; text-decoration: none; border-radius: 8px; font-weight: 600; }
    .btn:hover { opacity: 0.9; }
    .text-primary { color: #111; }
    .text-secondary { color: #666; }
    .divider { height: 1px; background: #eee; margin: 20px 0; }
    .highlight { background: #fff3e0; padding: 16px; border-radius: 8px; border-left: 4px solid #F5A623; }
    .code { font-family: monospace; background: #f0f0f0; padding: 2px 8px; border-radius: 4px; }
  </style>
`;

/**
 * Pre-built email templates
 */
export const templates: Record<string, EmailTemplate> = {

  // Welcome Email
  welcome: {
    id: 'welcome',
    name: 'Welcome Email',
    subject: 'Welcome to {{company_name}}! 🎉',
    category: 'transactional',
    variables: ['name', 'company_name', 'login_url', 'support_email'],
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  ${baseStyles}
</head>
<body>
  <div class="email-body">
    <div class="email-container">
      <div class="email-header">
        <h1>Welcome to {{company_name}}!</h1>
      </div>
      <div class="email-content">
        <p class="text-primary" style="font-size: 18px; margin-bottom: 20px;">
          Hi {{name}},
        </p>
        <p class="text-secondary" style="line-height: 1.6; margin-bottom: 20px;">
          We're thrilled to have you on board! Your account has been created successfully
          and you're ready to start exploring everything {{company_name}} has to offer.
        </p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="{{login_url}}" class="btn">Get Started</a>
        </div>
        <div class="highlight">
          <p class="text-secondary" style="font-size: 14px;">
            <strong>Quick tip:</strong> Complete your profile to unlock all features
            and get personalized recommendations.
          </p>
        </div>
      </div>
      <div class="email-footer">
        <p>Need help? Contact us at {{support_email}}</p>
        <p style="margin-top: 10px;">© {{year}} {{company_name}}. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>`,
    text: `
Welcome to {{company_name}}!

Hi {{name}},

We're thrilled to have you on board! Your account has been created successfully.

Get started: {{login_url}}

Need help? Contact us at {{support_email}}

© {{year}} {{company_name}}
`,
  },

  // Password Reset
  password_reset: {
    id: 'password_reset',
    name: 'Password Reset',
    subject: 'Reset your password',
    category: 'transactional',
    variables: ['name', 'reset_url', 'expiry_hours', 'company_name'],
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  ${baseStyles}
</head>
<body>
  <div class="email-body">
    <div class="email-container">
      <div class="email-header">
        <h1>Password Reset</h1>
      </div>
      <div class="email-content">
        <p class="text-primary" style="font-size: 18px; margin-bottom: 20px;">
          Hi {{name}},
        </p>
        <p class="text-secondary" style="line-height: 1.6; margin-bottom: 20px;">
          We received a request to reset your password. Click the button below to
          create a new password:
        </p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="{{reset_url}}" class="btn">Reset Password</a>
        </div>
        <div class="highlight">
          <p class="text-secondary" style="font-size: 14px;">
            ⚠️ This link expires in <strong>{{expiry_hours}} hours</strong>.
            If you didn't request this reset, please ignore this email.
          </p>
        </div>
      </div>
      <div class="email-footer">
        <p>© {{year}} {{company_name}}. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>`,
    text: `
Password Reset

Hi {{name}},

We received a request to reset your password.

Reset your password: {{reset_url}}

This link expires in {{expiry_hours}} hours. If you didn't request this, ignore this email.

© {{year}} {{company_name}}
`,
  },

  // Order Confirmation
  order_confirmation: {
    id: 'order_confirmation',
    name: 'Order Confirmation',
    subject: 'Order #{{order_id}} confirmed! ✓',
    category: 'transactional',
    variables: ['name', 'order_id', 'items', 'total', 'shipping_address', 'tracking_url', 'company_name'],
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  ${baseStyles}
</head>
<body>
  <div class="email-body">
    <div class="email-container">
      <div class="email-header">
        <h1>Order Confirmed!</h1>
      </div>
      <div class="email-content">
        <p class="text-primary" style="font-size: 18px; margin-bottom: 20px;">
          Hi {{name}},
        </p>
        <p class="text-secondary" style="line-height: 1.6; margin-bottom: 20px;">
          Thank you for your order! We've received your order and it's being processed.
        </p>

        <div style="background: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <p style="font-weight: 600; margin-bottom: 10px;">Order #{{order_id}}</p>
          <div>{{items}}</div>
          <div class="divider"></div>
          <p style="font-size: 18px; font-weight: 600;">Total: {{total}}</p>
        </div>

        <div class="highlight">
          <p style="font-weight: 600; margin-bottom: 8px;">Shipping to:</p>
          <p class="text-secondary">{{shipping_address}}</p>
        </div>

        <div style="text-align: center; margin: 30px 0;">
          <a href="{{tracking_url}}" class="btn">Track Order</a>
        </div>
      </div>
      <div class="email-footer">
        <p>© {{year}} {{company_name}}. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>`,
    text: `
Order Confirmed!

Hi {{name}},

Thank you for your order!

Order #{{order_id}}
{{items}}
Total: {{total}}

Shipping to:
{{shipping_address}}

Track your order: {{tracking_url}}

© {{year}} {{company_name}}
`,
  },

  // Invoice
  invoice: {
    id: 'invoice',
    name: 'Invoice',
    subject: 'Invoice #{{invoice_id}} from {{company_name}}',
    category: 'transactional',
    variables: ['name', 'invoice_id', 'amount', 'due_date', 'items', 'payment_url', 'company_name'],
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  ${baseStyles}
</head>
<body>
  <div class="email-body">
    <div class="email-container">
      <div class="email-header">
        <h1>Invoice #{{invoice_id}}</h1>
      </div>
      <div class="email-content">
        <p class="text-primary" style="font-size: 18px; margin-bottom: 20px;">
          Hi {{name}},
        </p>
        <p class="text-secondary" style="line-height: 1.6; margin-bottom: 20px;">
          Here's your invoice for this billing period.
        </p>

        <div style="background: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <div>{{items}}</div>
          <div class="divider"></div>
          <p style="font-size: 24px; font-weight: 600; color: #F5A623;">{{amount}}</p>
          <p class="text-secondary" style="font-size: 14px;">Due by {{due_date}}</p>
        </div>

        <div style="text-align: center; margin: 30px 0;">
          <a href="{{payment_url}}" class="btn">Pay Now</a>
        </div>
      </div>
      <div class="email-footer">
        <p>© {{year}} {{company_name}}. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>`,
    text: `
Invoice #{{invoice_id}}

Hi {{name}},

Here's your invoice:

{{items}}

Total: {{amount}}
Due by: {{due_date}}

Pay now: {{payment_url}}

© {{year}} {{company_name}}
`,
  },

  // Notification
  notification: {
    id: 'notification',
    name: 'Notification',
    subject: '{{title}}',
    category: 'notification',
    variables: ['name', 'title', 'message', 'action_text', 'action_url', 'company_name'],
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  ${baseStyles}
</head>
<body>
  <div class="email-body">
    <div class="email-container">
      <div class="email-header">
        <h1>{{title}}</h1>
      </div>
      <div class="email-content">
        <p class="text-primary" style="font-size: 18px; margin-bottom: 20px;">
          Hi {{name}},
        </p>
        <p class="text-secondary" style="line-height: 1.6; margin-bottom: 20px;">
          {{message}}
        </p>
        <div style="text-align: center; margin: 30px 0;">
          <a href="{{action_url}}" class="btn">{{action_text}}</a>
        </div>
      </div>
      <div class="email-footer">
        <p>© {{year}} {{company_name}}. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>`,
    text: `
{{title}}

Hi {{name}},

{{message}}

{{action_text}}: {{action_url}}

© {{year}} {{company_name}}
`,
  },

  // Verification Code
  verification_code: {
    id: 'verification_code',
    name: 'Verification Code',
    subject: 'Your verification code: {{code}}',
    category: 'transactional',
    variables: ['name', 'code', 'expiry_minutes', 'company_name'],
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  ${baseStyles}
</head>
<body>
  <div class="email-body">
    <div class="email-container">
      <div class="email-header">
        <h1>Verification Code</h1>
      </div>
      <div class="email-content">
        <p class="text-primary" style="font-size: 18px; margin-bottom: 20px;">
          Hi {{name}},
        </p>
        <p class="text-secondary" style="line-height: 1.6; margin-bottom: 20px;">
          Use the following code to verify your identity:
        </p>
        <div style="text-align: center; margin: 30px 0;">
          <div style="font-size: 36px; font-weight: 700; letter-spacing: 8px; color: #F5A623; background: #f9f9f9; padding: 20px; border-radius: 8px; display: inline-block;">
            {{code}}
          </div>
        </div>
        <div class="highlight">
          <p class="text-secondary" style="font-size: 14px;">
            This code expires in <strong>{{expiry_minutes}} minutes</strong>.
            Don't share this code with anyone.
          </p>
        </div>
      </div>
      <div class="email-footer">
        <p>© {{year}} {{company_name}}. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>`,
    text: `
Verification Code

Hi {{name}},

Your verification code is: {{code}}

This code expires in {{expiry_minutes}} minutes. Don't share it with anyone.

© {{year}} {{company_name}}
`,
  },

  // Subscription Renewal
  subscription_renewal: {
    id: 'subscription_renewal',
    name: 'Subscription Renewal',
    subject: 'Your {{plan_name}} subscription renews soon',
    category: 'transactional',
    variables: ['name', 'plan_name', 'amount', 'renewal_date', 'manage_url', 'company_name'],
    html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  ${baseStyles}
</head>
<body>
  <div class="email-body">
    <div class="email-container">
      <div class="email-header">
        <h1>Subscription Renewal</h1>
      </div>
      <div class="email-content">
        <p class="text-primary" style="font-size: 18px; margin-bottom: 20px;">
          Hi {{name}},
        </p>
        <p class="text-secondary" style="line-height: 1.6; margin-bottom: 20px;">
          Your <strong>{{plan_name}}</strong> subscription will automatically renew on
          <strong>{{renewal_date}}</strong>.
        </p>

        <div style="background: #f9f9f9; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: center;">
          <p class="text-secondary">Amount to be charged</p>
          <p style="font-size: 32px; font-weight: 700; color: #F5A623; margin: 10px 0;">{{amount}}</p>
          <p class="text-secondary" style="font-size: 14px;">on {{renewal_date}}</p>
        </div>

        <div style="text-align: center; margin: 30px 0;">
          <a href="{{manage_url}}" class="btn">Manage Subscription</a>
        </div>
      </div>
      <div class="email-footer">
        <p>© {{year}} {{company_name}}. All rights reserved.</p>
      </div>
    </div>
  </div>
</body>
</html>`,
    text: `
Subscription Renewal

Hi {{name}},

Your {{plan_name}} subscription will renew on {{renewal_date}}.

Amount: {{amount}}

Manage your subscription: {{manage_url}}

© {{year}} {{company_name}}
`,
  },
};

/**
 * Render a template with variables
 */
export function renderTemplate(
  templateId: string,
  variables: TemplateVariables,
): { subject: string; html: string; text?: string } | null {
  const template = templates[templateId];
  if (!template) return null;

  // Add default variables
  const vars: TemplateVariables = {
    year: new Date().getFullYear(),
    ...variables,
  };

  // Render template
  const render = (str: string): string => {
    return str.replace(/\{\{(\w+)\}\}/g, (_, key) => {
      return String(vars[key] ?? '');
    });
  };

  return {
    subject: render(template.subject),
    html: render(template.html),
    text: template.text ? render(template.text) : undefined,
  };
}

/**
 * Get all available templates
 */
export function listTemplates(): Array<{
  id: string;
  name: string;
  category: string;
  variables: string[];
}> {
  return Object.values(templates).map(t => ({
    id: t.id,
    name: t.name,
    category: t.category,
    variables: t.variables,
  }));
}

/**
 * Get template by ID
 */
export function getTemplate(id: string): EmailTemplate | null {
  return templates[id] || null;
}

/**
 * Validate template variables
 */
export function validateVariables(
  templateId: string,
  variables: TemplateVariables,
): { valid: boolean; missing: string[] } {
  const template = templates[templateId];
  if (!template) return { valid: false, missing: [] };

  const missing = template.variables.filter(v => !(v in variables));

  return {
    valid: missing.length === 0,
    missing,
  };
}
