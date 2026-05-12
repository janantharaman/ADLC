# Success Patterns for LWC Developers (Anjali) ✨

**Role**: LWC Developer
**Employee**: Anjali
**Updated**: Continuously as successes occur

---

## How to Use This File

**Before Starting Work**:
- Review recent successes for proven approaches to similar challenges
- Identify reusable patterns that apply to your current task

**After Exceptional Delivery**:
- This file may be updated with your success!
- Reference your own patterns for consistency

---

## LWC-Specific Success Patterns

### ✅ Success: Intuitive Card UI with Loading, Empty State, and Contextual Hints (TPM Cards 2026-03-11)

**Date**: 2026-03-11
**Context**: TPM Key Event selector + Related Promotions cards — improved from plain slds-card to production-grade UX
**Category**: UX Excellence / SLDS / Accessibility

**What worked**:
- **lightning-card** with `icon-name` and `title` for clear hierarchy (vs plain `slds-card`)
- **Loading state**: `lightning-spinner` with `alternative-text` while data loads — no blank/jumpy UI
- **Empty state**: Centered layout with icon, heading, and explanatory text (e.g. "No promotions linked yet" + "Promotions that link to this Key Event will appear here")
- **Contextual hints**: When controls are disabled (e.g. view mode), show "Click Edit above to change..." with info icon — users understand why they can't edit
- **Success feedback**: When selection exists, show "Key Event linked to this promotion" with success icon
- **Error display**: SLDS alert styling with error icon for consistency
- **Actions slot**: "Open Key Event" button in card actions; count badge ("3 promotions") for list cards

**Pattern**:
```html
<lightning-card title={cardTitle} icon-name="standard:event">
  <div slot="actions"><!-- contextual actions --></div>
  <template if:true={isLoading}>
    <lightning-spinner alternative-text="Loading..." size="medium"></lightning-spinner>
  </template>
  <template if:false={isLoading}>
    <!-- content -->
    <template if:false={editMode}>
      <div class="slds-form-element__help slds-text-color_weak">
        <lightning-icon icon-name="utility:info" size="xx-small"></lightning-icon>
        Click Edit above to change...
      </div>
    </template>
  </template>
</lightning-card>
```

**Why it matters**:
Reduces support questions, improves perceived quality, aligns with SLDS and accessibility (role="status", alternative-text).

**Reuse when**: Building record-page cards, list components, or any LWC that loads data or has disabled states.

---

## Active Success Patterns (Currently Referenced)

- **Card UI**: lightning-card + spinner + empty state + contextual hints (see above)

---

## Success Categories

### 1. UX Excellence 💫
*No patterns yet*

**Look for**:
- Intuitive user interfaces
- Accessibility excellence (WCAG compliance)
- User delight achievements

---

### 2. Performance Excellence ⚡
*No patterns yet*

**Look for**:
- Fast rendering and interactions
- Optimal data handling
- Efficient wire adapters

---

### 3. Innovation Excellence 🚀
*No patterns yet*

**Look for**:
- Novel UI patterns
- Creative component designs
- Breakthrough user experiences

---

### 4. Code Quality Excellence ✨
*No patterns yet*

**Look for**:
- Clean, reusable components
- Comprehensive testing
- Excellent documentation

---

### 5. Architectural Excellence 🏗️
*No patterns yet*

**Look for**:
- Well-structured component hierarchies
- Smart state management
- Elegant event handling

---

## Evolved to Standard Practices

*Success patterns move here when they become mandatory standards*

---

## Statistics

**Total Successes Documented**: 0
**Active References**: 0
**Evolved to Standards**: 0
**Average Measurable Impact**: N/A
**Pattern Reuse Events**: 0
**Last Updated**: N/A

---

## Quick Best-Practice Checklist

Based on documented successes:
- [ ] *No patterns yet - checklist will grow as successes are documented*

---

## See Also

- **Team-Wide Successes**: `../_shared/success-patterns.md`
- **Team Learning Log**: `../_shared/team-learnings.md`
- **Common Pitfalls**: `common-pitfalls.md`

---

*This file celebrates your exceptional work and helps you replicate excellence.*
