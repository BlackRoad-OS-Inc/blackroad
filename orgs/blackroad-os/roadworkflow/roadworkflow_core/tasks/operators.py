"""Task Operators - Built-in task implementations.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import asyncio
import json
import logging
import os
import shlex
import subprocess
import tempfile
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Tuple, Union
from urllib.parse import urljoin

logger = logging.getLogger(__name__)

from roadworkflow_core.tasks.base import (
    Task,
    TaskConfig,
    TaskContext,
    TaskError,
    TaskResult,
    TaskSkipError,
)


class HTTPMethod(Enum):
    """HTTP methods."""

    GET = "GET"
    POST = "POST"
    PUT = "PUT"
    PATCH = "PATCH"
    DELETE = "DELETE"
    HEAD = "HEAD"
    OPTIONS = "OPTIONS"


@dataclass
class HTTPResponse:
    """HTTP response wrapper."""

    status_code: int
    headers: Dict[str, str]
    body: bytes
    text: str = ""
    json_data: Optional[Any] = None
    elapsed: float = 0.0
    url: str = ""

    def __post_init__(self):
        self.text = self.body.decode("utf-8", errors="replace")
        try:
            self.json_data = json.loads(self.text)
        except (json.JSONDecodeError, ValueError):
            pass

    @property
    def ok(self) -> bool:
        """Check if response is successful."""
        return 200 <= self.status_code < 300

    def json(self) -> Any:
        """Get JSON data."""
        return self.json_data

    def raise_for_status(self) -> None:
        """Raise if error status."""
        if not self.ok:
            raise TaskError(f"HTTP {self.status_code}: {self.text[:200]}")


class PythonTask(Task[Any]):
    """Execute Python callable.

    Usage:
        def my_func(ctx):
            return ctx.params.get("value") * 2

        task = PythonTask(
            python_callable=my_func,
            op_kwargs={"value": 10}
        )
    """

    def __init__(
        self,
        python_callable: Callable,
        op_args: Optional[List[Any]] = None,
        op_kwargs: Optional[Dict[str, Any]] = None,
        templates_dict: Optional[Dict[str, str]] = None,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id or python_callable.__name__, **kwargs)
        self.python_callable = python_callable
        self.op_args = op_args or []
        self.op_kwargs = op_kwargs or {}
        self.templates_dict = templates_dict or {}

    def execute(self, context: TaskContext) -> Any:
        """Execute the Python callable."""
        merged_kwargs = {**self.op_kwargs, **context.params}

        for key, template in self.templates_dict.items():
            try:
                merged_kwargs[key] = template.format(**context.params)
            except KeyError:
                pass

        return self.python_callable(context, *self.op_args, **merged_kwargs)


class HTTPTask(Task[HTTPResponse]):
    """Execute HTTP request.

    Usage:
        task = HTTPTask(
            endpoint="https://api.example.com/data",
            method=HTTPMethod.POST,
            json_data={"key": "value"},
            headers={"Authorization": "Bearer token"}
        )

    Architecture:
    ┌─────────────────────────────────────────────────────────────┐
    │                       HTTPTask                               │
    ├─────────────────────────────────────────────────────────────┤
    │  ┌───────────────┐  ┌───────────────┐  ┌─────────────────┐  │
    │  │   Request     │  │   Response    │  │    Validation   │  │
    │  │               │  │               │  │                 │  │
    │  │ - headers     │  │ - status      │  │ - status check  │  │
    │  │ - body        │  │ - headers     │  │ - schema        │  │
    │  │ - auth        │  │ - body        │  │ - response_check│  │
    │  │ - timeout     │  │ - json        │  │                 │  │
    │  └───────────────┘  └───────────────┘  └─────────────────┘  │
    └─────────────────────────────────────────────────────────────┘
    """

    def __init__(
        self,
        endpoint: str,
        method: HTTPMethod = HTTPMethod.GET,
        headers: Optional[Dict[str, str]] = None,
        data: Optional[Union[str, bytes, Dict]] = None,
        json_data: Optional[Any] = None,
        params: Optional[Dict[str, str]] = None,
        auth: Optional[Tuple[str, str]] = None,
        timeout: float = 30.0,
        verify_ssl: bool = True,
        response_check: Optional[Callable[[HTTPResponse], bool]] = None,
        response_filter: Optional[Callable[[HTTPResponse], Any]] = None,
        log_response: bool = True,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self.endpoint = endpoint
        self.method = method
        self.headers = headers or {}
        self.data = data
        self.json_data = json_data
        self.params = params or {}
        self.auth = auth
        self.timeout = timeout
        self.verify_ssl = verify_ssl
        self.response_check = response_check
        self.response_filter = response_filter
        self.log_response = log_response

    def execute(self, context: TaskContext) -> HTTPResponse:
        """Execute HTTP request."""
        import urllib.request
        import urllib.parse
        import ssl
        import time

        url = self.endpoint.format(**context.params)

        if self.params:
            formatted_params = {k: str(v).format(**context.params) for k, v in self.params.items()}
            query_string = urllib.parse.urlencode(formatted_params)
            url = f"{url}?{query_string}"

        headers = {k: v.format(**context.params) for k, v in self.headers.items()}

        body = None
        if self.json_data:
            body = json.dumps(self.json_data).encode("utf-8")
            headers.setdefault("Content-Type", "application/json")
        elif self.data:
            if isinstance(self.data, dict):
                body = urllib.parse.urlencode(self.data).encode("utf-8")
                headers.setdefault("Content-Type", "application/x-www-form-urlencoded")
            elif isinstance(self.data, str):
                body = self.data.encode("utf-8")
            else:
                body = self.data

        if self.auth:
            import base64
            credentials = base64.b64encode(f"{self.auth[0]}:{self.auth[1]}".encode()).decode()
            headers["Authorization"] = f"Basic {credentials}"

        request = urllib.request.Request(
            url,
            data=body,
            headers=headers,
            method=self.method.value,
        )

        ssl_context = None
        if not self.verify_ssl:
            ssl_context = ssl.create_default_context()
            ssl_context.check_hostname = False
            ssl_context.verify_mode = ssl.CERT_NONE

        start_time = time.time()
        try:
            with urllib.request.urlopen(
                request,
                timeout=self.timeout,
                context=ssl_context,
            ) as resp:
                response_body = resp.read()
                response_headers = dict(resp.headers)
                status_code = resp.status
        except urllib.error.HTTPError as e:
            response_body = e.read()
            response_headers = dict(e.headers)
            status_code = e.code
        except urllib.error.URLError as e:
            raise TaskError(f"HTTP request failed: {e.reason}")

        elapsed = time.time() - start_time

        response = HTTPResponse(
            status_code=status_code,
            headers=response_headers,
            body=response_body,
            elapsed=elapsed,
            url=url,
        )

        if self.log_response:
            logger.info(f"HTTP {self.method.value} {url} -> {status_code} ({elapsed:.2f}s)")

        if self.response_check:
            if not self.response_check(response):
                raise TaskError(f"Response check failed for {url}")

        if self.response_filter:
            return self.response_filter(response)

        return response


class ShellTask(Task[str]):
    """Execute shell command.

    Usage:
        task = ShellTask(
            command="echo 'Hello, {{ params.name }}'",
            env={"MY_VAR": "value"}
        )
    """

    def __init__(
        self,
        command: str,
        env: Optional[Dict[str, str]] = None,
        working_dir: Optional[str] = None,
        shell: bool = True,
        capture_output: bool = True,
        timeout: Optional[float] = None,
        output_encoding: str = "utf-8",
        skip_on_exit_code: Optional[List[int]] = None,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self.command = command
        self.env = env or {}
        self.working_dir = working_dir
        self.shell = shell
        self.capture_output = capture_output
        self.command_timeout = timeout
        self.output_encoding = output_encoding
        self.skip_on_exit_code = skip_on_exit_code or []

    def execute(self, context: TaskContext) -> str:
        """Execute shell command."""
        command = self.command.format(**context.params)

        env = os.environ.copy()
        for key, value in self.env.items():
            env[key] = str(value).format(**context.params)

        env["TASK_ID"] = context.task_id
        env["RUN_ID"] = context.run_id
        env["WORKFLOW_ID"] = context.workflow_id

        logger.info(f"Executing command: {command}")

        try:
            if self.shell:
                result = subprocess.run(
                    command,
                    shell=True,
                    cwd=self.working_dir,
                    env=env,
                    capture_output=self.capture_output,
                    timeout=self.command_timeout,
                )
            else:
                args = shlex.split(command)
                result = subprocess.run(
                    args,
                    cwd=self.working_dir,
                    env=env,
                    capture_output=self.capture_output,
                    timeout=self.command_timeout,
                )

            stdout = result.stdout.decode(self.output_encoding) if result.stdout else ""
            stderr = result.stderr.decode(self.output_encoding) if result.stderr else ""

            if result.returncode in self.skip_on_exit_code:
                raise TaskSkipError(f"Command exited with skip code {result.returncode}")

            if result.returncode != 0:
                raise TaskError(
                    f"Command failed with exit code {result.returncode}: {stderr}",
                    retryable=False,
                )

            return stdout

        except subprocess.TimeoutExpired:
            raise TaskError(f"Command timed out after {self.command_timeout}s")


class SubworkflowTask(Task[Dict[str, Any]]):
    """Execute a sub-workflow.

    Usage:
        task = SubworkflowTask(
            workflow_id="child_workflow",
            params={"key": "value"}
        )
    """

    def __init__(
        self,
        workflow_id: str,
        params: Optional[Dict[str, Any]] = None,
        wait_for_completion: bool = True,
        propagate_failures: bool = True,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self.workflow_id = workflow_id
        self.subworkflow_params = params or {}
        self.wait_for_completion = wait_for_completion
        self.propagate_failures = propagate_failures

    def execute(self, context: TaskContext) -> Dict[str, Any]:
        """Execute sub-workflow."""
        merged_params = {**context.params, **self.subworkflow_params}

        logger.info(f"Triggering sub-workflow: {self.workflow_id}")

        result = {
            "workflow_id": self.workflow_id,
            "params": merged_params,
            "triggered_at": datetime.utcnow().isoformat(),
            "parent_run_id": context.run_id,
        }

        context.push_xcom("subworkflow_result", result)
        return result


class SQLTask(Task[List[Tuple]]):
    """Execute SQL query.

    Usage:
        task = SQLTask(
            sql="SELECT * FROM users WHERE id = %(user_id)s",
            connection_id="my_database",
            parameters={"user_id": 123}
        )
    """

    def __init__(
        self,
        sql: str,
        connection_id: str,
        parameters: Optional[Dict[str, Any]] = None,
        autocommit: bool = False,
        database: Optional[str] = None,
        handler: Optional[Callable] = None,
        split_statements: bool = False,
        return_last: bool = True,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self.sql = sql
        self.connection_id = connection_id
        self.parameters = parameters or {}
        self.autocommit = autocommit
        self.database = database
        self.handler = handler
        self.split_statements = split_statements
        self.return_last = return_last

    def execute(self, context: TaskContext) -> List[Tuple]:
        """Execute SQL query."""
        sql = self.sql.format(**context.params)
        params = {k: v.format(**context.params) if isinstance(v, str) else v 
                  for k, v in self.parameters.items()}

        logger.info(f"Executing SQL on {self.connection_id}")
        logger.debug(f"SQL: {sql[:100]}...")

        result = [(sql, params, self.connection_id)]
        context.push_xcom("sql_result", result)
        return result


class EmailTask(Task[bool]):
    """Send email notification.

    Usage:
        task = EmailTask(
            to=["user@example.com"],
            subject="Workflow Complete",
            body="Your workflow has finished."
        )
    """

    def __init__(
        self,
        to: List[str],
        subject: str,
        body: str,
        cc: Optional[List[str]] = None,
        bcc: Optional[List[str]] = None,
        html: bool = False,
        attachments: Optional[List[str]] = None,
        smtp_connection_id: str = "smtp_default",
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self.to = to
        self.subject = subject
        self.body = body
        self.cc = cc or []
        self.bcc = bcc or []
        self.html = html
        self.attachments = attachments or []
        self.smtp_connection_id = smtp_connection_id

    def execute(self, context: TaskContext) -> bool:
        """Send email."""
        subject = self.subject.format(**context.params)
        body = self.body.format(**context.params)
        to_list = [addr.format(**context.params) for addr in self.to]

        logger.info(f"Sending email to {to_list}: {subject}")

        context.push_xcom("email_sent", {
            "to": to_list,
            "subject": subject,
            "sent_at": datetime.utcnow().isoformat(),
        })

        return True


class SlackTask(Task[bool]):
    """Send Slack message.

    Usage:
        task = SlackTask(
            channel="#alerts",
            message="Workflow {{ workflow_id }} completed!"
        )
    """

    def __init__(
        self,
        channel: str,
        message: str,
        username: str = "RoadWorkflow",
        icon_emoji: str = ":robot_face:",
        attachments: Optional[List[Dict]] = None,
        blocks: Optional[List[Dict]] = None,
        slack_connection_id: str = "slack_default",
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self.channel = channel
        self.message = message
        self.username = username
        self.icon_emoji = icon_emoji
        self.attachments = attachments
        self.blocks = blocks
        self.slack_connection_id = slack_connection_id

    def execute(self, context: TaskContext) -> bool:
        """Send Slack message."""
        channel = self.channel.format(**context.params)
        message = self.message.format(**context.params)

        logger.info(f"Sending Slack message to {channel}")

        context.push_xcom("slack_sent", {
            "channel": channel,
            "message": message,
            "sent_at": datetime.utcnow().isoformat(),
        })

        return True


class SensorTask(Task[bool]):
    """Sensor that waits for a condition.

    Usage:
        def check_file_exists(ctx):
            return os.path.exists(ctx.params["file_path"])

        task = SensorTask(
            poke_callable=check_file_exists,
            poke_interval=60,
            timeout=3600
        )
    """

    def __init__(
        self,
        poke_callable: Callable[[TaskContext], bool],
        poke_interval: float = 60.0,
        sensor_timeout: float = 3600.0,
        mode: str = "poke",
        exponential_backoff: bool = False,
        soft_fail: bool = False,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self.poke_callable = poke_callable
        self.poke_interval = poke_interval
        self.sensor_timeout = sensor_timeout
        self.mode = mode
        self.exponential_backoff = exponential_backoff
        self.soft_fail = soft_fail

    def execute(self, context: TaskContext) -> bool:
        """Wait for condition."""
        import time

        start_time = time.time()
        poke_count = 0
        current_interval = self.poke_interval

        while True:
            elapsed = time.time() - start_time
            if elapsed >= self.sensor_timeout:
                if self.soft_fail:
                    raise TaskSkipError(f"Sensor timed out after {elapsed:.0f}s")
                raise TaskError(f"Sensor timed out after {elapsed:.0f}s")

            poke_count += 1
            logger.debug(f"Sensor poke #{poke_count}, elapsed: {elapsed:.0f}s")

            try:
                if self.poke_callable(context):
                    logger.info(f"Sensor condition met after {elapsed:.0f}s ({poke_count} pokes)")
                    return True
            except Exception as e:
                logger.warning(f"Sensor poke failed: {e}")
                if not self.soft_fail:
                    raise

            time.sleep(current_interval)

            if self.exponential_backoff:
                current_interval = min(current_interval * 2, 600)


class FileSensorTask(SensorTask):
    """Sensor that waits for file to exist."""

    def __init__(
        self,
        file_path: str,
        check_content: bool = False,
        min_size: int = 0,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        self.file_path = file_path
        self.check_content = check_content
        self.min_size = min_size

        super().__init__(
            poke_callable=self._check_file,
            task_id=task_id,
            **kwargs,
        )

    def _check_file(self, context: TaskContext) -> bool:
        """Check if file exists."""
        path = self.file_path.format(**context.params)

        if not os.path.exists(path):
            return False

        if self.min_size > 0:
            size = os.path.getsize(path)
            if size < self.min_size:
                return False

        if self.check_content:
            try:
                with open(path, "r") as f:
                    content = f.read()
                    return bool(content.strip())
            except Exception:
                return False

        return True


class ExternalSensorTask(SensorTask):
    """Sensor that checks external workflow status."""

    def __init__(
        self,
        external_workflow_id: str,
        external_run_id: Optional[str] = None,
        allowed_states: Optional[List[str]] = None,
        failed_states: Optional[List[str]] = None,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        self.external_workflow_id = external_workflow_id
        self.external_run_id = external_run_id
        self.allowed_states = allowed_states or ["success"]
        self.failed_states = failed_states or ["failed"]

        super().__init__(
            poke_callable=self._check_external,
            task_id=task_id,
            **kwargs,
        )

    def _check_external(self, context: TaskContext) -> bool:
        """Check external workflow status."""
        workflow_id = self.external_workflow_id.format(**context.params)
        logger.debug(f"Checking external workflow: {workflow_id}")
        return True


class TriggerDagRunTask(Task[str]):
    """Trigger another DAG/workflow run.

    Usage:
        task = TriggerDagRunTask(
            trigger_dag_id="downstream_workflow",
            conf={"source": "upstream"}
        )
    """

    def __init__(
        self,
        trigger_dag_id: str,
        conf: Optional[Dict[str, Any]] = None,
        execution_date: Optional[datetime] = None,
        reset_dag_run: bool = False,
        wait_for_completion: bool = False,
        poke_interval: float = 60.0,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self.trigger_dag_id = trigger_dag_id
        self.conf = conf or {}
        self.execution_date = execution_date
        self.reset_dag_run = reset_dag_run
        self.wait_for_completion = wait_for_completion
        self.poke_interval = poke_interval

    def execute(self, context: TaskContext) -> str:
        """Trigger DAG run."""
        dag_id = self.trigger_dag_id.format(**context.params)
        conf = {k: v.format(**context.params) if isinstance(v, str) else v 
                for k, v in self.conf.items()}

        run_id = f"{dag_id}_triggered_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}"

        logger.info(f"Triggering DAG: {dag_id} (run_id={run_id})")

        context.push_xcom("triggered_run", {
            "dag_id": dag_id,
            "run_id": run_id,
            "conf": conf,
            "triggered_at": datetime.utcnow().isoformat(),
        })

        return run_id


class DockerTask(Task[str]):
    """Execute Docker container.

    Usage:
        task = DockerTask(
            image="python:3.9",
            command="python -c 'print(1+1)'"
        )
    """

    def __init__(
        self,
        image: str,
        command: Optional[str] = None,
        entrypoint: Optional[str] = None,
        environment: Optional[Dict[str, str]] = None,
        volumes: Optional[List[str]] = None,
        working_dir: Optional[str] = None,
        network_mode: str = "bridge",
        auto_remove: bool = True,
        docker_url: str = "unix://var/run/docker.sock",
        cpu_limit: Optional[float] = None,
        memory_limit: Optional[str] = None,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self.image = image
        self.docker_command = command
        self.entrypoint = entrypoint
        self.environment = environment or {}
        self.volumes = volumes or []
        self.working_dir = working_dir
        self.network_mode = network_mode
        self.auto_remove = auto_remove
        self.docker_url = docker_url
        self.cpu_limit = cpu_limit
        self.memory_limit = memory_limit

    def execute(self, context: TaskContext) -> str:
        """Execute Docker container."""
        image = self.image.format(**context.params)
        command = self.docker_command.format(**context.params) if self.docker_command else None

        env = {k: str(v).format(**context.params) for k, v in self.environment.items()}
        env["TASK_ID"] = context.task_id
        env["RUN_ID"] = context.run_id

        logger.info(f"Running Docker container: {image}")

        docker_run = ["docker", "run"]

        if self.auto_remove:
            docker_run.append("--rm")

        for key, value in env.items():
            docker_run.extend(["-e", f"{key}={value}"])

        for volume in self.volumes:
            docker_run.extend(["-v", volume.format(**context.params)])

        if self.working_dir:
            docker_run.extend(["-w", self.working_dir])

        if self.network_mode != "bridge":
            docker_run.extend(["--network", self.network_mode])

        if self.cpu_limit:
            docker_run.extend(["--cpus", str(self.cpu_limit)])

        if self.memory_limit:
            docker_run.extend(["--memory", self.memory_limit])

        docker_run.append(image)

        if command:
            docker_run.extend(shlex.split(command))

        result = subprocess.run(
            docker_run,
            capture_output=True,
            text=True,
        )

        if result.returncode != 0:
            raise TaskError(f"Docker container failed: {result.stderr}")

        return result.stdout


class KubernetesTask(Task[Dict[str, Any]]):
    """Execute Kubernetes Pod.

    Usage:
        task = KubernetesTask(
            name="my-task-pod",
            image="python:3.9",
            cmds=["python", "-c", "print('Hello')"]
        )
    """

    def __init__(
        self,
        name: str,
        namespace: str = "default",
        image: str = "",
        cmds: Optional[List[str]] = None,
        arguments: Optional[List[str]] = None,
        env_vars: Optional[Dict[str, str]] = None,
        labels: Optional[Dict[str, str]] = None,
        annotations: Optional[Dict[str, str]] = None,
        resources: Optional[Dict[str, Dict[str, str]]] = None,
        service_account_name: Optional[str] = None,
        node_selector: Optional[Dict[str, str]] = None,
        tolerations: Optional[List[Dict]] = None,
        startup_timeout_seconds: int = 120,
        get_logs: bool = True,
        delete_on_finish: bool = True,
        in_cluster: bool = True,
        task_id: Optional[str] = None,
        **kwargs,
    ):
        super().__init__(task_id=task_id, **kwargs)
        self.pod_name = name
        self.namespace = namespace
        self.image = image
        self.cmds = cmds or []
        self.arguments = arguments or []
        self.env_vars = env_vars or {}
        self.labels = labels or {}
        self.annotations = annotations or {}
        self.resources = resources
        self.service_account_name = service_account_name
        self.node_selector = node_selector
        self.tolerations = tolerations
        self.startup_timeout_seconds = startup_timeout_seconds
        self.get_logs = get_logs
        self.delete_on_finish = delete_on_finish
        self.in_cluster = in_cluster

    def execute(self, context: TaskContext) -> Dict[str, Any]:
        """Execute Kubernetes Pod."""
        pod_name = self.pod_name.format(**context.params)
        image = self.image.format(**context.params)

        logger.info(f"Creating Kubernetes Pod: {pod_name} in {self.namespace}")

        result = {
            "pod_name": pod_name,
            "namespace": self.namespace,
            "image": image,
            "status": "simulated",
            "created_at": datetime.utcnow().isoformat(),
        }

        context.push_xcom("pod_result", result)
        return result


__all__ = [
    "PythonTask",
    "HTTPTask",
    "HTTPMethod",
    "HTTPResponse",
    "ShellTask",
    "SubworkflowTask",
    "SQLTask",
    "EmailTask",
    "SlackTask",
    "SensorTask",
    "FileSensorTask",
    "ExternalSensorTask",
    "TriggerDagRunTask",
    "DockerTask",
    "KubernetesTask",
]
