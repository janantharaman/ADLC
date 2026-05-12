import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import apexInquiryReconciliationData from "@salesforce/apex/REC_ReconInquiryCtrl.inquiryReconciliationData";
import lblUnexpectedError from "@salesforce/label/c.EVA_MSG_UNEXPECTED_ERROR";

export default class RecSettlementLineItemInquiry extends LightningElement {
    // ── Table Data ───────────────────────────────────────────────────────

    @track tableData = [];

    // ── Table state ──────────────────────────────────────────────────────

    _isLoading = false;
    _lastFilterValues = null;

    get displayRowCount() {
        return this.tableData?.length || 0;
    }

    // ── Filter / Action handlers ──────────────────────────────────────────────

    handleInquiryClick() {
        if (!this.refs.filter.validate()) return;

        const values = this.refs.filter.getValues();
        this._lastFilterValues = values;

        const columnFields = this._extractColumnFields();

        this._isLoading = true;
        apexInquiryReconciliationData({
            filters: JSON.stringify(values),
            relFields: columnFields.length ? JSON.stringify(columnFields) : null
        })
            .then((result) => {
                this.tableData = this._buildTreeData(result || []);
                this._selectedCount = 0;
            })
            .catch((error) => {
                console.error("Inquiry error:", error);
                this._showToast("Error", error.body?.message || lblUnexpectedError, "error");
                this.tableData = [];
            })
            .finally(() => {
                this._isLoading = false;
                //this.refs.table.clearSelection();
            });
    }

    handleResetClick() {
        this.refs.filter.reset();
    }

    handleExportClick() {
        const timestamp = new Date().toISOString().replace(/[:.-]/g, "");
        this.refs.table.exportToExcel({ filename: `Reconciliation_${timestamp}.xlsx` });
    }

    // ── recTable event handlers ───────────────────────────────────────────────
    handleGroupCollapse(event) {
        const { groupName, collapsed } = event.detail;
    }

    handleExpandAllClick() {
        this.refs.table.expandAll();
    }

    handleCollapseAllClick() {
        this.refs.table.collapseAll();
    }

    // ── Private helpers ────────────────────────────────────────────────────────

    /**
     * Re-fetch table data using the last inquiry filter values.
     * Does NOT toggle _isLoading — caller is responsible.
     */
    async _refreshTableData() {
        if (!this._lastFilterValues) return;
        const columnFields = this._extractColumnFields();
        try {
            const result = await getReconciliationData({
                filters: JSON.stringify(this._lastFilterValues),
                relFields: columnFields.length ? JSON.stringify(columnFields) : null
            });
            this.tableData = this._buildTreeData(result || []);
        } catch (error) {
            console.error("Refresh error:", error);
        }
    }

    _showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    /**
     * Extracts all leaf-column field names from tableColumns.
     * Relationship fields (dot-notation) are appended to the SOQL SELECT;
     * direct fields are validated against the selector's getDefaultFields().
     */
    _extractColumnFields() {
        const fields = new Set();
        const walk = (cols) => {
            if (!Array.isArray(cols)) return;
            for (const col of cols) {
                if (col.columns) {
                    walk(col.columns);
                } else if (col.name && col.type !== "button" && !col.name.startsWith("_")) {
                    fields.add(col.name);
                }
            }
        };
        walk(this.tableColumns);
        return [...fields];
    }

    /**
     * Transforms flat ReconciliationLineItem__c array into a tree structure
     * grouped by RefReconciliation__r.
     */
    _buildTreeData(flatData) {
        if (!flatData || flatData.length === 0) return [];

        const map = new Map();

        flatData.forEach((row) => {
            const recId = row.RefReconciliation__c;
            if (!recId) return;

            if (!map.has(recId)) {
                const rec = row.RefReconciliation__r || {};
                map.set(recId, {
                    Id: recId,
                    RefReconciliation__c: recId,
                    RefReconciliation__r: {
                        Name: rec.Name || recId,
                        // Reconciliation-level fields (match column dot-notation)
                        Status__c: rec.Status__c || row.RLIStatus__c,
                        ReconciledDate__c: rec.ReconciledDate__c,
                        ReconciledCurrency__c: rec.ReconciledCurrency__c,
                        ReconciledAMT__c: rec.ReconciledAMT__c,
                        BaseType_fm__c: rec.BaseType_fm__c || row.BaseType_fm__c
                    },
                    _children: [],
                    _sliSet: new Set(),
                    _btSet: new Set(),
                    _foSet: new Set()
                });
            }

            const parent = map.get(recId);

            if (row.RefSettlementLineItem__c) parent._sliSet.add(row.RefSettlementLineItem__c);
            if (row.RefBankTransaction__c) parent._btSet.add(row.RefBankTransaction__c);
            if (row.RefFiduciaryOthers__c) parent._foSet.add(row.RefFiduciaryOthers__c);

            // Clone to avoid side effects
            const child = { ...row };
            child.Id = row.Id;
            child.RefReconciliation__c = row.Id; // Redirect child click to RLI record
            child.RefReconciliation__r = {
                Name: row.Name,
                // Clear Reconciliation-only fields on child rows
                Status__c: row.RLIStatus__c,
                ReconciledDate__c: null,
                ReconciledCurrency__c: null,
                ReconciledAMT__c: null,
                BaseType_fm__c: null
            };

            parent._children.push(child);
        });

        const treeData = [];
        for (const parent of map.values()) {
            // SLI / BT summary labels
            parent.RefSettlementLineItem__r = { Name: parent._sliSet.size > 0 ? `SLI (${parent._sliSet.size})` : "" };
            parent.RefBankTransaction__r = { Name: parent._btSet.size > 0 ? `BT (${parent._btSet.size})` : "" };
            parent.RefFiduciaryOthers__r = { Name: parent._foSet.size > 0 ? `FO (${parent._foSet.size})` : "" };

            delete parent._sliSet;
            delete parent._btSet;
            delete parent._foSet;

            treeData.push(parent);
        }

        return treeData;
    }

    // ── Filter definitions ────────────────────────────────────────────────────

    filterDefs = [
        // ── Row 1 ──────────────────────────────────────────────────────────────
        {
            label: "Reconciled Status",
            name: "RefReconciliation__r.Status__c",
            type: "combobox",
            required: false,
            size: 4,
            config: {
                picklistObject: "Reconciliation__c",
                picklistField: "Status__c"
            }
        },
        {
            label: "Reconciled Currency",
            name: "RefReconciliation__r.ReconciledCurrency__c",
            type: "combobox",
            required: false,
            size: 4,
            config: {
                picklistObject: "Reconciliation__c",
                picklistField: "ReconciledCurrency__c"
            }
        },
        {
            label: "Settlement Line Item",
            name: "RefSettlementLineItem__c",
            type: "lookup",
            size: 4,
            config: {
                objectApiName: "SettlementLineItem__c",
                labelField: "Name",
                subLabelFields: ["ClosingType__c"],
                subLabelDelimiter: " | ",
                placeholder: "Search Settlement Line Item..."
            }
        },
        // ── Row 2 ──────────────────────────────────────────────────────────────
        {
            label: "Reconciled Date",
            name: "RefReconciliation__r.ReconciledDate__c",
            type: "date-range",
            size: 4
        },
        {
            label: "Reconciled Amount",
            name: "RefReconciliation__r.ReconciledAMT__c",
            type: "number-range",
            size: 4,
            config: {
                fromField: "RefReconciliation__r.ReconciledAMT__c",
                toField: "RefReconciliation__r.ReconciledAMT__c"
            }
        },
        {
            label: "Bank Transaction",
            name: "RefBankTransaction__c",
            type: "lookup",
            size: 4,
            config: {
                objectApiName: "BankTransaction__c",
                labelField: "Name",
                subLabelFields: ["TransactionDate__c"],
                subLabelDelimiter: " | ",
                placeholder: "Search Bank Transaction..."
            }
        }
    ];

    // ── Column definitions (single source of truth) ───────────────────────────
    tableColumns = [
        {
            label: "Reconciliation",
            name: "Reconciliation",
            collapsed: true,
            columns: [
                {
                    label: "Name",
                    name: "RefReconciliation__r.Name",
                    type: "url",
                    config: {
                        idField: "RefReconciliation__c",
                        objectApiName: "Reconciliation__c"
                    }
                },
                { label: "Reconcilied Status", name: "RefReconciliation__r.Status__c" },
                { label: "Reconcilied Date", name: "RefReconciliation__r.ReconciledDate__c", type: "date" },
                { label: "Reconcilied Currency", name: "RefReconciliation__r.ReconciledCurrency__c" },
                {
                    label: "Reconcilied AMT",
                    name: "RefReconciliation__r.ReconciledAMT__c",
                    type: "currency",
                    config: { ccyField: "RefReconciliation__r.ReconciledCurrency__c" }
                },
                { label: "Base Type", name: "RefReconciliation__r.BaseType_fm__c" }
            ]
        },
        {
            label: "Settlement Line Item",
            name: "SettlementLineItem",
            collapsed: true,
            columns: [
                {
                    label: "Name",
                    type: "url",
                    name: "RefSettlementLineItem__r.Name",
                    config: {
                        idField: "RefSettlementLineItem__c",
                        objectApiName: "SettlementLineItem__c"
                    }
                },
                {
                    label: "Closing Type",
                    name: "RefSettlementLineItem__r.ClosingType__c"
                },
                {
                    label: "COA",
                    name: "RefSettlementLineItem__r.COA_lk__r.Name",
                    type: "url",
                    collapsible: true,
                    config: {
                        objectApiName: "COA__c",
                        idField: "RefSettlementLineItem__r.COA_lk__c"
                    }
                },
                {
                    label: "Account Name",
                    name: "RefSettlementLineItem__r.AccountName__r.Name",
                    type: "url",
                    config: {
                        objectApiName: "Account",
                        idField: "RefSettlementLineItem__c"
                    }
                },
                { label: "Currency", name: "RefSettlementLineItem__r.OriginCurrency__c" },
                {
                    label: "Origin Amount",
                    name: "RefSettlementLineItem__r.OriginAmount__c",
                    type: "currency",
                    config: { ccyField: "RefSettlementLineItem__r.OriginCurrency__c" },
                    collapsible: true
                },
                {
                    label: "Settlement Date",
                    name: "RefSettlementLineItem__r.SettlementDate__c",
                    type: "date",
                    collapsible: true
                },
                {
                    label: "Settlement Currency",
                    name: "RefSettlementLineItem__r.SettlementCurrency__c",
                    collapsible: true
                },
                {
                    label: "FX Rate (to Settlement)",
                    name: "RefSettlementLineItem__r.FXRateOrigintoSettlement__c",
                    type: "currency",
                    config: { ccyField: "RefSettlementLineItem__r.SettlementCurrency__c" },
                    collapsible: true
                },
                {
                    label: "Settlement Amount (SLI)",
                    name: "RefSettlementLineItem__r.SettlementAmountSLI__c",
                    type: "currency",
                    config: { ccyField: "RefSettlementLineItem__r.SettlementCurrency__c" },
                    collapsible: true
                },
                {
                    label: "Other Charges",
                    name: "RefSettlementLineItem__r.OtherCharges__c",
                    type: "currency",
                    config: { ccyField: "RefSettlementLineItem__r.SettlementCurrency__c" },
                    collapsible: true
                },
                {
                    label: "Settlement Amount (TTL)",
                    name: "RefSettlementLineItem__r.SettlementAmountTTL__c",
                    type: "currency",
                    config: { ccyField: "RefSettlementLineItem__r.SettlementCurrency__c" }
                },
                { label: "Settlement Type", name: "RefSettlementLineItem__r.SettlementType__c", collapsible: true },
                {
                    label: "Settlement Status",
                    name: "RefSettlementLineItem__r.SettlementStatus__c",
                    type: "badge",
                    config: { variantMap: { "Not-Available": "slds-theme_error", Available: "slds-theme_success" } },
                    collapsible: true
                },
                {
                    label: "Remittance On Hold",
                    name: "RefSettlementLineItem__r.RemittanceOnHold__c",
                    collapsible: true,
                    type: "boolean"
                },
                { label: "Hold Reason", name: "RefSettlementLineItem__r.HoldReason__c", collapsible: true },
                { label: "Exchange Date", name: "RefSettlementLineItem__r.ExchangeDate__c", collapsible: true },
                { label: "Exchange Currency", name: "RefSettlementLineItem__r.ExchangeCurrency__c", collapsible: true },
                {
                    label: "Exchange Amount",
                    name: "RefSettlementLineItem__r.ExchangeAmount__c",
                    type: "currency",
                    config: { ccyField: "RefSettlementLineItem__r.ExchangeCurrency__c" },
                    collapsible: true
                },
                {
                    label: "Exchange Rate",
                    name: "RefSettlementLineItem__r.ExchangeRate__c",
                    type: "number",
                    collapsible: true
                }
            ]
        },
        {
            label: "Bank Transaction",
            name: "BankTransaction",
            collapsed: true,
            columns: [
                {
                    label: "Name",
                    type: "url",
                    name: "RefBankTransaction__r.Name",
                    config: {
                        idField: "RefBankTransaction__c",
                        objectApiName: "BankTransaction__c"
                    }
                },
                {
                    label: "Transaction Date",
                    name: "RefBankTransaction__r.TransactionDate__c",
                    type: "date",
                    collapsible: true
                },
                {
                    label: "BT Status",
                    name: "RefBankTransaction__r.Status__c",
                    type: "badge",
                    config: {
                        variantMap: { Clear: "slds-theme_success", Partial: "slds-theme_warning", None: "slds-theme_error" }
                    }
                },
                { label: "Settlement Currency", name: "RefBankTransaction__r.Currency__c" },
                {
                    label: "Origin Amount",
                    name: "RefBankTransaction__r.OriginAmount__c",
                    type: "currency",
                    config: { ccyField: "RefBankTransaction__r.Currency__c" },
                    collapsible: true
                },
                {
                    label: "Balance",
                    name: "RefBankTransaction__r.Balance__c",
                    type: "currency",
                    config: { ccyField: "RefBankTransaction__r.Currency__c" },
                    collapsible: true
                },
                { label: "Depositor", name: "RefBankTransaction__r.Depositor__c", collapsible: true },
                {
                    label: "Account Name",
                    name: "RefBankTransaction__r.AccountName__r.Name",
                    type: "url",
                    config: {
                        objectApiName: "Account",
                        idField: "RefBankTransaction__c"
                    }
                },
                {
                    label: "Reconciled AMT",
                    name: "RefBankTransaction__r.TotalClearedAmount__c",
                    type: "currency",
                    config: { ccyField: "RefBankTransaction__r.Currency__c" }
                },
                {
                    label: "Not-Reconciled AMT",
                    name: "RefBankTransaction__r.NetBalanceAftCleared__c",
                    type: "currency",
                    config: { ccyField: "RefBankTransaction__r.Currency__c" }
                },
                { label: "Remarks", name: "RefBankTransaction__r.Remarks__c", collapsible: true }
            ]
        },
        {
            label: "Fiduciary Others",
            name: "FiduciaryOthers",
            collapsed: true,
            columns: [
                {
                    label: "Name",
                    name: "RefFiduciaryOthers__r.Name",
                    type: "url",
                    config: {
                        idField: "RefFiduciaryOthers__c",
                        objectApiName: "FiduciaryOthers__c"
                    }
                }
            ]
        }
    ];
}