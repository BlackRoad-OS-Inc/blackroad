"""
RoadOAuth - OAuth 2.0 for BlackRoad
OAuth 2.0 authorization server and client implementation.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Set
import base64
import hashlib
import json
import logging
import secrets
import threading
import urllib.parse
import uuid

logger = logging.getLogger(__name__)


class GrantType(str, Enum):
    AUTHORIZATION_CODE = "authorization_code"
    CLIENT_CREDENTIALS = "client_credentials"
    REFRESH_TOKEN = "refresh_token"
    PASSWORD = "password"


class ResponseType(str, Enum):
    CODE = "code"
    TOKEN = "token"


class TokenType(str, Enum):
    BEARER = "Bearer"


@dataclass
class OAuthClient:
    client_id: str
    client_secret: str
    name: str
    redirect_uris: List[str] = field(default_factory=list)
    allowed_scopes: Set[str] = field(default_factory=set)
    allowed_grants: Set[GrantType] = field(default_factory=set)
    access_token_ttl: int = 3600
    refresh_token_ttl: int = 86400 * 30
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class AuthorizationCode:
    code: str
    client_id: str
    user_id: str
    redirect_uri: str
    scopes: Set[str]
    code_challenge: Optional[str] = None
    code_challenge_method: Optional[str] = None
    expires_at: datetime = field(default_factory=lambda: datetime.now() + timedelta(minutes=10))

    @property
    def is_expired(self) -> bool:
        return datetime.now() > self.expires_at


@dataclass
class AccessToken:
    token: str
    client_id: str
    user_id: Optional[str]
    scopes: Set[str]
    token_type: TokenType = TokenType.BEARER
    expires_at: datetime = field(default_factory=lambda: datetime.now() + timedelta(hours=1))
    refresh_token: Optional[str] = None
    created_at: datetime = field(default_factory=datetime.now)

    @property
    def is_expired(self) -> bool:
        return datetime.now() > self.expires_at

    @property
    def expires_in(self) -> int:
        return max(0, int((self.expires_at - datetime.now()).total_seconds()))

    def to_dict(self) -> Dict[str, Any]:
        result = {
            "access_token": self.token,
            "token_type": self.token_type.value,
            "expires_in": self.expires_in,
            "scope": " ".join(self.scopes)
        }
        if self.refresh_token:
            result["refresh_token"] = self.refresh_token
        return result


@dataclass
class RefreshToken:
    token: str
    client_id: str
    user_id: Optional[str]
    scopes: Set[str]
    expires_at: datetime = field(default_factory=lambda: datetime.now() + timedelta(days=30))

    @property
    def is_expired(self) -> bool:
        return datetime.now() > self.expires_at


class TokenStore:
    def __init__(self):
        self.access_tokens: Dict[str, AccessToken] = {}
        self.refresh_tokens: Dict[str, RefreshToken] = {}
        self.authorization_codes: Dict[str, AuthorizationCode] = {}
        self._lock = threading.Lock()

    def store_access_token(self, token: AccessToken) -> None:
        with self._lock:
            self.access_tokens[token.token] = token

    def get_access_token(self, token: str) -> Optional[AccessToken]:
        return self.access_tokens.get(token)

    def revoke_access_token(self, token: str) -> bool:
        with self._lock:
            if token in self.access_tokens:
                del self.access_tokens[token]
                return True
            return False

    def store_refresh_token(self, token: RefreshToken) -> None:
        with self._lock:
            self.refresh_tokens[token.token] = token

    def get_refresh_token(self, token: str) -> Optional[RefreshToken]:
        return self.refresh_tokens.get(token)

    def revoke_refresh_token(self, token: str) -> bool:
        with self._lock:
            if token in self.refresh_tokens:
                del self.refresh_tokens[token]
                return True
            return False

    def store_authorization_code(self, code: AuthorizationCode) -> None:
        with self._lock:
            self.authorization_codes[code.code] = code

    def get_authorization_code(self, code: str) -> Optional[AuthorizationCode]:
        return self.authorization_codes.get(code)

    def delete_authorization_code(self, code: str) -> bool:
        with self._lock:
            if code in self.authorization_codes:
                del self.authorization_codes[code]
                return True
            return False


class OAuthError(Exception):
    def __init__(self, error: str, description: str = "", status_code: int = 400):
        self.error = error
        self.description = description
        self.status_code = status_code
        super().__init__(description or error)

    def to_dict(self) -> Dict[str, str]:
        result = {"error": self.error}
        if self.description:
            result["error_description"] = self.description
        return result


class AuthorizationServer:
    def __init__(self):
        self.clients: Dict[str, OAuthClient] = {}
        self.token_store = TokenStore()
        self.user_authenticator: Optional[Callable[[str, str], Optional[str]]] = None

    def register_client(self, name: str, redirect_uris: List[str], scopes: Set[str] = None, grants: Set[GrantType] = None) -> OAuthClient:
        client = OAuthClient(
            client_id=secrets.token_urlsafe(16),
            client_secret=secrets.token_urlsafe(32),
            name=name,
            redirect_uris=redirect_uris,
            allowed_scopes=scopes or {"read"},
            allowed_grants=grants or {GrantType.AUTHORIZATION_CODE}
        )
        self.clients[client.client_id] = client
        return client

    def get_client(self, client_id: str) -> Optional[OAuthClient]:
        return self.clients.get(client_id)

    def authorize(self, client_id: str, redirect_uri: str, response_type: str, scope: str, user_id: str, state: str = None, code_challenge: str = None, code_challenge_method: str = None) -> str:
        client = self.clients.get(client_id)
        if not client:
            raise OAuthError("invalid_client", "Client not found")
        
        if redirect_uri not in client.redirect_uris:
            raise OAuthError("invalid_request", "Invalid redirect URI")
        
        scopes = set(scope.split()) if scope else {"read"}
        if not scopes.issubset(client.allowed_scopes):
            raise OAuthError("invalid_scope", "Requested scope not allowed")
        
        if response_type == "code":
            code = AuthorizationCode(
                code=secrets.token_urlsafe(32),
                client_id=client_id,
                user_id=user_id,
                redirect_uri=redirect_uri,
                scopes=scopes,
                code_challenge=code_challenge,
                code_challenge_method=code_challenge_method
            )
            self.token_store.store_authorization_code(code)
            
            params = {"code": code.code}
            if state:
                params["state"] = state
            return f"{redirect_uri}?{urllib.parse.urlencode(params)}"
        
        raise OAuthError("unsupported_response_type")

    def token(self, grant_type: str, client_id: str, client_secret: str, **kwargs) -> Dict[str, Any]:
        client = self._authenticate_client(client_id, client_secret)
        
        if grant_type == GrantType.AUTHORIZATION_CODE.value:
            return self._handle_authorization_code(client, **kwargs)
        elif grant_type == GrantType.CLIENT_CREDENTIALS.value:
            return self._handle_client_credentials(client, **kwargs)
        elif grant_type == GrantType.REFRESH_TOKEN.value:
            return self._handle_refresh_token(client, **kwargs)
        elif grant_type == GrantType.PASSWORD.value:
            return self._handle_password(client, **kwargs)
        
        raise OAuthError("unsupported_grant_type")

    def _authenticate_client(self, client_id: str, client_secret: str) -> OAuthClient:
        client = self.clients.get(client_id)
        if not client or client.client_secret != client_secret:
            raise OAuthError("invalid_client", "Invalid credentials", 401)
        return client

    def _handle_authorization_code(self, client: OAuthClient, code: str, redirect_uri: str, code_verifier: str = None, **kwargs) -> Dict[str, Any]:
        auth_code = self.token_store.get_authorization_code(code)
        if not auth_code:
            raise OAuthError("invalid_grant", "Authorization code not found")
        
        if auth_code.is_expired:
            raise OAuthError("invalid_grant", "Authorization code expired")
        
        if auth_code.client_id != client.client_id:
            raise OAuthError("invalid_grant", "Client mismatch")
        
        if auth_code.redirect_uri != redirect_uri:
            raise OAuthError("invalid_grant", "Redirect URI mismatch")
        
        if auth_code.code_challenge:
            if not code_verifier:
                raise OAuthError("invalid_grant", "Code verifier required")
            if auth_code.code_challenge_method == "S256":
                expected = base64.urlsafe_b64encode(hashlib.sha256(code_verifier.encode()).digest()).rstrip(b"=").decode()
            else:
                expected = code_verifier
            if auth_code.code_challenge != expected:
                raise OAuthError("invalid_grant", "Code verifier mismatch")
        
        self.token_store.delete_authorization_code(code)
        return self._issue_tokens(client, auth_code.user_id, auth_code.scopes)

    def _handle_client_credentials(self, client: OAuthClient, scope: str = None, **kwargs) -> Dict[str, Any]:
        if GrantType.CLIENT_CREDENTIALS not in client.allowed_grants:
            raise OAuthError("unauthorized_client")
        scopes = set(scope.split()) if scope else client.allowed_scopes
        return self._issue_tokens(client, None, scopes, include_refresh=False)

    def _handle_refresh_token(self, client: OAuthClient, refresh_token: str, **kwargs) -> Dict[str, Any]:
        token = self.token_store.get_refresh_token(refresh_token)
        if not token or token.is_expired:
            raise OAuthError("invalid_grant", "Invalid refresh token")
        if token.client_id != client.client_id:
            raise OAuthError("invalid_grant", "Client mismatch")
        self.token_store.revoke_refresh_token(refresh_token)
        return self._issue_tokens(client, token.user_id, token.scopes)

    def _handle_password(self, client: OAuthClient, username: str, password: str, scope: str = None, **kwargs) -> Dict[str, Any]:
        if GrantType.PASSWORD not in client.allowed_grants:
            raise OAuthError("unauthorized_client")
        if not self.user_authenticator:
            raise OAuthError("server_error", "User authentication not configured")
        user_id = self.user_authenticator(username, password)
        if not user_id:
            raise OAuthError("invalid_grant", "Invalid credentials")
        scopes = set(scope.split()) if scope else client.allowed_scopes
        return self._issue_tokens(client, user_id, scopes)

    def _issue_tokens(self, client: OAuthClient, user_id: Optional[str], scopes: Set[str], include_refresh: bool = True) -> Dict[str, Any]:
        access_token = AccessToken(
            token=secrets.token_urlsafe(32),
            client_id=client.client_id,
            user_id=user_id,
            scopes=scopes,
            expires_at=datetime.now() + timedelta(seconds=client.access_token_ttl)
        )
        
        if include_refresh:
            refresh = RefreshToken(
                token=secrets.token_urlsafe(32),
                client_id=client.client_id,
                user_id=user_id,
                scopes=scopes,
                expires_at=datetime.now() + timedelta(seconds=client.refresh_token_ttl)
            )
            access_token.refresh_token = refresh.token
            self.token_store.store_refresh_token(refresh)
        
        self.token_store.store_access_token(access_token)
        return access_token.to_dict()

    def validate_token(self, token: str, required_scope: str = None) -> Optional[AccessToken]:
        access_token = self.token_store.get_access_token(token)
        if not access_token or access_token.is_expired:
            return None
        if required_scope and required_scope not in access_token.scopes:
            return None
        return access_token

    def revoke(self, token: str) -> bool:
        return self.token_store.revoke_access_token(token) or self.token_store.revoke_refresh_token(token)


def example_usage():
    server = AuthorizationServer()
    
    # Register a client
    client = server.register_client(
        name="My App",
        redirect_uris=["https://myapp.com/callback"],
        scopes={"read", "write", "admin"},
        grants={GrantType.AUTHORIZATION_CODE, GrantType.CLIENT_CREDENTIALS, GrantType.REFRESH_TOKEN}
    )
    print(f"Client ID: {client.client_id}")
    print(f"Client Secret: {client.client_secret}")
    
    # Authorization code flow
    redirect = server.authorize(
        client_id=client.client_id,
        redirect_uri="https://myapp.com/callback",
        response_type="code",
        scope="read write",
        user_id="user-123",
        state="abc123"
    )
    print(f"\nAuthorization redirect: {redirect}")
    
    # Extract code from redirect
    parsed = urllib.parse.urlparse(redirect)
    code = urllib.parse.parse_qs(parsed.query)["code"][0]
    
    # Exchange code for tokens
    tokens = server.token(
        grant_type="authorization_code",
        client_id=client.client_id,
        client_secret=client.client_secret,
        code=code,
        redirect_uri="https://myapp.com/callback"
    )
    print(f"\nTokens: {tokens}")
    
    # Validate token
    access = server.validate_token(tokens["access_token"], required_scope="read")
    print(f"\nToken valid: {access is not None}")
    
    # Client credentials flow
    cc_tokens = server.token(
        grant_type="client_credentials",
        client_id=client.client_id,
        client_secret=client.client_secret,
        scope="read"
    )
    print(f"\nClient credentials tokens: {cc_tokens}")
