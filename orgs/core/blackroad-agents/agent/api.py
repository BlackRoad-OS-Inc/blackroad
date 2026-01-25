"""FastAPI application exposing the BlackRoad agent API."""
from __future__ import annotations

from typing import Any, Dict

from fastapi import FastAPI

from agent.auth import TokenAuthMiddleware
from agent.config import auth_token as get_auth_token
from agent.config import load as load_cfg
from agent.config import save as save_cfg

app = FastAPI(title="BlackRoad Agent API", version="1.0.0")
app.add_middleware(TokenAuthMiddleware)


@app.get("/healthz")
def healthcheck() -> Dict[str, Any]:
    """Return a minimal health payload."""
    return {"ok": True, "auth": bool(get_auth_token())}


@app.get("/settings")
def read_settings() -> Dict[str, Any]:
    """Return the current configuration."""
    return load_cfg()


@app.post("/settings/auth")
def set_auth_token(payload: Dict[str, Any] | None) -> Dict[str, Any]:
    """Persist a new shared authentication token."""
    token = (payload or {}).get("token", "")
    if token is None:
        token = ""
    token = str(token).strip()
    cfg = load_cfg()
    cfg.setdefault("auth", {})["token"] = token
    save_cfg(cfg)
    return {"ok": True, "enabled": bool(token)}
"""FastAPI surface for the BlackRoad device dashboard."""
"""FastAPI application exposing BlackRoad agent endpoints."""
"""FastAPI app exposing BlackRoad device agent endpoints."""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict

from fastapi import Body, FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from agent import discover
from agent.config import DEFAULT_USER, active_target, set_target

app = FastAPI(title="BlackRoad Device Agent")

templates = Jinja2Templates(directory=str(Path(__file__).parent / "templates"))


@app.get("/", response_class=HTMLResponse)
def dashboard(request: Request) -> HTMLResponse:
from fastapi import FastAPI, Request
from fastapi.templating import Jinja2Templates

from agent import discover
from agent.config import active_target, set_target

app = FastAPI(title="BlackRoad Agent", docs_url="/_docs")
_templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent / "templates"))


@app.get("/")
def dashboard(request: Request):
    """Serve the dashboard template."""
    context: Dict[str, Any] = {
        "request": request,
        "target": active_target(),
    }
    return templates.TemplateResponse("dashboard.html", context)


@app.get("/discover/scan")
def discover_scan() -> Dict[str, Any]:
    return _templates.TemplateResponse("dashboard.html", context)


@app.get("/discover/scan")
def discover_scan():
    return discover.scan()


@app.post("/discover/set")
def discover_set(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    host = payload.get("host")
    user = payload.get("user", DEFAULT_USER)
    if not host:
        return {"ok": False, "error": "host required"}
    try:
        set_target(host, user)
    except ValueError as exc:
        return {"ok": False, "error": str(exc)}
    except OSError as exc:
        return {"ok": False, "error": str(exc)}
    except Exception:
        return {"ok": False, "error": "failed to update target"}
def discover_set(j: Dict[str, Any]):
    host = j.get("host")
    user = j.get("user", "jetson")
"""FastAPI application exposing BlackRoad agent controls."""
from __future__ import annotations

import json
import pathlib
import subprocess
from typing import Any, Dict

from fastapi import Body, FastAPI, WebSocket, WebSocketDisconnect

from agent import flash, jobs, telemetry
from agent.config import active_target, load as load_cfg, set_target

app = FastAPI(title="BlackRoad Agent")


class ConnectionManager:
    """Minimal WebSocket manager for streaming logs."""

    def __init__(self) -> None:
        self._connections: set[WebSocket] = set()

    async def connect(self, websocket: WebSocket) -> None:
        await websocket.accept()
        self._connections.add(websocket)

    def disconnect(self, websocket: WebSocket) -> None:
        self._connections.discard(websocket)

    async def broadcast(self, message: str) -> None:
        for ws in list(self._connections):
            try:
                await ws.send_text(message)
            except RuntimeError:
                self.disconnect(ws)


manager = ConnectionManager()


@app.websocket("/ws/logs")
async def logs_websocket(websocket: WebSocket) -> None:
    """Simple echo socket that allows clients to keep an open channel."""
    await manager.connect(websocket)
    try:
        while True:
            try:
                payload = await websocket.receive_text()
            except RuntimeError:
                break
            await manager.broadcast(json.dumps({"echo": payload}))
    except WebSocketDisconnect:
        pass
    finally:
        manager.disconnect(websocket)


@app.get("/settings")
def get_settings() -> Dict[str, Any]:
    """Return the active Jetson settings and raw configuration."""
    host, user = active_target()
    return {"jetson": {"host": host, "user": user}, "raw": load_cfg()}


@app.post("/settings/jetson")
def set_jetson(jetson: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    host = (jetson or {}).get("host")
    user = (jetson or {}).get("user", "jetson")
    if not host:
        return {"ok": False, "error": "host required"}
    set_target(host, user)
    return {"ok": True, "jetson": {"host": host, "user": user}}


@app.get("/discover/target")
def get_target() -> Dict[str, Any]:
def discover_target():
    target = active_target()
    if not target:
        return {"ok": False, "jetson": None}
    return {"ok": True, "jetson": target}


__all__ = ["app"]
from fastapi import FastAPI, HTTPException
import os
from fastapi import Depends, FastAPI, Header, HTTPException, status
from pydantic import BaseModel
import uvicorn
from agent import telemetry, jobs

app = FastAPI(title="BlackRoad API")

JETSON_HOST = "jetson.local"
JETSON_USER = "jetson"


class JobRequest(BaseModel):
    command: str


@app.get("/status")
def status():
    """Return telemetry for Pi and Jetson."""
    try:
        pi = telemetry.collect_local()
    except telemetry.TelemetryError as exc:
        pi = {"status": "error", "detail": str(exc)}

    try:
        jetson = telemetry.collect_remote(JETSON_HOST, user=JETSON_USER)
    except telemetry.TelemetryError as exc:
        jetson = {"status": "error", "detail": str(exc)}

    return {"pi": pi, "jetson": jetson}


@app.post("/run")
def run_job(req: JobRequest):
    """Run a command on the Jetson."""
    try:
        result = jobs.run_remote(JETSON_HOST, req.command, user=JETSON_USER)
    except jobs.JobError as exc:
        raise HTTPException(status_code=502, detail=str(exc)) from exc
    return result


def main():
    uvicorn.run(app, host="0.0.0.0", port=8080)


if __name__ == "__main__":
    main()
"""FastAPI application exposing flashing utilities and dashboard UI."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Optional

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import HTMLResponse

from .flash import flash, list_devices

KNOWN_IMAGES = [
    {
        "name": "Raspberry Pi OS Lite (arm64)",
        "url": "https://downloads.raspberrypi.com/raspios_lite_arm64_latest",
    },
    {
        "name": "Ubuntu Server 24.04 (RPI arm64)",
        "url": "https://cdimage.ubuntu.com/releases/24.04/release/ubuntu-24.04.1-preinstalled-server-arm64+raspi.img.xz",
    },
    {
        "name": "BlackRoad OS (latest)",
        "url": "https://your.host/blackroad/latest.img.xz",
        "sha256": "https://your.host/blackroad/latest.sha256",
    },
]

app = FastAPI(title="BlackRoad Flasher")


@app.get("/")
def dashboard() -> HTMLResponse:
    """Serve the dashboard interface."""
    html_path = Path(__file__).resolve().parent.parent / "dashboard.html"
    html = html_path.read_text(encoding="utf-8")
    return HTMLResponse(html)
"""FastAPI app exposing the Pi flasher controls."""

from __future__ import annotations

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
"""FastAPI endpoints exposing device flashing capabilities."""
from __future__ import annotations

import asyncio
import threading
from typing import Any, Dict, Optional

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from starlette.websockets import WebSocketState

from agent import flash

app = FastAPI(title="BlackRoad Agent API")


@app.get("/flash/devices")
def flash_devices() -> dict:
    """List available block devices."""
    return {"devices": list_devices()}


@app.get("/flash/images")
def flash_images() -> dict:
    """Return curated image suggestions."""
    return {"images": KNOWN_IMAGES}


@app.websocket("/ws/flash")
async def ws_flash(websocket: WebSocket) -> None:
    await websocket.accept()
    try:
        payload_raw = await websocket.receive_text()
    except WebSocketDisconnect:
        return

    try:
        payload = json.loads(payload_raw)
    except json.JSONDecodeError:
        await websocket.send_text("ERROR: invalid payload")
        await websocket.close()
        return

    device = payload.get("device", "").strip()
    image_url = payload.get("image_url", "").strip()
    sha_url: Optional[str] = (payload.get("sha256_url") or payload.get("sha_url") or "").strip() or None

    if not device or not image_url:
        await websocket.send_text("ERROR: device and image_url required")
        await websocket.close()
        return

    try:
        for line in flash(device, image_url, sha_url):
            await websocket.send_text(line)
    except WebSocketDisconnect:
        return
    except Exception as exc:  # noqa: BLE001
        await websocket.send_text(f"ERROR: {exc}")
    finally:
        await websocket.close()
from fastapi import FastAPI
from fastapi import FastAPI, HTTPException
from fastapi.responses import HTMLResponse

from agent import models
"""FastAPI surface for agent utilities."""

from __future__ import annotations

import pathlib
import tempfile

from fastapi import FastAPI, File, UploadFile

from agent import transcribe

app = FastAPI(title="BlackRoad Agent API")

_DASHBOARD_PATH = Path(__file__).resolve().parent.parent / "dashboard.html"


def _load_dashboard() -> str:
    """Load the dashboard HTML from disk."""

    try:
        return _DASHBOARD_PATH.read_text(encoding="utf-8")
    except OSError as exc:  # pragma: no cover - protects startup failures
        raise HTTPException(status_code=500, detail="dashboard unavailable") from exc


@app.get("/", response_class=HTMLResponse)
def dashboard() -> str:
    """Serve the static dashboard UI."""

    return _load_dashboard()


@app.get("/models")
def models_list() -> Dict[str, Any]:
    """Return available local GGUF/BIN models."""

    return {"models": models.list_models()}


@app.post("/models/run")
def models_run(payload: Dict[str, Any]) -> Dict[str, Any]:
    """Run a llama.cpp model once with the provided prompt."""

    model = (payload or {}).get("model")
    prompt = (payload or {}).get("prompt", "")
    n_raw = (payload or {}).get("n", 128)

    if not model or not prompt:
        return {"error": "model and prompt required"}

    try:
        n_predict = max(1, int(n_raw))
    except (TypeError, ValueError):
        return {"error": "n must be an integer"}

    model_path = Path(model)
    if not model_path.exists():
        candidate = models.MODELS_DIR / model
        model_path = candidate if candidate.exists() else model_path

    try:
        resolved = model_path.resolve(strict=True)
    except FileNotFoundError:
        return {"error": f"model not found: {model}"}

    try:
        resolved.relative_to(models.MODELS_DIR.resolve())
    except ValueError:
        return {"error": "model must live under /var/lib/blackroad/models"}

    return models.run_llama(str(resolved), prompt, n_predict=n_predict)
    """Return removable devices available for flashing."""

    return {"devices": flash.list_devices()}
async def _list_devices() -> list[dict[str, Any]]:
    data = await asyncio.to_thread(flash.list_devices)
    if isinstance(data, dict):
        message = data.get("error", "Failed to enumerate devices")
        raise HTTPException(status_code=500, detail=message)
    return data


@app.get("/flash/devices")
async def flash_devices() -> Dict[str, Any]:
    """Return removable block devices available for flashing."""

    devices = await _list_devices()
    return {"devices": devices}


def _start_flash_worker(
    queue: "asyncio.Queue[str | None]",
    loop: asyncio.AbstractEventLoop,
    device: str,
    image_url: str,
    safe_hdmi: bool,
    enable_ssh: bool,
    stop: threading.Event,
) -> threading.Thread:
    def worker() -> None:
        try:
            for line in flash.flash(
                image_url,
                device,
                safe_hdmi=safe_hdmi,
                enable_ssh=enable_ssh,
            ):
                if stop.is_set():
                    break
                asyncio.run_coroutine_threadsafe(queue.put(line), loop)
        except Exception as exc:  # pragma: no cover - safety net
            asyncio.run_coroutine_threadsafe(queue.put(f"ERROR: {exc}"), loop)
        finally:
            asyncio.run_coroutine_threadsafe(queue.put(None), loop)

    thread = threading.Thread(target=worker, name="flash-writer", daemon=True)
    thread.start()
    return thread


@app.websocket("/ws/flash")
async def ws_flash(ws: WebSocket) -> None:
    """Stream flashing progress to the dashboard."""

    await ws.accept()
    await ws.accept()
    stop = threading.Event()
    queue: "asyncio.Queue[str | None]" = asyncio.Queue()
    thread: Optional[threading.Thread] = None

    try:
        msg = await ws.receive_json()
        device = msg.get("device")
        image_url = msg.get("image_url")
        if not device or not image_url:
            await ws.send_text("ERROR: device and image_url required")
            await ws.send_text("[[BLACKROAD_DONE]]")
            return

        for line in flash.flash(image_url, device):
        safe_hdmi = bool(msg.get("safe_hdmi", True))
        enable_ssh = bool(msg.get("enable_ssh", True))

        if not device or not image_url:
            await ws.send_text("ERROR: device and image_url are required")
            return

        loop = asyncio.get_running_loop()
        thread = _start_flash_worker(
            queue,
            loop,
            device,
            image_url,
            safe_hdmi,
            enable_ssh,
            stop,
        )

        while True:
            line = await queue.get()
            if line is None:
                break
            await ws.send_text(line)

        await ws.send_text("[[BLACKROAD_DONE]]")
    except WebSocketDisconnect:
        return
    except Exception as exc:  # pragma: no cover - network/runtime failure
        await ws.send_text(f"ERROR: {exc}")
        await ws.send_text("[[BLACKROAD_DONE]]")
    finally:
        if ws.application_state != WebSocketState.DISCONNECTED:
        stop.set()
    except Exception as exc:  # pragma: no cover - defensive guard
        await ws.send_text(f"ERROR: {exc}")
    finally:
        stop.set()
        if thread is not None:
            thread.join(timeout=1)
        if ws.client_state == WebSocketState.CONNECTED:
            await ws.close()
@app.get("/connect/test")
def connect_test() -> Dict[str, Any]:
    """Attempt to gather telemetry from the Pi and Jetson."""
    try:
        pi = telemetry.collect_local()
        jetson = telemetry.collect_remote()
        ok = all(not str(value).startswith("error") for value in jetson.values())
        return {"ok": ok, "pi": pi, "jetson": jetson}
    except Exception as exc:  # pragma: no cover - defensive
        return {"ok": False, "error": str(exc)}


@app.post("/connect/install-key")
def install_key() -> Dict[str, Any]:
    """Generate an SSH key for the `pi` user and copy it to the Jetson target."""
    host, user = active_target()
    home = pathlib.Path("/home/pi")
    ssh_dir = home / ".ssh"
    ssh_dir.mkdir(parents=True, exist_ok=True)
    key_path = ssh_dir / "id_rsa"

    if not key_path.exists():
        subprocess.run(
            [
                "sudo",
                "-u",
                "pi",
                "ssh-keygen",
                "-t",
                "rsa",
                "-N",
                "",
                "-f",
                str(key_path),
            ],
            check=True,
        )

    result = subprocess.call(
        [
            "sudo",
            "-u",
            "pi",
            "ssh-copy-id",
            "-i",
            f"{key_path}.pub",
            f"{user}@{host}",
        ]
    )
    note = (
        "If this returned false, run ssh-copy-id manually in a shell to enter the password."
    )
    return {"ok": result == 0, "note": note}


@app.get("/telemetry/local")
def telemetry_local() -> Dict[str, Any]:
    """Expose local telemetry for the dashboard."""
    return telemetry.collect_local()


@app.get("/telemetry/remote")
def telemetry_remote(host: str | None = None, user: str | None = None) -> Dict[str, Any]:
    """Expose remote telemetry, allowing overrides via query parameters."""
    return telemetry.collect_remote(host=host, user=user)


@app.post("/jobs/run")
def run_job(payload: Dict[str, Any] = Body(...)) -> Dict[str, Any]:
    """Execute a remote command on the Jetson target."""
    command = payload.get("command")
    host = payload.get("host")
    user = payload.get("user")
    if not command:
        return {"ok": False, "error": "command required"}
    result = jobs.run_remote(command, host=host, user=user)
    return {
        "ok": result.returncode == 0,
        "stdout": (result.stdout or "").strip(),
        "stderr": (result.stderr or "").strip(),
    }


@app.get("/flash/probe")
def flash_probe(host: str | None = None, user: str | None = None) -> Dict[str, Any]:
    """Call the flash probe helper."""
    return flash.probe(host=host, user=user)


__all__ = ["app"]
"""FastAPI application powering the agent dashboard."""

from __future__ import annotations

import asyncio
import json
import pathlib
import threading
from typing import Any

from fastapi import File, Request, UploadFile, WebSocket, WebSocketDisconnect
from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from agent import transcribe

app = FastAPI(title="BlackRoad Agent Dashboard")
templates = Jinja2Templates(directory=str(pathlib.Path(__file__).parent / "templates"))


@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request) -> HTMLResponse:
    """Render the dashboard UI."""

    return templates.TemplateResponse("dashboard.html", {"request": request})


@app.post("/transcribe/upload")
async def transcribe_upload(file: UploadFile = File(...)) -> dict[str, Any]:
    data = await file.read()
    suffix = pathlib.Path(file.filename or "audio.wav").suffix
    path = transcribe.save_upload(data, suffix=suffix)
    token = pathlib.Path(path).name
    return {"token": token}


@app.websocket("/ws/transcribe/run")
async def ws_transcribe(ws: WebSocket) -> None:
    await ws.accept()
    try:
        try:
            msg = await ws.receive_text()
        except WebSocketDisconnect:
            return
        except Exception:  # pragma: no cover - unexpected
            await ws.send_text("[error] invalid request")
            return

        try:
            payload = json.loads(msg)
        except json.JSONDecodeError:
            await ws.send_text("[error] invalid json")
            return

        token = payload.get("token")
        lang = payload.get("lang", "en")
        model = payload.get("model")

        if not token:
            await ws.send_text("[error] missing token")
            return

        candidate = (transcribe.TMP_DIR / token).resolve()
        try:
            candidate.relative_to(transcribe.TMP_DIR)
        except ValueError:
            await ws.send_text("[error] bad token")
            return

        if not candidate.exists():
            await ws.send_text("[error] audio not found")
            return

        queue: asyncio.Queue[tuple[str, str | None]] = asyncio.Queue()
        loop = asyncio.get_running_loop()

        def pump_stream() -> None:
            try:
                for line in transcribe.run_whisper_stream(
                    str(candidate), model_path=model, lang=lang
                ):
                    loop.call_soon_threadsafe(queue.put_nowait, ("data", line))
            except Exception as exc:  # pragma: no cover - defensive
                loop.call_soon_threadsafe(queue.put_nowait, ("error", str(exc)))
            finally:
                loop.call_soon_threadsafe(queue.put_nowait, ("done", None))

        thread = threading.Thread(target=pump_stream, name="whisper-stream", daemon=True)
        thread.start()

        try:
            while True:
                kind, payload = await queue.get()

                try:
                    if kind == "data" and payload is not None:
                        await ws.send_text(payload)
                    elif kind == "error" and payload is not None:
                        await ws.send_text(f"[error] {payload}")
                    elif kind == "done":
                        await ws.send_text("[[BLACKROAD_WHISPER_DONE]]")
                        break
                except WebSocketDisconnect:
                    break
        finally:
            if thread.is_alive():
                await asyncio.to_thread(thread.join)
    finally:
        try:
            await ws.close()
        except WebSocketDisconnect:
            pass
        except RuntimeError:
            # Connection already closed or closing; safe to ignore.
            pass
@app.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...)) -> dict[str, str]:
    """Accept an uploaded audio file and run whisper.cpp locally."""
    with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp:
        data = await file.read()
        tmp.write(data)
        tmp_path = pathlib.Path(tmp.name)

    try:
        text = transcribe.run_whisper(str(tmp_path))
    finally:
        tmp_path.unlink(missing_ok=True)

    return {"text": text}
"""FastAPI endpoints for streaming local model tokens to the dashboard."""

from __future__ import annotations

import asyncio
import contextlib

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse

from . import models

app = FastAPI(title="BlackRoad Local Models")


@app.get("/models")
async def get_models() -> JSONResponse:
    """Return the available local models."""

    return JSONResponse({"models": models.list_local_models()})


@app.websocket("/ws/model")
async def ws_model(ws: WebSocket) -> None:
    """Stream llama.cpp output over the websocket connection."""

    await ws.accept()
    try:
        message = await ws.receive_json()
        model = message.get("model")
        prompt = message.get("prompt", "")
        try:
            n_predict = int(message.get("n", 128))
        except (TypeError, ValueError):
            n_predict = 128

        if not model:
            await ws.send_text("[error] model path missing")
            await ws.send_text("[[BLACKROAD_MODEL_DONE]]")
            return

        loop = asyncio.get_running_loop()
        done_event = asyncio.Event()

        def stream_tokens() -> None:
            try:
                for token in models.run_llama_stream(
                    model, prompt, n_predict=n_predict
                ):
                    send_future = asyncio.run_coroutine_threadsafe(
                        ws.send_text(token), loop
                    )
                    try:
                        send_future.result()
                    except WebSocketDisconnect:
                        break
            except Exception as stream_exc:  # pragma: no cover - defensive in thread
                asyncio.run_coroutine_threadsafe(
                    ws.send_text(f"[error] {stream_exc}"), loop
                ).result()
            finally:
                asyncio.run_coroutine_threadsafe(
                    ws.send_text("[[BLACKROAD_MODEL_DONE]]"), loop
                ).result()
                loop.call_soon_threadsafe(done_event.set)

        await asyncio.gather(asyncio.to_thread(stream_tokens), done_event.wait())
    except WebSocketDisconnect:
        return
    except Exception as exc:  # pragma: no cover - defensive; websocket lifecycle
        await ws.send_text(f"[error] {exc}")
        await ws.send_text("[[BLACKROAD_MODEL_DONE]]")
    finally:
        with contextlib.suppress(RuntimeError):
            await ws.close()
JETSON_HOST = os.getenv("JETSON_HOST", "jetson.local")
JETSON_USER = os.getenv("JETSON_USER", "jetson")
AUTH_TOKEN = os.getenv("AGENT_AUTH_TOKEN")

if not AUTH_TOKEN:
    raise RuntimeError("AGENT_AUTH_TOKEN environment variable must be set for the API service")


def require_bearer_token(authorization: str = Header(default="")):
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or token != AUTH_TOKEN:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Unauthorized",
            headers={"WWW-Authenticate": "Bearer"},
        )


class JobRequest(BaseModel):
    command: str


@app.get("/status")
def status(_: None = Depends(require_bearer_token)):
    return {
        "target": {"host": JETSON_HOST, "user": JETSON_USER},
        "pi": telemetry.collect_local(),
        "jetson": telemetry.collect_remote(JETSON_HOST, JETSON_USER),
    }


@app.post("/run")
def run_job(req: JobRequest, _: None = Depends(require_bearer_token)):
    jobs.run_remote(JETSON_HOST, req.command, JETSON_USER)
    return {"ok": True, "command": req.command}


def main():
    uvicorn.run(app, host="0.0.0.0", port=8080)
