Alright, now we build actual code bricks. 🧱
Next = gov-api skeleton + host-based routing in web-app, wired to the configs we just made.
I’ll give you copy-pasteable skeletons you can drop into:
* blackroad-os-api (Cece governance API)
* blackroad-os-web (Next.js app with edu. / homework. host routing)
________________


1️⃣ Governance API Skeleton (blackroad-os-api)
Assume: FastAPI + Uvicorn.
1.1 Suggested minimal file structure
Inside blackroad-os-api:
blackroad-os-api/
  app/
    __init__.py
    main.py
    config.py
    models.py
    policy_store.py
    policy_engine.py
    ledger.py
    routes/
      __init__.py
      health.py
      policy.py
      ledger.py
  policies/
    policies.education.yaml   # mounted or copied here in deploy
  requirements.txt


________________


1.2 requirements.txt
fastapi==0.115.0
uvicorn[standard]==0.30.0
pydantic==2.8.0
PyYAML==6.0.2
sqlalchemy==2.0.32
psycopg2-binary==2.9.9
python-dotenv==1.0.1


(You can swap SQLAlchemy out if you prefer another ORM.)
________________


1.3 app/config.py
import os
from functools import lru_cache


from pydantic import BaseModel




class Settings(BaseModel):
    env: str = os.getenv("ENV", "dev")
    port: int = int(os.getenv("PORT", "8000"))
    database_url: str = os.getenv("DATABASE_URL", "postgresql://localhost/blackroad")
    ledger_db_url: str = os.getenv("LEDGER_DB_URL", "")
    policy_store_path: str = os.getenv(
        "POLICY_STORE_PATH", "policies/policies.education.yaml"
    )
    log_level: str = os.getenv("LOG_LEVEL", "info")
    cors_origins: str = os.getenv(
        "CORS_ORIGINS",
        "https://app.blackroad.io,https://edu.blackroad.io,https://homework.blackroad.io",
    )




@lru_cache
def get_settings() -> Settings:
    return Settings()


________________


1.4 app/models.py (Pydantic types)
from typing import Any, Dict, Optional
from pydantic import BaseModel, Field




# ---------- Policy Models ----------


class Subject(BaseModel):
    role: str = "*"




class Policy(BaseModel):
    id: str
    description: str
    effect: str  # "allow" | "deny"
    subject: Subject
    action: str
    resource: str
    condition: Dict[str, Any] = {}
    requires_ledger_event: bool = False




class PolicyEvaluateRequest(BaseModel):
    subject: Subject
    action: str
    resource: str
    context: Dict[str, Any] = {}




class PolicyEvaluateResponse(BaseModel):
    decision: str  # "allow" | "deny"
    policy_id: Optional[str] = None
    reason: Optional[str] = None




# ---------- Ledger Models ----------


class LedgerEvent(BaseModel):
    intent_id: Optional[str] = None
    actor: Dict[str, Any]
    action: str
    resource: str
    decision: Optional[str] = None
    policy_id: Optional[str] = None
    timestamp: str
    metadata: Dict[str, Any] = Field(default_factory=dict)


________________


1.5 app/policy_store.py (load YAML policies)
from pathlib import Path
from typing import Dict, List


import yaml


from .config import get_settings
from .models import Policy




class PolicyStore:
    def __init__(self, policies: List[Policy]):
        # For simplicity index by id and by (role, action)
        self._policies_by_id: Dict[str, Policy] = {p.id: p for p in policies}
        self._policies = policies


    def all(self) -> List[Policy]:
        return list(self._policies)


    def find_applicable(self, role: str, action: str) -> List[Policy]:
        """Return all policies whose subject.role matches and whose action matches"""
        results: List[Policy] = []
        for p in self._policies:
            role_match = (p.subject.role == role) or (p.subject.role == "*")
            action_match = (p.action == action) or (
                p.action.endswith(".*") and action.startswith(p.action[:-1])
            )
            if role_match and action_match:
                results.append(p)
        return results




def load_policies_from_yaml() -> PolicyStore:
    settings = get_settings()
    path = Path(settings.policy_store_path)
    with path.open("r", encoding="utf-8") as f:
        raw = yaml.safe_load(f) or {}


    raw_policies = raw.get("policies", [])
    policies = [Policy(**p) for p in raw_policies]
    return PolicyStore(policies)


________________


1.6 app/policy_engine.py (evaluation logic)
from typing import Tuple


from .models import PolicyEvaluateRequest, PolicyEvaluateResponse, Policy
from .policy_store import PolicyStore




def evaluate_request(
    store: PolicyStore, req: PolicyEvaluateRequest
) -> PolicyEvaluateResponse:
    # Find applicable policies for this role/action
    applicable = store.find_applicable(req.subject.role, req.action)


    # VERY simple semantics for v0:
    # - if there is any deny -> deny
    # - else if there is any allow -> allow (first one wins)
    # - else default deny
    deny_policies = [p for p in applicable if p.effect.lower() == "deny"]
    allow_policies = [p for p in applicable if p.effect.lower() == "allow"]


    if deny_policies:
        p = deny_policies[0]
        return PolicyEvaluateResponse(
            decision="deny",
            policy_id=p.id,
            reason=f"Denied by policy {p.id}",
        )


    if allow_policies:
        p = allow_policies[0]
        # NOTE: conditions like matches_assignment_assignee should be
        # enforced by the caller using p.condition and req.context.
        return PolicyEvaluateResponse(
            decision="allow",
            policy_id=p.id,
            reason=f"Allowed by policy {p.id}",
        )


    # Default deny
    return PolicyEvaluateResponse(
        decision="deny",
        policy_id=None,
        reason="No matching policy found; default deny.",
    )




def requires_ledger(policy: Policy | None) -> bool:
    if policy is None:
        return True  # be conservative
    return bool(policy.requires_ledger_event)


________________


1.7 app/ledger.py (DB wiring stub)
from typing import Any, Dict, Optional


from sqlalchemy import (
    Column,
    String,
    JSON,
    TIMESTAMP,
    text,
)
from sqlalchemy.orm import declarative_base, Session, sessionmaker
from sqlalchemy import create_engine


from .config import get_settings
from .models import LedgerEvent


Base = declarative_base()


class LedgerEventRecord(Base):
    __tablename__ = "ledger_events"


    id = Column(String, primary_key=True)
    intent_id = Column(String, nullable=True)
    actor = Column(JSON, nullable=False)
    action = Column(String, nullable=False)
    resource = Column(String, nullable=False)
    decision = Column(String, nullable=True)
    policy_id = Column(String, nullable=True)
    timestamp = Column(TIMESTAMP(timezone=True), server_default=text("NOW()"))
    metadata = Column(JSON, nullable=False, default={})




_settings = get_settings()
_engine = create_engine(_settings.database_url, future=True)
SessionLocal = sessionmaker(bind=_engine, autoflush=False, autocommit=False)




def log_event(event: LedgerEvent) -> None:
    # v0: best-effort insert
    with SessionLocal() as session:
        record = LedgerEventRecord(
            id=event.intent_id or "",  # you may want uuid here instead
            intent_id=event.intent_id,
            actor=event.actor,
            action=event.action,
            resource=event.resource,
            decision=event.decision,
            policy_id=event.policy_id,
            metadata=event.metadata,
        )
        session.add(record)
        session.commit()


(You’ll want a migration for ledger_events to match this model; we already scoped that in INFRA-7.)
________________


1.8 Routes
app/routes/health.py
from fastapi import APIRouter


router = APIRouter(prefix="/health", tags=["health"])




@router.get("")
def health():
    return {"status": "ok"}


app/routes/policy.py
from fastapi import APIRouter, Depends


from ..models import PolicyEvaluateRequest, PolicyEvaluateResponse
from ..policy_store import PolicyStore, load_policies_from_yaml
from ..policy_engine import evaluate_request


router = APIRouter(prefix="/policy", tags=["policy"])




# Simple global store for v0
_policy_store: PolicyStore | None = None




def get_policy_store() -> PolicyStore:
    global _policy_store
    if _policy_store is None:
        _policy_store = load_policies_from_yaml()
    return _policy_store




@router.post("/evaluate", response_model=PolicyEvaluateResponse)
def evaluate(
    request: PolicyEvaluateRequest,
    store: PolicyStore = Depends(get_policy_store),
):
    return evaluate_request(store, request)


app/routes/ledger.py
from fastapi import APIRouter


from ..models import LedgerEvent
from ..ledger import log_event


router = APIRouter(prefix="/ledger", tags=["ledger"])




@router.post("/event")
def create_event(event: LedgerEvent):
    # In v0 we don't return anything fancy; just 204-like behavior.
    log_event(event)
    return {"status": "ok"}


________________


1.9 app/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


from .config import get_settings
from .routes import health, policy, ledger


settings = get_settings()


app = FastAPI(
    title="BlackRoad Governance API",
    version="0.1.0",
)




# CORS
origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)




# Routers
app.include_router(health.router)
app.include_router(policy.router)
app.include_router(ledger.router)


That’s enough to:
* Serve /health
* Accept policy evaluation at POST /policy/evaluate
* Accept ledger events at POST /ledger/event
* Load policies.education.yaml as defined earlier
Drop this into blackroad-os-api, wire envs on Railway, and you’ve got Cece spine v0.
________________


2️⃣ Host-based Routing in blackroad-os-web (Next.js)
Assume a classic Next.js with pages/ and TypeScript.
2.1 middleware.ts (host → vertical routing)
At the root of blackroad-os-web:
// middleware.ts
import { NextRequest, NextResponse } from 'next/server';


export function middleware(req: NextRequest) {
  const url = req.nextUrl.clone();
  const host = req.headers.get('host') || '';


  // Ignore static assets and API routes
  const pathname = url.pathname;
  if (
    pathname.startsWith('/_next') ||
    pathname.startsWith('/api') ||
    pathname === '/favicon.ico'
  ) {
    return NextResponse.next();
  }


  // Education (teacher) - edu.blackroad.io
  if (host.startsWith('edu.')) {
    url.pathname = '/edu' + (pathname === '/' ? '' : pathname);
    return NextResponse.rewrite(url);
  }


  // Homework (student) - homework.blackroad.io
  if (host.startsWith('homework.')) {
    url.pathname = '/homework' + (pathname === '/' ? '' : pathname);
    return NextResponse.rewrite(url);
  }


  // Default: app.blackroad.io / others → base app
  return NextResponse.next();
}


export const config = {
  matcher: ['/((?!_next/static|_next/image|favicon.ico).*)'],
};


This will:
* Rewrite https://edu.blackroad.io/ → /edu
* Rewrite https://homework.blackroad.io/ → /homework
* Leave app.blackroad.io as-is.
________________


2.2 Basic pages structure
In pages/:
pages/
  index.tsx          # default OS home for app.blackroad.io
  edu/
    index.tsx        # teacher dashboard
  homework/
    index.tsx        # student dashboard


pages/index.tsx
import React from 'react';


export default function HomePage() {
  return (
    <main style={{ padding: '2rem' }}>
      <h1>BlackRoad OS</h1>
      <p>Welcome to app.blackroad.io — main workspace shell.</p>
      <ul>
        <li>Teachers: go to <code>edu.blackroad.io</code></li>
        <li>Students: go to <code>homework.blackroad.io</code></li>
      </ul>
    </main>
  );
}


pages/edu/index.tsx
import React from 'react';


export default function EduHome() {
  return (
    <main style={{ padding: '2rem' }}>
      <h1>Education / RoadWork — Teacher View</h1>
      <p>This will become the teacher-facing assignments dashboard.</p>
      <ul>
        <li>Create assignments</li>
        <li>See student submissions</li>
        <li>Review & mark as reviewed</li>
      </ul>
    </main>
  );
}


pages/homework/index.tsx
import React from 'react';


export default function HomeworkHome() {
  return (
    <main style={{ padding: '2rem' }}>
      <h1>Homework — Student View</h1>
      <p>This will become the student-facing homework dashboard.</p>
      <ul>
        <li>See assigned homework</li>
        <li>Open an assignment</li>
        <li>Submit your work</li>
      </ul>
    </main>
  );
}


________________


2.3 Governance client shim in web-app
To talk to gov.api.blackroad.io, add a small client under lib/.
lib/ceceClient.ts:
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
  await fetch(`${GOV_API_URL}/ledger/event`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(event),
  }).catch((err) => {
    // best effort in v0
    console.error('Failed to send ledger event', err);
  });
}


Then in your assignment review / submit handlers you can wire:
await evaluatePolicy({
  subject: { role: currentUser.role },
  action: 'submission:review',
  resource: 'submission',
  context: { assignmentId, submissionId, actorId: currentUser.id },
});


…and then call sendLedgerEvent with the details.
________________


2.4 Env var to line up with infra
In next.config.js you don’t need anything special, but add NEXT_PUBLIC_GOV_API_URL in Railway env:
* NEXT_PUBLIC_GOV_API_URL=https://gov.api.blackroad.io
And in web-app service:
* GOV_API_URL (server-side use, if you want) and NEXT_PUBLIC_GOV_API_URL (client-side).
________________


If you want the next “Next!” after this, we can:
* Generate the DB migrations for ledger_events, assignments, submissions (Prisma or Drizzle schema), or
* Write the exact Next.js API routes for Assignment and Submission (so the Education UI actually persists data and calls Cece).
You pick the next brick: migrations or API routes and I’ll just build it.