/**********************************************************************************
 * @filename      : oppProducingCoBroking.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-12-17
 * @description   : Opportunity Producing Co-broking LWC Component
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2025-12-17      i2max              Create
 * 1.1   2025-12-17      i2max              Fix dirty cell display per field
 * 1.2   2026-01-02      i2max              Add Read/Edit mode toggle
 **********************************************************************************/
import { LightningElement, api, track, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

import COBROKER_OBJ from "@salesforce/schema/OPP_Cobroker__c";

import LightningConfirm from "lightning/confirm";
import getCoBrokerList from "@salesforce/apex/Opp_ProducingCoBroking_Ctrl.getCoBrokerList";
import saveCoBrokers from "@salesforce/apex/Opp_ProducingCoBroking_Ctrl.saveCoBrokers";
import deleteCoBrokers from "@salesforce/apex/Opp_ProducingCoBroking_Ctrl.deleteCoBrokers";
import getSettlementTypeOptions from "@salesforce/apex/Opp_ProducingCoBroking_Ctrl.getSettlementTypeOptions";
import checkEditPermission from "@salesforce/apex/Opp_ProducingCoBroking_Ctrl.checkEditPermission";

import LABEL_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import LABEL_DELETE from "@salesforce/label/c.COM_BTN_DEL";
import LABEL_REFRESH from "@salesforce/label/c.COM_BTN_REFRESH";
import LABEL_ADD from "@salesforce/label/c.COM_BTN_ADD";
import LABEL_EDIT from "@salesforce/label/c.COM_BTN_EDIT";
import LABEL_CANCEL from "@salesforce/label/c.COM_BTN_CANCEL";
import LABEL_NORECORDS from "@salesforce/label/c.COM_MSG_NORECORDS";
import IPL_MSG_ChangedError from "@salesforce/label/c.IPL_MSG_ChangedError";

// Opportunity Fields
import ISCLOSED_FIELD from "@salesforce/schema/Opportunity.IsClosed";
import STAGENAME_FIELD from "@salesforce/schema/Opportunity.StageName";

// Constants
const PERCENTAGE_MIN = 0;
const PERCENTAGE_MAX = 100;

export default class OppProducingCoBroking extends NavigationMixin(LightningElement) {
    // API 속성
    @api recordId;

    // 추적 속성 (반응형)
    @track coBrokerList = [];
    @track settlementTypeOptions = [];
    @track isDeleteDisabled = true;
    @track activeSectionName = "producingCoBroking";
    @track allSelected = false;
    @track hasEditPermission = false;
    @track isClosed = false;

    // Private 속성
    wiredCoBrokerResult;
    wiredRecordResult;
    rowCounter = 0;
    originalData = new Map();
    previousIsClosed = false;
    objectFields;
    init = false;

    labels = {
        save: LABEL_SAVE,
        delete: LABEL_DELETE,
        add: LABEL_ADD,
        refresh: LABEL_REFRESH,
        edit: LABEL_EDIT,
        cancel: LABEL_CANCEL,
        noRecords: LABEL_NORECORDS,
        changedError: IPL_MSG_ChangedError
    };

    // Getter/Setter
    get hasRecords() {
        return this.coBrokerList && this.coBrokerList.length > 0;
    }

    get accountLookupConfig() {
        return {
            objectApiName: "Account",
            labelField: "Name",
            orderByField: "Name",
            orderDir: "ASC",
            filters: []
        };
    }

    get contactLookupConfig() {
        return (ctx) => ({
            objectApiName: "Contact",
            labelField: "Name",
            orderByField: "Name",
            orderDir: "ASC",
            filters: ctx.parentId ? [{ field: "AccountId", op: "EQ", value: ctx.parentId, groupKey: "account" }] : []
        });
    }

    get coBrokerNameLabel() {
        return this.objectFields?.CobrokerName_lk__c?.label ?? "CobrokerName_lk__c";
    }

    get coBrokerContactLabel() {
        return this.objectFields?.CobrokerContact_lk__c?.label ?? "CobrokerContact_lk__c";
    }

    get sharingPctLabel() {
        return this.objectFields?.SharingPct__c?.label ?? "SharingPct__c";
    }

    get settlementTypeLabel() {
        return this.objectFields?.SettlementType__c?.label ?? "Settlement Type";
    }

    get clientLabel() {
        return this.objectFields?.Client__c?.label ?? "Client";
    }

    get isSaveDisabled() {
        if (!this.hasEditPermission || this.isClosed) {
            return true;
        }

        return !this.validatePercentageFields();
    }

    // Wire 메서드
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [ISCLOSED_FIELD, STAGENAME_FIELD]
    })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        const { error, data } = result;

        if (data) {
            const currentIsClosed = getFieldValue(data, ISCLOSED_FIELD);

            if (this.previousIsClosed !== currentIsClosed) {
                this.handleOpportunityStatusChange(currentIsClosed);
                this.previousIsClosed = currentIsClosed;
            }
        } else if (error) {
            console.error("Error monitoring opportunity status:", error);
        }
    }

    @wire(checkEditPermission, { oppId: "$recordId" })
    wiredEditPermission({ data, error }) {
        if (data !== undefined) {
            this.hasEditPermission = data;
        } else if (error) {
            this.hasEditPermission = false;
            console.error("Error checking edit permission:", error);
        }
    }

    @wire(getCoBrokerList, { oppId: "$recordId" })
    wiredCoBrokers(result) {
        this.wiredCoBrokerResult = result;
        if (result.data) {
            this.coBrokerList = result.data.map((record, index) => {
                const key = record.Id || `new-${this.rowCounter++}`;
                const rowData = this.createRowData(record, key);
                rowData.rowNumber = index + 1;
                this.originalData.set(key, JSON.parse(JSON.stringify(rowData)));
                return rowData;
            });
            this.updateDeleteButtonState();
        } else if (result.error) {
            this.showToast("Error", "Error loading Co-Broker list", "error");
        }
    }

    @wire(getSettlementTypeOptions)
    wiredSettlementTypes({ data, error }) {
        this.settlementTypeOptions = [];
        if (data) {
            this.settlementTypeOptions = data || [];
        } else if (error) {
            this.showToast("Error", "Error loading Settlement Type options", "error");
        }
    }

    @wire(getObjectInfo, { objectApiName: COBROKER_OBJ })
    wiredObjectInfo({ data, error }) {
        if (data?.fields) {
            this.objectFields = data.fields;
        } else if (error) {
            this.objectFields = null;
            console.error(error);
        }
    }

    // 이벤트 핸들러
    handleFieldEdit(event) {
        const rowKey = event.currentTarget.dataset.key;

        this.coBrokerList = this.coBrokerList.map((row) => {
            if (row.key === rowKey) {
                return { ...row, isEditMode: true };
            }
            // 다른 행은 Read 모드로 전환 (dirtyFields가 있어도 저장 안됨)
            return { ...row, isEditMode: false };
        });
    }

    handleSelectAll(event) {
        event.stopPropagation();
        this.allSelected = event.target.checked;
        this.coBrokerList = this.coBrokerList.map((row) => ({
            ...row,
            isChecked: this.allSelected
        }));
        this.updateDeleteButtonState();
    }

    handleCheckboxChange(event) {
        event.stopPropagation();
        const rowKey = event.target.dataset.key;
        const isChecked = event.target.checked;

        this.coBrokerList = this.coBrokerList.map((row) => {
            if (row.key === rowKey) {
                return { ...row, isChecked: isChecked };
            }
            return row;
        });

        this.allSelected = this.coBrokerList.length > 0 && this.coBrokerList.every((row) => row.isChecked);
        this.updateDeleteButtonState();
    }

    handleLookupChange(event) {
        const fieldName = event.detail.fieldName;
        const rowKey = event.currentTarget.dataset.key;

        let updatedRow;
        if (fieldName === "CobrokerName_lk__c") {
            updatedRow = {
                CobrokerName_lk__c: event.detail.value,
                CobrokerNameLabel: event.detail.label || "",
                CobrokerContact_lk__c: null,
                CobrokerContactLabel: ""
            };
        } else if (fieldName === "CobrokerContact_lk__c") {
            updatedRow = {
                CobrokerContact_lk__c: event.detail.value,
                CobrokerContactLabel: event.detail.label || ""
            };
        }

        this.updateRowData(rowKey, fieldName, updatedRow);
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        const rowKey = event.target.dataset.key;
        let value = event.target.value;

        if (field === "SharingPct__c") {
            value = value ? parseFloat(value) : 0;
        }

        this.updateRowData(rowKey, field, { [field]: value });
    }

    handleComboboxChange(event) {
        const field = event.target.dataset.field;
        const rowKey = event.target.dataset.key;
        const value = event.detail.value;

        this.updateRowData(rowKey, field, { [field]: value });
    }

    handleCheckboxFieldChange(event) {
        event.stopPropagation();
        const rowKey = event.target.dataset.key;
        const isChecked = event.target.checked;

        this.updateRowData(rowKey, "Client__c", { Client__c: isChecked });
    }

    handleNavigateToRecord(event) {
        event.preventDefault();
        event.stopPropagation();

        const { recordId, objectApiName } = event.currentTarget.dataset;

        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                objectApiName: objectApiName,
                recordId: recordId,
                actionName: "view"
            }
        })
            .then((url) => {
                window.open(url, "_blank");
            })
            .catch((error) => {
                console.error("handleNavigateToRecord error", error);
            });
    }

    handleAdd() {
        const key = `new-${this.rowCounter++}`;
        const newRow = this.createRowData(
            {
                Id: null,
                CobrokerName_lk__c: null,
                CobrokerContact_lk__c: null,
                SharingPct__c: 0,
                SettlementType__c: "",
                Client__c: false
            },
            key,
            true
        );

        newRow.rowNumber = this.coBrokerList.length + 1;
        this.originalData.set(key, JSON.parse(JSON.stringify(newRow)));
        this.coBrokerList = [...this.coBrokerList, newRow];
    }

    async handleRefresh() {
        this.coBrokerList = [];
        try {
            const freshData = await getCoBrokerList({ oppId: this.recordId });

            this.coBrokerList = freshData.map((record, index) => {
                const key = record.Id || `new-${this.rowCounter++}`;
                const rowData = this.createRowData(record, key);
                rowData.rowNumber = index + 1;
                this.originalData.set(key, JSON.parse(JSON.stringify(rowData)));
                return rowData;
            });

            this.updateDeleteButtonState();
        } catch (error) {
            this.showToast("Error", "Error refreshing data: " + error.message, "error");
        }
    }

    async handleDelete() {
        const selectedRows = this.coBrokerList.filter((r) => r.isChecked);
        const idsToDelete = selectedRows.filter((r) => r.Id).map((r) => r.Id);
        const localUnsavedRowsToKeep = this.coBrokerList.filter((r) => !r.Id && !r.isChecked);
        const localSelectedKeysToDelete = selectedRows.filter((r) => !r.Id).map((r) => r.key);

        localSelectedKeysToDelete.forEach((k) => this.originalData.delete(k));

        if (idsToDelete.length > 0) {
            const confirmed = await LightningConfirm.open({
                message: "Are you sure you want to delete the selected records?",
                theme: "warning",
                label: "Confirm Delete"
            });
            if (!confirmed) return;

            try {
                await deleteCoBrokers({ coBrokerIds: idsToDelete, oppId: this.recordId });
                this.showToast("Success", "Co-Broker records deleted successfully", "success");

                await refreshApex(this.wiredCoBrokerResult);

                const merged = [...this.coBrokerList, ...localUnsavedRowsToKeep];

                this.coBrokerList = merged.map((r, idx) => ({
                    ...r,
                    rowNumber: idx + 1,
                    isChecked: false
                }));

                this.allSelected = false;
                this.updateDeleteButtonState();

                idsToDelete.forEach((id) => this.originalData.delete(id));
            } catch (error) {
                this.showToast("Error", error?.body?.message || "An error occurred", "error");
            }
        } else {
            const remainingRows = this.coBrokerList.filter((r) => !r.isChecked);

            this.coBrokerList = remainingRows.map((r, idx) => ({
                ...r,
                rowNumber: idx + 1,
                isChecked: false
            }));

            this.allSelected = false;
            this.updateDeleteButtonState();
            await refreshApex(this.wiredCoBrokerResult);
        }
    }

    handleSave() {
        const emptyRows = [];
        this.coBrokerList.forEach((row, index) => {
            if (!row.CobrokerName_lk__c) {
                emptyRows.push(index + 1);
            }
        });

        if (emptyRows.length > 0) {
            this.coBrokerList = this.coBrokerList.map((row) => {
                const updatedRow = { ...row };
                if (!row.CobrokerName_lk__c) {
                    updatedRow.CobrokerName_lk__cClass = "dirty-cell error-cell";
                } else {
                    updatedRow.CobrokerName_lk__cClass =
                        updatedRow.CobrokerName_lk__cClass?.replace(" error-cell", "").trim() || "";
                }
                return updatedRow;
            });

            const rowNumbers = emptyRows.join(", ");
            this.showToast("Warning", `Please enter Co-broker Name for row(s): ${rowNumbers}`, "warning");
            return;
        }

        const hasChanges = this.coBrokerList.some((row) => {
            return row.dirtyFields && row.dirtyFields.size > 0;
        });

        if (!hasChanges) {
            this.showToast("Info", this.labels.changedError, "info");
            return;
        }

        this.coBrokerList = this.coBrokerList.map((row) => {
            const updatedRow = { ...row };
            updatedRow.CobrokerName_lk__cClass =
                updatedRow.CobrokerName_lk__cClass?.replace(" error-cell", "").trim() || "";
            return updatedRow;
        });

        const recordsToSave = this.coBrokerList.map((row) => ({
            Id: row.Id,
            CobrokerName_lk__c: row.CobrokerName_lk__c,
            CobrokerContact_lk__c: row.CobrokerContact_lk__c,
            SharingPct__c: row.SharingPct__c,
            SettlementType__c: row.SettlementType__c,
            Client__c: row.Client__c
        }));

        saveCoBrokers({ coBrokers: recordsToSave, oppId: this.recordId })
            .then(() => {
                this.showToast("Success", "Co-Broker records saved successfully", "success");
                this.coBrokerList = this.coBrokerList.map((row) => {
                    const cleanRow = this.createRowData(row, row.key, false);
                    this.originalData.set(row.key, JSON.parse(JSON.stringify(cleanRow)));
                    return cleanRow;
                });
                return refreshApex(this.wiredCoBrokerResult);
            })
            .catch((error) => {
                this.showToast("Error", error.body?.message || "An error occurred", "error");
            });
    }

    // Private 메서드
    validatePercentageFields() {
        if (!this.coBrokerList || this.coBrokerList.length === 0) {
            return true;
        }

        return !this.coBrokerList.some((row) => {
            const sharingPct = parseFloat(row.SharingPct__c);

            return this.isInvalidPercentage(sharingPct);
        });
    }

    isInvalidPercentage(value) {
        return isNaN(value) || value < PERCENTAGE_MIN || value > PERCENTAGE_MAX;
    }

    createRowData(record, key, isNew = false) {
        const dirtyFields = isNew
            ? new Set([
                  "CobrokerName_lk__c",
                  "CobrokerContact_lk__c",
                  "SharingPct__c",
                  "SettlementType__c",
                  "Client__c"
              ])
            : new Set();

        const rowData = {
            key: key,
            Id: record.Id,
            CobrokerName_lk__c: record.CobrokerName_lk__c,
            CobrokerNameLabel: record.CobrokerName_lk__r?.Name || "",
            CobrokerContact_lk__c: record.CobrokerContact_lk__c,
            CobrokerContactLabel: record.CobrokerContact_lk__r?.Name || "",
            SharingPct__c: record.SharingPct__c || 0,
            SettlementType__c: record.SettlementType__c || "",
            Client__c: record.Client__c || false,
            isChecked: false,
            rowNumber: 0,
            dirtyFields: dirtyFields,
            isEditMode: isNew // 행 전체 Edit 모드
        };

        rowData.CobrokerName_lk__cClass = dirtyFields.has("CobrokerName_lk__c") ? "dirty-cell" : "";
        rowData.CobrokerContact_lk__cClass = dirtyFields.has("CobrokerContact_lk__c") ? "dirty-cell" : "";
        rowData.SharingPct__cClass = dirtyFields.has("SharingPct__c") ? "dirty-cell" : "";
        rowData.SettlementType__cClass = dirtyFields.has("SettlementType__c") ? "dirty-cell" : "";
        rowData.Client__cClass = dirtyFields.has("Client__c") ? "dirty-cell" : "";

        return rowData;
    }

    updateRowData(rowKey, changedField, updates) {
        this.coBrokerList = this.coBrokerList.map((row) => {
            if (row.key === rowKey) {
                const updatedRow = { ...row, ...updates };
                const original = this.originalData.get(rowKey);

                if (original) {
                    const dirtyFields = new Set(row.dirtyFields || []);

                    const fieldsToCheck =
                        changedField === "CobrokerName_lk__c"
                            ? ["CobrokerName_lk__c", "CobrokerContact_lk__c"]
                            : [changedField];

                    fieldsToCheck.forEach((field) => {
                        if (this.isFieldDirty(field, updatedRow, original)) {
                            dirtyFields.add(field);
                        } else {
                            dirtyFields.delete(field);
                        }
                    });

                    updatedRow.dirtyFields = dirtyFields;

                    updatedRow.CobrokerName_lk__cClass = dirtyFields.has("CobrokerName_lk__c") ? "dirty-cell" : "";
                    updatedRow.CobrokerContact_lk__cClass = dirtyFields.has("CobrokerContact_lk__c")
                        ? "dirty-cell"
                        : "";
                    updatedRow.SharingPct__cClass = dirtyFields.has("SharingPct__c") ? "dirty-cell" : "";
                    updatedRow.SettlementType__cClass = dirtyFields.has("SettlementType__c") ? "dirty-cell" : "";
                    updatedRow.Client__cClass = dirtyFields.has("Client__c") ? "dirty-cell" : "";
                }

                return updatedRow;
            }
            return row;
        });
    }

    isFieldDirty(fieldName, current, original) {
        return current[fieldName] !== original[fieldName];
    }

    handleOpportunityStatusChange(currentIsClosed) {
        this.isClosed = currentIsClosed;
        refreshApex(this.wiredCoBrokerResult);
    }

    updateDeleteButtonState() {
        this.isDeleteDisabled = !this.coBrokerList.some((row) => row.isChecked);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }

    // 라이프사이클 메서드
    connectedCallback() {
        if (this.init) return;
        this.init = true;
        const style = document.createElement("style");
        style.innerText = `.cus-lk-input-num-right input { text-align: right !important; }`;
        document.body.appendChild(style);
    }

    disconnectedCallback() {
        // cleanup
    }
}