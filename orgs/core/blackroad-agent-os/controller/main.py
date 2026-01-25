"""
BlackRoad Agent OS - Controller Service

Central orchestration service for managing Raspberry Pi agents.
"""
import asyncio
import os
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import structlog
import uvicorn

from api import agents_router, tasks_router, websocket_router
from api.websocket import dispatch_loop
from core.registry import registry
from services.audit import audit, AuditEventType, AuditEvent

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.dev.ConsoleRenderer()
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    logger.info("controller_starting", version="0.1.0")

    # Log system start
    audit.log(AuditEvent(
        event_type=AuditEventType.SYSTEM_STARTED,
        actor_type="system",
        action="start",
        details={"version": "0.1.0"},
    ))

    # Start background tasks
    dispatch_task = asyncio.create_task(dispatch_loop())
    health_task = asyncio.create_task(health_check_loop())

    yield

    # Cleanup
    dispatch_task.cancel()
    health_task.cancel()

    try:
        await dispatch_task
    except asyncio.CancelledError:
        pass

    try:
        await health_task
    except asyncio.CancelledError:
        pass

    # Log system stop
    audit.log(AuditEvent(
        event_type=AuditEventType.SYSTEM_STOPPED,
        actor_type="system",
        action="stop",
    ))

    logger.info("controller_stopped")


async def health_check_loop():
    """Background loop to check agent health"""
    while True:
        await asyncio.sleep(30)
        try:
            await registry.check_health()
        except Exception as e:
            logger.error("health_check_error", error=str(e))


# Create FastAPI app
app = FastAPI(
    title="BlackRoad Agent OS",
    description="Distributed agent orchestration system for Raspberry Pi machines",
    version="0.1.0",
    lifespan=lifespan,
)

# CORS middleware for browser access
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(agents_router)
app.include_router(tasks_router)
app.include_router(websocket_router)


@app.get("/")
async def root():
    """Root endpoint with system info"""
    return {
        "name": "BlackRoad Agent OS",
        "version": "0.1.0",
        "agents": len(registry.get_all()),
        "agents_online": len(registry.get_online()),
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    from services.planner_config import PlannerConfig
    config = PlannerConfig.from_env()

    return {
        "status": "healthy",
        "planner": {
            "provider": config.provider.value,
        },
        "agents": {
            "total": len(registry.get_all()),
            "online": len(registry.get_online()),
            "available": len(registry.get_available()),
        },
    }


# Mount static files for UI (if exists)
static_path = Path(__file__).parent / "static"
if static_path.exists():
    app.mount("/static", StaticFiles(directory=str(static_path)), name="static")


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=True,
        log_level="info",
    )
