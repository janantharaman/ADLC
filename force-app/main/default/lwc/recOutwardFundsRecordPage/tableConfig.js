// ── SLI Filter Definitions ───────────────────────────────────────────────

export const sliFilterDefs = [
    // ── Row 1 ──────────────────────────────────────────────────────────
    {
        label: "Settlement Status",
        name: "SettlementStatus__c",
        type: "combobox",
        required: true,
        size: 3,
        config: {
            options: [
                {
                    label: "Available",
                    value: "Available"
                },
                {
                    label: "Not-Available",
                    value: "Not-Available"
                }
            ]
        }
    },
    {
        label: "Account Name",
        name: "AccountName__c",
        type: "lookup",
        size: 3,
        config: {
            objectApiName: "Account",
            labelField: "Name",
            placeholder: "Search Account..."
        }
    },
    { blank: true, size: 6 },
    // ── Row 2 ──────────────────────────────────────────────────────────
    { label: "Debit/Credit No.", name: "PremiumNoteNo_fm__c", type: "text", size: 3 },
    {
        label: "Facility Name",
        name: "FacilityBDX_lk__c",
        type: "lookup",
        size: 3,
        config: {
            objectApiName: "COM_FacilityBDX__c",
            labelField: "Name",
            placeholder: "Search Facility BDX..."
        }
    },
    {
        label: "Facility BDX Period",
        name: "FacilityBDXPeriod",
        type: "date-between",
        size: 3,
        config: {
            fromField: "FacilityBDXPeriodFrom__c",
            toField: "FacilityBDXPeriodTo__c"
        }
    },
    {
        label: "Closing Type",
        name: "ClosingType__c",
        type: "combobox",
        size: 3,
        config: {
            multiple: true,
            picklistObject: "SettlementLineItem__c",
            picklistField: "ClosingType__c"
        }
    },
    // ── Row 3 ──────────────────────────────────────────────────────────
    { label: "LK Ref. No.", name: "LKRefNoReins_fm__c", type: "text", size: 3 },
    {
        label: "Placement No.",
        name: "RefReinsurance__c",
        type: "lookup",
        size: 3,
        config: {
            objectApiName: "Placement__c",
            labelField: "Name",
            placeholder: "Search Placement..."
        }
    },
    {
        label: "Insured",
        name: "Insured_fm__c",
        type: "like",
        size: 3
    },
    { label: "Inception Date", name: "InceptionDate__c", type: "date", size: 3 },
    // ── Row 4 ──────────────────────────────────────────────────────────
    { label: "No of Installment", name: "InstallmentNo__c", type: "number", size: 3 },
    { label: "PPW Date", name: "PPWDate__c", type: "date", size: 3 },
    { label: "Date of Loss", name: "RefClaim__r.LossDate__c", type: "date", size: 3 },
    { label: "SOC Seq.", name: "RefClaim__r.ClaimOrder__c", type: "text", size: 3 }
];

// ── Note Filter Definitions ──────────────────────────────────────────────

export const noteFilterDefs = [
    // ── Row 1 ──────────────────────────────────────────────────────────
    {
        label: "Note Status",
        name: "NoteStatus__c",
        type: "combobox",
        required: true,
        size: 3,
        config: {
            options: [
                {
                    label: "Available",
                    value: "Available"
                },
                {
                    label: "Non-Available",
                    value: "Non-Available"
                }
            ]
        }
    },
    {
        label: "Account Name",
        name: "Account_lk__c",
        type: "lookup",
        size: 3,
        config: {
            objectApiName: "Account",
            labelField: "Name",
            placeholder: "Search Account..."
        }
    },
    {
        label: "Note No.",
        name: "Note_lk__c",
        type: "lookup",
        size: 3,
        config: {
            objectApiName: "COM_Note__c",
            labelField: "Name",
            placeholder: "Search Note..."
        }
    },
    { blank: true, size: 3 },
    // ── Row 3 ──────────────────────────────────────────────────────────
    { label: "LK Ref No.", name: "LKRefNReins__c", type: "text", size: 3 },
    {
        label: "Placement No.",
        name: "Placement_lk__c",
        type: "lookup",
        size: 3,
        config: {
            objectApiName: "Placement__c",
            labelField: "Name",
            placeholder: "Search Placement..."
        }
    },
    {
        label: "Insured",
        name: "Insured_fm__c",
        type: "like",
        size: 3
    },
    { label: "Inception Date", name: "PeriodFrom_fm__c", type: "date", size: 3 },
    // ── Row 4 ──────────────────────────────────────────────────────────
    { label: "No of Installment", name: "InstallmentNo__c", type: "number", size: 3 },
    { label: "PPW Date", name: "PPWDate__c", type: "date", size: 3 }
];

// ── Column Definitions ───────────────────────────────────────────────────

export const outwardFundsColumns = [
    {
        label: "Funds No.",
        name: "Name",
        type: "url",
        config: { idField: "Id", objectApiName: "OutwardFund__c" }
    },
    { label: "Report Date", name: "ReportDate__c", type: "date" },
    { label: "Approved Date", name: "ApprovedDate__c", type: "date" },
    { label: "Total Records", name: "TotalRecords__c", type: "number", align: "center" },
    { label: "Approval Status", name: "ApprovalStatus__c", type: "text" }
];

export const sliColumns = [
    {
        label: "SLI No.",
        name: "Name",
        type: "url",
        align: "left",
        config: { idField: "Id", objectApiName: "SettlementLineItem__c" }
    },
    {
        label: "SLI Details",
        name: "SLIDetails",
        collapsed: false,
        columns: [
            { label: "Closing Type", name: "ClosingType__c", type: "text", collapsible: true },
            {
                label: "COA",
                name: "COA_lk__r.Name",
                collapsible: true,
                type: "url",
                align: "left",
                config: { objectApiName: "COA__c", idField: "COA_lk__c" }
            },
            { label: "COA Name", name: "COAName_fm__c", type: "text", collapsible: true },
            {
                label: "Account Name",
                name: "AccountName__r.Name",
                type: "url",
                align: "left",
                config: { objectApiName: "Account", idField: "AccountName__c" }
            },
            { label: "Origin Currency", name: "OriginCurrency__c", type: "text" },
            {
                label: "Origin Amount",
                name: "OriginAmount__c",
                type: "currency",
                config: { ccyField: "OriginCurrency__c" }
            }
        ]
    },
    {
        label: "Settlement Details",
        name: "SettlementDetails",
        columns: [{ label: "Settlement Status", name: "SettlementStatus__c", type: "text" }]
    },
    {
        label: "PPW Date",
        name: "PPWDate",
        columns: [
            { label: "PPW Type", name: "PPWType_fm__c", type: "text" },
            { label: "No of Installment", name: "InstallmentNo__c", type: "text", collapsible: true },
            { label: "PPW Date", name: "PPWDate__c", type: "date" }
        ]
    },
    {
        label: "Placement",
        name: "Placement",
        columns: [
            { label: "LK Ref. No.", name: "LKRefNoPolicy_fm__c", type: "element" },
            { label: "Cedant Ref. No.", name: "CedantRefNo__c", type: "text", collapsible: true },
            {
                label: "Cedant Facility Name",
                name: "CedantFacilityName__r.Name",
                collapsible: true,
                type: "url",
                align: "left",
                config: { objectApiName: "COM_Facility__c", idField: "CedantFacilityName__c" }
            },
            {
                label: "Insured",
                name: "Insured_fm__c",
                align: "left"
            },
            { label: "Inception Date", name: "InceptionDate__c", type: "date" },
            { label: "Expiration Date", name: "ExpirationDate__c", type: "date" },
            { label: "LOB", name: "LOB3__c", type: "text", collapsible: true }
        ]
    },
    {
        label: "Market Line",
        name: "MarketLine",
        columns: [
            {
                label: "Layer",
                name: "Layer__r.Name",
                type: "url",
                align: "left",
                config: { objectApiName: "OPP_Layer__c", idField: "Layer__c" }
            },
            {
                label: "Reinsurer",
                name: "Reinsurer__r.Name",
                type: "url",
                align: "left",
                config: { objectApiName: "Account", idField: "Reinsurer__c" }
            },
            {
                label: "Market Facility Name",
                name: "MarketFacilityName__r.Name",
                collapsible: true,
                type: "url",
                align: "left",
                config: { objectApiName: "COM_Facility__c", idField: "MarketFacilityName__c" }
            },
            { label: "Co-brk Type", name: "CoBrokingType__c", type: "text", collapsible: true }
        ]
    },
    {
        label: "Claim",
        name: "Claim",
        columns: [
            {
                label: "Parent Claim No.",
                name: "ParentClaimNo__r.Name",
                collapsible: true,
                type: "url",
                align: "left",
                config: { objectApiName: "Claim", idField: "ParentClaimNo__c" }
            },
            {
                label: "Cedant Claim No.",
                name: "CedantClaimNo__c",
                collapsible: true
            },
            { label: "Date of Loss", name: "DateOfLoss__c", type: "text" },
            { label: "Location of Loss", name: "LocationOfLoss__c", type: "text" },
            { label: "SOC Seq.", name: "Claim__r.ClaimOrder__c", type: "text" },
            { label: "Child Claim No.", name: "Claim__r.Name", type: "text", collapsible: true }
        ]
    },
    {
        label: "Facility BDX",
        name: "FacilityBDX",
        columns: [
            {
                label: "Facility Name",
                name: "FacilityName__r.Name",
                type: "url",
                align: "left",
                config: { objectApiName: "COM_Facility__c", idField: "FacilityName__c" }
            },
            { label: "Facility_UY", name: "Facility_UY__c", type: "text" },
            { label: "Facility BDX Period From", name: "FacilityBDXPeriodFrom__c", type: "date" },
            { label: "Facility BDX Period To", name: "FacilityBDXPeriodTo__c", type: "date" }
        ]
    }
];

// ── Selected SLI Column Definitions ─────────────────────────────────────

export const selectedSliColumns = [
    {
        label: "SLI No.",
        name: "Name",
        type: "url",
        align: "left",
        config: { idField: "Id", objectApiName: "SettlementLineItem__c" }
    },
    {
        label: "SLI Details",
        name: "SLIDetails",
        collapsed: false,
        columns: [
            { label: "Closing Type", name: "ClosingType__c", type: "text" },
            {
                label: "COA",
                name: "COA_lk__r.Name",
                type: "url",
                align: "left",
                config: { objectApiName: "COA__c", idField: "COA_lk__c" }
            },
            { label: "COA Name", name: "COAName_fm__c", type: "text" },
            {
                label: "Account Name",
                name: "AccountName__r.Name",
                type: "url",
                align: "left",
                config: { objectApiName: "Account", idField: "AccountName__c" }
            },
            { label: "Origin Currency", name: "OriginCurrency__c", type: "text" },
            {
                label: "Origin Amount",
                name: "OriginAmount__c",
                type: "currency",
                config: { ccyField: "OriginCurrency__c" }
            }
        ]
    },
    {
        label: "Settlement Details",
        name: "SettlementDetails",
        columns: [
            { label: "Settlement Date", name: "SettlementDate__c", type: "date" },
            {
                label: "Settlement Currency",
                name: "SettlementCurrency__c",
                type: "combobox",
                editable: true,
                config: {
                    picklistObject: "SettlementLineItem__c",
                    picklistField: "SettlementCurrency__c"
                }
            },
            { label: "FX Rate (to Settlement)", name: "FXRateOrigintoSettlement__c", type: "number", editable: true },
            {
                label: "Settlement Amount (SLI)",
                name: "SettlementAmountSLI__c",
                type: "currency",
                config: { ccyField: "SettlementCurrency__c" }
            },
            {
                label: "Other Charges",
                name: "OtherCharges__c",
                type: "currency",
                config: { ccyField: "SettlementCurrency__c" }
            },
            {
                label: "Settlement Amount (TTL)",
                name: "SettlementAmountTTL__c",
                type: "currency",
                config: { ccyField: "SettlementCurrency__c" }
            },
            {
                label: "Settlement Type",
                name: "SettlementType__c",
                type: "combobox",
                editable: true,
                config: {
                    picklistObject: "SettlementLineItem__c",
                    picklistField: "SettlementType__c"
                }
            },
            { label: "Settlement Status", name: "SettlementStatus__c", type: "text" },
            { label: "Settlement Date (Counterparty)", name: "SettlementDateCounterparty__c", type: "date" },
            {
                label: "Additional Account Info",
                name: "AdditionalAccountInfo__c",
                type: "record-picker",
                editable: true,
                config: {
                    objectApiName: "ACC_AdditionalInfo__c",
                    labelField: "Name",
                    placeholder: "Search Account Info...",
                    filters: [
                        {
                            field: "Account_lk__c",
                            op: "=",
                            filterFromRowField: "AccountName__c"
                        }
                    ]
                }
            },
            { label: "Remittance On Hold", name: "RemittanceOnHold__c", type: "boolean", editable: true },
            { label: "Hold Reason", name: "HoldReason__c", type: "text", editable: true }
        ]
    },
    {
        label: "Exchange Details",
        name: "ExchangeDetails",
        columns: [
            { label: "Exchange Date", name: "ExchangeDate__c", type: "date", editable: true },
            {
                label: "Exchange Currency",
                name: "ExchangeCurrency__c",
                type: "combobox",
                editable: true,
                config: {
                    picklistObject: "SettlementLineItem__c",
                    picklistField: "ExchangeCurrency__c"
                }
            },
            {
                label: "Exchange Amount",
                name: "ExchangeAmount__c",
                type: "currency",
                editable: true,
                config: { ccyField: "ExchangeCurrency__c" }
            },
            { label: "Exchange Rate", name: "ExchangeRate__c", type: "number", editable: true }
        ]
    }
];

// ── Note Column Definitions ──────────────────────────────────────────────

export const noteColumns = [
    {
        label: "Note No.",
        name: "Name",
        type: "url",
        align: "left",
        config: { idField: "Id", objectApiName: "COM_Note__c" }
    },
    { label: "Note Type", name: "NoteType__c", type: "text" },
    {
        label: "Note Details",
        name: "NoteDetails",
        collapsed: false,
        columns: [
            {
                label: "Account Name",
                name: "Account_lk__r.Name",
                type: "url",
                align: "left",
                config: { objectApiName: "Account", idField: "Account_lk__c" }
            },
            { label: "Origin Currency", name: "OriginCurrency__c", type: "text" },
            {
                label: "Origin Amount",
                name: "NoteAmount__c",
                type: "currency",
                config: { ccyField: "OriginCurrency__c" }
            },
            { label: "Issue Date", name: "IssueDate__c", type: "date" },
            {
                label: "Contact",
                name: "NoteContact_lk__r.Name",
                type: "url",
                align: "left",
                config: { objectApiName: "Contact", idField: "NoteContact_lk__c" }
            },
            { label: "Particular", name: "NoteParticular__c", type: "text" },
            { label: "Email", name: "Email__c", type: "email" },
            {
                label: "Origin Amount (Settled)",
                name: "NoteAmtSettled__c",
                type: "currency",
                config: { ccyField: "OriginCurrency__c" }
            },
            {
                label: "Origin Amount (Balance)",
                name: "NoteAmtBalance__c",
                type: "currency",
                config: { ccyField: "OriginCurrency__c" }
            },
            { label: "Note Status", name: "NoteStatus__c", type: "text" }
        ]
    },
    {
        label: "PPW Date",
        name: "PPWDate",
        columns: [
            { label: "PPW Type", name: "PPWType_fm__c", type: "text" },
            { label: "No of Installment", name: "InstallmentNo__c", type: "text" },
            { label: "Install(%)", name: "InstallPct__c", type: "number", collapsible: true },
            { label: "PPW Date", name: "PPWDate__c", type: "date" }
        ]
    },
    {
        label: "Placement",
        name: "Placement",
        columns: [
            { label: "LK Ref. No.", name: "LKRefNReins__c", type: "text" },
            {
                label: "Cedant Facility Name",
                name: "CedantFacility_lk__r.Name",
                collapsible: true,
                type: "url",
                align: "left",
                config: { objectApiName: "COM_Facility__c", idField: "CedantFacility_lk__c" }
            },
            {
                label: "Insured",
                name: "Insured_fm__c",
                type: "text",
                align: "left"
            },
            { label: "Inception Date", name: "PeriodFrom_fm__c", type: "date" },
            { label: "Expiration Date", name: "PeriodTo_fm__c", type: "date" },
            { label: "LOB", name: "LOB3_fm__c", type: "text", collapsible: true },
            { label: "Type", name: "Type_fm__c", type: "text", collapsible: true }
        ]
    },
    {
        label: "Claim",
        name: "Claim",
        columns: [
            { label: "Parent Claim No.", name: "ParentClaimNo_fm__c", type: "text", collapsible: true },
            { label: "Cedant Claim No.", name: "CedantClaimNo_fm__c", type: "text", collapsible: true },
            { label: "Date of Loss", name: "DateOfLoss_fm__c", type: "text" },
            { label: "Location of Loss", name: "LocationOfLoss_fm__c", type: "text" },
            { label: "SOC Seq.", name: "ChildClaim_lk__r.ClaimOrder__c", type: "text" },
            { label: "Child Claim No.", name: "ChildClaim_lk__r.Name", type: "text", collapsible: true }
        ]
    }
];