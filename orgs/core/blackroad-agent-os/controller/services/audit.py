"""
Audit Service - Immutable logging of all actions for compliance
"""
import json
from datetime import datetime
from pathlib import Path
from typing import Optional, Any
from enum import Enum
from pydantic import BaseModel, Field
import structlog

logger = structlog.get_logger()


class AuditEventType(str, Enum):
    # Task lifecycle
    TASK_CREATED = "task.created"
    TASK_PLANNED = "task.planned"
    TASK_APPROVED = "task.approved"
    TASK_REJECTED = "task.rejected"
    TASK_STARTED = "task.started"
    TASK_COMPLETED = "task.completed"
    TASK_FAILED = "task.failed"
    TASK_CANCELLED = "task.cancelled"

    # Command execution
    COMMAND_STARTED = "command.started"
    COMMAND_COMPLETED = "command.completed"
    COMMAND_BLOCKED = "command.blocked"

    # Agent events
    AGENT_CONNECTED = "agent.connected"
    AGENT_DISCONNECTED = "agent.disconnected"
    AGENT_HEARTBEAT = "agent.heartbeat"

    # Security events
    SECURITY_BLOCKED = "security.blocked"
    SECURITY_APPROVAL_REQUIRED = "security.approval_required"

    # System events
    SYSTEM_STARTED = "system.started"
    SYSTEM_STOPPED = "system.stopped"


class AuditEvent(BaseModel):
    """An immutable audit log entry"""
    id: str = Field(default_factory=lambda: datetime.utcnow().strftime("%Y%m%d%H%M%S%f"))
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    event_type: AuditEventType

    # Actor information
    actor_type: str = "system"  # user, agent, system, llm
    actor_id: Optional[str] = None

    # Target information
    target_type: Optional[str] = None  # task, agent, command
    target_id: Optional[str] = None

    # Event details
    action: str
    details: dict[str, Any] = Field(default_factory=dict)

    # Security context
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None

    # Result
    success: bool = True
    error: Optional[str] = None


class AuditService:
    """
    Immutable audit logging service.
    Writes append-only logs for compliance and debugging.
    """

    def __init__(self, log_dir: Optional[Path] = None):
        self.log_dir = log_dir or Path("./logs/audit")
        self.log_dir.mkdir(parents=True, exist_ok=True)
        self._current_file: Optional[Path] = None
        self._file_date: Optional[str] = None

    def _get_log_file(self) -> Path:
        """Get or create today's log file"""
        today = datetime.utcnow().strftime("%Y-%m-%d")
        if self._file_date != today:
            self._file_date = today
            self._current_file = self.log_dir / f"audit-{today}.jsonl"
        return self._current_file

    def log(self, event: AuditEvent):
        """Write an audit event (append-only)"""
        log_file = self._get_log_file()

        # Serialize to JSON line
        event_json = event.model_dump_json()

        # Append to file
        with open(log_file, "a") as f:
            f.write(event_json + "\n")

        # Also log to structured logger
        logger.info(
            "audit_event",
            event_type=event.event_type.value,
            actor=f"{event.actor_type}:{event.actor_id or 'unknown'}",
            target=f"{event.target_type or 'none'}:{event.target_id or 'none'}",
            action=event.action,
            success=event.success,
        )

    def log_task_created(self, task_id: str, request: str, user_id: str = "user"):
        """Log task creation"""
        self.log(AuditEvent(
            event_type=AuditEventType.TASK_CREATED,
            actor_type="user",
            actor_id=user_id,
            target_type="task",
            target_id=task_id,
            action="create_task",
            details={"request": request[:500]},  # Truncate long requests
        ))

    def log_task_planned(self, task_id: str, plan_summary: dict):
        """Log LLM planning completion"""
        self.log(AuditEvent(
            event_type=AuditEventType.TASK_PLANNED,
            actor_type="llm",
            target_type="task",
            target_id=task_id,
            action="plan_task",
            details=plan_summary,
        ))

    def log_task_approved(self, task_id: str, user_id: str = "user"):
        """Log task approval"""
        self.log(AuditEvent(
            event_type=AuditEventType.TASK_APPROVED,
            actor_type="user",
            actor_id=user_id,
            target_type="task",
            target_id=task_id,
            action="approve_task",
        ))

    def log_task_rejected(self, task_id: str, reason: str, user_id: str = "user"):
        """Log task rejection"""
        self.log(AuditEvent(
            event_type=AuditEventType.TASK_REJECTED,
            actor_type="user",
            actor_id=user_id,
            target_type="task",
            target_id=task_id,
            action="reject_task",
            details={"reason": reason},
            success=False,
        ))

    def log_command_started(self, task_id: str, agent_id: str, command: str, command_idx: int):
        """Log command execution start"""
        self.log(AuditEvent(
            event_type=AuditEventType.COMMAND_STARTED,
            actor_type="agent",
            actor_id=agent_id,
            target_type="task",
            target_id=task_id,
            action="start_command",
            details={"command": command[:500], "index": command_idx},
        ))

    def log_command_completed(
        self,
        task_id: str,
        agent_id: str,
        command: str,
        command_idx: int,
        exit_code: int,
        duration_ms: float,
    ):
        """Log command execution completion"""
        self.log(AuditEvent(
            event_type=AuditEventType.COMMAND_COMPLETED,
            actor_type="agent",
            actor_id=agent_id,
            target_type="task",
            target_id=task_id,
            action="complete_command",
            details={
                "command": command[:500],
                "index": command_idx,
                "exit_code": exit_code,
                "duration_ms": duration_ms,
            },
            success=exit_code == 0,
        ))

    def log_command_blocked(self, task_id: str, command: str, reason: str):
        """Log blocked command"""
        self.log(AuditEvent(
            event_type=AuditEventType.COMMAND_BLOCKED,
            actor_type="system",
            target_type="task",
            target_id=task_id,
            action="block_command",
            details={"command": command[:500], "reason": reason},
            success=False,
            error=reason,
        ))

    def log_agent_connected(self, agent_id: str, hostname: str, ip_address: Optional[str] = None):
        """Log agent connection"""
        self.log(AuditEvent(
            event_type=AuditEventType.AGENT_CONNECTED,
            actor_type="agent",
            actor_id=agent_id,
            target_type="agent",
            target_id=agent_id,
            action="connect",
            details={"hostname": hostname},
            ip_address=ip_address,
        ))

    def log_agent_disconnected(self, agent_id: str, reason: str = "normal"):
        """Log agent disconnection"""
        self.log(AuditEvent(
            event_type=AuditEventType.AGENT_DISCONNECTED,
            actor_type="agent",
            actor_id=agent_id,
            target_type="agent",
            target_id=agent_id,
            action="disconnect",
            details={"reason": reason},
        ))

    def get_events(
        self,
        start_date: Optional[datetime] = None,
        end_date: Optional[datetime] = None,
        event_type: Optional[AuditEventType] = None,
        target_id: Optional[str] = None,
        limit: int = 100,
    ) -> list[AuditEvent]:
        """Query audit events"""
        events = []

        # Determine which files to read
        files = sorted(self.log_dir.glob("audit-*.jsonl"), reverse=True)

        for log_file in files:
            # Extract date from filename
            file_date = log_file.stem.replace("audit-", "")

            if start_date:
                if file_date < start_date.strftime("%Y-%m-%d"):
                    continue
            if end_date:
                if file_date > end_date.strftime("%Y-%m-%d"):
                    continue

            # Read and filter events
            with open(log_file) as f:
                for line in f:
                    if len(events) >= limit:
                        break

                    try:
                        event = AuditEvent.model_validate_json(line)

                        # Apply filters
                        if event_type and event.event_type != event_type:
                            continue
                        if target_id and event.target_id != target_id:
                            continue
                        if start_date and event.timestamp < start_date:
                            continue
                        if end_date and event.timestamp > end_date:
                            continue

                        events.append(event)
                    except Exception as e:
                        logger.warning("audit_parse_error", file=str(log_file), error=str(e))

            if len(events) >= limit:
                break

        return events


# Global audit instance
audit = AuditService()
