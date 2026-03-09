"""
Salesforce OAuth 2.0 Authentication

Handles token acquisition, refresh, and secure storage.
"""

import os
import time
import json
import requests
from pathlib import Path
from dataclasses import dataclass
from typing import Optional
import structlog

logger = structlog.get_logger()


@dataclass
class AuthConfig:
    """Configuration for Salesforce authentication"""
    client_id: str
    client_secret: str
    username: str
    password: str
    security_token: str = ""
    domain: str = "login"  # "login", "test", or custom domain
    sfdx_auth_file: Optional[str] = None  # Path to SFDX auth file for CLI token reuse


@dataclass
class TokenInfo:
    """OAuth token information"""
    access_token: str
    refresh_token: Optional[str]
    instance_url: str
    token_type: str
    issued_at: float
    expires_in: int = 7200  # Default 2 hours

    @property
    def is_expired(self) -> bool:
        """Check if token is expired (with 5 min buffer)"""
        return time.time() > (self.issued_at + self.expires_in - 300)

    def to_dict(self) -> dict:
        return {
            'access_token': self.access_token,
            'refresh_token': self.refresh_token,
            'instance_url': self.instance_url,
            'token_type': self.token_type,
            'issued_at': self.issued_at,
            'expires_in': self.expires_in
        }

    @classmethod
    def from_dict(cls, data: dict) -> 'TokenInfo':
        return cls(**data)


class SalesforceAuth:
    """
    Salesforce OAuth 2.0 authentication handler.

    Supports:
    - Username-Password Flow (for server-to-server)
    - JWT Bearer Flow (for production)
    - Refresh Token Flow
    """

    LOGIN_URL = "https://login.salesforce.com"
    TEST_LOGIN_URL = "https://test.salesforce.com"

    def __init__(
        self,
        config: Optional[AuthConfig] = None,
        consumer_key: str = None,
        consumer_secret: str = None,
        username: str = None,
        password: Optional[str] = None,
        security_token: Optional[str] = None,
        instance_url: Optional[str] = None,
        is_sandbox: bool = False,
        token_cache_path: Optional[str] = None
    ):
        # Support both AuthConfig and direct params
        if config:
            self.consumer_key = config.client_id
            self.consumer_secret = config.client_secret
            self.username = config.username
            self.password = config.password
            self.security_token = config.security_token or ""
            self.is_sandbox = config.domain == "test"
            if config.domain not in ("login", "test"):
                self.instance_url = f"https://{config.domain}.my.salesforce.com"
            else:
                self.instance_url = instance_url
        else:
            self.consumer_key = consumer_key
            self.consumer_secret = consumer_secret
            self.username = username
            self.password = password
            self.security_token = security_token or ""
            self.instance_url = instance_url
            self.is_sandbox = is_sandbox

        self.token_cache_path = Path(token_cache_path or "~/.blackroad/sf_token.json").expanduser()
        self._token: Optional[TokenInfo] = None

        # Try to load cached token
        self._load_cached_token()

    @property
    def login_url(self) -> str:
        """Get appropriate login URL"""
        if self.instance_url:
            return self.instance_url
        return self.TEST_LOGIN_URL if self.is_sandbox else self.LOGIN_URL

    @property
    def token(self) -> TokenInfo:
        """Get valid access token, refreshing if needed"""
        if self._token is None or self._token.is_expired:
            self.authenticate()
        return self._token

    @property
    def access_token(self) -> str:
        """Get current access token"""
        return self.token.access_token

    @property
    def headers(self) -> dict:
        """Get authorization headers for API requests"""
        return {
            'Authorization': f'Bearer {self.access_token}',
            'Content-Type': 'application/json'
        }

    def authenticate(self) -> TokenInfo:
        """
        Authenticate with Salesforce using username-password flow.
        """
        logger.info("authenticating_with_salesforce", username=self.username)

        # Try refresh token first if available
        if self._token and self._token.refresh_token:
            try:
                return self._refresh_token()
            except Exception as e:
                logger.warning("refresh_token_failed", error=str(e))

        # Fall back to username-password flow
        return self._username_password_flow()

    def _username_password_flow(self) -> TokenInfo:
        """Authenticate using username-password flow"""
        token_url = f"{self.login_url}/services/oauth2/token"

        payload = {
            'grant_type': 'password',
            'client_id': self.consumer_key,
            'client_secret': self.consumer_secret,
            'username': self.username,
            'password': f"{self.password}{self.security_token}"
        }

        response = requests.post(token_url, data=payload)

        if response.status_code != 200:
            error = response.json()
            logger.error("authentication_failed", error=error)
            raise AuthenticationError(f"Authentication failed: {error.get('error_description', error)}")

        data = response.json()

        self._token = TokenInfo(
            access_token=data['access_token'],
            refresh_token=data.get('refresh_token'),
            instance_url=data['instance_url'],
            token_type=data['token_type'],
            issued_at=float(data['issued_at']) / 1000  # Convert ms to seconds
        )

        self._cache_token()

        logger.info("authentication_successful", instance_url=self._token.instance_url)
        return self._token

    def _refresh_token(self) -> TokenInfo:
        """Refresh access token using refresh token"""
        if not self._token or not self._token.refresh_token:
            raise AuthenticationError("No refresh token available")

        token_url = f"{self._token.instance_url}/services/oauth2/token"

        payload = {
            'grant_type': 'refresh_token',
            'client_id': self.consumer_key,
            'client_secret': self.consumer_secret,
            'refresh_token': self._token.refresh_token
        }

        response = requests.post(token_url, data=payload)

        if response.status_code != 200:
            raise AuthenticationError("Token refresh failed")

        data = response.json()

        self._token = TokenInfo(
            access_token=data['access_token'],
            refresh_token=self._token.refresh_token,  # Keep existing refresh token
            instance_url=data['instance_url'],
            token_type=data['token_type'],
            issued_at=time.time()
        )

        self._cache_token()

        logger.info("token_refreshed")
        return self._token

    def _cache_token(self):
        """Cache token to disk"""
        try:
            self.token_cache_path.parent.mkdir(parents=True, exist_ok=True)
            with open(self.token_cache_path, 'w') as f:
                json.dump(self._token.to_dict(), f)
            # Secure the file
            os.chmod(self.token_cache_path, 0o600)
        except Exception as e:
            logger.warning("token_cache_failed", error=str(e))

    def _load_cached_token(self):
        """Load cached token from disk"""
        try:
            if self.token_cache_path.exists():
                with open(self.token_cache_path, 'r') as f:
                    data = json.load(f)
                self._token = TokenInfo.from_dict(data)
                logger.info("loaded_cached_token")
        except Exception as e:
            logger.warning("load_cached_token_failed", error=str(e))

    def revoke(self):
        """Revoke current access token"""
        if not self._token:
            return

        revoke_url = f"{self._token.instance_url}/services/oauth2/revoke"
        requests.post(revoke_url, data={'token': self._token.access_token})

        self._token = None
        if self.token_cache_path.exists():
            self.token_cache_path.unlink()

        logger.info("token_revoked")

    @classmethod
    def from_sfdx(cls, username: str = None, sfdx_dir: str = "~/.sfdx") -> 'SalesforceAuth':
        """
        Create SalesforceAuth from existing SF CLI authentication.

        This allows reusing tokens from `sf org login` without needing
        Connected App credentials.

        Args:
            username: Salesforce username (will search for auth file)
            sfdx_dir: Directory containing SFDX auth files

        Returns:
            Configured SalesforceAuth instance with valid token
        """
        sfdx_path = Path(sfdx_dir).expanduser()

        # Find auth file
        if username:
            auth_file = sfdx_path / f"{username}.json"
        else:
            # Find first .json file
            json_files = list(sfdx_path.glob("*.json"))
            json_files = [f for f in json_files if f.name != "alias.json"]
            if not json_files:
                raise AuthenticationError("No SFDX auth files found")
            auth_file = json_files[0]

        if not auth_file.exists():
            raise AuthenticationError(f"Auth file not found: {auth_file}")

        with open(auth_file) as f:
            data = json.load(f)

        # Create instance
        instance = cls(
            consumer_key=data.get("clientId", "PlatformCLI"),
            consumer_secret="",
            username=data["username"],
            instance_url=data["instanceUrl"]
        )

        # Set token directly
        instance._token = TokenInfo(
            access_token=data["accessToken"],
            refresh_token=data.get("refreshToken"),
            instance_url=data["instanceUrl"],
            token_type="Bearer",
            issued_at=time.time(),
            expires_in=7200
        )

        logger.info("loaded_sfdx_auth", username=data["username"], instance=data["instanceUrl"])
        return instance


class AuthenticationError(Exception):
    """Raised when authentication fails"""
    pass
