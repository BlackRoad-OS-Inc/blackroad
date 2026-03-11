"""Tests for the foundation_system module."""

from __future__ import annotations

from foundation_system import (
    AI_Core,
    DistributedMemoryPalace,
    DomainManager,
    GitHubAutomation,
    InfrastructureManager,
    MobileSyncEngine,
    MultiModelOrchestrator,
    SSHOrchestrator,
    TeamNotificationSystem,
    UnifiedPortalSystem,
)


class TestDistributedMemoryPalace:

    def test_save_and_retrieve(self):
        mem = DistributedMemoryPalace()
        mem.save_context("key1", "value1")
        assert mem.retrieve_context("key1") == "value1"

    def test_retrieve_missing_returns_default(self):
        mem = DistributedMemoryPalace()
        assert mem.retrieve_context("missing") is None
        assert mem.retrieve_context("missing", "fallback") == "fallback"

    def test_overwrite(self):
        mem = DistributedMemoryPalace()
        mem.save_context("k", 1)
        mem.save_context("k", 2)
        assert mem.retrieve_context("k") == 2


class TestAICore:

    def test_process_request(self):
        mem = DistributedMemoryPalace()
        core = AI_Core(memory=mem)
        result = core.process_request("test input")
        assert "test input" in result


class TestServiceConnectors:

    def test_github_automation(self):
        gh = GitHubAutomation()
        assert "create repo" in gh.execute("create repo")

    def test_infrastructure_manager(self):
        infra = InfrastructureManager()
        assert "production" in infra.deploy("production")

    def test_mobile_sync(self):
        mobile = MobileSyncEngine()
        assert "sync" in mobile.sync().lower()

    def test_ssh_orchestrator(self):
        ssh = SSHOrchestrator()
        assert "ls" in ssh.run_command("ls -la")

    def test_domain_manager(self):
        dm = DomainManager()
        assert "example.com" in dm.register("example.com")

    def test_multi_model_orchestrator(self):
        mmo = MultiModelOrchestrator()
        assert "inference" in mmo.coordinate("inference")

    def test_team_notification(self):
        notifier = TeamNotificationSystem()
        assert "deploy" in notifier.notify("deploy complete")


class TestUnifiedPortalSystem:

    def test_status_report_keys(self):
        portal = UnifiedPortalSystem()
        report = portal.status_report()
        assert "ai_core" in report
        assert report["ai_core"] == "ready"
        for connector in ["github", "infrastructure", "mobile", "shellfish", "domain", "multimodel", "notify"]:
            assert connector in report
            assert report[connector] == "initialized"
