"""
RoadService - Service Discovery & Registry for BlackRoad
Service registration, health checking, and load balancing.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import asyncio
import hashlib
import json
import logging
import random
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class ServiceStatus(str, Enum):
    """Service health status."""
    HEALTHY = "healthy"
    UNHEALTHY = "unhealthy"
    DEGRADED = "degraded"
    UNKNOWN = "unknown"


class LoadBalancePolicy(str, Enum):
    """Load balancing policies."""
    ROUND_ROBIN = "round_robin"
    RANDOM = "random"
    LEAST_CONNECTIONS = "least_connections"
    WEIGHTED_RANDOM = "weighted_random"


@dataclass
class ServiceInstance:
    """A service instance."""
    id: str
    service_name: str
    host: str
    port: int
    status: ServiceStatus = ServiceStatus.UNKNOWN
    weight: int = 100
    connections: int = 0
    metadata: Dict[str, Any] = field(default_factory=dict)
    tags: Set[str] = field(default_factory=set)
    registered_at: datetime = field(default_factory=datetime.now)
    last_heartbeat: datetime = field(default_factory=datetime.now)
    health_check_url: Optional[str] = None

    @property
    def address(self) -> str:
        return f"{self.host}:{self.port}"

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "service_name": self.service_name,
            "host": self.host,
            "port": self.port,
            "status": self.status.value,
            "weight": self.weight,
            "connections": self.connections,
            "tags": list(self.tags),
            "registered_at": self.registered_at.isoformat(),
            "last_heartbeat": self.last_heartbeat.isoformat()
        }


@dataclass
class ServiceDefinition:
    """Definition of a service."""
    name: str
    description: str = ""
    version: str = "1.0.0"
    health_check_interval: int = 30
    health_check_timeout: int = 5
    deregister_after: int = 90
    metadata: Dict[str, Any] = field(default_factory=dict)


class ServiceRegistry:
    """Service registry."""

    def __init__(self):
        self.services: Dict[str, ServiceDefinition] = {}
        self.instances: Dict[str, Dict[str, ServiceInstance]] = {}  # service_name -> {instance_id -> instance}
        self._lock = threading.Lock()
        self._watchers: Dict[str, List[Callable]] = {}

    def register_service(self, definition: ServiceDefinition) -> None:
        """Register a service definition."""
        with self._lock:
            self.services[definition.name] = definition
            if definition.name not in self.instances:
                self.instances[definition.name] = {}

    def register_instance(self, instance: ServiceInstance) -> None:
        """Register a service instance."""
        with self._lock:
            if instance.service_name not in self.instances:
                self.instances[instance.service_name] = {}
            
            self.instances[instance.service_name][instance.id] = instance
            logger.info(f"Registered instance: {instance.service_name}/{instance.id}")
            
            self._notify_watchers(instance.service_name, "register", instance)

    def deregister_instance(self, service_name: str, instance_id: str) -> bool:
        """Deregister a service instance."""
        with self._lock:
            if service_name in self.instances:
                if instance_id in self.instances[service_name]:
                    instance = self.instances[service_name].pop(instance_id)
                    self._notify_watchers(service_name, "deregister", instance)
                    return True
        return False

    def get_instance(self, service_name: str, instance_id: str) -> Optional[ServiceInstance]:
        """Get a specific instance."""
        if service_name in self.instances:
            return self.instances[service_name].get(instance_id)
        return None

    def get_instances(
        self,
        service_name: str,
        healthy_only: bool = True,
        tags: Set[str] = None
    ) -> List[ServiceInstance]:
        """Get all instances of a service."""
        if service_name not in self.instances:
            return []
        
        instances = list(self.instances[service_name].values())
        
        if healthy_only:
            instances = [i for i in instances if i.status == ServiceStatus.HEALTHY]
        
        if tags:
            instances = [i for i in instances if tags.issubset(i.tags)]
        
        return instances

    def heartbeat(self, service_name: str, instance_id: str) -> bool:
        """Update instance heartbeat."""
        instance = self.get_instance(service_name, instance_id)
        if instance:
            instance.last_heartbeat = datetime.now()
            return True
        return False

    def update_status(self, service_name: str, instance_id: str, status: ServiceStatus) -> bool:
        """Update instance status."""
        instance = self.get_instance(service_name, instance_id)
        if instance:
            old_status = instance.status
            instance.status = status
            if old_status != status:
                self._notify_watchers(service_name, "status_change", instance)
            return True
        return False

    def watch(self, service_name: str, callback: Callable) -> None:
        """Watch for service changes."""
        if service_name not in self._watchers:
            self._watchers[service_name] = []
        self._watchers[service_name].append(callback)

    def _notify_watchers(self, service_name: str, event: str, instance: ServiceInstance) -> None:
        for callback in self._watchers.get(service_name, []):
            try:
                callback(event, instance)
            except Exception as e:
                logger.error(f"Watcher error: {e}")


class HealthChecker:
    """Check service health."""

    def __init__(self, registry: ServiceRegistry):
        self.registry = registry
        self._running = False

    async def check_instance(self, instance: ServiceInstance) -> ServiceStatus:
        """Check health of an instance."""
        if not instance.health_check_url:
            return ServiceStatus.HEALTHY  # Assume healthy if no check URL
        
        try:
            # Simulate health check (use aiohttp in production)
            await asyncio.sleep(0.1)
            return ServiceStatus.HEALTHY
        except Exception:
            return ServiceStatus.UNHEALTHY

    async def check_all(self) -> Dict[str, int]:
        """Check all instances."""
        stats = {"healthy": 0, "unhealthy": 0}
        
        for service_name, instances in self.registry.instances.items():
            for instance in instances.values():
                status = await self.check_instance(instance)
                self.registry.update_status(service_name, instance.id, status)
                
                if status == ServiceStatus.HEALTHY:
                    stats["healthy"] += 1
                else:
                    stats["unhealthy"] += 1
        
        return stats

    async def run_checks(self, interval: int = 30) -> None:
        """Run periodic health checks."""
        self._running = True
        while self._running:
            await self.check_all()
            await asyncio.sleep(interval)

    def stop(self) -> None:
        self._running = False


class LoadBalancer:
    """Load balance across service instances."""

    def __init__(self, registry: ServiceRegistry, policy: LoadBalancePolicy = LoadBalancePolicy.ROUND_ROBIN):
        self.registry = registry
        self.policy = policy
        self._counters: Dict[str, int] = {}
        self._lock = threading.Lock()

    def select(self, service_name: str, tags: Set[str] = None) -> Optional[ServiceInstance]:
        """Select an instance for the request."""
        instances = self.registry.get_instances(service_name, healthy_only=True, tags=tags)
        
        if not instances:
            return None
        
        if self.policy == LoadBalancePolicy.ROUND_ROBIN:
            return self._round_robin(service_name, instances)
        elif self.policy == LoadBalancePolicy.RANDOM:
            return random.choice(instances)
        elif self.policy == LoadBalancePolicy.LEAST_CONNECTIONS:
            return min(instances, key=lambda i: i.connections)
        elif self.policy == LoadBalancePolicy.WEIGHTED_RANDOM:
            return self._weighted_random(instances)
        
        return instances[0]

    def _round_robin(self, service_name: str, instances: List[ServiceInstance]) -> ServiceInstance:
        with self._lock:
            counter = self._counters.get(service_name, 0)
            instance = instances[counter % len(instances)]
            self._counters[service_name] = counter + 1
            return instance

    def _weighted_random(self, instances: List[ServiceInstance]) -> ServiceInstance:
        total_weight = sum(i.weight for i in instances)
        r = random.uniform(0, total_weight)
        cumulative = 0
        for instance in instances:
            cumulative += instance.weight
            if r <= cumulative:
                return instance
        return instances[-1]


class ServiceClient:
    """Client for service discovery."""

    def __init__(self, registry: ServiceRegistry, load_balancer: LoadBalancer):
        self.registry = registry
        self.load_balancer = load_balancer

    async def call(
        self,
        service_name: str,
        method: str,
        path: str,
        **kwargs
    ) -> Dict[str, Any]:
        """Call a service endpoint."""
        instance = self.load_balancer.select(service_name)
        
        if not instance:
            raise Exception(f"No healthy instances for service: {service_name}")
        
        instance.connections += 1
        
        try:
            # Simulate service call (use aiohttp in production)
            url = f"http://{instance.address}{path}"
            logger.debug(f"Calling {method} {url}")
            
            await asyncio.sleep(0.05)  # Simulate network latency
            
            return {
                "status": 200,
                "instance": instance.id,
                "address": instance.address
            }
        finally:
            instance.connections -= 1


class ServiceManager:
    """High-level service management."""

    def __init__(self, load_balance_policy: LoadBalancePolicy = LoadBalancePolicy.ROUND_ROBIN):
        self.registry = ServiceRegistry()
        self.health_checker = HealthChecker(self.registry)
        self.load_balancer = LoadBalancer(self.registry, load_balance_policy)
        self.client = ServiceClient(self.registry, self.load_balancer)
        self._health_check_task: Optional[asyncio.Task] = None

    def define_service(
        self,
        name: str,
        description: str = "",
        version: str = "1.0.0",
        **kwargs
    ) -> ServiceDefinition:
        """Define a service."""
        definition = ServiceDefinition(
            name=name,
            description=description,
            version=version,
            **kwargs
        )
        self.registry.register_service(definition)
        return definition

    def register(
        self,
        service_name: str,
        host: str,
        port: int,
        weight: int = 100,
        tags: Set[str] = None,
        metadata: Dict[str, Any] = None,
        health_check_url: str = None
    ) -> ServiceInstance:
        """Register a service instance."""
        instance = ServiceInstance(
            id=str(uuid.uuid4())[:8],
            service_name=service_name,
            host=host,
            port=port,
            weight=weight,
            tags=tags or set(),
            metadata=metadata or {},
            health_check_url=health_check_url,
            status=ServiceStatus.HEALTHY
        )
        
        self.registry.register_instance(instance)
        return instance

    def deregister(self, service_name: str, instance_id: str) -> bool:
        """Deregister an instance."""
        return self.registry.deregister_instance(service_name, instance_id)

    def heartbeat(self, service_name: str, instance_id: str) -> bool:
        """Send heartbeat."""
        return self.registry.heartbeat(service_name, instance_id)

    def get_service(self, service_name: str) -> Optional[ServiceInstance]:
        """Get a service instance (load balanced)."""
        return self.load_balancer.select(service_name)

    def list_services(self) -> List[str]:
        """List all registered services."""
        return list(self.registry.services.keys())

    def list_instances(self, service_name: str) -> List[Dict[str, Any]]:
        """List instances of a service."""
        instances = self.registry.get_instances(service_name, healthy_only=False)
        return [i.to_dict() for i in instances]

    async def call_service(
        self,
        service_name: str,
        method: str = "GET",
        path: str = "/",
        **kwargs
    ) -> Dict[str, Any]:
        """Call a service."""
        return await self.client.call(service_name, method, path, **kwargs)

    async def start_health_checks(self, interval: int = 30) -> None:
        """Start background health checks."""
        self._health_check_task = asyncio.create_task(
            self.health_checker.run_checks(interval)
        )

    async def stop_health_checks(self) -> None:
        """Stop health checks."""
        self.health_checker.stop()
        if self._health_check_task:
            self._health_check_task.cancel()

    def watch_service(self, service_name: str, callback: Callable) -> None:
        """Watch for service changes."""
        self.registry.watch(service_name, callback)


# Example usage
async def example_usage():
    """Example service discovery usage."""
    manager = ServiceManager(load_balance_policy=LoadBalancePolicy.ROUND_ROBIN)

    # Define service
    manager.define_service(
        name="user-service",
        description="User management service",
        version="2.0.0"
    )

    # Register instances
    instance1 = manager.register(
        "user-service",
        host="192.168.1.10",
        port=8080,
        tags={"primary", "v2"},
        health_check_url="/health"
    )

    instance2 = manager.register(
        "user-service",
        host="192.168.1.11",
        port=8080,
        tags={"secondary", "v2"},
        weight=50
    )

    print(f"Registered instances: {instance1.id}, {instance2.id}")

    # Watch for changes
    def on_service_change(event, instance):
        print(f"Service event: {event} - {instance.id}")

    manager.watch_service("user-service", on_service_change)

    # Get instances
    instances = manager.list_instances("user-service")
    print(f"Instances: {len(instances)}")

    # Call service (load balanced)
    for _ in range(5):
        response = await manager.call_service("user-service", "GET", "/api/users")
        print(f"Response from: {response['instance']}")

    # Deregister
    manager.deregister("user-service", instance2.id)
    print("Instance 2 deregistered")
