"""
RoadFeatures - Feature Flags System for BlackRoad
Progressive rollouts, A/B testing, and feature management.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Union
import asyncio
import hashlib
import json
import logging
import random
import re
import threading

logger = logging.getLogger(__name__)


class FlagStatus(str, Enum):
    """Feature flag status."""
    ENABLED = "enabled"
    DISABLED = "disabled"
    CONDITIONAL = "conditional"


class RolloutStrategy(str, Enum):
    """Rollout strategies."""
    PERCENTAGE = "percentage"
    USER_LIST = "user_list"
    GROUP = "group"
    ATTRIBUTE = "attribute"
    GRADUAL = "gradual"
    SCHEDULE = "schedule"


@dataclass
class RolloutRule:
    """A rule for feature rollout."""
    strategy: RolloutStrategy
    value: Any
    priority: int = 0
    name: Optional[str] = None
    description: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "strategy": self.strategy.value,
            "value": self.value,
            "priority": self.priority,
            "name": self.name,
            "description": self.description
        }


@dataclass
class Variant:
    """A variant for A/B testing."""
    name: str
    value: Any
    weight: int = 1
    description: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class FeatureFlag:
    """A feature flag definition."""
    key: str
    name: str
    description: str = ""
    status: FlagStatus = FlagStatus.DISABLED
    default_value: Any = False
    rules: List[RolloutRule] = field(default_factory=list)
    variants: List[Variant] = field(default_factory=list)
    tags: Set[str] = field(default_factory=set)
    owner: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.now)
    updated_at: datetime = field(default_factory=datetime.now)
    expires_at: Optional[datetime] = None
    metadata: Dict[str, Any] = field(default_factory=dict)

    def is_expired(self) -> bool:
        return self.expires_at is not None and datetime.now() > self.expires_at

    def to_dict(self) -> Dict[str, Any]:
        return {
            "key": self.key,
            "name": self.name,
            "description": self.description,
            "status": self.status.value,
            "default_value": self.default_value,
            "rules": [r.to_dict() for r in self.rules],
            "variants": [{"name": v.name, "value": v.value, "weight": v.weight} for v in self.variants],
            "tags": list(self.tags),
            "owner": self.owner,
            "created_at": self.created_at.isoformat(),
            "updated_at": self.updated_at.isoformat(),
            "expires_at": self.expires_at.isoformat() if self.expires_at else None
        }


@dataclass
class EvaluationContext:
    """Context for flag evaluation."""
    user_id: Optional[str] = None
    session_id: Optional[str] = None
    groups: List[str] = field(default_factory=list)
    attributes: Dict[str, Any] = field(default_factory=dict)
    timestamp: datetime = field(default_factory=datetime.now)

    def get_hash_key(self, flag_key: str) -> str:
        """Generate consistent hash for this context and flag."""
        key = f"{flag_key}:{self.user_id or self.session_id or 'anonymous'}"
        return hashlib.md5(key.encode()).hexdigest()


@dataclass
class EvaluationResult:
    """Result of flag evaluation."""
    flag_key: str
    enabled: bool
    value: Any
    variant: Optional[str] = None
    rule_matched: Optional[str] = None
    reason: str = ""
    timestamp: datetime = field(default_factory=datetime.now)


class FlagStore:
    """Storage for feature flags."""

    def __init__(self):
        self.flags: Dict[str, FeatureFlag] = {}
        self._lock = threading.RLock()

    def save(self, flag: FeatureFlag) -> None:
        """Save a feature flag."""
        with self._lock:
            flag.updated_at = datetime.now()
            self.flags[flag.key] = flag
            logger.info(f"Saved feature flag: {flag.key}")

    def get(self, key: str) -> Optional[FeatureFlag]:
        """Get a flag by key."""
        return self.flags.get(key)

    def delete(self, key: str) -> bool:
        """Delete a flag."""
        with self._lock:
            if key in self.flags:
                del self.flags[key]
                return True
            return False

    def list_all(self) -> List[FeatureFlag]:
        """List all flags."""
        return list(self.flags.values())

    def list_by_tag(self, tag: str) -> List[FeatureFlag]:
        """List flags by tag."""
        return [f for f in self.flags.values() if tag in f.tags]

    def list_by_owner(self, owner: str) -> List[FeatureFlag]:
        """List flags by owner."""
        return [f for f in self.flags.values() if f.owner == owner]


class RuleEvaluator:
    """Evaluate rollout rules."""

    def __init__(self):
        self.custom_evaluators: Dict[str, Callable[[Any, EvaluationContext], bool]] = {}

    def register_evaluator(self, strategy: str, evaluator: Callable) -> None:
        """Register custom rule evaluator."""
        self.custom_evaluators[strategy] = evaluator

    def evaluate(self, rule: RolloutRule, context: EvaluationContext, flag_key: str) -> bool:
        """Evaluate a single rule."""
        if rule.strategy == RolloutStrategy.PERCENTAGE:
            return self._evaluate_percentage(rule.value, context, flag_key)

        elif rule.strategy == RolloutStrategy.USER_LIST:
            return self._evaluate_user_list(rule.value, context)

        elif rule.strategy == RolloutStrategy.GROUP:
            return self._evaluate_group(rule.value, context)

        elif rule.strategy == RolloutStrategy.ATTRIBUTE:
            return self._evaluate_attribute(rule.value, context)

        elif rule.strategy == RolloutStrategy.SCHEDULE:
            return self._evaluate_schedule(rule.value, context)

        elif rule.strategy == RolloutStrategy.GRADUAL:
            return self._evaluate_gradual(rule.value, context, flag_key)

        elif rule.strategy.value in self.custom_evaluators:
            return self.custom_evaluators[rule.strategy.value](rule.value, context)

        return False

    def _evaluate_percentage(self, percentage: float, context: EvaluationContext, flag_key: str) -> bool:
        """Evaluate percentage rollout."""
        hash_key = context.get_hash_key(flag_key)
        hash_value = int(hash_key[:8], 16) % 100
        return hash_value < percentage

    def _evaluate_user_list(self, users: List[str], context: EvaluationContext) -> bool:
        """Evaluate user list rule."""
        return context.user_id in users

    def _evaluate_group(self, groups: List[str], context: EvaluationContext) -> bool:
        """Evaluate group membership."""
        return bool(set(groups) & set(context.groups))

    def _evaluate_attribute(self, conditions: Dict[str, Any], context: EvaluationContext) -> bool:
        """Evaluate attribute conditions."""
        for attr, condition in conditions.items():
            value = context.attributes.get(attr)

            if isinstance(condition, dict):
                if "$eq" in condition and value != condition["$eq"]:
                    return False
                if "$ne" in condition and value == condition["$ne"]:
                    return False
                if "$gt" in condition and not (value and value > condition["$gt"]):
                    return False
                if "$gte" in condition and not (value and value >= condition["$gte"]):
                    return False
                if "$lt" in condition and not (value and value < condition["$lt"]):
                    return False
                if "$lte" in condition and not (value and value <= condition["$lte"]):
                    return False
                if "$in" in condition and value not in condition["$in"]:
                    return False
                if "$nin" in condition and value in condition["$nin"]:
                    return False
                if "$regex" in condition and not re.match(condition["$regex"], str(value or "")):
                    return False
            else:
                if value != condition:
                    return False

        return True

    def _evaluate_schedule(self, schedule: Dict[str, str], context: EvaluationContext) -> bool:
        """Evaluate schedule-based rule."""
        now = context.timestamp

        if "start" in schedule:
            start = datetime.fromisoformat(schedule["start"])
            if now < start:
                return False

        if "end" in schedule:
            end = datetime.fromisoformat(schedule["end"])
            if now > end:
                return False

        if "days" in schedule:
            if now.weekday() not in schedule["days"]:
                return False

        if "hours" in schedule:
            hours = schedule["hours"]
            if now.hour < hours.get("start", 0) or now.hour >= hours.get("end", 24):
                return False

        return True

    def _evaluate_gradual(self, config: Dict[str, Any], context: EvaluationContext, flag_key: str) -> bool:
        """Evaluate gradual rollout."""
        start_percentage = config.get("start", 0)
        end_percentage = config.get("end", 100)
        start_date = datetime.fromisoformat(config["start_date"])
        end_date = datetime.fromisoformat(config["end_date"])

        now = context.timestamp
        if now < start_date:
            current_percentage = start_percentage
        elif now > end_date:
            current_percentage = end_percentage
        else:
            progress = (now - start_date) / (end_date - start_date)
            current_percentage = start_percentage + progress * (end_percentage - start_percentage)

        return self._evaluate_percentage(current_percentage, context, flag_key)


class FeatureFlagService:
    """Main feature flag service."""

    def __init__(self, store: Optional[FlagStore] = None):
        self.store = store or FlagStore()
        self.evaluator = RuleEvaluator()
        self.hooks: List[Callable[[EvaluationResult], None]] = []
        self.overrides: Dict[str, Dict[str, Any]] = {}  # flag_key -> {user_id -> value}
        self._cache: Dict[str, Tuple[EvaluationResult, datetime]] = {}
        self._cache_ttl = 60  # seconds

    def add_hook(self, hook: Callable[[EvaluationResult], None]) -> None:
        """Add evaluation hook."""
        self.hooks.append(hook)

    def set_override(self, flag_key: str, user_id: str, value: Any) -> None:
        """Set user-specific override."""
        if flag_key not in self.overrides:
            self.overrides[flag_key] = {}
        self.overrides[flag_key][user_id] = value

    def clear_override(self, flag_key: str, user_id: str) -> None:
        """Clear user-specific override."""
        if flag_key in self.overrides:
            self.overrides[flag_key].pop(user_id, None)

    def create_flag(
        self,
        key: str,
        name: str,
        description: str = "",
        default_value: Any = False,
        status: FlagStatus = FlagStatus.DISABLED,
        **kwargs
    ) -> FeatureFlag:
        """Create a new feature flag."""
        flag = FeatureFlag(
            key=key,
            name=name,
            description=description,
            default_value=default_value,
            status=status,
            **kwargs
        )
        self.store.save(flag)
        return flag

    def add_rule(self, flag_key: str, rule: RolloutRule) -> bool:
        """Add rule to flag."""
        flag = self.store.get(flag_key)
        if not flag:
            return False

        flag.rules.append(rule)
        flag.rules.sort(key=lambda r: r.priority, reverse=True)
        self.store.save(flag)
        return True

    def add_variant(self, flag_key: str, variant: Variant) -> bool:
        """Add variant to flag for A/B testing."""
        flag = self.store.get(flag_key)
        if not flag:
            return False

        flag.variants.append(variant)
        self.store.save(flag)
        return True

    def evaluate(self, flag_key: str, context: Optional[EvaluationContext] = None) -> EvaluationResult:
        """Evaluate a feature flag."""
        context = context or EvaluationContext()
        flag = self.store.get(flag_key)

        # Check cache
        cache_key = f"{flag_key}:{context.user_id or 'anonymous'}"
        if cache_key in self._cache:
            cached, cached_at = self._cache[cache_key]
            if (datetime.now() - cached_at).seconds < self._cache_ttl:
                return cached

        result = self._evaluate_flag(flag, flag_key, context)

        # Cache result
        self._cache[cache_key] = (result, datetime.now())

        # Call hooks
        for hook in self.hooks:
            try:
                hook(result)
            except Exception as e:
                logger.error(f"Flag evaluation hook error: {e}")

        return result

    def _evaluate_flag(
        self,
        flag: Optional[FeatureFlag],
        flag_key: str,
        context: EvaluationContext
    ) -> EvaluationResult:
        """Internal flag evaluation."""
        # Flag not found
        if not flag:
            return EvaluationResult(
                flag_key=flag_key,
                enabled=False,
                value=False,
                reason="flag_not_found"
            )

        # Check expiration
        if flag.is_expired():
            return EvaluationResult(
                flag_key=flag_key,
                enabled=False,
                value=flag.default_value,
                reason="flag_expired"
            )

        # Check overrides
        if flag_key in self.overrides and context.user_id in self.overrides[flag_key]:
            override_value = self.overrides[flag_key][context.user_id]
            return EvaluationResult(
                flag_key=flag_key,
                enabled=bool(override_value),
                value=override_value,
                reason="override"
            )

        # Check status
        if flag.status == FlagStatus.DISABLED:
            return EvaluationResult(
                flag_key=flag_key,
                enabled=False,
                value=flag.default_value,
                reason="flag_disabled"
            )

        if flag.status == FlagStatus.ENABLED:
            return self._get_enabled_result(flag, context)

        # Conditional evaluation
        for rule in flag.rules:
            if self.evaluator.evaluate(rule, context, flag_key):
                return self._get_enabled_result(flag, context, rule.name)

        return EvaluationResult(
            flag_key=flag_key,
            enabled=False,
            value=flag.default_value,
            reason="no_rules_matched"
        )

    def _get_enabled_result(
        self,
        flag: FeatureFlag,
        context: EvaluationContext,
        rule_name: Optional[str] = None
    ) -> EvaluationResult:
        """Get result for enabled flag (including variant selection)."""
        # If variants exist, select one
        if flag.variants:
            variant = self._select_variant(flag, context)
            return EvaluationResult(
                flag_key=flag.key,
                enabled=True,
                value=variant.value,
                variant=variant.name,
                rule_matched=rule_name,
                reason="variant_selected"
            )

        return EvaluationResult(
            flag_key=flag.key,
            enabled=True,
            value=flag.default_value if flag.default_value is not False else True,
            rule_matched=rule_name,
            reason="flag_enabled"
        )

    def _select_variant(self, flag: FeatureFlag, context: EvaluationContext) -> Variant:
        """Select variant based on weights."""
        hash_key = context.get_hash_key(flag.key)
        hash_value = int(hash_key[:8], 16)

        total_weight = sum(v.weight for v in flag.variants)
        threshold = hash_value % total_weight

        cumulative = 0
        for variant in flag.variants:
            cumulative += variant.weight
            if threshold < cumulative:
                return variant

        return flag.variants[-1]

    def is_enabled(self, flag_key: str, context: Optional[EvaluationContext] = None) -> bool:
        """Quick check if flag is enabled."""
        return self.evaluate(flag_key, context).enabled

    def get_value(self, flag_key: str, context: Optional[EvaluationContext] = None) -> Any:
        """Get flag value."""
        return self.evaluate(flag_key, context).value

    def get_variant(self, flag_key: str, context: Optional[EvaluationContext] = None) -> Optional[str]:
        """Get selected variant name."""
        return self.evaluate(flag_key, context).variant

    def get_all_flags(self, context: Optional[EvaluationContext] = None) -> Dict[str, EvaluationResult]:
        """Evaluate all flags for context."""
        results = {}
        for flag in self.store.list_all():
            results[flag.key] = self.evaluate(flag.key, context)
        return results


# Decorator for feature-flagged functions
def feature_flag(
    flag_key: str,
    default: Any = None,
    context_extractor: Optional[Callable] = None
):
    """Decorator to conditionally execute based on feature flag."""
    def decorator(func: Callable) -> Callable:
        def wrapper(*args, **kwargs):
            from functools import wraps
            service = FeatureFlagService()  # Would use singleton in practice

            context = None
            if context_extractor:
                context = context_extractor(*args, **kwargs)

            if service.is_enabled(flag_key, context):
                return func(*args, **kwargs)
            elif default is not None:
                return default() if callable(default) else default
            return None

        return wrapper
    return decorator


# Example usage
def example_usage():
    """Example feature flag usage."""
    service = FeatureFlagService()

    # Create feature flag
    service.create_flag(
        key="new_checkout",
        name="New Checkout Flow",
        description="Redesigned checkout experience",
        status=FlagStatus.CONDITIONAL
    )

    # Add percentage rollout
    service.add_rule("new_checkout", RolloutRule(
        strategy=RolloutStrategy.PERCENTAGE,
        value=25,
        name="25% rollout",
        priority=1
    ))

    # Add beta users rule
    service.add_rule("new_checkout", RolloutRule(
        strategy=RolloutStrategy.GROUP,
        value=["beta_testers"],
        name="Beta testers",
        priority=10
    ))

    # Create A/B test
    service.create_flag(
        key="button_color",
        name="Button Color Test",
        status=FlagStatus.ENABLED
    )

    service.add_variant("button_color", Variant(name="blue", value="#0066FF", weight=50))
    service.add_variant("button_color", Variant(name="green", value="#00FF66", weight=50))

    # Evaluate
    context = EvaluationContext(
        user_id="user-123",
        groups=["beta_testers"],
        attributes={"plan": "premium"}
    )

    result = service.evaluate("new_checkout", context)
    print(f"New checkout enabled: {result.enabled}")
    print(f"Reason: {result.reason}")

    color_result = service.evaluate("button_color", context)
    print(f"Button color variant: {color_result.variant}")
    print(f"Button color value: {color_result.value}")
