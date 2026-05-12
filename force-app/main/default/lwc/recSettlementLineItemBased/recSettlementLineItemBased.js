import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import apexGetBaseSettlementLineItem from "@salesforce/apex/REC_SLIBasedReconCtrl.getBaseSettlementLineItem";
import apexGetReconciliationStatus from "@salesforce/apex/REC_SLIBasedReconCtrl.getReconciliationStatus";
import apexInquiryBankTransactions from "@salesforce/apex/REC_SLIBasedReconCtrl.inquiryBankTransactions";
import apexInquiryFiduciaryOthers from "@salesforce/apex/REC_SLIBasedReconCtrl.inquiryFiduciaryOthers";
import apexGetRelatedReconciliationLineItems from "@salesforce/apex/REC_SLIBasedReconCtrl.getRelatedReconciliationLineItems";
import apexDraftSettlementLineItemBased from "@salesforce/apex/REC_SLIBasedReconCtrl.draftSettlementLineItemBased";
import apexConfirmSettlementLineItemBased from "@salesforce/apex/REC_SLIBasedReconCtrl.confirmSettlementLineItemBased";
import { roundByCurrency } from "c/recUtils";
import apexGetPcOtherChargesRlis from "@salesforce/apex/REC_SLIBasedReconCtrl.getPcOtherChargesRlis";
import apexGetOptionsByIds from "@salesforce/apex/REC_Lookup_Ctrl.getOptionsByIds";

// ── Constants ────────────────────────────────────────────────────────────────

const SOURCE_TYPE = { BT: "Bank Transaction", FO: "Fiduciary Others" };
const STATUS = { CONFIRMED: "Confirmed", CLEAR: "Clear", PARTIAL: "Partial" };
const VALID_CONFIRM_STATUSES = [STATUS.CLEAR, STATUS.PARTIAL];

function buildRecordUrl(objectApiName, recordId) {
    return `/lightning/r/${objectApiName}/${recordId}/view`;
}

export default class RecSettlementLineItemBased extends LightningElement {
    @api recordId;

    // ── Table Data ───────────────────────────────────────────────────────
    @track baseSliData = [];
    @track btData = [];
    @track selectedItems = [];
    @track otherChargesData = [];
    @track foData = [];

    // ── Table State ──────────────────────────────────────────────────────
    _isLoading = false;
    _selectedCount = 0;
    _selectedItemSelectedCount = 0;
    _foSelectedCount = 0;
    _otherChargesSelectedCount = 0;
    _reconciliationStatus = null;
    _activeTab = "bt";
    _tempIdCounter = 0;
    _otherChargesTempId = 0;

    // ── Lifecycle ────────────────────────────────────────────────────────

    connectedCallback() {
        this.getBaseSettlementLineItem();
        this.getRelatedReconciliationLineItems();
        this.getOtherCharges();
        this.getReconciliationStatus();
    }

    // ── Computed Properties ──────────────────────────────────────────────

    get isConfirmed() {
        return this._reconciliationStatus === STATUS.CONFIRMED;
    }

    get confirmBtnDisabled() {
        if (this.isConfirmed) return true;
        if (!this.selectedItems?.length) return true;
    }

    get actionBtnsDisabled() {
        return this.isConfirmed;
    }

    get draftBtnDisabled() {
        if (this.isConfirmed) return true;
        return false;
    }

    get displayRowCount() {
        return this.btData?.length || 0;
    }

    get displaySelectedCount() {
        return this._selectedCount;
    }

    get displaySelectedItemRowCount() {
        return this.selectedItems?.length || 0;
    }

    get displaySelectedItemSelectedCount() {
        return this._selectedItemSelectedCount;
    }

    get displayFoRowCount() {
        return this.foData?.length || 0;
    }

    get displayFoSelectedCount() {
        return this._foSelectedCount;
    }

    get settlementCurrency() {
        return this.selectedItems?.[0]?.BTCurrency_fm__c || null;
    }

    get displaySettlementCurrency() {
        return this.settlementCurrency || "N/A";
    }

    get reconciledAmount() {
        const raw = this.selectedItems.reduce((sum, item) => sum + (item.ReconciledAMT__c || 0), 0);
        return roundByCurrency(raw, this.settlementCurrency);
    }

    get btDisabledRowIds() {
        return this._getDisabledRowIds(SOURCE_TYPE.BT, "RefBankTransaction__c", this.btData, "Currency__c");
    }

    get foDisabledRowIds() {
        return this._getDisabledRowIds(SOURCE_TYPE.FO, "RefFiduciaryOthers__c", this.foData, "SettlementCurrency__c");
    }

    get baseSliDisabledRowIds() {
        if (!this.isConfirmed) return [];
        return this.baseSliData.map((r) => r.Id);
    }

    get selectedItemDisabledRowIds() {
        if (!this.isConfirmed) return [];
        return this.selectedItems.map((r) => r.Id);
    }

    get otherChargesDisabledRowIds() {
        if (!this.isConfirmed) return [];
        return this.otherChargesData.map((r) => r.Id);
    }

    get _baseSliAccountId() {
        return this.baseSliData?.[0]?.RefSettlementLineItem__r?.AccountName__c || null;
    }

    get foFilter() {
        return this.refs?.foFilter || this.template.querySelector("c-rec-filter-bar[data-id='foFilter']");
    }

    // ── Data Loading ─────────────────────────────────────────────────────

    async getBaseSettlementLineItem() {
        try {
            const rli = await apexGetBaseSettlementLineItem({ reconId: this.recordId });
            this.baseSliData = rli ? [rli] : [];
            this._applyFilterAccountDefault();
        } catch (error) {
            console.error("Failed to load Base Settlement Line Item:", error);
        }
    }

    _applyFilterAccountDefault() {
        const accountId = this._baseSliAccountId;
        if (!accountId) return;

        const apply = (defs) => {
            const current = defs.find((d) => d.name === "AccountName__c");
            if (current?.defaultValue === accountId && current?.disabled === true) return defs;
            return defs.map((def) =>
                def.name === "AccountName__c" ? { ...def, defaultValue: accountId, disabled: true } : def
            );
        };

        this.btFilterDefs = apply(this.btFilterDefs);
        this.foFilterDefs = apply(this.foFilterDefs);
    }

    async getReconciliationStatus() {
        try {
            this._reconciliationStatus = await apexGetReconciliationStatus({ reconciliationId: this.recordId });
        } catch (error) {
            console.error("Failed to load Reconciliation status:", error);
        }
    }

    async getOtherCharges() {
        try {
            const rows = await apexGetPcOtherChargesRlis({ reconciliationId: this.recordId });
            const ccy = this.settlementCurrency;
            this.otherChargesData = (rows || []).map((row) => ({ ...row, OriginCurrency__c: ccy }));
        } catch (error) {
            console.error("Failed to load Other Charges:", error);
        }
    }

    async getRelatedReconciliationLineItems() {
        try {
            const rlis = await apexGetRelatedReconciliationLineItems({ reconciliationId: this.recordId });
            if (rlis?.length) {
                this.selectedItems = rlis.map((rli) => {
                    const isFo = !!rli.RefFiduciaryOthers__c;
                    const isBt = !!rli.RefBankTransaction__c;
                    return {
                        ...rli,
                        _sourceType: isFo ? SOURCE_TYPE.FO : isBt ? SOURCE_TYPE.BT : "Unknown",
                        _refName: isFo ? rli.RefFiduciaryOthers__r?.Name : rli.RefBankTransaction__r?.Name,
                        _refUrl: isFo
                            ? buildRecordUrl("FiduciaryOthers__c", rli.RefFiduciaryOthers__c)
                            : isBt
                              ? buildRecordUrl("BankTransaction__c", rli.RefBankTransaction__c)
                              : null,
                        ...(isFo && { BTAccountName_fm__c: rli.RefFiduciaryOthers__r?.AccountName__c })
                    };
                });
                this._syncOtherChargesCurrency();
            }
        } catch (error) {
            console.error("Failed to load Reconciliation Line Items:", error);
        }
    }

    // ── Private Helpers ──────────────────────────────────────────────────

    /**
     * Create a ReconciliationLineItem-shaped object from a BankTransaction record.
     */
    _createRliFromBt(bt) {
        return {
            Id: `_temp_${this._tempIdCounter++}_${bt.Id}`,
            _sourceType: SOURCE_TYPE.BT,
            _refName: bt.Name,
            _refUrl: buildRecordUrl("BankTransaction__c", bt.Id),
            RefBankTransaction__c: bt.Id,
            RefBankTransaction__r: { ...bt },
            BizRegion__c: bt.BizRegion__c,
            TransactionDate_fm__c: bt.TransactionDate__c,
            BTCurrency_fm__c: bt.Currency__c,
            BTOriginAmount_fm__c: bt.OriginAmount__c,
            Depositor_fm__c: bt.Depositor__c,
            BTAccountName_fm__c: bt.AccountName__c,
            // RLI Calculation fields
            TotalClearedAmount__c: bt.TotalClearedAmount__c,
            NetAmountAfterClearing__c: bt.NetBalanceAftCleared__c,
            BTStatus__c: bt.Status__c,
            ReconciledAMT__c: bt.NetBalanceAftCleared__c
        };
    }

    /**
     * Create a ReconciliationLineItem-shaped object from a FiduciaryOthers record.
     */
    _createRliFromFo(fo) {
        return {
            Id: `_temp_${this._tempIdCounter++}_${fo.Id}`,
            _sourceType: SOURCE_TYPE.FO,
            _refName: fo.Name,
            _refUrl: buildRecordUrl("FiduciaryOthers__c", fo.Id),
            RefFiduciaryOthers__c: fo.Id,
            RefFiduciaryOthers__r: { ...fo },
            BizRegion__c: fo.BizRegion__c,
            TransactionDate_fm__c: fo.TransactionDate__c,
            BTCurrency_fm__c: fo.SettlementCurrency__c,
            BTOriginAmount_fm__c: fo.OriginAmount__c,
            Depositor_fm__c: fo.Depositor__c,
            BTAccountName_fm__c: fo.AccountName__c,
            // RLI Calculation fields
            TotalClearedAmount__c: fo.ReconciledAMT__c,
            NetAmountAfterClearing__c: fo.NotReconciledAMT__c,
            BTStatus__c: fo.Status__c,
            ReconciledAMT__c: fo.NotReconciledAMT__c
        };
    }

    /**
     * Disabled Row ID 산출 공통 로직.
     * 이미 선택된 항목과 통화 불일치 항목을 모아 반환.
     */
    _getDisabledRowIds(sourceType, refField, tableData, ccyField) {
        const alreadySelectedIds = this.selectedItems
            .filter((r) => r._sourceType === sourceType)
            .map((r) => r[refField])
            .filter(Boolean);
        const ccy = this.settlementCurrency;
        if (ccy && tableData?.length) {
            const mismatchIds = tableData.filter((r) => r[ccyField] !== ccy).map((r) => r.Id);
            return [...new Set([...alreadySelectedIds, ...mismatchIds])];
        }
        return alreadySelectedIds;
    }

    /**
     * 공통 Inquiry: filterRef에서 값을 읽어 apexFn 호출 후, 결과를 콜백으로 전달.
     */
    _inquiry(filterRef, apexFn, columns, onResult, extraFilters, extraApexParams) {
        const values = filterRef.getValues();
        if (extraFilters) {
            Object.assign(values, extraFilters);
        }
        const columnFields = this._extractColumnFields(columns);

        this._isLoading = true;
        apexFn({
            filters: JSON.stringify(values),
            relFields: columnFields.length ? JSON.stringify(columnFields) : null,
            ...extraApexParams
        })
            .then((result) => onResult(result || []))
            .catch((error) => {
                console.error("Inquiry error:", error);
                onResult([]);
            })
            .finally(() => {
                this._isLoading = false;
            });
    }

    /**
     * Extracts all leaf-column field names from a column definition array.
     * Relationship fields (dot-notation) are appended to the SOQL SELECT;
     * direct fields are validated against the selector's getDefaultFields().
     */
    _extractColumnFields(columns) {
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
        walk(columns);
        return [...fields];
    }

    /**
     * 공통 통화 일관성 검증.
     * @returns {boolean} 검증 통과 시 true
     */
    _validateCurrency(newRows, baseCcy, ccyField, label) {
        if (baseCcy) {
            const mismatch = newRows.filter((r) => r[ccyField] !== baseCcy);
            if (mismatch.length) {
                this.showToast("Error", `Settlement Currency must be the same: ${baseCcy}`, "error");
                return false;
            }
        } else {
            const currencies = new Set(newRows.map((r) => r[ccyField]));
            if (currencies.size > 1) {
                this.showToast("Error", `Cannot select ${label} with different Settlement Currencies.`, "error");
                return false;
            }
        }
        return true;
    }

    _syncOtherChargesCurrency() {
        const ccy = this.settlementCurrency;
        this.otherChargesData = this.otherChargesData.map((row) => ({
            ...row,
            OriginCurrency__c: ccy ? ccy : row.OriginCurrency__c
        }));
    }

    _handleFilterChange(filterRef, event) {
        const { name, value } = event.detail;
        if (name === "Status__c") {
            filterRef.setFieldError(
                "Status__c",
                value === STATUS.CLEAR ? `"${STATUS.CLEAR}" status cannot be used as a filter.` : null
            );
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // ── Tab Handler ──────────────────────────────────────────────────────

    handleTabChange(event) {
        this._activeTab = event.target.value;
    }

    // ── BT Event Handlers ────────────────────────────────────────────────

    handleBtFilterChange(event) {
        this._handleFilterChange(this.refs.btFilter, event);
    }

    handleBtInquiryClick() {
        const extra = this._baseSliAccountId ? { AccountName__c: this._baseSliAccountId } : {};
        this._inquiry(
            this.refs.btFilter,
            apexInquiryBankTransactions,
            this.btColumns,
            (data) => {
                this.btData = data;
                this._selectedCount = 0;
            },
            extra,
            { reconciliationId: this.recordId }
        );
    }

    handleBtResetClick() {
        this.refs.btFilter.reset();
    }

    handleBtRowSelection(event) {
        this._selectedCount = event.detail.selectedRows.length;
    }

    handleBtSelect() {
        const selectedRows = this.refs.btTable.getSelectedRows();
        if (!selectedRows.length) return;

        const existingBtIds = new Set(
            this.selectedItems
                .filter((r) => r._sourceType === SOURCE_TYPE.BT)
                .map((r) => r.RefBankTransaction__c)
                .filter(Boolean)
        );
        const newRows = selectedRows.filter((r) => !existingBtIds.has(r.Id));
        if (!newRows.length) return;

        // Currency check against ALL existing selectedItems (both BT and FO)
        const baseCcy = this.settlementCurrency;
        if (!this._validateCurrency(newRows, baseCcy, "Currency__c", "Bank Transactions")) return;

        // BT → ReconciliationLineItem 변환
        const rliRows = newRows.map((bt) => this._createRliFromBt(bt));

        this.selectedItems = [...this.selectedItems, ...rliRows];
        this.refs.btTable.clearSelection();
        this._selectedCount = 0;

        this._syncOtherChargesCurrency();
    }

    // ── FO Event Handlers ────────────────────────────────────────────────

    handleFoFilterChange(event) {
        this._handleFilterChange(this.foFilter, event);
    }

    handleFoInquiryClick() {
        console.log("all refs:", Object.keys(this.refs));

        const extra = this._baseSliAccountId ? { AccountName__c: this._baseSliAccountId } : {};
        this._inquiry(
            this.foFilter,
            apexInquiryFiduciaryOthers,
            this.foColumns,
            (data) => {
                this.foData = data;
                this._foSelectedCount = 0;
            },
            extra,
            { reconciliationId: this.recordId }
        );
    }

    handleFoResetClick() {
        this.foFilter.reset();
    }

    handleFoRowSelection(event) {
        this._foSelectedCount = event.detail.selectedRows.length;
    }

    handleFoSelect() {
        const selectedRows = this.refs.foTable.getSelectedRows();
        if (!selectedRows.length) return;

        const existingFoIds = new Set(
            this.selectedItems
                .filter((r) => r._sourceType === SOURCE_TYPE.FO)
                .map((r) => r.RefFiduciaryOthers__c)
                .filter(Boolean)
        );
        const newRows = selectedRows.filter((r) => !existingFoIds.has(r.Id));
        if (!newRows.length) return;

        // Currency check against ALL existing selectedItems (both BT and FO)
        const baseCcy = this.settlementCurrency;
        if (!this._validateCurrency(newRows, baseCcy, "SettlementCurrency__c", "Fiduciary Others")) return;

        // FO → ReconciliationLineItem 변환
        const rliRows = newRows.map((fo) => this._createRliFromFo(fo));

        this.selectedItems = [...this.selectedItems, ...rliRows];
        this.refs.foTable.clearSelection();
        this._foSelectedCount = 0;

        this._syncOtherChargesCurrency();
    }

    // ── Selected Items Event Handlers ────────────────────────────────────

    handleSelectedItemRowSelection(event) {
        this._selectedItemSelectedCount = event.detail.selectedRows.length;
    }

    handleSelectedItemDelete() {
        const selected = this.refs.selectedTable.getSelectedRows();
        if (!selected.length) return;
        const removeIds = new Set(selected.map((r) => r.Id));
        this.selectedItems = this.selectedItems.filter((r) => !removeIds.has(r.Id));
        this._selectedItemSelectedCount = 0;
        this._syncOtherChargesCurrency();
    }

    // ── Save Helpers (shared by Draft & Confirm) ─────────────────────────

    /**
     * Collects common save payload from all tables.
     * @returns {{ baseSli, otherCharges, orderKeys, details }}
     */
    _collectSavePayload() {
        const selectedData = this.refs.selectedTable.getData();
        const baseSliTableData = this.refs.baseSliTable.getData();
        const baseSli = baseSliTableData?.[0];
        const otherCharges = baseSli?.OtherCharges__c || 0;

        // Preserve row order keys for post-save restoration
        const orderKeys = selectedData.map((item) => item.RefBankTransaction__c || item.RefFiduciaryOthers__c);

        // Build detail records for Apex (strip _temp IDs)
        const details = selectedData.map((item) => {
            const d = { ReconciledAMT__c: item.ReconciledAMT__c };
            if (item.Id && !String(item.Id).startsWith("_temp")) d.Id = item.Id;
            if (item.RefBankTransaction__c) d.RefBankTransaction__c = item.RefBankTransaction__c;
            if (item.RefFiduciaryOthers__c) d.RefFiduciaryOthers__c = item.RefFiduciaryOthers__c;
            return d;
        });

        return { baseSli, otherCharges, orderKeys, details };
    }

    /**
     * Refreshes data after a save operation.
     * @param {string[]} orderKeys  Row order keys for restoring selected-items order.
     * @param {Object}   opts
     * @param {boolean}   opts.clearInquiryData  True to clear BT/FO inquiry tables (Confirm).
     */
    async _refreshAfterSave(orderKeys, { clearInquiryData = false } = {}) {
        const refreshPromises = [this.getBaseSettlementLineItem(), this.getRelatedReconciliationLineItems()];

        if (clearInquiryData) {
            // Confirm: clear inquiry tables, reload Other Charges
            this.btData = [];
            this.foData = [];
            this._selectedCount = 0;
            this._foSelectedCount = 0;
            refreshPromises.push(this.getOtherCharges());
        } else {
            // Draft: reload Other Charges and re-query existing inquiry data
            refreshPromises.push(this.getOtherCharges());
            if (this.btData.length) {
                const btValues = this.refs.btFilter.getValues();
                if (this._baseSliAccountId) {
                    btValues.AccountName__c = this._baseSliAccountId;
                }
                const btColumnFields = this._extractColumnFields(this.btColumns);
                refreshPromises.push(
                    apexInquiryBankTransactions({
                        filters: JSON.stringify(btValues),
                        relFields: btColumnFields.length ? JSON.stringify(btColumnFields) : null
                    }).then((result) => {
                        this.btData = result || [];
                        this._selectedCount = 0;
                    })
                );
            }
            if (this.foData.length) {
                const foValues = this.foFilter.getValues();
                if (this._baseSliAccountId) {
                    foValues.AccountName__c = this._baseSliAccountId;
                }
                const foColumnFields = this._extractColumnFields(this.foColumns);
                refreshPromises.push(
                    apexInquiryFiduciaryOthers({
                        filters: JSON.stringify(foValues),
                        relFields: foColumnFields.length ? JSON.stringify(foColumnFields) : null
                    }).then((result) => {
                        this.foData = result || [];
                        this._foSelectedCount = 0;
                    })
                );
            }
        }

        await Promise.all(refreshPromises);

        // Restore selected item row order
        if (orderKeys?.length && this.selectedItems.length) {
            const orderMap = new Map(orderKeys.map((key, idx) => [key, idx]));
            this.selectedItems = [...this.selectedItems].sort((a, b) => {
                const keyA = a.RefBankTransaction__c || a.RefFiduciaryOthers__c;
                const keyB = b.RefBankTransaction__c || b.RefFiduciaryOthers__c;
                return (orderMap.get(keyA) ?? 999) - (orderMap.get(keyB) ?? 999);
            });
        }
    }

    /**
     * Resolves a dot-notation field path from an object.
     * Checks flat key first (recTable stores edits as flat keys), then traverses.
     */
    _resolveField(obj, path) {
        if (!path || !obj) return undefined;
        // Flat key takes precedence (edit override)
        if (Object.prototype.hasOwnProperty.call(obj, path)) return obj[path];
        // Fall back to dot-notation traversal
        if (path.includes(".")) {
            return path.split(".").reduce((o, key) => (o != null ? o[key] : undefined), obj);
        }
        return undefined;
    }

    // ── Draft / Confirm Handlers ─────────────────────────────────────────

    async handleSelectedItemDraft() {
        if (this.draftBtnDisabled) return;

        const { otherCharges, orderKeys, details } = this._collectSavePayload();

        // Collect P_C Other Charges RLI items
        // NOTE: use state directly; otherChargesTable.getData() can return []
        // while record-picker (COA) lookup hydration is in flight.
        const otherChargesTableData = this.otherChargesData;
        const otherChargeRliItems = otherChargesTableData.map((item) => {
            const d = {
                ClosingType__c: "P_C",
                COA_lk__c: item.COA_lk__c,
                OriginAmount__c: item.OriginAmount__c,
                RefSettlementLineItem__c: item.RefSettlementLineItem__c,
                RefBankTransaction__c: item.RefBankTransaction__c,
                Remarks__c: item.Remarks__c
            };
            if (item.Id && !String(item.Id).startsWith("_oc_temp")) d.Id = item.Id;
            return d;
        });

        this._isLoading = true;
        try {
            await apexDraftSettlementLineItemBased({
                reconciliationId: this.recordId,
                details,
                otherCharges,
                otherChargeRliItems
            });

            this.showToast("Success", "Draft saved successfully.", "success");
            await this._refreshAfterSave(orderKeys);
        } catch (error) {
            console.error("Draft error:", error);
            this.showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    async handleSelectedItemConfirm() {
        if (this.confirmBtnDisabled) return;

        const { baseSli, otherCharges, orderKeys, details } = this._collectSavePayload();

        // Build baseSliInput: user-entered fields from Base SLI table
        const baseSliInput = {
            RemittanceOnHold__c: this._resolveField(baseSli, "RefSettlementLineItem__r.RemittanceOnHold__c"),
            HoldReason__c: this._resolveField(baseSli, "RefSettlementLineItem__r.HoldReason__c"),
            ExchangeDate__c: this._resolveField(baseSli, "RefSettlementLineItem__r.ExchangeDate__c"),
            ExchangeCurrency__c: this._resolveField(baseSli, "RefSettlementLineItem__r.ExchangeCurrency__c"),
            ExchangeAmount__c: this._resolveField(baseSli, "RefSettlementLineItem__r.ExchangeAmount__c"),
            ExchangeRate__c: this._resolveField(baseSli, "RefSettlementLineItem__r.ExchangeRate__c")
        };

        // Build Other Charges items (P_C Settlement Line Items)
        const otherChargesTableData = this.refs.otherChargesTable.getData();
        const otherChargeItems = otherChargesTableData.map((item) => ({
            ClosingType__c: "P_C",
            OriginCurrency__c: item.OriginCurrency__c,
            OriginAmount__c: item.OriginAmount__c,
            COA_lk__c: item.COA_lk__c,
            OriginSettlementLineItem__c: item.RefSettlementLineItem__c,
            OriginBankTransaction__c: item.RefBankTransaction__c,
            Remark__c: item.Remarks__c
        }));

        // Collect P_C Other Charges RLI items
        const otherChargeRliItems = otherChargesTableData.map((item) => {
            const d = {
                ClosingType__c: "P_C",
                COA_lk__c: item.COA_lk__c,
                OriginAmount__c: item.OriginAmount__c,
                RefSettlementLineItem__c: item.RefSettlementLineItem__c,
                RefBankTransaction__c: item.RefBankTransaction__c,
                Remarks__c: item.Remarks__c
            };
            if (item.Id && !String(item.Id).startsWith("_oc_temp")) d.Id = item.Id;
            return d;
        });

        this._isLoading = true;
        try {
            await apexConfirmSettlementLineItemBased({
                reconciliationId: this.recordId,
                details,
                otherCharges,
                baseSliInput,
                otherChargeItems,
                otherChargeRliItems
            });

            this.showToast("Success", "Reconciliation confirmed successfully.", "success");

            // Update status locally (avoids cacheable stale read)
            this._reconciliationStatus = STATUS.CONFIRMED;

            // Refresh: reload base SLI, selected items, other charges; clear inquiry tables
            await this._refreshAfterSave(orderKeys, { clearInquiryData: true });
        } catch (error) {
            console.error("Confirm error:", error);
            this.showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    // ── Other Charges Event Handlers ─────────────────────────────────────

    handleOtherChargesRowSelection(event) {
        this._otherChargesSelectedCount = event.detail.selectedRows.length;
    }

    handleOtherChargesDelete() {
        const selected = this.refs.otherChargesTable.getSelectedRows();
        if (!selected.length) return;
        const removeIds = new Set(selected.map((r) => r.Id));
        this.otherChargesData = this.otherChargesData.filter((r) => !removeIds.has(r.Id));
        this._otherChargesSelectedCount = 0;
    }

    handleOtherChargesAdd() {
        const ccy = this.settlementCurrency;
        const newRow = {
            Id: `_oc_temp_${this._otherChargesTempId++}`,
            OriginCurrency__c: ccy || null,
            ClosingType__c: "P_C",
            RefSettlementLineItem__c: this.baseSliData[0]?.RefSettlementLineItem__c || null,
            RefBankTransaction__c: this.selectedItems.find((r) => r.RefBankTransaction__c)?.RefBankTransaction__c || null
        };
        this.otherChargesData = [...this.otherChargesData, newRow];
    }

    async handleOtherChargesCellChange(event) {
        const { rowId, fieldName, value } = event.detail;

        if (fieldName === "COA_lk__c") {
            let coaName = null;
            if (value) {
                try {
                    const options = await apexGetOptionsByIds({
                        objectApiName: "COA__c",
                        labelField: "COAName__c",
                        ids: [value]
                    });
                    coaName = options?.[0]?.label || null;
                } catch (error) {
                    console.error("Failed to fetch COA Name:", error);
                }
            }
            this.otherChargesData = this.otherChargesData.map((row) =>
                row.Id === rowId ? { ...row, COA_lk__c: value, COAName_fm__c: coaName } : row
            );
        }
    }

    // ── Column & Filter Definitions ──────────────────────────────────────

    baseSliColumns = [
        {
            label: "SLI No.",
            name: "RefSettlementLineItem__r.Name",
            type: "url",
            config: {
                idField: "RefSettlementLineItem__c",
                objectApiName: "SettlementLineItem__c"
            }
        },
        {
            label: "SLI Details",
            name: "SLIDetails",
            columns: [
                {
                    label: "Closing Type",
                    name: "RefSettlementLineItem__r.ClosingType__c",
                    align: "center"
                },
                {
                    label: "COA",
                    name: "RefSettlementLineItem__r.COA_lk__c",
                    type: "record-picker",
                    disabled: true,
                    config: {
                        objectApiName: "COA__c",
                        labelField: "Name"
                    }
                },
                {
                    label: "COA Name",
                    name: "RefSettlementLineItem__r.COAName_fm__c"
                },
                {
                    label: "Account Name",
                    name: "RefSettlementLineItem__r.AccountName__c",
                    type: "record-picker",
                    disabled: true,
                    config: {
                        objectApiName: "Account",
                        labelField: "Name"
                    }
                },
                {
                    label: "Origin Currency",
                    name: "RefSettlementLineItem__r.OriginCurrency__c",
                    align: "center"
                },
                {
                    label: "Origin Amount",
                    name: "RefSettlementLineItem__r.OriginAmount__c",
                    type: "currency",
                    config: { ccyField: "RefSettlementLineItem__r.OriginCurrency__c" }
                }
            ]
        },
        {
            label: "Settlement Details",
            name: "SettlementDetails",
            columns: [
                {
                    label: "Settlement Date",
                    name: "SettlementDate__c",
                    type: "date"
                },
                {
                    label: "Settlement Currency",
                    name: "SettlementCurrency__c",
                    align: "center"
                },
                {
                    label: "FX Rate (to Settlement)",
                    name: "FXRateOrigintoSettlement__c",
                    type: "number",
                    config: {
                        decimalPlaces: 6
                    }
                },
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
                    editable: true,
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
                    name: "RefSettlementLineItem__r.SettlementType__c"
                },
                {
                    label: "Settlement Status",
                    name: "RefSettlementLineItem__r.SettlementStatus__c"
                },
                {
                    label: "Remittance On Hold",
                    name: "RefSettlementLineItem__r.RemittanceOnHold__c",
                    type: "boolean",
                    align: "center",
                    editable: true
                },
                {
                    label: "Hold Reason",
                    name: "RefSettlementLineItem__r.HoldReason__c",
                    type: "text",
                    editable: true
                }
            ]
        },
        {
            label: "Exchange Details",
            name: "ExchangeDetails",
            columns: [
                {
                    label: "Exchange Date",
                    name: "RefSettlementLineItem__r.ExchangeDate__c",
                    type: "date",
                    editable: true
                },
                {
                    label: "Exchange Currency",
                    name: "RefSettlementLineItem__r.ExchangeCurrency__c",
                    type: "combobox",
                    editable: true,
                    config: {
                        picklistObject: "SettlementLineItem__c",
                        picklistField: "ExchangeCurrency__c"
                    }
                },
                {
                    label: "Exchange Amount",
                    name: "RefSettlementLineItem__r.ExchangeAmount__c",
                    type: "currency",
                    editable: true,
                    config: { ccyField: "RefSettlementLineItem__r.ExchangeCurrency__c" }
                },
                {
                    label: "Exchange Rate",
                    name: "RefSettlementLineItem__r.ExchangeRate__c",
                    type: "number",
                    editable: true
                }
            ]
        }
    ];

    btFilterDefs = [
        // ── Row 1 ──────────────────────────────────────────────────────────────
        {
            label: "BT Status",
            name: "Status__c",
            type: "combobox",
            size: 4,
            config: {
                picklistObject: "BankTransaction__c",
                picklistField: "Status__c",
                picklistExclude: [STATUS.CLEAR]
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
        // ── Row 2 ──────────────────────────────────────────────────────────────
        {
            label: "Account Name",
            name: "AccountName__c",
            type: "record-picker",
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

    btColumns = [
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
            name: "AccountName__c",
            type: "record-picker",
            disabled: true,
            config: {
                objectApiName: "Account",
                labelField: "Name",
                placeholder: "Search reinsurer..."
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
            label: "Status",
            name: "Status__c"
        },
        {
            label: "Remarks",
            name: "Remarks__c",
            type: "text"
        }
    ];

    selectedItemColumns = [
        {
            label: "Source",
            name: "_sourceType",
            align: "center"
        },
        {
            label: "Transaction No.",
            name: "_refName",
            type: "url",
            config: {
                urlField: "_refUrl"
            }
        },
        {
            label: "Transaction Date",
            name: "TransactionDate_fm__c",
            type: "date"
        },
        {
            label: "Currency",
            name: "BTCurrency_fm__c"
        },
        {
            label: "Origin Amount",
            name: "BTOriginAmount_fm__c",
            type: "currency",
            config: { ccyField: "BTCurrency_fm__c" }
        },
        {
            label: "Account Name",
            name: "BTAccountName_fm__c",
            type: "record-picker",
            disabled: true,
            config: {
                objectApiName: "Account",
                labelField: "Name",
                placeholder: "Search Account..."
            }
        },
        {
            label: "Total Cleared AMT",
            name: "TotalClearedAmount__c",
            type: "currency",
            config: { ccyField: "BTCurrency_fm__c" }
        },
        {
            label: "Not-Reconciled AMT",
            name: "NetAmountAfterClearing__c",
            type: "currency",
            config: { ccyField: "BTCurrency_fm__c" }
        },
        {
            label: "Status",
            name: "BTStatus__c"
        },
        {
            label: "Reconciled AMT",
            name: "ReconciledAMT__c",
            type: "currency",
            editable: true,
            config: { ccyField: "BTCurrency_fm__c" }
        }
    ];

    foFilterDefs = [
        // ── Row 1 ──────────────────────────────────────────────────────────────
        {
            label: "FO Status",
            name: "Status__c",
            type: "combobox",
            size: 4,
            config: {
                picklistObject: "FiduciaryOthers__c",
                picklistField: "Status__c",
                picklistExclude: [STATUS.CLEAR]
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
            name: "SettlementCurrency__c",
            type: "combobox",
            size: 4,
            config: {
                picklistObject: "FiduciaryOthers__c",
                picklistField: "SettlementCurrency__c"
            }
        },
        // ── Row 2 ──────────────────────────────────────────────────────────────
        {
            label: "Account Name",
            name: "AccountName__c",
            type: "record-picker",
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

    foColumns = [
        {
            label: "F.Others No.",
            name: "Name",
            type: "url",
            config: {
                idField: "RefFiduciaryOthers__c",
                objectApiName: "FiduciaryOthers__c"
            }
        },
        {
            label: "Transaction Date",
            name: "TransactionDate__c",
            type: "date"
        },
        {
            label: "Settlement Currency",
            name: "SettlementCurrency__c"
        },
        {
            label: "Origin Amount",
            name: "OriginAmount__c",
            type: "currency",
            config: { ccyField: "SettlementCurrency__c" }
        },
        {
            label: "Depositor",
            name: "Depositor__c"
        },
        {
            label: "Account Name",
            name: "AccountName__c",
            type: "record-picker",
            disabled: true,
            config: {
                objectApiName: "Account",
                labelField: "Name",
                placeholder: "Search reinsurer..."
            }
        },
        {
            label: "Reconciled AMT",
            name: "ReconciledAMT__c",
            type: "currency",
            config: { ccyField: "SettlementCurrency__c" }
        },
        {
            label: "Not-Reconciled AMT",
            name: "NotReconciledAMT__c",
            type: "currency",
            config: { ccyField: "SettlementCurrency__c" }
        },
        {
            label: "Status",
            name: "Status__c"
        },
        {
            label: "Remarks",
            name: "Remarks__c",
            type: "text"
        }
    ];

    otherChargesColumns = [
        {
            label: "COA",
            name: "COA_lk__c",
            type: "record-picker",
            align: "left",
            editable: true,
            config: {
                objectApiName: "COA__c",
                labelField: "Name",
                subLabelFields: ["COAName__c"]
            }
        },
        { label: "COA Name", name: "COAName_fm__c" },
        {
            label: "Closing Type",
            name: "ClosingType__c"
        },
        {
            label: "Origin Currency",
            name: "OriginCurrency__c"
        },
        {
            label: "Amount",
            name: "OriginAmount__c",
            type: "currency",
            editable: true,
            config: { ccyField: "OriginCurrency__c" }
        },
        {
            label: "Origin Settlement Line Item",
            name: "RefSettlementLineItem__c",
            type: "record-picker",
            editable: true,
            config: {
                objectApiName: "SettlementLineItem__c",
                labelField: "Name",
                placeholder: "Search Settlement Line Item..."
            }
        },
        {
            label: "Origin Bank Transaction",
            name: "RefBankTransaction__c",
            type: "record-picker",
            editable: true,
            config: {
                objectApiName: "BankTransaction__c",
                labelField: "Name",
                placeholder: "Search Bank Transaction..."
            }
        },
        {
            label: "Remark",
            name: "Remarks__c",
            editable: true
        }
    ];
}