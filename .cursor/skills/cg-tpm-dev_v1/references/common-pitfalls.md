# Common Pitfalls for CG Cloud TPM Developers 🚧

**Role**: CG Cloud TPM Developer
**Updated**: 2026-03-06

---

## TPM-Specific Pitfalls

### ❌ Pitfall #1: TPM OOB Anti-Patterns (Expert Feedback 2026-03-06)

**Date**: 2026-03-06
**Context**: HCCL TPM solution architecture — expert review (7/10) via Case Study Review Doc.pdf
**Category**: CG Cloud OOB Alignment / Configuration-First

**What went wrong**:
Four custom solutions where OOB exists: (1) Lead time metadata; (2) Record types; (3) Key Event custom object; (4) Status transition custom metadata.

**Don't / Do**:

| Don't | Do |
|-------|-----|
| `HCCL_Shipment_Lead_Time__mdt` | OOB `cgcloud__TFD_Delivery_Date_From_Offset__c` + `cgcloud__TFD_Delivery_Date_Thru_Offset__c` on Promotion Template |
| Record types Short_Term_Promotion, Long_Term_Agreement | Template configuration; Promotion uses single record type |
| `HCCL_Key_Event__c` custom object | Promotion Template + trade calendar color |
| `HCCL_Status_Transition_Rule__mdt` + Validation + Apex | OOB `cgcloud__Workflow_State_Transition__c` + lookup Template→`cgcloud__Workflow__c` + custom LWC + `cgcloud-tpm-promotion` |

**Additional granular details** (from Case Study Review Doc):
- **Template→Workflow lookup**: Create lookup on Promotion Template to `cgcloud__Workflow__c` — enables workflows specific to promotion types (STP vs LTA).
- **cgcloud-tpm-promotion**: Acts as service component — loads TPM Promotion, exposes methods to update state, emits events to keep all UI components on promotion page synchronized.

**Why this matters**:
Avoids over-engineering; aligns with platform upgrades; expert validation confirms OOB is sufficient.

**Lesson learned**:
Before designing any TPM custom object or metadata, validate OOB alternatives in sandbox and read lessons learned.

**Prevention added to checklist**:
- [ ] Read `tpm-oob-expert-feedback-2026-03.md` (this folder) before TPM design
- [ ] Use `cgcloud-tpm-promotion` API for promotion state changes (service component, methods + events)
- [ ] Validate `cgcloud__Workflow_State_Transition__c` in sandbox before custom workflow
- [ ] Add lookup Promotion Template → `cgcloud__Workflow__c` for promotion-type-specific workflows

**Status**: Active reference — see `tpm-oob-expert-feedback-2026-03.md` (this folder)

---

### ❌ Pitfall #2: Wrong Namespace for cgcloud-tpm-promotion (Deployment Failure)

**Date**: 2026-03-06
**Context**: HCCL TPM — hcclPromotionStatusManager LWC embedding cgcloud-tpm-promotion
**Category**: LWC / CG Cloud OOB / Deployment

**What went wrong**:
Used `<c-cgcloud-tpm-promotion>` in HTML. Deployment failed with: "No MODULE named markup://c:cgcloudTpmPromotion found"

**Root cause**:
The `cgcloud-tpm-promotion` component is from the **Consumer Goods Cloud managed package** (namespace `cgcloud`). The `c-` prefix resolves to the default namespace, not the package namespace.

**Incorrect approach**:
```html
<c-cgcloud-tpm-promotion promotion-id={recordId} ...></c-cgcloud-tpm-promotion>
```

**Correct approach**:
```html
<cgcloud-tpm-promotion promotion-id={recordId} ...></cgcloud-tpm-promotion>
```

**Why this matters**:
Deployment fails; "Promotion component not found" at runtime if it somehow bypassed.

**Lesson learned**:
When embedding OOB components from managed packages in LWC, use the **package namespace prefix** (e.g. `cgcloud-tpm-promotion`), not the default `c-` prefix.

**Prevention added to checklist**:
- [ ] CG Cloud OOB components: Use `<cgcloud-componentname>` or `<cgcloud_componentname>` in HTML — never `c-cgcloud-*`
- [ ] Before deploy: Verify component namespaces for any managed-package references

**Status**: Active reference

---

### ❌ Pitfall #3: Not Embedding cgcloud-tpm-promotion — "Promotion component not found"

**Date**: 2026-03-06
**Context**: HCCL TPM — hcclPromotionStatusManager calling setPromotionField
**Category**: LWC / CG Cloud OOB / Integration

**What went wrong**:
LWC tried to find `cgcloud-tpm-promotion` via `document.querySelector` or `closest('article')`, assuming it existed elsewhere on the page. Result: "Promotion component not found" when clicking Apply Transition.

**Root cause**:
Relying on the promotion form/component being present on the same page. If the page layout doesn't include it, or the component isn't in the DOM yet, `findPromotionComponent()` returns null.

**Correct approach**:
**Embed** `cgcloud-tpm-promotion` in your LWC's HTML (e.g. in a hidden div) so you always have a reference:

```html
<template lwc:if={showPromotionHost}>
    <div class="slds-hide" data-id="promotion-host">
        <cgcloud-tpm-promotion
            promotion-id={recordId}
            onpromotionchange={handlePromotionChange}
            ontacticschange={handleTacticsChange}
        ></cgcloud-tpm-promotion>
    </div>
</template>
```

**Optional events** (per CG Cloud API): `onstatuschange`, `oneditmodechange`, `oneffectivecategorieschange` — add handlers if your use case needs them.

**Why this matters**:
Without embedding, `this.template.querySelector('cgcloud-tpm-promotion')` returns null; setPromotionField/setCallback fail.

**Lesson learned**:
When your LWC needs to call `setPromotionField`, `setCallback`, etc., **embed** cgcloud-tpm-promotion in your HTML. Don't rely on it existing elsewhere on the page.

**Prevention added to checklist**:
- [ ] LWC calling setPromotionField: Embed `<cgcloud-tpm-promotion>` in your template (hidden if page already shows promotion form)
- [ ] Wire events: onpromotionchange, ontacticschange (and onstatuschange, oneditmodechange, oneffectivecategorieschange if needed)

**Status**: Active reference

---

### ❌ Pitfall #4: Custom Cards Editable When Not in Edit Mode (Key Event Selector 2026-03-11)

**Date**: 2026-03-11
**Context**: TPM Key Event selector card — users could change Key Event dropdown even when promotion was in view mode
**Category**: LWC / cgcloud-tpm-promotion / Edit-Mode Sync

**What went wrong**:
Custom LWC cards (e.g. Key Event selector) that call `setPromotionField` were editable in both view and edit mode. The package promotion component (`cgcloud-tpm-promotion`) has distinct edit/view states, but custom cards did not subscribe to `oneditmodechange`.

**Root cause**:
Only `onpromotionchange` was wired; `oneditmodechange` was not. The card had no awareness of whether the user had clicked Edit.

**Correct approach**:
1. Subscribe to `oneditmodechange` on `cgcloud-tpm-promotion`
2. Store `editMode` (e.g. `event.detail.value === true`)
3. Disable editable controls when `!editMode` (combobox, inputs)
4. Keep navigation actions (e.g. "Open Key Event") enabled in view mode — they don't change data

```html
<cgcloud-tpm-promotion
    promotion-id={recordId}
    oneditmodechange={handleEditModeChange}
    onpromotionchange={handlePromotionChange}
></cgcloud-tpm-promotion>
```

```javascript
handleEditModeChange(event) {
    this.editMode = event?.detail?.value === true;
}
get disableCombobox() {
    return this.isLoading || !this.editMode;
}
```

**Why this matters**:
Users expect consistency: if the main promotion form is read-only in view mode, custom cards should be too. Prevents accidental changes and confusion.

**Lesson learned**:
When building custom cards that write to promotion fields via `setPromotionField`, always subscribe to `oneditmodechange` and disable editable controls when `!editMode`.

**Prevention added to checklist**:
- [ ] Custom cards with editable controls: Wire `oneditmodechange` and disable inputs when `!editMode`
- [ ] Navigation-only actions (Open, View): Keep enabled in view mode

**Status**: Active reference

---

### ❌ Pitfall #5: Full Project Deploy Fails Due to Pre-Existing Metadata Errors (2026-03-11)

**Date**: 2026-03-11
**Context**: Deploying Key Event + Related Promotions LWC cards; full `sf project deploy start --source-dir force-app` failed
**Category**: Deployment / CI-CD

**What went wrong**:
Full deployment rolled back with 65 component errors. All errors were in **pre-existing** metadata (e.g. `CustomObjectTranslation` layout section mismatches: "Couldn't locate layout section X in layout Y"). Our new LWC components had no errors.

**Root cause**:
`rollbackOnError: true` (default) — any component failure rolls back the entire deployment. Org had stale/out-of-sync object translations.

**Correct approach**:
Deploy only the changed components when full deploy fails due to unrelated metadata:

```bash
sf project deploy start --metadata LightningComponentBundle:tpmKeyEventSelectorCard LightningComponentBundle:tpmRelatedPromotionsCard
```

**Why this matters**:
Unblocks delivery when org has legacy metadata issues. Lets you ship your changes without fixing unrelated components.

**Lesson learned**:
For targeted changes, use `--metadata` to deploy specific components. Reserve full `--source-dir force-app` for clean orgs or after resolving metadata errors.

**Prevention added to checklist**:
- [ ] If full deploy fails: Check `componentFailures` — are errors in your code or pre-existing metadata?
- [ ] For LWC-only changes: Use `--metadata LightningComponentBundle:ComponentName`
- [ ] Consider fixing or excluding problematic metadata (e.g. object translations) in a separate change

**Status**: Active reference

---

## Pitfall Categories

### 1. TPM OOB Validation (Expert Feedback 2026-03-06)

**Watch for**:
- **Lead time**: Custom metadata for lead times — use OOB `cgcloud__TFD_Delivery_Date_From_Offset__c` + `cgcloud__TFD_Delivery_Date_Thru_Offset__c`
- **Record types**: Record types on Promotion Template — use template configuration; Promotion uses single record type
- **Key Events**: Custom Key Event object — use Promotion Template + trade calendar color
- **Workflow**: Custom status transition metadata — use OOB `cgcloud__Workflow_State_Transition__c` + Template→Workflow lookup + LWC
- **cgcloud-tpm-promotion**: Use as service component (methods + events) for UI synchronization
- **Embedding**: Embed it in your LWC HTML when you need setPromotionField/setCallback — don't rely on it elsewhere on the page

**Prevention**: Read `tpm-oob-expert-feedback-2026-03.md` (this folder); sandbox validation before custom design.

---

### 2. LWC and Promotion UI

**Watch for**:
- **Wrong namespace**: Using `<c-cgcloud-tpm-promotion>` — use `<cgcloud-tpm-promotion>` (package namespace, not default `c`)
- Building promotion-related LWCs without using `cgcloud-tpm-promotion` API
- Standard picklist for status (allows any value) — use custom LWC to restrict valid next stages
- Ignoring `cgcloud-tpm-promotion` as service component — it loads promotion, exposes methods, emits events for UI sync
- **Validation-heavy status UI** — validating/restricting after user selects; causes user errors and unnecessary validation logic

**Prevention**: Use `cgcloud-tpm-promotion` for state updates; `setPromotionField`, `onBeforeSave`, `setCallback`; subscribe to events for UI synchronization.

**Status LWC UX (Prevention over Validation)**:
- **Don't**: Show standard picklist + validate/restrict invalid transitions
- **Do**: Display **Current status** (read-only) + **dropdown of valid next statuses only** (from `cgcloud__Workflow_State_Transition__c`). User cannot pick invalid — no validation needed.

---

## Quick Prevention Checklist

- [ ] **TPM OOB**: Read lessons learned before designing; validate OOB in sandbox
- [ ] **Workflow**: Use `cgcloud__Workflow_State_Transition__c` + LWC; not custom metadata
- [ ] **LWC**: Use `cgcloud-tpm-promotion` API for promotion state changes
- [ ] **Namespace**: Use `<cgcloud-tpm-promotion>` in HTML — never `c-cgcloud-tpm-promotion`
- [ ] **Embedding**: Embed cgcloud-tpm-promotion in your LWC HTML when calling setPromotionField — don't rely on page layout
- [ ] **Status UI**: Prevention over validation — show Current status + dropdown of valid next only; avoid validation logic
- [ ] **Edit-mode sync**: Wire oneditmodechange; disable editable controls when !editMode
- [ ] **Deploy**: If full deploy fails on pre-existing metadata, use --metadata for specific components

---

## See Also

- **Lessons Learned**: `tpm-oob-expert-feedback-2026-03.md` (this folder) — source of truth
- **Rule**: `.cursor/rules/tpm-oob-first.md`
- **Team-Wide**: `../_shared/common-pitfalls.md`
