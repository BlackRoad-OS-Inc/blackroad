Okay okay okay, beast mode continues. 🧱
You’ve got:
* Plan → ✔️
* Issues → ✔️
* DNS + Railway + Cece configs → ✔️
* Infra README → ✔️
* gov-api skeleton → ✔️
* host-based routing for edu/homework → ✔️
Next brick: make the Education / RoadWork vertical actually do something:
1. DB migrations for:
   * users (minimal)
   * assignments
   * submissions
   * ledger_events
2. Next.js API routes for:
   * Teacher: create/list assignments
   * Student: list assignments, submit work
   * Teacher: review submission
3. Hook those API routes into Cece governance (policy + ledger) using the ceceClient shim.
I’ll keep it generic Postgres + Next.js API routes so you can drop it into blackroad-os-web as-is.
________________


1️⃣ Postgres Schema / Migrations (SQL)
You can apply these via:
* Railway’s migration feature,
* A simple psql run,
* Or integrated into Prisma/Drizzle later.
1.1 users table (if you don’t have one yet)
-- 0001_create_users.sql
CREATE TABLE IF NOT EXISTS users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         TEXT NOT NULL UNIQUE,
  name          TEXT,
  role          TEXT NOT NULL DEFAULT 'student', -- 'teacher' | 'student' | 'creator' | 'admin'
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);


If you already have a users table, just align the columns or skip this and adapt the foreign keys below.
________________


1.2 assignments table
-- 0002_create_assignments.sql
CREATE TABLE IF NOT EXISTS assignments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  description   TEXT,
  due_date      TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- Optional pivot table if you want explicit assignment → student mapping
CREATE TABLE IF NOT EXISTS assignment_students (
  assignment_id UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  student_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (assignment_id, student_id)
);


________________


1.3 submissions table
-- 0003_create_submissions.sql
CREATE TABLE IF NOT EXISTS submissions (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assignment_id  UUID NOT NULL REFERENCES assignments(id) ON DELETE CASCADE,
  student_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content        TEXT NOT NULL,
  status         TEXT NOT NULL DEFAULT 'submitted', -- 'submitted' | 'reviewed'
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (assignment_id, student_id) -- one active submission per student/assignment for v0
);


CREATE INDEX IF NOT EXISTS idx_submissions_assignment ON submissions(assignment_id);
CREATE INDEX IF NOT EXISTS idx_submissions_student ON submissions(student_id);


________________


1.4 ledger_events table (for Cece)
Align this with the Python LedgerEventRecord from the gov-api skeleton:
-- 0004_create_ledger_events.sql
CREATE TABLE IF NOT EXISTS ledger_events (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  intent_id   TEXT,
  actor       JSONB NOT NULL,
  action      TEXT NOT NULL,
  resource    TEXT NOT NULL,
  decision    TEXT,
  policy_id   TEXT,
  timestamp   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  metadata    JSONB NOT NULL DEFAULT '{}'::jsonb
);


CREATE INDEX IF NOT EXISTS idx_ledger_events_action ON ledger_events(action);
CREATE INDEX IF NOT EXISTS idx_ledger_events_policy ON ledger_events(policy_id);
CREATE INDEX IF NOT EXISTS idx_ledger_events_timestamp ON ledger_events(timestamp DESC);


You can run these in order, or combine them into a single migration file.
________________


2️⃣ Next.js DB Helper (blackroad-os-web)
Use pg for now, keep it simple.
Install in blackroad-os-web:
npm install pg


Create lib/db.ts:
// lib/db.ts
import { Pool } from 'pg';


const connectionString = process.env.DATABASE_URL;


if (!connectionString) {
  throw new Error('DATABASE_URL is not set');
}


export const pool = new Pool({
  connectionString,
  // Optional: ssl: { rejectUnauthorized: false } if needed by provider
});


// Simple helper
export async function query<T = any>(text: string, params?: any[]): Promise<T[]> {
  const client = await pool.connect();
  try {
    const res = await client.query(text, params);
    return res.rows as T[];
  } finally {
    client.release();
  }
}


________________


3️⃣ Cece Client (reminder) in blackroad-os-web
If not already created, drop this in lib/ceceClient.ts:
// lib/ceceClient.ts
const GOV_API_URL =
  process.env.NEXT_PUBLIC_GOV_API_URL || 'https://gov.api.blackroad.io';


export type CeceSubject = {
  role: string;
};


export type PolicyEvaluateRequest = {
  subject: CeceSubject;
  action: string;
  resource: string;
  context?: Record<string, unknown>;
};


export type PolicyEvaluateResponse = {
  decision: 'allow' | 'deny';
  policy_id?: string | null;
  reason?: string | null;
};


export async function evaluatePolicy(
  req: PolicyEvaluateRequest
): Promise<PolicyEvaluateResponse> {
  const res = await fetch(`${GOV_API_URL}/policy/evaluate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(req),
  });


  if (!res.ok) {
    throw new Error(`Cece policy error: ${res.status}`);
  }


  return res.json();
}


export async function sendLedgerEvent(event: Record<string, unknown>) {
  try {
    await fetch(`${GOV_API_URL}/ledger/event`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(event),
    });
  } catch (err) {
    // Best-effort for v0
    console.error('Failed to send ledger event', err);
  }
}


And in Railway:
* NEXT_PUBLIC_GOV_API_URL=https://gov.api.blackroad.io
________________


4️⃣ Next.js API Routes for Education
Assume pages/api structure (Next ≤13 pages router). Adapt to app/api if you’re on app router.
4.1 Helper to get current user (stub)
In reality you’ll read from session/auth; for now a fake helper to wire the flow:
// lib/auth.ts
export type CurrentUser = {
  id: string;
  email: string;
  role: 'teacher' | 'student' | 'creator' | 'admin';
};


export async function getCurrentUser(req: any): Promise<CurrentUser> {
  // TODO: Replace with real auth (JWT/cookies)
  // For now, read from headers for testing / dev
  const role = (req.headers['x-dev-role'] as string) || 'student';
  const id = (req.headers['x-dev-user-id'] as string) || '00000000-0000-0000-0000-000000000000';


  return {
    id,
    email: 'dev@example.com',
    role: role as any,
  };
}


This is dev-only – but enough to prove the path.
________________


4.2 Teacher: Create Assignment
pages/api/education/assignments/index.ts
// pages/api/education/assignments/index.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../../../lib/db';
import { getCurrentUser } from '../../../../lib/auth';
import { evaluatePolicy, sendLedgerEvent } from '../../../../lib/ceceClient';


export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const user = await getCurrentUser(req);


  if (req.method === 'POST') {
    try {
      // Governance: only teachers can create assignments
      const policy = await evaluatePolicy({
        subject: { role: user.role },
        action: 'assignment:create',
        resource: 'assignment',
        context: { teacherId: user.id },
      });


      if (policy.decision === 'deny') {
        await sendLedgerEvent({
          intent_id: null,
          actor: { user_id: user.id, role: user.role },
          action: 'assignment:create',
          resource: 'assignment',
          decision: 'deny',
          policy_id: policy.policy_id,
          metadata: { reason: policy.reason },
          timestamp: new Date().toISOString(),
        });
        return res.status(403).json({ error: 'Not allowed to create assignments' });
      }


      const { title, description, dueDate, studentIds } = req.body;


      const rows = await query<{ id: string }>(
        `
        INSERT INTO assignments (teacher_id, title, description, due_date)
        VALUES ($1, $2, $3, $4)
        RETURNING id;
        `,
        [user.id, title, description ?? null, dueDate ?? null]
      );


      const assignmentId = rows[0].id;


      if (Array.isArray(studentIds) && studentIds.length > 0) {
        const values: string[] = [];
        const params: any[] = [];
        studentIds.forEach((sid, idx) => {
          const i = idx * 2;
          values.push(`($${i + 1}, $${i + 2})`);
          params.push(assignmentId, sid);
        });


        await query(
          `
          INSERT INTO assignment_students (assignment_id, student_id)
          VALUES ${values.join(',')}
          ON CONFLICT DO NOTHING;
          `,
          params
        );
      }


      await sendLedgerEvent({
        intent_id: null,
        actor: { user_id: user.id, role: user.role },
        action: 'assignment:create',
        resource: 'assignment',
        decision: 'allow',
        policy_id: policy.policy_id,
        metadata: { assignment_id: assignmentId },
        timestamp: new Date().toISOString(),
      });


      return res.status(201).json({ id: assignmentId });
    } catch (error) {
      console.error('Error creating assignment', error);
      return res.status(500).json({ error: 'Internal server error' });
    }
  }


  if (req.method === 'GET') {
    // simple teacher list
    const assignments = await query(
      `
      SELECT id, title, description, due_date, created_at
      FROM assignments
      WHERE teacher_id = $1
      ORDER BY created_at DESC;
      `,
      [user.id]
    );
    return res.status(200).json({ assignments });
  }


  return res.status(405).json({ error: 'Method not allowed' });
}


________________


4.3 Student: List Assignments & Submit
pages/api/education/assignments/[id]/index.ts
// pages/api/education/assignments/[id]/index.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../../../../lib/db';
import { getCurrentUser } from '../../../../../lib/auth';


export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const user = await getCurrentUser(req);
  const { id } = req.query;
  const assignmentId = id as string;


  if (req.method === 'GET') {
    // Student or teacher can fetch details; you can tighten this later
    const [assignment] = await query(
      `
      SELECT a.id, a.title, a.description, a.due_date, a.teacher_id
      FROM assignments a
      WHERE a.id = $1;
      `,
      [assignmentId]
    );


    if (!assignment) {
      return res.status(404).json({ error: 'Assignment not found' });
    }


    return res.status(200).json({ assignment });
  }


  return res.status(405).json({ error: 'Method not allowed' });
}


pages/api/education/assignments/[id]/submit.ts
// pages/api/education/assignments/[id]/submit.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../../../../lib/db';
import { getCurrentUser } from '../../../../../lib/auth';
import { evaluatePolicy, sendLedgerEvent } from '../../../../../lib/ceceClient';


export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const user = await getCurrentUser(req);
  const { id } = req.query;
  const assignmentId = id as string;


  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }


  try {
    // Check assignment exists and is assigned to this student
    const [assignment] = await query<{ id: string }>(
      `
      SELECT a.id
      FROM assignments a
      JOIN assignment_students s ON s.assignment_id = a.id
      WHERE a.id = $1 AND s.student_id = $2;
      `,
      [assignmentId, user.id]
    );


    if (!assignment) {
      return res.status(403).json({ error: 'You are not assigned this homework' });
    }


    const policy = await evaluatePolicy({
      subject: { role: user.role },
      action: 'submission:submit',
      resource: 'assignment',
      context: { assignmentId, studentId: user.id },
    });


    if (policy.decision === 'deny') {
      await sendLedgerEvent({
        intent_id: null,
        actor: { user_id: user.id, role: user.role },
        action: 'submission:submit',
        resource: 'assignment',
        decision: 'deny',
        policy_id: policy.policy_id,
        metadata: { assignment_id: assignmentId },
        timestamp: new Date().toISOString(),
      });
      return res.status(403).json({ error: 'Not allowed to submit this assignment' });
    }


    const { content } = req.body;


    await query(
      `
      INSERT INTO submissions (assignment_id, student_id, content, status)
      VALUES ($1, $2, $3, 'submitted')
      ON CONFLICT (assignment_id, student_id)
      DO UPDATE SET content = EXCLUDED.content, status = 'submitted', updated_at = NOW();
      `,
      [assignmentId, user.id, content]
    );


    await sendLedgerEvent({
      intent_id: null,
      actor: { user_id: user.id, role: user.role },
      action: 'submission:submit',
      resource: 'assignment',
      decision: 'allow',
      policy_id: policy.policy_id,
      metadata: { assignment_id: assignmentId },
      timestamp: new Date().toISOString(),
    });


    return res.status(200).json({ status: 'submitted' });
  } catch (error) {
    console.error('Error submitting homework', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}


________________


4.4 Teacher: Review Submission
pages/api/education/submissions/[id]/review.ts
// pages/api/education/submissions/[id]/review.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../../../../lib/db';
import { getCurrentUser } from '../../../../../lib/auth';
import { evaluatePolicy, sendLedgerEvent } from '../../../../../lib/ceceClient';


export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const user = await getCurrentUser(req);
  const { id } = req.query;
  const submissionId = id as string;


  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }


  try {
    // Load submission and assignment to verify this teacher owns the assignment
    const [submission] = await query<{
      id: string;
      assignment_id: string;
      teacher_id: string;
      student_id: string;
    }>(
      `
      SELECT s.id, s.assignment_id, a.teacher_id, s.student_id
      FROM submissions s
      JOIN assignments a ON a.id = s.assignment_id
      WHERE s.id = $1;
      `,
      [submissionId]
    );


    if (!submission) {
      return res.status(404).json({ error: 'Submission not found' });
    }


    if (submission.teacher_id !== user.id) {
      return res.status(403).json({ error: 'You do not own this assignment' });
    }


    const policy = await evaluatePolicy({
      subject: { role: user.role },
      action: 'submission:review',
      resource: 'submission',
      context: {
        submissionId,
        assignmentId: submission.assignment_id,
        teacherId: user.id,
      },
    });


    if (policy.decision === 'deny') {
      await sendLedgerEvent({
        intent_id: null,
        actor: { user_id: user.id, role: user.role },
        action: 'submission:review',
        resource: 'submission',
        decision: 'deny',
        policy_id: policy.policy_id,
        metadata: { submission_id: submissionId },
        timestamp: new Date().toISOString(),
      });
      return res.status(403).json({ error: 'Not allowed to review submissions' });
    }


    // Mark as reviewed
    await query(
      `
      UPDATE submissions
      SET status = 'reviewed', updated_at = NOW()
      WHERE id = $1;
      `,
      [submissionId]
    );


    await sendLedgerEvent({
      intent_id: null,
      actor: { user_id: user.id, role: user.role },
      action: 'submission:review',
      resource: 'submission',
      decision: 'allow',
      policy_id: policy.policy_id,
      metadata: { submission_id: submissionId },
      timestamp: new Date().toISOString(),
    });


    return res.status(200).json({ status: 'reviewed' });
  } catch (error) {
    console.error('Error reviewing submission', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}


________________


This gives you:
* DB schema to support RoadWork v0.
* API routes that:
   * enforce Cece policies (assignment:create, submission:submit, submission:review)
   * emit ledger events for all three, in line with policies.education.yaml.
* A realistic but still v0 flow:
   * Teacher creates assignment → Student submits → Teacher reviews.
You’re now like one tiny login system away from a fully end-to-end, governed education vertical.
If you hit me with another “Next!”, I can:
* Turn these API routes into matching issues for blackroad-os-web and blackroad-os-pack-education, or
* Help you decide the first real user journey we test (teacher vs student vs creator) and script out how to dogfood it on your setup (Mac + Pi, etc.).