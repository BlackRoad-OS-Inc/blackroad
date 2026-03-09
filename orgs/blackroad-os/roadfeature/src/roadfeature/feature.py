"""
RoadFeature - Feature Flags for BlackRoad
Feature toggles with targeting, rollouts, and A/B testing.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Union
import hashlib
import json
import logging
import random
import threading

logger = logging.getLogger(__name__)


class FeatureState(str, Enum):
    """Feature flag state."""
    ON = "on"
    OFF = "off"
    ROLLOUT = "rollout"
    EXPERIMENT = "experiment"


class TargetType(str, Enum):
    """Targeting types."""
    USER = "user"
    GROUP = "group"
    PERCENTAGE = "percentage"
    ATTRIBUTE = "attribute"
    SCHEDULE = "schedule"


@dataclass
class TargetRule:
    """A targeting rule."""
    type: TargetType
    values: List[Any] = field(default_factory=list)
    attribute: Optional[str] = None
    operator: str = "in"  # in, not_in, equals, gt, lt, contains
    percentage: float = 0

    def matches(self, context: Dict[str, Any]) -> bool:
        """Check if rule matches context."""
        if self.type == TargetType.USER:
            user_id = context.get("user_id")
            return user_id in self.values

        elif self.type == TargetType.GROUP:
            groups = context.get("groups", [])
            return any(g in self.values for g in groups)

        elif self.type == TargetType.PERCENTAGE:
            # Deterministic based on user_id
            user_id = context.get("user_id", "")
            hash_val = int(hashlib.md5(user_id.encode()).hexdigest(), 16)
            return (hash_val % 100) < self.percentage

        elif self.type == TargetType.ATTRIBUTE:
            if not self.attribute:
                return False

            attr_val = context.get(self.attribute)
            if self.operator == "in":
                return attr_val in self.values
            elif self.operator == "not_in":
                return attr_val not in self.values
            elif self.operator == "equals":
                return attr_val == self.values[0] if self.values else False
            elif self.operator == "contains":
                return self.values[0] in str(attr_val) if self.values else False
            elif self.operator == "gt":
                return attr_val > self.values[0] if self.values else False
            elif self.operator == "lt":
                return attr_val < self.values[0] if self.values else False

        elif self.type == TargetType.SCHEDULE:
            now = datetime.now()
            for schedule in self.values:
                start = datetime.fromisoformat(schedule.get("start", ""))
                end = datetime.fromisoformat(schedule.get("end", ""))
                if start <= now <= end:
                    return True

        return False


@dataclass
class Variant:
    """A feature variant for experiments."""
    name: str
    value: Any
    weight: float = 1.0
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class Feature:
    """A feature flag."""
    key: str
    name: str
    description: str = ""
    state: FeatureState = FeatureState.OFF
    default_value: Any = False
    rules: List[TargetRule] = field(default_factory=list)
    variants: List[Variant] = field(default_factory=list)
    rollout_percentage: float = 0
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    tags: List[str] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def evaluate(self, context: Dict[str, Any] = None) -> Any:
        """Evaluate the feature flag."""
        context = context or {}

        # Check state
        if self.state == FeatureState.OFF:
            return self.default_value

        if self.state == FeatureState.ON:
            return self._get_on_value()

        # Check rules
        for rule in self.rules:
            if rule.matches(context):
                return self._get_on_value()

        # Rollout
        if self.state == FeatureState.ROLLOUT:
            user_id = context.get("user_id", str(random.random()))
            hash_val = int(hashlib.md5(user_id.encode()).hexdigest(), 16)
            if (hash_val % 100) < self.rollout_percentage:
                return self._get_on_value()

        # Experiment
        if self.state == FeatureState.EXPERIMENT and self.variants:
            return self._select_variant(context)

        return self.default_value

    def _get_on_value(self) -> Any:
        """Get the 'on' value."""
        if self.variants and len(self.variants) == 1:
            return self.variants[0].value
        return True

    def _select_variant(self, context: Dict[str, Any]) -> Any:
        """Select a variant for experiment."""
        if not self.variants:
            return self.default_value

        # Deterministic selection based on user_id
        user_id = context.get("user_id", str(random.random()))
        hash_val = int(hashlib.md5(f"{self.key}:{user_id}".encode()).hexdigest(), 16)

        total_weight = sum(v.weight for v in self.variants)
        threshold = (hash_val % 100) / 100 * total_weight

        cumulative = 0
        for variant in self.variants:
            cumulative += variant.weight
            if threshold < cumulative:
                return variant.value

        return self.variants[-1].value


class FeatureStore:
    """Store feature flags."""

    def __init__(self):
        self.features: Dict[str, Feature] = {}
        self._lock = threading.Lock()

    def add(self, feature: Feature) -> None:
        """Add a feature."""
        with self._lock:
            self.features[feature.key] = feature

    def get(self, key: str) -> Optional[Feature]:
        """Get a feature by key."""
        return self.features.get(key)

    def remove(self, key: str) -> bool:
        """Remove a feature."""
        with self._lock:
            if key in self.features:
                del self.features[key]
                return True
            return False

    def list(self, tags: List[str] = None) -> List[Feature]:
        """List features, optionally filtered by tags."""
        features = list(self.features.values())
        if tags:
            features = [
                f for f in features
                if any(t in f.tags for t in tags)
            ]
        return features

    def load_json(self, data: str) -> int:
        """Load features from JSON."""
        parsed = json.loads(data)
        count = 0

        for f_data in parsed.get("features", []):
            feature = Feature(
                key=f_data["key"],
                name=f_data.get("name", f_data["key"]),
                description=f_data.get("description", ""),
                state=FeatureState(f_data.get("state", "off")),
                default_value=f_data.get("default", False),
                rollout_percentage=f_data.get("rollout_percentage", 0),
                tags=f_data.get("tags", [])
            )

            # Load rules
            for r_data in f_data.get("rules", []):
                rule = TargetRule(
                    type=TargetType(r_data["type"]),
                    values=r_data.get("values", []),
                    attribute=r_data.get("attribute"),
                    operator=r_data.get("operator", "in"),
                    percentage=r_data.get("percentage", 0)
                )
                feature.rules.append(rule)

            # Load variants
            for v_data in f_data.get("variants", []):
                variant = Variant(
                    name=v_data["name"],
                    value=v_data["value"],
                    weight=v_data.get("weight", 1.0)
                )
                feature.variants.append(variant)

            self.add(feature)
            count += 1

        return count

    def export_json(self) -> str:
        """Export features to JSON."""
        features = []
        for f in self.features.values():
            f_data = {
                "key": f.key,
                "name": f.name,
                "description": f.description,
                "state": f.state.value,
                "default": f.default_value,
                "rollout_percentage": f.rollout_percentage,
                "tags": f.tags,
                "rules": [
                    {
                        "type": r.type.value,
                        "values": r.values,
                        "attribute": r.attribute,
                        "operator": r.operator,
                        "percentage": r.percentage
                    }
                    for r in f.rules
                ],
                "variants": [
                    {
                        "name": v.name,
                        "value": v.value,
                        "weight": v.weight
                    }
                    for v in f.variants
                ]
            }
            features.append(f_data)

        return json.dumps({"features": features}, indent=2)


class FeatureClient:
    """Client for evaluating feature flags."""

    def __init__(self, store: FeatureStore, default_context: Dict = None):
        self.store = store
        self.default_context = default_context or {}
        self._overrides: Dict[str, Any] = {}

    def is_enabled(self, key: str, context: Dict = None) -> bool:
        """Check if feature is enabled."""
        return bool(self.get_value(key, context))

    def get_value(self, key: str, context: Dict = None) -> Any:
        """Get feature value."""
        # Check overrides
        if key in self._overrides:
            return self._overrides[key]

        feature = self.store.get(key)
        if not feature:
            return False

        merged_context = {**self.default_context, **(context or {})}
        return feature.evaluate(merged_context)

    def override(self, key: str, value: Any) -> None:
        """Set a local override."""
        self._overrides[key] = value

    def clear_override(self, key: str) -> None:
        """Clear an override."""
        self._overrides.pop(key, None)

    def clear_all_overrides(self) -> None:
        """Clear all overrides."""
        self._overrides.clear()


class FeatureBuilder:
    """Builder for feature flags."""

    def __init__(self, key: str):
        self.feature = Feature(key=key, name=key)

    def name(self, name: str) -> "FeatureBuilder":
        self.feature.name = name
        return self

    def description(self, desc: str) -> "FeatureBuilder":
        self.feature.description = desc
        return self

    def on(self) -> "FeatureBuilder":
        self.feature.state = FeatureState.ON
        return self

    def off(self) -> "FeatureBuilder":
        self.feature.state = FeatureState.OFF
        return self

    def rollout(self, percentage: float) -> "FeatureBuilder":
        self.feature.state = FeatureState.ROLLOUT
        self.feature.rollout_percentage = percentage
        return self

    def experiment(self) -> "FeatureBuilder":
        self.feature.state = FeatureState.EXPERIMENT
        return self

    def default(self, value: Any) -> "FeatureBuilder":
        self.feature.default_value = value
        return self

    def for_users(self, *user_ids: str) -> "FeatureBuilder":
        self.feature.rules.append(TargetRule(
            type=TargetType.USER,
            values=list(user_ids)
        ))
        return self

    def for_groups(self, *groups: str) -> "FeatureBuilder":
        self.feature.rules.append(TargetRule(
            type=TargetType.GROUP,
            values=list(groups)
        ))
        return self

    def for_attribute(
        self,
        attribute: str,
        operator: str,
        *values
    ) -> "FeatureBuilder":
        self.feature.rules.append(TargetRule(
            type=TargetType.ATTRIBUTE,
            attribute=attribute,
            operator=operator,
            values=list(values)
        ))
        return self

    def variant(
        self,
        name: str,
        value: Any,
        weight: float = 1.0
    ) -> "FeatureBuilder":
        self.feature.variants.append(Variant(
            name=name,
            value=value,
            weight=weight
        ))
        return self

    def tags(self, *tags: str) -> "FeatureBuilder":
        self.feature.tags.extend(tags)
        return self

    def build(self) -> Feature:
        return self.feature


class FeatureManager:
    """High-level feature flag management."""

    def __init__(self):
        self.store = FeatureStore()
        self._clients: Dict[str, FeatureClient] = {}

    def define(self, key: str) -> FeatureBuilder:
        """Define a new feature."""
        return FeatureBuilder(key)

    def register(self, feature: Feature) -> None:
        """Register a feature."""
        self.store.add(feature)

    def client(self, name: str = "default", context: Dict = None) -> FeatureClient:
        """Get or create a client."""
        if name not in self._clients:
            self._clients[name] = FeatureClient(self.store, context)
        return self._clients[name]

    def is_enabled(self, key: str, context: Dict = None) -> bool:
        """Quick check if feature is enabled."""
        return self.client().is_enabled(key, context)

    def get_value(self, key: str, context: Dict = None) -> Any:
        """Get feature value."""
        return self.client().get_value(key, context)

    def list_features(self, tags: List[str] = None) -> List[Dict[str, Any]]:
        """List all features."""
        return [
            {
                "key": f.key,
                "name": f.name,
                "state": f.state.value,
                "tags": f.tags
            }
            for f in self.store.list(tags)
        ]


# Example usage
def example_usage():
    """Example feature flag usage."""
    manager = FeatureManager()

    # Define features
    dark_mode = (
        manager.define("dark_mode")
        .name("Dark Mode")
        .description("Enable dark mode UI")
        .rollout(50)
        .tags("ui", "theme")
        .build()
    )
    manager.register(dark_mode)

    new_checkout = (
        manager.define("new_checkout")
        .name("New Checkout Flow")
        .off()
        .for_users("user-123", "user-456")
        .for_groups("beta_testers")
        .tags("checkout", "experiment")
        .build()
    )
    manager.register(new_checkout)

    pricing_ab = (
        manager.define("pricing_experiment")
        .name("Pricing A/B Test")
        .experiment()
        .variant("control", {"price": 99, "label": "$99"}, weight=50)
        .variant("treatment_a", {"price": 89, "label": "$89"}, weight=25)
        .variant("treatment_b", {"price": 79, "label": "$79"}, weight=25)
        .tags("pricing", "experiment")
        .build()
    )
    manager.register(pricing_ab)

    # Evaluate features
    user_context = {
        "user_id": "user-123",
        "groups": ["beta_testers"],
        "country": "US"
    }

    print(f"Dark mode enabled: {manager.is_enabled('dark_mode', user_context)}")
    print(f"New checkout enabled: {manager.is_enabled('new_checkout', user_context)}")

    pricing = manager.get_value("pricing_experiment", user_context)
    print(f"Pricing variant: {pricing}")

    # List features
    features = manager.list_features(tags=["experiment"])
    print(f"\nExperiment features: {features}")

    # Client with overrides
    client = manager.client("test")
    client.override("dark_mode", True)
    print(f"\nWith override - Dark mode: {client.is_enabled('dark_mode')}")

