# Business Continuity Plan (BCP)
**BlackRoad OS, Inc.**
**Effective Date:** [Entity formed November 2024]
**Last Reviewed:** January 4, 2026

---

## Executive Summary

This Business Continuity Plan ("BCP") establishes procedures for BlackRoad OS, Inc. ("BlackRoad" or the "Firm") to:
1. **Respond** to significant business disruptions
2. **Recover** critical business operations
3. **Resume** normal operations within acceptable timeframes
4. **Protect** client assets and data

**Regulatory Basis:**
- Investment Advisers Act Rule 206(4)-7 (Compliance policies and procedures)
- SEC Staff Guidance on Business Continuity Planning

**Plan Owner:** Alexa Louise Amundson, Chief Compliance Officer (CCO)

---

## Table of Contents

1. [Plan Objectives and Scope](#plan-objectives-and-scope)
2. [Critical Business Functions](#critical-business-functions)
3. [Disaster Scenarios](#disaster-scenarios)
4. [Emergency Contact Information](#emergency-contact-information)
5. [Data Backup and Recovery](#data-backup-and-recovery)
6. [Alternate Physical Location](#alternate-physical-location)
7. [Technology Recovery](#technology-recovery)
8. [Client Communication](#client-communication)
9. [Vendor and Service Provider Continuity](#vendor-and-service-provider-continuity)
10. [Regulatory Notification](#regulatory-notification)
11. [Testing and Maintenance](#testing-and-maintenance)
12. [Plan Activation and Authority](#plan-activation-and-authority)

---

## 1. Plan Objectives and Scope

### A. Objectives

This BCP is designed to:
1. **Protect:** Client assets, data, and confidential information
2. **Maintain:** Critical business operations during disruptions
3. **Minimize:** Financial losses and reputational damage
4. **Recover:** Normal operations within Recovery Time Objectives (RTOs)
5. **Communicate:** With clients, regulators, and stakeholders
6. **Comply:** With SEC and other regulatory requirements

### B. Scope

**Covered Disruptions:**
- Natural disasters (earthquake, flood, fire, tornado)
- Pandemic or health emergency
- Cyberattack or data breach
- Technology failure (systems, internet, power)
- Loss of key personnel
- Loss of office space
- Vendor or service provider failure

**Out of Scope:**
- Day-to-day operational issues
- Minor technology glitches
- Individual employee absences

### C. Recovery Time Objectives (RTO)

| Business Function | RTO | Justification |
|-------------------|-----|---------------|
| Client communication | 4 hours | Clients must be able to reach Firm |
| Access to client accounts | 24 hours | Clients need account access |
| Portfolio management | 48 hours | Investment decisions can wait short period |
| Trading execution | 48 hours | Non-critical for RIA |
| Regulatory reporting | 72 hours | Most deadlines allow grace period |
| Fee billing | 5 business days | Monthly/quarterly process |

---

## 2. Critical Business Functions

### A. Client Account Access

**Function:** Clients can view accounts, contact Firm, request transactions

**Critical Systems:**
- Custodian access (Schwab, Fidelity, etc.)
- Firm website and client portal
- Email and phone communications

**Backup Procedures:**
- Custodians have independent DR/BCP (verified annually)
- Firm website hosted on Cloudflare (99.99% uptime SLA)
- Mobile phones and alternate email as backup communication

**Key Personnel:**
- Primary: Alexa Amundson (Principal/CCO)
- Backup: [Designated backup advisor or outsourced continuity service]

### B. Investment Management and Trading

**Function:** Monitor portfolios, execute trades, rebalance accounts

**Critical Systems:**
- Portfolio management system (PMS)
- Custodian trading platforms
- Market data feeds

**Backup Procedures:**
- Cloud-based PMS accessible from any location
- Custodian platforms accessible via web
- Trading can be executed via phone if necessary

**Key Personnel:**
- Primary: Alexa Amundson (Principal)
- Backup: [Designated investment professional or sub-advisory arrangement]

### C. Compliance and Regulatory

**Function:** AML monitoring, regulatory filings, recordkeeping

**Critical Systems:**
- Compliance monitoring system
- Email archiving (Smarsh or Global Relay)
- OFAC screening platform
- Form ADV filing system (IARD)

**Backup Procedures:**
- Cloud-based compliance systems accessible remotely
- IARD accessible from any internet connection
- Email archiving vendor has independent DR/BCP

**Key Personnel:**
- Primary: Alexa Amundson (CCO)
- Backup: [External compliance consultant on retainer]

### D. Client Service and Communication

**Function:** Respond to client inquiries, provide account information

**Critical Systems:**
- Email (Microsoft 365 or Google Workspace)
- Phone system (VoIP or mobile)
- CRM system (Redtail, Wealthbox, etc.)

**Backup Procedures:**
- Email accessible from any device (cloud-based)
- Mobile phones as backup to office phones
- CRM accessible via web from any location

**Key Personnel:**
- Primary: Alexa Amundson (Principal)
- Backup: [Client service associate or virtual assistant]

---

## 3. Disaster Scenarios

### Scenario 1: Loss of Office Space (Fire, Flood, Earthquake)

**Impact:** Cannot access physical office, but systems intact

**Immediate Actions (0-4 hours):**
1. ✅ **Safety First:** Ensure all personnel safe and accounted for
2. ✅ **Notify:** Alert all employees of office closure
3. ✅ **Activate:** Work-from-home procedures
4. ✅ **Client Communication:** Post notice on website, send email to all clients
5. ✅ **Regulatory:** Notify SEC/State if office closed >3 days

**Short-Term Recovery (4-48 hours):**
1. Access all systems remotely from home
2. Route office phones to mobile phones
3. Verify custodian access and trading capability
4. Check email and respond to urgent client inquiries
5. Assess alternate office space needs

**Long-Term Recovery (48 hours - 30 days):**
1. Secure alternate office space (WeWork, Regus, or permanent relocation)
2. Update Form ADV with new address (if permanent)
3. Notify clients of new office location
4. Restore physical files from offsite backup
5. Resume normal operations from new location

**Responsible Party:** Principal (Alexa Amundson)

---

### Scenario 2: Pandemic or Health Emergency

**Impact:** Staff unable to come to office, health risks

**Immediate Actions (0-24 hours):**
1. ✅ **Work-from-Home:** Activate remote work for all employees
2. ✅ **Health:** Follow CDC/WHO guidance on employee safety
3. ✅ **Client Communication:** Notify clients of remote operations
4. ✅ **Verify Systems:** Ensure all can access systems remotely
5. ✅ **Continuity:** Confirm vendors/custodians operational

**Ongoing Operations (24 hours - duration):**
1. Daily check-ins with all staff (health and operational status)
2. Monitor portfolio performance and market conditions
3. Maintain client communication (email, phone, video calls)
4. Weekly team meetings via Zoom/Teams
5. Track regulatory guidance (SEC, FINRA relief programs)

**Recovery (post-pandemic):**
1. Gradual return to office (phased approach)
2. Assess permanent work-from-home policies
3. Update BCP based on lessons learned
4. Client surveys on remote service satisfaction

**Responsible Party:** Principal (Alexa Amundson)

---

### Scenario 3: Cyberattack or Ransomware

**Impact:** Systems compromised, data potentially stolen/encrypted

**Immediate Actions (0-1 hour):**
1. ✅ **Isolate:** Disconnect affected systems from network
2. ✅ **Notify:** Alert CCO and IT support immediately
3. ✅ **Assess:** Determine scope of attack (which systems, data)
4. ✅ **Preserve:** Do not reboot systems (preserve forensic evidence)
5. ✅ **Activate:** Incident response team (legal, forensics, PR)

**Containment (1-24 hours):**
1. Engage cybersecurity forensics firm (CrowdStrike, Mandiant, etc.)
2. Reset all passwords from clean systems
3. Verify integrity of backups (not encrypted by ransomware)
4. Assess data exfiltration (client PII, financial data)
5. Notify legal counsel (breach notification analysis)

**Eradication and Recovery (24-72 hours):**
1. Remove malware from systems (or rebuild from clean backups)
2. Restore data from backups (verified clean)
3. Strengthen security (patch vulnerabilities, MFA, network segmentation)
4. **DO NOT** pay ransom without legal/law enforcement consultation

**Notification (varies by jurisdiction):**
- **SEC:** Notify if material impact on operations
- **State AGs:** Per state breach notification laws (typically 30-60 days)
- **Clients:** Without unreasonable delay if PII compromised
- **Law Enforcement:** FBI Cyber Division (IC3.gov)

**Responsible Party:** CCO (Alexa Amundson) + Incident Response Team

---

### Scenario 4: Loss of Key Personnel (Death or Incapacity)

**Impact:** Principal/CCO unable to perform duties

**Immediate Actions (0-24 hours):**
1. ✅ **Notification:** Inform all employees and family (if appropriate)
2. ✅ **Backup Authority:** Activate succession plan
3. ✅ **Client Communication:** Notify clients of temporary changes
4. ✅ **Regulatory:** Notify SEC/State of material change to Form ADV
5. ✅ **Continuity:** Ensure ongoing operations maintained

**Succession Plan:**

**If Alexa Amundson (Principal/CCO) incapacitated:**
- **Temporary Authority:** [Name of backup advisor or designated successor]
- **Investment Management:** Continue existing strategies, no new positions
- **Client Service:** Respond to inquiries, defer major decisions
- **Compliance:** External compliance consultant (NRS, ACA Group) engaged
- **Duration:** Until permanent replacement hired or Principal returns

**If Permanent Loss:**
- **Option 1:** Hire new Principal/CCO (recruiting within 60 days)
- **Option 2:** Merge with another RIA (solicit offers)
- **Option 3:** Wind down Firm (orderly transition of clients)

**Client Asset Protection:**
- Assets remain at qualified custodians (not affected)
- No changes to custody arrangements
- Clients retain right to terminate and transfer accounts

**Responsible Party:** [Designated successor or Board of Directors]

---

### Scenario 5: Technology Failure (Internet, Power, Systems)

**Impact:** Cannot access cloud systems, communicate with clients

**Immediate Actions (0-4 hours):**
1. ✅ **Assess:** Determine scope (internet, power, specific system)
2. ✅ **Backup Internet:** Use mobile hotspot (Verizon, AT&T, T-Mobile)
3. ✅ **Backup Power:** Use laptop battery power, portable generators
4. ✅ **Communication:** Use mobile phones to contact clients
5. ✅ **Vendor Status:** Check custodian/vendor status pages

**Workarounds:**
- **No Internet:** Use mobile data (4G/5G hotspot)
- **No Power:** Work from Starbucks, library, or WeWork
- **System Down:** Use custodian direct platforms as backup
- **Phones Down:** Use mobile phones, email as primary contact

**Long-Term (if extended outage):**
1. Relocate to alternate location with connectivity
2. Notify clients of temporary communication channels
3. Defer non-urgent work until systems restored
4. Vendor escalation (demand status updates, ETR)

**Responsible Party:** Principal (Alexa Amundson) + IT Support

---

## 4. Emergency Contact Information

### A. Key Personnel

| Name | Role | Mobile | Email | Backup Email |
|------|------|--------|-------|--------------|
| Alexa Amundson | Principal/CCO | [Mobile] | blackroad.systems@gmail.com | amundsonalexa@gmail.com |
| [Backup Advisor] | Backup | [Mobile] | [Email] | [Personal Email] |

### B. Critical Vendors and Service Providers

| Vendor | Service | Contact | Phone | Emergency Email |
|--------|---------|---------|-------|-----------------|
| [Schwab/Fidelity/etc.] | Custody | [Account Rep] | [Phone] | [Email] |
| [Redtail/Wealthbox] | CRM | Support | [Phone] | [Email] |
| [Smarsh/Global Relay] | Email Archiving | Support | [Phone] | [Email] |
| Microsoft 365 / Google | Email | Support | [Phone] | [Email] |
| Cloudflare | Website Hosting | Support | [Phone] | [Email] |
| [IT Support Provider] | Technology | [Name] | [Phone] | [Email] |

### C. Regulatory Contacts

| Agency | Contact | Phone | Email |
|--------|---------|-------|-------|
| SEC Division of Investment Management | General Inquiries | (202) 551-6720 | [Regional office] |
| State Securities Regulator | [State] | [Phone] | [Email] |
| FinCEN | BSA/AML Helpline | (800) 949-2732 | FRC@fincen.gov |

---

## 5. Data Backup and Recovery

### A. Backup Strategy

**3-2-1 Backup Rule:**
- **3** copies of data (original + 2 backups)
- **2** different media types (local + cloud)
- **1** offsite backup (geographic diversity)

**Backup Locations:**
1. **Primary:** Cloud-based systems (Microsoft 365, Google Workspace, AWS)
2. **Secondary:** Cloud backup service (Backblaze, Carbonite, IDrive)
3. **Tertiary:** External hard drive (encrypted, stored offsite)

### B. Backup Schedule

| Data Type | Backup Frequency | Retention Period | Location |
|-----------|------------------|------------------|----------|
| Email | Real-time | 7 years | Smarsh/Global Relay (cloud) |
| Client files (CRM) | Daily | Indefinite | Cloud (vendor backup) |
| Financial records | Daily | 6 years | Cloud + encrypted external drive |
| Compliance records | Weekly | 6 years | Cloud + encrypted external drive |
| Trading records | Daily | 6 years | Custodian + cloud backup |

### C. Backup Verification

**Monthly Testing:**
- CCO randomly selects 5 files to restore from backup
- Verify successful restoration and file integrity
- Document test results in compliance log

**Annual Full Restore Test:**
- Simulate complete system failure
- Restore entire system from backups
- Verify all critical data recoverable
- Document test in BCP annual review

### D. Encryption and Security

**All Backups Encrypted:**
- **Standard:** AES-256 encryption
- **Key Management:** Encryption keys stored separately from backups
- **Password Protection:** Strong passwords (16+ characters)
- **Access Control:** Limited to Principal and IT administrator

---

## 6. Alternate Physical Location

### A. Primary Office

**Address:** [To be determined]
**Landlord:** [Building management contact]

**Critical Infrastructure:**
- High-speed internet (fiber)
- Power (UPS battery backup)
- Phone system (VoIP or landline)
- Security (building access, alarm)

### B. Alternate Work Locations

**Option 1: Work-from-Home (Principal Residence)**
- **Address:** [Alexa's home address]
- **Internet:** [Provider] (backup: mobile hotspot)
- **Phone:** Mobile phone
- **Systems Access:** All cloud-based systems accessible
- **Readiness:** Test quarterly

**Option 2: Temporary Office Space (WeWork, Regus)**
- **Provider:** WeWork or Regus
- **Locations:** [List 2-3 nearby locations]
- **Availability:** On-demand or reserved
- **Cost:** ~$200-500/day for private office

**Option 3: Secondary Office (if applicable)**
- **Address:** [If applicable]
- **Systems:** Full redundancy of primary office
- **Staff:** Cross-trained employees

### C. Relocation Procedures

**Temporary Relocation (1-30 days):**
1. Activate work-from-home for all employees
2. Forward office phones to mobile phones
3. Update website with temporary contact information
4. Notify clients via email of temporary changes
5. **Do Not** update Form ADV (temporary <30 days)

**Permanent Relocation (>30 days):**
1. Secure new office space
2. Set up infrastructure (internet, phones, security)
3. Migrate physical files and equipment
4. Update Form ADV Part 1A, Item 1.F (address)
5. File Form ADV amendment via IARD
6. Notify all clients in writing
7. Update business cards, letterhead, website

---

## 7. Technology Recovery

### A. Critical Technology Systems

| System | Provider | Cloud/On-Prem | RTO | Backup Access Method |
|--------|----------|---------------|-----|----------------------|
| Email | Microsoft 365 / Google | Cloud | 4 hours | Web access from any device |
| CRM | Redtail / Wealthbox | Cloud | 24 hours | Web access from any device |
| Portfolio Management | [PMS Provider] | Cloud | 48 hours | Web access from any device |
| Custodian Platform | Schwab / Fidelity | Cloud | 24 hours | Web access + phone trading |
| Email Archiving | Smarsh / Global Relay | Cloud | 72 hours | Vendor DR site |
| Website | Cloudflare Pages | Cloud | 4 hours | Cloudflare global CDN |
| Compliance Monitoring | Custom | On-Prem | 48 hours | Restore from GitHub + backups |

### B. Technology Recovery Procedures

**Cloud Systems (Email, CRM, PMS):**
1. Verify vendor system status (status page)
2. If vendor outage: Wait for vendor recovery (verified DR/BCP)
3. If local internet outage: Use mobile hotspot or alternate location
4. If device failure: Use any other device (cloud accessible)

**On-Premises Systems:**
1. Verify hardware failure vs. software issue
2. If hardware: Replace hardware or use alternate device
3. If software: Reinstall from backups or vendor install media
4. If data loss: Restore from most recent backup

**Cybersecurity Incident:**
1. Follow Scenario 3 procedures (isolate, contain, eradicate)
2. Rebuild systems from clean backups
3. Restore data from verified clean backups
4. Strengthen security before resuming operations

### C. Vendor Disaster Recovery Verification

**Annual Vendor BCP Review:**
CCO requests and reviews vendor DR/BCP documentation for:
- Custodians (Schwab, Fidelity, etc.)
- Email archiving provider
- CRM provider
- Email provider

**Verification Checklist:**
- [ ] Vendor has written BCP
- [ ] Vendor conducts annual BCP testing
- [ ] Vendor has geographically diverse data centers
- [ ] Vendor has redundant systems (failover capability)
- [ ] Vendor has SLA for recovery time (<24 hours)
- [ ] Vendor provides status page for outage notifications

---

## 8. Client Communication

### A. Communication Channels

**Primary:**
- Email (blackroad.systems@gmail.com)
- Office phone (forwarded to mobile if office down)
- Firm website

**Backup:**
- Mobile phone (Principal direct line)
- Personal email (if firm email down)
- Client portal (if available)

**Emergency Mass Communication:**
- Email blast to all clients (via CRM system)
- Website banner notification
- Social media update (LinkedIn if used professionally)

### B. Communication Templates

**Template 1: Office Closure Notification**
```
Subject: BlackRoad OS - Temporary Office Closure

Dear Valued Clients,

Due to [reason], our office is temporarily closed. We want to assure you that:

✅ Your accounts are SAFE - all assets remain at [Custodian Name]
✅ You can still access your accounts via [custodian website/phone]
✅ We are fully operational remotely and monitoring your portfolios
✅ You can reach us via:
   - Email: blackroad.systems@gmail.com
   - Mobile: [Phone Number]

We expect to [resume normal operations on [date]].

Thank you for your patience.

Sincerely,
Alexa Amundson
Principal & Chief Compliance Officer
BlackRoad OS, Inc.
```

**Template 2: Cybersecurity Incident Notification**
```
Subject: IMPORTANT: Security Incident Notification

Dear [Client Name],

We are writing to inform you of a cybersecurity incident that may have affected your personal information.

What Happened: [Brief description]
What Information Was Involved: [Specific data types]
What We Are Doing: [Actions taken]
What You Can Do: [Recommendations]

For questions: blackroad.systems@gmail.com or [Phone]

Sincerely,
Alexa Amundson
Chief Compliance Officer
BlackRoad OS, Inc.
```

---

## 9. Vendor and Service Provider Continuity

### A. Critical Vendor List

| Vendor | Criticality | Alternative Provider (if vendor fails) |
|--------|-------------|----------------------------------------|
| Custodian | **CRITICAL** | Transfer accounts to alternate custodian (30-60 days) |
| Email Archiving | **CRITICAL** | Global Relay, Proofpoint (migrate data) |
| CRM | **HIGH** | Wealthbox, Salesforce (data migration) |
| Email | **HIGH** | Google Workspace (change MX records) |
| Internet Provider | **HIGH** | Mobile hotspot |

### B. Vendor Failure Procedures

**Custodian Failure:**
1. **Immediate:** Verify SIPC protection ($500K per account)
2. **24 Hours:** Contact alternate custodian
3. **48 Hours:** Initiate ACATS transfer to new custodian
4. **30-60 Days:** Complete full account migration
5. **Client Communication:** Daily updates during transition

**Technology Vendor Failure:**
1. Assess criticality and RTO
2. Activate backup provider or workaround
3. Migrate data from failed vendor
4. Resume operations with alternate solution
5. Update vendor due diligence procedures

### C. Vendor Due Diligence

**Annual Review (required for critical vendors):**
- [ ] Financial stability
- [ ] BCP documentation
- [ ] SOC 2 Type II audit report
- [ ] Insurance coverage
- [ ] Data security practices
- [ ] Regulatory compliance

---

## 10. Regulatory Notification

### A. SEC Notification Requirements

**When to Notify SEC:**
- Material disruption to business operations (>5 business days)
- Cybersecurity incident affecting client data
- Loss of key personnel resulting in business wind-down
- Change in principal office address (Form ADV amendment)

**How to Notify:**
- **Non-Emergency:** File Form ADV amendment via IARD
- **Emergency:** Email SEC Division of Investment Management + regional office

**Contact:**
- SEC Division of Investment Management: (202) 551-6720

### B. State Regulator Notification

**State Securities Regulator:**
- [State] Department of Commerce/Securities
- Notification requirements per state law
- Typically same as SEC (material disruptions, office changes)

### C. Other Notifications

**Insurance Company (E&O, Cyber Liability):**
- Notify within required timeframe (typically 30-60 days)
- Critical for cyber incidents (may deny coverage if late notification)

**Custodians:**
- Notify if Firm unable to access systems or perform duties
- Request custodian to accept client instructions directly

---

## 11. Testing and Maintenance

### A. Annual BCP Testing

**Full BCP Test (Annually - Q1 each year):**
1. **Tabletop Exercise:** Simulate disaster scenario
2. **Participants:** All employees, key vendors (optional)
3. **Scenario:** Rotate through different scenarios yearly
4. **Test Elements:**
   - Emergency contact list verification
   - Data backup restoration
   - Alternate location access
   - Vendor status verification
   - Client communication (draft sample emails)

**Documentation:**
- BCP test report
- Update BCP based on test findings
- Distribute updated BCP to all employees

**Test Schedule:**
- **2026:** Pandemic scenario (work-from-home)
- **2027:** Office loss scenario (natural disaster)
- **2028:** Cyberattack scenario
- **2029:** Key personnel loss scenario

### B. Quarterly BCP Review

**CCO Responsibilities (Each Quarter):**
- [ ] Verify emergency contact list current
- [ ] Test backup restoration (sample files)
- [ ] Review vendor status pages / BCP summaries
- [ ] Check alternate location readiness
- [ ] Update BCP for any business changes

### C. BCP Updates

**Update BCP When:**
- Material change to business operations
- New vendors or service providers
- Change in key personnel
- Office relocation
- Technology system changes
- Regulatory changes requiring BCP updates
- Post-disaster (lessons learned)

**Version Control:**
- BCP version number and date on each update
- Maintain prior versions for 6 years
- Distribute updated BCP to all employees

---

## 12. Plan Activation and Authority

### A. Activation Authority

**Who Can Activate BCP:**
- **Principal (Alexa Amundson):** Full authority to activate for any scenario
- **CCO (Alexa Amundson):** Full authority to activate for any scenario
- **Backup Designee:** [Name] - Authority to activate if Principal/CCO unavailable

**Activation Triggers:**
- Office inaccessible
- Pandemic or health emergency
- Technology failure affecting critical systems >4 hours
- Cyberattack or data breach
- Loss of key personnel
- Vendor failure affecting critical functions

### B. Activation Procedures

**Step 1: Assess Situation (0-30 minutes)**
- Determine nature and scope of disruption
- Identify which critical business functions affected
- Estimate duration of disruption

**Step 2: Declare Activation (30-60 minutes)**
- Principal/CCO formally declares BCP activation
- Notify all employees via phone, text, email
- Document activation (date, time, scenario, expected duration)

**Step 3: Execute Recovery Procedures (1-48 hours)**
- Follow scenario-specific procedures
- Activate backup systems and alternate locations
- Communicate with clients, vendors, regulators

**Step 4: Monitor and Adjust (Ongoing)**
- Daily status updates to all stakeholders
- Adjust recovery procedures based on evolving situation
- Track progress against RTOs

**Step 5: Deactivation and Return to Normal**
- Declare BCP deactivation when normal operations resumed
- Conduct post-incident review (lessons learned)
- Update BCP based on actual experience
- Document final report

### C. Deactivation and Post-Incident Review

**Deactivation Criteria:**
- All critical business functions restored
- RTOs achieved
- Clients fully serviced
- No ongoing threats to operations

**Post-Incident Review (Within 15 Days):**
1. **What Happened:** Chronology of events
2. **What Worked Well:** Successful elements of BCP
3. **What Didn't Work:** Deficiencies identified
4. **Action Items:** BCP updates, training needs
5. **Financial Impact:** Costs incurred, insurance claims

---

## Acknowledgment and Distribution

All employees must review this Business Continuity Plan and acknowledge understanding of their responsibilities.

**I acknowledge that:**
- I have read and understand the Business Continuity Plan
- I know my role and responsibilities during a disaster
- I have provided current emergency contact information
- I will participate in annual BCP testing
- I will report any deficiencies or suggested improvements to the CCO

---

**Name:** _______________________________
**Title:** _______________________________
**Emergency Contact (Mobile):** _______________________________
**Signature:** __________________________
**Date:** _______________________________

---

**Last Updated:** January 4, 2026
**Next Review:** January 4, 2027
**Next Test:** Q1 2026
**Approved by:** Alexa Louise Amundson, Principal & Chief Compliance Officer

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
**Devereux - Chief Compliance Officer**
**BlackRoad OS, Inc.**
