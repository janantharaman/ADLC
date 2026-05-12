import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import RecRelatedReconciliationModal from "c/recRelatedReconciliationModal";

import apexInquiryEvaluationSLIs from "@salesforce/apex/REC_SLIInquiryCtrl.inquiryEvaluationSLIs";
import apexUpdateSLIEvaluationDate from "@salesforce/apex/REC_SLIInquiryCtrl.updateSLIEvaluationDate";

import lblPageTitle from "@salesforce/label/c.EVA_LBL_SETTLEMENT_LINE_ITEM_INQUIRY";
import lblLoading from "@salesforce/label/c.COM_LBL_LOADING";
import lblBtnInquiry from "@salesforce/label/c.COM_BTN_INQUIRY";
import lblBtnReset from "@salesforce/label/c.COM_BTN_RESET";
import lblBtnEvaluation from "@salesforce/label/c.COM_BTN_EVALUATION";
import lblBtnRemove from "@salesforce/label/c.COM_BTN_REMOVE";
import lblBtnExpandAll from "@salesforce/label/c.COM_BTN_EXPAND_ALL";
import lblBtnCollapseAll from "@salesforce/label/c.COM_BTN_COLLAPSE_ALL";
import lblBtnExport from "@salesforce/label/c.COM_BTN_EXPORT";
import lblRows from "@salesforce/label/c.COM_LBL_ROWS";
import lblSelected from "@salesforce/label/c.COM_LBL_SELECTED";
import lblConfirmRemoveEvaluation from "@salesforce/label/c.EVA_MSG_CONFIRM_REMOVE_EVALUATION";
import lblSliUpdateSuccess from "@salesforce/label/c.EVA_MSG_SLI_UPDATE_SUCCESS";
import lblSliUpdateFailed from "@salesforce/label/c.EVA_MSG_SLI_UPDATE_FAILED";
import lblUnexpectedError from "@salesforce/label/c.EVA_MSG_UNEXPECTED_ERROR";
import lblFltPeriodClose from "@salesforce/label/c.EVA_FLT_PERIOD_CLOSE";
import lblFltPeriodClosePlaceholder from "@salesforce/label/c.EVA_FLT_PERIOD_CLOSE_PLACEHOLDER";
import lblFltClosingOrigin from "@salesforce/label/c.EVA_FLT_CLOSING_ORIGIN";
import lblColSliNo from "@salesforce/label/c.EVA_COL_SLI_NO";
import lblColClosingType from "@salesforce/label/c.EVA_COL_CLOSING_TYPE";
import lblColOriginCurrency from "@salesforce/label/c.EVA_COL_ORIGIN_CURRENCY";
import lblColOriginAmount from "@salesforce/label/c.EVA_COL_ORIGIN_AMOUNT";
import lblColAccountingDate from "@salesforce/label/c.EVA_COL_ACCOUNTING_DATE";
import lblColAccountingFXRate from "@salesforce/label/c.EVA_COL_ACCOUNTING_FX_RATE";
import lblColSettlementDate from "@salesforce/label/c.EVA_COL_SETTLEMENT_DATE";
import lblColAmtSettled from "@salesforce/label/c.EVA_COL_AMT_SETTLED";
import lblColEvaluationDate from "@salesforce/label/c.EVA_COL_EVALUATION_DATE";
import lblColEvaluationFXRate from "@salesforce/label/c.EVA_COL_EVALUATION_FX_RATE";
import lblColAmtApar from "@salesforce/label/c.EVA_COL_AMT_APAR";
import lblColUnrealizedFXGainLoss from "@salesforce/label/c.EVA_COL_UNREALIZED_FX_GAIN_LOSS";

export default class EvaSettlementLineItemInquiry extends LightningElement {
    // ── Table Data ───────────────────────────────────────────────────────

    @track tableData = [];

    // ── Table state ──────────────────────────────────────────────────────

    _isLoading = false;
    _selectedCount = 0;
    _hasDirtyRows = false;
    _showRemoveModal = false;
    _lastFilterValues = null;
    _lastPeriodCloseId = null;

    // ── Labels ────────────────────────────────────────────────────────────

    label = {
        pageTitle: lblPageTitle,
        loading: lblLoading,
        btnInquiry: lblBtnInquiry,
        btnReset: lblBtnReset,
        btnEvaluation: lblBtnEvaluation,
        btnRemove: lblBtnRemove,
        btnExpandAll: lblBtnExpandAll,
        btnCollapseAll: lblBtnCollapseAll,
        btnExport: lblBtnExport,
        confirmRemoveEvaluation: lblConfirmRemoveEvaluation
    };

    // ── Getters ──────────────────────────────────────────────────────────

    get evaluationBtnDisabled() {
        return this._selectedCount < 1 || !this._lastPeriodCloseId;
    }

    get removeEvaluationBtnDisabled() {
        return this._selectedCount < 1;
    }

    get displayRowCount() {
        return this.tableData?.length || 0;
    }

    get displaySelectedCount() {
        return this._selectedCount;
    }

    get tableSummary() {
        return `${lblRows}: ${this.displayRowCount} / ${lblSelected}: ${this.displaySelectedCount}`;
    }

    // ── Filter / Action handlers ──────────────────────────────────────────────
    handleInquiryClick() {
        const filterRef = this.refs.filterEval;
        if (!filterRef.validate()) return;

        const values = filterRef.getValues();
        this._lastFilterValues = values;
        const rawPeriodClose = values.PeriodClose__c;
        this._lastPeriodCloseId = Array.isArray(rawPeriodClose) ? (rawPeriodClose[0] ?? null) : (rawPeriodClose ?? null);

        const columnFields = this._extractColumnFields();

        this._isLoading = true;

        apexInquiryEvaluationSLIs({
            filters: JSON.stringify(values),
            relFields: columnFields.length ? JSON.stringify(columnFields) : null
        })
            .then((result) => {
                this.tableData = result || [];
                this._selectedCount = 0;
            })
            .catch((error) => {
                console.error("Inquiry error:", error);
                this._showToast("Error", error.body?.message || lblUnexpectedError, "error");
                this.tableData = [];
            })
            .finally(() => {
                this._isLoading = false;
                this.refs.table.clearSelection();
            });
    }

    handleResetClick() {
        const filterRef = this.refs.filterEval;
        filterRef.reset();
        this._lastPeriodCloseId = null;
    }

    handleFilterChange(event) {
        const { name, value } = event.detail;
        if (name === "PeriodClose__c" && !value) {
            this._lastPeriodCloseId = null;
        }
    }

    // ── Evaluation button handler ─────────────────────────────────────────

    handleEvaluationClick() {
        this._performEvaluationDateUpdate(this._lastPeriodCloseId);
    }

    handleRemoveEvaluationClick() {
        this._showRemoveModal = true;
    }

    handleRemoveModalConfirm() {
        this._showRemoveModal = false;
        this._performEvaluationDateUpdate(null);
    }

    handleRemoveModalCancel() {
        this._showRemoveModal = false;
    }

    async _performEvaluationDateUpdate(periodCloseId) {
        const selectedRows = this.refs.table.getSelectedRows() || [];
        if (selectedRows.length === 0) return;

        const sliIds = selectedRows.map((row) => row.Id);

        this._isLoading = true;
        try {
            await apexUpdateSLIEvaluationDate({
                sliIds: sliIds,
                periodCloseId: periodCloseId || null
            });
            this._showToast("Success", lblSliUpdateSuccess.replace("{0}", sliIds.length), "success");
            this.refs.table.clearSelection();
            this._selectedCount = 0;
            await this._refreshTableData();
        } catch (error) {
            console.error("Update PeriodClose error:", error);
            this._showToast("Error", error.body?.message || lblSliUpdateFailed, "error");
        } finally {
            this._isLoading = false;
        }
    }

    // ── recTable event handlers ───────────────────────────────────────────────

    handleRowSelection(event) {
        const { selectedRows } = event.detail;
        this._selectedCount = selectedRows.length;
        console.log("Selected rows:", selectedRows);
    }

    handleCellChange(event) {
        const { rowId, fieldName, value, oldValue } = event.detail;
        console.log(`Cell changed — row:${rowId} field:${fieldName} ${oldValue} → ${value}`);
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
        console.log(`Group "${groupName}" ${collapsed ? "collapsed" : "expanded"}`);
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

    async _refreshTableData() {
        if (!this._lastFilterValues) return;
        const columnFields = this._extractColumnFields();
        try {
            const result = await apexInquiryEvaluationSLIs({
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
            label: lblFltPeriodClose,
            name: "PeriodClose__c",
            type: "lookup",
            required: true,
            config: {
                objectApiName: "PeriodClose__c",
                labelField: "Name",
                placeholder: lblFltPeriodClosePlaceholder
            },
            size: 4
        },
        {
            label: lblFltClosingOrigin,
            name: "ClosingOrign__c",
            type: "combobox",
            size: 3,
            config: {
                picklistObject: "SettlementLineItem__c",
                picklistField: "ClosingOrign__c"
            }
        }
    ];

    // ── Column definitions (single source of truth) ───────────────────────────

    tableColumns = [
        {
            label: lblColSliNo,
            name: "Name",
            type: "url",
            config: { idField: "Id", objectApiName: "SettlementLineItem__c" }
        },
        { label: lblColClosingType, name: "ClosingType__c", type: "text" },
        { label: lblColOriginCurrency, name: "OriginCurrency__c", type: "text" },
        { label: lblColOriginAmount, name: "OriginAmount__c", type: "currency", config: { ccyField: "OriginCurrency__c" } },
        { label: lblColAccountingDate, name: "AccountingDate__c", type: "date" },
        { label: lblColAccountingFXRate, name: "AccountingFXRate__c", type: "number" },
        { label: lblColSettlementDate, name: "SettlementDate__c", type: "date" },
        { label: lblColAmtSettled, name: "AMTSettled__c", type: "currency", config: { ccyField: "OriginCurrency__c" } },
        { label: lblColEvaluationDate, name: "EvaluationDate__c", type: "date" },
        { label: lblColEvaluationFXRate, name: "EvaluationFXRate__c", type: "number" },
        { label: lblColAmtApar, name: "AmtAPAR__c", type: "number" },
        { label: lblColUnrealizedFXGainLoss, name: "UnrealizedFXGainLoss__c", type: "number" }
    ];
}