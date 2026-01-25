"""FastAPI application serving the BlackRoad dashboard."""

from __future__ import annotations

from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from agent.auth import TokenAuthMiddleware

BASE_DIR = Path(__file__).resolve().parent
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))

app = FastAPI(title="BlackRoad Dashboard", version="1.0.0")
app.add_middleware(TokenAuthMiddleware)


@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request) -> HTMLResponse:
    """Render the dashboard UI."""
    return templates.TemplateResponse("dashboard.html", {"request": request})
import uvicorn

from agent import telemetry

app = FastAPI(title="BlackRoad Dashboard")
_templates_dir = Path(__file__).parent / "templates"
templates = Jinja2Templates(directory=str(_templates_dir))
"""FastAPI application providing the BlackRoad device dashboard."""

from __future__ import annotations

from fastapi import FastAPI, Request, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from agent import jobs, telemetry
from fastapi import FastAPI, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
import uvicorn
from agent import telemetry, jobs

app = FastAPI(title="BlackRoad Dashboard")
templates = Jinja2Templates(directory="agent/templates")

JETSON_HOST = "jetson.local"
JETSON_USER = "jetson"


@app.get("/", response_class=HTMLResponse)
def home(request: Request):
def home(request: Request) -> HTMLResponse:
    """Render the dashboard page with telemetry from the Pi and Jetson."""
import asyncio
import base64
import os
import secrets
import threading

from fastapi import (
    Depends,
    FastAPI,
    Form,
    HTTPException,
    Request,
    WebSocket,
    WebSocketDisconnect,
    WebSocketException,
    status,
)
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from fastapi.templating import Jinja2Templates
import uvicorn
from agent import telemetry, jobs

app = FastAPI(title="BlackRoad Dashboard")
templates = Jinja2Templates(directory="agent/templates")

JETSON_HOST = os.getenv("JETSON_HOST", "jetson.local")
JETSON_USER = os.getenv("JETSON_USER", "jetson")
DASHBOARD_USERNAME = os.getenv("AGENT_DASHBOARD_USERNAME", "operator")
DASHBOARD_PASSWORD = os.getenv("AGENT_DASHBOARD_PASSWORD")

if not DASHBOARD_PASSWORD:
    raise RuntimeError("AGENT_DASHBOARD_PASSWORD environment variable must be set for the dashboard")

basic_auth = HTTPBasic()


def require_basic_auth(credentials: HTTPBasicCredentials = Depends(basic_auth)):
    username_ok = secrets.compare_digest(credentials.username, DASHBOARD_USERNAME)
    password_ok = secrets.compare_digest(credentials.password, DASHBOARD_PASSWORD)
    if not (username_ok and password_ok):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized",
            headers={"WWW-Authenticate": "Basic"},
        )


def _require_websocket_basic_auth(websocket: WebSocket):
    header = websocket.headers.get("authorization", "")
    if not header.lower().startswith("basic "):
        raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Unauthorized")
    try:
        encoded = header.split(" ", 1)[1]
        decoded = base64.b64decode(encoded).decode()
    except Exception as exc:  # noqa: BLE001
        raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid credentials") from exc
    username, _, password = decoded.partition(":")
    username_ok = secrets.compare_digest(username, DASHBOARD_USERNAME)
    password_ok = secrets.compare_digest(password, DASHBOARD_PASSWORD)
    if not (username_ok and password_ok):
        raise WebSocketException(code=status.WS_1008_POLICY_VIOLATION, reason="Unauthorized")


@app.get("/", response_class=HTMLResponse)
def home(request: Request, _: HTTPBasicCredentials = Depends(require_basic_auth)):
    pi = telemetry.collect_local()
    jetson = telemetry.collect_remote(JETSON_HOST, user=JETSON_USER)
    return templates.TemplateResponse(
        "dashboard.html",
        {"request": request, "pi": pi, "jetson": jetson},
    )


def main():
    uvicorn.run(app, host="0.0.0.0", port=8081)
@app.websocket("/ws/run")
async def ws_run(websocket: WebSocket) -> None:
    """WebSocket endpoint streaming command output from the Jetson."""
    await websocket.accept()
    try:
        cmd = await websocket.receive_text()
        for line in jobs.run_remote_stream(JETSON_HOST, cmd, user=JETSON_USER):
        {
            "request": request,
            "pi": pi,
            "jetson": jetson,
            "target": {"host": JETSON_HOST, "user": JETSON_USER},
        }
        {"request": request, "pi": pi, "jetson": jetson}
    )


@app.post("/run")
def run_job(
    command: str = Form(...),
    _: HTTPBasicCredentials = Depends(require_basic_auth),
):
def run_job(command: str = Form(...)):
    jobs.run_remote(JETSON_HOST, command, user=JETSON_USER)
    return RedirectResponse("/", status_code=303)


@app.websocket("/ws/run")
async def ws_run(websocket: WebSocket):
    try:
        _require_websocket_basic_auth(websocket)
    except WebSocketException as exc:
        await websocket.close(code=exc.code, reason=exc.reason)
        return

    await websocket.accept()
    try:
        cmd = await websocket.receive_text()
    except WebSocketDisconnect:
        await websocket.close()
        return

    loop = asyncio.get_running_loop()
    queue: asyncio.Queue = asyncio.Queue()

    def producer() -> None:
        try:
            for line in jobs.run_remote_stream(JETSON_HOST, cmd, user=JETSON_USER):
                asyncio.run_coroutine_threadsafe(queue.put(line), loop).result()
        finally:
            asyncio.run_coroutine_threadsafe(queue.put(None), loop).result()

    thread = threading.Thread(target=producer, daemon=True)
    thread.start()

    try:
        while True:
            line = await queue.get()
            if line is None:
                break
            await websocket.send_text(line)
        await websocket.send_text("[[BLACKROAD_DONE]]")
    except WebSocketDisconnect:
        pass
    finally:
        await websocket.close()


def main():
    uvicorn.run(app, host="0.0.0.0", port=8081)
def main():
    uvicorn.run(app, host="0.0.0.0", port=8081)


if __name__ == "__main__":
    main()
