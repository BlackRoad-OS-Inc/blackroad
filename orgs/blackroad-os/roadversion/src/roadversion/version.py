"""
RoadVersion - Version Control & Release Management for BlackRoad
Semantic versioning, changelog generation, and release automation.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Tuple
import hashlib
import json
import logging
import re
import threading

logger = logging.getLogger(__name__)


class VersionBump(str, Enum):
    """Version bump types."""
    MAJOR = "major"
    MINOR = "minor"
    PATCH = "patch"
    PRERELEASE = "prerelease"
    BUILD = "build"


class ReleaseStatus(str, Enum):
    """Release status."""
    DRAFT = "draft"
    PENDING = "pending"
    PUBLISHED = "published"
    DEPRECATED = "deprecated"


class ChangeType(str, Enum):
    """Types of changes."""
    FEATURE = "feat"
    FIX = "fix"
    DOCS = "docs"
    STYLE = "style"
    REFACTOR = "refactor"
    PERF = "perf"
    TEST = "test"
    BUILD = "build"
    CI = "ci"
    CHORE = "chore"
    BREAKING = "breaking"


@dataclass
class SemanticVersion:
    """Semantic version."""
    major: int
    minor: int
    patch: int
    prerelease: Optional[str] = None
    build: Optional[str] = None

    def __str__(self) -> str:
        version = f"{self.major}.{self.minor}.{self.patch}"
        if self.prerelease:
            version += f"-{self.prerelease}"
        if self.build:
            version += f"+{self.build}"
        return version

    @staticmethod
    def parse(version_str: str) -> "SemanticVersion":
        """Parse version string."""
        pattern = r"^v?(\d+)\.(\d+)\.(\d+)(?:-([a-zA-Z0-9.-]+))?(?:\+([a-zA-Z0-9.-]+))?$"
        match = re.match(pattern, version_str)
        if not match:
            raise ValueError(f"Invalid version: {version_str}")
        
        return SemanticVersion(
            major=int(match.group(1)),
            minor=int(match.group(2)),
            patch=int(match.group(3)),
            prerelease=match.group(4),
            build=match.group(5)
        )

    def bump(self, bump_type: VersionBump, prerelease_label: str = "alpha") -> "SemanticVersion":
        """Bump version."""
        if bump_type == VersionBump.MAJOR:
            return SemanticVersion(self.major + 1, 0, 0)
        elif bump_type == VersionBump.MINOR:
            return SemanticVersion(self.major, self.minor + 1, 0)
        elif bump_type == VersionBump.PATCH:
            return SemanticVersion(self.major, self.minor, self.patch + 1)
        elif bump_type == VersionBump.PRERELEASE:
            if self.prerelease:
                # Increment prerelease number
                parts = self.prerelease.rsplit(".", 1)
                if len(parts) == 2 and parts[1].isdigit():
                    new_pre = f"{parts[0]}.{int(parts[1]) + 1}"
                else:
                    new_pre = f"{self.prerelease}.1"
            else:
                new_pre = f"{prerelease_label}.1"
            return SemanticVersion(self.major, self.minor, self.patch, new_pre)
        
        return self

    def __lt__(self, other: "SemanticVersion") -> bool:
        if self.major != other.major:
            return self.major < other.major
        if self.minor != other.minor:
            return self.minor < other.minor
        if self.patch != other.patch:
            return self.patch < other.patch
        # Prerelease versions have lower precedence
        if self.prerelease and not other.prerelease:
            return True
        if not self.prerelease and other.prerelease:
            return False
        return (self.prerelease or "") < (other.prerelease or "")


@dataclass
class ChangelogEntry:
    """A changelog entry."""
    change_type: ChangeType
    scope: Optional[str]
    description: str
    breaking: bool = False
    commit_hash: Optional[str] = None
    author: Optional[str] = None
    pr_number: Optional[int] = None
    timestamp: datetime = field(default_factory=datetime.now)


@dataclass
class Release:
    """A release."""
    version: SemanticVersion
    status: ReleaseStatus = ReleaseStatus.DRAFT
    changelog: List[ChangelogEntry] = field(default_factory=list)
    created_at: datetime = field(default_factory=datetime.now)
    published_at: Optional[datetime] = None
    tag: Optional[str] = None
    assets: List[str] = field(default_factory=list)
    notes: str = ""
    metadata: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "version": str(self.version),
            "status": self.status.value,
            "created_at": self.created_at.isoformat(),
            "published_at": self.published_at.isoformat() if self.published_at else None,
            "changes": len(self.changelog)
        }


class ChangelogGenerator:
    """Generate changelog from commits."""

    def __init__(self):
        self.commit_pattern = re.compile(
            r"^(?P<type>\w+)(?:\((?P<scope>[^)]+)\))?(?P<breaking>!)?: (?P<description>.+)$"
        )

    def parse_commit(self, message: str, commit_hash: str = None) -> Optional[ChangelogEntry]:
        """Parse conventional commit message."""
        lines = message.strip().split("\n")
        if not lines:
            return None

        match = self.commit_pattern.match(lines[0])
        if not match:
            return None

        try:
            change_type = ChangeType(match.group("type"))
        except ValueError:
            return None

        return ChangelogEntry(
            change_type=change_type,
            scope=match.group("scope"),
            description=match.group("description"),
            breaking=bool(match.group("breaking")) or "BREAKING CHANGE" in message,
            commit_hash=commit_hash
        )

    def generate_markdown(self, entries: List[ChangelogEntry], version: str) -> str:
        """Generate markdown changelog."""
        lines = [f"## [{version}] - {datetime.now().strftime('%Y-%m-%d')}\n"]

        # Group by type
        groups: Dict[str, List[ChangelogEntry]] = {}
        for entry in entries:
            key = entry.change_type.value
            if key not in groups:
                groups[key] = []
            groups[key].append(entry)

        type_titles = {
            "feat": "### Features",
            "fix": "### Bug Fixes",
            "docs": "### Documentation",
            "perf": "### Performance",
            "refactor": "### Refactoring",
            "breaking": "### BREAKING CHANGES"
        }

        # Breaking changes first
        breaking = [e for e in entries if e.breaking]
        if breaking:
            lines.append("\n### ⚠️ BREAKING CHANGES\n")
            for entry in breaking:
                scope = f"**{entry.scope}:** " if entry.scope else ""
                lines.append(f"- {scope}{entry.description}")

        for type_key, title in type_titles.items():
            if type_key in groups and type_key != "breaking":
                lines.append(f"\n{title}\n")
                for entry in groups[type_key]:
                    if not entry.breaking:  # Already listed above
                        scope = f"**{entry.scope}:** " if entry.scope else ""
                        commit = f" ({entry.commit_hash[:7]})" if entry.commit_hash else ""
                        lines.append(f"- {scope}{entry.description}{commit}")

        return "\n".join(lines)


class VersionStore:
    """Store for versions and releases."""

    def __init__(self):
        self.releases: Dict[str, Release] = {}  # version string -> release
        self.current_version: Optional[SemanticVersion] = None
        self._lock = threading.Lock()

    def save_release(self, release: Release) -> None:
        with self._lock:
            version_str = str(release.version)
            self.releases[version_str] = release
            if not self.current_version or release.version > self.current_version:
                self.current_version = release.version

    def get_release(self, version: str) -> Optional[Release]:
        return self.releases.get(version)

    def get_releases(self, limit: int = 50) -> List[Release]:
        releases = list(self.releases.values())
        return sorted(releases, key=lambda r: r.version, reverse=True)[:limit]

    def get_latest(self, stable_only: bool = True) -> Optional[Release]:
        releases = self.get_releases()
        for release in releases:
            if stable_only and release.version.prerelease:
                continue
            if release.status == ReleaseStatus.PUBLISHED:
                return release
        return releases[0] if releases else None


class VersionManager:
    """High-level version management."""

    def __init__(self, initial_version: str = "0.0.0"):
        self.store = VersionStore()
        self.changelog_generator = ChangelogGenerator()
        self.store.current_version = SemanticVersion.parse(initial_version)
        self._hooks: Dict[str, List[Callable]] = {
            "pre_release": [],
            "post_release": []
        }

    def add_hook(self, event: str, handler: Callable) -> None:
        if event in self._hooks:
            self._hooks[event].append(handler)

    def get_current_version(self) -> str:
        """Get current version string."""
        return str(self.store.current_version) if self.store.current_version else "0.0.0"

    def bump_version(self, bump_type: VersionBump, prerelease_label: str = "alpha") -> SemanticVersion:
        """Bump version and return new version."""
        current = self.store.current_version or SemanticVersion(0, 0, 0)
        new_version = current.bump(bump_type, prerelease_label)
        self.store.current_version = new_version
        return new_version

    def create_release(
        self,
        version: Optional[str] = None,
        changelog: List[ChangelogEntry] = None,
        notes: str = ""
    ) -> Release:
        """Create a new release."""
        if version:
            ver = SemanticVersion.parse(version)
        else:
            ver = self.store.current_version or SemanticVersion(0, 1, 0)

        release = Release(
            version=ver,
            changelog=changelog or [],
            notes=notes,
            tag=f"v{ver}"
        )

        self.store.save_release(release)
        return release

    def publish_release(self, version: str) -> bool:
        """Publish a release."""
        release = self.store.get_release(version)
        if not release:
            return False

        # Run pre-release hooks
        for hook in self._hooks.get("pre_release", []):
            try:
                hook(release)
            except Exception as e:
                logger.error(f"Pre-release hook failed: {e}")
                return False

        release.status = ReleaseStatus.PUBLISHED
        release.published_at = datetime.now()

        # Run post-release hooks
        for hook in self._hooks.get("post_release", []):
            try:
                hook(release)
            except Exception as e:
                logger.error(f"Post-release hook error: {e}")

        return True

    def deprecate_release(self, version: str) -> bool:
        """Deprecate a release."""
        release = self.store.get_release(version)
        if release:
            release.status = ReleaseStatus.DEPRECATED
            return True
        return False

    def add_changelog_entry(
        self,
        version: str,
        change_type: str,
        description: str,
        scope: Optional[str] = None,
        breaking: bool = False
    ) -> bool:
        """Add changelog entry to release."""
        release = self.store.get_release(version)
        if not release:
            return False

        entry = ChangelogEntry(
            change_type=ChangeType(change_type),
            scope=scope,
            description=description,
            breaking=breaking
        )
        release.changelog.append(entry)
        return True

    def generate_changelog(self, version: str) -> str:
        """Generate changelog markdown for release."""
        release = self.store.get_release(version)
        if not release:
            return ""
        
        return self.changelog_generator.generate_markdown(release.changelog, version)

    def get_releases(self, limit: int = 50) -> List[Dict[str, Any]]:
        """Get release history."""
        releases = self.store.get_releases(limit)
        return [r.to_dict() for r in releases]

    def get_latest_version(self, stable_only: bool = True) -> Optional[str]:
        """Get latest version."""
        release = self.store.get_latest(stable_only)
        return str(release.version) if release else None

    def compare_versions(self, v1: str, v2: str) -> int:
        """Compare two versions. Returns -1, 0, or 1."""
        ver1 = SemanticVersion.parse(v1)
        ver2 = SemanticVersion.parse(v2)
        
        if ver1 < ver2:
            return -1
        elif ver1 == ver2:
            return 0
        else:
            return 1

    def is_upgrade(self, from_version: str, to_version: str) -> bool:
        """Check if to_version is an upgrade from from_version."""
        return self.compare_versions(from_version, to_version) < 0

    def suggest_bump(self, changes: List[ChangelogEntry]) -> VersionBump:
        """Suggest version bump based on changes."""
        if any(c.breaking for c in changes):
            return VersionBump.MAJOR
        if any(c.change_type == ChangeType.FEATURE for c in changes):
            return VersionBump.MINOR
        return VersionBump.PATCH


# Example usage
def example_usage():
    """Example version management usage."""
    manager = VersionManager(initial_version="1.0.0")

    # Bump version
    new_version = manager.bump_version(VersionBump.MINOR)
    print(f"New version: {new_version}")

    # Create release
    release = manager.create_release(
        notes="This release includes new features and bug fixes."
    )

    # Add changelog entries
    manager.add_changelog_entry(
        str(release.version),
        "feat",
        "Add user authentication",
        scope="auth"
    )
    manager.add_changelog_entry(
        str(release.version),
        "fix",
        "Fix memory leak in cache",
        scope="cache"
    )
    manager.add_changelog_entry(
        str(release.version),
        "feat",
        "New API endpoint for bulk operations",
        scope="api",
        breaking=True
    )

    # Generate changelog
    changelog = manager.generate_changelog(str(release.version))
    print(f"\nChangelog:\n{changelog}")

    # Publish
    manager.publish_release(str(release.version))

    # Get releases
    releases = manager.get_releases()
    print(f"\nReleases: {releases}")

    # Suggest bump
    changes = release.changelog
    suggested = manager.suggest_bump(changes)
    print(f"\nSuggested bump: {suggested.value}")
