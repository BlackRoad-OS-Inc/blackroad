#!/usr/bin/env python3
"""BlackRoad MCP Bridge"""
import os, subprocess, json, hashlib, platform
from datetime import datetime
from pathlib import Path
from typing import Optional
from fastapi import FastAPI, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

AUTH_TOKEN = os.getenv("MCP_BRIDGE_TOKEN", "1017034750fe4cb3868f47ba8eb4b8b03188ad6bed8582f262d81f99ac1473e3")
MEMORY_DIR = Path.home() / "blackroad" / "memory"
MEMORY_DIR.mkdir(parents=True, exist_ok=True)

app = FastAPI(title="BlackRoad MCP Bridge")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

async def verify_token(authorization: str = Header(...)):
    if not authorization.startswith("Bearer ") or authorization[7:] != AUTH_TOKEN:
        raise HTTPException(status_code=403, detail="Invalid token")

class ExecRequest(BaseModel):
    command: str
    cwd: Optional[str] = None
    timeout: Optional[int] = 60

class FileReadRequest(BaseModel):
    path: str

class FileWriteRequest(BaseModel):
    path: str
    content: str

class MemoryRequest(BaseModel):
    key: str
    value: Optional[dict] = None

@app.get("/")
async def root():
    return {"service": "BlackRoad MCP Bridge", "host": platform.node()}

@app.get("/system", dependencies=[Depends(verify_token)])
async def system_status():
    return {"hostname": platform.node(), "system": platform.system(), "timestamp": datetime.utcnow().isoformat()}

@app.post("/exec", dependencies=[Depends(verify_token)])
async def exec_command(req: ExecRequest):
    result = subprocess.run(req.command, shell=True, cwd=req.cwd, capture_output=True, text=True, timeout=req.timeout)
    return {"stdout": result.stdout, "stderr": result.stderr, "returncode": result.returncode}

@app.post("/file/read", dependencies=[Depends(verify_token)])
async def read_file(req: FileReadRequest):
    path = Path(req.path).expanduser()
    if not path.exists(): raise HTTPException(404, "Not found")
    return {"path": str(path), "content": path.read_text()}

@app.post("/file/write", dependencies=[Depends(verify_token)])
async def write_file(req: FileWriteRequest):
    path = Path(req.path).expanduser()
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(req.content)
    return {"path": str(path), "sha256": hashlib.sha256(req.content.encode()).hexdigest()}

@app.post("/memory/write", dependencies=[Depends(verify_token)])
async def memory_write(req: MemoryRequest):
    fp = MEMORY_DIR / f"{req.key.replace('/', '_')}.json"
    data = {"key": req.key, "value": req.value, "ts": datetime.utcnow().isoformat()}
    fp.write_text(json.dumps(data, indent=2))
    return {"status": "ok", "path": str(fp)}

@app.post("/memory/read", dependencies=[Depends(verify_token)])
async def memory_read(req: MemoryRequest):
    fp = MEMORY_DIR / f"{req.key.replace('/', '_')}.json"
    if not fp.exists(): raise HTTPException(404, "Key not found")
    return json.loads(fp.read_text())

@app.get("/memory/list", dependencies=[Depends(verify_token)])
async def memory_list():
    return {"keys": [f.stem for f in MEMORY_DIR.glob("*.json")]}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=8420)
