/**
 * @description       :
 * @author            : shkang@trestle.co.kr
 * @last modified on  : 2026-04-24
 * @last modified by  : Akrom Saidkamolov
 **/
import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

import apexGetBaseBankTransaction from "@salesforce/apex/REC_BTBasedReconCtrl.getBaseBankTransaction";
import apexInquirySettlementLineItems from "@salesforce/apex/REC_BTBasedReconCtrl.inquirySettlementLineItems";
import apexGetSliIdsAlreadyReconciled from "@salesforce/apex/REC_BTBasedReconCtrl.getSliIdsAlreadyReconciled";
import apexGetRelatedReconciliationLineItems from "@salesforce/apex/REC_BTBasedReconCtrl.getRelatedReconciliationLineItems";
import apexDraftBankTransactionBased from "@salesforce/apex/REC_BTBasedReconCtrl.draftBankTransactionBased";
import apexConfirmBankTransactionBased from "@salesforce/apex/REC_BTBasedReconCtrl.confirmBankTransactionBased";
import apexGetReconciliationStatus from "@salesforce/apex/REC_BTBasedReconCtrl.getReconciliationStatus";
import apexGetPcOtherChargesRlis from "@salesforce/apex/REC_BTBasedReconCtrl.getPcOtherChargesRlis";
import apexValidateSli from "@salesforce/apex/REC_BTBasedReconCtrl.validateSettlementLineItems";
import apexInquiryNotes from "@salesforce/apex/REC_BTBasedReconCtrl.inquiryNotes";
import apexGetRelatedSlis from "@salesforce/apex/REC_BTBasedReconCtrl.getRelatedSlis";
import apexGetOptionsByIds from "@salesforce/apex/REC_Lookup_Ctrl.getOptionsByIds";

import ExchangeRatePopup from "./exchangeRatePopup/exchangeRatePopup";
import RecSettlementLineItemConfirmModal from "c/recSettlementLineItemConfirmModal";
import apexConfirmSliStatus from "@salesforce/apex/REC_SLIInquiryCtrl.confirmSliStatus";
import { roundByCurrency } from "c/recUtils";

const STATUS = { CONFIRMED: "Confirmed", CLEAR: "Clear", PARTIAL: "Partial" };

export default class RecBankTransactionBased extends LightningElement {
    @api recordId;

    // ── Table Data ───────────────────────────────────────────────────────
    @track baseBtData = [];
    @track sliData = [];
    @track noteData = [];
    @track selectedItems = [];
    @track otherChargesData = [];

    // ── Table State ──────────────────────────────────────────────────────
    _isLoading = false;
    _activeTab = "sli";
    _selectedCount = 0;
    _noteSelectedCount = 0;
    _selectedItemSelectedCount = 0;
    _otherChargesSelectedCount = 0;
    _tempIdCounter = 0;
    _otherChargesTempId = 0;
    _reconciliationStatus = null;
    _noteIdsWithNoSlis = [];

    // ── Lifecycle ────────────────────────────────────────────────────────

    connectedCallback() {
        this.getBaseBankTransaction();
        this.getRelatedReconciliationLineItems();
        this.getOtherCharges();
        this.getReconciliationStatus();
    }

    // ── Computed Properties ──────────────────────────────────────────────

    get baseCurrency() {
        const rli = this.baseBtData?.[0];
        return rli?.RefBankTransaction__r?.Currency__c || null;
    }

    get baseTransactionDate() {
        const rli = this.baseBtData?.[0];
        return rli?.RefBankTransaction__r?.TransactionDate__c || null;
    }

    get baseBizRegion() {
        const rli = this.baseBtData?.[0];
        return rli?.RefBankTransaction__r?.BizRegion__c || null;
    }

    get baseBankTransactionId() {
        const rli = this.baseBtData?.[0];
        return rli?.RefBankTransaction__c || null;
    }

    get displayOtherChargesRowCount() {
        return this.otherChargesData?.length || 0;
    }

    get displayOtherChargesSelectedCount() {
        return this._otherChargesSelectedCount;
    }

    get otherChargesTotalAmount() {
        const raw = this.otherChargesData.reduce((sum, item) => sum + (item.OriginAmount__c || 0), 0);
        return roundByCurrency(raw, this.baseCurrency);
    }

    get displayRowCount() {
        return this.sliData?.length || 0;
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

    get displaySettlementCurrency() {
        return this.baseCurrency || "N/A";
    }

    get sliDisabledRowIds() {
        if (this.isConfirmed) return this.sliData.map((r) => r.Id);

        const alreadySelectedIds = this.selectedItems.map((r) => r.RefSettlementLineItem__c).filter(Boolean);

        // Available SLI 중 SettlementCurrency가 Base BT Currency와 다르면 비활성화
        const ccy = this.baseCurrency;
        let currencyMismatchIds = [];
        if (ccy && this.sliData?.length) {
            currencyMismatchIds = this.sliData
                .filter((r) => r.SettlementStatus__c === "Available" && r.SettlementCurrency__c !== ccy)
                .map((r) => r.Id);
        }

        return [...new Set([...alreadySelectedIds, ...currencyMismatchIds])];
    }

    get displayNoteRowCount() {
        return this.noteData?.length || 0;
    }

    get displayNoteSelectedCount() {
        return this._noteSelectedCount;
    }

    get noteDisabledRowIds() {
        if (this.isConfirmed) return this.noteData.map((r) => r.Id);

        const alreadySelected = this.selectedItems.map((r) => r.RefSettlementLineItem__r?.Note_lk__c).filter(Boolean);
        return [...new Set([...alreadySelected])];
    }

    get reconciledAmount() {
        const raw = this.selectedItems.reduce((sum, item) => sum + (item.SettlementAmountTTL__c || 0), 0);
        return roundByCurrency(raw, this.baseCurrency);
    }

    get isConfirmed() {
        return this._reconciliationStatus === STATUS.CONFIRMED;
    }

    get draftBtnDisabled() {
        return this.isConfirmed;
    }

    get confirmBtnDisabled() {
        if (this.isConfirmed) return true;
        if (!this.selectedItems?.length) return true;
        return false;
    }

    get actionBtnsDisabled() {
        return this.isConfirmed;
    }

    get selectedItemDisabledRowIds() {
        if (!this.isConfirmed) return [];
        return this.selectedItems.map((r) => r.Id);
    }

    get otherChargesDisabledRowIds() {
        if (!this.isConfirmed) return [];
        return this.otherChargesData.map((r) => r.Id);
    }

    // ── Status Loading ─────────────────────────────────────────────────

    async getReconciliationStatus() {
        try {
            this._reconciliationStatus = await apexGetReconciliationStatus({ reconciliationId: this.recordId });
        } catch (error) {
            console.error("Failed to load Reconciliation status:", error);
        }
    }

    // ── Other Charges Data Loading ───────────────────────────────────────

    async getOtherCharges() {
        try {
            const rows = await apexGetPcOtherChargesRlis({ reconciliationId: this.recordId });
            const ccy = this.baseCurrency;
            this.otherChargesData = (rows || []).map((row) => ({ ...row, BTCurrency__c: ccy }));
        } catch (error) {
            console.error("Failed to load Other Charges:", error);
        }
    }

    // ── Data Loading ─────────────────────────────────────────────────────

    async getBaseBankTransaction() {
        try {
            const rli = await apexGetBaseBankTransaction({ reconId: this.recordId });

            rli.NetAmountAfterClearing__c =
                rli.NetAmountAfterClearing__c || rli.RefBankTransaction__r.NetBalanceAftCleared__c;

            this.baseBtData = rli ? [rli] : [];

            const accountId = rli?.RefBankTransaction__r?.AccountName__c;
            if (accountId) {
                this._sliFilterFieldDefs = this._sliFilterFieldDefs.map((def) =>
                    def.name === "AccountName__c" ? { ...def, defaultValue: accountId } : def
                );
                this.noteFilterDefs = this.noteFilterDefs.map((def) =>
                    def.name === "Account_lk__c" ? { ...def, defaultValue: accountId } : def
                );
            }
        } catch (error) {
            console.error("Failed to load Base Bank Transaction:", error);
        }
    }

    async getRelatedReconciliationLineItems() {
        try {
            const rlis = await apexGetRelatedReconciliationLineItems({ reconciliationId: this.recordId });
            this.selectedItems = rlis || [];
        } catch (error) {
            console.error("Failed to load Reconciliation Line Items:", error);
        }
    }

    // ── Private Helpers ──────────────────────────────────────────────────

    /**
     * 공통 Inquiry: filterRef에서 값을 읽어 apexFn 호출 후, 결과를 콜백으로 전달.
     */
    _inquiry(filterRef, apexFn, columns, onResult) {
        if (!filterRef.validate()) return;

        const values = filterRef.getValues();
        const columnFields = this._extractColumnFields(columns);

        this._isLoading = true;
        apexFn({
            filters: JSON.stringify(values),
            relFields: columnFields.length ? JSON.stringify(columnFields) : null
        })
            .then((result) => onResult(result || []))
            .catch((error) => {
                console.error("Inquiry error:", error);
                this.showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
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

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // ── Tab Handler ──────────────────────────────────────────────────────

    handleTabChange(event) {
        this._activeTab = event.target.value;
    }

    _noteFilterRef() {
        return this.refs.noteFilter || this.template.querySelector("c-rec-filter-bar[data-id='noteFilter']");
    }

    // ── SLI Event Handlers ───────────────────────────────────────────────

    async handleSliInquiryClick() {
        const filterRef = this.refs.sliFilter;
        if (!filterRef.validate()) return;

        const values = filterRef.getValues();
        const columnFields = this._extractColumnFields(this.sliColumns);

        this._isLoading = true;
        try {
            const result = await apexInquirySettlementLineItems({
                filters: JSON.stringify(values),
                relFields: columnFields.length ? JSON.stringify(columnFields) : null
            });

            let data = result || [];

            if (data.length) {
                const reconciledIds = await apexGetSliIdsAlreadyReconciled({
                    sliIds: data.map((r) => r.Id),
                    reconciliationId: this.recordId
                });
                if (reconciledIds?.length) {
                    const reconciledSet = new Set(reconciledIds);
                    data = data.filter((r) => !reconciledSet.has(r.Id));
                }
            }

            this.sliData = data;
            this._selectedCount = 0;
        } catch (error) {
            console.error("Inquiry error:", error);
            this.showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
            this.sliData = [];
            this._selectedCount = 0;
        } finally {
            this._isLoading = false;
        }
    }

    handleSliResetClick() {
        this.refs.sliFilter.reset();
    }

    handleSliRowSelection(event) {
        this._selectedCount = event.detail.selectedRows.length;
    }

    handleSliCellChange(event) {
        const { rowId, fieldName, value, oldValue } = event.detail;
        console.log(`Cell changed — row:${rowId} field:${fieldName} ${oldValue} → ${value}`);
    }

    handleSliGroupCollapse(event) {
        const { groupName, collapsed } = event.detail;
        console.log(`Group "${groupName}" ${collapsed ? "collapsed" : "expanded"}`);
    }

    handleSliExpandAllClick() {
        this.refs.sliTable.expandAll();
    }

    handleSliCollapseAllClick() {
        this.refs.sliTable.collapseAll();
    }

    get sliConfirmBtnDisabled() {
        return this._selectedCount < 1 || this.isConfirmed;
    }

    async handleSliConfirmClick() {
        const selectedRows = this.refs.sliTable.getSelectedRows() || [];

        if (selectedRows.length === 0) {
            this.showToast("No rows selected", "Please select at least one row to confirm.", "warning");
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
                await this._refreshSliTable();
            }
        } catch (error) {
            console.error("Confirm error:", error);
            this.showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    async handleSliSelect() {
        const selectedRows = this.refs.sliTable.getSelectedRows();
        if (!selectedRows.length) return;

        // 이미 selected된 SLI는 제외 (RefSettlementLineItem__c 기준)
        const alreadySelectedSliIds = new Set(this.selectedItems.map((r) => r.RefSettlementLineItem__c));
        const newRows = selectedRows.filter((r) => !alreadySelectedSliIds.has(r.Id));
        if (!newRows.length) return;

        // SettlementStatus__c 기준으로 분류
        const notAvailableRows = newRows.filter((r) => r.SettlementStatus__c === "Not-Available");
        const directRows = newRows.filter((r) => r.SettlementStatus__c !== "Not-Available");

        // 직접 추가 가능한 row → FX Rate 는 기존 SLI 값 또는 동일통화면 1
        const directRliRows = directRows.map((sli) => {
            const fxRate = sli.FXRateOrigintoSettlement__c || (sli.OriginCurrency__c === this.baseCurrency ? 1 : 0);
            return this._createRliFromSli(sli, fxRate);
        });

        let popupRliRows = [];

        // Not-Available row만 FX Rate Popup 진행
        if (notAvailableRows.length) {
            const settlements = notAvailableRows.reduce((acc, item) => {
                const existingItem = acc.find((i) => i.OriginCurrency__c === item.OriginCurrency__c);
                if (existingItem) {
                    existingItem.OriginAmount__c += item.OriginAmount__c;
                } else {
                    acc.push({
                        ...item,
                        fxRate: item.OriginCurrency__c === this.baseCurrency ? 1 : 0
                    });
                }
                return acc;
            }, []);

            const fxRates = await ExchangeRatePopup.open({
                label: "FX Rate Popup",
                baseCurrency: this.baseCurrency,
                settlements
            });

            if (!fxRates) {
                // Popup 취소 시에도 directRows는 추가
                if (!directRliRows.length) return;
                this.selectedItems = [...this.selectedItems, ...directRliRows];
                await this._executeDraft(this.selectedItems);
                return;
            }

            popupRliRows = notAvailableRows.map((sli) => this._createRliFromSli(sli, fxRates[sli.OriginCurrency__c]));
        }

        // 기존 + 직접추가 + 팝업결과 합산 후, Draft 실행
        const allNewRliRows = [...directRliRows, ...popupRliRows];
        if (!allNewRliRows.length) return;

        this.selectedItems = [...this.selectedItems, ...allNewRliRows];
        this.refs.sliTable.clearSelection();
        this._selectedCount = 0;

        await this._executeDraft(this.selectedItems);
    }

    // ── Note Event Handlers ──────────────────────────────────────────────

    async handleNoteInquiryClick() {
        if (!this._noteFilterRef().validate()) return;

        const values = this._noteFilterRef().getValues();

        this._isLoading = true;
        try {
            const notes = await apexInquiryNotes({ filters: JSON.stringify(values), relFields: null });
            this.noteData = notes || [];
            this._noteSelectedCount = 0;
            this._noteIdsWithNoSlis = this.noteData.filter((n) => !n.SettlementLineItemsByNote__r?.length).map((n) => n.Id);
        } catch (error) {
            console.error("Note inquiry error:", error);
            this.showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
            this.noteData = [];
            this._noteIdsWithNoSlis = [];
        } finally {
            this._isLoading = false;
        }
    }

    handleNoteResetClick() {
        this._noteFilterRef().reset();
    }

    handleNoteRowSelection(event) {
        this._noteSelectedCount = event.detail.selectedRows.length;
    }

    handleNoteExpandAllClick() {
        this.refs.noteTable?.expandAll();
    }

    handleNoteCollapseAllClick() {
        this.refs.noteTable?.collapseAll();
    }

    get noteConfirmBtnDisabled() {
        return this._noteSelectedCount < 1 || this.isConfirmed;
    }

    async handleNoteConfirmClick() {
        const selectedRows = this.refs.noteTable?.getSelectedRows() || [];

        if (selectedRows.length === 0) {
            this.showToast("No rows selected", "Please select at least one row to confirm.", "warning");
            return;
        }

        const sliIds = selectedRows.flatMap((note) => (note.SettlementLineItemsByNote__r || []).map((sli) => sli.Id));

        if (sliIds.length === 0) {
            this.showToast("No SLIs found", "Selected notes have no related Settlement Line Items.", "warning");
            return;
        }

        try {
            this._isLoading = true;
            const result = await apexConfirmSliStatus({ sliIds });

            await RecSettlementLineItemConfirmModal.open({
                size: "small",
                total: result.total,
                confirmCount: result.confirmCount,
                errorCount: result.errorCount
            });

            if (result.confirmCount > 0) {
                await this._refreshNoteTable();
            }
        } catch (error) {
            console.error("Note Confirm error:", error);
            this.showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    async handleNoteSelect() {
        const selectedRows = this.refs.noteTable?.getSelectedRows() || [];
        if (!selectedRows.length) return;

        const noteIds = selectedRows.map((r) => r.Id);

        this._isLoading = true;
        try {
            let incomingSlis = (await apexGetRelatedSlis({ noteIds })) || [];
            if (!incomingSlis.length) {
                this.showToast("Info", "No related SLIs found for the selected Notes.", "info");
                return;
            }

            // Exclude: (Available AND currency mismatch) OR already reconciled OR Clear
            const ccy = this.baseCurrency;
            incomingSlis = incomingSlis.filter(
                (r) =>
                    r.SettlementStatus__c !== "Clear" &&
                    !(r.SettlementStatus__c === "Available" && ccy && r.SettlementCurrency__c !== ccy)
            );

            // Filter out already reconciled SLIs
            const reconciledIds = await apexGetSliIdsAlreadyReconciled({
                sliIds: incomingSlis.map((r) => r.Id),
                reconciliationId: this.recordId
            });
            if (reconciledIds?.length) {
                const reconciledSet = new Set(reconciledIds);
                incomingSlis = incomingSlis.filter((r) => !reconciledSet.has(r.Id));
            }

            // Filter out already selected SLIs
            const alreadySelectedSliIds = new Set(this.selectedItems.map((r) => r.RefSettlementLineItem__c));
            const newRows = incomingSlis.filter((r) => !alreadySelectedSliIds.has(r.Id));
            if (!newRows.length) {
                this.showToast("Info", "All related SLIs are already selected or reconciled.", "info");
                return;
            }

            // Classify by SettlementStatus__c (same logic as SLI select)
            const notAvailableRows = newRows.filter((r) => r.SettlementStatus__c === "Not-Available");
            const directRows = newRows.filter((r) => r.SettlementStatus__c !== "Not-Available");

            const directRliRows = directRows.map((sli) => {
                const fxRate = sli.FXRateOrigintoSettlement__c || (sli.OriginCurrency__c === this.baseCurrency ? 1 : 0);
                return this._createRliFromSli(sli, fxRate);
            });

            let popupRliRows = [];

            if (notAvailableRows.length) {
                const settlements = notAvailableRows.reduce((acc, item) => {
                    const existingItem = acc.find((i) => i.OriginCurrency__c === item.OriginCurrency__c);
                    if (existingItem) {
                        existingItem.OriginAmount__c += item.OriginAmount__c;
                    } else {
                        acc.push({
                            ...item,
                            fxRate: item.OriginCurrency__c === this.baseCurrency ? 1 : 0
                        });
                    }
                    return acc;
                }, []);

                const fxRates = await ExchangeRatePopup.open({
                    label: "FX Rate Popup",
                    baseCurrency: this.baseCurrency,
                    settlements
                });

                if (!fxRates) {
                    if (!directRliRows.length) return;
                    this.selectedItems = [...this.selectedItems, ...directRliRows];
                    await this._executeDraft(this.selectedItems);
                    return;
                }

                popupRliRows = notAvailableRows.map((sli) => this._createRliFromSli(sli, fxRates[sli.OriginCurrency__c]));
            }

            const allNewRliRows = [...directRliRows, ...popupRliRows];
            if (!allNewRliRows.length) return;

            this.selectedItems = [...this.selectedItems, ...allNewRliRows];
            this.refs.noteTable?.clearSelection();
            this._noteSelectedCount = 0;

            await this._executeDraft(this.selectedItems);
        } catch (error) {
            console.error("Note select error:", error);
            this.showToast("Error", error.body?.message || error?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    // ── RLI Builder ──────────────────────────────────────────────────────

    /**
     * Create a ReconciliationLineItem-shaped object from a SettlementLineItem.
     */
    _createRliFromSli(sli, fxRate) {
        const fxRateVal = fxRate || sli.FXRateOrigintoSettlement__c || 0;
        const originAmt = sli.OriginAmount__c || 0;
        const otherCharges = sli.OtherCharges__c || 0;
        const ccy = sli.SettlementCurrency__c;
        const settlementAmtSli = roundByCurrency(originAmt * fxRateVal, ccy);

        return {
            Id: `_temp_${this._tempIdCounter++}_${sli.Id}`,
            RefSettlementLineItem__c: sli.Id,
            RefSettlementLineItem__r: { ...sli },
            BizRegion__c: sli.BizRegion__c,
            SettlementDate__c: sli.SettlementDate__c,
            SettlementCurrency__c: ccy,
            FXRateOrigintoSettlement__c: fxRateVal,
            SettlementAmountSLI__c: settlementAmtSli,
            OtherCharges__c: otherCharges,
            SettlementAmountTTL__c: roundByCurrency(settlementAmtSli + otherCharges, ccy),
            SettlementType__c: sli.SettlementType__c,
            RemittanceOnHold__c: sli.RemittanceOnHold__c || false,
            HoldReason__c: sli.HoldReason__c || null,
            ExchangeDate__c: sli.ExchangeDate__c || null,
            ExchangeCurrency__c: sli.ExchangeCurrency__c || null,
            ExchangeAmount__c: sli.ExchangeAmount__c || null,
            ExchangeRate__c: sli.ExchangeRate__c || null
        };
    }

    // ── Selected Items Event Handlers ────────────────────────────────────

    handleSelectedItemRowSelection(event) {
        this._selectedItemSelectedCount = event.detail.selectedRows.length;
    }

    async handleSelectedItemCellChange(event) {
        const { rowId, fieldName, value } = event.detail;
        this.selectedItems = this.selectedItems.map((item) => {
            if (String(item.Id) === String(rowId)) {
                return { ...item, [fieldName]: value };
            }
            return item;
        });

        if (fieldName === "SettlementType__c") {
            await this._validateSettlementType(rowId, value);
        }
    }

    async _validateSettlementType(rowId, value) {
        if (!value) {
            this.refs.selectedTable?.setCellErrors([]);
            return;
        }

        const item = this.selectedItems.find((r) => String(r.Id) === String(rowId));
        if (!item) return;

        const sli = item.RefSettlementLineItem__r || {};
        const record = {
            Id: item.RefSettlementLineItem__c,
            SettlementType__c: value,
            OriginAmount__c: sli.OriginAmount__c,
            SettlementStatus__c: sli.SettlementStatus__c
        };

        try {
            const errors = await apexValidateSli({ records: [record] });
            if (errors && errors.length > 0) {
                this.selectedItems = this.selectedItems.map((r) => {
                    if (String(r.Id) === String(rowId)) {
                        return { ...r, SettlementType__c: null };
                    }
                    return r;
                });
                this._applyCellErrors(errors, this.selectedItems);
            } else {
                this.refs.selectedTable?.setCellErrors([]);
            }
        } catch (error) {
            console.error("Validation error:", error);
            this.showToast("Error", error.body?.message || "Validation failed.", "error");
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

    handleOtherChargesAdd() {
        const ccy = this.baseCurrency;
        const newRow = {
            Id: `_oc_temp_${this._otherChargesTempId++}`,
            BTCurrency__c: ccy || null,
            ClosingType__c: "P_C",
            RefBankTransaction__c: this.baseBankTransactionId || null,
            RefSettlementLineItem__c: this.selectedItems[0]?.RefSettlementLineItem__c || null
        };
        this.otherChargesData = [...this.otherChargesData, newRow];
    }

    async handleSelectedItemDelete() {
        const selected = this.refs.selectedTable.getSelectedRows();
        if (!selected.length) return;
        const removeIds = new Set(selected.map((r) => r.Id));
        this.selectedItems = this.selectedItems.filter((r) => !removeIds.has(r.Id));
        this._selectedItemSelectedCount = 0;

        // Delete 후 Draft 실행하여 Base BT RLI 갱신
        await this._executeDraft(this.selectedItems);
    }

    // ── Draft / Confirm Handlers ────────────────────────────────────────

    async handleDraft() {
        if (this.draftBtnDisabled) return;
        await this._executeDraft();
    }

    async handleConfirm() {
        if (this.confirmBtnDisabled) return;
        await this._executeConfirm();
    }

    // ── Draft Execution ──────────────────────────────────────────────────

    /**
     * Collects RLI detail records from selectedItems and calls the Apex draft method.
     * After draft, refreshes Base BT table and Selected Items table.
     *
     * @param {Object[]} [selectedItemsOverride] — When the caller has just mutated
     *   this.selectedItems, the child c-rec-table hasn't re-rendered yet, so
     *   getData() would return stale rows.  Pass the fresh array here to
     *   bypass the child read.
     */
    async _executeDraft(selectedItemsOverride) {
        // Read the latest data from the table (includes pending edits from _rowEditMap).
        // If an override is supplied (caller just updated selectedItems but the
        // child table hasn't received the new @api data yet), use it instead.
        const latestData = selectedItemsOverride || this.refs.selectedTable?.getData() || this.selectedItems;
        const details = latestData.map((item) => {
            const d = {
                RefSettlementLineItem__c: item.RefSettlementLineItem__c,
                FXRateOrigintoSettlement__c: item.FXRateOrigintoSettlement__c,
                OtherCharges__c: item.OtherCharges__c,
                SettlementType__c: item.SettlementType__c,
                RemittanceOnHold__c: item.RemittanceOnHold__c,
                HoldReason__c: item.HoldReason__c,
                ExchangeDate__c: item.ExchangeDate__c,
                ExchangeCurrency__c: item.ExchangeCurrency__c,
                ExchangeAmount__c: item.ExchangeAmount__c,
                ExchangeRate__c: item.ExchangeRate__c
            };
            if (item.Id && !String(item.Id).startsWith("_temp")) {
                d.Id = item.Id;
            }
            return d;
        });

        this._isLoading = true;
        try {
            // Clear previous validation errors
            this.refs.selectedTable?.setCellErrors([]);

            // Collect P_C Other Charges RLI items
            // NOTE: use state directly; otherChargesTable.getData() can return []
            // while record-picker (COA) lookup hydration is in flight.
            const otherChargesTableData = this.otherChargesData;
            const otherChargeRliItems = otherChargesTableData.map((item) => {
                const d = {
                    ClosingType__c: "P_C",
                    COA_lk__c: item.COA_lk__c,
                    OriginAmount__c: item.OriginAmount__c,
                    BTCurrency__c: item.BTCurrency__c,
                    RefSettlementLineItem__c: item.RefSettlementLineItem__c,
                    RefBankTransaction__c: item.RefBankTransaction__c,
                    Remarks__c: item.Remarks__c
                };
                if (item.Id && !String(item.Id).startsWith("_oc_temp")) d.Id = item.Id;
                return d;
            });

            const result = await apexDraftBankTransactionBased({
                reconciliationId: this.recordId,
                details,
                otherChargeRliItems
            });

            if (!result.success) {
                this._applyCellErrors(result.cellErrors, latestData);
                return;
            }

            if (result.message) {
                this.showToast("Warning", result.message, "warning");
            } else {
                this.showToast("Success", "Draft saved successfully.", "success");
            }
            await this._refreshAfterDraft();
        } catch (error) {
            console.error("Draft error:", error);
            this.showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    /**
     * Refreshes Base BT and Selected Items tables after draft.
     * Does NOT refresh the SLI inquiry table.
     */
    async _refreshAfterDraft() {
        await Promise.all([this.getBaseBankTransaction(), this.getRelatedReconciliationLineItems(), this.getOtherCharges()]);
    }

    /**
     * Re-fetches SLI table data using the current filter values.
     * Row selection is preserved (recTable keeps _selectedRowIds across data updates).
     */
    async _refreshSliTable() {
        const filterRef = this.refs.sliFilter;
        if (!filterRef) return;

        const values = filterRef.getValues();
        const columnFields = this._extractColumnFields(this.sliColumns);

        try {
            const result = await apexInquirySettlementLineItems({
                filters: JSON.stringify(values),
                relFields: columnFields.length ? JSON.stringify(columnFields) : null
            });

            let data = result || [];

            if (data.length) {
                const reconciledIds = await apexGetSliIdsAlreadyReconciled({
                    sliIds: data.map((r) => r.Id),
                    reconciliationId: this.recordId
                });
                if (reconciledIds?.length) {
                    const reconciledSet = new Set(reconciledIds);
                    data = data.filter((r) => !reconciledSet.has(r.Id));
                }
            }

            this.sliData = data;
        } catch (error) {
            console.error("SLI refresh error:", error);
        }
    }

    /**
     * Re-fetches Note table data using the current filter values.
     * Row selection is preserved.
     */
    async _refreshNoteTable() {
        const filterRef = this._noteFilterRef();
        if (!filterRef) return;

        const values = filterRef.getValues();

        try {
            const notes = await apexInquiryNotes({ filters: JSON.stringify(values), relFields: null });
            this.noteData = notes || [];
            this._noteIdsWithNoSlis = this.noteData.filter((n) => !n.SettlementLineItemsByNote__r?.length).map((n) => n.Id);
        } catch (error) {
            console.error("Note refresh error:", error);
        }
    }

    // ── Confirm Execution ────────────────────────────────────────────────

    /**
     * Collects RLI detail records + Other Charges from tables, calls the Apex confirm method.
     * After confirm, refreshes all tables and sets status to Confirmed.
     */
    async _executeConfirm() {
        const latestData = this.refs.selectedTable?.getData() || this.selectedItems;
        const details = latestData.map((item) => {
            const d = {
                RefSettlementLineItem__c: item.RefSettlementLineItem__c,
                FXRateOrigintoSettlement__c: item.FXRateOrigintoSettlement__c,
                OtherCharges__c: item.OtherCharges__c,
                SettlementType__c: item.SettlementType__c,
                RemittanceOnHold__c: item.RemittanceOnHold__c,
                HoldReason__c: item.HoldReason__c,
                ExchangeDate__c: item.ExchangeDate__c,
                ExchangeCurrency__c: item.ExchangeCurrency__c,
                ExchangeAmount__c: item.ExchangeAmount__c,
                ExchangeRate__c: item.ExchangeRate__c
            };
            if (item.Id && !String(item.Id).startsWith("_temp")) {
                d.Id = item.Id;
            }
            return d;
        });

        // Collect Other Charges data (P_C SLIs — only applied at Confirm)
        // See draft handler for why state is used instead of getData().
        const otherChargesTableData = this.otherChargesData;
        const otherChargeItems = otherChargesTableData.map((item) => ({
            ClosingType__c: "P_C",
            OriginCurrency__c: item.BTCurrency__c,
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
                BTCurrency__c: item.BTCurrency__c,
                RefSettlementLineItem__c: item.RefSettlementLineItem__c,
                RefBankTransaction__c: item.RefBankTransaction__c,
                Remarks__c: item.Remarks__c
            };
            if (item.Id && !String(item.Id).startsWith("_oc_temp")) d.Id = item.Id;
            return d;
        });

        this._isLoading = true;
        try {
            // Clear previous validation errors
            this.refs.selectedTable?.setCellErrors([]);

            const result = await apexConfirmBankTransactionBased({
                reconciliationId: this.recordId,
                details,
                otherChargeItems,
                otherChargeRliItems
            });

            if (!result.success) {
                this._applyCellErrors(result.cellErrors, latestData);
                return;
            }

            if (result.message) {
                // Validation warning — fell back to Draft
                this.showToast("Warning", result.message, "warning");
                await this._refreshAfterDraft();
                return;
            }

            this.showToast("Success", "Reconciliation confirmed successfully.", "success");

            // Update status locally (avoids cacheable stale read)
            this._reconciliationStatus = STATUS.CONFIRMED;

            // Refresh: reload base BT, selected items, other charges; clear inquiry tables
            await this._refreshAfterConfirm();
        } catch (error) {
            console.error("Confirm error:", error);
            this.showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    /**
     * Refreshes all tables after confirm.
     * Clears SLI inquiry data and reloads Other Charges from DB.
     */
    async _refreshAfterConfirm() {
        this.sliData = [];
        this.noteData = [];
        this._selectedCount = 0;
        this._noteSelectedCount = 0;
        this._noteIdsWithNoSlis = [];
        await Promise.all([this.getBaseBankTransaction(), this.getRelatedReconciliationLineItems(), this.getOtherCharges()]);
    }

    /**
     * Maps SLI-Id-based cell errors from Apex to row-Id-based errors
     * that recTable can locate, then highlights the failing cells.
     *
     * @param {Array<{rowId: string, fieldName: string, message: string}>} cellErrors
     * @param {Object[]} latestData — selectedItems snapshot used for SLI→rowId mapping
     */
    _applyCellErrors(cellErrors, latestData) {
        if (!cellErrors?.length) return;

        // Build SLI Id → table row Id map
        const sliToRowId = {};
        for (const item of latestData) {
            if (item.RefSettlementLineItem__c) {
                sliToRowId[item.RefSettlementLineItem__c] = String(item.Id);
            }
        }

        const mappedErrors = cellErrors.map((err) => ({
            ...err,
            rowId: sliToRowId[err.rowId] || err.rowId
        }));

        this.refs.selectedTable?.setCellErrors(mappedErrors);

        // Show summary toast
        const messages = cellErrors.map((e) => e.message);
        const uniqueMessages = [...new Set(messages)];
        this.showToast("Validation Error", uniqueMessages.join("\n"), "error");
    }

    // ── Column & Filter Definitions (labels loaded from Schema) ─────────

    _baseBtColumnDefs = [
        {
            label: "Trans. No.",
            name: "RefBankTransaction__r.Name",
            type: "url",
            config: { idField: "RefBankTransaction__c", objectApiName: "BankTransaction__c" }
        },
        { label: "Transaction Date", name: "RefBankTransaction__r.TransactionDate__c", type: "date" },
        { label: "Settlement Currency", name: "RefBankTransaction__r.Currency__c" },
        {
            label: "Origin Amount",
            name: "RefBankTransaction__r.OriginAmount__c",
            type: "currency",
            config: { ccyField: "RefBankTransaction__r.Currency__c" }
        },
        { label: "Depositor", name: "RefBankTransaction__r.Depositor__c" },
        {
            label: "Account Name",
            name: "RefBankTransaction__r.AccountName__c",
            type: "record-picker",
            align: "left",
            disabled: true,
            config: { objectApiName: "Account", labelField: "Name" }
        },
        {
            label: "Reconciled AMT",
            name: "TotalClearedAmount__c",
            type: "currency",
            config: { ccyField: "RefBankTransaction__r.Currency__c" }
        },
        {
            label: "Not-Reconciled AMT",
            name: "NetAmountAfterClearing__c",
            type: "currency",
            config: { ccyField: "RefBankTransaction__r.Currency__c" }
        },
        { label: "Remarks", name: "RefBankTransaction__r.Remarks__c" }
    ];

    get baseBtColumns() {
        return this._baseBtColumnDefs;
    }

    _sliFilterFieldDefs = [
        // ── Row 1 ──────────────────────────────────────────────────────────────
        {
            label: "Settlement Status",
            name: "SettlementStatus__c",
            type: "combobox",
            required: true,
            size: 3,
            config: { multiple: true, picklistObject: "SettlementLineItem__c", picklistField: "SettlementStatus__c" }
        },
        {
            label: "Account Name",
            name: "AccountName__c",
            type: "lookup",
            align: "left",
            size: 3,
            config: { objectApiName: "Account", labelField: "Name", placeholder: "Search Account..." }
        },
        { blank: true, size: 6 },
        // ── Row 2 ──────────────────────────────────────────────────────────────
        { label: "Debit/Credit No.", name: "PremiumNoteNo_fm__c", type: "like", size: 3 },
        {
            label: "Facility Name",
            name: "FacilityName__c",
            type: "lookup",
            size: 3,
            config: { objectApiName: "COM_Facility__c", labelField: "Name", placeholder: "Search Facility..." }
        },
        {
            label: "Facility BDX Period",
            name: "FacilityBDXPeriod",
            type: "date-between",
            size: 3,
            config: { fromField: "FacilityBDXPeriodFrom__c", toField: "FacilityBDXPeriodTo__c" }
        },
        {
            label: "Closing Type",
            name: "ClosingType__c",
            type: "combobox",
            size: 3,
            config: { multiple: true, picklistObject: "SettlementLineItem__c", picklistField: "ClosingType__c" }
        },
        // ── Row 3 ──────────────────────────────────────────────────────────────
        { label: "LK Ref. No.", name: "LKRefNoReins_fm__c", type: "text", size: 3 },
        {
            label: "Placement No.",
            name: "RefReinsurance__c",
            type: "lookup",
            size: 3,
            config: { objectApiName: "Placement__c", labelField: "Name", placeholder: "Search Placement..." }
        },
        {
            label: "Insured",
            name: "Insured_fm__c",
            type: "like",
            size: 3
        },
        { label: "Inception Date", name: "InceptionDate__c", type: "date", size: 3 },
        // ── Row 4 ──────────────────────────────────────────────────────────────
        { label: "No of Installment", name: "InstallmentNo__c", type: "number", size: 3 },
        { label: "PPW Date", name: "PPWDate__c", type: "date-range", size: 3 },
        { label: "Date of Loss", name: "RefClaim__r.LossDate__c", type: "date", size: 3 },
        { label: "SOC Seq.", name: "SOCSeq__c", type: "text", size: 3 },
        // ── Row 5 ──────────────────────────────────────────────────────────────
        {
            label: "SOA No.",
            name: "Note_lk__r.SOA_lk__c",
            type: "lookup",
            size: 3,
            config: { objectApiName: "SOA_Statement__c", labelField: "Name", placeholder: "Search SOA..." }
        },
        {
            label: "Outward Funds",
            name: "OutwardFunds_lk__c",
            type: "lookup",
            size: 3,
            config: { objectApiName: "OutwardFund__c", labelField: "Name", placeholder: "Search Outward Funds..." }
        },
        {
            label: "STC Status",
            name: "Status__c",
            type: "combobox",
            defaultValue: "Confirm",
            size: 3,
            config: {
                picklistObject: "SettlementLineItem__c",
                picklistField: "Status__c"
            }
        },
        {
            label: "Claim No.",
            name: "RefClaim__c",
            type: "lookup",
            size: 3,
            config: { objectApiName: "Claim", labelField: "Name", placeholder: "Search Claim..." }
        }
    ];

    get sliFilterDefs() {
        return this._sliFilterFieldDefs;
    }

    _sliColumnDefs = [
        {
            //label: "SLI No.",
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
                    //label: "Closing Type",
                    name: "ClosingType__c"
                },
                {
                    label: "COA",
                    name: "COA_lk__c",
                    type: "record-picker",
                    disabled: true,
                    collapsible: true,
                    config: { objectApiName: "COA__c", labelField: "Name", placeholder: "Search COA..." }
                },
                { label: "COA Name", name: "COAName_fm__c", collapsible: true },
                {
                    //label: "Account Name",
                    name: "AccountName__c",
                    type: "record-picker",
                    align: "left",
                    disabled: true,
                    config: { objectApiName: "Account", labelField: "Name" }
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
                { label: "LK Ref No", name: "LKRefNoPolicy_fm__c", type: "element" },
                { label: "Cedant Ref No", name: "CedantRefNo__c", collapsible: true },
                {
                    label: "Cedant Facility Name",
                    name: "CedantFacilityName__c",
                    type: "record-picker",
                    disabled: true,
                    config: { objectApiName: "COM_Facility__c", labelField: "Name", placeholder: "Search Facility..." },
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
                    label: "Layer",
                    name: "Layer__c",
                    type: "record-picker",
                    disabled: true,
                    config: { objectApiName: "OPP_Layer__c", labelField: "Name", placeholder: "Search Layer..." }
                },
                {
                    label: "Reinsurer",
                    name: "Reinsurer__c",
                    type: "record-picker",
                    disabled: true,
                    config: { objectApiName: "Account", labelField: "Name", placeholder: "Search Reinsurer..." }
                },
                {
                    label: "Market Facility Name",
                    name: "MarketFacilityName__c",
                    type: "record-picker",
                    disabled: true,
                    config: { objectApiName: "COM_Facility__c", labelField: "Name", placeholder: "Search Facility..." },
                    collapsible: true
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
                    name: "ParentClaimNo__c",
                    type: "record-picker",
                    disabled: true,
                    config: { objectApiName: "Claim", labelField: "Name", placeholder: "Search Claim..." },
                    collapsible: true
                },
                {
                    label: "Cedant Claim No.",
                    name: "CedantClaimNo__c",
                    collapsible: true
                },
                { label: "Date of Loss", name: "DateOfLoss__c", type: "date" },
                { label: "SOC Seq.", name: "SOCSeq__c" },
                {
                    label: "Child Claim No.",
                    name: "RefClaim__r.Name",
                    type: "url",
                    align: "left",
                    collapsible: true,
                    config: { idField: "RefClaim__c", objectApiName: "Claim" }
                },
                { label: "Location of Loss", name: "LocationOfLoss__c" }
            ]
        },

        {
            label: "Facility BDX",
            name: "FacilityBDX",
            columns: [
                {
                    label: "Facility Name",
                    name: "FacilityName__c",
                    type: "record-picker",
                    disabled: true,
                    config: { objectApiName: "COM_Facility__c", labelField: "Name", placeholder: "Search Facility..." }
                },
                { label: "Facility_UY", name: "Facility_UY__c" },
                { label: "Facility BDX Period From", name: "FacilityBDXPeriodFrom__c", type: "date" },
                { label: "Facility BDX Period To", name: "FacilityBDXPeriodTo__c", type: "date" }
            ]
        }
    ];

    get sliColumns() {
        return this._sliColumnDefs;
    }

    _selectedItemColumnDefs = [
        {
            label: "SLI No.",
            name: "RefSettlementLineItem__r.Name",
            type: "url",
            config: { idField: "RefSettlementLineItem__c", objectApiName: "SettlementLineItem__c" }
        },
        {
            label: "SLI Details",
            name: "header_SLIDetails",
            columns: [
                { label: "Closing Type", name: "RefSettlementLineItem__r.ClosingType__c" },
                {
                    label: "COA",
                    name: "RefSettlementLineItem__r.COA_lk__c",
                    type: "record-picker",
                    disabled: true,
                    config: { objectApiName: "COA__c", labelField: "Name", placeholder: "Search COA..." }
                },
                { label: "COA Name", name: "RefSettlementLineItem__r.COAName_fm__c" },
                {
                    label: "Account Name",
                    name: "RefSettlementLineItem__r.AccountName__c",
                    type: "record-picker",
                    align: "left",
                    disabled: true,
                    config: { objectApiName: "Account", labelField: "Name", placeholder: "Search Account..." }
                },
                { label: "Origin Currency", name: "RefSettlementLineItem__r.OriginCurrency__c" },
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
            name: "header_SettlementDetails",
            columns: [
                { label: "Settlement Date", name: "SettlementDate__c", type: "date" },
                { label: "Settlement Currency", name: "SettlementCurrency__c" },
                {
                    label: "FX Rate (to Settlement)",
                    name: "FXRateOrigintoSettlement__c",
                    type: "number"
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
                    editable: true,
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
                    editable: true,
                    type: "combobox",
                    config: { picklistObject: "ReconciliationLineItem__c", picklistField: "SettlementType__c" }
                },
                { label: "Settlement Status", name: "RefSettlementLineItem__r.SettlementStatus__c" },
                {
                    label: "Settlement Date (Counterparty)",
                    name: "RefSettlementLineItem__r.SettlementDateCounterparty__c",
                    type: "date"
                },
                {
                    label: "Remittance On Hold",
                    name: "RemittanceOnHold__c",
                    type: "boolean",
                    editable: true
                },
                { label: "Hold Reason", name: "HoldReason__c", editable: true }
            ]
        },
        {
            label: "Exchange Details",
            name: "header_ExchangeDetails",
            columns: [
                { label: "Exchange Date", name: "ExchangeDate__c", type: "date", editable: true },
                {
                    label: "Exchange Currency",
                    name: "ExchangeCurrency__c",
                    type: "combobox",
                    editable: true,
                    config: { picklistObject: "ReconciliationLineItem__c", picklistField: "ExchangeCurrency__c" }
                },
                {
                    label: "Exchange Amount",
                    name: "ExchangeAmount__c",
                    type: "currency",
                    config: { ccyField: "ExchangeCurrency__c" },
                    editable: true
                },
                { label: "Exchange Rate", name: "ExchangeRate__c", type: "number", editable: true }
            ]
        }
    ];

    get selectedItemColumns() {
        return this._selectedItemColumnDefs;
    }

    _otherChargesColumnDefs = [
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
        { label: "Closing Type", name: "ClosingType__c" },
        { label: "BT Currency", name: "BTCurrency__c" },
        {
            label: "Amount",
            name: "OriginAmount__c",
            type: "currency",
            editable: true,
            config: { ccyField: "BTCurrency__c" }
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
            config: { objectApiName: "BankTransaction__c", labelField: "Name", placeholder: "Search Bank Transaction..." }
        },
        {
            label: "Remark",
            name: "Remarks__c",
            editable: true
        }
    ];

    get otherChargesColumns() {
        return this._otherChargesColumnDefs;
    }

    // ── Note Filter Definitions ──────────────────────────────────────────

    noteFilterDefs = [
        // ── Row 1 ──────────────────────────────────────────────────────────
        {
            label: "Note Status",
            name: "NoteStatus__c",
            type: "combobox",
            required: true,
            size: 3,
            config: {
                picklistObject: "COM_Note__c",
                picklistField: "NoteStatus__c",
                picklistExclude: ["Clear"]
            }
        },
        {
            label: "Account Name",
            name: "Account_lk__c",
            type: "lookup",
            size: 3,
            config: { objectApiName: "Account", labelField: "Name", placeholder: "Search Account..." }
        },
        {
            label: "Id",
            name: "Id",
            type: "lookup",
            size: 3,
            config: { objectApiName: "COM_Note__c", labelField: "Name", placeholder: "Search Note..." }
        },
        {
            blank: true,
            size: 3
        },
        {
            label: "LK Ref No.",
            name: "LKRefNReins__c",
            size: 3
        },
        {
            label: "Placement No.",
            name: "Placement_lk__c",
            type: "lookup",
            size: 3,
            config: { objectApiName: "Placement__c", labelField: "Name", placeholder: "Search Placement..." }
        },
        {
            label: "Insured",
            name: "Insured_fm__c",
            type: "like"
        },
        {
            blank: true,
            size: 3
        },
        {
            label: "Inception Date",
            name: "PeriodFrom_fm__c",
            type: "date",
            size: 3
        },
        {
            label: "No of Installment",
            name: "InstallmentNo__c",
            type: "number"
        },
        {
            label: "PPW Date",
            name: "PPWDate__c",
            type: "date-range"
        }
    ];

    // ── Note Column Definitions ──────────────────────────────────────────

    noteColumns = [
        {
            label: "Note No.",
            name: "Name",
            type: "url",
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
                    name: "Account_lk__c",
                    type: "record-picker",
                    disabled: true,
                    config: { objectApiName: "Account", labelField: "Name" }
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
                    name: "NoteContact_lk__c",
                    type: "record-picker",
                    disabled: true,
                    config: { objectApiName: "Contact", labelField: "Name" }
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
                { label: "PPW Type", name: "PPWType__c", type: "text" },
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
                    name: "CedantFacility_lk__c",
                    type: "record-picker",
                    disabled: true,
                    collapsible: true,
                    config: { objectApiName: "COM_Facility__c", labelField: "Name", placeholder: "Search Facility..." }
                },
                {
                    label: "Insured",
                    name: "Insured_fm__c",
                    type: "text"
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
}