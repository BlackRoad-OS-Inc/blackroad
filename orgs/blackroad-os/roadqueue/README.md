# RoadQueue

**Enterprise Message Queue System for BlackRoad OS**

RoadQueue is a high-performance, distributed message queue system designed for enterprise workloads. It provides reliable message delivery, priority queues, delayed jobs, dead letter handling, and comprehensive monitoring.

## Features

- **Queue Types**: Standard FIFO, Priority, Delay queues
- **Message Routing**: Direct, Topic, Fanout, Headers exchanges
- **Worker Management**: Auto-scaling worker pools
- **Job Scheduling**: Cron-based task scheduling
- **Storage Backends**: Memory, Redis, SQL
- **Middleware Pipeline**: Rate limiting, validation
- **Monitoring**: Metrics, alerting, distributed tracing

## Quick Start

```python
from roadqueue_core import Broker, Message, Queue

# Create broker
broker = Broker()
broker.start()

# Declare a queue
queue = broker.declare_queue("my-queue")

# Publish a message
message = Message.create(body={"task": "process"}, queue_name="my-queue")
broker.publish(message, routing_key="my-queue")

# Consume messages
def handler(msg):
    print(f"Processing: {msg.body}")
    msg.ack()

broker.consume("my-queue", "consumer-1", handler)
```

## License

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
