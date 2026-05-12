/**
 * @description       :
 * @author            : Akrom Saidkamolov
 * @last modified on  : 2026-03-12
 * @last modified by  : Akrom Saidkamolov
 **/
import { LightningElement, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import SheetJs from "@salesforce/resourceUrl/sheetjs";

import RecRelatedReconciliationModal from "c/recRelatedReconciliationModal";
import RecFiduciaryMappingModal from "c/recFiduciaryMappingModal";
import AccountMappingModal from "./modal/accountMapping";

import apexInquiryBankTransactions from "@salesforce/apex/REC_BTInquiryCtrl.inquiryBankTransactions";
import apexSaveBankTransactions from "@salesforce/apex/REC_BTInquiryCtrl.saveBankTransactions";
import apexFindAccountDepositor from "@salesforce/apex/REC_BTInquiryCtrl.findAccountDepositor";

export default class RecBankTransactionInquiry extends LightningElement {
    // ── Table data ──────────────────────────────────────────────────────────

    @track tableData = [];

    XLSX;

    // ── Table state ──────────────────────────────────────────────────────

    _isLoading = false;
    _selectedCount = 0;
    _hasDirtyRows = false;
    _lastFilterValues = null;

    get _table() {
        return this.refs?.table ?? this.template.querySelector("c-rec-table");
    }

    get isLoading() {
        return this._isLoading;
    }

    get saveBtnDisabled() {
        return !this._hasDirtyRows;
    }

    get fiduciaryBtnDisabled() {
        return this._selectedCount <= 0;
    }

    get accountMappingBtnDisabled() {
        if (this._selectedCount !== 1) return true;
        const selectedRows = this._table?.getSelectedRows();
        if (!selectedRows || selectedRows.length !== 1) return true;
        return !selectedRows[0].Depositor__c;
    }

    get displayRowCount() {
        return this.tableData?.length || 0;
    }

    get displaySelectedCount() {
        return this._selectedCount;
    }

    // ── Filter / Action handlers ──────────────────────────────────────────────

    handleInquiryClick() {
        const values = this.refs.filter.getValues();
        this._lastFilterValues = values;

        const columnFields = this._extractColumnFields();

        this._isLoading = true;
        this._table?.clearSelection();
        this._selectedCount = 0;

        apexInquiryBankTransactions({
            filters: JSON.stringify(values),
            relFields: columnFields.length ? JSON.stringify(columnFields) : null
        })
            .then((result) => {
                this.tableData = result || [];
            })
            .catch((error) => {
                console.error("Inquiry error:", error);
                this.tableData = [];
            })
            .finally(() => {
                this._isLoading = false;
            });
    }

    handleResetClick() {
        this.refs.filter.reset();
    }

    // ── recTable event handlers ───────────────────────────────────────────────

    handleRowSelection(event) {
        const { selectedRows } = event.detail;
        this._selectedCount = selectedRows.length;
    }

    handleCellChange(event) {
        const { rowId, fieldName, value, oldValue } = event.detail;
    }

    async handleCellButtonClick(event) {
        const { fieldName, rowId } = event.detail;

        if (fieldName === "action_Reconciliation") {
            RecRelatedReconciliationModal.open({
                size: "small",
                recordId: rowId,
                type: "Reconciliation"
            });
        }

        if (fieldName === "action_Statement") {
            if (!this.XLSX) {
                try {
                    await loadScript(this, SheetJs);
                    this.XLSX = window.XLSX;
                } catch (e) {
                    console.error("SheetJS load error:", e);
                }
            }
            RecRelatedReconciliationModal.open({
                size: "small",
                recordId: rowId,
                type: "Statement",
                xlsx: this.XLSX
            });
        }
    }

    handleDirtyStateChange(event) {
        this._hasDirtyRows = event.detail.hasDirty;
    }

    async handleTableSave() {
        const dirtyRows = this._table.getDirtyRows();

        if (!dirtyRows.length) return;

        this._isLoading = true;
        try {
            const rowsJson = JSON.stringify(dirtyRows);
            const result = await apexSaveBankTransactions({ rowsJson });

            if (result.success) {
                // All rows saved — clear dirty state
                this._table.markSaved();
                this._showToast("Success", "All changes saved successfully.", "success");
            } else {
                await this._refreshTableData();

                // Highlight the failed cells
                this._table.setCellErrors(result.cellErrors);

                // Row-level errors (fieldName == null) shown via toast
                const rowLevelErrors = result.cellErrors.filter((e) => !e.fieldName).map((e) => e.message);

                this._showToast(
                    "Partial Save",
                    `${result.successCount} saved, ${result.errorCount} failed.` +
                        (rowLevelErrors.length ? "\n" + rowLevelErrors.join("\n") : ""),
                    "warning"
                );
            }
        } catch (error) {
            console.error("Save error:", error);
            this._showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    async handleFiduciaryLiabilityClick() {
        // Placeholder for future implementation
        const selectedRows = this._table.getSelectedRows();

        const result = await RecFiduciaryMappingModal.open({
            size: "large",
            btRecords: selectedRows
        });

        if (result) {
            this._table?.clearSelection();
            this._refreshTableData();
        }
    }

    async handleAccountMappingClick() {
        const selectedRows = this._table.getSelectedRows();
        if (selectedRows.length !== 1) return;

        const row = selectedRows[0];

        this._isLoading = true;
        try {
            // Query AccountDepositor on server
            const existingRecords = await apexFindAccountDepositor({
                bizRegion: row.BizRegion__c,
                accountNameId: row.AccountName__c,
                depositorName: row.Depositor__c
            });

            const result = await AccountMappingModal.open({
                size: "small",
                btRecord: row,
                existingDepositors: existingRecords || []
            });

            if (result) {
                await this._refreshTableData();
                // Re-evaluate button disabled states with current selection
                const selectedRows = this._table?.getSelectedRows();
                this._selectedCount = selectedRows?.length || 0;
            }
        } catch (error) {
            console.error("Account Mapping error:", error);
            this._showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
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
            const result = await apexInquiryBankTransactions({
                filters: JSON.stringify(this._lastFilterValues),
                relFields: columnFields.length ? JSON.stringify(columnFields) : null
            });
            this.tableData = result || [];
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

    // ── Filter definitions ────────────────────────────────────────────────────

    filterDefs = [
        // ── Row 1 ──────────────────────────────────────────────────────────────
        {
            label: "Bank Account",
            name: "BankAccount__c",
            type: "lookup",
            config: {
                objectApiName: "ACC_AdditionalInfo__c",
                labelField: "Name",
                placeholder: "Search Bank Account..."
            },
            size: 4
        },
        { blank: true, size: 8 },
        // ── Row 2 ──────────────────────────────────────────────────────────────
        {
            label: "Status",
            name: "Status__c",
            type: "combobox",
            size: 4,
            config: {
                multiple: true,
                picklistObject: "BankTransaction__c",
                picklistField: "Status__c"
            }
        },
        {
            label: "Transaction Date",
            name: "TransactionDate__c",
            type: "date-range",
            size: 4
        },
        {
            label: "Settlement Currency",
            name: "Currency__c",
            type: "combobox",
            size: 4,
            config: {
                picklistObject: "BankTransaction__c",
                picklistField: "Currency__c"
            }
        },
        // ── Row 3 ──────────────────────────────────────────────────────────────
        {
            label: "Account Name",
            name: "AccountName__c",
            type: "lookup",
            size: 4,
            config: {
                objectApiName: "Account",
                labelField: "Name",
                placeholder: "Search Account..."
            }
        },
        {
            label: "Origin Amount",
            name: "OriginAmount__c",
            type: "number-range",
            size: 4
        },
        {
            label: "Depositor",
            name: "Depositor__c",
            type: "like",
            size: 4
        }
    ];

    // ── Column definitions ──────────────────────────────────────────────────

    tableColumns = [
        {
            label: "Trans. No.",
            name: "Name",
            type: "url",
            config: {
                idField: "Id",
                objectApiName: "BankTransaction__c"
            }
        },
        {
            label: "Transaction Date",
            name: "TransactionDate__c",
            type: "date"
        },
        {
            label: "Settlement Currency",
            name: "Currency__c"
        },
        {
            label: "Origin Amount",
            name: "OriginAmount__c",
            type: "currency",
            config: { ccyField: "Currency__c" }
        },
        {
            label: "Balance",
            name: "Balance__c",
            type: "currency",
            config: { ccyField: "Currency__c" }
        },
        {
            label: "Depositor",
            name: "Depositor__c"
        },
        {
            label: "Account Name",
            name: "AccountName__r.Name",
            type: "url",
            config: {
                idField: "AccountName__c",
                objectApiName: "Account"
            }
        },
        {
            label: "Reconciled AMT",
            name: "TotalClearedAmount__c",
            type: "currency",
            config: { ccyField: "Currency__c" }
        },
        {
            label: "Not-Reconciled AMT",
            name: "NetBalanceAftCleared__c",
            type: "currency",
            config: { ccyField: "Currency__c" }
        },
        {
            label: "BT Status",
            name: "Status__c"
        },
        {
            label: "Remarks",
            name: "Remarks__c",
            type: "text",
            editable: true
        },
        {
            label: "Reconciliation Line Item",
            name: "action_Reconciliation",
            type: "button",
            config: {
                variant: "border",
                iconName: "utility:add",
                size: "small"
            }
        },
        {
            label: "Statement Upload",
            name: "action_Statement",
            type: "button",
            config: {
                variant: "border",
                iconName: "utility:add",
                size: "small"
            }
        }
    ];
}