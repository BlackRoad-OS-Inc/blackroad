"""
Safety Validator - Command allowlist/blocklist and validation
"""
import re
from typing import Optional
from pydantic import BaseModel
import structlog

from models import Command, RiskLevel

logger = structlog.get_logger()


class SafetyConfig(BaseModel):
    """Configuration for safety rules"""
    # Patterns that are always blocked
    blocklist_patterns: list[str] = [
        r"rm\s+-rf\s+/",           # rm -rf /
        r"rm\s+-rf\s+/\*",         # rm -rf /*
        r"rm\s+-rf\s+~",           # rm -rf ~
        r"rm\s+-rf\s+\$HOME",      # rm -rf $HOME
        r"mkfs\.",                  # Format filesystem
        r"dd\s+if=.+of=/dev/",     # Direct disk writes
        r":\(\)\{:\|:&\};:",       # Fork bomb
        r">\s*/dev/sd",            # Write to raw disk
        r"chmod\s+-R\s+777\s+/",   # Recursive 777 on root
        r"curl.+\|\s*bash",        # Pipe curl to bash (be careful)
        r"wget.+\|\s*bash",        # Pipe wget to bash
        r"sudo\s+rm\s+-rf",        # Sudo rm -rf
        r"/etc/passwd",            # Password file access
        r"/etc/shadow",            # Shadow file access
        r"iptables\s+-F",          # Flush iptables
        r"systemctl\s+stop\s+ssh", # Stop SSH service
    ]

    # Patterns that require approval
    approval_required_patterns: list[str] = [
        r"reboot",
        r"shutdown",
        r"systemctl\s+(restart|stop|disable)",
        r"apt\s+(install|remove|purge|upgrade|dist-upgrade)",
        r"apt-get\s+(install|remove|purge|upgrade|dist-upgrade)",
        r"pip\s+install",
        r"npm\s+install\s+-g",
        r"docker\s+(rm|rmi|system\s+prune)",
        r"git\s+push\s+.*--force",
        r"DROP\s+TABLE",
        r"DELETE\s+FROM",
        r"TRUNCATE",
    ]

    # Allowed safe command patterns (for quick exec without LLM)
    safe_patterns: list[str] = [
        r"^ls\s",
        r"^pwd$",
        r"^whoami$",
        r"^date$",
        r"^uptime$",
        r"^df\s",
        r"^free\s",
        r"^cat\s",
        r"^head\s",
        r"^tail\s",
        r"^grep\s",
        r"^find\s",
        r"^git\s+(status|log|diff|branch|fetch|pull)",
        r"^docker\s+(ps|images|logs)",
        r"^systemctl\s+status",
        r"^journalctl",
    ]


class ValidationResult(BaseModel):
    """Result of command validation"""
    valid: bool
    blocked: bool = False
    requires_approval: bool = False
    risk_level: RiskLevel = RiskLevel.LOW
    reason: Optional[str] = None
    matched_pattern: Optional[str] = None


class SafetyValidator:
    """
    Validates commands against safety rules.
    """

    def __init__(self, config: Optional[SafetyConfig] = None):
        self.config = config or SafetyConfig()
        self._compile_patterns()

    def _compile_patterns(self):
        """Compile regex patterns for efficiency"""
        self._blocklist = [re.compile(p, re.IGNORECASE) for p in self.config.blocklist_patterns]
        self._approval = [re.compile(p, re.IGNORECASE) for p in self.config.approval_required_patterns]
        self._safe = [re.compile(p, re.IGNORECASE) for p in self.config.safe_patterns]

    def validate_command(self, command: str) -> ValidationResult:
        """
        Validate a single command string.
        Returns validation result with risk assessment.
        """
        # Check blocklist first
        for i, pattern in enumerate(self._blocklist):
            if pattern.search(command):
                logger.warning("command_blocked", command=command, pattern=self.config.blocklist_patterns[i])
                return ValidationResult(
                    valid=False,
                    blocked=True,
                    risk_level=RiskLevel.HIGH,
                    reason=f"Command matches blocked pattern: {self.config.blocklist_patterns[i]}",
                    matched_pattern=self.config.blocklist_patterns[i],
                )

        # Check if approval required
        for i, pattern in enumerate(self._approval):
            if pattern.search(command):
                return ValidationResult(
                    valid=True,
                    requires_approval=True,
                    risk_level=RiskLevel.MEDIUM,
                    reason=f"Command requires approval: {self.config.approval_required_patterns[i]}",
                    matched_pattern=self.config.approval_required_patterns[i],
                )

        # Check if explicitly safe
        for i, pattern in enumerate(self._safe):
            if pattern.search(command):
                return ValidationResult(
                    valid=True,
                    risk_level=RiskLevel.LOW,
                    reason="Command matches safe pattern",
                    matched_pattern=self.config.safe_patterns[i],
                )

        # Default: valid but medium risk (unknown command)
        return ValidationResult(
            valid=True,
            requires_approval=True,  # Default to requiring approval for unknown commands
            risk_level=RiskLevel.MEDIUM,
            reason="Unknown command - requires approval",
        )

    def validate_commands(self, commands: list[Command]) -> tuple[bool, list[ValidationResult]]:
        """
        Validate a list of commands.
        Returns (all_valid, results) tuple.
        """
        results = []
        all_valid = True
        any_requires_approval = False

        for cmd in commands:
            result = self.validate_command(cmd.run)
            results.append(result)
            if not result.valid:
                all_valid = False
            if result.requires_approval:
                any_requires_approval = True

        return all_valid, results

    def get_risk_level(self, commands: list[Command]) -> RiskLevel:
        """
        Get overall risk level for a set of commands.
        """
        _, results = self.validate_commands(commands)

        if any(r.risk_level == RiskLevel.HIGH for r in results):
            return RiskLevel.HIGH
        if any(r.risk_level == RiskLevel.MEDIUM for r in results):
            return RiskLevel.MEDIUM
        return RiskLevel.LOW

    def should_require_approval(self, commands: list[Command]) -> bool:
        """
        Determine if the command set should require user approval.
        """
        _, results = self.validate_commands(commands)
        return any(r.requires_approval for r in results)


# Global validator instance
safety = SafetyValidator()
