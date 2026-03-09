#!/usr/bin/env python3
"""
BlackRoad Salesforce Agent - Daemon Mode

Runs continuously, processing tasks from the queue.
Designed for systemd deployment on Pi cluster.

Usage:
    python -m src.daemon
    python -m src.daemon --username alexa@alexa.com
"""

import sys
import time
import signal
import argparse
from datetime import datetime
import structlog

from .auth.oauth import SalesforceAuth
from .api.client import SalesforceClient
from .api.bulk import BulkClient
from .queue.task_queue import TaskQueue, Task, TaskStatus, TaskPriority

# Configure logging for daemon
structlog.configure(
    processors=[
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer()
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    context_class=dict,
    logger_factory=structlog.stdlib.LoggerFactory(),
)

logger = structlog.get_logger()


class SalesforceDaemon:
    """Daemon that processes Salesforce tasks from queue"""

    def __init__(self, username: str, sfdx_dir: str = "~/.sfdx"):
        self.username = username
        self.sfdx_dir = sfdx_dir
        self.running = False

        # Will be initialized on start
        self.auth = None
        self.client = None
        self.bulk = None
        self.queue = None

        # Stats
        self.tasks_processed = 0
        self.tasks_failed = 0
        self.start_time = None

    def start(self):
        """Start the daemon"""
        logger.info("daemon_starting", username=self.username)

        # Load auth
        self.auth = SalesforceAuth.from_sfdx(self.username, self.sfdx_dir)
        self.client = SalesforceClient(self.auth)
        self.bulk = BulkClient(self.auth)
        self.queue = TaskQueue()

        # Verify connection
        limits = self.client.get_limits()
        daily = limits.get("DailyApiRequests", {})
        logger.info("daemon_connected",
                   instance=self.auth._token.instance_url,
                   api_remaining=daily.get('Remaining'),
                   api_max=daily.get('Max'))

        # Setup signal handlers
        signal.signal(signal.SIGINT, self._handle_shutdown)
        signal.signal(signal.SIGTERM, self._handle_shutdown)

        self.running = True
        self.start_time = time.time()

        logger.info("daemon_started")
        print(f"[{datetime.now().isoformat()}] BlackRoad Salesforce Daemon started")
        print(f"  User: {self.username}")
        print(f"  Instance: {self.auth._token.instance_url}")
        print(f"  API: {daily.get('Remaining')}/{daily.get('Max')} remaining")
        print(f"  Waiting for tasks...")

        # Main loop
        self._run_loop()

    def _run_loop(self):
        """Main processing loop"""
        idle_count = 0
        last_status = time.time()

        while self.running:
            try:
                # Check for tasks
                task = self.queue.get_next(f"daemon-{self.username}")

                if task:
                    idle_count = 0
                    self._process_task(task)
                else:
                    idle_count += 1
                    # Adaptive sleep: 1s, 2s, 4s, max 30s
                    sleep_time = min(30, 2 ** min(idle_count // 10, 5))
                    time.sleep(sleep_time)

                # Periodic status log (every 5 minutes)
                if time.time() - last_status > 300:
                    self._log_status()
                    last_status = time.time()

            except Exception as e:
                logger.error("loop_error", error=str(e))
                time.sleep(5)

        logger.info("daemon_stopped",
                   tasks_processed=self.tasks_processed,
                   tasks_failed=self.tasks_failed,
                   uptime_seconds=int(time.time() - self.start_time))

    def _process_task(self, task: Task):
        """Process a single task"""
        logger.info("task_processing",
                   task_id=task.id,
                   operation=task.operation,
                   sobject=task.sobject)

        try:
            result = None

            if task.operation == "create":
                record_id = self.client.create(task.sobject, task.data)
                result = {"id": record_id, "success": True}

            elif task.operation == "update":
                record_id = task.data.pop("id")
                self.client.update(task.sobject, record_id, task.data)
                result = {"id": record_id, "success": True}

            elif task.operation == "delete":
                record_id = task.data.get("id")
                self.client.delete(task.sobject, record_id)
                result = {"id": record_id, "success": True}

            elif task.operation == "query":
                soql = task.data.get("soql")
                query_result = self.client.query(soql)
                result = {"records": query_result.records, "total": query_result.total_size}

            elif task.operation == "bulk_insert":
                records = task.data.get("records", [])
                bulk_result = self.bulk.insert(task.sobject, records)
                result = {
                    "job_id": bulk_result.job_id,
                    "processed": bulk_result.records_processed,
                    "failed": bulk_result.records_failed
                }

            else:
                raise ValueError(f"Unknown operation: {task.operation}")

            self.queue.complete(task.id, result)
            self.tasks_processed += 1
            logger.info("task_completed", task_id=task.id, operation=task.operation)

        except Exception as e:
            self.queue.fail(task.id, str(e))
            self.tasks_failed += 1
            logger.error("task_failed", task_id=task.id, error=str(e))

    def _log_status(self):
        """Log daemon status"""
        stats = self.queue.stats()
        uptime = int(time.time() - self.start_time)

        logger.info("daemon_status",
                   uptime_seconds=uptime,
                   tasks_processed=self.tasks_processed,
                   tasks_failed=self.tasks_failed,
                   queue_pending=stats['pending'],
                   queue_processing=stats['processing'])

    def _handle_shutdown(self, signum, frame):
        """Handle shutdown signal"""
        logger.info("shutdown_signal", signal=signum)
        self.running = False


def main():
    parser = argparse.ArgumentParser(
        description="BlackRoad Salesforce Agent Daemon"
    )
    parser.add_argument(
        "--username", "-u",
        default="alexa@alexa.com",
        help="Salesforce username"
    )
    parser.add_argument(
        "--sfdx-dir",
        default="~/.sfdx",
        help="SFDX auth directory"
    )

    args = parser.parse_args()

    daemon = SalesforceDaemon(args.username, args.sfdx_dir)
    daemon.start()


if __name__ == "__main__":
    main()
