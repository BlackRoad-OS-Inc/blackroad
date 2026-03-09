/**
 * RoadMail - Transactional Email Service
 *
 * Features:
 * - Multiple providers (Resend, SendGrid, Mailgun)
 * - Template rendering
 * - Queue-based delivery
 * - Delivery tracking
 * - Bounce handling
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';

interface Env {
  EMAIL_LOGS: KVNamespace;
  EMAIL_QUEUE: Queue;
  DEFAULT_FROM: string;
  RESEND_API_KEY?: string;
  SENDGRID_API_KEY?: string;
  MAILGUN_API_KEY?: string;
  MAILGUN_DOMAIN?: string;
}

interface EmailMessage {
  id: string;
  to: string | string[];
  from?: string;
  subject: string;
  html?: string;
  text?: string;
  template?: string;
  templateData?: Record<string, any>;
  replyTo?: string;
  cc?: string[];
  bcc?: string[];
  attachments?: Attachment[];
  tags?: string[];
  metadata?: Record<string, any>;
  provider?: 'resend' | 'sendgrid' | 'mailgun';
  scheduledAt?: number;
  createdAt: number;
  status: 'pending' | 'sent' | 'failed' | 'bounced';
}

interface Attachment {
  filename: string;
  content: string; // Base64
  contentType: string;
}

interface Template {
  id: string;
  name: string;
  subject: string;
  html: string;
  text?: string;
  variables: string[];
}

const app = new Hono<{ Bindings: Env }>();

app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'OPTIONS'],
}));

// Health check
app.get('/health', (c) => c.json({ status: 'healthy', service: 'roadmail' }));

// Root
app.get('/', (c) => c.json({
  name: 'RoadMail',
  version: '0.1.0',
  description: 'Transactional Email Service',
  endpoints: {
    send: 'POST /send',
    bulk: 'POST /bulk',
    template: 'POST /send/template',
    status: 'GET /status/:id',
    templates: '/templates',
    webhooks: 'POST /webhooks/:provider',
  },
}));

// Send single email
app.post('/send', async (c) => {
  const body = await c.req.json<Partial<EmailMessage>>();

  if (!body.to || !body.subject) {
    return c.json({ error: 'Missing required fields: to, subject' }, 400);
  }

  const email: EmailMessage = {
    id: crypto.randomUUID(),
    to: body.to,
    from: body.from || c.env.DEFAULT_FROM,
    subject: body.subject,
    html: body.html,
    text: body.text,
    replyTo: body.replyTo,
    cc: body.cc,
    bcc: body.bcc,
    attachments: body.attachments,
    tags: body.tags,
    metadata: body.metadata,
    provider: body.provider,
    createdAt: Date.now(),
    status: 'pending',
  };

  // Log email
  await c.env.EMAIL_LOGS.put(`email:${email.id}`, JSON.stringify(email), {
    expirationTtl: 60 * 60 * 24 * 30, // 30 days
  });

  // Send immediately or queue
  if (body.scheduledAt && body.scheduledAt > Date.now()) {
    email.scheduledAt = body.scheduledAt;
    await c.env.EMAIL_QUEUE.send(email, { delaySeconds: Math.floor((body.scheduledAt - Date.now()) / 1000) });
    return c.json({ id: email.id, status: 'scheduled', scheduledAt: body.scheduledAt });
  }

  try {
    const result = await sendEmail(email, c.env);
    email.status = 'sent';
    await c.env.EMAIL_LOGS.put(`email:${email.id}`, JSON.stringify(email));
    return c.json({ id: email.id, status: 'sent', provider: result.provider });
  } catch (e) {
    email.status = 'failed';
    await c.env.EMAIL_LOGS.put(`email:${email.id}`, JSON.stringify(email));
    return c.json({ id: email.id, status: 'failed', error: (e as Error).message }, 500);
  }
});

// Send with template
app.post('/send/template', async (c) => {
  const body = await c.req.json<{
    to: string | string[];
    template: string;
    data: Record<string, any>;
    from?: string;
    replyTo?: string;
  }>();

  const template = await getTemplate(body.template, c.env);
  if (!template) {
    return c.json({ error: 'Template not found' }, 404);
  }

  const html = renderTemplate(template.html, body.data);
  const text = template.text ? renderTemplate(template.text, body.data) : undefined;
  const subject = renderTemplate(template.subject, body.data);

  const email: EmailMessage = {
    id: crypto.randomUUID(),
    to: body.to,
    from: body.from || c.env.DEFAULT_FROM,
    subject,
    html,
    text,
    replyTo: body.replyTo,
    template: body.template,
    templateData: body.data,
    createdAt: Date.now(),
    status: 'pending',
  };

  await c.env.EMAIL_LOGS.put(`email:${email.id}`, JSON.stringify(email));

  try {
    const result = await sendEmail(email, c.env);
    email.status = 'sent';
    await c.env.EMAIL_LOGS.put(`email:${email.id}`, JSON.stringify(email));
    return c.json({ id: email.id, status: 'sent', provider: result.provider });
  } catch (e) {
    email.status = 'failed';
    await c.env.EMAIL_LOGS.put(`email:${email.id}`, JSON.stringify(email));
    return c.json({ id: email.id, status: 'failed', error: (e as Error).message }, 500);
  }
});

// Bulk send
app.post('/bulk', async (c) => {
  const body = await c.req.json<{
    emails: Partial<EmailMessage>[];
  }>();

  const results = [];

  for (const emailData of body.emails) {
    const email: EmailMessage = {
      id: crypto.randomUUID(),
      to: emailData.to!,
      from: emailData.from || c.env.DEFAULT_FROM,
      subject: emailData.subject!,
      html: emailData.html,
      text: emailData.text,
      tags: emailData.tags,
      metadata: emailData.metadata,
      createdAt: Date.now(),
      status: 'pending',
    };

    await c.env.EMAIL_QUEUE.send(email);
    results.push({ id: email.id, status: 'queued' });
  }

  return c.json({ queued: results.length, emails: results });
});

// Get email status
app.get('/status/:id', async (c) => {
  const id = c.req.param('id');
  const data = await c.env.EMAIL_LOGS.get(`email:${id}`);

  if (!data) {
    return c.json({ error: 'Email not found' }, 404);
  }

  const email = JSON.parse(data) as EmailMessage;

  return c.json({
    id: email.id,
    to: email.to,
    subject: email.subject,
    status: email.status,
    createdAt: email.createdAt,
    template: email.template,
    tags: email.tags,
  });
});

// List emails
app.get('/emails', async (c) => {
  const limit = parseInt(c.req.query('limit') || '50');
  const prefix = 'email:';

  const list = await c.env.EMAIL_LOGS.list({ prefix, limit });

  const emails = await Promise.all(
    list.keys.map(async (key) => {
      const data = await c.env.EMAIL_LOGS.get(key.name);
      if (!data) return null;
      const email = JSON.parse(data) as EmailMessage;
      return {
        id: email.id,
        to: email.to,
        subject: email.subject,
        status: email.status,
        createdAt: email.createdAt,
      };
    })
  );

  return c.json({
    emails: emails.filter(Boolean),
    count: emails.length,
  });
});

// Templates CRUD
app.get('/templates', async (c) => {
  const list = await c.env.EMAIL_LOGS.list({ prefix: 'template:' });

  const templates = await Promise.all(
    list.keys.map(async (key) => {
      const data = await c.env.EMAIL_LOGS.get(key.name);
      if (!data) return null;
      const template = JSON.parse(data) as Template;
      return {
        id: template.id,
        name: template.name,
        variables: template.variables,
      };
    })
  );

  return c.json({ templates: templates.filter(Boolean) });
});

app.post('/templates', async (c) => {
  const body = await c.req.json<Partial<Template>>();

  if (!body.name || !body.subject || !body.html) {
    return c.json({ error: 'Missing required fields: name, subject, html' }, 400);
  }

  const template: Template = {
    id: body.id || crypto.randomUUID(),
    name: body.name,
    subject: body.subject,
    html: body.html,
    text: body.text,
    variables: extractVariables(body.html),
  };

  await c.env.EMAIL_LOGS.put(`template:${template.id}`, JSON.stringify(template));

  return c.json({ id: template.id, name: template.name, variables: template.variables });
});

app.get('/templates/:id', async (c) => {
  const id = c.req.param('id');
  const data = await c.env.EMAIL_LOGS.get(`template:${id}`);

  if (!data) {
    return c.json({ error: 'Template not found' }, 404);
  }

  return c.json(JSON.parse(data));
});

app.delete('/templates/:id', async (c) => {
  const id = c.req.param('id');
  await c.env.EMAIL_LOGS.delete(`template:${id}`);
  return c.json({ deleted: true });
});

// Webhooks for provider callbacks
app.post('/webhooks/:provider', async (c) => {
  const provider = c.req.param('provider');
  const body = await c.req.json();

  // Log webhook
  await c.env.EMAIL_LOGS.put(
    `webhook:${provider}:${Date.now()}`,
    JSON.stringify(body),
    { expirationTtl: 60 * 60 * 24 * 7 } // 7 days
  );

  // Handle based on provider
  switch (provider) {
    case 'resend':
      await handleResendWebhook(body, c.env);
      break;
    case 'sendgrid':
      await handleSendGridWebhook(body, c.env);
      break;
    case 'mailgun':
      await handleMailgunWebhook(body, c.env);
      break;
  }

  return c.json({ received: true });
});

// Stats
app.get('/stats', async (c) => {
  const emails = await c.env.EMAIL_LOGS.list({ prefix: 'email:' });

  let sent = 0, failed = 0, pending = 0;

  for (const key of emails.keys) {
    const data = await c.env.EMAIL_LOGS.get(key.name);
    if (data) {
      const email = JSON.parse(data) as EmailMessage;
      if (email.status === 'sent') sent++;
      else if (email.status === 'failed') failed++;
      else pending++;
    }
  }

  return c.json({
    total: emails.keys.length,
    sent,
    failed,
    pending,
  });
});

// Email sending functions
async function sendEmail(email: EmailMessage, env: Env): Promise<{ provider: string }> {
  // Try providers in order
  if (env.RESEND_API_KEY) {
    return await sendViaResend(email, env.RESEND_API_KEY);
  }

  if (env.SENDGRID_API_KEY) {
    return await sendViaSendGrid(email, env.SENDGRID_API_KEY);
  }

  if (env.MAILGUN_API_KEY && env.MAILGUN_DOMAIN) {
    return await sendViaMailgun(email, env.MAILGUN_API_KEY, env.MAILGUN_DOMAIN);
  }

  throw new Error('No email provider configured');
}

async function sendViaResend(email: EmailMessage, apiKey: string): Promise<{ provider: string }> {
  const response = await fetch('https://api.resend.com/emails', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      from: email.from,
      to: Array.isArray(email.to) ? email.to : [email.to],
      subject: email.subject,
      html: email.html,
      text: email.text,
      reply_to: email.replyTo,
      cc: email.cc,
      bcc: email.bcc,
      tags: email.tags?.map(t => ({ name: t })),
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Resend error: ${error}`);
  }

  return { provider: 'resend' };
}

async function sendViaSendGrid(email: EmailMessage, apiKey: string): Promise<{ provider: string }> {
  const to = Array.isArray(email.to) ? email.to : [email.to];

  const response = await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [{ to: to.map(e => ({ email: e })) }],
      from: { email: email.from },
      subject: email.subject,
      content: [
        email.text ? { type: 'text/plain', value: email.text } : null,
        email.html ? { type: 'text/html', value: email.html } : null,
      ].filter(Boolean),
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`SendGrid error: ${error}`);
  }

  return { provider: 'sendgrid' };
}

async function sendViaMailgun(email: EmailMessage, apiKey: string, domain: string): Promise<{ provider: string }> {
  const to = Array.isArray(email.to) ? email.to.join(',') : email.to;

  const formData = new FormData();
  formData.append('from', email.from!);
  formData.append('to', to);
  formData.append('subject', email.subject);
  if (email.html) formData.append('html', email.html);
  if (email.text) formData.append('text', email.text);

  const response = await fetch(`https://api.mailgun.net/v3/${domain}/messages`, {
    method: 'POST',
    headers: {
      'Authorization': 'Basic ' + btoa(`api:${apiKey}`),
    },
    body: formData,
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Mailgun error: ${error}`);
  }

  return { provider: 'mailgun' };
}

// Template functions
async function getTemplate(id: string, env: Env): Promise<Template | null> {
  const data = await env.EMAIL_LOGS.get(`template:${id}`);
  return data ? JSON.parse(data) : null;
}

function renderTemplate(template: string, data: Record<string, any>): string {
  return template.replace(/\{\{(\w+)\}\}/g, (_, key) => data[key] || '');
}

function extractVariables(html: string): string[] {
  const matches = html.matchAll(/\{\{(\w+)\}\}/g);
  return [...new Set([...matches].map(m => m[1]))];
}

// Webhook handlers
async function handleResendWebhook(body: any, env: Env) {
  const { type, data } = body;

  if (type === 'email.bounced' || type === 'email.complained') {
    // Update email status
    const emailData = await env.EMAIL_LOGS.get(`email:${data.email_id}`);
    if (emailData) {
      const email = JSON.parse(emailData) as EmailMessage;
      email.status = 'bounced';
      await env.EMAIL_LOGS.put(`email:${email.id}`, JSON.stringify(email));
    }
  }
}

async function handleSendGridWebhook(events: any[], env: Env) {
  for (const event of events) {
    if (event.event === 'bounce' || event.event === 'spam_report') {
      // Update based on message ID if available
      console.log('SendGrid event:', event.event);
    }
  }
}

async function handleMailgunWebhook(body: any, env: Env) {
  const eventType = body['event-data']?.event;

  if (eventType === 'failed' || eventType === 'complained') {
    console.log('Mailgun event:', eventType);
  }
}

// Queue consumer
export default {
  fetch: app.fetch,

  async queue(batch: MessageBatch<EmailMessage>, env: Env) {
    for (const message of batch.messages) {
      const email = message.body;

      try {
        await sendEmail(email, env);
        email.status = 'sent';
        await env.EMAIL_LOGS.put(`email:${email.id}`, JSON.stringify(email));
        message.ack();
      } catch (e) {
        email.status = 'failed';
        await env.EMAIL_LOGS.put(`email:${email.id}`, JSON.stringify(email));
        message.retry();
      }
    }
  },
};
