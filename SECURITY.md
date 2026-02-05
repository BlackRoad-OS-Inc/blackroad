# Security Policy

> Security is a top priority for BlackRoad OS

---

## 🔐 Supported Versions

| Version | Supported |
|---------|-----------|
| 2.x.x | ✅ Active support |
| 1.x.x | ⚠️ Security fixes only |
| < 1.0 | ❌ No support |

---

## 🚨 Reporting a Vulnerability

### DO NOT

- ❌ Open a public GitHub issue
- ❌ Post on social media
- ❌ Share in public channels

### DO

1. **Email** security@blackroad.io (or blackroad.systems@gmail.com)
2. **Encrypt** using our PGP key (below)
3. **Include** detailed information

### What to Include

```
Subject: [SECURITY] Brief description

1. Description of vulnerability
2. Steps to reproduce
3. Potential impact
4. Suggested fix (if any)
5. Your contact info (for follow-up)
```

### PGP Key

```
-----BEGIN PGP PUBLIC KEY BLOCK-----
[Contact us for PGP key]
-----END PGP PUBLIC KEY BLOCK-----
```

### Response Timeline

| Phase | Timeline |
|-------|----------|
| Initial response | 24 hours |
| Triage & assessment | 72 hours |
| Fix development | 7-14 days |
| Coordinated disclosure | 90 days |

---

## 🛡️ Security Measures

### Authentication

| Component | Method |
|-----------|--------|
| API | JWT + API Keys |
| Web | OAuth2 / OIDC |
| CLI | Token-based |
| Agent-to-Agent | mTLS |

### Encryption

| Data State | Method |
|------------|--------|
| In Transit | TLS 1.3 |
| At Rest | AES-256-GCM |
| Secrets | HashiCorp Vault |

### Access Control

```
┌─────────────────────────────────────────────────────────────┐
│                    ACCESS CONTROL MODEL                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ROLE              PERMISSIONS                              │
│  ──────────────────────────────────────────────────────────│
│  Admin             Full access to all resources             │
│  Developer         Read/write to assigned repos             │
│  Operator          Deploy, monitor, manage agents           │
│  Viewer            Read-only access                         │
│  Agent             Scoped to assigned tasks                 │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔍 Security Scanning

### Automated Scans

| Scan Type | Frequency | Tool |
|-----------|-----------|------|
| SAST | Every PR | CodeQL |
| DAST | Weekly | OWASP ZAP |
| Dependencies | Daily | Dependabot |
| Containers | Every build | Trivy |
| Secrets | Every commit | GitLeaks |

### Current Status

```
Last scan: 2026-02-05

Dependabot alerts:    30 (reviewing)
CodeQL alerts:        30 (reviewing)
Secret scanning:      30 (reviewing)
Container vulns:      0 critical
```

---

## 🔒 Security Best Practices

### For Contributors

1. **Never commit secrets**
   ```bash
   # Use environment variables
   export API_KEY="your-key"

   # Or .env files (gitignored)
   echo "API_KEY=your-key" >> .env
   ```

2. **Validate all input**
   ```python
   def process_input(data: str) -> str:
       # Validate before processing
       if not is_valid(data):
           raise ValidationError("Invalid input")
       return sanitize(data)
   ```

3. **Use parameterized queries**
   ```python
   # Good
   cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))

   # Bad - SQL injection risk
   cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
   ```

4. **Keep dependencies updated**
   ```bash
   # Check for updates
   npm audit
   pip-audit
   cargo audit
   ```

### For Operators

1. **Rotate credentials regularly**
2. **Use least-privilege access**
3. **Enable audit logging**
4. **Monitor for anomalies**
5. **Keep systems patched**

---

## 🚫 Known Security Limitations

### Current Limitations

| Limitation | Risk Level | Mitigation | ETA |
|------------|------------|------------|-----|
| No MFA for CLI | Medium | Use strong tokens | Q1 2026 |
| Logs may contain PII | Low | Log sanitization | Q1 2026 |
| No E2E encryption | Medium | TLS sufficient for now | Q2 2026 |

### Won't Fix

| Issue | Reason |
|-------|--------|
| Self-signed certs in dev | Development only |
| Local Ollama unencrypted | Localhost only |

---

## 📜 Compliance

### Current Status

| Standard | Status |
|----------|--------|
| SOC2 Type 1 | 📋 Planned Q2 2026 |
| SOC2 Type 2 | 📋 Planned Q4 2026 |
| GDPR | ⚠️ In progress |
| HIPAA | ❌ Not applicable |
| ISO 27001 | 📋 Planned 2027 |

### Data Handling

```
Data Classification:
├── Public         - Open documentation, public APIs
├── Internal       - Internal docs, non-sensitive configs
├── Confidential   - User data, API keys, credentials
└── Restricted     - Encryption keys, security logs
```

---

## 🔑 Secrets Management

### Approved Storage

| Secret Type | Storage | Access |
|-------------|---------|--------|
| API Keys | Vault | Service accounts |
| DB Credentials | Vault | Operators |
| Encryption Keys | HSM | Automated only |
| User Passwords | DB (hashed) | Auth service |

### Rotation Schedule

| Secret Type | Rotation |
|-------------|----------|
| API Keys | 90 days |
| Service Tokens | 30 days |
| DB Passwords | 90 days |
| Encryption Keys | Annually |

---

## 📞 Security Contacts

| Role | Contact |
|------|---------|
| Security Lead | security@blackroad.io |
| Backup | blackroad.systems@gmail.com |
| Emergency | [On-call rotation] |

---

## 🏆 Bug Bounty

### Scope

| In Scope | Out of Scope |
|----------|--------------|
| *.blackroad.io | Third-party services |
| API endpoints | Social engineering |
| Agent vulnerabilities | Physical attacks |
| Auth/authz issues | DoS attacks |

### Rewards

| Severity | Bounty |
|----------|--------|
| Critical | $1,000 - $5,000 |
| High | $500 - $1,000 |
| Medium | $100 - $500 |
| Low | Recognition |

*Bug bounty program coming Q2 2026*

---

*Last updated: 2026-02-05*
