---
source: Consumer Goods Cloud Developer Guide (1840p); Spring '26; grounded 2026-05-11
cloud: Consumer Goods Cloud
section: metadata-tooling
last-updated: 2026-05-11
---

# Consumer Goods Cloud — Metadata & Tooling

## Metadata Types

### Summary Table

| Metadata Type | API Version | File Suffix | Directory | Wildcard (*) |
|---|---|---|---|---|
| `RetailExecutionSettings` | v47.0+ | See Settings | `settings/RetailExecution.settings` | Yes (Settings type) |
| `Sync_Ignored_Fields__mdt` | v59.0+ | `.Sync_Ignored_Fields__mdt` | Custom Metadata | Yes |
| Standard `CustomObject` | — | `.object` | `objects/` | Yes |
| Standard `Flow` | — | `.flow` | `flows/` | Yes |
| Standard `ApexClass` | — | `.cls` | `classes/` | Yes |
| Standard `LightningComponentBundle` | — | `.js-meta.xml` | `lwc/` | Yes |
| Standard `CustomMetadata` | — | `.md` | `customMetadata/` | Yes |
| Standard `PermissionSet` | — | `.permissionset` | `permissionsets/` | Yes |

---

## Metadata Type Details

### RetailExecutionSettings (v47.0+)

Represents settings to manage your inventory, promotions, planograms, and in-store activities.

This type extends the `Metadata` type and inherits its `fullName` field. Stored as a single file.

**File location:** `settings/RetailExecution.settings`  
**Package manifest:** Accessed via the `Settings` metadata type name

| Field | Type | API Version | Description |
|---|---|---|---|
| `enableRetailExecution` | boolean | v47.0+ | Enables Retail Execution. Default: false |
| `enableProductHierarchy` | boolean | v53.0+ | Enables Product Hierarchy feature |
| `enableVisitSharing` | boolean | v55.0+ | Enables Visit Share. Default: false |

**Sample XML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<RetailExecutionSettings xmlns="http://soap.sforce.com/2006/04/metadata">
  <enableRetailExecution>true</enableRetailExecution>
  <enableProductHierarchy>true</enableProductHierarchy>
  <enableVisitSharing>false</enableVisitSharing>
</RetailExecutionSettings>
```

**Package manifest:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <types>
    <members>RetailExecution</members>
    <name>Settings</name>
  </types>
  <version>55.0</version>
</Package>
```

**Wildcard support:** Yes — the `*` wildcard works for Settings metadata type.

---

### Sync_Ignored_Fields__mdt (v59.0+)

Custom metadata type for controlling which fields are excluded from mobile sync per client app.

**Type:** `CustomMetadata`  
**Directory:** `customMetadata/`

| Field | Description |
|---|---|
| `Label` | Human-readable label for this ignored field rule |
| `Client_App_Id__c` | Client app identifier this exclusion applies to |
| `Field_Api_Name__c` | API name of the field to exclude from sync |
| `Object_Api_Name__c` | API name of the object containing the excluded field |

**Package manifest:**
```xml
<types>
  <members>Sync_Ignored_Fields__mdt.*</members>
  <name>CustomMetadata</name>
</types>
```

---

### CGCloud Process Customization (Custom Metadata)

Managed package custom metadata type (`cgcloud` namespace) used to register Apex callable hooks for order customization.

| Field | Value for Order Save Hook | Value for Proposal List Hook |
|---|---|---|
| `Label` | `RE_Order_Save` | `RE_Order_Proposal_List` |
| `DeveloperName` | `RE_Order_Save` | `RE_Order_Proposal_List` |
| `Class` | Your Apex class name | Your Apex class name |
| `Method` | `save` | `proposalList` |
| `Enabled` | checked | checked |

This custom metadata type is managed by the `cgcloud` package — do not attempt to deploy its type definition. Only deploy the instance records.

---

## cgcloud Custom Object Metadata Notes

All `cgcloud__*__c` custom objects are part of the managed package and deployed WITH the package installation. You cannot retrieve or deploy the object definitions themselves via your org's `package.xml` — the managed package controls the schema.

What you CAN deploy:
- `CustomField` additions to `cgcloud__*__c` objects (your custom fields on managed objects)
- `Layout` additions
- `RecordType` additions (if allowed by the package)
- `PermissionSet` and `Profile` field-level security grants for `cgcloud__` fields
- `FlexiPage` and page layout assignments
- `Flow` records that reference `cgcloud__` objects
- `ApexClass` records in your own namespace

---

## Package XML Template — Retail Execution Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <!-- RE Feature Settings -->
  <types>
    <members>RetailExecution</members>
    <name>Settings</name>
  </types>
  <!-- Sync Ignored Fields (custom metadata instances) -->
  <types>
    <members>Sync_Ignored_Fields__mdt.*</members>
    <name>CustomMetadata</name>
  </types>
  <!-- CGCloud Process Customization instances (order hooks) -->
  <types>
    <members>cgcloud__CGCloud_Process_Customization__mdt.*</members>
    <name>CustomMetadata</name>
  </types>
  <!-- Custom Apex implementations -->
  <types>
    <members>RetailOrderSaveCustomization</members>
    <members>OrderProposalListCustomization</members>
    <name>ApexClass</name>
  </types>
  <!-- Custom LWC components for order screens -->
  <types>
    <members>*</members>
    <name>LightningComponentBundle</name>
  </types>
  <!-- Permission Sets -->
  <types>
    <members>*</members>
    <name>PermissionSet</name>
  </types>
  <!-- Flows -->
  <types>
    <members>*</members>
    <name>Flow</name>
  </types>
  <version>66.0</version>
</Package>
```

---

## Package XML Template — TPM Deployment

```xml
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
  <!-- RTR Report Configurations (as CustomMetadata instances) -->
  <types>
    <members>cgcloud__RTR_Report_Configuration__c.*</members>
    <name>CustomMetadata</name>
  </types>
  <!-- Business Object API Workflow Steps -->
  <types>
    <members>*</members>
    <name>ApexClass</name>
  </types>
  <!-- Promotion Apex customization -->
  <types>
    <members>SetCommentValue</members>
    <name>ApexClass</name>
  </types>
  <!-- Permission Sets -->
  <types>
    <members>*</members>
    <name>PermissionSet</name>
  </types>
  <version>66.0</version>
</Package>
```

---

## Deployment Order

Deploy CGC metadata in this sequence to avoid dependency errors:

1. **RetailExecutionSettings** — enable features first
2. **Permission Sets** — deploy before assigning to users
3. **Custom Metadata (Sync_Ignored_Fields__mdt)** — after sync package installed
4. **Custom Metadata (CGCloud Process Customization instances)** — after Apex classes deployed
5. **Apex Classes** — callable hooks and TPM workflow step classes
6. **Flows** — after objects and Apex available
7. **LWC Components** — after cgcloud namespace available (package installed)
8. **Page Layouts and FlexiPages** — after LWC components deployed

---

## Common Deployment Errors

| Error | Cause | Fix |
|---|---|---|
| `INVALID_TYPE` on cgcloud__*__c objects | CGC managed package not installed in target org | Install package first |
| `INVALID_TYPE` on TPM objects | TPM license not provisioned | Confirm TPM license and re-install/configure |
| `INVALID_TYPE` on cgc_sync__*__c objects | Mobile Sync package not installed | Install Mobile Sync package |
| `Cannot modify managed package metadata` | Attempting to deploy cgcloud object definitions | Remove object definitions from package.xml; only deploy instances |
| `FIELD_INTEGRITY_EXCEPTION` on RetailExecutionSettings | Feature dependency not met | Enable in correct order; `enableRetailExecution` before other flags |
| LWC not rendering in cgcloud Order page | `runtimeNamespace` not set OR LWS not enabled | Set `<runtimeNamespace>cgcloud</runtimeNamespace>` in LWC metadata, OR enable LWS |
| Order save hook not firing | `CGCloud Process Customization` record not enabled | Check `Enabled` checkbox on the custom metadata record |
| Proposal list hook not firing | `Consider Listing` not set to Yes on Order Template | Update Order Template setting |

---

## Salesforce CLI Commands

**Retrieve RetailExecutionSettings:**
```bash
sf project retrieve start \
  --metadata "Settings:RetailExecution" \
  --target-org sandbox-alias
```

**Retrieve cgcloud custom metadata instances:**
```bash
sf project retrieve start \
  --metadata "CustomMetadata:Sync_Ignored_Fields__mdt.*" \
  --target-org sandbox-alias
```

**Deploy with validate-only:**
```bash
# Step 1: validate
sf project deploy start \
  --manifest package.xml \
  --target-org prod-alias \
  --dry-run

# Step 2: deploy
sf project deploy start \
  --manifest package.xml \
  --target-org prod-alias
```

**Retrieve all custom LWC (for cgcloud order components):**
```bash
sf project retrieve start \
  --metadata "LightningComponentBundle:*" \
  --target-org sandbox-alias
```

---

## CI/CD Considerations

- **Never deploy cgcloud managed package objects** — the schema is controlled by the package; retrieve only your customizations (fields, layouts, flows, Apex, LWC)
- **Sync Management config is org-specific** — `cgc_sync__Sync_Config__c` and sync object configurations should be maintained per environment, not promoted via CI/CD. Use environment-specific setup scripts
- **RetailExecutionSettings deployment is idempotent** — safe to redeploy; it only updates the three boolean flags
- **TPM Business Years are data, not metadata** — do not attempt to deploy Business Year records via package.xml; create them as setup data post-deployment
- **cgcloud__Trigger_Setting__c and cgcloud__Validation_Rules_Setting__c are data** — manage via setup scripts, not metadata deployment. Always restore trigger settings after data migration
