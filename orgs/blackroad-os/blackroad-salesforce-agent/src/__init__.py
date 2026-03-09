"""
BlackRoad Salesforce Agent

Autonomous AI agent that turns 1 Salesforce seat into unlimited scale.
Deploy 500+ agents on Pi cluster, all using 1 API user ($330/mo).
Fortune 500 pays $10M+/year for what we get for $4K/year.
"""

__version__ = "1.0.0"
__author__ = "BlackRoad OS, Inc."

from .agents import SalesforceAgent
from .api import SalesforceClient, BulkClient
from .queue import TaskQueue, Task, TaskStatus

__all__ = [
    'SalesforceAgent',
    'SalesforceClient',
    'BulkClient',
    'TaskQueue',
    'Task',
    'TaskStatus',
]
