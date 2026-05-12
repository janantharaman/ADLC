# Salesforce Architecture References

**Source**: architect.salesforce.com - Well-Architected Framework

This directory contains detailed architectural patterns extracted from the official Salesforce Architect website.

## Contents

### 1. Well-Architected: 24 Patterns
**File**: `well-architected-24-patterns.md` (36KB)

Complete catalog of all 24 Well-Architected patterns across three pillars:

#### 🛡️ TRUSTED Pillar (8 Patterns)
1. **Defense in Depth** - Multiple overlapping security controls
2. **Least Privilege Access** - Minimum permissions required
3. **Data Classification & Protection** - Classify and protect by sensitivity
4. **Encryption at Rest & in Transit** - Encrypt data in all states
5. **Performance by Design** - Build performance in from the start
6. **Observability & Monitoring** - Proactive monitoring and alerting
7. **Resilience & Fault Tolerance** - Design for failure, build redundancy
8. **Disaster Recovery & Business Continuity** - Backup, recovery, continuity planning

#### 🎯 EASY Pillar (8 Patterns)
9. **Progressive Disclosure** - Show what's needed, when needed
10. **Declarative First** - Use declarative tools before code
11. **Self-Service & Guided Experiences** - Self-documenting UI with guidance
12. **Consistent UI/UX** - Use Salesforce Lightning Design System
13. **Testable & Maintainable Code** - Clean, testable, documented code
14. **Documentation as Code** - Document within code, automate
15. **Reusable Components** - Build component library
16. **Usability Testing** - Test with real users iteratively

#### 🔄 ADAPTABLE Pillar (8 Patterns)
17. **Configuration Over Customization** - Externalize configuration to metadata
18. **API-First Design** - Design APIs before implementation
19. **Event-Driven Architecture** - Use events for decoupled communication
20. **Microservices Architecture** - Decompose into smaller, focused services
21. **Data Archival & Retention** - Archive old data, retain what's needed
22. **Multi-Tenant Architecture** - Design for multi-tenancy from the start
23. **Horizontal & Vertical Scaling** - Scale in multiple dimensions
24. **Graceful Degradation** - Degrade functionality, don't break

---

### 2. Session Security Patterns
**File**: `session-security-patterns.md` (50KB, 1,946 lines)

Detailed session security patterns extracted from architect.salesforce.com screenshots:

#### Pattern Hierarchy
```
Well-Architected
└─ Trusted
   └─ Secure
      └─ Session Security
         ├─ Device Access Pattern
         ├─ Session Management Pattern
         ├─ Session Timeout Pattern
         ├─ Multi-Factor Authentication (MFA) Pattern
         ├─ IP Restrictions Pattern
         ├─ Single Sign-On (SSO) Pattern
         └─ Threat Detection & Response Pattern
```

#### Patterns Included

**Pattern 1: Device Access Pattern**
- Map security personas to device policies
- Configure Salesforce mobile security
- API Access Control for mobile
- Implementation checklist with code examples

**Pattern 2: Session Management Pattern** ⭐ (From Screenshot 1)
- Custom login flow session management (Apex, Aura, LWC)
- Security persona session standards
- Elevated session-level security
- Connected app scope & token management
- Login hours configuration

**Pattern 3: Session Timeout Pattern**
- Timeout configuration by user type
- Profile-based session timeout
- Organization-wide defaults
- Session monitoring code

**Pattern 4: Multi-Factor Authentication (MFA) Pattern**
- MFA policy levels (Basic, Standard, High Security)
- User enrollment process
- Exception handling
- Code examples for MFA verification

**Pattern 5: IP Restrictions Pattern**
- IP restriction strategy by user type
- Configuration per profile
- Organization-wide trusted IPs
- Exception handling

**Pattern 6: Single Sign-On (SSO) Pattern**
- SAML 2.0 configuration
- Just-in-Time (JIT) provisioning
- Attribute mapping
- Testing scenarios

**Pattern 7: Threat Detection & Response Pattern** ⭐ (From Screenshots 2 & 3)
- Einstein Agent event logging
- Einstein Trust Layer audit
- Audit data reporting for stakeholders
- Regular audit reviews
- Automated response documentation
- Log review process
- Audit level specification
- Security event response policies
- Real-time threat response automation
- Anomalous activity notifications
- **Field History tracking for sensitive data** ⭐ (From Screenshot 3)

---

## Pattern Format (Official Salesforce Format)

All patterns follow the official architect.salesforce.com format:

```
Pattern Name: [Pattern Name]
Category: [Hierarchy Path]
Purpose: [What it solves]

Implementation Checklist:
┌─────────────────────────────────┬────────────────────────────────┐
│ Where to look?                  │ What does good look like?      │
│ Product Area | Location         │ Pattern                        │
├─────────────────────────────────┼────────────────────────────────┤
│ Platform | Apex                 │ ✅ Pattern implementation      │
│ Platform | Aura                 │ ✅ Pattern implementation      │
│ Platform | LWC                  │ ✅ Pattern implementation      │
│ Platform | Design Standards     │ ✅ Pattern documentation       │
│ Platform | Documentation        │ ✅ Pattern guidance            │
│ Platform | Org                  │ ✅ Pattern configuration       │
└─────────────────────────────────┴────────────────────────────────┘

[Implementation details with code examples]
```

---

## Screenshots Captured

### Screenshot 1: Device Access Pattern
**Content**: Device security and mobile app policies
- Security personas mapped to device policies
- Mobile PIN/passcode requirements
- API Access Control configuration

### Screenshot 2: Session Management Pattern
**Content**: Custom login flows and session security
- Apex: Use Auth.SessionManagement methods
- Aura/LWC: Use Apex controller with SessionManagement
- Security persona session standards
- Elevated security requirements
- Connected app scope and token management
- Login hours configuration

### Screenshot 3: Threat Detection & Response Pattern
**Content**: Monitoring, auditing, and automated responses
- Einstein Agent event logs (conversation data)
- Einstein Trust Layer audit (Generative AI)
- Audit data reporting for stakeholders
- Regular audit reviews schedule
- Automated response documentation
- Log review procedures
- Audit level specification per object
- Security event response matrix
- Real-time threat automation
- Anomalous activity alerts
- **Field History tracking for sensitive data**

---

## Key Features

### 1. Production-Ready Code Examples
Every pattern includes:
- ✅ Complete Apex implementations
- ✅ Aura component examples
- ✅ Lightning Web Component (LWC) examples
- ✅ Configuration steps
- ✅ Testing approaches

### 2. Official Salesforce Format
- ✅ Exact format from architect.salesforce.com
- ✅ "Where to look?" and "What does good look like?" structure
- ✅ Product Area | Location format
- ✅ Checkboxes for each pattern item

### 3. Comprehensive Coverage
- ✅ Security personas and policies
- ✅ Session management and timeout
- ✅ MFA and IP restrictions
- ✅ SSO and identity management
- ✅ Threat detection and response
- ✅ Audit and compliance

### 4. Implementation Guidance
- ✅ Step-by-step configuration
- ✅ Best practices
- ✅ Anti-patterns to avoid
- ✅ Testing strategies
- ✅ Monitoring and alerting

---

## Usage

### For Architects
Reference these patterns when:
- Designing security architecture
- Planning session management strategy
- Implementing threat detection
- Configuring audit and compliance
- Making architectural decisions

### For Developers
Use code examples for:
- Custom login flow implementation
- Session security enforcement
- Token management
- Threat response automation
- Audit logging

### For Security Teams
Use checklists for:
- Security posture assessment
- Compliance verification
- Audit trail configuration
- Threat response planning
- Regular security reviews

### For Administrators
Use configuration guides for:
- User profile setup
- Permission set configuration
- Connected app policies
- Session timeout settings
- Field history tracking

---

## Statistics

| File | Lines | Size | Patterns |
|------|-------|------|----------|
| well-architected-24-patterns.md | 1,343 | 36KB | 24 patterns |
| session-security-patterns.md | 1,946 | 50KB | 7 patterns |
| **Total** | **3,289** | **86KB** | **31 patterns** |

---

## Implementation Checklist

When implementing session security:

**Phase 1: Device Access** ✅
- [ ] Map security personas to device policies
- [ ] Configure Salesforce mobile security (PIN/passcode)
- [ ] Enable API Access Control
- [ ] Test device policies per persona

**Phase 2: Session Management** ✅
- [ ] Document security persona standards
- [ ] Define session timeout policies
- [ ] Implement elevated security for sensitive operations
- [ ] Configure connected app token policies
- [ ] Set login hours restrictions

**Phase 3: Authentication** ✅
- [ ] Enable MFA organization-wide
- [ ] Configure IP restrictions per profile
- [ ] Set up SSO with identity provider
- [ ] Test authentication flows

**Phase 4: Threat Detection** ✅
- [ ] Enable Einstein Agent event logging
- [ ] Configure Einstein Trust Layer audit
- [ ] Set up audit data dashboards
- [ ] Enable Field History tracking for sensitive data
- [ ] Document automated responses
- [ ] Configure real-time threat automation
- [ ] Set up anomalous activity alerts

**Phase 5: Monitoring** ✅
- [ ] Establish regular audit review schedule
- [ ] Create compliance reports
- [ ] Configure monitoring dashboards
- [ ] Test alert notifications

---

## Resources

- **Official Site**: https://architect.salesforce.com/
- **Well-Architected Framework**: https://architect.salesforce.com/design/well-architected
- **Session Security**: Navigate to Trusted → Secure → Session Security
- **Integration Patterns**: https://architect.salesforce.com/design/integration-patterns
- **Reference Architectures**: https://architect.salesforce.com/diagrams

---

## Updates

- **2024-02-28**: Created from architect.salesforce.com screenshots
  - Added Device Access Pattern
  - Added Session Management Pattern (from screenshot)
  - Added Threat Detection & Response Pattern (from screenshots)
  - Added Field History tracking requirement
  - All patterns include complete code examples
  - All patterns follow official Salesforce format

---

## Contributing

To add more patterns from architect.salesforce.com:

1. **Capture screenshot** of the pattern page
2. **Extract checklist items** (Where to look? / What does good look like?)
3. **Add implementation details** with code examples
4. **Follow official format** (Product Area | Location structure)
5. **Test code examples** in Salesforce org
6. **Update this README** with new pattern info

---

**Remember**: These patterns represent **official Salesforce architectural best practices**. Apply them based on your specific requirements and constraints.
