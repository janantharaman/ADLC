# TPM OOB Expert Feedback (2026-03)

**Source**: Case Study Review Doc.pdf  
**Context**: HCCL TPM solution architecture — expert review (7/10)  
**Status**: Active — MANDATORY read before TPM design/implementation  
**Location**: `.cursor/skills/cg-tpm-dev/references/` (skill-owned, not docs/)

---

## Purpose

This file is the **source of truth** for TPM OOB-first lessons from expert review. It lives in the skill folder so it is:
- Co-located with the skill that owns TPM knowledge
- In context when cg-tpm-dev or solution-architect (TPM) is invoked
- Part of the composable skill package

**Who must read this**: Solution Architect (Priya), CG TPM Developer, CG Cloud Developer (Nisha) — before any TPM design or implementation.

---

## 1. Custom Metadata for Lead Times — DON'T

**Don't**: Create `HCCL_Shipment_Lead_Time__mdt` or custom metadata for shipment lead times.

**Do**: Configure shipment lead time directly on Promotion Templates using OOB fields:
- `cgcloud__TFD_Delivery_Date_From_Offset__c` — start of date range
- `cgcloud__TFD_Delivery_Date_Thru_Offset__c` — end of date range

**Why**: OOB fields support the full date range; custom metadata adds maintenance without benefit.

---

## 2. Data Model Design — Record Types

**Don't**: Create record types `Short_Term_Promotion` and `Long_Term_Agreement` on Promotion Template.

**Do**: 
- In TPM, **only Promotion** (Advanced Promotion) uses the record type, which supports all TPM functionalities.
- The type of promotion (STP vs LTA) should be determined by **promotion details and configurations defined within the Promotion Template**.
- Use template configuration for type differentiation — no record types on Template.

**Why**: Record types on Template are not required; template configuration is sufficient.

---

## 3. Custom Object — Key Events — DON'T

**Don't**: Create custom object `HCCL_Key_Event__c`.

**Do**: Key Events are a type of promotion that differ only by promotion templates. Use:
- Promotion Template with appropriate type (e.g., "Mega Event")
- **Specific trade calendar color** in the template configuration to highlight them on the Trade Calendar

**Why**: Creating a custom object would require creating and customizing a completely new Trade Calendar. OOB handles this via template + color.

---

## 4. Custom Metadata — Status Transitions — DON'T

**Don't**: Create custom metadata `HCCL_Status_Transition_Rule__mdt`.

**Do**: Use OOB `cgcloud__Workflow_State_Transition__c` — it already supports this functionality. Additional custom fields can be added if needed.

### 4a. Template → Workflow Lookup (IMPORTANT)

**Create a lookup field on Promotion Template to `cgcloud__Workflow__c`.**

This allows workflow state transitions to be linked to specific workflows. Different promotion types (STP vs LTA) can have different workflows. The template drives which workflow applies.

### 4b. Custom LWC for Status Management

**Use a custom LWC screen** to display and manage the different stages.

- Standard picklists allow users to change status to **any** value — problematic.
- A custom screen can **restrict** users to select only the **next valid stage**.
- Control this using `cgcloud__Workflow_State_Transition__c`; apply additional rules based on business requirements.

### 4c. cgcloud-tpm-promotion Component

The **`cgcloud-tpm-promotion`** (tpm-promotion) component supports this implementation:

- Acts as a **service component** that loads a TPM Promotion
- **Exposes methods** to update the promotion state: `setPromotionField`, `setCallback('onBeforeSave')`
- **Emits events** to keep all UI components on the promotion page synchronized:
  - `onpromotionchange` — when promotion state changes
  - `ontacticschange` — when tactics change

**Implementation**: Subscribe to BOTH events for full UI synchronization.

---

## Quick Reference: Don't / Do

| Area | Don't | Do |
|------|-------|-----|
| **Lead time** | `HCCL_Shipment_Lead_Time__mdt` | `cgcloud__TFD_Delivery_Date_From_Offset__c` + `cgcloud__TFD_Delivery_Date_Thru_Offset__c` on Promotion Template |
| **Record types** | Short_Term_Promotion, Long_Term_Agreement on Template | Template configuration; Promotion uses single record type |
| **Key Events** | `HCCL_Key_Event__c` custom object | Promotion Template + trade calendar color |
| **Status transitions** | `HCCL_Status_Transition_Rule__mdt` | OOB `cgcloud__Workflow_State_Transition__c` + custom LWC + `cgcloud-tpm-promotion` |
| **Workflow linkage** | — | Lookup from Promotion Template → `cgcloud__Workflow__c` |
| **Status UI** | Standard picklist (any value) | Custom LWC restricting to valid next stages |
| **Promotion state** | Custom state management | `cgcloud-tpm-promotion` as service component (`onpromotionchange`, `ontacticschange`, `setPromotionField`, `setCallback`) |

---

## See Also

- `common-pitfalls.md` (this folder) — TPM-specific pitfalls
- `.cursor/rules/tpm-oob-first.md` — Pre-design rule
- `../SKILL.md` — CG TPM Developer skill
