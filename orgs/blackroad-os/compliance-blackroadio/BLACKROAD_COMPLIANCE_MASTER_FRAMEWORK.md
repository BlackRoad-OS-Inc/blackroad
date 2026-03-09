# BlackRoad OS - Master Compliance Framework
**Classification:** INTERNAL - COMPLIANCE RESTRICTED
**Owner:** Devereux (Chief Compliance Officer)
**Principal:** Alexa Louise Amundson (CRD# 7794541)
**Generated:** 2026-01-04
**Version:** 1.0

---

## Executive Summary

This document establishes comprehensive regulatory compliance for **BlackRoad OS, Inc.** and all subsidiaries, with specific focus on establishing **BlackRoad Financial Services** (or **Amundson Financial Services**) as a **Registered Investment Advisor (RIA)** and **Broker-Dealer (BD)** under BlackRoad OS as the parent organization.

### Current Status
- **Principal:** Alexa L. Amundson holds Series 7, 63, 65, SIE (CRD# 7794541)
- **Registration Status:** Currently not registered (former Ameriprise/Securian)
- **No Disclosure Events:** Clean FINRA BrokerCheck record
- **Infrastructure:** 66 GitHub repos, 16 Cloudflare zones, multi-cloud deployment

### Compliance Scope
1. **Financial Services** (SEC, FINRA, State Securities)
2. **Consumer Protection** (CFPB, FTC, State AGs)
3. **Cybersecurity** (Reg S-P, Reg S-ID, GLBA, CCPA, GDPR)
4. **Anti-Money Laundering** (BSA/FinCEN, OFAC)
5. **Crypto/Digital Assets** (SEC, CFTC, FinCEN)
6. **Data Privacy** (SOC 2, ISO 27001, NIST)
7. **AI/ML Governance** (EU AI Act, NIST AI RMF)

---

## Part I: RIA/BD Registration Roadmap

### A. Entity Structure

```yaml
parent:
  name: BlackRoad OS, Inc.
  state: Delaware (recommended) or Minnesota
  status: To be incorporated
  role: Parent holding company

financial_services_entity:
  proposed_name:
    - Option 1: "BlackRoad Financial Services, LLC"
    - Option 2: "Amundson Financial Services, LLC"
    - Option 3: "BlackRoad Wealth Management, LLC"
  parent: BlackRoad OS, Inc.
  structure: LLC (member: BlackRoad OS, Inc.)
  state: Delaware (for entity) + State Securities registrations

registrations_required:
  ria:
    authority: SEC (if $100M+ AUM) or State (if under $100M)
    form: Form ADV Parts 1, 2A, 2B
    timeline: 4-6 months

  bd:
    authority: SEC + FINRA
    form: Form BD
    timeline: 6-12 months
    membership_required:
      - FINRA (Financial Industry Regulatory Authority)
      - SIPC (Securities Investor Protection Corporation)
```

### B. Pre-Registration Requirements

#### 1. Corporate Formation
- [ ] Incorporate BlackRoad OS, Inc. (Parent)
- [ ] Form BlackRoad Financial Services, LLC (Subsidiary)
- [ ] Obtain EIN from IRS
- [ ] Open business bank accounts (segregated for securities)
- [ ] Obtain E&O insurance ($1M-$5M minimum)
- [ ] Obtain fidelity bond (required for BD)

#### 2. Compliance Infrastructure
- [ ] Appoint Chief Compliance Officer (Alexa or hire)
- [ ] Establish compliance manual (see Part II)
- [ ] Create Written Supervisory Procedures (WSPs)
- [ ] Implement recordkeeping system (SEC Rule 17a-4)
- [ ] Deploy surveillance and monitoring systems
- [ ] Establish cybersecurity program (Reg S-P)

#### 3. Technology & Systems
- [ ] Deploy trade order management system (TOMS)
- [ ] Implement portfolio management system (PMS)
- [ ] Deploy CRM with audit trail
- [ ] Establish secure communication platform
- [ ] Implement document management (17a-4 compliant)
- [ ] Deploy AML/KYC screening platform

#### 4. Policies & Procedures
- [ ] Code of Ethics
- [ ] Anti-Money Laundering Program (AML)
- [ ] Customer Identification Program (CIP)
- [ ] Cybersecurity & Data Protection
- [ ] Business Continuity Plan (BCP)
- [ ] Disaster Recovery Plan (DRP)
- [ ] Privacy Policy (Reg S-P, GLBA)
- [ ] Complaint Handling Procedures
- [ ] Trade Error Policy
- [ ] Best Execution Policy
- [ ] Conflicts of Interest Policy

### C. Registration Timeline

```
Month 1-2: Entity Formation & Infrastructure
├─ Form entities (BlackRoad OS + Financial Services)
├─ Obtain EIN, insurance, bank accounts
├─ Deploy core technology systems
└─ Draft initial compliance manual

Month 3-4: Form Preparation & Filing
├─ Complete Form ADV (RIA) or Form BD
├─ Prepare disclosure documents (ADV Part 2)
├─ Draft client agreements and disclosures
├─ Complete FINRA membership application (if BD)
└─ Submit state registrations (Form U4 for individuals)

Month 5-6: Review & Approval Process
├─ SEC/State review of application
├─ FINRA review (if BD)
├─ Respond to deficiency letters
├─ Complete on-site inspection (if required)
└─ Receive registration approval

Month 7-12: Operational Readiness (BD only)
├─ FINRA membership approval
├─ Join SIPC
├─ Establish clearing relationships
├─ Complete operational testing
└─ Launch operations
```

### D. Ongoing Compliance Obligations

#### Annual Requirements
- Form ADV amendments (within 90 days of fiscal year end)
- Annual compliance review
- Annual AML independent test
- Annual cybersecurity assessment
- Annual BCP testing
- Annual privacy notice delivery

#### Periodic Requirements
- Material Form ADV amendments (promptly)
- Form U4/U5 updates for associated persons (30 days)
- Trade confirmations (at or before completion)
- Account statements (quarterly minimum)
- FOCUS reports (BD only - monthly/quarterly)

#### Recordkeeping (17a-4 & 17a-3)
- Client communications (3-7 years, WORM storage)
- Trade blotters and ledgers (6 years)
- Customer account records (6 years post-closing)
- Written complaints (4 years)
- Advertising and marketing (5 years from last use)

---

## Part II: Compliance Manual Structure

### 1. Governance & Oversight
```yaml
compliance_committee:
  chair: Alexa Amundson (Principal & CCO)
  members:
    - Operations Manager
    - Technology Officer
    - Legal Counsel (external)
  meetings: Quarterly minimum

responsibilities:
  - Review compliance metrics
  - Approve policy changes
  - Review examination findings
  - Oversee remediation
```

### 2. Supervisory Structure
```yaml
principal:
  name: Alexa L. Amundson
  crd: 7794541
  qualifications:
    - Series 7 (General Securities)
    - Series 63 (State Law)
    - Series 65 (Investment Adviser Law)
    - SIE (Securities Industry Essentials)
  responsibilities:
    - Ultimate compliance authority
    - Supervise all associated persons
    - Review and approve trades
    - Sign off on new accounts
```

### 3. Core Compliance Functions

#### A. Anti-Money Laundering (BSA/FinCEN)
```yaml
aml_program:
  officer: Alexa Amundson (AMLCO)

  components:
    - Customer Identification Program (CIP)
    - Customer Due Diligence (CDD)
    - Enhanced Due Diligence (EDD) for high-risk
    - Ongoing monitoring and surveillance
    - Suspicious Activity Reporting (SAR)
    - Currency Transaction Reporting (CTR)
    - OFAC screening (SDN list)

  risk_categories:
    high_risk:
      - PEPs (Politically Exposed Persons)
      - High-risk jurisdictions
      - Cash-intensive businesses
      - Foreign correspondent accounts
    medium_risk:
      - Non-resident aliens
      - Trusts and entities
      - High-net-worth individuals
    low_risk:
      - Established domestic clients
      - Low transaction volume

  monitoring:
    - Real-time OFAC screening
    - Pattern detection algorithms
    - Large transaction alerts ($10K+)
    - Rapid movement of funds
    - Structuring detection
```

#### B. Know Your Customer (KYC)
```yaml
kyc_requirements:
  individual_accounts:
    - Full legal name
    - Date of birth
    - SSN or TIN
    - Physical address (no PO boxes)
    - Government-issued ID verification
    - Employment/occupation
    - Investment objectives
    - Risk tolerance
    - Financial situation

  entity_accounts:
    - Legal entity name
    - EIN
    - Formation documents
    - Beneficial ownership (25%+ owners)
    - Authorized signers
    - Business purpose

  verification:
    - Document verification (ID, utility bill)
    - Database verification (Equifax, LexisNexis)
    - Beneficial ownership certification (FinCEN)
```

#### C. Cybersecurity (Reg S-P, Reg S-ID, GLBA)
```yaml
cybersecurity_program:
  framework: NIST Cybersecurity Framework v1.1

  requirements:
    - Written cybersecurity policy
    - Annual risk assessment
    - Incident response plan
    - Data encryption (at rest & in transit)
    - Access controls & MFA
    - Vendor management program
    - Employee training (annual)
    - Penetration testing (annual)

  data_protection:
    pii_categories:
      - SSN, TIN
      - Account numbers
      - Driver's license
      - Financial information
      - Investment positions

    protection_controls:
      - AES-256 encryption
      - TLS 1.3 for transmission
      - Role-based access control (RBAC)
      - Audit logging (tamper-proof)
      - Data loss prevention (DLP)

  breach_notification:
    - Internal detection: immediate escalation
    - CCO notification: within 24 hours
    - Regulatory notification: as required by state law
    - Customer notification: without unreasonable delay
    - Law enforcement: coordinate with FBI/Secret Service
```

#### D. Trade Surveillance
```yaml
surveillance_program:
  monitoring_areas:
    - Pre-trade compliance (suitability, concentration)
    - Order handling (best execution, time stamps)
    - Post-trade review (trade errors, markups)
    - Personal trading (code of ethics)
    - Market manipulation (wash sales, layering)

  automated_alerts:
    - Excessive trading (churning)
    - Unauthorized trading
    - Outside business activities
    - Gifts and entertainment thresholds
    - Political contributions (Pay-to-Play)

  review_frequency:
    - Real-time: OFAC, trading limits
    - Daily: Trade blotter review
    - Weekly: Exception reports
    - Monthly: Compliance testing
    - Quarterly: Supervisory review
```

---

## Part III: Consumer Protection Compliance

### A. Consumer Financial Protection Bureau (CFPB)
```yaml
cfpb_compliance:
  applicable_if:
    - Offering consumer financial products
    - Credit, lending, or payment services
    - Debt collection

  requirements:
    - Fair lending practices (ECOA)
    - Truth in Lending (TILA)
    - Fair Debt Collection (FDCPA)
    - Electronic Fund Transfer (Reg E)
    - Consumer complaint response (<15 days)
```

### B. Federal Trade Commission (FTC)
```yaml
ftc_compliance:
  areas:
    - Advertising truth-in-advertising
    - Data privacy and security
    - Consumer protection against fraud
    - Endorsement and testimonial disclosure

  key_rules:
    - FTC Act Section 5 (unfair/deceptive practices)
    - Safeguards Rule (financial institutions)
    - Gramm-Leach-Bliley Act (GLBA)
    - CAN-SPAM Act (email marketing)
```

### C. State Attorneys General
```yaml
state_compliance:
  consumer_protection:
    - State UDAP (Unfair/Deceptive Acts)
    - State data breach notification laws
    - State licensing requirements

  key_states:
    - Minnesota (principal residence)
    - California (CCPA, CPRA)
    - New York (SHIELD Act, DFS Cybersecurity)
    - Delaware (if incorporated)
```

---

## Part IV: Crypto/Digital Asset Compliance

### A. Regulatory Framework
```yaml
crypto_compliance:
  sec_jurisdiction:
    - Securities determination (Howey Test)
    - Investment Adviser Act (if managing crypto assets)
    - Custody Rule (digital asset custody)

  cftc_jurisdiction:
    - Commodities (Bitcoin, Ethereum as commodities)
    - Derivatives and futures
    - Swap dealer registration (if applicable)

  fincen_bsa:
    - Money Services Business (MSB) registration
    - AML program for virtual currency
    - Suspicious Activity Reports (SARs)
    - Travel Rule (transfers >$3,000)
```

### B. Digital Asset Custody
```yaml
custody_requirements:
  sec_custody_rule:
    - Qualified custodian requirement
    - Account verification
    - Surprise audits

  digital_asset_controls:
    - Cold storage (95% of assets)
    - Multi-signature wallets (3-of-5 minimum)
    - Hardware security modules (HSM)
    - Disaster recovery keys (geographically distributed)
    - Insurance coverage (crime/specie policy)

  current_holdings:
    - ETH: 2.5 ETH (MetaMask - migrate to custody)
    - SOL: 100 SOL (Phantom - migrate to custody)
    - BTC: 0.1 BTC (Coinbase - verify custody status)
    - BTC Address: 1Ak2fc5N2q4imYxqVMqBNEQDFq8J2Zs9TZ
```

---

## Part V: Technology Compliance Infrastructure

### A. Recordkeeping System (SEC Rule 17a-4)
```yaml
requirements:
  storage_type: WORM (Write Once Read Many)
  retention_periods:
    - Books and records: 6 years
    - Communications: 3-7 years
    - Customer account docs: 6 years after closing

  implementation:
    primary_storage:
      - Cloudflare D1 (immutable tables)
      - S3 Glacier Deep Archive (WORM configured)

    audit_trail:
      - PS-SHA-∞ verification chain
      - Cryptographic timestamping
      - Immutable event logging

    access_controls:
      - RBAC (Role-Based Access Control)
      - MFA for all access
      - Audit log of all retrievals
```

### B. Communication Surveillance
```yaml
communication_channels:
  email:
    - Google Workspace (retention: 7 years)
    - Archiving: Smarsh or Global Relay
    - Keyword monitoring

  instant_messaging:
    - Slack Enterprise Grid
    - Retention: 7 years
    - eDiscovery-ready export

  voice:
    - VoIP system with recording
    - Retention: 3 years

  social_media:
    - Archiving required for business use
    - Pre-approval for posts
    - Third-party archiving (Smarsh Social)
```

### C. Cybersecurity Architecture
```yaml
security_controls:
  perimeter:
    - Cloudflare WAF (Web Application Firewall)
    - DDoS protection
    - Rate limiting
    - Bot management

  application:
    - Input validation
    - SQL injection prevention
    - XSS prevention
    - CSRF tokens

  data:
    - Encryption at rest (AES-256)
    - Encryption in transit (TLS 1.3)
    - Key management (Cloudflare KV encrypted)
    - Secrets management (Railway/GitHub Secrets)

  access:
    - SSO (Cloudflare Access)
    - MFA required (Duo, Google Authenticator)
    - Least privilege principle
    - Regular access reviews

  monitoring:
    - SIEM (Security Information Event Management)
    - Intrusion detection (IDS/IPS)
    - Log aggregation (Cloudflare Logs)
    - Anomaly detection (AI/ML)
```

---

## Part VI: Operational Procedures

### A. New Account Opening
```yaml
workflow:
  step_1_application:
    - Client submits account application
    - Collects KYC information
    - Verifies identity (ID + utility bill)

  step_2_aml_screening:
    - OFAC/SDN list check
    - PEP screening
    - Adverse media search

  step_3_suitability:
    - Investment objectives
    - Risk tolerance
    - Financial situation
    - Investment experience

  step_4_approval:
    - Principal review and approval
    - Sign account agreement
    - Deliver disclosures (ADV Part 2, privacy notice)

  step_5_funding:
    - Receive initial deposit
    - Verify source of funds
    - Account activation
```

### B. Trade Order Handling
```yaml
workflow:
  step_1_order_receipt:
    - Client places order (phone, email, portal)
    - Time stamp order receipt
    - Verify account authorization

  step_2_suitability_check:
    - Automated suitability screening
    - Concentration limit checks
    - Trading authorization verification

  step_3_execution:
    - Route to best execution venue
    - Execute trade
    - Time stamp execution

  step_4_confirmation:
    - Generate trade confirmation
    - Deliver to client (T+1)
    - Update account records

  step_5_settlement:
    - Settle trade (T+2 for securities)
    - Update ledgers
    - Reconcile positions
```

### C. Complaint Handling
```yaml
procedure:
  step_1_receipt:
    - Log complaint in CRM
    - Assign tracking number
    - Acknowledge receipt (within 24 hours)

  step_2_investigation:
    - Gather facts and documents
    - Interview involved parties
    - Determine if reportable (Form U4/U5)

  step_3_resolution:
    - Draft response letter
    - Offer remediation if appropriate
    - Principal review and approval

  step_4_response:
    - Send response to client
    - Document resolution
    - Retain records (4 years)

  step_5_reporting:
    - File Form U4/U5 amendment (if required)
    - Report to state (if required)
    - Internal compliance review
```

---

## Part VII: Audit & Examination Readiness

### A. Self-Assessment Program
```yaml
frequency: Quarterly
areas:
  - AML program effectiveness
  - Trade surveillance accuracy
  - Recordkeeping compliance
  - Cybersecurity posture
  - Privacy compliance

deliverable:
  - Written self-assessment report
  - Exception tracking
  - Remediation plan
  - Board presentation
```

### B. Independent Testing
```yaml
annual_tests:
  - AML independent test (BSA requirement)
  - Cybersecurity penetration test
  - Business continuity plan test
  - Disaster recovery test

providers:
  - External audit firm (Big 4 or specialized)
  - Cybersecurity firm (e.g., Mandiant, CrowdStrike)
  - Compliance consultants
```

### C. Regulatory Examination Preparation
```yaml
examination_types:
  sec_ria:
    frequency: Every 3-5 years (random selection)
    focus_areas:
      - Custody and safekeeping
      - Portfolio management
      - Disclosure and advertising
      - Code of ethics
      - Valuation

  finra_bd:
    frequency: Cycle exams (every 2-4 years)
    focus_areas:
      - AML program
      - Supervision
      - Sales practices
      - Books and records
      - Financial responsibility

  state_securities:
    frequency: Variable (often piggyback on SEC)
    focus_areas:
      - Investment adviser operations
      - Fee arrangements
      - State notice filings

  preparation:
    - Mock examination (annual)
    - Document request response plan
    - Examination response team
    - Legal counsel on standby
```

---

## Part VIII: Implementation Checklist

### Phase 1: Foundation (Months 1-3)
- [ ] Incorporate BlackRoad OS, Inc.
- [ ] Form BlackRoad Financial Services, LLC
- [ ] Obtain EIN and business licenses
- [ ] Open business bank accounts
- [ ] Obtain E&O insurance ($3M minimum)
- [ ] Obtain fidelity bond ($500K minimum)
- [ ] Deploy Compliance Manual v1.0
- [ ] Draft Written Supervisory Procedures
- [ ] Establish Code of Ethics
- [ ] Create AML Program Manual
- [ ] Deploy CRM with audit trail
- [ ] Implement 17a-4 compliant recordkeeping

### Phase 2: Technology (Months 2-4)
- [ ] Deploy trade order management system
- [ ] Implement portfolio management system
- [ ] Configure OFAC/AML screening
- [ ] Deploy email archiving (Smarsh/Global Relay)
- [ ] Implement MFA across all systems
- [ ] Configure Cloudflare security (WAF, Access)
- [ ] Deploy SIEM/logging infrastructure
- [ ] Implement backup and disaster recovery
- [ ] Configure GitHub repository compliance checks
- [ ] Deploy PS-SHA-∞ verification throughout

### Phase 3: Registration (Months 3-6)
- [ ] Prepare Form ADV Parts 1, 2A, 2B (RIA)
- [ ] OR prepare Form BD (Broker-Dealer)
- [ ] Complete FINRA membership application (if BD)
- [ ] File Form U4 for Alexa (Principal)
- [ ] Submit state notice filings (all states of operation)
- [ ] Respond to deficiency letters
- [ ] Complete regulatory examinations
- [ ] Receive registration approval

### Phase 4: Operations (Months 6-12)
- [ ] Establish clearing relationships (if BD)
- [ ] Join SIPC (if BD)
- [ ] Deploy client portal
- [ ] Launch marketing website (compliance.blackroad.io)
- [ ] Onboard first clients (friends & family phase)
- [ ] Complete first quarterly compliance review
- [ ] File first Form ADV amendment (if applicable)
- [ ] Conduct annual compliance training
- [ ] Complete independent AML test
- [ ] Achieve full operational status

---

## Part IX: Key Contacts & Resources

### A. Regulatory Agencies
```yaml
sec:
  name: Securities and Exchange Commission
  website: sec.gov
  divisions:
    - Investment Management (RIA)
    - Trading and Markets (BD)

finra:
  name: Financial Industry Regulatory Authority
  website: finra.org
  contact: Member Regulation

fincen:
  name: Financial Crimes Enforcement Network
  website: fincen.gov

cfpb:
  name: Consumer Financial Protection Bureau
  website: consumerfinance.gov
```

### B. Service Providers
```yaml
compliance_consultants:
  - National Regulatory Services (NRS)
  - ACA Compliance Group
  - CCO Consulting

technology:
  - Smarsh (communication archiving)
  - Eze Castle (trading systems)
  - Riskalyze (risk assessment)
  - Redtail CRM (advisory CRM)

legal:
  - Find securities law firm (Minnesota or national)
  - Focus: RIA/BD formation and compliance
```

---

## Part X: Budget Estimate

### Initial Setup Costs (One-Time)
```yaml
legal_entity_formation: $5,000 - $10,000
insurance_bonds:
  - E&O insurance: $10,000 - $25,000/year
  - Fidelity bond: $2,000 - $5,000/year
  - Cyber insurance: $5,000 - $15,000/year

technology:
  - CRM system: $5,000 - $15,000
  - Compliance software: $10,000 - $30,000
  - Trading systems: $20,000 - $100,000 (BD only)
  - Archiving: $5,000 - $15,000/year

compliance_consulting: $25,000 - $75,000
legal_counsel: $25,000 - $100,000
registration_fees:
  - SEC Form ADV: $0 (no filing fee)
  - FINRA BD: $10,000 - $50,000
  - State filings: $500 - $2,000 per state

total_initial: $100,000 - $400,000 (RIA lower, BD higher)
```

### Annual Operating Costs
```yaml
compliance_staff:
  - CCO (Alexa): market rate or allocated
  - Compliance analyst: $60,000 - $100,000

technology_subscriptions: $30,000 - $75,000/year
insurance_renewal: $17,000 - $45,000/year
audit_testing: $15,000 - $40,000/year
legal_counsel: $10,000 - $50,000/year
registration_renewals: $5,000 - $20,000/year

total_annual: $137,000 - $330,000/year
```

---

## Appendices

### Appendix A: Principal Qualifications
**Alexa Louise Amundson - CRD# 7794541**
- Series 7: General Securities Representative (11/04/2023)
- Series 63: Uniform Securities Agent State Law (02/16/2024)
- Series 65: Uniform Investment Adviser Law (02/21/2024)
- SIE: Securities Industry Essentials (09/14/2023)
- Former Firms: Ameriprise (11/2023-06/2024), Securian (07/2024-06/2025)
- Disclosure Events: None (clean record)

### Appendix B: Technology Stack
```yaml
source_of_truth:
  - GitHub: 66 repositories across 15 organizations
  - Cloudflare: 16 zones, 8 Pages, 8 KV, 1 D1

infrastructure:
  - Railway: 12+ projects (compute)
  - DigitalOcean: Droplet (backup)
  - Raspberry Pi: Edge devices (3x)

verification:
  - PS-SHA-∞: Infinite cascade hashing
  - 256-step verification chain
```

### Appendix C: Document Templates
- [ ] Form ADV Part 1
- [ ] Form ADV Part 2A (Brochure)
- [ ] Form ADV Part 2B (Brochure Supplement)
- [ ] Form BD (if BD)
- [ ] Form U4 (Individual Registration)
- [ ] Investment Advisory Agreement
- [ ] Brokerage Account Agreement
- [ ] Privacy Notice (Reg S-P)
- [ ] Code of Ethics
- [ ] AML Program Manual
- [ ] Written Supervisory Procedures

---

**END OF MASTER COMPLIANCE FRAMEWORK**

*This document is the living compliance blueprint for BlackRoad OS.*
*Update as regulations evolve and operations mature.*
*All compliance = risk mitigation = sustainable growth.*

---

Generated by Devereux (Chief Compliance Officer)
Powered by Claude Code
