# HIPAA Compliance

**Health Insurance Portability and Accountability Act**

## Safeguard Categories

### Administrative Safeguards

| Requirement | Implementation |
|-------------|----------------|
| Security Officer | Designated CISO |
| Risk Analysis | Annual assessment |
| Workforce Training | Mandatory annual |
| Access Management | RBAC + MFA |
| Incident Response | 24/7 SOC |
| Business Associates | BAA required |

### Physical Safeguards

| Requirement | Implementation |
|-------------|----------------|
| Facility Access | Badge + biometric |
| Workstation Use | Clean desk policy |
| Device Security | Encrypted devices |
| Media Disposal | Certified destruction |

### Technical Safeguards

| Requirement | Implementation |
|-------------|----------------|
| Access Control | Unique user IDs |
| Audit Controls | Complete logging |
| Integrity Controls | Hash verification |
| Transmission Security | TLS 1.3 |
| Encryption | AES-256 |

## PHI Handling

```yaml
# PHI detection and handling
phi_detection:
  enabled: true
  fields:
    - name
    - dob
    - ssn
    - medical_record_number
    - health_plan_id
  action: encrypt_and_log
```

## Breach Notification

| Affected | Notification Timeline |
|----------|----------------------|
| < 500 individuals | 60 days (HHS annual) |
| >= 500 individuals | 60 days (immediate to HHS + media) |

## Business Associate Agreement

Required for all third-party vendors handling PHI.
Template: `policies/baa-template.md`
