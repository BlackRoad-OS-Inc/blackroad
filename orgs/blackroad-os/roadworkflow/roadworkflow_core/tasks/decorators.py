"""Task Decorators - Function-to-task decorators.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import functools
import inspect
import logging
from datetime import timedelta
from typing import Any, Callable, Dict, List, Optional, Type, TypeVar, Union

from roadworkflow_core.tasks.base import (
    RetryConfig,
    RetryPolicy,
    SyncTask,
    AsyncTask,
    Task,
    TaskConfig,
    TaskContext,
    TaskPriority,
)
from roadworkflow_core.tasks.operators import PythonTask, SensorTask

logger = logging.getLogger(__name__)

F = TypeVar("F", bound=Callable[..., Any])


def task(
    task_id: Optional[str] = None,
    name: Optional[str] = None,
    retries: int = 0,
    retry_delay: float = 60.0,
    retry_policy: RetryPolicy = RetryPolicy.EXPONENTIAL,
    timeout: Optional[float] = None,
    priority: TaskPriority = TaskPriority.NORMAL,
    pool: Optional[str] = None,
    queue: Optional[str] = None,
    tags: Optional[List[str]] = None,
    owner: str = "",
    doc: Optional[str] = None,
    doc_md: Optional[str] = None,
    multiple_outputs: bool = False,
    on_failure_callback: Optional[Callable] = None,
    on_success_callback: Optional[Callable] = None,
    on_retry_callback: Optional[Callable] = None,
    trigger_rule: str = "all_success",
    **kwargs,
) -> Callable[[F], Task]:
    """Decorator to convert a function to a Task.

    Usage:
        @task(retries=3, timeout=300)
        def my_task(context):
            return "result"

        # Use in workflow
        workflow.add_task(my_task)

    Args:
        task_id: Unique task identifier
        name: Human-readable task name
        retries: Number of retries on failure
        retry_delay: Base delay between retries (seconds)
        retry_policy: Retry backoff policy
        timeout: Task timeout in seconds
        priority: Task priority level
        pool: Execution pool name
        queue: Execution queue name
        tags: Task tags for filtering
        owner: Task owner/responsible party
        doc: Task documentation
        doc_md: Task documentation in Markdown
        multiple_outputs: Whether task returns multiple outputs
        on_failure_callback: Callback on task failure
        on_success_callback: Callback on task success
        on_retry_callback: Callback on task retry
        trigger_rule: Rule for triggering task

    Returns:
        Task wrapper
    """
    def decorator(func: F) -> Task:
        func_name = task_id or func.__name__
        func_doc = doc or doc_md or func.__doc__ or ""

        retry_config = RetryConfig(
            max_retries=retries,
            policy=retry_policy,
            base_delay=retry_delay,
        )

        config = TaskConfig(
            task_id=func_name,
            name=name or func_name,
            description=func_doc,
            owner=owner,
            tags=tags or [],
            priority=priority,
            timeout=timeout,
            retry_config=retry_config,
            pool=pool,
            queue=queue,
            trigger_rule=trigger_rule,
        )

        if inspect.iscoroutinefunction(func):
            task_instance = AsyncTask(func, task_id=func_name, config=config)
        else:
            task_instance = SyncTask(func, task_id=func_name, config=config)

        if on_failure_callback:
            task_instance.on_failure(on_failure_callback)
        if on_success_callback:
            task_instance.on_success(on_success_callback)
        if on_retry_callback:
            task_instance.on_retry(on_retry_callback)

        task_instance._multiple_outputs = multiple_outputs
        task_instance.__doc__ = func_doc
        task_instance.__name__ = func_name
        task_instance.__wrapped__ = func

        return task_instance

    return decorator


def python_task(
    python_callable: Optional[Callable] = None,
    task_id: Optional[str] = None,
    op_args: Optional[List[Any]] = None,
    op_kwargs: Optional[Dict[str, Any]] = None,
    templates_dict: Optional[Dict[str, str]] = None,
    templates_exts: Optional[List[str]] = None,
    show_return_value_in_logs: bool = True,
    **kwargs,
) -> Union[PythonTask, Callable[[F], PythonTask]]:
    """Decorator to create PythonTask from function.

    Usage:
        @python_task(op_kwargs={"multiplier": 2})
        def multiply(context, value, multiplier):
            return value * multiplier

        # Or without decorator args
        @python_task
        def simple_task(context):
            return "done"

    Args:
        python_callable: The callable to execute
        task_id: Task identifier
        op_args: Positional arguments for callable
        op_kwargs: Keyword arguments for callable
        templates_dict: Template strings to render
        templates_exts: Template file extensions
        show_return_value_in_logs: Log return value

    Returns:
        PythonTask or decorator
    """
    def create_python_task(func: F) -> PythonTask:
        return PythonTask(
            python_callable=func,
            task_id=task_id or func.__name__,
            op_args=op_args,
            op_kwargs=op_kwargs,
            templates_dict=templates_dict,
            **kwargs,
        )

    if python_callable is not None:
        return create_python_task(python_callable)

    return create_python_task


def sensor(
    poke_interval: float = 60.0,
    timeout: float = 3600.0,
    mode: str = "poke",
    exponential_backoff: bool = False,
    soft_fail: bool = False,
    task_id: Optional[str] = None,
    **kwargs,
) -> Callable[[F], SensorTask]:
    """Decorator to create sensor from function.

    Usage:
        @sensor(poke_interval=30, timeout=1800)
        def wait_for_file(context):
            import os
            return os.path.exists(context.params["file_path"])

    Args:
        poke_interval: Seconds between condition checks
        timeout: Maximum wait time in seconds
        mode: Sensor mode (poke or reschedule)
        exponential_backoff: Use exponential backoff
        soft_fail: Skip instead of fail on timeout
        task_id: Task identifier

    Returns:
        SensorTask wrapper
    """
    def decorator(func: F) -> SensorTask:
        return SensorTask(
            poke_callable=func,
            poke_interval=poke_interval,
            sensor_timeout=timeout,
            mode=mode,
            exponential_backoff=exponential_backoff,
            soft_fail=soft_fail,
            task_id=task_id or func.__name__,
            **kwargs,
        )

    return decorator


def branch(
    task_id: Optional[str] = None,
    **kwargs,
) -> Callable[[F], Task]:
    """Decorator to create branching task.

    Usage:
        @branch
        def choose_path(context):
            if context.params.get("urgent"):
                return "fast_path"
            return "slow_path"

    The returned task ID(s) will be the only downstream tasks executed.

    Args:
        task_id: Task identifier

    Returns:
        BranchTask wrapper
    """
    from roadworkflow_core.tasks.base import BranchTask

    def decorator(func: F) -> BranchTask:
        return BranchTask(
            branch_func=func,
            task_id=task_id or func.__name__,
            **kwargs,
        )

    return decorator


def short_circuit(
    task_id: Optional[str] = None,
    ignore_downstream_trigger_rules: bool = True,
    **kwargs,
) -> Callable[[F], Task]:
    """Decorator to create short-circuit task.

    Usage:
        @short_circuit
        def check_condition(context):
            # Return False to skip all downstream tasks
            return context.params.get("should_continue", True)

    Args:
        task_id: Task identifier
        ignore_downstream_trigger_rules: Skip regardless of trigger rules

    Returns:
        ShortCircuitTask wrapper
    """
    def decorator(func: F) -> Task:
        @functools.wraps(func)
        def wrapped(context: TaskContext) -> bool:
            result = func(context)
            if not result:
                from roadworkflow_core.tasks.base import TaskSkipError
                raise TaskSkipError("Short circuit: downstream tasks skipped")
            return result

        return SyncTask(
            func=wrapped,
            task_id=task_id or func.__name__,
            **kwargs,
        )

    return decorator


def task_group(
    group_id: Optional[str] = None,
    prefix_group_id: bool = True,
    tooltip: str = "",
    ui_color: str = "#e8f7ff",
    ui_fgcolor: str = "#000000",
    default_args: Optional[Dict[str, Any]] = None,
) -> Callable[[F], Any]:
    """Decorator to create task group from function.

    Usage:
        @task_group(group_id="data_processing")
        def process_data():
            @task
            def extract():
                ...

            @task
            def transform():
                ...

            extract() >> transform()

    Args:
        group_id: Group identifier
        prefix_group_id: Prefix task IDs with group ID
        tooltip: Tooltip text
        ui_color: Background color in UI
        ui_fgcolor: Foreground color in UI
        default_args: Default arguments for tasks

    Returns:
        TaskGroup containing defined tasks
    """
    from roadworkflow_core.tasks.base import TaskGroup

    def decorator(func: F) -> TaskGroup:
        gid = group_id or func.__name__

        group = TaskGroup(
            group_id=gid,
            prefix_group_id=prefix_group_id,
            tooltip=tooltip or func.__doc__ or "",
            ui_color=ui_color,
            ui_fgcolor=ui_fgcolor,
            default_args=default_args,
        )

        func()

        return group

    return decorator


def virtualenv(
    python_version: Optional[str] = None,
    requirements: Optional[List[str]] = None,
    pip_install_options: Optional[List[str]] = None,
    task_id: Optional[str] = None,
    **kwargs,
) -> Callable[[F], Task]:
    """Decorator to run task in isolated virtualenv.

    Usage:
        @virtualenv(
            python_version="3.9",
            requirements=["pandas", "numpy"]
        )
        def analysis_task(context):
            import pandas as pd
            # Use pandas in isolated environment
            return pd.DataFrame()

    Args:
        python_version: Python version for virtualenv
        requirements: Pip packages to install
        pip_install_options: Additional pip options
        task_id: Task identifier

    Returns:
        Task that runs in virtualenv
    """
    def decorator(func: F) -> Task:
        import tempfile
        import subprocess
        import sys

        @functools.wraps(func)
        def wrapped(context: TaskContext) -> Any:
            with tempfile.TemporaryDirectory() as venv_dir:
                python_cmd = f"python{python_version}" if python_version else sys.executable

                subprocess.run(
                    [python_cmd, "-m", "venv", venv_dir],
                    check=True,
                )

                venv_python = f"{venv_dir}/bin/python"

                if requirements:
                    pip_cmd = [venv_python, "-m", "pip", "install"]
                    if pip_install_options:
                        pip_cmd.extend(pip_install_options)
                    pip_cmd.extend(requirements)
                    subprocess.run(pip_cmd, check=True)

                return func(context)

        return SyncTask(
            func=wrapped,
            task_id=task_id or func.__name__,
            **kwargs,
        )

    return decorator


def docker(
    image: str,
    auto_remove: bool = True,
    environment: Optional[Dict[str, str]] = None,
    volumes: Optional[List[str]] = None,
    network_mode: str = "bridge",
    task_id: Optional[str] = None,
    **kwargs,
) -> Callable[[F], Task]:
    """Decorator to run task in Docker container.

    Usage:
        @docker(image="python:3.9")
        def containerized_task(context):
            return "running in container"

    Args:
        image: Docker image to use
        auto_remove: Remove container after completion
        environment: Environment variables
        volumes: Volume mounts
        network_mode: Docker network mode
        task_id: Task identifier

    Returns:
        Task that runs in Docker
    """
    from roadworkflow_core.tasks.operators import DockerTask

    def decorator(func: F) -> DockerTask:
        import dill
        import base64

        serialized = base64.b64encode(dill.dumps(func)).decode()

        command = f"python -c \"import dill, base64; f = dill.loads(base64.b64decode('{serialized}')); print(f(None))\""

        return DockerTask(
            image=image,
            command=command,
            auto_remove=auto_remove,
            environment=environment,
            volumes=volumes,
            network_mode=network_mode,
            task_id=task_id or func.__name__,
            **kwargs,
        )

    return decorator


def retry(
    max_retries: int = 3,
    delay: float = 1.0,
    backoff: float = 2.0,
    max_delay: float = 300.0,
    retry_on: Optional[List[Type[Exception]]] = None,
) -> Callable[[F], F]:
    """Decorator to add retry behavior to any function.

    Usage:
        @retry(max_retries=5, delay=2.0)
        def flaky_operation():
            # May fail sometimes
            ...

    Args:
        max_retries: Maximum retry attempts
        delay: Initial delay between retries
        backoff: Backoff multiplier
        max_delay: Maximum delay
        retry_on: Exception types to retry on

    Returns:
        Wrapped function with retry behavior
    """
    def decorator(func: F) -> F:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            import time

            last_exception = None
            current_delay = delay

            for attempt in range(max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except Exception as e:
                    last_exception = e

                    if retry_on and not any(isinstance(e, t) for t in retry_on):
                        raise

                    if attempt < max_retries:
                        logger.warning(
                            f"{func.__name__} failed (attempt {attempt + 1}), "
                            f"retrying in {current_delay:.1f}s: {e}"
                        )
                        time.sleep(current_delay)
                        current_delay = min(current_delay * backoff, max_delay)

            raise last_exception

        return wrapper  # type: ignore

    return decorator


def timeout(seconds: float) -> Callable[[F], F]:
    """Decorator to add timeout to function.

    Usage:
        @timeout(30)
        def slow_operation():
            # Will be killed after 30 seconds
            ...

    Args:
        seconds: Timeout in seconds

    Returns:
        Wrapped function with timeout
    """
    def decorator(func: F) -> F:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            import concurrent.futures

            with concurrent.futures.ThreadPoolExecutor(max_workers=1) as executor:
                future = executor.submit(func, *args, **kwargs)
                try:
                    return future.result(timeout=seconds)
                except concurrent.futures.TimeoutError:
                    raise TimeoutError(f"{func.__name__} timed out after {seconds}s")

        return wrapper  # type: ignore

    return decorator


def log_execution(
    level: int = logging.INFO,
    include_args: bool = False,
    include_result: bool = False,
) -> Callable[[F], F]:
    """Decorator to log function execution.

    Usage:
        @log_execution(include_result=True)
        def my_task(context):
            return "result"

    Args:
        level: Logging level
        include_args: Log function arguments
        include_result: Log return value

    Returns:
        Wrapped function with logging
    """
    def decorator(func: F) -> F:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            import time

            if include_args:
                logger.log(level, f"Starting {func.__name__} with args={args}, kwargs={kwargs}")
            else:
                logger.log(level, f"Starting {func.__name__}")

            start = time.time()
            try:
                result = func(*args, **kwargs)
                elapsed = time.time() - start

                if include_result:
                    logger.log(level, f"Completed {func.__name__} in {elapsed:.2f}s: {result}")
                else:
                    logger.log(level, f"Completed {func.__name__} in {elapsed:.2f}s")

                return result
            except Exception as e:
                elapsed = time.time() - start
                logger.error(f"Failed {func.__name__} in {elapsed:.2f}s: {e}")
                raise

        return wrapper  # type: ignore

    return decorator


__all__ = [
    "task",
    "python_task",
    "sensor",
    "branch",
    "short_circuit",
    "task_group",
    "virtualenv",
    "docker",
    "retry",
    "timeout",
    "log_execution",
]
