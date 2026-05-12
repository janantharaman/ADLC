/**********************************************************************************
 * @filename      : oppProducingCoBrokingSingle.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-12-23
 * @group         :
 * @group-content :
 * @description   : Opportunity Producing Co-broking Single Row LWC 컴포넌트
 *                  - Producing Co-broking 단일 행 데이터를 조회·편집·저장·삭제하고,
 *                  - 기존 레코드 대체 저장 확인 모달 처리,
 *                  - Opportunity/Placement/Claim 컨텍스트 분기 및 이벤트 연동을 수행한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2025-12-23       i2max             Create
 **********************************************************************************/

import { LightningElement, api, track, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { toast } from "c/com";
import { NavigationMixin } from "lightning/navigation";
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import LightningConfirm from "lightning/confirm";

// LMS
import { publish, MessageContext } from "lightning/messageService";
import OPP_DATA_CHANGED from "@salesforce/messageChannel/OPP_OpportunityDataChanged__c";

// Apex Methods
import getInitData from "@salesforce/apex/Opp_ProducingCoBroking_Ctrl.getInitData";
import saveWithReplace from "@salesforce/apex/Opp_ProducingCoBroking_Ctrl.saveWithReplace";
import saveCoBrokers from "@salesforce/apex/Opp_ProducingCoBroking_Ctrl.saveCoBrokers";
import deleteCoBrokers from "@salesforce/apex/Opp_ProducingCoBroking_Ctrl.deleteCoBrokers";

// Custom Labels
import LABEL_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import LABEL_REFRESH from "@salesforce/label/c.COM_BTN_REFRESH";
import COM_BTN_CANCEL from "@salesforce/label/c.COM_BTN_CANCEL";
import COM_BTN_DEL from "@salesforce/label/c.COM_BTN_DEL";
import OPP_MSG_TYPE_CLIENT from "@salesforce/label/c.OPP_MSG_TYPE_CLIENT";
import IPL_MSG_ChangedError from "@salesforce/label/c.IPL_MSG_ChangedError";
import OPP_MSG_COBROKER_LOAD_ERROR from "@salesforce/label/c.OPP_MSG_COBROKER_LOAD_ERROR";
import OPP_MSG_COBROKER_NAME from "@salesforce/label/c.OPP_MSG_COBROKER_NAME";
import OPP_MSG_COBROKER_SAVE_SUCCESS from "@salesforce/label/c.OPP_MSG_COBROKER_SAVE_SUCCESS";
import OPP_LBL_COBROKER_EXIST from "@salesforce/label/c.OPP_LBL_COBROKER_EXIST";
import OPP_MSG_COBROKER_DELETE_SUCCESS from "@salesforce/label/c.OPP_MSG_COBROKER_DELETE_SUCCESS";
import OPP_MSG_COBROKER_DELETE_CONFIRM from "@salesforce/label/c.OPP_MSG_COBROKER_DELETE_CONFIRM";

// Schema
import ISCLOSED_FIELD from "@salesforce/schema/Opportunity.IsClosed";
import STAGENAME_FIELD from "@salesforce/schema/Opportunity.StageName";
import COBROKER_OBJ from "@salesforce/schema/OPP_Cobroker__c";

// Constants
const PERCENTAGE_MIN = 0;
const PERCENTAGE_MAX = 100;

export default class OppProducingCoBrokingSingle extends NavigationMixin(LightningElement) {
    // Public Properties
    @api recordId;

    // Reactive Properties
    @track coBrokerRow = null;
    @track settlementTypeOptions = [];
    @track hasEditPermission = false;
    @track _isClosed = false;
    @track isPlacementClosed = false;
    @track showConfirmModal = false;
    @track existingRecords = [];
    @track isPlacementMode = false;
    isClaim = false;

    // Private Properties
    wiredInitDataResult;
    wiredRecordResult;
    originalData = null;
    previousIsClosed = false;
    objectFields;
    _bizRegion = null;

    // Custom Labels
    labels = {
        save: LABEL_SAVE,
        refresh: LABEL_REFRESH,
        cancel: COM_BTN_CANCEL,
        delete: COM_BTN_DEL,
        typeClientMsg: OPP_MSG_TYPE_CLIENT,
        changedError: IPL_MSG_ChangedError,
        loadError: OPP_MSG_COBROKER_LOAD_ERROR,
        coBrokerNameEmpty: OPP_MSG_COBROKER_NAME,
        saveSuccess: OPP_MSG_COBROKER_SAVE_SUCCESS,
        coBrokerExist: OPP_LBL_COBROKER_EXIST,
        deleteSuccess: OPP_MSG_COBROKER_DELETE_SUCCESS,
        deleteConfirm: OPP_MSG_COBROKER_DELETE_CONFIRM
    };

    // Constants / Maps
    _BIZ_REGION_FILTER_MAP = {
        LK_KR: "ActiveKr_is__c",
        LK_Re: "ActiveRe_is__c",
        LK_VN: "ActiveVn_is__c",
        "LK_A&G": null
    };

    // Getters
    get isClosed() {
        return this._isClosed || this.isPlacementClosed;
    }

    get activeSectionName() {
        return this.isClaim ? "" : "producingCoBrokingSingle";
    }

    get accountLookupConfig() {
        const filters = [];
        if (this._bizRegion) {
            const activeField = this._BIZ_REGION_FILTER_MAP[this._bizRegion];
            if (activeField) {
                filters.push({ field: activeField, op: "EQ", value: true, type: "BOOLEAN" });
            }
        }
        return {
            objectApiName: "Account",
            labelField: "Name",
            orderByField: "Name",
            orderDir: "ASC",
            filters
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
        return this.objectFields?.CobrokerName_lk__c?.label ?? "Co-broker name";
    }

    get coBrokerContactLabel() {
        return this.objectFields?.CobrokerContact_lk__c?.label ?? "Co-broker contact";
    }

    get sharingPctLabel() {
        return this.objectFields?.SharingPct__c?.label ?? "Sharing (%)";
    }

    get lkAdminFeePctLabel() {
        return this.objectFields?.LKAdminFeePct__c?.label ?? "Admin Fee";
    }

    get settlementTypeLabel() {
        return this.objectFields?.SettlementType__c?.label ?? "Settlement Type";
    }

    get clientLabel() {
        return this.objectFields?.Client__c?.label ?? "Client";
    }

    get isSaveDisabled() {
        if (!this.hasEditPermission || this.isClosed) return true;
        if (!this.coBrokerRow) return true;
        return !this.validatePercentageFields();
    }

    get showNoRecordsRow() {
        return (!this.hasEditPermission || this.isClosed) && (!this.coBrokerRow || !this.coBrokerRow.Id);
    }

    get hasRecord() {
        return !!(this.coBrokerRow && this.coBrokerRow.Id);
    }

    get oppRecordId() {
        return this.recordId?.startsWith("006") ? this.recordId : null;
    }

    get showCard() {
        return !(this.isClaim && !this.hasRecord);
    }

    get showBrokerageAdjRow() {
        return !this.isClaim;
    }

    // Wire Methods

    /**
     * @description OPP_Cobroker__c 메타 정보를 조회하여 필드 라벨에 사용한다.
     * @return {void}
     */
    @wire(getObjectInfo, { objectApiName: COBROKER_OBJ })
    wiredObjectInfo({ data, error }) {
        if (data?.fields) {
            this.objectFields = data.fields;
        } else if (error) {
            this.objectFields = null;
            console.error("Error loading object info:", error);
        }
    }

    /**
     * @description 초기 화면 데이터를 조회하여 단일 행 데이터와 권한, 옵션, 컨텍스트 값을 세팅한다.
     * @param {Object} result wire 결과 객체
     * @return {void}
     */
    @wire(getInitData, { recordId: "$recordId" })
    wiredInitData(result) {
        this.wiredInitDataResult = result;
        const { data, error } = result;

        if (data) {
            this.isPlacementMode = data.isPlacement || false;
            this.isClaim = data.isClaim || false;
            this.hasEditPermission = data.hasEditPermission || false;
            this.isPlacementClosed = this.isPlacementMode && data.placementClosingDate != null;
            this.settlementTypeOptions = data.settlementTypeOptions || [];
            this._bizRegion = data.bizRegion || null;
            this._applyRowData(data.coBrokerList || []);
        } else if (error) {
            toast("Error", this.labels.loadError, "error");
        }
    }

    /**
     * @description Opportunity IsClosed 상태를 모니터링하여 상태 변경 시 초기 데이터를 새로고침한다.
     * @param {Object} result wire 결과 객체
     * @return {void}
     */
    @wire(getRecord, { recordId: "$oppRecordId", fields: [ISCLOSED_FIELD, STAGENAME_FIELD] })
    wiredRecord(result) {
        this.wiredRecordResult = result;
        const { error, data } = result;

        if (data) {
            const currentIsClosed = getFieldValue(data, ISCLOSED_FIELD);
            if (this.previousIsClosed !== currentIsClosed) {
                this._isClosed = currentIsClosed;
                refreshApex(this.wiredInitDataResult);
                this.previousIsClosed = currentIsClosed;
            }
        } else if (error) {
            console.error("Error monitoring opportunity status:", error);
        }
    }

    @wire(MessageContext)
    messageContext;

    // Event Handlers

    /**
     * @description 현재 행을 편집 모드로 전환한다.
     * @return {void}
     */
    handleFieldEdit() {
        this.coBrokerRow = { ...this.coBrokerRow, isEditMode: true };
    }

    /**
     * @description Lookup 필드 변경 시 해당 값을 행 데이터에 반영한다.
     *              Co-broker 변경 시 Contact 값을 초기화한다.
     * @param {Event} event lookup change 이벤트
     * @return {void}
     */
    handleLookupChange(event) {
        const fieldName = event.detail.fieldName;

        let updatedData;
        if (fieldName === "CobrokerName_lk__c") {
            updatedData = {
                CobrokerName_lk__c: event.detail.value,
                CobrokerNameLabel: event.detail.label || "",
                CobrokerContact_lk__c: null,
                CobrokerContactLabel: ""
            };
        } else if (fieldName === "CobrokerContact_lk__c") {
            updatedData = {
                CobrokerContact_lk__c: event.detail.value,
                CobrokerContactLabel: event.detail.label || ""
            };
        }

        this.updateRowData(fieldName, updatedData);
    }

    /**
     * @description 숫자/문자 입력 필드 변경 시 값을 행 데이터에 반영한다.
     * @param {Event} event input change 이벤트
     * @return {void}
     */
    handleInputChange(event) {
        const field = event.target.dataset.field;
        let value = event.target.value;

        if (field === "SharingPct__c" || field === "LKAdminFeePct__c") {
            value = value ? parseFloat(value) : 0;
        }

        this.updateRowData(field, { [field]: value });
    }

    /**
     * @description Settlement Type 변경 시 Client 및 관련 값을 함께 반영한다.
     * @param {Event} event combobox change 이벤트
     * @return {void}
     */
    handleComboboxChange(event) {
        const field = event.detail.fieldName;
        const value = event.detail.value;

        if (field === "SettlementType__c") {
            const updates = { [field]: value };

            if (value === "Together") {
                updates.Client__c = true;
            } else if (value === "Separate") {
                if (this.coBrokerRow?.Client__c) {
                    updates.SharingPct__c = 0;
                }
            }

            this.updateRowData(field, updates);
        } else {
            this.updateRowData(field, { [field]: value });
        }
    }

    /**
     * @description Client 체크박스 변경 시 Client 및 SharingPct 값을 반영한다.
     * @param {Event} event checkbox change 이벤트
     * @return {void}
     */
    handleCheckboxFieldChange(event) {
        event.stopPropagation();
        const isChecked = event.target.checked;

        const updates = { Client__c: isChecked };

        if (this.coBrokerRow?.SettlementType__c === "Separate" && isChecked) {
            updates.SharingPct__c = 0;
        }

        this.updateRowData("Client__c", updates);
    }

    /**
     * @description 레코드 링크 클릭 시 새 탭으로 레코드 페이지를 연다.
     * @param {Event} event 클릭 이벤트
     * @return {void}
     */
    handleNavigateToRecord(event) {
        event.preventDefault();
        event.stopPropagation();
        const { recordId, objectApiName } = event.currentTarget.dataset;

        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: { objectApiName, recordId, actionName: "view" }
        })
            .then((url) => window.open(url, "_blank"))
            .catch((error) => console.error("handleNavigateToRecord error", error));
    }

    /**
     * @description 초기 데이터를 다시 조회하여 현재 행 데이터를 새로고침한다.
     * @return {Promise<void>}
     */
    async handleRefresh() {
        try {
            await refreshApex(this.wiredInitDataResult);
            this._applyRowData(this.wiredInitDataResult?.data?.coBrokerList || []);
        } catch (error) {
            toast("Error", "Error refreshing data: " + error.message, "error");
        }
    }

    /**
     * @description 저장 전 검증 후 기존 레코드 존재 여부에 따라 즉시 저장 또는 확인 모달을 표시한다.
     * @return {Promise<void>}
     */
    async handleSave() {
        if (!this._validateBeforeSave()) return;

        const hasChanges = this.coBrokerRow.dirtyFields?.size > 0;
        if (!hasChanges) {
            toast("Info", this.labels.changedError, "info");
            return;
        }

        try {
            const freshData = await refreshApex(this.wiredInitDataResult);
            const wireData = freshData || this.wiredInitDataResult?.data;

            if (wireData?.hasExisting) {
                this.existingRecords = wireData.existingRecords;
                this.showConfirmModal = true;
            } else {
                await this._executeSave(false);
            }
        } catch (error) {
            toast("Error", error.body?.message || "An error occurred", "error");
        }
    }

    /**
     * @description 현재 Producing Co-broking 레코드 삭제 확인 후 서버에서 삭제한다.
     * @return {Promise<void>}
     */
    async handleDeleteClick() {
        const confirmed = await LightningConfirm.open({
            message: this.labels.deleteConfirm + " : Producing",
            theme: "warning",
            label: "Confirm Delete"
        });

        if (!confirmed) return;

        try {
            await deleteCoBrokers({ coBrokerIds: [this.coBrokerRow.Id], oppId: this.isPlacementMode ? null : this.recordId, placementId: this.isPlacementMode ? this.recordId : null });
            toast("Success", this.labels.deleteSuccess, "success");
            this._fireCustomEvent("cobrokingrefresh", { recordId: this.recordId });
            await refreshApex(this.wiredInitDataResult);

            publish(this.messageContext, OPP_DATA_CHANGED, {
                opportunityId: this.recordId,
                action: "NEED_RECALCULATE"
            });
            console.log("Published NEED_RECALCULATE message for opportunityId:", this.recordId);
        } catch (error) {
            toast("Error", error.body?.message || "An error occurred", "error");
        }
    }

    /**
     * @description 대체 저장 확인 모달을 닫고 기존 레코드 목록을 초기화한다.
     * @return {void}
     */
    handleModalCancel() {
        this.showConfirmModal = false;
        this.existingRecords = [];
    }

    /**
     * @description 대체 저장 확인 후 기존 레코드를 대체하는 저장을 수행한다.
     * @return {Promise<void>}
     */
    async handleModalSave() {
        this.showConfirmModal = false;
        await this._executeSave(true);
    }

    /**
     * @description 외부 cobrokingrefresh 이벤트 수신 시 동일 recordId이면 데이터를 새로고침한다.
     * @param {CustomEvent} event 사용자 정의 이벤트
     * @return {void}
     */
    handleCobrokingRefreshEvent(event) {
        if (event.detail && event.detail.recordId === this.recordId) {
            console.log("OppProducingCoBrokingSingle - cobrokingrefresh event received");
            refreshApex(this.wiredInitDataResult);
        }
    }

    // Private Methods

    /**
     * @description 저장 공통 실행 메서드이다.
     *              일반 저장(replace=false)과 대체 저장(replace=true)을 공통 처리한다.
     * @param {Boolean} replace 기존 LK Co-broking 레코드 대체 여부
     * @return {Promise<void>}
     */
    async _executeSave(replace) {
        const needsRecalc = this.coBrokerRow?.dirtyFields?.has("SharingPct__c") || this.coBrokerRow?.dirtyFields?.has("LKAdminFeePct__c");

        const recordToSave = this._buildRecord();

        try {
            if (replace) {
                await saveWithReplace({
                    coBrokers: [recordToSave],
                    oppId: this.isPlacementMode ? null : this.recordId,
                    placementId: this.isPlacementMode ? this.recordId : null,
                    needsRecalculate: needsRecalc
                });
                this.existingRecords = [];
            } else {
                await saveCoBrokers({
                    coBrokers: [recordToSave],
                    oppId: this.isPlacementMode ? null : this.recordId,
                    placementId: this.isPlacementMode ? this.recordId : null,
                    needsRecalculate: needsRecalc
                });
            }

            toast("Success", this.labels.saveSuccess, "success");

            publish(this.messageContext, OPP_DATA_CHANGED, {
                opportunityId: this.recordId,
                action: "NEED_RECALCULATE"
            });
            console.log("Published NEED_RECALCULATE message for opportunityId:", this.recordId);

            const cleanRow = this.createRowData(this.coBrokerRow, false);
            this.originalData = JSON.parse(JSON.stringify(cleanRow));
            this.coBrokerRow = cleanRow;

            const title = recordToSave.SettlementType__c === "Separate" && recordToSave.Client__c === true ? "CI Detail" : "Market Line";

            this._fireCustomEvent("updatemarkettitle", { recordId: this.recordId, title });
            this._fireCustomEvent("cobrokingrefresh", { recordId: this.recordId });

            if (replace) {
                publish(this.messageContext, OPP_DATA_CHANGED, {
                    opportunityId: this.recordId,
                    entity: "CoBroker__c",
                    action: "REFRESH",
                    reason: "OppProducingCoBrokingSingle"
                });
            }

            await refreshApex(this.wiredInitDataResult);
        } catch (error) {
            toast("Error", error.body?.message || "An error occurred", "error");
        }
    }

    /**
     * @description 현재 단일 행 데이터를 Apex 저장용 오브젝트로 변환한다.
     * @return {Object} 저장용 Co-broker 레코드
     */
    _buildRecord() {
        return {
            Id: this.coBrokerRow.Id,
            CobrokerName_lk__c: this.coBrokerRow.CobrokerName_lk__c,
            CobrokerContact_lk__c: this.coBrokerRow.CobrokerContact_lk__c,
            SharingPct__c: this.coBrokerRow.SharingPct__c,
            LKAdminFeePct__c: this.coBrokerRow.LKAdminFeePct__c,
            SettlementType__c: this.coBrokerRow.SettlementType__c,
            Client__c: this.coBrokerRow.Client__c
        };
    }

    /**
     * @description 저장 전 필수 입력값을 검증하고 에러 스타일을 반영한다.
     * @return {Boolean} 검증 통과 여부
     */
    _validateBeforeSave() {
        const row = this.coBrokerRow;
        const updatedRow = { ...row };
        let hasError = false;

        if (!row.CobrokerName_lk__c) {
            updatedRow.CobrokerName_lk__cClass = "dirty-cell error-cell";
            hasError = true;
        } else {
            updatedRow.CobrokerName_lk__cClass = updatedRow.CobrokerName_lk__cClass?.replace(" error-cell", "").trim() || "";
        }

        if (!row.CobrokerContact_lk__c) {
            updatedRow.CobrokerContact_lk__cClass = "dirty-cell error-cell";
            hasError = true;
        } else {
            updatedRow.CobrokerContact_lk__cClass = updatedRow.CobrokerContact_lk__cClass?.replace(" error-cell", "").trim() || "";
        }

        if (!row.SettlementType__c) {
            updatedRow.SettlementType__cClass = "dirty-cell error-cell";
            hasError = true;
        } else {
            updatedRow.SettlementType__cClass = updatedRow.SettlementType__cClass?.replace(" error-cell", "").trim() || "";
        }

        this.coBrokerRow = updatedRow;

        if (hasError) {
            toast("Warning", "Please fill in all required fields: Co-broker name, Co-broker contact, Settlement Type.", "warning");
        }

        return !hasError;
    }

    /**
     * @description Apex coBrokerList 데이터를 단일 행 화면 데이터로 변환하여 적용한다.
     * @param {Array} records Apex에서 조회한 coBrokerList
     * @return {void}
     */
    _applyRowData(records) {
        if (records.length > 0) {
            this.coBrokerRow = this.createRowData(records[0]);
        } else {
            this.coBrokerRow = this.createRowData({
                Id: null,
                CobrokerName_lk__c: null,
                CobrokerContact_lk__c: null,
                SharingPct__c: 0,
                LKAdminFeePct__c: 0,
                SettlementType__c: "",
                Client__c: false
            });
        }
        this.originalData = JSON.parse(JSON.stringify(this.coBrokerRow));
    }

    /**
     * @description 퍼센트 값을 소수점 2자리 문자열로 포맷한다.
     * @param {Number|String} value 포맷 대상 값
     * @return {String} 포맷된 퍼센트 문자열
     */
    formatPercentage(value) {
        if (!value || isNaN(value)) return "0.00";
        return Number(value).toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    /**
     * @description SharingPct 값이 허용 범위 내에 있는지 검증한다.
     * @return {Boolean} 퍼센트 유효 여부
     */
    validatePercentageFields() {
        if (!this.coBrokerRow) return true;
        const sharingPct = parseFloat(this.coBrokerRow.SharingPct__c);
        return !isNaN(sharingPct) && sharingPct >= PERCENTAGE_MIN && sharingPct <= PERCENTAGE_MAX;
    }

    /**
     * @description 서버 레코드를 화면 단일 행 데이터 구조로 변환한다.
     * @param {Object} record 원본 Co-broker 레코드
     * @param {Boolean} isNew 신규 행 여부
     * @return {Object} 화면용 row 데이터
     */
    createRowData(record, isNew = false) {
        const dirtyFields = isNew ? new Set(["CobrokerName_lk__c", "CobrokerContact_lk__c", "SharingPct__c", "LKAdminFeePct__c", "SettlementType__c", "Client__c"]) : new Set();

        const rowData = {
            Id: record.Id,
            CobrokerName_lk__c: record.CobrokerName_lk__c,
            CobrokerNameLabel: record.CobrokerName_lk__r?.Name || "",
            CobrokerContact_lk__c: record.CobrokerContact_lk__c,
            CobrokerContactLabel: record.CobrokerContact_lk__r?.Name || "",
            SharingPct__c: this.formatPercentage(record.SharingPct__c) || 0.0,
            LKAdminFeePct__c: this.formatPercentage(record.LKAdminFeePct__c) || 0.0,
            SettlementType__c: record.SettlementType__c || "",
            Client__c: record.Client__c || false,
            dirtyFields: dirtyFields,
            isEditMode: isNew
        };

        rowData.CobrokerName_lk__cClass = dirtyFields.has("CobrokerName_lk__c") ? "dirty-cell" : "";
        rowData.CobrokerContact_lk__cClass = dirtyFields.has("CobrokerContact_lk__c") ? "dirty-cell" : "";
        rowData.SharingPct__cClass = dirtyFields.has("SharingPct__c") ? "dirty-cell" : "";
        rowData.LKAdminFeePct__cClass = dirtyFields.has("LKAdminFeePct__c") ? "dirty-cell" : "";
        rowData.SettlementType__cClass = dirtyFields.has("SettlementType__c") ? "dirty-cell" : "";
        rowData.Client__cClass = dirtyFields.has("Client__c") ? "dirty-cell" : "";

        rowData.isClientDisabled = rowData.SettlementType__c === "Together";
        rowData.isSharingDisabled = rowData.SettlementType__c === "Separate" && rowData.Client__c === true;

        return rowData;
    }

    /**
     * @description 변경 필드와 원본 값을 비교하여 dirty 상태 및 파생 상태를 갱신한다.
     * @param {String} changedField 변경된 필드명
     * @param {Object} updates 변경값 객체
     * @return {void}
     */
    updateRowData(changedField, updates) {
        const updatedRow = { ...this.coBrokerRow, ...updates };
        const original = this.originalData;

        if (original) {
            const dirtyFields = new Set(this.coBrokerRow.dirtyFields || []);

            let fieldsToCheck = Object.keys(updates);
            if (changedField === "CobrokerName_lk__c") {
                fieldsToCheck = [...new Set([...fieldsToCheck, "CobrokerName_lk__c", "CobrokerContact_lk__c"])];
            }

            fieldsToCheck.forEach((field) => {
                if (updatedRow[field] !== original[field]) {
                    dirtyFields.add(field);
                } else {
                    dirtyFields.delete(field);
                }
            });

            updatedRow.dirtyFields = dirtyFields;

            updatedRow.CobrokerName_lk__cClass = dirtyFields.has("CobrokerName_lk__c") ? "dirty-cell" : "";
            updatedRow.CobrokerContact_lk__cClass = dirtyFields.has("CobrokerContact_lk__c") ? "dirty-cell" : "";
            updatedRow.SharingPct__cClass = dirtyFields.has("SharingPct__c") ? "dirty-cell" : "";
            updatedRow.LKAdminFeePct__cClass = dirtyFields.has("LKAdminFeePct__c") ? "dirty-cell" : "";
            updatedRow.SettlementType__cClass = dirtyFields.has("SettlementType__c") ? "dirty-cell" : "";
            updatedRow.Client__cClass = dirtyFields.has("Client__c") ? "dirty-cell" : "";

            updatedRow.isClientDisabled = updatedRow.SettlementType__c === "Together";
            updatedRow.isSharingDisabled = updatedRow.SettlementType__c === "Separate" && updatedRow.Client__c === true;
        }

        this.coBrokerRow = updatedRow;
    }

    /**
     * @description bubbles/composed 옵션을 포함한 CustomEvent를 발행한다.
     * @param {String} eventName 이벤트명
     * @param {Object} detail 이벤트 상세 데이터
     * @return {void}
     */
    _fireCustomEvent(eventName, detail) {
        this.dispatchEvent(new CustomEvent(eventName, { bubbles: true, composed: true, detail }));
    }

    // Lifecycle Methods

    /**
     * @description 컴포넌트 초기화 시 숫자 input 정렬 스타일을 적용하고 이벤트 리스너를 등록한다.
     * @return {void}
     */
    connectedCallback() {
        if (this.init) return;
        this.init = true;

        const style = document.createElement("style");
        style.innerText = `.cus-lk-input-num-right input { text-align: right !important; }`;
        document.body.appendChild(style);

        this._boundHandleCobrokingRefreshEvent = this.handleCobrokingRefreshEvent.bind(this);
        window.addEventListener("cobrokingrefresh", this._boundHandleCobrokingRefreshEvent);
    }

    /**
     * @description 컴포넌트 제거 시 등록한 이벤트 리스너를 해제한다.
     * @return {void}
     */
    disconnectedCallback() {
        if (this._boundHandleCobrokingRefreshEvent) {
            window.removeEventListener("cobrokingrefresh", this._boundHandleCobrokingRefreshEvent);
        }
    }
}