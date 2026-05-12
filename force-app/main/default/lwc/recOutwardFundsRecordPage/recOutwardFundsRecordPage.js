/**
 * @description       : Settlement Line Item inquiry for Outward Fund record page
 * @author            : Akrom Saidkamolov
 * @last modified on  : 2026-04-22
 * @last modified by  : Akrom Saidkamolov
 **/
import { LightningElement, api, track } from "lwc";
import { registerRefreshHandler, unregisterRefreshHandler } from "lightning/refresh";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import LightningConfirm from "lightning/confirm";
import RecOutwardFundsModal from "c/recOutwardFundsModal";

import apexInquirySettlementLineItems from "@salesforce/apex/REC_OutwardFundCtrl.inquirySettlementLineItems";
import apexInquiryNotes from "@salesforce/apex/REC_OutwardFundCtrl.inquiryNotes";
import apexGetRelatedSlis from "@salesforce/apex/REC_OutwardFundCtrl.getRelatedSlis";
import apexGetOutwardFundWithLineItems from "@salesforce/apex/REC_OutwardFundCtrl.getOutwardFundWithLineItems";
import apexSaveOutwardFundLineItems from "@salesforce/apex/REC_OutwardFundCtrl.saveOutwardFundLineItems";
import apexDeleteOutwardFundLineItems from "@salesforce/apex/REC_OutwardFundCtrl.deleteOutwardFundLineItems";

import {
    sliFilterDefs as _sliFilterDefs,
    noteFilterDefs as _noteFilterDefs,
    outwardFundsColumns as _outwardFundsColumns,
    sliColumns as _sliColumns,
    selectedSliColumns as _selectedSliColumns,
    noteColumns as _noteColumns
} from "./tableConfig";

export default class RecOutwardFundsRecordPage extends LightningElement {
    @api recordId;

    // ── Table Data ───────────────────────────────────────────────────────

    @track outwardFundsData = [];
    @track sliData = [];
    @track noteData = [];
    @track selectedItems = [];

    // ── Refresh Handler ───────────────────────────────────────────────────

    _refreshHandlerId;

    // ── Table State ──────────────────────────────────────────────────────

    _isLoading = false;
    _activeTab = "sli";
    _selectedCount = 0;
    _noteSelectedCount = 0;
    _selectedItemSelectedCount = 0;
    _noteIdsWithNoSlis = [];

    // ── Filter & Column Definitions ─────────────────────────────────────

    sliFilterDefs = _sliFilterDefs;
    noteFilterDefs = _noteFilterDefs;
    outwardFundsColumns = _outwardFundsColumns;
    sliColumns = _sliColumns;
    selectedSliColumns = _selectedSliColumns;
    noteColumns = _noteColumns;

    // ── Lifecycle ────────────────────────────────────────────────────────

    async connectedCallback() {
        this.registerRefreshApi();
        this._isLoading = true;
        await this._loadOutwardFundWithLineItems();
        this._isLoading = false;
    }

    registerRefreshApi() {
        try {
            console.log("Registering refresh handler for LWS");
            this._refreshHandlerId = registerRefreshHandler(this, this._handleRefresh);
        } catch (error) {
            console.log("Registering refresh handler for Locker");
            this._refreshHandlerId = registerRefreshHandler(this.template.host, this._handleRefresh.bind(this));
        }
    }

    disconnectedCallback() {
        console.log("Unregistering refresh handler:", this._refreshHandlerId);
        unregisterRefreshHandler(this._refreshHandlerId);
    }

    // ── Data Loading ─────────────────────────────────────────────────────
    _handleRefresh() {
        return this._loadOutwardFundWithLineItems();
    }

    async _loadOutwardFundWithLineItems() {
        try {
            const record = await apexGetOutwardFundWithLineItems({ outwardFundId: this.recordId });

            if (!record) throw new Error("Outward Fund not found");

            this.selectedItems = (record.OutwardFundLineItems__r || []).map((ofli) => {
                return {
                    ...ofli.ClosingInfo__r,
                    AdditionalAccountInfo__c: ofli.AdditionalAccountInfo__c
                };
            });

            this.outwardFundsData = [{ ...record, OutwardFundLineItems__r: null }];

            this._applySettlementEditability();
        } catch (error) {
            console.error("Failed to load Outward Fund Line Items:", error);
        }
    }

    /** Disable SettlementCurrency__c for rows where SettlementStatus__c is not "Not-Available" */
    _applySettlementEditability() {
        Promise.resolve().then(() => {
            const table = this.refs.selectedTable;
            if (!table) return;
            this.selectedItems.forEach((row) => {
                const editable = row.SettlementStatus__c === "Not-Available";
                table.setCellDisabled(row.Id, "SettlementCurrency__c", !editable);
                table.setCellDisabled(row.Id, "FXRateOrigintoSettlement__c", !editable);
                table.setCellDisabled(row.Id, "SettlementType__c", !editable);
            });
        });
    }

    // ── Computed Properties ──────────────────────────────────────────────

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

    get sliDisabledRowIds() {
        return this.selectedItems.map((r) => r.Id);
    }

    get displayNoteRowCount() {
        return this.noteData?.length || 0;
    }

    get displayNoteSelectedCount() {
        return this._noteSelectedCount;
    }

    get noteDisabledRowIds() {
        const alreadySelected = this.selectedItems.map((r) => r.Note_lk__c).filter(Boolean);
        return [...new Set([...alreadySelected])];
    }

    get isRecordLocked() {
        return (
            this.outwardFundsData.at(0)?.ApprovalStatus__c === "In Review" ||
            this.outwardFundsData.at(0)?.ApprovalStatus__c === "Approved"
        );
    }

    _noteFilterRef() {
        const ref = this.refs.noteFilter;
        const selectedElement = this.template.querySelector("c-rec-filter-bar[data-id='noteFilter']");

        console.log("_noteFilterRef:", { ref, selectedElement });

        return ref || selectedElement;
    }

    // ── Tab Handler ──────────────────────────────────────────────────────

    handleTabChange(event) {
        this._activeTab = event.target.value;
    }

    // ── SLI Event Handlers ───────────────────────────────────────────────

    handleSliInquiryClick() {
        if (!this.refs.sliFilter.validate()) return;

        const values = this.refs.sliFilter.getValues();
        this._isLoading = true;
        apexInquirySettlementLineItems({ filters: JSON.stringify(values) })
            .then((result) => {
                this.sliData = (result || []).map((sli) => ({ ...sli }));
                this._selectedCount = 0;
            })
            .catch((error) => {
                console.error("Inquiry error:", error);
                this._showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
                this.sliData = [];
            })
            .finally(() => {
                this._isLoading = false;
            });
    }

    handleSliResetClick() {
        this.refs.sliFilter.reset();
    }

    handleSliRowSelection(event) {
        this._selectedCount = event.detail.selectedRows.length;
    }

    handleSelectedSliCellChange(event) {
        const { rowId, fieldName, value, oldValue } = event.detail;
        console.log(`Cell changed — row:${rowId} field:${fieldName} ${oldValue} → ${value}`);

        const row = this.selectedItems.find((r) => r.Id === rowId);
        if (row) {
            row[fieldName] = value;
            this.selectedItems = [...this.selectedItems];
        }
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

    async handleSliSelect() {
        const selectedRows = this.refs.sliTable.getSelectedRows() || [];
        if (!selectedRows.length) return;

        const alreadySelectedIds = new Set(this.selectedItems.map((r) => r.Id));
        let newRows = selectedRows.filter((r) => !alreadySelectedIds.has(r.Id));
        if (!newRows.length) return;

        try {
            const updatedRows = await RecOutwardFundsModal.open({
                settlementLineItems: newRows,
                size: "small"
            });

            if (!updatedRows) return;
            this._isLoading = true;

            this.selectedItems = [...this.selectedItems, ...updatedRows];
            this._applySettlementEditability();
            this.refs.sliTable.clearSelection();
            this._selectedCount = 0;
        } catch (error) {
            console.error("SLI select error:", error);
            this._showToast("Error", error.body?.message || error?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    // ── Note Event Handlers ──────────────────────────────────────────────

    async handleNoteInquiryClick() {
        try {
            if (!this._noteFilterRef().validate()) return;
            this._isLoading = true;

            const values = this._noteFilterRef().getValues();

            const notes = await apexInquiryNotes({
                filters: JSON.stringify(values),
                relFields: JSON.stringify([
                    "Account_lk__r.Name",
                    "NoteContact_lk__r.Name",
                    "CedantFacility_lk__r.Name",
                    "Insured_lk__r.Name"
                ])
            });
            this.noteData = notes || [];
            this._noteSelectedCount = 0;
            this._noteIdsWithNoSlis = this.noteData.filter((n) => !n.SettlementLineItemsByNote__r?.length).map((n) => n.Id);
        } catch (error) {
            console.error("Note inquiry error:", error);
            this._showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
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

    async handleNoteSelect() {
        try {
            const selectedRows = this.refs.noteTable?.getSelectedRows() || [];
            if (!selectedRows.length) return;

            const noteIds = selectedRows.map((r) => r.Id);

            this._isLoading = true;

            const incomingSlis = (await apexGetRelatedSlis({ noteIds })) || [];
            if (!incomingSlis.length) {
                this._showToast("Info", "No related SLIs found for the selected Notes.", "info");
                return;
            }

            const alreadySelectedIds = new Set(this.selectedItems.map((r) => r.Id));
            let newRows = incomingSlis.filter((r) => !alreadySelectedIds.has(r.Id));
            if (!newRows.length) {
                this._showToast("Info", "All related SLIs are already in the selected table.", "info");
                return;
            }
            this._isLoading = false;
            const updatedRows = await RecOutwardFundsModal.open({
                settlementLineItems: newRows,
                size: "small"
            });

            if (!updatedRows) return;
            this._isLoading = true;

            this.selectedItems = [...this.selectedItems, ...updatedRows];
            this._applySettlementEditability();
            this.refs.noteTable?.clearSelection();
            this._noteSelectedCount = 0;
        } catch (error) {
            console.error("Note select error:", error);
            this._showToast("Error", error.body?.message || error?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    // ── Selected Items Event Handlers ────────────────────────────────────────

    handleSelectedItemRowSelection(event) {
        this._selectedItemSelectedCount = event.detail.selectedRows.length;
    }

    async handleSaveClick() {
        try {
            if (!this.selectedItems.length) {
                this._showToast("Warning", "No items to save.", "warning");
                return;
            }

            this._isLoading = true;

            const outwardFundLineItems = this.selectedItems.map((item) => ({
                OutwardFund__c: this.recordId,
                ClosingInfo__c: item.Id,
                AdditionalAccountInfo__c: item.AdditionalAccountInfo__c
            }));

            console.log("sli records to confirm:", JSON.stringify(this.selectedItems, null, 2));
            console.log("outward fund line items to confirm:", JSON.stringify(outwardFundLineItems, null, 2));

            await apexSaveOutwardFundLineItems({ outwardFundLineItems, sliRecords: this.selectedItems });
            this._showToast("Success", "Outward Fund Line Items saved successfully.", "success");
            this._loadOutwardFundWithLineItems();
        } catch (error) {
            console.error("Confirm error:", error);
            this._showToast("Error", error.body?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    async handleSelectedItemReset() {
        this._isLoading = true;
        await this._loadOutwardFundWithLineItems();
        this._isLoading = false;
    }

    async handleSelectedItemDelete() {
        const selectedRows = this.refs.selectedTable.getSelectedRows() || [];

        if (!selectedRows.length) {
            this._showToast("No rows selected", "Please select at least one item to delete.", "warning");
            return;
        }

        const confirmed = await LightningConfirm.open({
            label: "Delete Line Items",
            message: `Remove ${selectedRows.length} item(s) from this Outward Fund?`,
            theme: "error"
        });

        if (!confirmed) return;

        try {
            this._isLoading = true;
            const sliIds = selectedRows.map((r) => r.Id);
            await apexDeleteOutwardFundLineItems({ outwardFundId: this.recordId, sliIds });

            const deletedIds = new Set(sliIds);
            this.selectedItems = this.selectedItems.filter((r) => !deletedIds.has(r.Id));
            this._selectedItemSelectedCount = 0;
            this._showToast("Success", "Line item(s) removed successfully.", "success");

            this._loadOutwardFundWithLineItems();
        } catch (error) {
            console.error("Delete error:", error);
            this._showToast("Error", error.body?.message || error?.message || "An unexpected error occurred.", "error");
        } finally {
            this._isLoading = false;
        }
    }

    // ── Private Helpers ──────────────────────────────────────────────────

    _showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}