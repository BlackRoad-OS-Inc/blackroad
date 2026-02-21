#!/usr/bin/env python3
"""
BlackRoad OAuth Handler - Extract tokens from OAuth URLs
Supports: OpenAI, Anthropic, GitHub, Google, and more
"""

import re
import json
import urllib.parse
import hashlib
import base64
from pathlib import Path
from datetime import datetime

class BlackRoadOAuthHandler:
    """Universal OAuth token extractor"""
    
    def __init__(self):
        self.tokens_dir = Path.home() / '.blackroad' / 'oauth-tokens'
        self.tokens_dir.mkdir(parents=True, exist_ok=True)
    
    def parse_url(self, url):
        """Parse OAuth URL and extract useful info"""
        parsed = urllib.parse.urlparse(url)
        params = dict(urllib.parse.parse_qsl(parsed.query))
        
        provider = self._detect_provider(parsed.netloc, url)
        
        return {
            'provider': provider,
            'url': url,
            'domain': parsed.netloc,
            'path': parsed.path,
            'params': params,
            'extracted': self._extract_by_provider(provider, params, parsed)
        }
    
    def _detect_provider(self, domain, url):
        """Detect OAuth provider from domain"""
        if 'openai.com' in domain or 'codex' in url.lower():
            return 'openai'
        elif 'anthropic.com' in domain:
            return 'anthropic'
        elif 'github.com' in domain:
            return 'github'
        elif 'google.com' in domain or 'googleapis.com' in domain:
            return 'google'
        elif 'microsoft.com' in domain or 'live.com' in domain:
            return 'microsoft'
        elif 'groq.com' in domain:
            return 'groq'
        elif 'replicate.com' in domain:
            return 'replicate'
        elif 'huggingface.co' in domain:
            return 'huggingface'
        else:
            return 'unknown'
    
    def _extract_by_provider(self, provider, params, parsed):
        """Provider-specific extraction logic"""
        extracted = {}
        
        if provider == 'openai':
            # OpenAI Codex CLI OAuth
            extracted['client_id'] = params.get('client_id')
            extracted['redirect_uri'] = params.get('redirect_uri')
            extracted['scope'] = params.get('scope', '').split()
            extracted['code_challenge'] = params.get('code_challenge')
            extracted['code_challenge_method'] = params.get('code_challenge_method')
            extracted['state'] = params.get('state')
            extracted['response_type'] = params.get('response_type')
            
            # Extract port from redirect_uri for local server
            if extracted['redirect_uri']:
                redirect_parsed = urllib.parse.urlparse(extracted['redirect_uri'])
                extracted['callback_port'] = redirect_parsed.port or 80
                extracted['callback_path'] = redirect_parsed.path
        
        elif provider == 'github':
            extracted['client_id'] = params.get('client_id')
            extracted['scope'] = params.get('scope', '').split()
            extracted['state'] = params.get('state')
        
        elif provider == 'google':
            extracted['client_id'] = params.get('client_id')
            extracted['redirect_uri'] = params.get('redirect_uri')
            extracted['scope'] = params.get('scope', '').split()
            extracted['response_type'] = params.get('response_type')
            extracted['access_type'] = params.get('access_type')
        
        return extracted
    
    def save_oauth_info(self, info):
        """Save OAuth info to disk"""
        provider = info['provider']
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        
        filename = f"{provider}_{timestamp}.json"
        filepath = self.tokens_dir / filename
        
        with open(filepath, 'w') as f:
            json.dump(info, f, indent=2)
        
        # Also save as "latest"
        latest_file = self.tokens_dir / f"{provider}_latest.json"
        with open(latest_file, 'w') as f:
            json.dump(info, f, indent=2)
        
        return str(filepath)
    
    def generate_pkce_verifier(self, code_challenge, method='S256'):
        """Generate PKCE verifier from challenge (for educational purposes)"""
        # Note: You can't reverse SHA256, this is just for understanding
        # In practice, you need the original verifier that created the challenge
        return {
            'challenge': code_challenge,
            'method': method,
            'note': 'PKCE prevents token theft - verifier is kept client-side'
        }
    
    def create_callback_server_config(self, info):
        """Create config for local OAuth callback server"""
        extracted = info.get('extracted', {})
        port = extracted.get('callback_port', 1455)
        path = extracted.get('callback_path', '/auth/callback')
        
        return {
            'port': port,
            'path': path,
            'expected_params': ['code', 'state'],
            'command': f"python3 -m http.server {port}"
        }


def main():
    import sys
    
    if len(sys.argv) < 2:
        print("""
╔═══════════════════════════════════════════════════╗
║     BlackRoad OAuth Handler                      ║
╚═══════════════════════════════════════════════════╝

Usage:
  ./blackroad-oauth-handler.py <oauth-url>
  ./blackroad-oauth-handler.py --list
  ./blackroad-oauth-handler.py --latest <provider>

Examples:
  # Parse OpenAI OAuth URL
  ./blackroad-oauth-handler.py "https://auth.openai.com/oauth/authorize?..."
  
  # List all stored tokens
  ./blackroad-oauth-handler.py --list
  
  # Get latest token for provider
  ./blackroad-oauth-handler.py --latest openai

Providers Supported:
  • OpenAI (Codex CLI)
  • Anthropic (Claude)
  • GitHub (Copilot)
  • Google (APIs)
  • Microsoft (Azure)
  • Groq, Replicate, HuggingFace

Philosophy:
  We extract everything we can from OAuth flows.
  They can limit the flow, but not our understanding.
  Multiple providers = unlimited access.
""")
        sys.exit(0)
    
    handler = BlackRoadOAuthHandler()
    
    if sys.argv[1] == '--list':
        tokens_dir = Path.home() / '.blackroad' / 'oauth-tokens'
        if not tokens_dir.exists():
            print("No OAuth tokens stored yet")
            sys.exit(0)
        
        print("Stored OAuth Tokens:")
        for f in sorted(tokens_dir.glob('*.json')):
            print(f"  • {f.name}")
        sys.exit(0)
    
    elif sys.argv[1] == '--latest' and len(sys.argv) > 2:
        provider = sys.argv[2]
        latest_file = Path.home() / '.blackroad' / 'oauth-tokens' / f"{provider}_latest.json"
        if latest_file.exists():
            with open(latest_file) as f:
                data = json.load(f)
            print(json.dumps(data, indent=2))
        else:
            print(f"No stored token for {provider}")
        sys.exit(0)
    
    else:
        # Parse OAuth URL
        url = sys.argv[1]
        info = handler.parse_url(url)
        filepath = handler.save_oauth_info(info)
        
        print(f"""
╔═══════════════════════════════════════════════════╗
║     OAuth URL Parsed                             ║
╚═══════════════════════════════════════════════════╝

Provider: {info['provider']}
Domain: {info['domain']}

Extracted Information:
""")
        
        for key, value in info['extracted'].items():
            if value:
                print(f"  {key}: {value}")
        
        print(f"""
Saved to: {filepath}

Callback Server Config:
""")
        
        callback_config = handler.create_callback_server_config(info)
        for key, value in callback_config.items():
            print(f"  {key}: {value}")
        
        print("""
Next Steps:
  1. Start callback server on specified port
  2. Complete OAuth flow in browser
  3. Extract access token from callback
  4. Store in BlackRoad API key system

Philosophy:
  OAuth can't stop us. We understand the flow.
  Multiple providers = unlimited paths.
""")


if __name__ == '__main__':
    main()
