#!/usr/bin/env python3
"""
CLI for creating GitHub issues.

Reads JSON payload from stdin with the following schema:
{
    "repository": "owner/repo",
    "title": "Issue title",
    "body": "Issue description",
    "labels": ["bug", "enhancement"],  // optional
    "assignees": ["username"],  // optional
    "milestone": 1  // optional milestone number
}

Requires GITHUB_TOKEN environment variable for authentication.
"""

import json
import logging
import os
import sys
from typing import Any, Dict, List, Optional

import requests

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger(__name__)


class GitHubAPIError(Exception):
    """Exception raised for GitHub API errors."""
    pass


def create_issue(
    repository: str,
    title: str,
    body: str,
    labels: Optional[List[str]] = None,
    assignees: Optional[List[str]] = None,
    milestone: Optional[int] = None,
    token: Optional[str] = None
) -> Dict[str, Any]:
    """
    Create a GitHub issue.

    Args:
        repository: Repository in format "owner/repo"
        title: Issue title
        body: Issue description
        labels: Optional list of label names
        assignees: Optional list of GitHub usernames
        milestone: Optional milestone number
        token: GitHub API token (defaults to GITHUB_TOKEN env var)

    Returns:
        Issue data from GitHub API

    Raises:
        GitHubAPIError: If issue creation fails
    """
    token = token or os.getenv('GITHUB_TOKEN')
    if not token:
        raise GitHubAPIError("GITHUB_TOKEN environment variable not set")

    # Parse repository
    try:
        owner, repo = repository.split('/', 1)
    except ValueError:
        raise GitHubAPIError(f"Invalid repository format: {repository}. Expected 'owner/repo'")

    # Build API request
    url = f"https://api.github.com/repos/{owner}/{repo}/issues"
    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'X-GitHub-Api-Version': '2022-11-28'
    }

    payload = {
        'title': title,
        'body': body
    }

    if labels:
        payload['labels'] = labels

    if assignees:
        payload['assignees'] = assignees

    if milestone is not None:
        payload['milestone'] = milestone

    # Make API request
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()

        issue = response.json()
        logger.info(f"Created issue #{issue['number']}: {issue['html_url']}")
        return issue

    except requests.exceptions.HTTPError as e:
        error_msg = f"GitHub API error: {e}"
        if e.response is not None:
            try:
                error_details = e.response.json()
                error_msg = f"GitHub API error: {error_details.get('message', str(e))}"
            except json.JSONDecodeError:
                pass
        raise GitHubAPIError(error_msg)

    except requests.exceptions.RequestException as e:
        raise GitHubAPIError(f"Request failed: {e}")


def main() -> None:
    """Main entry point for CLI."""
    try:
        # Read payload from stdin
        payload = json.load(sys.stdin)

        # Validate required fields
        repository = payload.get('repository')
        title = payload.get('title')
        body = payload.get('body', '')

        if not repository:
            logger.error("Missing required field: repository")
            sys.exit(1)

        if not title:
            logger.error("Missing required field: title")
            sys.exit(1)

        # Extract optional fields
        labels = payload.get('labels')
        assignees = payload.get('assignees')
        milestone = payload.get('milestone')

        # Create issue
        issue = create_issue(
            repository=repository,
            title=title,
            body=body,
            labels=labels,
            assignees=assignees,
            milestone=milestone
        )

        # Output result
        result = {
            'success': True,
            'issue_number': issue['number'],
            'issue_url': issue['html_url'],
            'issue_id': issue['id']
        }
        print(json.dumps(result, indent=2))

    except json.JSONDecodeError as e:
        logger.error(f"Invalid JSON input: {e}")
        sys.exit(1)

    except GitHubAPIError as e:
        logger.error(str(e))
        result = {
            'success': False,
            'error': str(e)
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)

    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        result = {
            'success': False,
            'error': str(e)
        }
        print(json.dumps(result, indent=2))
        sys.exit(1)


if __name__ == "__main__":
    main()
