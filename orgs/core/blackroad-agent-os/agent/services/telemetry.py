"""
Telemetry Service - Collect system metrics
"""
import asyncio
import time
from typing import Optional
import psutil
import structlog

from models import Telemetry

logger = structlog.get_logger()


class TelemetryService:
    """
    Collects system telemetry data for reporting to controller.
    """

    def __init__(self, collect_interval: int = 10):
        self.collect_interval = collect_interval
        self._telemetry = Telemetry()
        self._running = False
        self._boot_time = psutil.boot_time()

    @property
    def current(self) -> Telemetry:
        """Get current telemetry data"""
        return self._telemetry

    async def start(self):
        """Start collecting telemetry"""
        self._running = True
        while self._running:
            try:
                await self._collect()
            except Exception as e:
                logger.error("telemetry_collect_error", error=str(e))
            await asyncio.sleep(self.collect_interval)

    async def stop(self):
        """Stop collecting telemetry"""
        self._running = False

    async def _collect(self):
        """Collect telemetry data"""
        # Run blocking calls in executor
        loop = asyncio.get_event_loop()

        cpu = await loop.run_in_executor(None, psutil.cpu_percent, 1)
        memory = await loop.run_in_executor(None, psutil.virtual_memory)
        disk = await loop.run_in_executor(None, psutil.disk_usage, "/")
        load = await loop.run_in_executor(None, psutil.getloadavg)

        self._telemetry = Telemetry(
            cpu_percent=cpu,
            memory_percent=memory.percent,
            disk_percent=disk.percent,
            load_avg=list(load),
            uptime_seconds=time.time() - self._boot_time,
        )
