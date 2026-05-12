/* eslint-disable @lwc/lwc/ssr-no-unsupported-properties */
/**
 * @description       :
 * @author            : shkang@trestle.co.kr
 * @last modified on  : 2026-04-16
 * @last modified by  : Akrom Saidkamolov
 **/
import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

import RecRelatedReconciliationModal from "c/recRelatedReconciliationModal";
import RecSplitSliModal from "c/recSplitSliModal";
import RecOutwardFundsModal from "c/recOutwardFundsModal";
import RecSettlementLineItemConfirmModal from "c/recSettlementLineItemConfirmModal";
import RecPPWDateModal from "c/recSliPpwDateModal";

import apexInquirySettlementLineItems from "@salesforce/apex/REC_SLIInquiryCtrl.inquirySettlementLineItems";
import apexCreateOutwardFundWithLineItems from "@salesforce/apex/REC_OutwardFundCtrl.createOutwardFundWithLineItems";
import apexSaveOutwardFundLineItems from "@salesforce/apex/REC_OutwardFundCtrl.saveOutwardFundLineItems";
import apexCheckSliConflicts from "@salesforce/apex/REC_OutwardFundCtrl.checkSliConflicts";
import apexConfirmSliStatus from "@salesforce/apex/REC_SLIInquiryCtrl.confirmSliStatus";
import apexIsOperationUser from "@salesforce/apex/REC_Utils.isOperationUser";

import PC_SPLIT_NOT_ALLOWED from "@salesforce/label/c.REC_MSG_SPLIT_PC_SLI_NOT_ALLOWED";

export default class RecSettlementLineItemInquiry extends NavigationMixin(LightningElement) {
    high = 10;
    low = 7;

    // ── Table Data ───────────────────────────────────────────────────────

    @track tableData = [];

    // ── Table state ──────────────────────────────────────────────────────

    _isLoading = false;
    _selectedCount = 0;
    _selectedRows = [];
    _hasDirtyRows = false;
    _lastFilterValues = null;
    isOperationUser = false;

    get splitBtnDisabled() {
        return this._selectedCount !== 1 || this._selectedRows[0]?.SettlementStatus__c !== "Not-Available";
    }

    get ppwDateBtnDisabled() {
        return this._selectedCount === 0 || !this.isOperationUser;
    }

    get displayRowCount() {
        return this.tableData?.length || 0;
    }

    get displaySelectedCount() {
        return this._selectedCount;
    }

    async connectedCallback() {
        try {
            this.isOperationUser = await apexIsOperationUser();
        } catch (error) {
            console.error("Initialization error:", error);
        }
    }

    // ── Filter / Action handlers ──────────────────────────────────────────────────

    handleInquiryClick() {
        if (!this.refs.filter.validate()) return;

        const values = this.refs.filter.getValues();
        this._lastFilterValues = values;

        const columnFields = this._extractColumnFields();

        this._isLoading = true;
        apexInquirySettlementLineItems({
            filters: JSON.stringify(values),
            relFields: columnFields.length ? JSON.stringify(columnFields) : null
        })
            .then((result) => {
                this.tableData = result || [];
                this._selectedCount = 0;
            })
            .catch((error) => {
                console.error("Inquiry error:", error);
                this._showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
                this.tableData = [];
            })
            .finally(() => {
                this._isLoading = false;
                this.refs.table.clearSelection();
            });
    }

    handleResetClick() {
        this.refs.filter.reset();
    }

    async handleConfirmClick() {
        const selectedRows = this.refs.table.getSelectedRows() || [];

        if (selectedRows.length === 0) {
            this._showToast("No rows selected", "Please select at least one row to confirm.", "warning");
            return;
        }

        try {
            this._isLoading = true;
            const sliIds = selectedRows.map((r) => r.Id);
            const result = await apexConfirmSliStatus({ sliIds });

            await RecSettlementLineItemConfirmModal.open({
                size: "small",
                total: result.total,
                confirmCount: result.confirmCount,
                errorCount: result.errorCount
            });

            if (result.confirmCount > 0) {
                await this._refreshTableData();
            }
        } catch (error) {
            console.error("Confirm error:", error);
            this._showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    async handleSplitClick() {
        const selectedRows = this.refs.table.getSelectedRows() || [];

        if (selectedRows.length === 0) {
            this._showToast("No rows selected", "Please select at least one row to split.", "warning");
            return;
        }

        if (selectedRows.length > 1) {
            this._showToast("Multiple rows selected", "Please select only one row to split at a time.", "warning");
            return;
        }

        if (selectedRows[0].ClosingType__c === "P_C") {
            this._showToast(PC_SPLIT_NOT_ALLOWED, "", "warning");
            return;
        }

        const result = await RecSplitSliModal.open({
            size: "small",
            label: "Split Settlement Line Item",
            settlementLineItem: selectedRows[0]
        });

        if (result === "OK") {
            this.refs.table.clearSelection();
            await this._refreshTableData();
        }
    }

    async handlePPWDateClick() {
        const selectedRows = this.refs.table.getSelectedRows() || [];

        if (selectedRows.length === 0) {
            this._showToast("No rows selected", "Please select at least one row to update PPW Date.", "warning");
            return;
        }

        const sliIds = selectedRows.map((r) => r.Id);
        const result = await RecPPWDateModal.open({ sliIds, size: "small" });

        if (!result) return;

        this._showToast("Success", "PPW Date updated successfully.", "success");
        await this._refreshTableData();
    }

    async handleOutwardFundsClick() {
        const selectedRows = this.refs.table.getSelectedRows() || [];

        try {
            let updatedRows = [];

            if (selectedRows.length > 0) {
                this._isLoading = true;
                const sliIds = selectedRows.map((r) => r.Id);
                const conflicts = await apexCheckSliConflicts({ outwardFundId: null, sliIds });
                this._isLoading = false;

                if (conflicts?.length) {
                    const placeholders = conflicts.map((_, i) => `{${i}}`).join(", ");
                    const messageData = conflicts.map((c) => ({ url: `/${c.Id}`, label: c.Name }));
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: "Conflict Detected",
                            message: `The following SLIs are already linked to another Outward Fund: ${placeholders}`,
                            messageData,
                            variant: "warning"
                        })
                    );
                    return;
                }

                updatedRows = await RecOutwardFundsModal.open({
                    settlementLineItems: selectedRows,
                    size: "small"
                });

                if (!updatedRows) return;
            }

            this._isLoading = true;
            const sliIds = updatedRows.map((r) => r.Id);
            const newFundId = await apexCreateOutwardFundWithLineItems({ sliIds });

            const outwardFundLineItems = updatedRows.map((r) => ({
                OutwardFund__c: newFundId,
                ClosingInfo__c: r.Id,
                AdditionalAccountInfo__c: r.AdditionalAccountInfo__c ?? null
            }));

            await apexSaveOutwardFundLineItems({ outwardFundLineItems, sliRecords: updatedRows });

            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    recordId: newFundId,
                    objectApiName: "OutwardFund__c",
                    actionName: "view"
                }
            });
        } catch (error) {
            console.error("Outward Funds error:", error);
            this._showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    // ── recTable event handlers ───────────────────────────────────────────────

    handleRowSelection(event) {
        const { selectedRows } = event.detail;
        this._selectedRows = selectedRows;
        this._selectedCount = selectedRows.length;
    }

    handleCellChange(event) {
        const { rowId, fieldName, value, oldValue } = event.detail;
    }

    handleCellButtonClick(event) {
        const { rowId } = event.detail;

        RecRelatedReconciliationModal.open({
            size: "small",
            recordId: rowId
        });
    }

    handleGroupCollapse(event) {
        const { groupName, collapsed } = event.detail;
    }

    handleExpandAllClick() {
        this.refs.table.expandAll();
    }

    handleCollapseAllClick() {
        this.refs.table.collapseAll();
    }

    handleExportClick() {
        const timestamp = new Date().toISOString().replace(/[:.-]/g, "");
        this.refs.table.exportToExcel({ filename: `SettlementLineItems_${timestamp}.xlsx` });
    }

    handleDirtyStateChange(event) {
        this._hasDirtyRows = event.detail.hasDirty;
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
            const result = await apexInquirySettlementLineItems({
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
            label: "Settlement Status",
            name: "SettlementStatus__c",
            type: "combobox",
            required: true,
            size: 3,
            config: {
                multiple: true,
                picklistObject: "SettlementLineItem__c",
                picklistField: "SettlementStatus__c"
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
        // ── Row 2 ──────────────────────────────────────────────────────────────
        {
            label: "Facility Name",
            name: "FacilityName__c",
            type: "lookup",
            size: 3,
            config: {
                objectApiName: "COM_Facility__c",
                labelField: "Name",
                placeholder: "Search Facility..."
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
        { label: "LK Ref No.", name: "RefInsurancePolicy__r.LKRefNoh__c", type: "like", size: 3 },
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
        // ── Row 3 ──────────────────────────────────────────────────────────────
        {
            label: "Insured",
            name: "Insured_fm__c",
            align: "left",
            type: "like",
            size: 3
        },
        { label: "Inception Date", name: "InceptionDate__c", type: "date", size: 3 },
        { label: "No of Installment", name: "InstallmentNo__c", type: "number", size: 3 },
        { label: "PPW Date", name: "PPWDate__c", type: "date", size: 3 },
        // ── Row 4 ──────────────────────────────────────────────────────────────
        { label: "Date of Loss", name: "RefClaim__r.LossDate__c", type: "date", size: 3 },
        { label: "SOC Seq.", name: "RefClaim__r.ClaimOrder__c", type: "text", size: 3 },
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
        {
            label: "Outward Funds",
            name: "OutwardFunds_lk__c",
            type: "record-picker",
            size: 3,
            config: {
                objectApiName: "OutwardFund__c",
                labelField: "Name",
                placeholder: "Select Outward Funds..."
            }
        },
        // ── Row 5 ──────────────────────────────────────────────────────────────
        {
            label: "STC Status",
            name: "Status__c",
            type: "combobox",
            size: 3,
            config: {
                multiple: true,
                picklistObject: "SettlementLineItem__c",
                picklistField: "Status__c"
            }
        },
        {
            label: "Closing Origin",
            name: "ClosingOrign__c",
            type: "combobox",
            size: 3,
            config: {
                multiple: true,
                picklistObject: "SettlementLineItem__c",
                picklistField: "ClosingOrign__c"
            }
        },
        {
            label: "Policy No.",
            name: "RefInsurancePolicy__c",
            type: "record-picker",
            size: 3,
            config: {
                objectApiName: "InsurancePolicy",
                labelField: "Name",
                placeholder: "Select Policy..."
            }
        },
        {
            label: "Claim No.",
            name: "RefClaim__c",
            type: "record-picker",
            size: 3,
            config: {
                objectApiName: "Claim",
                labelField: "Name",
                placeholder: "Select Claim..."
            }
        },
        // ── Row 6 ──────────────────────────────────────────────────────────────
        {
            label: "SOA No.",
            name: "Note_lk__r.SOA_lk__c",
            type: "record-picker",
            size: 3,
            config: {
                objectApiName: "SOA_Statement__c",
                labelField: "Name",
                placeholder: "Select SOA..."
            }
        }
    ];

    // ── Column definitions (single source of truth) ───────────────────────────

    tableColumns = [
        {
            label: "Reconciliation Line Item",
            name: "Actions",
            type: "button",
            config: {
                variant: "border",
                iconName: "utility:add",
                size: "small"
            }
        },
        {
            label: "SLI No.",
            name: "Name",
            type: "url",
            config: { idField: "Id", objectApiName: "SettlementLineItem__c" }
        },

        {
            label: "SLI Details",
            name: "SLIDetails",
            collapsed: false,
            columns: [
                {
                    label: "Closing Type",
                    name: "ClosingType__c"
                },
                { label: "COA Name", name: "COAName_fm__c", align: "left", collapsible: true },
                {
                    label: "Account Name",
                    name: "AccountName__r.Name",
                    align: "left",
                    type: "url",
                    config: {
                        objectApiName: "Account",
                        idField: "AccountName__c"
                    }
                },
                { label: "Origin Currency", name: "OriginCurrency__c" },
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
                {
                    label: "Settlement Status",
                    name: "SettlementStatus__c",
                    type: "text"
                }
            ]
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
                { label: "LK Ref. No.", name: "LKRefNoPolicy_fm__c", type: "element", exportFormatter: "innerText" },
                { label: "Cedant Ref. No.", name: "CedantRefNo__c", collapsible: true },
                {
                    label: "Cedant Facility Name",
                    name: "CedantFacilityName__r.Name",
                    type: "url",
                    config: {
                        objectApiName: "COM_Facility__c",
                        idField: "CedantFacilityName__c"
                    },
                    collapsible: true
                },
                {
                    label: "Insured",
                    name: "Insured_fm__c",
                    type: "text"
                },
                { label: "Inception Date", name: "InceptionDate__c", type: "date" },
                { label: "Expiration Date", name: "ExpirationDate__c", type: "date" },
                { label: "LOB", name: "LOB3__c", collapsible: true }
            ]
        },

        {
            label: "Market Line",
            name: "MarketLine",
            columns: [
                {
                    label: "Reinsurer",
                    name: "Reinsurer__r.Name",
                    align: "left",
                    type: "url",
                    config: {
                        objectApiName: "Account",
                        idField: "Reinsurer__c"
                    }
                },
                {
                    label: "Market Facility Name",
                    name: "MarketFacilityName__r.Name",
                    type: "url",
                    align: "left",
                    collapsible: true,
                    config: {
                        objectApiName: "COM_Facility__c",
                        idField: "MarketFacilityName__c"
                    }
                },
                { label: "Co-brk Type", name: "CoBrokingType__c", collapsible: true }
            ]
        },

        {
            label: "Claim",
            name: "Claim",
            columns: [
                {
                    label: "Parent Claim No.",
                    name: "ParentClaimNo__r.Name",
                    type: "url",
                    width: "12rem",
                    collapsible: true,
                    config: {
                        objectApiName: "Claim",
                        idField: "ParentClaimNo__c"
                    }
                },
                {
                    label: "Cedant Claim No.",
                    name: "CedantClaimNo__c",
                    type: "text",
                    collapsible: true
                },
                { label: "Date of Loss", name: "DateOfLoss__c", type: "text" },
                { label: "SOC Seq.", name: "RefClaim__r.ClaimOrder__c" }
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
                    config: {
                        objectApiName: "COM_Facility__c",
                        idField: "FacilityName__c"
                    }
                },
                { label: "Facility_UY", name: "Facility_UY__c" }
            ]
        }
    ];
}