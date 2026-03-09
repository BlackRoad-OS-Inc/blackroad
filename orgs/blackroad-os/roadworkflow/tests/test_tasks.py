"""Task tests."""

import pytest
from datetime import datetime, timedelta
from roadworkflow_core.tasks.base import (
    Task,
    TaskConfig,
    TaskContext,
    TaskStatus,
    TaskResult,
    RetryConfig,
    RetryPolicy,
)
from roadworkflow_core.tasks.operators import (
    PythonTask,
    ShellTask,
    HTTPTask,
)
from roadworkflow_core.tasks.decorators import task, sensor


class TestTaskConfig:
    """TaskConfig tests."""

    def test_default_config(self):
        config = TaskConfig()
        assert config.task_id != ""
        assert config.timeout is None

    def test_custom_config(self):
        config = TaskConfig(
            task_id="custom_task",
            timeout=300,
        )
        assert config.task_id == "custom_task"
        assert config.timeout == 300


class TestRetryConfig:
    """RetryConfig tests."""

    def test_exponential_delay(self):
        config = RetryConfig(
            max_retries=5,
            policy=RetryPolicy.EXPONENTIAL,
            base_delay=1.0,
            jitter=False,
        )
        
        delays = [config.get_delay(i) for i in range(5)]
        assert delays[0] == 1.0
        assert delays[1] == 2.0
        assert delays[2] == 4.0

    def test_should_retry(self):
        config = RetryConfig(max_retries=3)
        
        assert config.should_retry(Exception("test"), 0)
        assert config.should_retry(Exception("test"), 2)
        assert not config.should_retry(Exception("test"), 3)


class TestTaskContext:
    """TaskContext tests."""

    def test_create_context(self):
        context = TaskContext(
            task_id="task1",
            run_id="run1",
            workflow_id="workflow1",
            execution_date=datetime.utcnow(),
        )
        assert context.task_id == "task1"

    def test_xcom(self):
        context = TaskContext(
            task_id="task1",
            run_id="run1",
            workflow_id="workflow1",
            execution_date=datetime.utcnow(),
        )
        
        context.push_xcom("key1", "value1")
        assert context.pull_xcom("key1") == "value1"


class TestPythonTask:
    """PythonTask tests."""

    def test_execute(self):
        def my_func(context):
            return "result"
        
        task = PythonTask(
            python_callable=my_func,
            task_id="test_task",
        )
        
        context = TaskContext(
            task_id="test_task",
            run_id="run1",
            workflow_id="workflow1",
            execution_date=datetime.utcnow(),
        )
        
        result = task.execute(context)
        assert result == "result"


class TestTaskDecorator:
    """Task decorator tests."""

    def test_task_decorator(self):
        @task(task_id="decorated_task", retries=3)
        def my_task(context):
            return "done"
        
        assert my_task.task_id == "decorated_task"
        assert my_task.config.retry_config.max_retries == 3
