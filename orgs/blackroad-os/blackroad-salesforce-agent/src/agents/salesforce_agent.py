"""
BlackRoad Salesforce Agent

The core autonomous agent that enables 1 Salesforce seat to serve billions.
Runs on Octavia (Pi cluster) with 500+ concurrent instances.
"""

import time
import uuid
import signal
import threading
from typing import Any, Dict, List, Optional, Callable
from dataclasses import dataclass
from concurrent.futures import ThreadPoolExecutor
import structlog

from ..auth.oauth import SalesforceAuth, AuthConfig
from ..api.client import SalesforceClient, SalesforceAPIError
from ..api.bulk import BulkClient, BulkJobResult
from ..queue.task_queue import TaskQueue, Task, TaskStatus, TaskPriority

logger = structlog.get_logger()


@dataclass
class AgentConfig:
    """Configuration for a Salesforce agent"""
    # Authentication
    client_id: str
    client_secret: str
    username: str
    password: str
    security_token: str = ""
    domain: str = "login"

    # Agent settings
    agent_id: Optional[str] = None
    max_workers: int = 4
    poll_interval: float = 1.0
    batch_size: int = 200

    # Queue settings
    queue_backend: str = "sqlite"
    queue_db_path: str = "~/.blackroad/task_queue.db"


class SalesforceAgent:
    """
    Autonomous Salesforce Agent.

    The key innovation: instead of humans clicking buttons ($165/seat/month),
    agents call APIs. One seat, unlimited scale.

    Architecture:
    - Pulls tasks from shared queue
    - Executes Salesforce operations
    - Reports results back
    - Handles errors and retries
    - Runs 24/7 without human intervention
    """

    def __init__(self, config: AgentConfig):
        self.config = config
        self.agent_id = config.agent_id or f"agent-{uuid.uuid4().hex[:8]}"

        # Initialize authentication
        auth_config = AuthConfig(
            client_id=config.client_id,
            client_secret=config.client_secret,
            username=config.username,
            password=config.password,
            security_token=config.security_token,
            domain=config.domain
        )
        self.auth = SalesforceAuth(auth_config)

        # Initialize clients
        self.client = SalesforceClient(self.auth)
        self.bulk = BulkClient(self.auth)

        # Initialize task queue
        self.queue = TaskQueue(
            backend=config.queue_backend,
            db_path=config.queue_db_path
        )

        # Operation handlers
        self._handlers: Dict[str, Callable] = {
            "create": self._handle_create,
            "get": self._handle_get,
            "update": self._handle_update,
            "delete": self._handle_delete,
            "upsert": self._handle_upsert,
            "query": self._handle_query,
            "bulk_insert": self._handle_bulk_insert,
            "bulk_update": self._handle_bulk_update,
            "bulk_delete": self._handle_bulk_delete,
        }

        # State
        self._running = False
        self._executor: Optional[ThreadPoolExecutor] = None

        logger.info("agent_initialized", agent_id=self.agent_id)

    # ==================== Lifecycle ====================

    def start(self):
        """Start the agent"""
        if self._running:
            logger.warning("agent_already_running", agent_id=self.agent_id)
            return

        # Authenticate
        self.auth.authenticate()
        logger.info("agent_authenticated", agent_id=self.agent_id)

        self._running = True
        self._executor = ThreadPoolExecutor(max_workers=self.config.max_workers)

        # Handle shutdown signals
        signal.signal(signal.SIGINT, self._handle_shutdown)
        signal.signal(signal.SIGTERM, self._handle_shutdown)

        logger.info("agent_started", agent_id=self.agent_id, workers=self.config.max_workers)

        # Main processing loop
        self._process_loop()

    def stop(self):
        """Stop the agent gracefully"""
        logger.info("agent_stopping", agent_id=self.agent_id)
        self._running = False

        if self._executor:
            self._executor.shutdown(wait=True)

        logger.info("agent_stopped", agent_id=self.agent_id)

    def _handle_shutdown(self, signum, frame):
        """Handle shutdown signals"""
        logger.info("shutdown_signal_received", signal=signum)
        self.stop()

    # ==================== Task Processing ====================

    def _process_loop(self):
        """Main task processing loop"""
        consecutive_empty = 0

        while self._running:
            try:
                # Get next task
                task = self.queue.get_next(self.agent_id)

                if task:
                    consecutive_empty = 0
                    self._executor.submit(self._process_task, task)
                else:
                    consecutive_empty += 1
                    # Adaptive polling: back off when queue is empty
                    sleep_time = min(self.config.poll_interval * (1 + consecutive_empty * 0.1), 10)
                    time.sleep(sleep_time)

            except Exception as e:
                logger.error("process_loop_error", error=str(e), agent_id=self.agent_id)
                time.sleep(5)  # Back off on error

    def _process_task(self, task: Task):
        """Process a single task"""
        logger.info("task_processing", task_id=task.id, operation=task.operation, sobject=task.sobject)

        try:
            handler = self._handlers.get(task.operation)

            if not handler:
                raise ValueError(f"Unknown operation: {task.operation}")

            result = handler(task)

            self.queue.complete(task.id, result)
            logger.info("task_completed", task_id=task.id, operation=task.operation)

        except SalesforceAPIError as e:
            logger.error("task_api_error", task_id=task.id, error=str(e), status_code=e.status_code)
            self.queue.fail(task.id, str(e))

        except Exception as e:
            logger.error("task_error", task_id=task.id, error=str(e))
            self.queue.fail(task.id, str(e))

    # ==================== Operation Handlers ====================

    def _handle_create(self, task: Task) -> Dict[str, Any]:
        """Handle create operation"""
        record_id = self.client.create(task.sobject, task.data)
        return {"id": record_id, "success": True}

    def _handle_get(self, task: Task) -> Dict[str, Any]:
        """Handle get operation"""
        record_id = task.data.get("id")
        fields = task.data.get("fields")
        record = self.client.get(task.sobject, record_id, fields)
        return {"record": record, "success": True}

    def _handle_update(self, task: Task) -> Dict[str, Any]:
        """Handle update operation"""
        record_id = task.data.pop("id")
        self.client.update(task.sobject, record_id, task.data)
        return {"id": record_id, "success": True}

    def _handle_delete(self, task: Task) -> Dict[str, Any]:
        """Handle delete operation"""
        record_id = task.data.get("id")
        self.client.delete(task.sobject, record_id)
        return {"id": record_id, "success": True}

    def _handle_upsert(self, task: Task) -> Dict[str, Any]:
        """Handle upsert operation"""
        external_id_field = task.data.pop("external_id_field")
        external_id = task.data.pop("external_id")
        record_id = self.client.upsert(task.sobject, external_id_field, external_id, task.data)
        return {"id": record_id, "success": True}

    def _handle_query(self, task: Task) -> Dict[str, Any]:
        """Handle query operation"""
        soql = task.data.get("soql")
        all_records = task.data.get("all", False)

        if all_records:
            records = self.client.query_all(soql)
        else:
            result = self.client.query(soql)
            records = result.records

        return {"records": records, "count": len(records), "success": True}

    def _handle_bulk_insert(self, task: Task) -> Dict[str, Any]:
        """Handle bulk insert operation"""
        records = task.data.get("records", [])
        result = self.bulk.insert(task.sobject, records)
        return self._bulk_result_to_dict(result)

    def _handle_bulk_update(self, task: Task) -> Dict[str, Any]:
        """Handle bulk update operation"""
        records = task.data.get("records", [])
        result = self.bulk.update(task.sobject, records)
        return self._bulk_result_to_dict(result)

    def _handle_bulk_delete(self, task: Task) -> Dict[str, Any]:
        """Handle bulk delete operation"""
        record_ids = task.data.get("ids", [])
        result = self.bulk.delete(task.sobject, record_ids)
        return self._bulk_result_to_dict(result)

    def _bulk_result_to_dict(self, result: BulkJobResult) -> Dict[str, Any]:
        """Convert bulk result to dictionary"""
        return {
            "job_id": result.job_id,
            "state": result.state.value,
            "records_processed": result.records_processed,
            "records_failed": result.records_failed,
            "processing_time_ms": result.processing_time_ms,
            "success": result.records_failed == 0
        }

    # ==================== Direct API Access ====================

    def create(self, sobject: str, data: Dict[str, Any]) -> str:
        """Create a record directly (bypass queue)"""
        return self.client.create(sobject, data)

    def get(self, sobject: str, record_id: str, fields: List[str] = None) -> Dict[str, Any]:
        """Get a record directly"""
        return self.client.get(sobject, record_id, fields)

    def update(self, sobject: str, record_id: str, data: Dict[str, Any]) -> bool:
        """Update a record directly"""
        return self.client.update(sobject, record_id, data)

    def delete(self, sobject: str, record_id: str) -> bool:
        """Delete a record directly"""
        return self.client.delete(sobject, record_id)

    def query(self, soql: str) -> List[Dict[str, Any]]:
        """Execute a query directly"""
        return self.client.query_all(soql)

    # ==================== Queue Operations ====================

    def submit_task(
        self,
        operation: str,
        sobject: str,
        data: Dict[str, Any],
        priority: TaskPriority = TaskPriority.NORMAL
    ) -> str:
        """Submit a task to the queue"""
        return self.queue.submit(operation, sobject, data, priority)

    def submit_batch(
        self,
        operation: str,
        sobject: str,
        data_list: List[Dict[str, Any]],
        priority: TaskPriority = TaskPriority.NORMAL
    ) -> List[str]:
        """Submit multiple tasks to the queue"""
        return self.queue.submit_batch(operation, sobject, data_list, priority)

    def get_stats(self) -> Dict[str, Any]:
        """Get agent and queue statistics"""
        queue_stats = self.queue.stats()

        try:
            limits = self.client.get_limits()
            api_usage = {
                "daily_api_requests": limits.get("DailyApiRequests", {}),
                "bulk_api_requests": limits.get("DailyBulkApiRequests", {}),
            }
        except:
            api_usage = {}

        return {
            "agent_id": self.agent_id,
            "running": self._running,
            "queue": queue_stats,
            "api_usage": api_usage
        }
