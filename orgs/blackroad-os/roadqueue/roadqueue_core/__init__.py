"""RoadQueue - Enterprise Message Queue System.

RoadQueue is a high-performance, distributed message queue system designed
for enterprise workloads. It provides reliable message delivery, priority
queues, delayed jobs, dead letter handling, and comprehensive monitoring.

Architecture Overview:
┌─────────────────────────────────────────────────────────────────────────┐
│                           RoadQueue System                              │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐   │
│  │  Producers  │  │   Brokers   │  │   Workers   │  │  Consumers  │   │
│  │             │──▶│             │──▶│             │──▶│             │   │
│  │ • Publish   │  │ • Route     │  │ • Process   │  │ • Receive   │   │
│  │ • Priority  │  │ • Balance   │  │ • Retry     │  │ • Ack       │   │
│  │ • Delay     │  │ • Persist   │  │ • DLQ       │  │ • Subscribe │   │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘   │
├─────────────────────────────────────────────────────────────────────────┤
│                           Core Components                               │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                        Queue Module                               │ │
│  │  • Message - Message with headers, body, metadata                 │ │
│  │  • Queue - FIFO queue with priority support                       │ │
│  │  • PriorityQueue - Multi-level priority queue                     │ │
│  │  • DelayQueue - Delayed message delivery                          │ │
│  │  • DeadLetterQueue - Failed message handling                      │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                        Broker Module                              │ │
│  │  • Broker - Central message routing                               │ │
│  │  • Exchange - Topic/direct/fanout routing                         │ │
│  │  • Binding - Queue-exchange bindings                              │ │
│  │  • Router - Intelligent message routing                           │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                        Worker Module                              │ │
│  │  • Worker - Message processor                                     │ │
│  │  • WorkerPool - Worker lifecycle management                       │ │
│  │  • TaskExecutor - Async task execution                           │ │
│  │  • RetryPolicy - Retry with backoff                              │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                       Scheduler Module                            │ │
│  │  • Scheduler - Cron-like job scheduling                          │ │
│  │  • PeriodicTask - Recurring task definition                      │ │
│  │  • CronParser - Cron expression parser                           │ │
│  │  • ScheduleRegistry - Task registration                          │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                        Storage Module                             │ │
│  │  • Backend - Abstract storage interface                          │ │
│  │  • MemoryBackend - In-memory storage                             │ │
│  │  • RedisBackend - Redis-based persistence                        │ │
│  │  • SQLBackend - SQL database persistence                         │ │
│  │  • WAL - Write-ahead logging                                     │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                       Protocol Module                             │ │
│  │  • Serializer - Message serialization                            │ │
│  │  • Compressor - Message compression                              │ │
│  │  • Encryptor - Message encryption                                │ │
│  │  • Codec - Pluggable codec system                                │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                      Middleware Module                            │ │
│  │  • Pipeline - Middleware pipeline                                │ │
│  │  • RateLimiter - Rate limiting middleware                        │ │
│  │  • Validator - Message validation                                │ │
│  │  • Logger - Audit logging                                        │ │
│  │  • Metrics - Metrics collection                                  │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                      Monitoring Module                            │ │
│  │  • Monitor - System monitoring                                   │ │
│  │  • Dashboard - Real-time dashboard                               │ │
│  │  • Alerter - Alert management                                    │ │
│  │  • Tracer - Distributed tracing                                  │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘

Features:
- Priority-based message queuing
- Delayed message delivery
- Dead letter queue handling
- Distributed worker pools
- Cron-based job scheduling
- Multiple storage backends
- Message encryption and compression
- Comprehensive monitoring
- Rate limiting and validation

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

# Queue components
from roadqueue_core.queue.message import (
    Message,
    MessageHeaders,
    MessageState,
    MessagePriority,
)
from roadqueue_core.queue.base import Queue, QueueConfig
from roadqueue_core.queue.priority import PriorityQueue
from roadqueue_core.queue.delay import DelayQueue
from roadqueue_core.queue.dlq import DeadLetterQueue

# Broker components
from roadqueue_core.broker.broker import Broker, BrokerConfig
from roadqueue_core.broker.exchange import Exchange, ExchangeType
from roadqueue_core.broker.binding import Binding
from roadqueue_core.broker.router import Router

# Worker components
from roadqueue_core.worker.worker import Worker, WorkerState
from roadqueue_core.worker.pool import WorkerPool, PoolConfig
from roadqueue_core.worker.executor import TaskExecutor
from roadqueue_core.worker.retry import RetryPolicy, BackoffStrategy

# Scheduler components
from roadqueue_core.scheduler.scheduler import Scheduler
from roadqueue_core.scheduler.periodic import PeriodicTask
from roadqueue_core.scheduler.cron import CronParser, CronSchedule

# Storage components
from roadqueue_core.storage.backend import StorageBackend
from roadqueue_core.storage.memory import MemoryBackend
from roadqueue_core.storage.redis import RedisBackend
from roadqueue_core.storage.sql import SQLBackend

# Protocol components
from roadqueue_core.protocol.serializer import Serializer, JSONSerializer
from roadqueue_core.protocol.compressor import Compressor, GzipCompressor
from roadqueue_core.protocol.codec import Codec, CodecRegistry

# Middleware components
from roadqueue_core.middleware.pipeline import Pipeline, Middleware
from roadqueue_core.middleware.ratelimit import RateLimiter
from roadqueue_core.middleware.validator import Validator

# Monitoring components
from roadqueue_core.monitoring.monitor import Monitor, QueueMetrics
from roadqueue_core.monitoring.alerter import Alerter, Alert
from roadqueue_core.monitoring.tracer import Tracer, Span

__version__ = "1.0.0"
__author__ = "BlackRoad OS"
__license__ = "Proprietary"

__all__ = [
    # Version
    "__version__",
    # Queue
    "Message",
    "MessageHeaders",
    "MessageState",
    "MessagePriority",
    "Queue",
    "QueueConfig",
    "PriorityQueue",
    "DelayQueue",
    "DeadLetterQueue",
    # Broker
    "Broker",
    "BrokerConfig",
    "Exchange",
    "ExchangeType",
    "Binding",
    "Router",
    # Worker
    "Worker",
    "WorkerState",
    "WorkerPool",
    "PoolConfig",
    "TaskExecutor",
    "RetryPolicy",
    "BackoffStrategy",
    # Scheduler
    "Scheduler",
    "PeriodicTask",
    "CronParser",
    "CronSchedule",
    # Storage
    "StorageBackend",
    "MemoryBackend",
    "RedisBackend",
    "SQLBackend",
    # Protocol
    "Serializer",
    "JSONSerializer",
    "Compressor",
    "GzipCompressor",
    "Codec",
    "CodecRegistry",
    # Middleware
    "Pipeline",
    "Middleware",
    "RateLimiter",
    "Validator",
    # Monitoring
    "Monitor",
    "QueueMetrics",
    "Alerter",
    "Alert",
    "Tracer",
    "Span",
]
