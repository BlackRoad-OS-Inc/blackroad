#!/usr/bin/env python3
"""
BlackRoad Webhook Server
Handles GitHub webhook events for automatic deployments
"""

import os
import json
import hmac
import hashlib
import subprocess
from http.server import HTTPServer, BaseHTTPRequestHandler
from threading import Thread

PORT = int(os.getenv('WEBHOOK_PORT', 9000))
SECRET = os.getenv('WEBHOOK_SECRET', 'blackroad-deploy-secret')
DEPLOYMENTS_FILE = os.path.expanduser('~/.blackroad-deploy/deployments.json')

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != '/webhook':
            self.send_response(404)
            self.end_headers()
            return
        
        # Verify signature
        signature = self.headers.get('X-Hub-Signature-256', '')
        content_length = int(self.headers.get('Content-Length', 0))
        body = self.rfile.read(content_length)
        
        expected_signature = 'sha256=' + hmac.new(
            SECRET.encode(), body, hashlib.sha256
        ).hexdigest()
        
        if not hmac.compare_digest(signature, expected_signature):
            print(f"⚠ Invalid signature from {self.client_address[0]}")
            self.send_response(401)
            self.end_headers()
            self.wfile.write(b'Invalid signature')
            return
        
        # Parse payload
        try:
            payload = json.loads(body)
            event = self.headers.get('X-GitHub-Event', '')
            
            print(f"✓ Received {event} event")
            
            if event == 'push':
                self.handle_push(payload)
            elif event == 'ping':
                print("  Ping received - webhook is working!")
            
            self.send_response(200)
            self.end_headers()
            self.wfile.write(b'OK')
            
        except Exception as e:
            print(f"✗ Error processing webhook: {e}")
            self.send_response(500)
            self.end_headers()
            self.wfile.write(f'Error: {str(e)}'.encode())
    
    def handle_push(self, payload):
        """Handle push events and trigger deployments"""
        repo_name = payload['repository']['name']
        repo_url = payload['repository']['clone_url']
        branch = payload['ref'].split('/')[-1]
        
        print(f"  Repository: {repo_name}")
        print(f"  Branch: {branch}")
        
        # Load deployment config
        if not os.path.exists(DEPLOYMENTS_FILE):
            print(f"  No deployments configured for {repo_name}")
            return
        
        with open(DEPLOYMENTS_FILE) as f:
            deployments = json.load(f)
        
        # Find matching deployment
        for deployment in deployments:
            if deployment['repo'] == repo_name and deployment.get('branch', 'main') == branch:
                print(f"  Triggering deployment to {deployment['target']}...")
                
                # Clone/update repo and deploy
                Thread(target=self.deploy_repo, args=(deployment, repo_url, branch)).start()
                
                return
        
        print(f"  No matching deployment found")
    
    def deploy_repo(self, deployment, repo_url, branch):
        """Clone repo and deploy"""
        try:
            repo_name = deployment['repo']
            target = deployment['target']
            app_name = deployment.get('app_name', repo_name)
            
            # Clone/update repo
            deploy_dir = os.path.expanduser(f'~/.blackroad-deploy/repos/{repo_name}')
            
            if os.path.exists(deploy_dir):
                print(f"  Updating {repo_name}...")
                subprocess.run(['git', '-C', deploy_dir, 'pull'], check=True)
            else:
                print(f"  Cloning {repo_name}...")
                os.makedirs(os.path.dirname(deploy_dir), exist_ok=True)
                subprocess.run(['git', 'clone', '-b', branch, repo_url, deploy_dir], check=True)
            
            # Deploy
            br_deploy = os.path.expanduser('~/blackroad-deploy/br-deploy')
            print(f"  Deploying {app_name} to {target}...")
            
            result = subprocess.run(
                [br_deploy, 'deploy', deploy_dir, target, app_name],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print(f"✓ Deployment successful!")
                print(result.stdout)
            else:
                print(f"✗ Deployment failed!")
                print(result.stderr)
                
        except Exception as e:
            print(f"✗ Deployment error: {e}")
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass

def main():
    # Ensure config directory exists
    os.makedirs(os.path.dirname(DEPLOYMENTS_FILE), exist_ok=True)
    
    if not os.path.exists(DEPLOYMENTS_FILE):
        with open(DEPLOYMENTS_FILE, 'w') as f:
            json.dump([], f)
    
    server = HTTPServer(('0.0.0.0', PORT), WebhookHandler)
    
    print(f"🚀 BlackRoad Webhook Server")
    print(f"   Port: {PORT}")
    print(f"   Endpoint: http://0.0.0.0:{PORT}/webhook")
    print(f"   Deployments: {DEPLOYMENTS_FILE}")
    print(f"\n✓ Server started - waiting for webhooks...\n")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n\n✓ Server stopped")
        server.shutdown()

if __name__ == '__main__':
    main()
