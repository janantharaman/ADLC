/**********************************************************************************
 * @filename      : oppLKCoBroking.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-12-23 (월)
 * @group         :
 * @group-content :
 * @description   : LK Co-Broking LWC 컴포넌트
 *                  - Opportunity / Placement / Claim 컨텍스트에서 LK Co-Broking 데이터를 조회·편집·저장하고,
 *                  - 저장 전 Producing / Placing 충돌 여부를 검사하여 확인 모달을 표시하며,
 *                  - 삭제/복원/행 편집/Lookup 변경/체크박스 처리 및 LMS 이벤트 발행을 수행한다.
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
import USER_ID from "@salesforce/user/Id";
import USER_REGION_FIELD from "@salesforce/schema/User.Region__c";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

// LMS
import LightningConfirm from "lightning/confirm";
import { publish, MessageContext } from "lightning/messageService";
import OPP_DATA_CHANGED from "@salesforce/messageChannel/OPP_OpportunityDataChanged__c";

// Apex Methods
import getInitData from "@salesforce/apex/Opp_LkCoBroking_Ctrl.getInitData";
import saveCoBrokers from "@salesforce/apex/Opp_LkCoBroking_Ctrl.saveCoBrokers";
import deleteCoBrokers from "@salesforce/apex/Opp_LkCoBroking_Ctrl.deleteCoBrokers";
import checkPreSaveConflicts from "@salesforce/apex/Opp_LkCoBroking_Ctrl.checkPreSaveConflicts";
import resolvePreSaveConflicts from "@salesforce/apex/Opp_LkCoBroking_Ctrl.resolvePreSaveConflicts";
import getAccountInternalRegion from "@salesforce/apex/Opp_LkCoBroking_Ctrl.getAccountInternalRegion";

// Custom Labels
import LABEL_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import LABEL_CANCEL from "@salesforce/label/c.COM_BTN_CANCEL";
import OPP_MSG_TYPE_CLIENT from "@salesforce/label/c.OPP_MSG_TYPE_CLIENT";
import IPL_MSG_ChangedError from "@salesforce/label/c.IPL_MSG_ChangedError";
import OPP_MSG_COBROKER_LOAD_ERROR from "@salesforce/label/c.OPP_MSG_COBROKER_LOAD_ERROR";
import OPP_MSG_COBROKER_NAME from "@salesforce/label/c.OPP_MSG_COBROKER_NAME";
import OPP_MSG__SETTLEMENT_LOAD_ERROR from "@salesforce/label/c.OPP_MSG_SETTLEMENT_LOAD_ERROR";
import OPP_MSG__COBROKERTYPE_LOAD_ERROR from "@salesforce/label/c.OPP_MSG_COBROKERTYPE_LOAD_ERROR";
import OPP_MSG__COBROKER_DELETE_CONFIRM from "@salesforce/label/c.OPP_MSG_COBROKER_DELETE_CONFIRM";
import OPP_MSG_COBROKER_SAVE_SUCCESS from "@salesforce/label/c.OPP_MSG_COBROKER_SAVE_SUCCESS";
import OPP_MSG_COBROKER_DELETE_SUCCESS from "@salesforce/label/c.OPP_MSG_COBROKER_DELETE_SUCCESS";
import OPP_LBL_COBROKER_EXIST from "@salesforce/label/c.OPP_LBL_COBROKER_EXIST";

// Schema
import ISCLOSED_FIELD from "@salesforce/schema/Opportunity.IsClosed";
import COBROKER_OBJ from "@salesforce/schema/OPP_Cobroker__c";

export default class OppLKCoBroking extends NavigationMixin(LightningElement) {
    // Public Properties
    @api recordId;

    // Reactive Properties
    @track coBrokerList = [];
    @track settlementTypeOptions = [];
    @track cobrokerOptions = [];
    @track producingChecked = false;
    @track placingChecked = false;
    @track hasEditPermission = false;
    @track _isClosed = false;
    @track recordsToDelete = [];
    @track producingDisabled = false;
    @track isPlacementMode = false;
    @track isPlacementClosed = false;
    @track showConflictModal = false;
    @track producingConflicts = [];
    @track placingPanelConflicts = [];
    @track hasProducingConflicts = false;
    @track hasPlacingConflicts = false;

    // Private Properties
    isClaim = false;
    wiredInitDataResult;
    wiredRecordResult;
    rowCounter = 0;
    originalData = new Map();
    previousIsClosed = false;
    initialProducingChecked = false;
    initialPlacingChecked = false;
    objectFields;
    initialCoBrokerList = [];
    initialApexData = null;
    init = false;
    _currentUserRegion = null;

    // Custom Labels
    labels = {
        save: LABEL_SAVE,
        cancel: LABEL_CANCEL,
        typeClientMsg: OPP_MSG_TYPE_CLIENT,
        changedError: IPL_MSG_ChangedError,
        loadError: OPP_MSG_COBROKER_LOAD_ERROR,
        cobrokerNameError: OPP_MSG_COBROKER_NAME,
        settlementLoadError: OPP_MSG__SETTLEMENT_LOAD_ERROR,
        cobrokerTypeLoadError: OPP_MSG__COBROKERTYPE_LOAD_ERROR,
        deleteConfirm: OPP_MSG__COBROKER_DELETE_CONFIRM,
        saveSuccess: OPP_MSG_COBROKER_SAVE_SUCCESS,
        deleteSuccess: OPP_MSG_COBROKER_DELETE_SUCCESS,
        cobrokerExist: OPP_LBL_COBROKER_EXIST
    };

    // Getter / Setter
    // Claim 일 때 Default로 Section 접히게
    // get activeSectionName() {
    //     return this.isClaim ? "" : "lkCoBroking";
    // }

    get hasRecords() {
        return this.coBrokerList && this.coBrokerList.length > 0;
    }

    get isClosed() {
        return this._isClosed || this.isPlacementClosed;
    }

    get canEdit() {
        return this.hasEditPermission && !this.isClosed;
    }

    get showTable() {
        return true;
    }

    get cobrokingTypeLabel() {
        return this.objectFields?.CobrokingType__c?.label ?? "Co-Broking Type";
    }

    get cobrokerLabel() {
        return this.objectFields?.LKCobroker_lk__c?.label ?? "Co-broker";
    }

    get cobrokerLookupConfig() {
        const filters = [{ field: "LKInternalCompany_is__c", op: "EQ", value: true, type: "BOOLEAN" }];

        if (this._currentUserRegion) {
            const excludeKey = Object.keys(this._REGION_MAP).find((k) => this._REGION_MAP[k] === this._currentUserRegion);
            if (excludeKey) {
                filters.push({ field: "LKInternalRegion__c", op: "NE", value: excludeKey, type: "STRING" });
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

    _REGION_MAP = {
        LK_KR: "KR",
        LK_Re: "SG",
        LK_VN: "VN",
        "LK_A&G": "A&G"
    };

    get cobrokerNameLabel() {
        return this.objectFields?.CobrokerUser_lk__c?.label ?? "Co-broker name";
    }

    get settlementTypeLabel() {
        return this.objectFields?.SettlementType__c?.label ?? "Settlement Type";
    }

    get sharingPctLabel() {
        return this.objectFields?.SharingPct__c?.label ?? "Sharing(%)";
    }

    get clientLabel() {
        return this.objectFields?.Client__c?.label ?? "Client";
    }

    get hasClientColumn() {
        return this.coBrokerList.some((row) => row.CobrokingType__c === "Producing");
    }

    get isProducingDisabled() {
        return this.producingDisabled;
    }

    get isCancelDisabled() {
        const producingChanged = this.producingChecked !== this.initialProducingChecked;
        const placingChanged = this.placingChecked !== this.initialPlacingChecked;
        const listChanged = JSON.stringify(this.coBrokerList) !== JSON.stringify(this.initialCoBrokerList);
        return !(producingChanged || placingChanged || listChanged);
    }

    get isSaveDisabled() {
        return !this.canEdit;
    }

    get oppRecordId() {
        return this.recordId?.startsWith("006") ? this.recordId : null;
    }

    get showCard() {
        return !(this.isClaim && !this.hasRecords);
    }

    // Wire Methods

    /**
     * @description OPP_Cobroker__c Object Info를 조회하여 필드 라벨 정보를 세팅한다.
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
     * @description 초기 LK Co-Broking 데이터를 조회하여 화면 상태를 초기화한다.
     * @return {void}
     */
    @wire(getInitData, { recordId: "$recordId" })
    wiredInitData(result) {
        this.wiredInitDataResult = result;
        const { data, error } = result;

        if (data) {
            this.initialApexData = data;
            this.isPlacementMode = data.isPlacement || false;
            this.isClaim = data.isClaim || false;
            this.hasEditPermission = data.hasEditPermission || false;
            this.isPlacementClosed = this.isPlacementMode && data.placementClosingDate != null;
            this.settlementTypeOptions = data.settlementTypeOptions || [];
            this.cobrokerOptions = data.cobrokerOptions || [];
            this.producingDisabled = data.producingDisabled;
            this._applyListData(data);
        } else if (error) {
            toast("Error", this.labels.loadError, "error");
        }
    }

    /**
     * @description Opportunity 종료 여부를 감시하여 상태 변경 시 초기 데이터를 다시 조회한다.
     * @return {void}
     */
    @wire(getRecord, { recordId: "$oppRecordId", fields: [ISCLOSED_FIELD] })
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

    /**
     * @description 현재 로그인 사용자 Region 값을 조회하여 Lookup 필터 구성에 사용한다.
     * @return {void}
     */
    @wire(getRecord, { recordId: USER_ID, fields: [USER_REGION_FIELD] })
    wiredCurrentUser({ data, error }) {
        if (data) {
            this._currentUserRegion = getFieldValue(data, USER_REGION_FIELD);
        } else if (error) {
            console.error("Error loading current user region:", error);
        }
    }

    // Event Handlers

    /**
     * @description 행 단위 편집 아이콘 클릭 시 해당 행만 편집 모드로 전환한다.
     * @param {Event} event 클릭 이벤트
     * @return {void}
     */
    handleFieldEdit(event) {
        const rowKey = event.currentTarget.dataset.key;

        this.coBrokerList = this.coBrokerList.map((row) => {
            if (row.key === rowKey) {
                return { ...row, isEditMode: true };
            }
            return { ...row, isEditMode: false };
        });
    }

    /**
     * @description Producing 체크박스 변경 시 행 복원 또는 삭제 대상 표시를 수행한다.
     * @param {Event} event 체크박스 이벤트
     * @return {void}
     */
    handleProducingCheckbox(event) {
        const isChecked = event.target.checked;
        this.producingChecked = isChecked;

        if (isChecked) {
            this.restoreOrAddRow("Producing");
        } else {
            this.markForDeletion("Producing");
        }
    }

    /**
     * @description Placing 체크박스 변경 시 행 복원 또는 삭제 대상 표시를 수행한다.
     * @param {Event} event 체크박스 이벤트
     * @return {void}
     */
    handlePlacingCheckbox(event) {
        const isChecked = event.target.checked;
        this.placingChecked = isChecked;

        if (isChecked) {
            this.restoreOrAddRow("Placing");
        } else {
            this.markForDeletion("Placing");
        }
    }

    /**
     * @description Cancel 클릭 시 초기 Apex 조회 결과를 기준으로 화면 상태를 복원한다.
     * @return {void}
     */
    handleCancel() {
        if (this.initialApexData) {
            this._applyListData(this.initialApexData);
        }
    }

    /**
     * @description Lookup 변경 시 선택된 값과 라벨을 행 데이터에 반영한다.
     *              LKCobroker 변경 시 내부 Region을 조회하여 사용자 Lookup 필터도 재구성한다.
     * @param {Event} event Lookup 변경 이벤트
     * @return {void}
     */
    handleLookupChange(event) {
        const fieldName = event.detail.fieldName;
        const rowKey = event.currentTarget.dataset.key;

        let updatedRow;
        if (fieldName === "LKCobroker_lk__c") {
            updatedRow = {
                LKCobroker_lk__c: event.detail.value,
                LKCobrokerLabel: event.detail.label || ""
            };

            const accountId = event.detail.value;
            if (accountId) {
                getAccountInternalRegion({ accountId })
                    .then((region) => {
                        console.log("[LKCobroker] LKInternalRegion__c =", region);
                        this.updateRowData(rowKey, fieldName, {
                            ...updatedRow,
                            userLookupConfig: this._buildUserLookupConfig(region)
                        });
                    })
                    .catch((err) => {
                        console.error("[LKCobroker] getAccountInternalRegion error", err);
                        this.updateRowData(rowKey, fieldName, updatedRow);
                    });
                return;
            }
        } else {
            updatedRow = {
                CobrokerUser_lk__c: event.detail.value,
                CobrokerNameLabel: event.detail.label || ""
            };
        }

        this.updateRowData(rowKey, fieldName, updatedRow);
    }

    /**
     * @description Combobox 변경 시 행 데이터와 관련 파생값(Client, disabled 상태 등)을 갱신한다.
     * @param {Event} event Combobox 변경 이벤트
     * @return {void}
     */
    handleComboboxChange(event) {
        const field = event.target.dataset.field;
        const rowKey = event.target.dataset.key;
        const value = event.detail.value;

        const updates = { [field]: value };

        if (field === "SettlementType__c") {
            const row = this.coBrokerList.find((r) => r.key === rowKey);
            if (row && row.CobrokingType__c === "Producing") {
                if (value === "Together") {
                    updates.Client__c = true;
                    updates.isClientDisabled = true;
                } else if (value === "Separate") {
                    updates.Client__c = false;
                    updates.isClientDisabled = true;
                } else {
                    updates.isClientDisabled = false;
                }
            } else if (row && row.CobrokingType__c === "Placing") {
                if (value === "Together") {
                    updates.Client__c = false;
                    updates.isClientDisabled = true;
                } else {
                    updates.isClientDisabled = false;
                }
            }
        }

        this.updateRowData(rowKey, field, updates);
    }

    /**
     * @description 일반 입력값 변경 시 해당 필드를 행 데이터에 반영한다.
     * @param {Event} event 입력 이벤트
     * @return {void}
     */
    handleInputChange(event) {
        const field = event.target.dataset.field;
        const rowKey = event.target.dataset.key;
        const value = event.target.value;

        this.updateRowData(rowKey, field, { [field]: value });
    }

    /**
     * @description Client 체크박스 변경 시 해당 행의 Client 값을 갱신한다.
     * @param {Event} event 체크박스 이벤트
     * @return {void}
     */
    handleClientChange(event) {
        event.stopPropagation();
        const rowKey = event.target.dataset.key;
        const isChecked = event.target.checked;

        this.updateRowData(rowKey, "Client__c", { Client__c: isChecked });
    }

    /**
     * @description 레코드 링크 클릭 시 새 탭으로 해당 레코드 상세 페이지를 연다.
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
     * @description 충돌 확인 모달을 닫고 관련 상태값을 초기화한다.
     * @return {void}
     */
    handleModalCancel() {
        this.showConflictModal = false;
        this.producingConflicts = [];
        this.placingPanelConflicts = [];
        this.hasProducingConflicts = false;
        this.hasPlacingConflicts = false;
    }

    /**
     * @description 충돌 확인 모달에서 확인 시 충돌 데이터를 정리한 후 저장을 진행한다.
     * @return {Promise<void>}
     */
    async handleModalConfirm() {
        try {
            const resolveProducing = this.producingChecked === true && this.hasProducingConflicts === true;
            const resolvePlacing = this.placingChecked === true && this.hasPlacingConflicts === true;

            await resolvePreSaveConflicts({
                oppId: this.isPlacementMode ? null : this.recordId,
                placementId: this.isPlacementMode ? this.recordId : null,
                resolveProducing: resolveProducing,
                resolvePlacing: resolvePlacing
            });

            this.showConflictModal = false;

            await this._executeSave();

            if (resolveProducing) {
                this._fireCustomEvent("updatemarkettitle", { recordId: this.recordId, title: "Market Line" });
            }

            if (resolvePlacing) {
                publish(this.messageContext, OPP_DATA_CHANGED, {
                    opportunityId: this.recordId,
                    entity: "CoBroker__c",
                    action: "REFRESH",
                    reason: "OppLKCoBroking"
                });
            }
        } catch (error) {
            toast("Error", error?.body?.message || "An error occurred while resolving conflicts", "error");
        }
    }

    /**
     * @description 저장 전 유효성 및 충돌 여부를 검사한 후 실제 저장을 수행한다.
     * @return {Promise<void>}
     */
    async handleSave() {
        if (!this._validateBeforeSave()) return;

        const hasChanges = this.coBrokerList.some((row) => row.dirtyFields && row.dirtyFields.size > 0);
        if (!hasChanges && this.recordsToDelete.length === 0) {
            toast("Info", this.labels.changedError, "info");
            return;
        }

        try {
            const checkProducing = this.producingChecked === true;
            const checkPlacing = this.placingChecked === true;

            if (checkProducing || checkPlacing) {
                const conflictResult = await checkPreSaveConflicts({
                    oppId: this.isPlacementMode ? null : this.recordId,
                    placementId: this.isPlacementMode ? this.recordId : null,
                    checkProducing: checkProducing,
                    checkPlacing: checkPlacing
                });

                if (conflictResult?.hasAny) {
                    this.hasProducingConflicts = conflictResult.hasProducingConflicts;
                    this.hasPlacingConflicts = conflictResult.hasPlacingConflicts;
                    this.producingConflicts = conflictResult.producingConflicts || [];
                    this.placingPanelConflicts = conflictResult.placingPanelConflicts || [];
                    this.showConflictModal = true;
                    return;
                }
            }
        } catch (error) {
            toast("Error", error?.body?.message || "An error occurred while checking conflicts", "error");
            return;
        }

        await this._executeSave();
    }

    /**
     * @description 외부 cobrokingrefresh 이벤트 수신 시 초기 데이터를 다시 조회한다.
     * @param {CustomEvent} event 커스텀 이벤트
     * @return {void}
     */
    handleCobrokingRefreshEvent(event) {
        if (event.detail && event.detail.recordId === this.recordId) {
            console.log("OppLKCoBroking - cobrokingrefresh event received");
            refreshApex(this.wiredInitDataResult);
        }
    }

    /**
     * @description 외부 updatemarkettitle 이벤트 수신 시 Producing disabled 상태를 다시 조회한다.
     * @param {CustomEvent} event 커스텀 이벤트
     * @return {void}
     */
    handleUpdateMarketTitleEvent(event) {
        if (event.detail && event.detail.recordId === this.recordId) {
            console.log("OppLKCoBroking - updatemarkettitle event received, refreshing producing disabled status");
            refreshApex(this.wiredInitDataResult);
        }
    }

    // Private Methods

    /**
     * @description LK Region 값을 기준으로 사용자 Lookup 설정 객체를 생성한다.
     * @param {String} lkRegion LKInternalRegion__c 값
     * @return {Object} 사용자 Lookup 설정 객체
     */
    _buildUserLookupConfig(lkRegion) {
        const filters = [];
        const userRegion = lkRegion ? this._REGION_MAP[lkRegion] : null;
        if (userRegion) {
            filters.push({ field: "Region__c", op: "EQ", value: userRegion, type: "STRING" });
        }
        return {
            objectApiName: "User",
            labelField: "Name",
            orderByField: "Name",
            orderDir: "ASC",
            filters
        };
    }

    /**
     * @description 저장 공통 실행 메서드이다.
     *              버튼 저장(handleSave)과 모달 확인 저장(handleModalConfirm) 모두 이 메서드를 통해 처리한다.
     * @return {Promise<void>}
     */
    async _executeSave() {
        let producingDeleted = false;
        let placingDeleted = false;

        if (this.recordsToDelete.length > 0) {
            const deleteMessages = this.recordsToDelete.map((r) => r.CobrokingType__c).join(", ");
            const confirmed = await LightningConfirm.open({
                message: `${this.labels.deleteConfirm} : ${deleteMessages}`,
                theme: "warning",
                label: "Confirm Delete"
            });

            if (!confirmed) return;

            producingDeleted = this.recordsToDelete.some((r) => r.CobrokingType__c === "Producing");
            placingDeleted = this.recordsToDelete.some((r) => r.CobrokingType__c === "Placing");

            const idsToDelete = this.recordsToDelete.filter((r) => r.Id).map((r) => r.Id);
            if (idsToDelete.length > 0) {
                try {
                    await deleteCoBrokers({ coBrokerIds: idsToDelete, oppId: this.isPlacementMode ? null : this.recordId, placementId: this.isPlacementMode ? this.recordId : null });
                    toast("Success", this.labels.deleteSuccess, "success");
                } catch (error) {
                    toast("Error", error?.body?.message || "An error occurred while deleting", "error");
                    return;
                }
            }
        }

        const needsRecalc = this.coBrokerList.some((row) => row.dirtyFields?.has("SharingPct__c"));

        const recordsToSave = this._buildRecords();
        if (recordsToSave.length > 0) {
            try {
                await saveCoBrokers({
                    coBrokers: recordsToSave,
                    oppId: this.isPlacementMode ? null : this.recordId,
                    placementId: this.isPlacementMode ? this.recordId : null,
                    needsRecalculate: needsRecalc
                });
                toast("Success", this.labels.saveSuccess, "success");

                this.recordsToDelete = [];
                this.coBrokerList = this.coBrokerList.map((row) => {
                    const cleanRow = this.createRowData(row, row.key, false);
                    this.originalData.set(row.key, JSON.parse(JSON.stringify(cleanRow)));
                    return cleanRow;
                });
            } catch (error) {
                toast("Error", error?.body?.message || "An error occurred", "error");
                return;
            }
        }

        publish(this.messageContext, OPP_DATA_CHANGED, {
            opportunityId: this.recordId,
            action: "NEED_RECALCULATE"
        });
        console.log("Published NEED_RECALCULATE message for opportunityId:", this.recordId);

        await refreshApex(this.wiredInitDataResult);

        if (producingDeleted) {
            this._fireCustomEvent("updatemarkettitle", { recordId: this.recordId, title: "Market Line" });
        }

        if (placingDeleted) {
            publish(this.messageContext, OPP_DATA_CHANGED, {
                opportunityId: this.recordId,
                entity: "CoBroker__c",
                action: "REFRESH",
                reason: "OppLKCoBroking"
            });
        }

        this._fireCustomEvent("cobrokingrefresh", { recordId: this.recordId });
    }

    /**
     * @description 저장 전 필수 입력값(Co-broker, Co-broker name)을 검증한다.
     * @return {Boolean} 유효성 검증 통과 여부
     */
    _validateBeforeSave() {
        const emptyRows = [];

        this.coBrokerList = this.coBrokerList.map((row, index) => {
            const updatedRow = { ...row };
            let rowHasError = false;

            if (!row.LKCobroker_lk__c) {
                updatedRow.LKCobroker_lk__cClass = "dirty-cell error-cell";
                rowHasError = true;
            } else {
                updatedRow.LKCobroker_lk__cClass = updatedRow.LKCobroker_lk__cClass?.replace(" error-cell", "").trim() || "";
            }

            if (!row.CobrokerUser_lk__c) {
                updatedRow.CobrokerUser_lk__cClass = "dirty-cell error-cell";
                rowHasError = true;
            } else {
                updatedRow.CobrokerUser_lk__cClass = updatedRow.CobrokerUser_lk__cClass?.replace(" error-cell", "").trim() || "";
            }

            // if (!row.SettlementType__c) {
            //     updatedRow.SettlementType__cClass = "dirty-cell error-cell";
            //     rowHasError = true;
            // } else {
            //     updatedRow.SettlementType__cClass = updatedRow.SettlementType__cClass?.replace(" error-cell", "").trim() || "";
            // }

            if (rowHasError) emptyRows.push(index + 1);
            return updatedRow;
        });

        if (emptyRows.length > 0) {
            toast("Warning", `Co-broker, Co-broker name, and Settlement Type are required. Row(s): ${emptyRows.join(", ")}`, "warning");
            return false;
        }
        return true;
    }

    /**
     * @description 현재 coBrokerList를 Apex 저장용 오브젝트 배열로 변환한다.
     * @return {Array} 저장 대상 레코드 배열
     */
    _buildRecords() {
        return this.coBrokerList.map((row) => ({
            Id: row.Id,
            CobrokingType__c: row.CobrokingType__c,
            LKCobroker_lk__c: row.LKCobroker_lk__c,
            CobrokerUser_lk__c: row.CobrokerUser_lk__c,
            SettlementType__c: row.SettlementType__c,
            Client__c: row.Client__c || false,
            SharingPct__c: row.SharingPct__c ?? 0
        }));
    }

    /**
     * @description Apex 조회 데이터를 rowData 형태로 변환하여 화면 리스트와 초기 상태를 적용한다.
     * @param {Object} data getInitData 반환 데이터
     * @return {void}
     */
    _applyListData(data) {
        const producingExists = data.coBrokerList.some((r) => r.CobrokingType__c === "Producing");
        const placingExists = data.coBrokerList.some((r) => r.CobrokingType__c === "Placing");

        this.producingChecked = producingExists;
        this.placingChecked = placingExists;
        this.initialProducingChecked = producingExists;
        this.initialPlacingChecked = placingExists;

        const mappedList = data.coBrokerList.map((record) => {
            const key = record.Id || `new-${this.rowCounter++}`;
            const rowData = this.createRowData(record, key);
            this.originalData.set(key, JSON.parse(JSON.stringify(rowData)));
            return rowData;
        });
        this.coBrokerList = this.sortCoBrokerList(mappedList);
        this.initialCoBrokerList = JSON.parse(JSON.stringify(this.coBrokerList));
        this.recordsToDelete = [];
    }

    /**
     * @description bubbles/composed 옵션과 함께 CustomEvent를 발행한다.
     * @param {String} eventName 이벤트명
     * @param {Object} detail 이벤트 상세 데이터
     * @return {void}
     */
    _fireCustomEvent(eventName, detail) {
        this.dispatchEvent(new CustomEvent(eventName, { bubbles: true, composed: true, detail }));
    }

    /**
     * @description 퍼센트 값을 화면 표시용 문자열로 포맷한다.
     * @param {Number} value 퍼센트 값
     * @return {String} 포맷된 퍼센트 문자열
     */
    formatPercentage(value) {
        if (!value || isNaN(value)) {
            return "0.00";
        }
        return Number(value).toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    /**
     * @description Co-Broking Type 기준으로 Producing 행을 앞쪽에 오도록 정렬한다.
     * @param {Array} list 정렬 대상 리스트
     * @return {Array} 정렬된 리스트
     */
    sortCoBrokerList(list) {
        return [...list].sort((a, b) => {
            if (a.CobrokingType__c === "Producing" && b.CobrokingType__c === "Placing") return -1;
            if (a.CobrokingType__c === "Placing" && b.CobrokingType__c === "Producing") return 1;
            return 0;
        });
    }

    /**
     * @description 지정한 CobrokingType 행이 없으면 신규 행을 추가한다.
     * @param {String} cobrokingType Co-Broking Type
     * @return {void}
     */
    addRowIfNotExists(cobrokingType) {
        const exists = this.coBrokerList.some((row) => row.CobrokingType__c === cobrokingType);
        if (!exists) {
            const key = `new-${this.rowCounter++}`;
            const newRow = this.createRowData(
                {
                    Id: null,
                    CobrokingType__c: cobrokingType,
                    LKCobroker_lk__c: null,
                    CobrokerUser_lk__c: null,
                    SettlementType__c: "",
                    Client__c: false
                },
                key,
                true
            );

            this.originalData.set(key, JSON.parse(JSON.stringify(newRow)));
            this.coBrokerList = this.sortCoBrokerList([...this.coBrokerList, newRow]);
        }
    }

    /**
     * @description 지정한 CobrokingType 행을 리스트에서 제거하고 필요 시 삭제 대상에 추가한다.
     * @param {String} cobrokingType Co-Broking Type
     * @return {void}
     */
    markForDeletion(cobrokingType) {
        const rowToRemove = this.coBrokerList.find((row) => row.CobrokingType__c === cobrokingType);

        if (rowToRemove) {
            this.coBrokerList = this.coBrokerList.filter((row) => row.CobrokingType__c !== cobrokingType);

            if (rowToRemove.Id) {
                this.recordsToDelete.push(rowToRemove);
            } else {
                this.originalData.delete(rowToRemove.key);
            }
        }
    }

    /**
     * @description 삭제 대기 중인 행을 복원하거나, 없으면 신규 행을 추가한다.
     * @param {String} cobrokingType Co-Broking Type
     * @return {void}
     */
    restoreOrAddRow(cobrokingType) {
        const deletedRowIndex = this.recordsToDelete.findIndex((row) => row.CobrokingType__c === cobrokingType);

        if (deletedRowIndex !== -1) {
            const restoredRow = this.recordsToDelete[deletedRowIndex];
            this.recordsToDelete = this.recordsToDelete.filter((_, index) => index !== deletedRowIndex);
            this.coBrokerList = this.sortCoBrokerList([...this.coBrokerList, restoredRow]);
        } else {
            this.addRowIfNotExists(cobrokingType);
        }
    }

    /**
     * @description 원본 레코드를 화면용 rowData 객체로 변환한다.
     * @param {Object} record 원본 레코드
     * @param {String} key 행 식별 키
     * @param {Boolean} isNew 신규 행 여부
     * @return {Object} 화면용 rowData 객체
     */
    createRowData(record, key, isNew = false) {
        const dirtyFields = isNew ? new Set(["LKCobroker_lk__c", "CobrokerUser_lk__c", "SettlementType__c", "Client__c", "SharingPct__c"]) : new Set();

        const sharingPct = record.SharingPct__c ?? 0;
        const settlementType = record.SettlementType__c || "";
        const isProducing = record.CobrokingType__c === "Producing";
        const isPlacing = record.CobrokingType__c === "Placing";
        const isClientDisabled = isProducing && (settlementType === "Together" || settlementType === "Separate");

        // Placing이면 None + Separate만 표시, 그 외에는 전체 옵션
        // const rowSettlementOptions = isPlacing ? [{ label: "--None--", value: "" }, ...this.settlementTypeOptions.filter((opt) => opt.value === "Separate")] : this.settlementTypeOptions;

        const rowData = {
            key: key,
            Id: record.Id,
            CobrokingType__c: record.CobrokingType__c,
            LKCobroker_lk__c: record.LKCobroker_lk__c || null,
            LKCobrokerLabel: record.LKCobroker_lk__r?.Name || "",
            CobrokerUser_lk__c: record.CobrokerUser_lk__c,
            CobrokerNameLabel: record.CobrokerUser_lk__r?.Name || "",
            SettlementType__c: settlementType,
            Client__c: record.Client__c || false,
            SharingPct__c: sharingPct,
            formattedSharingPct: sharingPct != null ? this.formatPercentage(sharingPct) : 0.0,
            isProducing: isProducing,
            isPlacing: isPlacing,
            isClientDisabled: isClientDisabled,
            settlementTypeOptionsForRow: this.settlementTypeOptions,
            dirtyFields: dirtyFields,
            isEditMode: isNew,
            userLookupConfig: this._buildUserLookupConfig(null)
        };
        // settlementTypeOptionsForRow: rowSettlementOptions,

        rowData.CobrokingType__cClass = "readonly-cell";
        rowData.LKCobroker_lk__cClass = dirtyFields.has("LKCobroker_lk__c") ? "dirty-cell" : "";
        rowData.CobrokerUser_lk__cClass = dirtyFields.has("CobrokerUser_lk__c") ? "dirty-cell" : "";
        rowData.SettlementType__cClass = dirtyFields.has("SettlementType__c") ? "dirty-cell" : "";
        rowData.Client__cClass = dirtyFields.has("Client__c") ? "dirty-cell" : "";
        rowData.SharingPct__cClass = dirtyFields.has("SharingPct__c") ? "dirty-cell" : "";

        return rowData;
    }

    /**
     * @description 특정 행의 데이터를 갱신하고 dirty 상태 및 화면 표시 클래스를 재계산한다.
     * @param {String} rowKey 행 식별 키
     * @param {String} changedField 변경 필드명
     * @param {Object} updates 반영할 값
     * @return {void}
     */
    updateRowData(rowKey, changedField, updates) {
        this.coBrokerList = this.coBrokerList.map((row) => {
            if (row.key === rowKey) {
                const updatedRow = { ...row, ...updates };
                const original = this.originalData.get(rowKey);

                if (original) {
                    const dirtyFields = new Set(row.dirtyFields || []);

                    [changedField].forEach((field) => {
                        if (this.isFieldDirty(field, updatedRow, original)) {
                            dirtyFields.add(field);
                        } else {
                            dirtyFields.delete(field);
                        }
                    });

                    updatedRow.dirtyFields = dirtyFields;

                    updatedRow.LKCobroker_lk__cClass = dirtyFields.has("LKCobroker_lk__c") ? "dirty-cell" : "";
                    updatedRow.CobrokerUser_lk__cClass = dirtyFields.has("CobrokerUser_lk__c") ? "dirty-cell" : "";
                    updatedRow.SettlementType__cClass = dirtyFields.has("SettlementType__c") ? "dirty-cell" : "";
                    updatedRow.Client__cClass = dirtyFields.has("Client__c") ? "dirty-cell" : "";
                    updatedRow.SharingPct__cClass = dirtyFields.has("SharingPct__c") ? "dirty-cell" : "";

                    if (updates.SharingPct__c !== undefined) {
                        updatedRow.formattedSharingPct = updatedRow.SharingPct__c != null ? `${updatedRow.SharingPct__c}%` : "";
                    }
                }

                return updatedRow;
            }
            return row;
        });
    }

    /**
     * @description 특정 필드의 현재값과 원본값을 비교하여 dirty 여부를 반환한다.
     * @param {String} fieldName 필드명
     * @param {Object} current 현재 행 데이터
     * @param {Object} original 원본 행 데이터
     * @return {Boolean} dirty 여부
     */
    isFieldDirty(fieldName, current, original) {
        return current[fieldName] !== original[fieldName];
    }

    // Lifecycle Methods

    /**
     * @description 컴포넌트 초기화 시 외부 이벤트 리스너를 등록한다.
     * @return {void}
     */
    connectedCallback() {
        if (this.init) return;
        this.init = true;

        this._boundHandleCobrokingRefreshEvent = this.handleCobrokingRefreshEvent.bind(this);
        window.addEventListener("cobrokingrefresh", this._boundHandleCobrokingRefreshEvent);

        this._boundHandleUpdateMarketTitleEvent = this.handleUpdateMarketTitleEvent.bind(this);
        window.addEventListener("updatemarkettitle", this._boundHandleUpdateMarketTitleEvent);
    }

    /**
     * @description 컴포넌트 제거 시 등록한 외부 이벤트 리스너를 해제한다.
     * @return {void}
     */
    disconnectedCallback() {
        if (this._boundHandleCobrokingRefreshEvent) {
            window.removeEventListener("cobrokingrefresh", this._boundHandleCobrokingRefreshEvent);
        }
        if (this._boundHandleUpdateMarketTitleEvent) {
            window.removeEventListener("updatemarkettitle", this._boundHandleUpdateMarketTitleEvent);
        }
    }
}