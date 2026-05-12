/**********************************************************************************
 * @filename      : oppPremiumFromCedent.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-12-10 (수)
 * @description   : Premium From Cedent Component - Payment Type & Installs Only
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2025-12-09      i2max              Create
 **********************************************************************************/
import { LightningElement, api, wire, track } from "lwc";
import { getCurrencyScale, toast } from "c/com";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

// LMS
import { publish, MessageContext } from "lightning/messageService";
import OPP_DATA_CHANGED from "@salesforce/messageChannel/OPP_OpportunityDataChanged__c";

// Platform Event
import { subscribe, unsubscribe, onError } from "lightning/empApi";
const PANEL_CHANGED_CHANNEL = "/event/Panel_Record_Changed__e";

// Custom Labels
import LABEL_CANCEL from "@salesforce/label/c.COM_BTN_CANCEL";
import LABEL_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import COM_BTN_EDIT from "@salesforce/label/c.COM_BTN_EDIT";
import COM_BTN_SCHEDULE from "@salesforce/label/c.COM_BTN_SCHEDULE";
import COM_BTN_CONFIRM from "@salesforce/label/c.COM_BTN_CONFIRM";
import OPP_MSG_PREMIUM_VALID_ERROR from "@salesforce/label/c.OPP_MSG_PREMIUM_VALID_ERROR";
import OPP_MSG_PAYMENT_TYPE_REQUIRED from "@salesforce/label/c.OPP_MSG_PAYMENT_TYPE_REQUIRED";
import OPP_MSG_PAYMENT_SAVE_SUCCESS from "@salesforce/label/c.OPP_MSG_PAYMENT_SAVE_SUCCESS";
import OPP_MSG_PREMIUM_SAVE_SUCCESS from "@salesforce/label/c.OPP_MSG_PREMIUM_SAVE_SUCCESS";
import OPP_MSG_PAYMENT_INFO_CHANGED from "@salesforce/label/c.OPP_MSG_PAYMENT_INFO_CHANGED";

// Apex Methods
import getInitData from "@salesforce/apex/Opp_PremiumFromCedent_Ctrl.getInitData";
import updatePaymentInfo from "@salesforce/apex/Opp_PremiumFromCedent_Ctrl.updatePaymentInfo";
import getSOAChangePreview from "@salesforce/apex/Opp_PremiumFromCedent_Ctrl.getSOAChangePreview";

// Schema
import OPP_OBJECT from "@salesforce/schema/Opportunity";

// Constants
const PAYMENT_TYPE_INSTALL = "Install";
const PAYMENT_TYPE_SINGLE = "Single";
const PAYMENT_TYPE_SOA = "SOA";
const MIN_INSTALLS = 2;

const TOAST_VARIANT = {
    SUCCESS: "success",
    ERROR: "error",
    WARNING: "warning",
    INFO: "info"
};

const MESSAGES = {
    ERROR_INSTALLS_MIN: `# of Installs must be at least ${MIN_INSTALLS}`
};

export default class OppPremiumFromCedent extends LightningElement {
    // ========== API 속성 ==========
    _recordId;
    _selectedCurrency;

    @api hasCIDetail = false;

    @api
    get recordId() {
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
        this.loadData();
    }

    @api
    get selectedCurrency() {
        return this._selectedCurrency;
    }
    set selectedCurrency(value) {
        this._selectedCurrency = value;
        this.loadData();
    }

    // ========== 추적 속성 (반응형) ==========
    @track paymentType;
    @track totalInstalls;
    @track grossPrem = null;
    @track errorMessage;
    @track paymentTypeOptions = [];
    @track showScheduleModal = false;
    @track showSoaConfirmModal = false;
    @track installsWarningMessage = "";
    @track isEditMode = false;
    @track hasEditPermission = false;
    @track isPlacementMode = false;
    @track isClosed = false;

    // SOA 변경 미리보기 데이터
    soaPreviewToUpdate = [];
    soaPreviewToDelete = [];

    // ========== Private 속성 ==========
    savedScheduleCount = 0;
    originalData = {};
    fieldErrors = {};
    objectFields;
    transactionType;
    cedingType;
    tsiGrossPremSum = null;
    _panelEventSubscription = null;

    // ========== Custom Labels ==========
    labels = {
        save: LABEL_SAVE,
        cancel: LABEL_CANCEL,
        edit: COM_BTN_EDIT,
        schedule: COM_BTN_SCHEDULE,
        confirm: COM_BTN_CONFIRM,
        premiumValidError: OPP_MSG_PREMIUM_VALID_ERROR,
        paymentTypeRequired: OPP_MSG_PAYMENT_TYPE_REQUIRED,
        paymentSaveSuccess: OPP_MSG_PAYMENT_SAVE_SUCCESS,
        premiumSaveSuccess: OPP_MSG_PREMIUM_SAVE_SUCCESS,
        paymentInfoChanged: OPP_MSG_PAYMENT_INFO_CHANGED
    };

    // ========== Getter/Setter ==========
    get isInstallType() {
        return this.paymentType === PAYMENT_TYPE_INSTALL;
    }

    get isNotInstallType() {
        return !this.isInstallType;
    }

    get isSingleOrSOAType() {
        return this.paymentType === PAYMENT_TYPE_SINGLE || this.paymentType === PAYMENT_TYPE_SOA;
    }

    get isScheduleButtonDisabled() {
        return this.isNotInstallType || !this.totalInstalls || this.totalInstalls < MIN_INSTALLS;
    }

    get isTotalInstallsReadonly() {
        return this.isSingleOrSOAType;
    }

    get displayTotalInstalls() {
        if (this.isSingleOrSOAType) {
            return null;
        }
        return this.totalInstalls;
    }

    get isSaveDisabled() {
        return !this.isEditMode || this.hasValidationErrors() || (this.isInstallType && this.totalInstalls !== this.savedScheduleCount);
    }

    get showEditIcon() {
        return this.hasEditPermission && !this.isEditMode && !this.isClosed;
    }

    get showActionButtons() {
        return this.isEditMode && !this.isClosed;
    }

    get paymentTypeDisplayValue() {
        if (!this.paymentType) return "";
        const option = this.paymentTypeOptions.find((opt) => opt.value === this.paymentType);
        return option ? option.label : this.paymentType;
    }

    get isDeclaration() {
        return this.transactionType === "Declaration";
    }
    get isTreaty() {
        return this.cedingType === "Treaty";
    }

    get isCIDetail() {
        return this.hasCIDetail === true;
    }

    get isPlacementDeclaration() {
        return this.isPlacementMode && this.isDeclaration;
    }

    get showGrossPremEditIcon() {
        console.log("Checking gross prem edit icon visibility");
        console.log("isDeclaration:", this.isDeclaration);
        console.log("isTreaty:", this.isTreaty);
        console.log("isCIDetail:", this.isCIDetail);

        return this.showEditIcon && (this.isDeclaration || this.isTreaty || this.isCIDetail) && !this.isEditMode;
    }

    get isGrossPremEditable() {
        return (this.isDeclaration || this.isTreaty || this.isCIDetail) && this.isEditMode;
    }

    get grossPremDisplayValue() {
        const val = this.isDeclaration || this.isTreaty || this.isCIDetail ? this.grossPrem : this.tsiGrossPremSum;
        if (val == null) return "";
        const scale = getCurrencyScale(this.selectedCurrency, 2);
        return Number(val).toLocaleString("en-US", {
            minimumFractionDigits: scale,
            maximumFractionDigits: scale
        });
    }

    get grossPremLabel() {
        return "Gross Prem(DP Applied)";
    }

    get paymentTypeLabel() {
        return this.objectFields?.PaymentType__c?.label ?? "Payment Type";
    }

    get totalInstallsLabel() {
        return this.objectFields?.TotalInstalls__c?.label ?? "# of installs";
    }

    // ========== Wire 메서드 ==========
    @wire(MessageContext)
    messageContext;

    @wire(getObjectInfo, { objectApiName: OPP_OBJECT })
    wiredObjectInfo({ data, error }) {
        if (data?.fields) {
            this.objectFields = data.fields;
        } else if (error) {
            this.objectFields = null;
            console.error("Error loading object info:", error);
        }
    }

    async loadData() {
        if (!this._recordId || !this._selectedCurrency) return;
        try {
            const data = await getInitData({ recordId: this._recordId, curr: this._selectedCurrency });
            this.isPlacementMode = data.isPlacement || false;
            this.hasEditPermission = data.hasEditPermission || false;
            this.paymentTypeOptions = data.paymentTypeOptions;
            this.paymentType = data.paymentType;
            this.totalInstalls = data.totalInstalls;
            this.savedScheduleCount = data.totalInstalls || 0;
            this.grossPrem = data.grossPrem ?? null;
            this.tsiGrossPremSum = data.tsiGrossPremSum ?? null;
            this.transactionType = data.transactionType || null;
            this.cedingType = data.cedingType || null;
            this.isClosed = data.isClosed || false;

            // Declaration 타입이고 paymentType이 없으면 SOA 자동 설정
            if (this.transactionType === "Declaration" && !this.paymentType) {
                this.paymentType = PAYMENT_TYPE_SOA;
            }

            this.errorMessage = null;
            this.saveOriginalData();
            this.checkInstallsMatch();
        } catch (error) {
            this.handleWireError("Error loading payment info", error);
        }
    }

    // ========== 이벤트 핸들러 ==========
    handleEditClick() {
        this.isEditMode = true;
        this.saveOriginalData();
        this.clearFieldErrors();
    }

    handleCancelEdit() {
        this.isEditMode = false;
        this.restoreOriginalData();
        this.clearWarningMessage();
        this.clearFieldErrors();
    }

    handlePaymentTypeChange(event) {
        this.paymentType = event.target.value;
        this.validateRequiredField("paymentType", this.paymentType);

        if (this.isNotInstallType) {
            this.totalInstalls = null;
            this.clearWarningMessage();
            delete this.fieldErrors.totalInstalls;
        } else if (this.originalData.paymentType === PAYMENT_TYPE_INSTALL) {
            this.totalInstalls = this.originalData.totalInstalls;
        }

        this.updateWarningMessageForPaymentType();
    }

    handleTotalInstallsChange(event) {
        if (this.isSingleOrSOAType) return;

        this.totalInstalls = parseInt(event.target.value, 10) || 0;

        const isValid = this.validateInstallsField();
        if (!isValid) return;

        this.checkInstallsMatch();
    }

    handleGrossPremChange(event) {
        this.grossPrem = event.target.value ? parseFloat(event.target.value) : null;
    }

    handleScheduleClick() {
        this.showScheduleModal = true;
    }

    handleCloseModal() {
        this.showScheduleModal = false;
    }

    async handleScheduleSaved(event) {
        this.showScheduleModal = false;

        if (event.detail && event.detail.updatedInstalls !== undefined) {
            this.totalInstalls = event.detail.updatedInstalls;
            this.savedScheduleCount = event.detail.updatedInstalls;
        }

        toast("Success", this.labels.premiumSaveSuccess, TOAST_VARIANT.SUCCESS);
        await this.loadData();
        this.clearWarningMessage();
    }

    async handleSave() {
        try {
            if (!this.validateAllFieldsBeforeSave()) {
                toast("Error", this.labels.premiumValidError, TOAST_VARIANT.ERROR);
                return;
            }

            // SOA로 변경되는 경우 (기존이 SOA가 아니었을 때) 미리보기 모달 표시
            const isChangingToSOA = this.paymentType === PAYMENT_TYPE_SOA && this.originalData.paymentType !== PAYMENT_TYPE_SOA;

            if (isChangingToSOA) {
                const preview = await getSOAChangePreview({
                    recordId: this.recordId,
                    curr: this.selectedCurrency
                });
                const hasRecords = (preview.toUpdate && preview.toUpdate.length > 0) || (preview.toDelete && preview.toDelete.length > 0);
                if (hasRecords) {
                    this.soaPreviewToUpdate = preview.toUpdate || [];
                    this.soaPreviewToDelete = preview.toDelete || [];
                    this.showSoaConfirmModal = true;
                    return; // 사용자 확인 대기
                }
            }

            await this._doSave();
        } catch (error) {
            this.handleSaveError(error);
        }
    }

    handleSoaConfirmModalConfirm() {
        this.showSoaConfirmModal = false;
        this._doSave();
    }

    handleSoaConfirmModalCancel() {
        this.showSoaConfirmModal = false;
    }

    async _doSave() {
        try {
            const grossPremChanged = (this.isDeclaration || this.isTreaty || this.isCIDetail) && this.grossPrem !== this.originalData.grossPrem;

            await updatePaymentInfo({
                recordId: this.recordId,
                curr: this.selectedCurrency,
                paymentType: this.paymentType,
                grossPrem: this.grossPrem,
                hasCIDetail: this.hasCIDetail
            });

            if (grossPremChanged) {
                publish(this.messageContext, OPP_DATA_CHANGED, {
                    opportunityId: this.recordId,
                    action: "NEED_RECALCULATE"
                });
            }

            await this.loadData();
            this.handleSuccessfulSave(this.labels.paymentSaveSuccess);
        } catch (error) {
            this.handleSaveError(error);
        }
    }

    // ========== Private 메서드 ==========
    saveOriginalData() {
        this.originalData = {
            paymentType: this.paymentType,
            totalInstalls: this.totalInstalls,
            grossPrem: this.grossPrem
        };
    }

    restoreOriginalData() {
        this.paymentType = this.originalData.paymentType;
        this.totalInstalls = this.originalData.totalInstalls;
        this.grossPrem = this.originalData.grossPrem;
    }

    checkInstallsMatch() {
        if (this.isInstallType && (this.totalInstalls ?? 0) !== this.savedScheduleCount) {
            this.installsWarningMessage = this.labels.paymentInfoChanged;
        } else {
            this.clearWarningMessage();
        }
    }

    updateWarningMessageForPaymentType() {
        if (this.isNotInstallType) {
            this.clearWarningMessage();
        } else {
            this.checkInstallsMatch();
        }
    }

    clearWarningMessage() {
        this.installsWarningMessage = "";
    }

    validateRequiredField(fieldName, value) {
        if (!value || (typeof value === "string" && value.trim() === "")) {
            this.fieldErrors[fieldName] = this.labels.paymentTypeRequired;
            return false;
        }
        delete this.fieldErrors[fieldName];
        return true;
    }

    validateInstallsField() {
        if (this.isSingleOrSOAType) {
            delete this.fieldErrors.totalInstalls;
            return true;
        }

        if (!this.isInstallType) {
            delete this.fieldErrors.totalInstalls;
            return true;
        }

        if (!this.totalInstalls || this.totalInstalls < MIN_INSTALLS) {
            this.fieldErrors.totalInstalls = MESSAGES.ERROR_INSTALLS_MIN;
            this.installsWarningMessage = MESSAGES.ERROR_INSTALLS_MIN;
            return false;
        }

        delete this.fieldErrors.totalInstalls;
        return true;
    }

    validateAllFieldsBeforeSave() {
        this.clearFieldErrors();
        const isPaymentTypeValid = this.validateRequiredField("paymentType", this.paymentType);
        const isInstallsValid = this.validateInstallsField();
        return isPaymentTypeValid && isInstallsValid;
    }

    hasValidationErrors() {
        return Object.keys(this.fieldErrors).length > 0;
    }

    clearFieldErrors() {
        this.fieldErrors = {};
    }

    handleSuccessfulSave(result) {
        toast("Success", result, TOAST_VARIANT.SUCCESS);
        this.errorMessage = null;
        this.isEditMode = false;
        this.clearWarningMessage();
        this.clearFieldErrors();
        publish(this.messageContext, OPP_DATA_CHANGED, {
            opportunityId: this.recordId,
            action: "REFRESH"
        });
    }

    handleSaveError(error) {
        this.errorMessage = "Error saving record: " + this.reduceErrors(error);
        toast("Error", this.errorMessage, TOAST_VARIANT.ERROR);
    }

    handleWireError(message, error) {
        this.errorMessage = message + ": " + this.reduceErrors(error);
        toast("Error", this.errorMessage, TOAST_VARIANT.ERROR);
    }

    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }

        return errors
            .filter((error) => !!error)
            .map((error) => {
                if (Array.isArray(error.body)) {
                    return error.body.map((e) => e.message);
                } else if (error.body && typeof error.body.message === "string") {
                    return error.body.message;
                } else if (typeof error.message === "string") {
                    return error.message;
                }
                return JSON.stringify(error);
            })
            .reduce((prev, curr) => prev.concat(curr), [])
            .filter((message, index, self) => self.indexOf(message) === index)
            .join(", ");
    }

    _subscribeToPanelEvent() {
        onError((error) => console.error("EMP API error:", JSON.stringify(error)));
        subscribe(PANEL_CHANGED_CHANNEL, -1, (event) => {
            const payload = event?.data?.payload;
            console.log("Received panel change event:", payload);
            if (payload?.Record_Id__c === this._recordId && payload?.Currency__c === this._selectedCurrency) {
                this.loadData();
            }
        }).then((subscription) => {
            this._panelEventSubscription = subscription;
        });
    }

    _unsubscribeFromPanelEvent() {
        if (!this._panelEventSubscription) return;
        unsubscribe(this._panelEventSubscription, () => {
            this._panelEventSubscription = null;
        });
    }

    // ========== 라이프사이클 메서드 ==========
    connectedCallback() {
        if (this.init) return;
        this.init = true;
        const style = document.createElement("style");
        style.innerText = `.cus-lk-input-num-right input { text-align: right !important; }`;
        document.body.appendChild(style);
        this._subscribeToPanelEvent();
    }

    disconnectedCallback() {
        this._unsubscribeFromPanelEvent();
    }
}