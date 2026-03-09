/**
 * RoadForms - Form Builder Platform
 *
 * Features:
 * - Drag-and-drop form builder
 * - Multiple field types
 * - Conditional logic
 * - Submissions management
 * - Webhooks
 * - Analytics
 */

import { Hono } from 'hono';
import { cors } from 'hono/cors';

interface Env {
  FORMS: KVNamespace;
  DB: D1Database;
}

interface Form {
  id: string;
  name: string;
  description?: string;
  fields: FormField[];
  settings: FormSettings;
  createdAt: number;
  updatedAt: number;
  published: boolean;
  submissions: number;
}

interface FormField {
  id: string;
  type: FieldType;
  label: string;
  placeholder?: string;
  required: boolean;
  validation?: FieldValidation;
  options?: string[]; // For select, radio, checkbox
  conditionalLogic?: ConditionalLogic;
  order: number;
}

type FieldType =
  | 'text'
  | 'email'
  | 'phone'
  | 'number'
  | 'textarea'
  | 'select'
  | 'radio'
  | 'checkbox'
  | 'date'
  | 'time'
  | 'file'
  | 'rating'
  | 'signature'
  | 'hidden';

interface FieldValidation {
  min?: number;
  max?: number;
  minLength?: number;
  maxLength?: number;
  pattern?: string;
  customMessage?: string;
}

interface ConditionalLogic {
  action: 'show' | 'hide' | 'require';
  rules: {
    field: string;
    operator: 'equals' | 'not_equals' | 'contains' | 'greater_than' | 'less_than';
    value: string;
  }[];
  logic: 'and' | 'or';
}

interface FormSettings {
  submitButton: string;
  successMessage: string;
  redirectUrl?: string;
  notifyEmail?: string;
  webhookUrl?: string;
  captcha: boolean;
  onePerUser: boolean;
  closedMessage?: string;
  closeDate?: number;
}

interface Submission {
  id: string;
  formId: string;
  data: Record<string, any>;
  metadata: {
    ip?: string;
    userAgent?: string;
    referrer?: string;
    country?: string;
  };
  createdAt: number;
}

const app = new Hono<{ Bindings: Env }>();

app.use('*', cors({
  origin: '*',
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
}));

// Health check
app.get('/health', (c) => c.json({ status: 'healthy', service: 'roadforms' }));

// Root
app.get('/', (c) => c.json({
  name: 'RoadForms',
  version: '0.1.0',
  description: 'Form Builder Platform',
  endpoints: {
    forms: 'GET /forms',
    create: 'POST /forms',
    submit: 'POST /forms/:id/submit',
    submissions: 'GET /forms/:id/submissions',
    embed: 'GET /forms/:id/embed',
  },
}));

// List forms
app.get('/forms', async (c) => {
  const list = await c.env.FORMS.list({ prefix: 'form:' });

  const forms = await Promise.all(
    list.keys.map(async (key) => {
      const data = await c.env.FORMS.get(key.name);
      if (!data) return null;
      const form = JSON.parse(data) as Form;
      return {
        id: form.id,
        name: form.name,
        description: form.description,
        published: form.published,
        submissions: form.submissions,
        createdAt: form.createdAt,
      };
    })
  );

  return c.json({ forms: forms.filter(Boolean) });
});

// Create form
app.post('/forms', async (c) => {
  const body = await c.req.json<Partial<Form>>();

  if (!body.name) {
    return c.json({ error: 'Missing required field: name' }, 400);
  }

  const form: Form = {
    id: crypto.randomUUID(),
    name: body.name,
    description: body.description,
    fields: body.fields || [],
    settings: body.settings || {
      submitButton: 'Submit',
      successMessage: 'Thank you for your submission!',
      captcha: false,
      onePerUser: false,
    },
    createdAt: Date.now(),
    updatedAt: Date.now(),
    published: false,
    submissions: 0,
  };

  await c.env.FORMS.put(`form:${form.id}`, JSON.stringify(form));

  return c.json({ id: form.id, name: form.name });
});

// Get form
app.get('/forms/:id', async (c) => {
  const id = c.req.param('id');
  const data = await c.env.FORMS.get(`form:${id}`);

  if (!data) {
    return c.json({ error: 'Form not found' }, 404);
  }

  return c.json(JSON.parse(data));
});

// Update form
app.put('/forms/:id', async (c) => {
  const id = c.req.param('id');
  const data = await c.env.FORMS.get(`form:${id}`);

  if (!data) {
    return c.json({ error: 'Form not found' }, 404);
  }

  const existing = JSON.parse(data) as Form;
  const updates = await c.req.json<Partial<Form>>();

  const form: Form = {
    ...existing,
    ...updates,
    id: existing.id, // Prevent ID change
    createdAt: existing.createdAt,
    updatedAt: Date.now(),
  };

  await c.env.FORMS.put(`form:${form.id}`, JSON.stringify(form));

  return c.json({ id: form.id, updated: true });
});

// Delete form
app.delete('/forms/:id', async (c) => {
  const id = c.req.param('id');
  await c.env.FORMS.delete(`form:${id}`);

  // Also delete submissions
  const submissions = await c.env.FORMS.list({ prefix: `submission:${id}:` });
  for (const key of submissions.keys) {
    await c.env.FORMS.delete(key.name);
  }

  return c.json({ deleted: true });
});

// Publish/unpublish form
app.post('/forms/:id/publish', async (c) => {
  const id = c.req.param('id');
  const data = await c.env.FORMS.get(`form:${id}`);

  if (!data) {
    return c.json({ error: 'Form not found' }, 404);
  }

  const form = JSON.parse(data) as Form;
  form.published = true;
  form.updatedAt = Date.now();

  await c.env.FORMS.put(`form:${form.id}`, JSON.stringify(form));

  return c.json({ id: form.id, published: true });
});

app.post('/forms/:id/unpublish', async (c) => {
  const id = c.req.param('id');
  const data = await c.env.FORMS.get(`form:${id}`);

  if (!data) {
    return c.json({ error: 'Form not found' }, 404);
  }

  const form = JSON.parse(data) as Form;
  form.published = false;
  form.updatedAt = Date.now();

  await c.env.FORMS.put(`form:${form.id}`, JSON.stringify(form));

  return c.json({ id: form.id, published: false });
});

// Submit form
app.post('/forms/:id/submit', async (c) => {
  const id = c.req.param('id');
  const formData = await c.env.FORMS.get(`form:${id}`);

  if (!formData) {
    return c.json({ error: 'Form not found' }, 404);
  }

  const form = JSON.parse(formData) as Form;

  if (!form.published) {
    return c.json({ error: 'Form is not accepting submissions' }, 400);
  }

  if (form.settings.closeDate && Date.now() > form.settings.closeDate) {
    return c.json({ error: form.settings.closedMessage || 'Form is closed' }, 400);
  }

  const body = await c.req.json<Record<string, any>>();
  const cf = c.req.raw.cf;

  // Validate required fields
  for (const field of form.fields) {
    if (field.required && !body[field.id]) {
      return c.json({ error: `Field "${field.label}" is required` }, 400);
    }

    // Validate field types
    if (body[field.id]) {
      const error = validateField(field, body[field.id]);
      if (error) {
        return c.json({ error }, 400);
      }
    }
  }

  const submission: Submission = {
    id: crypto.randomUUID(),
    formId: id,
    data: body,
    metadata: {
      ip: c.req.header('CF-Connecting-IP'),
      userAgent: c.req.header('User-Agent'),
      referrer: c.req.header('Referer'),
      country: cf?.country as string,
    },
    createdAt: Date.now(),
  };

  await c.env.FORMS.put(
    `submission:${id}:${submission.id}`,
    JSON.stringify(submission),
    { expirationTtl: 60 * 60 * 24 * 365 } // 1 year
  );

  // Increment submission count
  form.submissions += 1;
  await c.env.FORMS.put(`form:${form.id}`, JSON.stringify(form));

  // Send webhook if configured
  if (form.settings.webhookUrl) {
    try {
      await fetch(form.settings.webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ form: form.name, submission }),
      });
    } catch (e) {
      console.error('Webhook error:', e);
    }
  }

  // Return success
  if (form.settings.redirectUrl) {
    return c.redirect(form.settings.redirectUrl);
  }

  return c.json({
    success: true,
    message: form.settings.successMessage,
    submissionId: submission.id,
  });
});

// Get submissions
app.get('/forms/:id/submissions', async (c) => {
  const id = c.req.param('id');
  const limit = parseInt(c.req.query('limit') || '100');

  const list = await c.env.FORMS.list({ prefix: `submission:${id}:`, limit });

  const submissions = await Promise.all(
    list.keys.map(async (key) => {
      const data = await c.env.FORMS.get(key.name);
      return data ? JSON.parse(data) : null;
    })
  );

  return c.json({
    submissions: submissions.filter(Boolean),
    count: submissions.length,
  });
});

// Get single submission
app.get('/forms/:formId/submissions/:subId', async (c) => {
  const formId = c.req.param('formId');
  const subId = c.req.param('subId');

  const data = await c.env.FORMS.get(`submission:${formId}:${subId}`);

  if (!data) {
    return c.json({ error: 'Submission not found' }, 404);
  }

  return c.json(JSON.parse(data));
});

// Delete submission
app.delete('/forms/:formId/submissions/:subId', async (c) => {
  const formId = c.req.param('formId');
  const subId = c.req.param('subId');

  await c.env.FORMS.delete(`submission:${formId}:${subId}`);

  return c.json({ deleted: true });
});

// Export submissions as CSV
app.get('/forms/:id/export', async (c) => {
  const id = c.req.param('id');

  const formData = await c.env.FORMS.get(`form:${id}`);
  if (!formData) {
    return c.json({ error: 'Form not found' }, 404);
  }

  const form = JSON.parse(formData) as Form;
  const list = await c.env.FORMS.list({ prefix: `submission:${id}:` });

  const submissions: Submission[] = [];
  for (const key of list.keys) {
    const data = await c.env.FORMS.get(key.name);
    if (data) {
      submissions.push(JSON.parse(data));
    }
  }

  // Build CSV
  const headers = ['Submission ID', 'Submitted At', ...form.fields.map(f => f.label)];
  const rows = submissions.map(sub => [
    sub.id,
    new Date(sub.createdAt).toISOString(),
    ...form.fields.map(f => sub.data[f.id] || ''),
  ]);

  const csv = [
    headers.join(','),
    ...rows.map(r => r.map(v => `"${String(v).replace(/"/g, '""')}"`).join(',')),
  ].join('\n');

  return new Response(csv, {
    headers: {
      'Content-Type': 'text/csv',
      'Content-Disposition': `attachment; filename="${form.name}-submissions.csv"`,
    },
  });
});

// Embed form HTML
app.get('/forms/:id/embed', async (c) => {
  const id = c.req.param('id');
  const data = await c.env.FORMS.get(`form:${id}`);

  if (!data) {
    return c.json({ error: 'Form not found' }, 404);
  }

  const form = JSON.parse(data) as Form;

  if (!form.published) {
    return c.text('Form is not published', 404);
  }

  const html = generateFormHTML(form, c.req.url.replace('/embed', '/submit'));

  return c.html(html);
});

// Form analytics
app.get('/forms/:id/analytics', async (c) => {
  const id = c.req.param('id');

  const formData = await c.env.FORMS.get(`form:${id}`);
  if (!formData) {
    return c.json({ error: 'Form not found' }, 404);
  }

  const form = JSON.parse(formData) as Form;
  const list = await c.env.FORMS.list({ prefix: `submission:${id}:` });

  const submissions: Submission[] = [];
  for (const key of list.keys) {
    const data = await c.env.FORMS.get(key.name);
    if (data) {
      submissions.push(JSON.parse(data));
    }
  }

  // Calculate analytics
  const byDay: Record<string, number> = {};
  const byCountry: Record<string, number> = {};

  for (const sub of submissions) {
    const day = new Date(sub.createdAt).toISOString().split('T')[0];
    byDay[day] = (byDay[day] || 0) + 1;

    const country = sub.metadata.country || 'Unknown';
    byCountry[country] = (byCountry[country] || 0) + 1;
  }

  return c.json({
    formId: id,
    formName: form.name,
    totalSubmissions: submissions.length,
    byDay,
    byCountry,
  });
});

// Helper functions
function validateField(field: FormField, value: any): string | null {
  const validation = field.validation;
  if (!validation) return null;

  if (field.type === 'email') {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(value)) {
      return validation.customMessage || `${field.label} must be a valid email`;
    }
  }

  if (field.type === 'phone') {
    const phoneRegex = /^[\d\s\-+()]+$/;
    if (!phoneRegex.test(value)) {
      return validation.customMessage || `${field.label} must be a valid phone number`;
    }
  }

  if (field.type === 'number') {
    const num = parseFloat(value);
    if (isNaN(num)) {
      return `${field.label} must be a number`;
    }
    if (validation.min !== undefined && num < validation.min) {
      return validation.customMessage || `${field.label} must be at least ${validation.min}`;
    }
    if (validation.max !== undefined && num > validation.max) {
      return validation.customMessage || `${field.label} must be at most ${validation.max}`;
    }
  }

  if (typeof value === 'string') {
    if (validation.minLength && value.length < validation.minLength) {
      return validation.customMessage || `${field.label} must be at least ${validation.minLength} characters`;
    }
    if (validation.maxLength && value.length > validation.maxLength) {
      return validation.customMessage || `${field.label} must be at most ${validation.maxLength} characters`;
    }
    if (validation.pattern && !new RegExp(validation.pattern).test(value)) {
      return validation.customMessage || `${field.label} format is invalid`;
    }
  }

  return null;
}

function generateFormHTML(form: Form, submitUrl: string): string {
  const fieldsHTML = form.fields
    .sort((a, b) => a.order - b.order)
    .map(field => {
      let input = '';

      switch (field.type) {
        case 'text':
        case 'email':
        case 'phone':
        case 'number':
        case 'date':
        case 'time':
          input = `<input type="${field.type}" name="${field.id}" placeholder="${field.placeholder || ''}" ${field.required ? 'required' : ''} class="form-input">`;
          break;
        case 'textarea':
          input = `<textarea name="${field.id}" placeholder="${field.placeholder || ''}" ${field.required ? 'required' : ''} class="form-input"></textarea>`;
          break;
        case 'select':
          input = `<select name="${field.id}" ${field.required ? 'required' : ''} class="form-input">
            <option value="">Select...</option>
            ${field.options?.map(o => `<option value="${o}">${o}</option>`).join('')}
          </select>`;
          break;
        case 'radio':
          input = `<div class="form-options">
            ${field.options?.map(o => `<label><input type="radio" name="${field.id}" value="${o}" ${field.required ? 'required' : ''}> ${o}</label>`).join('')}
          </div>`;
          break;
        case 'checkbox':
          input = `<div class="form-options">
            ${field.options?.map(o => `<label><input type="checkbox" name="${field.id}" value="${o}"> ${o}</label>`).join('')}
          </div>`;
          break;
        case 'hidden':
          input = `<input type="hidden" name="${field.id}" value="${field.placeholder || ''}">`;
          break;
        default:
          input = `<input type="text" name="${field.id}" class="form-input">`;
      }

      if (field.type === 'hidden') {
        return input;
      }

      return `
        <div class="form-field">
          <label class="form-label">${field.label}${field.required ? ' *' : ''}</label>
          ${input}
        </div>
      `;
    })
    .join('');

  return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${form.name}</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #000; color: #fff; padding: 20px; }
    .form-container { max-width: 600px; margin: 0 auto; }
    h1 { color: #F5A623; margin-bottom: 10px; }
    .description { color: #888; margin-bottom: 30px; }
    .form-field { margin-bottom: 20px; }
    .form-label { display: block; margin-bottom: 8px; font-weight: 500; }
    .form-input { width: 100%; padding: 12px; background: #111; border: 1px solid #333; border-radius: 8px; color: #fff; font-size: 16px; }
    .form-input:focus { outline: none; border-color: #F5A623; }
    .form-options { display: flex; flex-direction: column; gap: 10px; }
    .form-options label { display: flex; align-items: center; gap: 8px; cursor: pointer; }
    button { background: linear-gradient(135deg, #F5A623, #FF1D6C); border: none; color: #fff; padding: 14px 28px; border-radius: 8px; font-size: 16px; font-weight: 600; cursor: pointer; width: 100%; transition: transform 0.2s; }
    button:hover { transform: translateY(-2px); }
  </style>
</head>
<body>
  <div class="form-container">
    <h1>${form.name}</h1>
    ${form.description ? `<p class="description">${form.description}</p>` : ''}
    <form action="${submitUrl}" method="POST">
      ${fieldsHTML}
      <button type="submit">${form.settings.submitButton}</button>
    </form>
  </div>
</body>
</html>`;
}

export default app;
