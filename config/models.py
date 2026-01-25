"""Configuration models validated with Pydantic."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Dict, List

import yaml
from pydantic import BaseModel, Field, field_validator


class UserConfig(BaseModel):
    """User definition with role and permissions."""

    id: str
    role: str
    permissions: List[str] = Field(default_factory=list)


class UsersConfig(BaseModel):
    """Collection of user definitions."""

    users: List[UserConfig]


class ApprovalRuleConfig(BaseModel):
    """Approval rule for a policy."""

    requires_approval: bool = False
    approvers: List[str] = Field(default_factory=list)
    sla_hours: int | None = None

    @field_validator("sla_hours")
    @classmethod
    def validate_sla(cls, value: int | None) -> int | None:
        if value is not None and value <= 0:
            raise ValueError("sla_hours must be positive")
        return value


class ApprovalsConfig(BaseModel):
    """Mapping of policy names to approval rules."""

    policies: Dict[str, ApprovalRuleConfig] = Field(default_factory=dict)


class TreasuryConfig(BaseModel):
    """Treasury configuration options."""

    cash_floor: int
    hedge_policies: List[Dict[str, str]]


class CloseDeadline(BaseModel):
    """Deadline entry for the close calendar."""

    name: str
    due_days_from_period_end: int


class CloseCalendarConfig(BaseModel):
    """Calendar of close milestones."""

    deadlines: List[CloseDeadline]


class InventoryTarget(BaseModel):
    """Inventory target for a SKU."""

    sku: str
    min: int
    max: int


class LogisticsPartner(BaseModel):
    """Logistics partner configuration."""

    carrier: str
    lanes: List[str]


class SopConfig(BaseModel):
    """Sales and operations planning configuration."""

    planning_horizon_weeks: int
    inventory_targets: List[InventoryTarget]
    logistics_partners: List[LogisticsPartner]


class ConfigurationBundle(BaseModel):
    """Wrapper around all configuration sections."""

    users: UsersConfig
    approvals: ApprovalsConfig
    treasury: TreasuryConfig
    close_calendar: CloseCalendarConfig
    sop: SopConfig

    @classmethod
    def from_files(cls, base_path: Path) -> "ConfigurationBundle":
        """Load configuration files from *base_path*."""

        users_data = json.loads(
            (base_path / "users.json").read_text(encoding="utf-8")
        )
        approvals_data = yaml.safe_load(
            (base_path / "approvals.yaml").read_text(encoding="utf-8")
        )
        treasury_data = yaml.safe_load(
            (base_path / "finance" / "treasury.yaml").read_text(encoding="utf-8")
        )
        close_data = yaml.safe_load(
            (base_path / "close" / "calendar.yaml").read_text(encoding="utf-8")
        )
        sop_data = yaml.safe_load(
            (base_path / "supply" / "sop.yaml").read_text(encoding="utf-8")
        )
        return cls(
            users=UsersConfig.model_validate(users_data),
            approvals=ApprovalsConfig.model_validate(approvals_data),
            treasury=TreasuryConfig.model_validate(treasury_data),
            close_calendar=CloseCalendarConfig.model_validate(close_data),
            sop=SopConfig.model_validate(sop_data),
        )

    def validate(self) -> None:
        """Trigger validation for the bundle."""

        type(self).model_validate(self.model_dump())
