"""
RoadDeploy - Deployment Automation for BlackRoad
Blue-green deployments, rollbacks, and deployment pipelines.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional
import asyncio
import hashlib
import json
import logging
import threading
import time
import uuid

logger = logging.getLogger(__name__)


class DeploymentStatus(str, Enum):
    """Deployment status."""
    PENDING = "pending"
    BUILDING = "building"
    DEPLOYING = "deploying"
    VERIFYING = "verifying"
    COMPLETED = "completed"
    FAILED = "failed"
    ROLLED_BACK = "rolled_back"


class DeploymentStrategy(str, Enum):
    """Deployment strategies."""
    ROLLING = "rolling"
    BLUE_GREEN = "blue_green"
    CANARY = "canary"
    RECREATE = "recreate"


class Environment(str, Enum):
    """Deployment environments."""
    DEVELOPMENT = "development"
    STAGING = "staging"
    PRODUCTION = "production"


@dataclass
class DeploymentTarget:
    """A deployment target."""
    id: str
    name: str
    environment: Environment
    url: str
    health_check_url: Optional[str] = None
    active: bool = True
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class BuildArtifact:
    """A build artifact."""
    id: str
    version: str
    image: Optional[str] = None
    checksum: str = ""
    size_bytes: int = 0
    built_at: datetime = field(default_factory=datetime.now)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class DeploymentStep:
    """A step in the deployment."""
    name: str
    status: DeploymentStatus = DeploymentStatus.PENDING
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    output: str = ""
    error: Optional[str] = None


@dataclass
class Deployment:
    """A deployment."""
    id: str
    application_id: str
    artifact: BuildArtifact
    target: DeploymentTarget
    strategy: DeploymentStrategy = DeploymentStrategy.ROLLING
    status: DeploymentStatus = DeploymentStatus.PENDING
    steps: List[DeploymentStep] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.now)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    deployed_by: Optional[str] = None
    rollback_of: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "application_id": self.application_id,
            "version": self.artifact.version,
            "target": self.target.name,
            "environment": self.target.environment.value,
            "strategy": self.strategy.value,
            "status": self.status.value,
            "created_at": self.created_at.isoformat(),
            "completed_at": self.completed_at.isoformat() if self.completed_at else None
        }


@dataclass
class Application:
    """An application to deploy."""
    id: str
    name: str
    repository: str
    targets: List[DeploymentTarget] = field(default_factory=list)
    current_versions: Dict[str, str] = field(default_factory=dict)  # environment -> version
    metadata: Dict[str, Any] = field(default_factory=dict)


class DeploymentStore:
    """Store for deployment data."""

    def __init__(self):
        self.applications: Dict[str, Application] = {}
        self.deployments: Dict[str, Deployment] = {}
        self.artifacts: Dict[str, BuildArtifact] = {}
        self._lock = threading.Lock()

    def save_application(self, app: Application) -> None:
        with self._lock:
            self.applications[app.id] = app

    def get_application(self, app_id: str) -> Optional[Application]:
        return self.applications.get(app_id)

    def save_deployment(self, deployment: Deployment) -> None:
        with self._lock:
            self.deployments[deployment.id] = deployment

    def get_deployment(self, deployment_id: str) -> Optional[Deployment]:
        return self.deployments.get(deployment_id)

    def get_app_deployments(self, app_id: str, limit: int = 50) -> List[Deployment]:
        deployments = [d for d in self.deployments.values() if d.application_id == app_id]
        return sorted(deployments, key=lambda d: d.created_at, reverse=True)[:limit]

    def save_artifact(self, artifact: BuildArtifact) -> None:
        with self._lock:
            self.artifacts[artifact.id] = artifact


class HealthChecker:
    """Check deployment health."""

    def __init__(self, timeout: int = 30, retries: int = 3):
        self.timeout = timeout
        self.retries = retries

    async def check(self, url: str) -> bool:
        """Check if endpoint is healthy."""
        for attempt in range(self.retries):
            try:
                # Simulate health check (use aiohttp in production)
                await asyncio.sleep(0.1)
                logger.debug(f"Health check passed: {url}")
                return True
            except Exception as e:
                logger.warning(f"Health check failed (attempt {attempt + 1}): {e}")
                await asyncio.sleep(1)
        return False


class DeploymentExecutor:
    """Execute deployments."""

    def __init__(self, store: DeploymentStore, health_checker: HealthChecker):
        self.store = store
        self.health_checker = health_checker
        self._hooks: Dict[str, List[Callable]] = {
            "pre_deploy": [],
            "post_deploy": [],
            "rollback": []
        }

    def add_hook(self, event: str, handler: Callable) -> None:
        if event in self._hooks:
            self._hooks[event].append(handler)

    async def _run_hooks(self, event: str, deployment: Deployment) -> bool:
        for handler in self._hooks.get(event, []):
            try:
                if asyncio.iscoroutinefunction(handler):
                    await handler(deployment)
                else:
                    handler(deployment)
            except Exception as e:
                logger.error(f"Hook failed: {e}")
                return False
        return True

    def _add_step(self, deployment: Deployment, name: str) -> DeploymentStep:
        step = DeploymentStep(name=name, started_at=datetime.now())
        deployment.steps.append(step)
        return step

    async def execute(self, deployment: Deployment) -> bool:
        """Execute a deployment."""
        deployment.status = DeploymentStatus.BUILDING
        deployment.started_at = datetime.now()
        self.store.save_deployment(deployment)

        try:
            # Pre-deploy hooks
            step = self._add_step(deployment, "Pre-deploy hooks")
            if not await self._run_hooks("pre_deploy", deployment):
                step.error = "Pre-deploy hook failed"
                step.status = DeploymentStatus.FAILED
                raise Exception("Pre-deploy hook failed")
            step.status = DeploymentStatus.COMPLETED
            step.completed_at = datetime.now()

            # Execute based on strategy
            deployment.status = DeploymentStatus.DEPLOYING
            self.store.save_deployment(deployment)

            if deployment.strategy == DeploymentStrategy.ROLLING:
                await self._rolling_deploy(deployment)
            elif deployment.strategy == DeploymentStrategy.BLUE_GREEN:
                await self._blue_green_deploy(deployment)
            elif deployment.strategy == DeploymentStrategy.CANARY:
                await self._canary_deploy(deployment)
            else:
                await self._recreate_deploy(deployment)

            # Verify deployment
            deployment.status = DeploymentStatus.VERIFYING
            self.store.save_deployment(deployment)

            step = self._add_step(deployment, "Health verification")
            if deployment.target.health_check_url:
                healthy = await self.health_checker.check(deployment.target.health_check_url)
                if not healthy:
                    step.error = "Health check failed"
                    step.status = DeploymentStatus.FAILED
                    raise Exception("Health check failed")
            step.status = DeploymentStatus.COMPLETED
            step.completed_at = datetime.now()

            # Post-deploy hooks
            step = self._add_step(deployment, "Post-deploy hooks")
            await self._run_hooks("post_deploy", deployment)
            step.status = DeploymentStatus.COMPLETED
            step.completed_at = datetime.now()

            deployment.status = DeploymentStatus.COMPLETED
            deployment.completed_at = datetime.now()

            # Update current version
            app = self.store.get_application(deployment.application_id)
            if app:
                app.current_versions[deployment.target.environment.value] = deployment.artifact.version

            return True

        except Exception as e:
            deployment.status = DeploymentStatus.FAILED
            deployment.completed_at = datetime.now()
            logger.error(f"Deployment failed: {e}")
            return False

        finally:
            self.store.save_deployment(deployment)

    async def _rolling_deploy(self, deployment: Deployment) -> None:
        """Rolling deployment."""
        step = self._add_step(deployment, "Rolling update")
        # Simulate gradual rollout
        for i in range(5):
            await asyncio.sleep(0.1)
            step.output += f"Instance {i+1}/5 updated\n"
        step.status = DeploymentStatus.COMPLETED
        step.completed_at = datetime.now()

    async def _blue_green_deploy(self, deployment: Deployment) -> None:
        """Blue-green deployment."""
        step = self._add_step(deployment, "Deploy to green environment")
        await asyncio.sleep(0.2)
        step.output = "Green environment deployed"
        step.status = DeploymentStatus.COMPLETED
        step.completed_at = datetime.now()

        step = self._add_step(deployment, "Switch traffic to green")
        await asyncio.sleep(0.1)
        step.output = "Traffic switched"
        step.status = DeploymentStatus.COMPLETED
        step.completed_at = datetime.now()

    async def _canary_deploy(self, deployment: Deployment) -> None:
        """Canary deployment."""
        percentages = [10, 25, 50, 100]
        for pct in percentages:
            step = self._add_step(deployment, f"Route {pct}% traffic")
            await asyncio.sleep(0.1)
            step.output = f"{pct}% traffic routed to new version"
            step.status = DeploymentStatus.COMPLETED
            step.completed_at = datetime.now()

    async def _recreate_deploy(self, deployment: Deployment) -> None:
        """Recreate deployment."""
        step = self._add_step(deployment, "Stop existing instances")
        await asyncio.sleep(0.1)
        step.status = DeploymentStatus.COMPLETED
        step.completed_at = datetime.now()

        step = self._add_step(deployment, "Deploy new instances")
        await asyncio.sleep(0.2)
        step.status = DeploymentStatus.COMPLETED
        step.completed_at = datetime.now()


class DeploymentManager:
    """High-level deployment management."""

    def __init__(self):
        self.store = DeploymentStore()
        self.health_checker = HealthChecker()
        self.executor = DeploymentExecutor(self.store, self.health_checker)

    def register_application(
        self,
        name: str,
        repository: str,
        targets: List[Dict[str, Any]] = None
    ) -> Application:
        """Register an application."""
        app = Application(
            id=hashlib.md5(f"{name}{datetime.now()}".encode()).hexdigest()[:12],
            name=name,
            repository=repository
        )

        if targets:
            for t in targets:
                target = DeploymentTarget(
                    id=str(uuid.uuid4())[:8],
                    name=t.get("name", "default"),
                    environment=Environment(t.get("environment", "development")),
                    url=t.get("url", ""),
                    health_check_url=t.get("health_check_url")
                )
                app.targets.append(target)

        self.store.save_application(app)
        return app

    def create_artifact(
        self,
        version: str,
        image: Optional[str] = None,
        checksum: str = ""
    ) -> BuildArtifact:
        """Create a build artifact."""
        artifact = BuildArtifact(
            id=str(uuid.uuid4()),
            version=version,
            image=image,
            checksum=checksum
        )
        self.store.save_artifact(artifact)
        return artifact

    async def deploy(
        self,
        application_id: str,
        artifact: BuildArtifact,
        environment: Environment,
        strategy: DeploymentStrategy = DeploymentStrategy.ROLLING,
        deployed_by: Optional[str] = None
    ) -> Optional[Deployment]:
        """Create and execute a deployment."""
        app = self.store.get_application(application_id)
        if not app:
            return None

        target = next(
            (t for t in app.targets if t.environment == environment),
            None
        )
        if not target:
            return None

        deployment = Deployment(
            id=str(uuid.uuid4()),
            application_id=application_id,
            artifact=artifact,
            target=target,
            strategy=strategy,
            deployed_by=deployed_by
        )

        self.store.save_deployment(deployment)
        await self.executor.execute(deployment)

        return deployment

    async def rollback(
        self,
        application_id: str,
        environment: Environment
    ) -> Optional[Deployment]:
        """Rollback to previous version."""
        deployments = self.store.get_app_deployments(application_id)
        
        # Find last successful deployment
        env_deployments = [
            d for d in deployments
            if d.target.environment == environment and d.status == DeploymentStatus.COMPLETED
        ]

        if len(env_deployments) < 2:
            logger.warning("No previous deployment to rollback to")
            return None

        previous = env_deployments[1]  # Second most recent

        rollback_deployment = Deployment(
            id=str(uuid.uuid4()),
            application_id=application_id,
            artifact=previous.artifact,
            target=previous.target,
            strategy=previous.strategy,
            rollback_of=env_deployments[0].id
        )

        self.store.save_deployment(rollback_deployment)
        await self.executor.execute(rollback_deployment)

        return rollback_deployment

    def get_deployment(self, deployment_id: str) -> Optional[Dict[str, Any]]:
        """Get deployment details."""
        deployment = self.store.get_deployment(deployment_id)
        if deployment:
            return deployment.to_dict()
        return None

    def list_deployments(self, application_id: str, limit: int = 50) -> List[Dict[str, Any]]:
        """List deployments for an application."""
        deployments = self.store.get_app_deployments(application_id, limit)
        return [d.to_dict() for d in deployments]

    def get_current_version(self, application_id: str, environment: str) -> Optional[str]:
        """Get current deployed version."""
        app = self.store.get_application(application_id)
        if app:
            return app.current_versions.get(environment)
        return None


# Example usage
async def example_usage():
    """Example deployment usage."""
    manager = DeploymentManager()

    # Register application
    app = manager.register_application(
        name="my-service",
        repository="github.com/blackroad/my-service",
        targets=[
            {
                "name": "staging",
                "environment": "staging",
                "url": "https://staging.example.com",
                "health_check_url": "https://staging.example.com/health"
            },
            {
                "name": "production",
                "environment": "production",
                "url": "https://example.com",
                "health_check_url": "https://example.com/health"
            }
        ]
    )

    print(f"Registered app: {app.name}")

    # Create artifact
    artifact = manager.create_artifact(
        version="v1.2.3",
        image="ghcr.io/blackroad/my-service:v1.2.3"
    )

    # Deploy to staging
    deployment = await manager.deploy(
        app.id,
        artifact,
        Environment.STAGING,
        strategy=DeploymentStrategy.BLUE_GREEN
    )

    print(f"\nDeployment: {deployment.id}")
    print(f"Status: {deployment.status.value}")
    
    for step in deployment.steps:
        print(f"  - {step.name}: {step.status.value}")

    # Get current version
    version = manager.get_current_version(app.id, "staging")
    print(f"\nCurrent staging version: {version}")
