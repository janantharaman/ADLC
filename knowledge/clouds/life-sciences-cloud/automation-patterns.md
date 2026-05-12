---
source: Life Sciences Cloud Developer Guide (1869p); Spring '26 / v66.0; grounded 2026-05-11
cloud: Life Sciences Cloud
section: automation-patterns
last-updated: 2026-05-11
---

# Life Sciences Cloud — Automation Patterns

## Platform Events (PDF p.1368-1370)

LSC provides two platform events for asynchronous notification:

### ApplnFormAppealStsChgEvnt (API v63.0+)
Notifies subscribers when the status of a Financial Assistance Program appeal changes.

**Supported Calls:** `create()`, `describeSObjects()`

**Special Access:** Health Cloud Starter AND Manage Financial Assistance Program permission set required.

| Field | Type | Properties | Description |
|---|---|---|---|
| `AppealIdentifier` | string | Create, Nillable | Identifier of the appeal that changed status |
| `AppealStatus` | picklist | Create, Nillable, Restricted | Status of the appeal: `Accepted`, `Rejected` |
| `ApplicationFormIdentifier` | string | Create, Nillable | Identifier of the application associated with the appeal |
| `EventCreationDateTime` | dateTime | Create, Nillable | When the event was created |

**Apex Subscribe Pattern:**
```apex
EventBus.TriggerContext ctx = EventBus.TriggerContext.currentContext();
List<ApplnFormAppealStsChgEvnt> events = (List<ApplnFormAppealStsChgEvnt>) Trigger.new;
for (ApplnFormAppealStsChgEvnt evt : events) {
    // Process appeal status change
    String appealId = evt.AppealIdentifier;
    String status = evt.AppealStatus;
    // Update related Financial Assistance records
}
EventBus.TriggerContext.currentContext().setResumeCheckpoint(events[events.size()-1].ReplayId);
```

---

### CareBnftVrfyRqstStsChgEvent (API v65.0+)
Notifies subscribers when the status of a care benefit verify request changes.

**Supported Calls:** `create()`, `describeSObjects()`

**Special Access:** Manage Pharmacy Benefits Verification AND Health Cloud Starter (Life Sciences Cloud) or Health Cloud Foundation (Health Cloud) required.

| Field | Type | Properties | Description |
|---|---|---|---|
| `EventCreationDateTime` | dateTime | Create, Nillable | When the event was created |
| `RecordIdentifier` | string | Create | Identifier of the associated CareBenefitVerifyRequest record |
| `Status` | string | Create | Status of the care benefit verify request |

---

## Standard Invocable Actions (PDF pp.1742-1759)

### Clinical Trial Randomization Actions

**Assign Candidates to Research Study Group**
- **Action name:** `assignCndtToResearchStudyGroup`
- **Purpose:** Assign candidates enrolled in clinical trials to research study comparison groups through randomization
- **FlowActionCall `actionType`:** `assignCndtToResearchStudyGroup`

**Generate Research Study Blocks**
- **Action name:** `generateResearchStudyBlocks`
- **Purpose:** Generate research study randomization block records linking each block with a specific comparison group
- **FlowActionCall `actionType`:** `generateResearchStudyBlocks`

### AI / Generative Actions

**Get Context Data**
- **Action name:** `getContextData`
- **Purpose:** Retrieves context data passed as input to a prompt template that generates a summary of the data
- **FlowActionCall `actionType`:** `getContextData`

**Get Life Sciences Configuration Field Names and Values**
- **Purpose:** Retrieve configuration field names and values for LSC settings

**Process Criteria Matching Response**
- **Action name:** `processCriteriaMatchingResp`
- **Purpose:** Parses a GPT-generated JSON response to evaluate inclusion/exclusion criteria for a Research Study Candidate
- **Output:** Stores result in `CareProgramEnrollmentEvalRslt`; returns counts of matched inclusion and exclusion criteria
- **FlowActionCall `actionType`:** `processCriteriaMatchingResp`

**Serialize Hierarchical Context Data**
- **Action name:** `serializeHierarchicalContextData`
- **Purpose:** Serializes hierarchical context data from `embeddedai__RecordApexRepresentation` records for use in prompt templates
- **FlowActionCall `actionType`:** `serializeHierarchicalContextData`

### MedTech / Scheduling Actions

**Build Product Territory Detailed Availability Action**
- **Purpose:** Builds product territory detailed availability for territory management

**Work Type Lead Time (API v60.0)**
- **Purpose:** Gets a list of work types and their associated lead times optimized across regions for a specific advanced therapy

---

## Apex Namespace: `embeddedai`

The `embeddedai` namespace provides classes for embedded AI features:

### ApexMap Class
Create, clone, and convert string-based key-value pairs to JSON string format.

**Namespace:** `embeddedai`
- Used as input to prompt templates for context data generation

### RecordApexRepresentation Class
Creates a serializable representation of a record and its associated data for AI service integration.

**Namespace:** `embeddedai`

**Usage:**
```apex
embeddedai.RecordApexRepresentation rep = new embeddedai.RecordApexRepresentation();
// Populate record data for context
// Pass to serializeHierarchicalContextData action
```

---

## Automation Patterns by Use Case

### Consent Management Flow

**Pattern — Capture consent at HCP event registration:**
```
Screen Flow (Experience Cloud or internal)
  Screen: HCP details + consent checkboxes (email, phone, post, digital)
  Action: Create CommSubscription record per channel
  Action: Create CommSubscriptionConsent record per channel (OptIn/OptOut)
  Action: Create ContactPointConsent record per contact point
  Action: Update CommSubConsentCmplSnpsht (compliance snapshot)
  Screen: Confirmation
```

**Pattern — Process opt-out request:**
```
Screen Flow (triggered by email opt-out link or rep action)
  Get: Find CommSubscriptionConsent by PartyId + ChannelType
  Update: Set Status = 'OptOut' on CommSubscriptionConsent
  Update: Create new CommSubConsentCmplSnpsht snapshot record
  Send: Confirmation email via existing email template
```

**Critical Rule:** Consent records must NEVER be deleted. Add Validation Rule:
```
AND(ISPICKVAL(Status, 'OptIn'), ISNEW()) = FALSE  // allow only new OptIn creation
// Or in Apex trigger: throw DmlException on delete attempts
```

---

### Clinical Trial Enrollment Flow

**Pattern — Enroll patient in research study:**
```
Flow (triggered from ResearchStudyCandidate record)
  Screen: Verify eligibility criteria
  Action: processCriteriaMatchingResp (AI-generated criteria evaluation)
  Decision: If EligibilityResult.MatchedInclusionCount >= threshold AND ExclusionCount == 0
    Action: Create CareProgramEnrollee
    Action: Create CareProgramEnrolleeProduct (link to study product)
    Action: Update ResearchStudyCandidate.Status = 'Enrolled'
  Else
    Action: Update ResearchStudyCandidate.Status = 'Not Eligible'
```

**Randomization sub-flow:**
```
  Action: generateResearchStudyBlocks (create randomization blocks)
  Action: assignCndtToResearchStudyGroup (assign to comparison group)
  Update: ResearchStudyCandidate with assigned comparison group
```

---

### Sample Management Flow

**Pattern — Record sample disbursement with e-signature:**
```
Screen Flow (launched from Provider Visit record)
  Screen: Select products to sample, quantities
  Validate: Check ProviderSampleLimit records for compliance
  API Call: Sample Limits Validation Business API
    POST /connect/life-sciences/commercial/validate-sample-limits
  If within limits:
    Screen: Capture HCP e-signature (DigitalVerification component)
    Create: InventoryOperation (disbursement type)
    Create: DigitalVerification record linked to visit
    Update: Inventory counts via InventoryCountAssessment
  Else:
    Screen: Show limit exceeded error; prompt override with justification
```

---

### Advanced Therapy Management — Multi-Step Scheduling Flow

**Pattern — Schedule apheresis → manufacturing → infusion appointments:**
```
Flow (triggered from CareProgramEnrollee)
  Get: Work types for the advanced therapy work procedure
  API Call: Work Type Lead Time Business API
    POST /connect/health/advanced-therapy-management/work-type-lead-time
  Screen: Show available slots for each procedure step
  API Call: Book Slot Chain
    POST /connect/health/advanced-therapy-management/book-slot-chain
    Body: {careProgramEnrolleeId, workProcedureId, slots[{schedStartTime, workTypeId, serviceTerritoryId, ...}]}
  Create: ServiceAppointmentGroup record
  Update: CareProgramEnrollee status
```

---

### Financial Assistance Program Appeal

**Pattern — Process appeal status change via platform event:**
```
Apex Trigger on ApplnFormAppealStsChgEvnt__e
  → Handler: AppealStatusChangeHandler.cls
    1. Get ApplicationFormIdentifier from event
    2. Query CareProgramEnrollee by ApplicationFormIdentifier
    3. If Status = 'Accepted':
        - Update Benefit records with approved amount
        - Send welcome communication via CommSubscription
    4. If Status = 'Rejected':
        - Update enrollment status
        - Trigger rejection notification flow
```

---

### Benefit Verification (Pharmacy) Flow

**Pattern — Verify pharmacy benefits for a care program enrollee:**
```
Triggered Flow (on CareBenefitVerifyRequest creation)
  1. Call external payer system (via Named Credential + Custom Metadata)
  2. Parse response and update CareBenefitVerifyRequest.Status
  3. Platform event CareBnftVrfyRqstStsChgEvent fires automatically
  4. Downstream subscriber updates CoverageBenefit and FormularyItem records
```

---

### Provider Territory Alignment (Batch Pattern)

**Pattern — Nightly territory alignment job:**
```
Scheduled Apex (nightly)
  1. Call Territory Alignment API or trigger Territory2 rule recalculation
  2. Build Product Territory Detailed Availability:
     Action: Build Product Territory Detailed Availability
  3. Sync ProviderAcctTerritoryInfo records
  4. Sharing recalculated based on new territory assignments
  5. Update ActivityPlan records for reps in affected territories
```

---

## Automation Decision Matrix

| Use Case | Recommended Approach | Avoid |
|---|---|---|
| Consent capture from external portal | Screen Flow + CommSubscription objects | Custom Apex — use standard objects |
| Clinical trial enrollment eligibility | Flow + `processCriteriaMatchingResp` invocable action | Manual Apex evaluation |
| Multi-step appointment scheduling | Flow + Book Slot Chain Business API | Direct scheduler object DML |
| Sample limit validation | Flow + Sample Limits Validation Business API | Apex-only validation (misses real-time sync) |
| Territory alignment | Scheduled Apex or Territory2 rules | Manual account reassignment |
| Benefit verification | Triggered Flow + platform event subscriber | Synchronous callout in UI action |
| Adverse event reporting | Apex trigger on AdverseEventEntry + platform event | Flow (too slow for compliance SLAs) |
| Provider search | Provider Search Business API | Custom SOQL on CareProviderSearchableField (read-only denormalized) |
| E-signature capture | DigitalVerification + DigitalVerificationSetup | Custom signature in attachment |
| Next Best Action display | Next Best Action framework (enableNextBestAction) | Custom LWC with manual AI integration |
