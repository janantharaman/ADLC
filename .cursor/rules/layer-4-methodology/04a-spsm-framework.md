---
name: SPSM Framework
layer: 4
type: methodology
composable: true
requires: []
alwaysApply: true
crosses: all-layers
methodology: spsm
tags: [spsm, project-management, delivery, stages]
---

# SPSM Framework (Layer 4 - Methodology)

Salesforce Professional Services Methodology (SPSM) provides a structured, proven approach for delivering successful Salesforce projects.

## SPSM Core Values

1. **Business Outcomes First**: Technology serves business goals, not the other way around
2. **Collaboration & Empathy**: Partner with stakeholders, don't dictate solutions
3. **Adoption & Ownership**: Users must champion the solution for it to succeed

---

## SPSM Stages (Sequential Delivery)

### 1. PREPARE (Discovery & Planning)

**Objective**: Understand business goals, define success criteria, and plan the project

#### Key Activities

**Stakeholder Discovery**:
- Conduct interviews with key stakeholders (executives, managers, end users)
- Identify business pain points and opportunities
- Understand organizational structure and culture

**Current State Analysis (As-Is Process Mapping)**:
- Document existing business processes
- Identify manual workarounds and inefficiencies
- Catalog existing systems and integrations
- Assess data quality and migration complexity

**Define Business Objectives & KPIs**:
- Establish measurable success criteria
  - Example: "Reduce order processing time from 3 days to 1 day"
  - Example: "Increase sales rep productivity by 20%"
- Prioritize objectives based on business value

**High-Level Solution Vision**:
- Conceptual solution architecture
- Preliminary scope (in vs out)
- Identify dependencies on other systems/projects

**Risk & Dependency Assessment**:
- Technical risks (integration complexity, data migration challenges)
- Organizational risks (change management, user adoption)
- External dependencies (third-party systems, vendors)

#### Deliverables

- **Project Charter**: Vision, goals, scope, stakeholders, high-level timeline
- **Success Criteria**: Measurable KPIs and acceptance criteria
- **High-Level Roadmap**: Phased approach, major milestones
- **Risk Register**: Identified risks with mitigation strategies

#### Key Questions to Answer

- What business problem are we solving?
- What does success look like? (measurable outcomes)
- Who are the key stakeholders and decision-makers?
- What are the critical dependencies and risks?
- What's in scope vs out of scope?

---

### 2. DESIGN (Solution Design)

**Objective**: Design the future state solution in detail

#### Key Activities

**Future State Process Mapping (To-Be)**:
- Design optimized business processes
- Align processes with Salesforce best practices
- Identify automation opportunities (Flows, Apex, integrations)

**Data Model Design**:
- Object relationships (Master-Detail, Lookup)
- Custom objects and fields
- Data governance (validation rules, security model)
- Data migration strategy (source systems, transformations, quality)

**Integration Requirements**:
- Identify external systems to integrate
- Choose integration patterns (REST, SOAP, Platform Events, Middleware)
- Design authentication and error handling

**Security Model**:
- Organization-Wide Defaults (OWD)
- Profiles and Permission Sets
- Role hierarchy
- Sharing rules
- Field-Level Security (FLS)

**User Experience Design**:
- Wireframes and mockups (page layouts, Lightning pages)
- User journey mapping
- Accessibility considerations

**Technical Architecture**:
- Apex classes and triggers
- Lightning Web Components
- Batch/Queueable jobs for async processing
- Platform Events or Change Data Capture
- Custom metadata for configuration

#### Deliverables

- **Technical Design Document**: Detailed architecture, data model, integration design
- **Data Model Diagrams**: ERD (Entity Relationship Diagram) with objects, fields, relationships
- **Integration Architecture**: Endpoints, authentication, data flow diagrams
- **User Stories with Acceptance Criteria**: "As a [role], I want [feature] so that [benefit]"
- **Wireframes/Prototypes**: UI designs for key screens
- **Security Model Design**: OWD, profiles, permission sets, sharing rules

#### Key Questions to Answer

- How will the future state process work? (step-by-step)
- What data needs to be migrated, and how?
- Which systems need to integrate, and how?
- What's the security model? (who can see/edit what?)
- What does the user interface look like?
- What are the technical components? (Apex, LWC, Flows, integrations)

---

### 3. DELIVER (Build & Iterate)

**Objective**: Build and test the solution iteratively (Agile sprints)

#### Key Activities

**Configuration & Development** (in Sprints):
- Configure objects, fields, page layouts, record types
- Build Flows for automation
- Develop Apex triggers and classes
- Build Lightning Web Components
- Configure security (profiles, permission sets, sharing rules)

**Sprint Cadence**:
- Sprint Planning: Define sprint goals and user stories
- Daily Standups: Progress updates, blockers
- Sprint Review: Demo working solution to stakeholders
- Sprint Retrospective: What went well, what to improve

**Testing**:
- **Unit Testing**: Apex tests (75%+ coverage), Jest tests for LWC
- **Integration Testing**: Test integrations with external systems
- **User Acceptance Testing (UAT)**: Stakeholders validate solution meets requirements
- **Performance Testing**: Load testing for high-volume scenarios

**Data Migration Planning**:
- Extract data from source systems
- Transform data (cleanse, deduplicate, enrich)
- Load data into Salesforce (using Data Loader, ETL tools)
- Dry runs in sandbox environments

**Documentation**:
- **User Guides**: How to use new features (step-by-step instructions)
- **Admin Guides**: How to configure and maintain the solution
- **Technical Documentation**: Architecture, code comments, API docs
- **Training Materials**: Videos, slide decks, quick reference guides

#### Deliverables

- **Working Solution in Sandbox**: Fully functional solution ready for UAT
- **Test Results**: Unit test reports, integration test reports, UAT sign-off
- **Bug Tracking**: Issues logged in Jira/Rally/GitHub, resolution status
- **Data Migration Scripts**: ETL jobs, Data Loader mappings, validation queries
- **Training Materials**: User guides, admin guides, videos

#### Key Questions to Answer

- Is the solution working as designed? (functional requirements met)
- Have all critical bugs been resolved?
- Is the data migration strategy validated? (dry runs successful)
- Are users trained and ready to adopt the solution?
- Is the documentation complete and accurate?

---

### 4. DEPLOY (Go-Live)

**Objective**: Launch the solution to production and support users through transition

#### Key Activities

**Production Deployment**:
- Deploy metadata to production (Change Sets, Salesforce DX, DevOps tools)
- Verify deployment (run smoke tests, validate configuration)
- Enable features for users (permission sets, feature flags)

**Data Migration Execution**:
- Extract, Transform, Load (ETL) final production data
- Validate data integrity (record counts, relationships, field values)
- Handle errors and exceptions (duplicate detection, missing records)

**Go-Live Validation**:
- Smoke testing in production (key user journeys)
- Monitor system performance (API usage, CPU time, SOQL queries)
- Verify integrations are working (check external system logs)

**User Training**:
- Conduct live training sessions (demos, hands-on exercises)
- Distribute training materials (user guides, videos)
- Establish support channels (help desk, Slack/Teams, email)

**Hypercare Support** (1-2 weeks post-launch):
- Dedicated support team available for immediate issue resolution
- Daily standups to triage and prioritize issues
- Monitor adoption metrics (logins, feature usage, reports run)

**Change Management**:
- Communicate launch to all users (email, town halls)
- Celebrate early wins (success stories, user testimonials)
- Address concerns and resistance (empathy, training, support)

#### Deliverables

- **Production Environment Live**: Solution deployed and accessible to users
- **Data Migrated Successfully**: All production data loaded and validated
- **Trained Users**: Training sessions completed, materials distributed
- **Support Plan**: Hypercare team identified, escalation paths defined
- **Go-Live Checklist**: All pre-launch tasks completed and verified

#### Key Questions to Answer

- Is the production deployment successful? (no critical errors)
- Is the data migration complete and accurate?
- Are users trained and confident using the new solution?
- Is the support team ready to handle issues?
- How are we measuring adoption and success?

---

### 5. GOVERN (Continuous Improvement)

**Objective**: Maintain and improve the solution over time

#### Key Activities

**Monitor KPIs & Business Outcomes**:
- Track success metrics defined in PREPARE stage
- Generate reports and dashboards (adoption, performance, ROI)
- Compare actual results to project goals

**Gather User Feedback**:
- Conduct user surveys (satisfaction, pain points, feature requests)
- Hold feedback sessions (focus groups, office hours)
- Monitor support tickets (common issues, feature gaps)

**Prioritize Enhancements**:
- Maintain a product backlog (new features, improvements, bug fixes)
- Prioritize based on business value and user impact
- Plan enhancement releases (minor updates, major releases)

**Regular Health Checks**:
- Review system performance (governor limits, API usage, storage)
- Audit security model (profiles, permission sets, sharing rules)
- Review code quality (test coverage, technical debt, best practices)
- Update documentation (reflect changes, retire outdated content)

**Ongoing Training & Adoption**:
- Onboard new users (training materials, mentorship)
- Refresh training for existing users (new features, best practices)
- Build a community of champions (power users, admins)

#### Deliverables

- **Performance Reports**: KPI dashboards, adoption metrics, ROI analysis
- **Enhancement Backlog**: Prioritized list of new features and improvements
- **Health Check Reports**: System performance, security audit, technical debt assessment
- **Updated Documentation**: Reflects current state of the solution
- **Ongoing Support Model**: SLAs, support channels, escalation paths

#### Key Questions to Answer

- Are we achieving the business outcomes we set out to achieve?
- What are users saying? (feedback, feature requests)
- What enhancements should we prioritize next?
- Is the system healthy? (performance, security, maintainability)
- How can we improve adoption and user satisfaction?

---

## When to Apply SPSM

**SPSM applies to ALL project work**, not just large implementations:

- ✅ **Large Implementations** (6+ months): Full SPSM stages (Prepare → Design → Deliver → Deploy → Govern)
- ✅ **Medium Projects** (1-6 months): Abbreviated SPSM (shorter Prepare/Design, iterative Deliver)
- ✅ **Small Enhancements** (< 1 month): Lightweight SPSM (quick discovery, design, build, deploy)
- ✅ **Bug Fixes**: Minimal SPSM (understand problem, design fix, test, deploy, monitor)

**The key is to scale SPSM appropriately to the size and complexity of the work.**

---

## SPSM Stage Awareness for Employees

As an employee, always know **which SPSM stage** you're in:

**In PREPARE?**
- Focus on understanding business goals and defining success
- Ask questions, listen, empathize with stakeholders
- Don't jump to solutions too quickly (understand the "why" first)

**In DESIGN?**
- Focus on designing the right solution (not just a solution)
- Evaluate multiple options, discuss trade-offs
- Apply Well-Architected principles (Trusted, Easy, Adaptable)
- Consider Configuration-First (declarative before code)

**In DELIVER?**
- Focus on building production-ready quality
- Test thoroughly (unit, integration, UAT)
- Iterate based on feedback
- Document as you go

**In DEPLOY?**
- Focus on successful go-live
- Minimize disruption to users
- Validate deployment, monitor closely
- Provide hypercare support

**In GOVERN?**
- Focus on continuous improvement
- Monitor KPIs, gather feedback, prioritize enhancements
- Keep the solution healthy and maintainable
- Foster user adoption and satisfaction

---

## SPSM Best Practices

1. **Engage Stakeholders Early and Often**: Don't design in isolation; collaborate continuously
2. **Iterate, Don't Waterfall**: Deliver in sprints, get feedback, adjust
3. **Measure What Matters**: Define success criteria upfront, track progress
4. **Manage Change Proactively**: User adoption is critical; invest in training and support
5. **Document as You Go**: Don't leave documentation for the end; it never gets done
6. **Celebrate Wins**: Recognize successes, build momentum, keep stakeholders engaged

---

## Quick Reference: SPSM Stages at a Glance

| Stage | Objective | Key Activities | Deliverables |
|-------|-----------|----------------|--------------|
| **PREPARE** | Understand goals, plan project | Discovery, as-is analysis, define KPIs, identify risks | Project charter, success criteria, roadmap |
| **DESIGN** | Design future state solution | To-be process, data model, integrations, security, UX | Technical design, data model, user stories, wireframes |
| **DELIVER** | Build & test iteratively | Configure, develop, test, migrate data, document | Working sandbox, test results, migration scripts, training materials |
| **DEPLOY** | Launch to production | Deploy metadata, migrate data, train users, hypercare support | Production live, data migrated, trained users, support plan |
| **GOVERN** | Maintain & improve | Monitor KPIs, gather feedback, prioritize enhancements, health checks | Performance reports, enhancement backlog, health check reports |

---

**SPSM is not just for large projects. It's a mindset: understand before designing, design before building, test before deploying, monitor after launching.**

**Applies to**: All Salesforce employees (Architects, Developers, Admins) and ALL project sizes
