You’re a machine. I love this. Okay, we’re past “plan” and firmly in “this thing actually works” territory now.
At this point you already have:
* DB schema for users, assignments, submissions, ledger_events
* gov-api skeleton (FastAPI) with /policy/evaluate + /ledger/event
* Next.js host routing (app vs edu. vs homework.)
* Next.js API routes for:
   * POST/GET /api/education/assignments (teacher create/list)
   * GET /api/education/assignments/[id] (details)
   * POST /api/education/assignments/[id]/submit (student submit)
   * POST /api/education/submissions/[id]/review (teacher review)
* Cece client wired in web-app for policy + ledger
Next = actual UI + test flow.
Let’s make a teacher and a student actually click buttons and move data.
________________


1️⃣ Quick repo reality check (where this stuff lives)
From your GitHub, I can see (among many others):
* BlackRoad-OS/blackroad-os-api → good home for gov-api (governance)
* BlackRoad-OS/blackroad-os-infra → DNS, Railway, service_registry, policies
* BlackRoad-OS/blackroad-os-docs → governance/education docs
* BlackRoad-OS/blackroad-os-home, blackroad-os-core, blackroad-os-demo, etc.
I’ve been talking about blackroad-os-web as the Next.js app; if that repo name doesn’t exist yet, you can either:
* Create BlackRoad-OS/blackroad-os-web and drop the NextJS app there, or
* Use whichever repo currently holds your app shell (BlackRoad-AI/BlackRoad.io or BlackRoad-OS/blackroad-os-home) as “the web-app repo”.
Everything below assumes “web repo” = whatever you deploy to app.blackroad.io.
________________


2️⃣ Add a student assignments list API (tiny but needed)
Right now:
* Teacher list = GET /api/education/assignments
* Student submit uses assignment_students join, but there’s no simple “list my assignments” endpoint.
Let’s add one:
pages/api/education/student/assignments.ts
// pages/api/education/student/assignments.ts
import type { NextApiRequest, NextApiResponse } from 'next';
import { query } from '../../../../lib/db';
import { getCurrentUser } from '../../../../lib/auth';


export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  const user = await getCurrentUser(req);


  if (user.role !== 'student') {
    return res.status(403).json({ error: 'Only students can view this list' });
  }


  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }


  try {
    const assignments = await query(
      `
      SELECT a.id,
             a.title,
             a.description,
             a.due_date,
             a.teacher_id,
             u.name AS teacher_name
      FROM assignments a
      JOIN assignment_students s ON s.assignment_id = a.id
      JOIN users u ON u.id = a.teacher_id
      WHERE s.student_id = $1
      ORDER BY a.due_date NULLS LAST, a.created_at DESC;
      `,
      [user.id]
    );


    return res.status(200).json({ assignments });
  } catch (error) {
    console.error('Error fetching student assignments', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}


This gives the homework dashboard something sane to render.
________________


3️⃣ Teacher UI — pages/edu/index.tsx
This page will:
* Fetch teacher’s assignments from /api/education/assignments
* Render list of assignments
* Show a simple “create assignment” form (title + description + optional due date)
* (Optional) simple text input for student IDs for v0
// pages/edu/index.tsx
import React, { useEffect, useState, FormEvent } from 'react';


type Assignment = {
  id: string;
  title: string;
  description?: string;
  due_date?: string | null;
  created_at?: string;
};


export default function EduHome() {
  const [assignments, setAssignments] = useState<Assignment[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);


  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [dueDate, setDueDate] = useState('');
  const [studentIds, setStudentIds] = useState(''); // comma-separated UUIDs for v0


  async function fetchAssignments() {
    try {
      setLoading(true);
      const res = await fetch('/api/education/assignments');
      if (!res.ok) throw new Error(`Failed: ${res.status}`);
      const data = await res.json();
      setAssignments(data.assignments || []);
      setError(null);
    } catch (err: any) {
      console.error(err);
      setError('Failed to fetch assignments');
    } finally {
      setLoading(false);
    }
  }


  useEffect(() => {
    fetchAssignments();
  }, []);


  async function handleCreate(e: FormEvent) {
    e.preventDefault();
    try {
      setError(null);
      const body = {
        title,
        description,
        dueDate: dueDate || null,
        studentIds: studentIds
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean),
      };


      const res = await fetch('/api/education/assignments', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });


      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error || `Failed: ${res.status}`);
      }


      setTitle('');
      setDescription('');
      setDueDate('');
      setStudentIds('');
      await fetchAssignments();
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to create assignment');
    }
  }


  return (
    <main style={{ padding: '2rem', maxWidth: 800, margin: '0 auto' }}>
      <h1>Education / RoadWork — Teacher</h1>
      <p>You are viewing the teacher workspace at <code>edu.blackroad.io</code>.</p>


      <section style={{ marginTop: '2rem', marginBottom: '2rem' }}>
        <h2>Create Assignment</h2>
        <form onSubmit={handleCreate}>
          <div style={{ marginBottom: '0.75rem' }}>
            <label>
              Title<br />
              <input
                value={title}
                onChange={(e) => setTitle(e.target.value)}
                required
                style={{ width: '100%' }}
              />
            </label>
          </div>
          <div style={{ marginBottom: '0.75rem' }}>
            <label>
              Description<br />
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                rows={3}
                style={{ width: '100%' }}
              />
            </label>
          </div>
          <div style={{ marginBottom: '0.75rem' }}>
            <label>
              Due date (optional)<br />
              <input
                type="datetime-local"
                value={dueDate}
                onChange={(e) => setDueDate(e.target.value)}
              />
            </label>
          </div>
          <div style={{ marginBottom: '0.75rem' }}>
            <label>
              Student IDs (comma separated, v0)<br />
              <input
                value={studentIds}
                onChange={(e) => setStudentIds(e.target.value)}
                style={{ width: '100%' }}
                placeholder="uuid1, uuid2, uuid3"
              />
            </label>
          </div>
          <button type="submit">Create assignment</button>
        </form>
      </section>


      <section>
        <h2>Your Assignments</h2>
        {loading && <p>Loading…</p>}
        {error && <p style={{ color: 'red' }}>{error}</p>}
        {!loading && assignments.length === 0 && <p>No assignments yet.</p>}
        <ul>
          {assignments.map((a) => (
            <li key={a.id} style={{ marginBottom: '0.5rem' }}>
              <strong>{a.title}</strong>
              {a.due_date && (
                <>
                  {' '}
                  — due{' '}
                  {new Date(a.due_date).toLocaleString(undefined, {
                    dateStyle: 'medium',
                    timeStyle: 'short',
                  })}
                </>
              )}
            </li>
          ))}
        </ul>
      </section>
    </main>
  );
}


This is ugly-but-functional. We can beautify later.
________________


4️⃣ Student UI — pages/homework/index.tsx
This page:
* Fetches assigned homework from /api/education/student/assignments
* Lets student click into one assignment, show a simple text area, submit via /submit API
* Shows status + errors
// pages/homework/index.tsx
import React, { useEffect, useState, FormEvent } from 'react';


type Assignment = {
  id: string;
  title: string;
  description?: string;
  due_date?: string | null;
  teacher_name?: string;
};


export default function HomeworkHome() {
  const [assignments, setAssignments] = useState<Assignment[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [content, setContent] = useState('');
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);


  async function fetchAssignments() {
    try {
      setLoading(true);
      const res = await fetch('/api/education/student/assignments');
      if (!res.ok) throw new Error(`Failed: ${res.status}`);
      const data = await res.json();
      setAssignments(data.assignments || []);
      setError(null);
    } catch (err: any) {
      console.error(err);
      setError('Failed to fetch assignments');
    } finally {
      setLoading(false);
    }
  }


  useEffect(() => {
    fetchAssignments();
  }, []);


  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    if (!selectedId) return;


    try {
      setSubmitting(true);
      setError(null);
      setMessage(null);


      const res = await fetch(`/api/education/assignments/${selectedId}/submit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ content }),
      });


      const data = await res.json().catch(() => ({}));


      if (!res.ok) {
        throw new Error(data.error || `Failed: ${res.status}`);
      }


      setMessage('Submission saved!');
      setContent('');
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to submit homework');
    } finally {
      setSubmitting(false);
    }
  }


  const selected = assignments.find((a) => a.id === selectedId) || null;


  return (
    <main style={{ padding: '2rem', maxWidth: 800, margin: '0 auto' }}>
      <h1>Homework — Student</h1>
      <p>You are viewing the student workspace at <code>homework.blackroad.io</code>.</p>


      <section style={{ marginTop: '2rem' }}>
        <h2>Your assignments</h2>
        {loading && <p>Loading…</p>}
        {error && <p style={{ color: 'red' }}>{error}</p>}
        {!loading && assignments.length === 0 && <p>No assignments yet.</p>}


        <ul>
          {assignments.map((a) => (
            <li key={a.id} style={{ marginBottom: '0.5rem' }}>
              <button
                type="button"
                onClick={() => {
                  setSelectedId(a.id);
                  setMessage(null);
                  setError(null);
                  setContent('');
                }}
              >
                {a.title}
              </button>
              {a.due_date && (
                <>
                  {' '}
                  — due{' '}
                  {new Date(a.due_date).toLocaleString(undefined, {
                    dateStyle: 'medium',
                    timeStyle: 'short',
                  })}
                </>
              )}
              {a.teacher_name && <> — teacher: {a.teacher_name}</>}
            </li>
          ))}
        </ul>
      </section>


      {selected && (
        <section style={{ marginTop: '2rem' }}>
          <h2>Submit work for: {selected.title}</h2>
          {message && <p style={{ color: 'green' }}>{message}</p>}
          {error && <p style={{ color: 'red' }}>{error}</p>}
          <form onSubmit={handleSubmit}>
            <div style={{ marginBottom: '0.75rem' }}>
              <label>
                Your response<br />
                <textarea
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  rows={6}
                  style={{ width: '100%' }}
                  required
                />
              </label>
            </div>
            <button type="submit" disabled={submitting}>
              {submitting ? 'Submitting…' : 'Submit homework'}
            </button>
          </form>
        </section>
      )}
    </main>
  );
}


________________


5️⃣ Manual “Dev Mode” Test Script
Because auth isn’t wired yet, use the x-dev-role and x-dev-user-id headers we stubbed in getCurrentUser.
In your browser you can’t easily set headers, but you can:
* Use curl / HTTP client (Insomnia/Postman) or
* Temporarily hack getCurrentUser to:
// dev hack in lib/auth.ts
export async function getCurrentUser(req: any): Promise<CurrentUser> {
  // For dev, hardcode teacher vs student based on query param or hostname
  const host = req.headers['host'] as string;


  if (host.startsWith('edu.')) {
    return {
      id: '11111111-1111-1111-1111-111111111111', // fake teacher id that exists in DB
      email: 'teacher@example.com',
      role: 'teacher',
    };
  }


  if (host.startsWith('homework.')) {
    return {
      id: '22222222-2222-2222-2222-222222222222', // fake student id
      email: 'student@example.com',
      role: 'student',
    };
  }


  // default
  return {
    id: '00000000-0000-0000-0000-000000000000',
    email: 'dev@example.com',
    role: 'admin',
  };
}


Then:
1. Insert rows in users table for those IDs (teacher + student).
2. Open https://edu.blackroad.io:
   * Create assignment (past a student id).
3. Open https://homework.blackroad.io:
   * See assignment in list.
   * Submit homework.
4. In DB:
   * Check submissions table: row exists, status submitted.
   * Check ledger_events in governance DB: events for assignment:create and submission:submit present.
At that point you have:
* Real DB writes,
* Real Cece policy calls,
* Real ledger events,
* Real teacher/student screens, even if dev-auth-hacked.
________________


If you hit me with another “Next!!!!” after this, the next brick I’d build is:
* A tiny auth layer (even just email+magic link or password) so getCurrentUser is real, and we stop faking IDs — plus the policy wiring for “only teacher can review submission” in the UI (a basic review screen).