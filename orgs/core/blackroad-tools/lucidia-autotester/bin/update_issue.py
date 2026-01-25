#!/usr/bin/env python3
"""
CLI for updating GitHub issues.

Reads JSON payload from stdin with the following schema:
{
    "repository": "owner/repo",
    "issue_number": 123,
    "title": "Updated title",  // optional
    "body": "Updated description",  // optional
    "state": "open" or "closed",  // optional
    "labels": ["bug"],  // optional
    "assignees": ["username"],  // optional
    "milestone": 1  // optional milestone number, null to remove
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


def update_issue(
    repository: str,
    issue_number: int,
    title: Optional[str] = None,
    body: Optional[str] = None,
    state: Optional[str] = None,
    labels: Optional[List[str]] = None,
    assignees: Optional[List[str]] = None,
    milestone: Optional[int] = None,
    token: Optional[str] = None
) -> Dict[str, Any]:
    """
    Update a GitHub issue.

    Args:
        repository: Repository in format "owner/repo"
        issue_number: Issue number to update
        title: New issue title
        body: New issue description
        state: Issue state ("open" or "closed")
        labels: New list of label names (replaces existing)
        assignees: New list of GitHub usernames (replaces existing)
        milestone: New milestone number (None to keep, pass null object to remove)
        token: GitHub API token (defaults to GITHUB_TOKEN env var)

    Returns:
        Updated issue data from GitHub API

    Raises:
        GitHubAPIError: If issue update fails
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
    url = f"https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}"
    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'X-GitHub-Api-Version': '2022-11-28'
    }

    payload = {}

    if title is not None:
        payload['title'] = title

    if body is not None:
        payload['body'] = body

    if state is not None:
        if state not in ['open', 'closed']:
            raise GitHubAPIError(f"Invalid state: {state}. Must be 'open' or 'closed'")
        payload['state'] = state

    if labels is not None:
        payload['labels'] = labels

    if assignees is not None:
        payload['assignees'] = assignees

    if milestone is not None:
        payload['milestone'] = milestone

    # Validate at least one field is being updated
    if not payload:
        raise GitHubAPIError("No fields provided for update")

    # Make API request
    try:
        response = requests.patch(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()

        issue = response.json()
        logger.info(f"Updated issue #{issue['number']}: {issue['html_url']}")
        return issue

    except requests.exceptions.HTTPError as e:
        error_msg = f"GitHub API error: {e}"
        if e.response is not None:
            try:
                error_details = e.response.json()
                error_msg = f"GitHub API error: {error_details.get('message', str(e))}"
                # Handle specific error cases
                if e.response.status_code == 404:
                    error_msg = f"Issue #{issue_number} not found in {repository}"
            except json.JSONDecodeError:
                pass
        raise GitHubAPIError(error_msg)

    except requests.exceptions.RequestException as e:
        raise GitHubAPIError(f"Request failed: {e}")


def add_comment(
    repository: str,
    issue_number: int,
    comment: str,
    token: Optional[str] = None
) -> Dict[str, Any]:
    """
    Add a comment to a GitHub issue.

    Args:
        repository: Repository in format "owner/repo"
        issue_number: Issue number
        comment: Comment text
        token: GitHub API token (defaults to GITHUB_TOKEN env var)

    Returns:
        Comment data from GitHub API

    Raises:
        GitHubAPIError: If comment creation fails
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
    url = f"https://api.github.com/repos/{owner}/{repo}/issues/{issue_number}/comments"
    headers = {
        'Authorization': f'Bearer {token}',
        'Accept': 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
        'X-GitHub-Api-Version': '2022-11-28'
    }

    payload = {'body': comment}

    # Make API request
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=30)
        response.raise_for_status()

        comment_data = response.json()
        logger.info(f"Added comment to issue #{issue_number}")
        return comment_data

    except requests.exceptions.RequestException as e:
        raise GitHubAPIError(f"Failed to add comment: {e}")


def main() -> None:
    """Main entry point for CLI."""
    try:
        # Read payload from stdin
        payload = json.load(sys.stdin)

        # Validate required fields
        repository = payload.get('repository')
        issue_number = payload.get('issue_number')

        if not repository:
            logger.error("Missing required field: repository")
            sys.exit(1)

        if not issue_number:
            logger.error("Missing required field: issue_number")
            sys.exit(1)

        # Check if this is a comment-only update
        comment = payload.get('comment')
        if comment and len([k for k in payload.keys() if k not in ['repository', 'issue_number', 'comment']]) == 0:
            # Add comment only
            comment_data = add_comment(
                repository=repository,
                issue_number=issue_number,
                comment=comment
            )
            result = {
                'success': True,
                'action': 'comment_added',
                'comment_id': comment_data['id'],
                'comment_url': comment_data['html_url']
            }
            print(json.dumps(result, indent=2))
            return

        # Extract optional update fields
        title = payload.get('title')
        body = payload.get('body')
        state = payload.get('state')
        labels = payload.get('labels')
        assignees = payload.get('assignees')
        milestone = payload.get('milestone')

        # Update issue
        issue = update_issue(
            repository=repository,
            issue_number=issue_number,
            title=title,
            body=body,
            state=state,
            labels=labels,
            assignees=assignees,
            milestone=milestone
        )

        # Add comment if provided
        if comment:
            add_comment(
                repository=repository,
                issue_number=issue_number,
                comment=comment
            )

        # Output result
        result = {
            'success': True,
            'issue_number': issue['number'],
            'issue_url': issue['html_url'],
            'state': issue['state']
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
