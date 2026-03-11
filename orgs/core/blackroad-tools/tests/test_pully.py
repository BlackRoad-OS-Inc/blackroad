"""Tests for pully — PR classifier."""

import json
import pytest
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from pully import PullRequest, from_pr_json, classify_pr, format_output


class TestFromPrJson:
    def test_full_object(self):
        obj = {"title": "Fix bug", "body": "Fixes #42", "author": "alexa",
               "files": ["src/main.py"], "labels": ["bug"]}
        pr = from_pr_json(obj)
        assert pr.title == "Fix bug"
        assert pr.author == "alexa"
        assert pr.files == ["src/main.py"]

    def test_empty_object(self):
        pr = from_pr_json({})
        assert pr.title == ""
        assert pr.files == []
        assert pr.labels == []


class TestClassifyPr:
    def test_keyword_label(self):
        pr = PullRequest("fix: resolve crash", "bug fix", "dev", [], [])
        config = {"label_rules": [{"label": "bugfix", "keywords": ["fix", "bug"]}]}
        result = classify_pr(pr, config)
        assert "bugfix" in result["labels"]

    def test_file_rule(self):
        pr = PullRequest("update docs", "", "dev", ["docs/README.md"], [])
        config = {"file_rules": [{"pattern": "^docs/", "label": "documentation"}]}
        result = classify_pr(pr, config)
        assert "documentation" in result["labels"]

    def test_reviewer_by_label(self):
        pr = PullRequest("fix crash", "bug", "dev", [], ["security"])
        config = {"reviewer_rules": [{"reviewer": "secteam", "labels": ["security"]}]}
        result = classify_pr(pr, config)
        assert "secteam" in result["reviewers"]

    def test_reviewer_by_path(self):
        pr = PullRequest("update", "", "dev", ["src/auth.py"], [])
        config = {"reviewer_rules": [{"reviewer": "secteam", "paths": ["^src/auth"]}]}
        result = classify_pr(pr, config)
        assert "secteam" in result["reviewers"]

    def test_checklist_tests_added(self):
        pr = PullRequest("add feature", "", "dev", ["tests/test_new.py"], [])
        result = classify_pr(pr, {})
        checklist = dict(result["checklist"])
        assert checklist["Tests added/updated"] is True

    def test_checklist_description_filled(self):
        pr = PullRequest("title", "some body", "dev", [], [])
        result = classify_pr(pr, {})
        checklist = dict(result["checklist"])
        assert checklist["PR description filled"] is True

    def test_checklist_empty_body(self):
        pr = PullRequest("title", "", "dev", [], [])
        result = classify_pr(pr, {})
        checklist = dict(result["checklist"])
        assert checklist["PR description filled"] is False

    def test_empty_config(self):
        pr = PullRequest("title", "body", "author", [], [])
        result = classify_pr(pr, {})
        assert result["labels"] == []
        assert result["reviewers"] == []


class TestFormatOutput:
    def test_format(self):
        classification = {
            "labels": ["bug"],
            "reviewers": ["alice"],
            "checklist": [("Tests added/updated", True), ("Code builds locally", False)],
        }
        output = format_output(classification)
        parsed = json.loads(output)
        assert parsed["labels"] == ["bug"]
        assert "[x] Tests added/updated" in parsed["checklist"]
        assert "[ ] Code builds locally" in parsed["checklist"]
