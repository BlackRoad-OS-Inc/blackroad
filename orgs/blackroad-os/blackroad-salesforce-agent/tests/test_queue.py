"""
Tests for task queue system
"""

import pytest
import tempfile
import os
from src.queue import TaskQueue, Task, TaskStatus
from src.queue.task_queue import TaskPriority


class TestTaskQueue:
    """Test the task queue"""

    @pytest.fixture
    def queue(self):
        """Create a temporary queue for testing"""
        with tempfile.NamedTemporaryFile(suffix='.db', delete=False) as f:
            db_path = f.name

        q = TaskQueue(backend="sqlite", db_path=db_path)
        yield q

        # Cleanup
        os.unlink(db_path)

    def test_submit_task(self, queue):
        """Test submitting a task"""
        task_id = queue.submit(
            operation="create",
            sobject="Client_Household__c",
            data={"Name": "Test Household"}
        )

        assert task_id is not None
        assert len(task_id) == 36  # UUID format

    def test_get_next_task(self, queue):
        """Test getting next task from queue"""
        # Submit a task
        queue.submit(
            operation="create",
            sobject="Client_Household__c",
            data={"Name": "Test Household"}
        )

        # Get the task
        task = queue.get_next("test-agent")

        assert task is not None
        assert task.operation == "create"
        assert task.sobject == "Client_Household__c"
        assert task.status == TaskStatus.PROCESSING

    def test_priority_ordering(self, queue):
        """Test that higher priority tasks are returned first"""
        # Submit low priority first
        queue.submit(
            operation="create",
            sobject="Low",
            data={},
            priority=TaskPriority.LOW
        )

        # Submit high priority second
        queue.submit(
            operation="create",
            sobject="High",
            data={},
            priority=TaskPriority.HIGH
        )

        # High priority should come first
        task = queue.get_next("test-agent")
        assert task.sobject == "High"

    def test_complete_task(self, queue):
        """Test completing a task"""
        task_id = queue.submit(
            operation="query",
            sobject="Account",
            data={"soql": "SELECT Id FROM Account"}
        )

        task = queue.get_next("test-agent")
        queue.complete(task_id, {"records": [], "count": 0})

        stats = queue.stats()
        assert stats["completed"] == 1

    def test_fail_and_retry(self, queue):
        """Test failing and retrying a task"""
        task_id = queue.submit(
            operation="create",
            sobject="Test",
            data={}
        )

        task = queue.get_next("test-agent")

        # Fail the task (should retry)
        queue.fail(task_id, "Test error")

        # Task should be back in queue
        task = queue.get_next("test-agent")
        assert task is not None
        assert task.retry_count == 1

    def test_batch_submit(self, queue):
        """Test submitting multiple tasks"""
        data_list = [
            {"Name": f"Household {i}"}
            for i in range(10)
        ]

        task_ids = queue.submit_batch(
            operation="create",
            sobject="Client_Household__c",
            data_list=data_list
        )

        assert len(task_ids) == 10

        stats = queue.stats()
        assert stats["pending"] == 10

    def test_stats(self, queue):
        """Test queue statistics"""
        # Submit some tasks
        for i in range(5):
            queue.submit("create", "Test", {})

        stats = queue.stats()

        assert stats["pending"] == 5
        assert stats["total"] == 5
        assert stats["processing"] == 0
        assert stats["completed"] == 0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
