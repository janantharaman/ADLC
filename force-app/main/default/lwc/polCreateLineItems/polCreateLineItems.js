/**********************************************************************************
 * @filename      : polCreateLineItems.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-18 (수)
 * @group         :
 * @group-content :
 * @description   : InsurancePolicy 레코드 기준 Line Item 생성 Quick Action LWC 컴포넌트
 *                  - Step 0에서 생성 방식 및 Policy 기본 정보를 입력하고,
 *                  - Step 1에서 Participants 또는 Co-Broking 데이터를 입력하며,
 *                  - Step 2에서 Premium Installment를 관리하고,
 *                  - Step 3에서 생성 결과를 검토 및 저장한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-18       i2max             Create
 **********************************************************************************/

// LWC
import { LightningElement, api, track, wire } from "lwc";

// Navigation / UI API
import { NavigationMixin } from "lightning/navigation";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

// Common Utils
import { toast, getCurrencyScale, scaleToStep } from "c/com";

// Apex Methods
import getInitData from "@salesforce/apex/POL_CreateLineItems_Ctrl.getInitData";
import getParticipants from "@salesforce/apex/POL_CreateLineItems_Ctrl.getParticipants";
import saveParticipants from "@salesforce/apex/POL_CreateLineItems_Ctrl.saveParticipants";
import getInsurerCommission from "@salesforce/apex/POL_CreateLineItems_Ctrl.getInsurerCommission";
import upsertSchedules from "@salesforce/apex/POL_CreateLineItems_Ctrl.upsertSchedules";
import runPolicyLineItemFlow from "@salesforce/apex/POL_CreateLineItems_Ctrl.runPolicyLineItemFlow";
import getReviewData from "@salesforce/apex/POL_CreateLineItems_Ctrl.getReviewData";
import saveLineItems from "@salesforce/apex/POL_CreateLineItems_Ctrl.saveLineItems";
import updatePolicyInfo from "@salesforce/apex/POL_CreateLineItems_Ctrl.updatePolicyInfo";
import getSchedules from "@salesforce/apex/POL_CreateLineItems_Ctrl.getSchedules";
import getWritingCarrierCommission from "@salesforce/apex/POL_CreateLineItems_Ctrl.getWritingCarrierCommission";
import updatePolicyBrokerageInfo from "@salesforce/apex/POL_CreateLineItems_Ctrl.updatePolicyBrokerageInfo";
import updateParticipantsCommission from "@salesforce/apex/POL_CreateLineItems_Ctrl.updateParticipantsCommission";
import updateAllParticipantsCommission from "@salesforce/apex/POL_CreateLineItems_Ctrl.updateAllParticipantsCommission";
import getExistingExpDates from "@salesforce/apex/POL_CreateLineItems_Ctrl.getExistingExpDates";
import getCoBrokingInitData from "@salesforce/apex/POL_CreateLineItems_Ctrl.getCoBrokingInitData";
import saveCoBrokingParticipants from "@salesforce/apex/POL_CreateLineItems_Ctrl.saveCoBrokingParticipants";
import runCoBrokingLineItemFlow from "@salesforce/apex/POL_CreateLineItems_Ctrl.runCoBrokingLineItemFlow";
import getCoBrokingReviewData from "@salesforce/apex/POL_CreateLineItems_Ctrl.getCoBrokingReviewData";
import saveCoBrokingLineItems from "@salesforce/apex/POL_CreateLineItems_Ctrl.saveCoBrokingLineItems";
import getExistingCoBrokingExpDates from "@salesforce/apex/POL_CreateLineItems_Ctrl.getExistingCoBrokingExpDates";

// Custom Labels
import LABEL_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import LABEL_CANCEL from "@salesforce/label/c.COM_BTN_CANCEL";
import COM_BTN_ADD from "@salesforce/label/c.COM_BTN_ADD";
import POL_LBL_SELECT_ACTION from "@salesforce/label/c.POL_LBL_SELECT_ACTION";
import POL_BTN_CREATE_LINEITEM from "@salesforce/label/c.POL_BTN_CREATE_LINEITEM";
import POL_BTN_ADD_INSTALL from "@salesforce/label/c.POL_BTN_ADD_INSTALL";
import POL_BTN_PREV from "@salesforce/label/c.POL_BTN_PREV";
import POL_MSG_EXCHANGERATE from "@salesforce/label/c.POL_MSG_EXCHANGERATE";
import POL_BTN_NEXT from "@salesforce/label/c.POL_BTN_NEXT";
import POL_MSG_SIGNEDLINE_MATCH from "@salesforce/label/c.POL_MSG_SIGNEDLINE_MATCH";
import POL_MSG_REQUIRE_FIELD from "@salesforce/label/c.POL_MSG_REQUIRE_FIELD";
import POL_MSG_EXIST_INSURE from "@salesforce/label/c.POL_MSG_EXIST_INSURE";
import POL_MSG_PART_SAVE_SUCCESS from "@salesforce/label/c.POL_MSG_PART_SAVE_SUCCESS";
import POL_MSG_DATE_FORMAT from "@salesforce/label/c.POL_MSG_DATE_FORMAT";
import POL_MSG_PS_SAVE_SUCCESS from "@salesforce/label/c.POL_MSG_PS_SAVE_SUCCESS";
import POL_MSG_LINEITEM_SAVE_SUCCESS from "@salesforce/label/c.POL_MSG_LINEITEM_SAVE_SUCCESS";
import POL_MSG_DATE from "@salesforce/label/c.POL_MSG_DATE";

// Schema
import POL_OBJ from "@salesforce/schema/InsurancePolicy";
import PARTICIPANT_OBJ from "@salesforce/schema/InsurancePolicyParticipant";
import SCHEDULE_OBJ from "@salesforce/schema/OPP_PremiumSchedule__c";
import POLLINEITEM_OBJ from "@salesforce/schema/InsurancePolicyLineItem__c";

// Constants
const STEP0 = "step0";
const STEP1 = "step1";
const STEP1_PREMIUM = "step1_premium";
const STEP1_COBROKING = "step1_cobroking";
const STEP2 = "step2";
const STEP3 = "step3";

const INSURER_LOOKUP_CONFIG = {
    objectApiName: "Account",
    labelField: "Name",
    orderByField: "Name",
    orderDir: "ASC",
    filters: [{ field: "isInsurerAcc__c", op: "=", value: true, type: "boolean" }]
};

const COBROKER_LOOKUP_CONFIG = {
    objectApiName: "Account",
    labelField: "Name",
    orderByField: "Name",
    orderDir: "ASC",
    filters: [{ field: "isBrokerAcc__c", op: "=", value: true, type: "boolean" }]
};

export default class PolCreateLineItems extends NavigationMixin(LightningElement) {
    // Public Properties
    @api objectApiName;

    _recordId;

    @api
    get recordId() {
        return this._recordId;
    }

    set recordId(value) {
        this._recordId = value;
        if (value) this._loadInitData();
    }

    // Reactive Properties
    @track currentStep = STEP0;
    @track selectedAction = "Prem";
    @track hasStepError = false;
    @track isLoading = false;
    @track allRows = [];
    @track scheduleRows = [];
    @track reviewPolicyInfo = { totalPremiumAmount: 0, totalInstalment: 0 };
    @track reviewSections = [];
    @track coBrokingReviewSections = [];
    @track policyForm = {
        incomeClass: "",
        insurerPolicyNo: "",
        identificationValue: "",
        totalPremiumAmount: null,
        curr: "",
        totalInstalment: null,
        exchangeRate: null
    };

    // Private Properties
    _stepOrder = [STEP1, STEP2, STEP3];
    _rowSeq = 0;
    _isDirty = false;
    _isSaved = false;
    _originalRows = [];
    _deletedIds = [];
    _deletedScheduleIds = [];
    _policyTotalPremium = 0;
    _policyTotalInstalment = 0;
    _policyBrokerageAmt = 0;
    _policyBrokerageRate = 0;
    _policyWritingCarrierName = "";
    _policyCurrency = "";
    @track _insurerCommission = null;
    _participantFields = null;
    _scheduleFields = null;
    _incomeClassOptions = [];
    _currencyOptions = [];

    // CoBroking 상태
    @track coBrokingRows = [];
    _coBrokingDeletedIds = [];
    _isCoBrokingSaved = false;
    _isCoBrokingDirty = false;
    _insurerOptions = [];
    _coBrokingTypeOptions = [];
    _coBrokingCurrencyOptions = [];

    // Custom Labels
    labels = {
        save: LABEL_SAVE,
        cancel: LABEL_CANCEL,
        add: COM_BTN_ADD,
        selectAction: POL_LBL_SELECT_ACTION,
        createLineItem: POL_BTN_CREATE_LINEITEM,
        addInstallment: POL_BTN_ADD_INSTALL,
        previous: POL_BTN_PREV,
        exchangeRate: POL_MSG_EXCHANGERATE,
        next: POL_BTN_NEXT,
        signedLineMatch: POL_MSG_SIGNEDLINE_MATCH,
        requireField: POL_MSG_REQUIRE_FIELD,
        existInsure: POL_MSG_EXIST_INSURE,
        partSaveSuccess: POL_MSG_PART_SAVE_SUCCESS,
        dateFormat: POL_MSG_DATE_FORMAT,
        psSaveSuccess: POL_MSG_PS_SAVE_SUCCESS,
        lineItemSaveSuccess: POL_MSG_LINEITEM_SAVE_SUCCESS,
        dateMsg: POL_MSG_DATE
    };

    // Getter / Setter
    get insurerLookupConfig() {
        return INSURER_LOOKUP_CONFIG;
    }

    get coBrokerLookupConfig() {
        return COBROKER_LOOKUP_CONFIG;
    }

    get coBrokingInsurerLookupConfig() {
        const ids = this._insurerOptions.filter((o) => o.value).map((o) => o.value);
        return {
            objectApiName: "Account",
            labelField: "Name",
            orderByField: "Name",
            orderDir: "ASC",
            filters: ids.length > 0 ? ids.map((id) => ({ field: "Id", op: "EQ", value: id, groupKey: id })) : [{ field: "isInsurerAcc__c", op: "=", value: true, type: "boolean" }]
        };
    }

    get actionOptions() {
        return [
            { label: "Create by Premium", value: "Prem" },
            { label: "Create by Co-Insurer & Signed Line(%)", value: "SignedLine" },
            { label: "Create by Co-Broking Type", value: "CoBroking" }
        ];
    }

    get incomeClassOptions() {
        return this._incomeClassOptions;
    }

    get currencyOptions() {
        return this._currencyOptions;
    }

    get isStep0() {
        return this.currentStep === STEP0;
    }

    get isStep1() {
        return this.currentStep === STEP1;
    }

    get isStep1Premium() {
        return this.currentStep === STEP1_PREMIUM;
    }

    get isStep1CoBroking() {
        return this.currentStep === STEP1_COBROKING;
    }

    get isStep2() {
        return this.currentStep === STEP2;
    }

    get isStep3() {
        return this.currentStep === STEP3;
    }

    get showProgressIndicator() {
        return [STEP1, STEP1_COBROKING, STEP2, STEP3].includes(this.currentStep);
    }

    get currentProgressStep() {
        return this.currentStep === STEP1_COBROKING ? STEP1 : this.currentStep;
    }

    get insurerOptions() {
        return this._insurerOptions;
    }

    get coBrokingTypeOptions() {
        return this._coBrokingTypeOptions;
    }

    get coBrokingCurrencyOptions() {
        return this._coBrokingCurrencyOptions;
    }

    get hasCoBrokingRows() {
        return this.coBrokingRows.length > 0;
    }

    get isAddCoBrokingInstallmentsDisabled() {
        return this.isLoading || (this.coBrokingRows.length > 0 && !this._isCoBrokingSaved);
    }

    get isNextDisabled() {
        const f = this.policyForm;
        const requiredFilled = f.incomeClass && f.totalPremiumAmount != null && f.totalPremiumAmount !== "" && f.curr && f.totalInstalment != null && f.totalInstalment !== "";
        return !this.selectedAction || !requiredFilled;
    }

    get isPremiumAction() {
        return this.selectedAction === "Prem";
    }

    get isCoBrokingAction() {
        return this.selectedAction === "CoBroking";
    }

    get isSignedLineAction() {
        return this.selectedAction === "SignedLine";
    }

    get isEditingOrDirty() {
        return this._isDirty || this.allRows.some((r) => r.isEditMode);
    }

    get isCoBrokingDirty() {
        return this._isCoBrokingDirty;
    }

    get hasAnyRows() {
        return this.allRows.length > 0;
    }

    get labelPaymentDueDate() {
        return this._scheduleFields?.CRSPaymentDueDate__c?.label ?? "Payment Due Date";
    }

    get labelExpPaymentDate() {
        return this._scheduleFields?.CRSExpPaymentDate__c?.label ?? "Expiration Payment Date";
    }

    get labelIncomeClass() {
        return this._policyFields?.IncomeClass__c?.label ?? "Income Class";
    }

    get labelInsurerPolicyNo() {
        return this._policyFields?.Insurer_Policy_No__c?.label ?? "Insurer Policy No";
    }

    get labelIdentificationValue() {
        return this._policyFields?.IdentificationValue__c?.label ?? "Identification Value";
    }

    get labelTotalPremiumAmount() {
        return this._policyFields?.Total_Premium_Amount__c?.label ?? "Total Premium Amount";
    }

    get labelCurrency() {
        return this._policyFields?.Currency__c?.label ?? "Currency";
    }

    get labelExchangeRate() {
        return this._policyFields?.ExchangeRatePolicy__c?.label ?? "Exchange Rate";
    }

    get labelInsurer() {
        return this._policyLineItemFields?.Insurer__c?.label ?? "Insurer";
    }

    get labelSignedLine() {
        return this._policyLineItemFields?.SignedLine__c?.label ?? "Signed Line(%)";
    }

    get labelInsurerCommission() {
        return this._participantFields?.InsurerCommission__c?.label ?? "Insurer Commission(%)";
    }

    get labelLeadInsurer() {
        return this._participantFields?.LeadInsurer__c?.label ?? "Lead Insurer";
    }

    get labelBrokerageRate() {
        return this._policyLineItemFields?.BrokerageRate__c?.label ?? "Brokerage Rate(%)";
    }

    get labelInstallRate() {
        return this._scheduleFields?.CRSInstallmentRate__c?.label ?? "Install Rate(%)";
    }

    get labelInstallPremium() {
        return this._scheduleFields?.CRSInstallPremium__c?.label ?? "Install Premium";
    }

    get labelInstallBrokerage() {
        return this._scheduleFields?.CRSInstallBrokerage__c?.label ?? "Install Brokerage";
    }

    get totalSignedLine() {
        return this.allRows.reduce((sum, row) => sum + (parseFloat(row.SignedLine__c) || 0), 0);
    }

    get isSignedLineValid() {
        return this.allRows.length > 0 && Math.abs(this.totalSignedLine - 100) < 0.001;
    }

    get signedLineErrorMessage() {
        if (this.allRows.length === 0) return null;
        const total = this.totalSignedLine;
        if (Math.abs(total - 100) < 0.001) return null;
        return this.labels.signedLineMatch + `${total}%`;
    }

    get isSaveDisabled() {
        return !!this.signedLineErrorMessage;
    }

    get hasReviewErrors() {
        const signedLineHasError = this.reviewSections.some(
            (sec) => sec.premiumErrorMessage || (sec.lineItems || []).some((li) => li.expPaymentDateError || li.paymentDueDateError)
        );
        const coBrokingHasError = this.coBrokingReviewSections.some((sec) =>
            (sec.lineItems || []).some((li) => li.expPaymentDateError || li.paymentDueDateError)
        );
        return signedLineHasError || coBrokingHasError;
    }

    get isSaveAllDisabled() {
        return this.isLoading || this.hasReviewErrors;
    }

    get isAddInstallmentsDisabled() {
        return !this._isSaved || !this.isSignedLineValid || this.isLoading || this.allRows.some((r) => r.isEditMode);
    }

    get policyTotalPremium() {
        return this._policyTotalPremium;
    }

    get policyTotalInstalment() {
        return this._policyTotalInstalment;
    }

    get hasScheduleRows() {
        return this.scheduleRows.length > 0;
    }

    get totalScheduleRate() {
        return this.scheduleRows.reduce((sum, row) => sum + (parseFloat(row.CRSInstallmentRate__c) || 0), 0);
    }

    get totalSchedulePremium() {
        return this.scheduleRows.reduce((sum, row) => sum + (parseFloat(row.CRSInstallPremium__c) || 0), 0);
    }

    get isSchedulePremiumValid() {
        const rawTotal = this.scheduleRows.reduce((sum, row) => sum + (row._rawPremium ?? parseFloat(row.CRSInstallPremium__c) ?? 0), 0);
        return this._policyTotalPremium > 0 && Math.abs(rawTotal - this._policyTotalPremium) < 1e-9;
    }

    get schedulePremiumErrorMessage() {
        if (!this.hasScheduleRows || this.isSchedulePremiumValid) return null;
        const fmt = (v) => v.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        return `Install Premium total (${fmt(this.totalSchedulePremium)}) does not match Policy Premium (${fmt(this._policyTotalPremium)}).`;
    }

    get isScheduleRateValid() {
        return this.hasScheduleRows && Math.abs(this.totalScheduleRate - 100) < 0.01;
    }

    get scheduleRateErrorMessage() {
        if (!this.hasScheduleRows || this.isScheduleRateValid) return null;
        const fmt = (v) => v.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        return `Installment Rate total (${fmt(this.totalScheduleRate)}%) must equal 100%.`;
    }

    get hasDateErrors() {
        return this.scheduleRows.some((r) => r.paymentDueDateError || r.expPaymentDateError);
    }

    get isCreateLineItemsDisabled() {
        return this.isLoading || !this.isSchedulePremiumValid || !this.isScheduleRateValid || this.hasDateErrors || this.hasMissingDates;
    }

    get _currencyScale() {
        return getCurrencyScale(this.policyForm?.curr || this._policyCurrency, 2);
    }

    get currencyStep() {
        return scaleToStep(this._currencyScale);
    }

    get currencyFractionDigits() {
        return this._currencyScale;
    }

    get policyWritingCarrierName() {
        return this._policyWritingCarrierName;
    }

    get insurerCommission() {
        return this._insurerCommission;
    }

    get totalScheduleBrokerage() {
        return this.scheduleRows.reduce((sum, row) => sum + (parseFloat(row.CRSInstallBrokerage__c) || 0), 0);
    }

    get isScheduleBrokerageValid() {
        return this._policyBrokerageAmt > 0 && Math.abs(this.totalScheduleBrokerage - this._policyBrokerageAmt) < 0.01;
    }

    get scheduleBrokerageErrorMessage() {
        if (!this.hasScheduleRows || this.isScheduleBrokerageValid) return null;
        const fmt = (v) => v.toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        return `Install Brokerage total (${fmt(this.totalScheduleBrokerage)}) does not match Brokerage Amount (${fmt(this._policyBrokerageAmt)}).`;
    }

    get hasMissingDates() {
        return this.scheduleRows.some((r) => !r.CRSPaymentDueDateNum__c || !r.CRSExpPaymentDateNum__c);
    }

    get isCreateLineItemsPremiumDisabled() {
        return this.isLoading || !this.isSchedulePremiumValid || !this.isScheduleRateValid || this.hasDateErrors || this.hasMissingDates;
    }

    // Wire Methods

    /**
     * @description InsurancePolicy Object Info를 조회하여 Policy 필드 라벨 정보를 저장한다.
     * @return {void}
     */
    @wire(getObjectInfo, { objectApiName: POL_OBJ })
    wiredPolicyInfo({ data, error }) {
        if (data?.fields) {
            this._policyFields = data.fields;
        } else if (error) {
            this._policyFields = null;
        }
    }

    /**
     * @description InsurancePolicyParticipant Object Info를 조회하여 Participant 필드 라벨 정보를 저장한다.
     * @return {void}
     */
    @wire(getObjectInfo, { objectApiName: PARTICIPANT_OBJ })
    wiredParticipantInfo({ data, error }) {
        if (data?.fields) {
            this._participantFields = data.fields;
        } else if (error) {
            this._participantFields = null;
        }
    }

    /**
     * @description Premium Schedule Object Info를 조회하여 Schedule 필드 라벨 정보를 저장한다.
     * @return {void}
     */
    @wire(getObjectInfo, { objectApiName: SCHEDULE_OBJ })
    wiredScheduleInfo({ data, error }) {
        if (data?.fields) {
            this._scheduleFields = data.fields;
        } else if (error) {
            this._scheduleFields = null;
        }
    }

    /**
     * @description InsurancePolicyLineItem Object Info를 조회하여 Review 화면용 필드 라벨 정보를 저장한다.
     * @return {void}
     */
    @wire(getObjectInfo, { objectApiName: POLLINEITEM_OBJ })
    wiredPolicyLineItemInfo({ data, error }) {
        if (data?.fields) {
            this._policyLineItemFields = data.fields;
        } else if (error) {
            this._policyLineItemFields = null;
        }
    }

    // Event Handlers

    /**
     * @description 생성 방식 라디오 선택값을 변경한다.
     * @param {Event} event action change 이벤트
     * @return {void}
     */
    handleActionChange(event) {
        this.selectedAction = event.detail.value;
    }

    /**
     * @description Step 0 Policy 입력값을 변경한다.
     * @param {Event} event 입력 change 이벤트
     * @return {void}
     */
    handlePolicyFormChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;
        const updated = { ...this.policyForm, [field]: value };
        this.policyForm = updated;
    }

    /**
     * @description Insurer Commission 변경 시 Schedule Brokerage를 재계산한다.
     * @param {Event} event commission input 이벤트
     * @return {void}
     */
    handleInsurerCommissionChange(event) {
        const value = event.target.value;
        this._insurerCommission = value !== "" && value != null ? parseFloat(value) : null;
        this.scheduleRows = this.scheduleRows.map((row) => ({
            ...row,
            CRSInstallBrokerage__c: this._calcBrokerage(row._rawPremium ?? row.CRSInstallPremium__c)
        }));
    }

    /**
     * @description Step 0 데이터를 저장한 뒤 선택된 생성 방식에 맞는 다음 스텝으로 이동한다.
     * @return {Promise<void>}
     */
    async handleNextFromStep0() {
        this.isLoading = true;
        try {
            await updatePolicyInfo({
                policyId: this.recordId,
                incomeClass: this.policyForm.incomeClass || null,
                insurerPolicyNo: this.policyForm.insurerPolicyNo || null,
                identificationValue: this.policyForm.identificationValue || null,
                totalPremiumAmount: this.policyForm.totalPremiumAmount != null ? parseFloat(this.policyForm.totalPremiumAmount) : null,
                curr: this.policyForm.curr || null,
                totalInstalment: this.policyForm.totalInstalment != null ? parseFloat(this.policyForm.totalInstalment) : null,
                exchangeRate: this.policyForm.exchangeRate != null ? parseFloat(this.policyForm.exchangeRate) : null,
                premCalcType: this.selectedAction
            });

            this._policyTotalPremium = parseFloat(this.policyForm.totalPremiumAmount) || 0;
            this._policyTotalInstalment = parseInt(this.policyForm.totalInstalment, 10) || 0;
            this._policyCurrency = this.policyForm.curr || "";

            if (this.selectedAction === "Prem") {
                this._insurerCommission = null;
                try {
                    const commission = await getWritingCarrierCommission({ policyId: this.recordId });
                    this._insurerCommission = commission != null ? commission : null;
                } catch {
                    this._insurerCommission = null;
                }

                const schedules = await getSchedules({ policyId: this.recordId });
                this._initScheduleRows(schedules || []);
                this.currentStep = STEP1_PREMIUM;
            } else if (this.selectedAction === "CoBroking") {
                const initData = await getCoBrokingInitData({ policyId: this.recordId });
                this._insurerOptions = initData.insurerOptions || [];
                this._coBrokingTypeOptions = [...(initData.coBrokingTypeOptions || [])];
                this._coBrokingCurrencyOptions = [...(initData.currencyOptions || [])];

                const existingRows = initData.existingRows || [];
                this.coBrokingRows = existingRows.map((row, i) => ({
                    _key: `cb_${row.Id}_${i}`,
                    Id: row.Id,
                    Insurer__c: row.Insurer__c || null,
                    TBD__c: row.TBD__c || null,
                    coBrokerName: row.TBD__r ? row.TBD__r.Name : "",
                    CoBrokingType__c: row.CoBrokingType__c || null,
                    Currency__c: row.Currency__c || null,
                    isCoBrokingNone: row.CoBrokingType__c === "None",
                    insurerClass: "",
                    coBrokerClass: "",
                    coBrokingTypeClass: "",
                    currencyClass: ""
                }));
                this._coBrokingDeletedIds = [];
                this._isCoBrokingSaved = existingRows.length > 0;
                this.currentStep = STEP1_COBROKING;
            } else {
                const participants = await getParticipants({ policyId: this.recordId });
                const seenIds = new Set();
                const mapped = (participants || [])
                    .filter((row) => {
                        if (!row.Id || seenIds.has(row.Id)) return false;
                        seenIds.add(row.Id);
                        return true;
                    })
                    .map((row, i) => ({
                        _key: `${row.Id}_${i}`,
                        Id: row.Id,
                        Role: row.Role,
                        Insurer__c: row.Insurer__c,
                        insurerName: row.Insurer__r ? row.Insurer__r.Name : "",
                        SignedLine__c: row.SignedLine__c,
                        formattedSignedLine: this.formatPercentage(row.SignedLine__c),
                        InsurerCommission__c: row.InsurerCommission__c,
                        formattedCommission: this.formatPercentage(row.InsurerCommission__c),
                        LeadInsurer__c: row.LeadInsurer__c || false,
                        isEditMode: false,
                        insurerClass: "",
                        signedLineClass: "",
                        commissionClass: ""
                    }));

                this.allRows = mapped;
                this._originalRows = mapped.map((r) => ({ ...r }));
                this._isDirty = false;
                this._deletedIds = [];
                this._isSaved = mapped.length > 0 && mapped.every((r) => this._isRowValid(r));
                this.currentStep = STEP1;
            }
        } catch (error) {
            toast("Error", error?.body?.message || "Failed to update policy.", "error");
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description 선택한 Participant 행을 편집 모드로 전환한다.
     * @param {Event} event edit 아이콘 클릭 이벤트
     * @return {void}
     */
    handleFieldEdit(event) {
        const rowKey = event.currentTarget.dataset.rowkey;
        this.allRows = this.allRows.map((row) => ({
            ...row,
            isEditMode: row._key === rowKey
        }));
    }

    /**
     * @description Participant 신규 행을 추가한다.
     * @return {void}
     */
    handleAddRow() {
        const key = String(++this._rowSeq);
        this.allRows = [
            ...this.allRows.map((r) => ({ ...r, isEditMode: false })),
            {
                _key: key,
                Id: null,
                Insurer__c: null,
                insurerName: "",
                SignedLine__c: null,
                formattedSignedLine: "0.00",
                InsurerCommission__c: null,
                formattedCommission: "0.00",
                LeadInsurer__c: false,
                isEditMode: true,
                insurerClass: "",
                signedLineClass: "",
                commissionClass: ""
            }
        ];
        this._isDirty = true;
        this._isSaved = false;
    }

    /**
     * @description Participant 행을 검증하고 로컬 저장 상태로 확정한다.
     * @return {void}
     */
    handleSaveRows() {
        let hasError = false;

        this.allRows = this.allRows.map((row) => {
            const updated = { ...row };

            if (!row.Insurer__c) {
                updated.insurerClass = "error-cell";
                hasError = true;
            } else {
                updated.insurerClass = "";
            }

            const sl = row.SignedLine__c;
            if (sl === null || sl === undefined || sl === "" || parseFloat(sl) <= 0) {
                updated.signedLineClass = "error-cell";
                hasError = true;
            } else {
                updated.signedLineClass = "";
            }

            return updated;
        });

        if (hasError) {
            const errorRows = this.allRows
                .map((row, i) => (!this._isRowValid(row) ? i + 1 : null))
                .filter((n) => n !== null)
                .join(", ");
            toast("Validation Error", `${this.labels.requireField}: ${errorRows}`, "error");
            return;
        }

        this.allRows = this.allRows.map((row) => ({
            ...row,
            formattedSignedLine: this.formatPercentage(row.SignedLine__c),
            formattedCommission: this.formatPercentage(row.InsurerCommission__c)
        }));
        this._exitAllEditModes();
        this._isDirty = false;
        this._isSaved = true;
    }

    /**
     * @description Participant 행의 Insurer Lookup 변경을 처리한다.
     * @param {Event} event lookup change 이벤트
     * @return {Promise<void>}
     */
    async handleInsurerLookupChange(event) {
        const rowKey = event.target.dataset.rowkey;
        const { value, label } = event.detail;

        if (!value) {
            this.allRows = this.allRows.map((row) => (row._key === rowKey ? { ...row, Insurer__c: null, insurerName: "", InsurerCommission__c: null, insurerClass: "error-cell" } : row));
            this._isDirty = true;
            this._isSaved = false;
            return;
        }

        const isDuplicate = this.allRows.some((row) => row._key !== rowKey && row.Insurer__c === value);
        if (isDuplicate) {
            toast("Duplicate Error", `${this.labels.existInsure} (${label})`, "error");
            const lookup = this.template.querySelector(`c-com-lookup[data-rowkey="${rowKey}"]`);
            if (lookup) lookup.resetLookup(true);
            return;
        }

        this.allRows = this.allRows.map((row) => (row._key === rowKey ? { ...row, Insurer__c: value, insurerName: label, InsurerCommission__c: null, insurerClass: "" } : row));
        this._isDirty = true;
        this._isSaved = false;
    }

    /**
     * @description Participant 행의 입력값 변경을 처리한다.
     * @param {Event} event input change 이벤트
     * @return {void}
     */
    handleRowChange(event) {
        const rowKey = event.target.dataset.rowkey;
        const field = event.target.dataset.field;
        const value = field === "LeadInsurer__c" ? event.target.checked : event.target.value;

        if (field === "LeadInsurer__c" && value === true) {
            this.allRows = this.allRows.map((row) => ({ ...row, LeadInsurer__c: row._key === rowKey }));
        } else {
            this.allRows = this.allRows.map((row) => {
                if (row._key !== rowKey) return row;
                const updated = { ...row, [field]: value };
                if (field === "SignedLine__c") {
                    updated.signedLineClass = value !== "" && value !== null && parseFloat(value) >= 0 ? "" : "error-cell";
                    updated.formattedSignedLine = this.formatPercentage(value);
                }
                if (field === "InsurerCommission__c") {
                    updated.commissionClass = value !== "" && value !== null && parseFloat(value) >= 0 ? "" : "error-cell";
                    updated.formattedCommission = this.formatPercentage(value);
                }
                return updated;
            });
        }
        this._isDirty = true;
        this._isSaved = false;
    }

    /**
     * @description Participant 행을 삭제하고 기존 레코드는 삭제 대상 목록에 추가한다.
     * @param {Event} event delete 버튼 클릭 이벤트
     * @return {void}
     */
    handleDeleteRow(event) {
        const rowKey = event.target.dataset.rowkey;
        const row = this.allRows.find((r) => r._key === rowKey);
        if (row?.Id) {
            this._deletedIds = [...this._deletedIds, row.Id];
        }
        this.allRows = this.allRows.filter((r) => r._key !== rowKey);
        this._isDirty = true;
        this._isSaved = false;
    }

    /**
     * @description Participants를 저장한 뒤 Schedule Step으로 이동한다.
     * @return {Promise<void>}
     */
    async handleAddInstallments() {
        this._exitAllEditModes();
        this.isLoading = true;
        try {
            const participants = this.allRows.map((row) => {
                const p = {
                    Insurer__c: row.Insurer__c || null,
                    SignedLine__c: row.SignedLine__c != null ? parseFloat(row.SignedLine__c) : null,
                    InsurerCommission__c: row.InsurerCommission__c != null ? parseFloat(row.InsurerCommission__c) : null,
                    LeadInsurer__c: row.LeadInsurer__c || false
                };
                if (row.Id) p.Id = row.Id;
                return p;
            });

            await saveParticipants({ recordId: this.recordId, participants, deletedIds: this._deletedIds });
            this._deletedIds = [];
            this._isDirty = false;
            toast("Success", `${this.labels.partSaveSuccess}`, "success");

            const schedules = await getSchedules({ policyId: this.recordId });
            this._initScheduleRows(schedules || []);

            const currentIndex = this._stepOrder.indexOf(this.currentStep);
            if (currentIndex < this._stepOrder.length - 1) {
                this.currentStep = this._stepOrder[currentIndex + 1];
            }
        } catch (error) {
            toast("Error", error?.body?.message || "Failed to save participants.", "error");
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Step 2 날짜 입력값을 마스킹 및 검증하여 반영한다.
     * @param {Event} event date input 이벤트
     * @return {void}
     */
    handleDateInput(event) {
        const rowKey = event.target.dataset.rowkey;
        const field = event.target.dataset.field;
        const isPayment = field === "CRSPaymentDueDateNum__c";
        const displayField = isPayment ? "paymentDueDateDisplay" : "expPaymentDateDisplay";
        const errorField = isPayment ? "paymentDueDateClass" : "expPaymentDateClass";
        const errorMsgField = isPayment ? "paymentDueDateError" : "expPaymentDateError";

        const digits = event.target.value.replace(/\D/g, "").slice(0, 6);
        const formatted = this._formatDateInput(digits);
        event.target.value = formatted;

        let numValue = null;
        let errorClass = "";
        let errorMsg = "";

        if (digits.length === 0) {
        } else if (digits.length < 6) {
            errorClass = "error-cell";
            errorMsg = this.labels.dateFormat;
        } else {
            const mm = parseInt(digits.slice(2, 4), 10);
            const dd = parseInt(digits.slice(4, 6), 10);
            if (mm >= 1 && mm <= 12 && dd >= 1 && dd <= 31) {
                numValue = parseInt(digits, 10);
            } else {
                errorClass = "error-cell";
                errorMsg = "Invalid date.";
            }
        }

        this.scheduleRows = this.scheduleRows.map((row) => {
            if (row._key !== rowKey) return row;
            const updated = { ...row, [field]: numValue, [displayField]: formatted, [errorField]: errorClass, [errorMsgField]: errorMsg };
            const payNum = updated.CRSPaymentDueDateNum__c;
            const expNum = updated.CRSExpPaymentDateNum__c;
            if (payNum != null && expNum != null) {
                if (expNum > payNum) {
                    updated.paymentDueDateClass = "error-cell";
                    updated.paymentDueDateError = this.labels.dateMsg;
                } else if (updated.paymentDueDateError === this.labels.dateMsg) {
                    updated.paymentDueDateClass = "";
                    updated.paymentDueDateError = "";
                }
            } else if (updated.paymentDueDateError === this.labels.dateMsg) {
                updated.paymentDueDateClass = "";
                updated.paymentDueDateError = "";
            }
            return updated;
        });
    }

    /**
     * @description Step 2 Schedule 행 입력값 변경을 처리한다.
     * @param {Event} event input change 이벤트
     * @return {void}
     */
    handleScheduleChange(event) {
        const rowKey = event.target.dataset.rowkey;
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.scheduleRows = this.scheduleRows.map((row) => {
            if (row._key !== rowKey) return row;
            const updated = { ...row, [field]: value };
            if (field === "CRSInstallmentRate__c") {
                const rawPremium = this._calcInstallPremium(value);
                updated._rawPremium = rawPremium;
                updated.CRSInstallPremium__c = this._roundToScale(rawPremium);
                updated.CRSInstallBrokerage__c = this._calcBrokerage(rawPremium);
            }
            if (field === "CRSInstallPremium__c") {
                const rawPremium = value != null && value !== "" ? parseFloat(value) : null;
                updated._rawPremium = rawPremium;
                updated.CRSInstallBrokerage__c = this._calcBrokerage(rawPremium);
            }
            return updated;
        });
    }

    /**
     * @description Premium 방식 Line Item 생성을 실행한다.
     * @return {Promise<void>}
     */
    async handleCreateLineItemsPremium() {
        if (!this._validateRequiredDates()) return;
        this.isLoading = true;
        try {
            const schedules = this.scheduleRows.map((row) => {
                const s = {
                    CRSInstallmentRate__c: row.CRSInstallmentRate__c != null ? parseFloat(row.CRSInstallmentRate__c) : null,
                    CRSInstallPremium__c: row.CRSInstallPremium__c != null ? parseFloat(row.CRSInstallPremium__c) : null,
                    CRSInstallBrokerage__c: row.CRSInstallBrokerage__c != null ? parseFloat(row.CRSInstallBrokerage__c) : null,
                    CRSPaymentDueDateNum__c: row.CRSPaymentDueDateNum__c || null,
                    CRSExpPaymentDateNum__c: row.CRSExpPaymentDateNum__c || null
                };
                if (row.Id) s.Id = row.Id;
                return s;
            });

            await upsertSchedules({ policyId: this.recordId, schedules, deletedIds: this._deletedScheduleIds, calcType: "Prem" });
            this._deletedScheduleIds = [];

            const totalBrokerage = this.totalScheduleBrokerage;
            const totalPremium = this.totalSchedulePremium;
            const brokerageRate = parseFloat((totalPremium > 0 ? (totalBrokerage / totalPremium) * 100 : 0).toFixed(2));
            await updatePolicyBrokerageInfo({ policyId: this.recordId, brokerageAmt: totalBrokerage, brokerageRate });
            await updateParticipantsCommission({ policyId: this.recordId, commission: brokerageRate });

            toast("Success", this.labels.psSaveSuccess, "success");

            const success = await runPolicyLineItemFlow({ policyId: this.recordId });
            console.log("[handleCreateLineItemsPremium] runPolicyLineItemFlow result:", success, typeof success);
            if (success) {
                console.log("[handleCreateLineItemsPremium] closing modal");
                this._closeAndRefresh();
            } else {
                console.warn("[handleCreateLineItemsPremium] success is falsy — modal not closed. value:", success);
            }
        } catch (error) {
            console.error("[handleCreateLineItemsPremium] catch:", error);
            console.error("[handleCreateLineItemsPremium] error.body:", error?.body);
            console.error("[handleCreateLineItemsPremium] stack:", error?.stack);
            toast("Error", error?.body?.message || "Failed to create line items.", "error");
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Signed Line 또는 Co-Broking 방식 Line Item 생성을 실행한다.
     * @return {Promise<void>}
     */
    async handleCreateLineItems() {
        if (!this._validateRequiredDates()) return;
        this.isLoading = true;
        try {
            const schedules = this.scheduleRows.map((row) => {
                const s = {
                    CRSInstallmentRate__c: row.CRSInstallmentRate__c != null ? parseFloat(row.CRSInstallmentRate__c) : null,
                    CRSInstallPremium__c: row.CRSInstallPremium__c != null ? parseFloat(row.CRSInstallPremium__c) : null,
                    CRSPaymentDueDateNum__c: row.CRSPaymentDueDateNum__c || null,
                    CRSExpPaymentDateNum__c: row.CRSExpPaymentDateNum__c || null
                };
                if (row.Id) s.Id = row.Id;
                return s;
            });

            const calcType = this.selectedAction === "CoBroking" ? "CoBroking" : "SignedLine";
            await upsertSchedules({ policyId: this.recordId, schedules, deletedIds: this._deletedScheduleIds, calcType });
            this._deletedScheduleIds = [];
            toast("Success", this.labels.psSaveSuccess, "success");

            if (this.selectedAction === "CoBroking") {
                const existingCoBrokingSnapshot = await getExistingCoBrokingExpDates({ policyId: this.recordId });
                const success = await runCoBrokingLineItemFlow({ policyId: this.recordId });
                if (success) {
                    await this._loadCoBrokingReviewData(existingCoBrokingSnapshot);
                    this.currentStep = STEP3;
                }
            } else {
                const existingExpDates = await getExistingExpDates({ policyId: this.recordId });
                const success = await runPolicyLineItemFlow({ policyId: this.recordId });
                if (success) {
                    await this._loadReviewData(existingExpDates);
                    this.currentStep = STEP3;
                }
            }
        } catch (error) {
            toast("Error", error?.body?.message || "Failed to create line items.", "error");
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Review Step의 Line Item 값 변경을 반영한다.
     * @param {Event} event input change 이벤트
     * @return {void}
     */
    handleReviewLineItemChange(event) {
        const secKey = event.target.dataset.seckey;
        const liKey = event.target.dataset.likey;
        const field = event.target.dataset.field;
        const value = event.target.value;

        if (field === "InsurerCommission__c") {
            const targetSec = this.reviewSections.find((s) => s._key === secKey);
            const targetLi = targetSec?.lineItems.find((li) => li._key === liKey);
            const insurerId = targetLi?.Insurer__c;
            const isSnapshotRow = !!targetLi?._hasSnapshot;

            this.reviewSections = this.reviewSections.map((sec) => {
                const updatedItems = sec.lineItems.map((li) => {
                    if (li.Insurer__c !== insurerId) return li;
                    if (isSnapshotRow) {
                        if (li._key !== liKey) return li;
                    } else {
                        if (li._hasSnapshot) return li;
                    }
                    return { ...li, InsurerCommission__c: value, BrokerageAmt__c: this._calcBrokerage(li.Premium__c, value) };
                });
                const isDirty = updatedItems.some((li, i) => li !== sec.lineItems[i]);
                const rebuilt = this._buildSection(sec._key.replace("sec_", ""), sec.scheduleId, sec.installmentNum, sec.installmentRate, sec.installPremium, updatedItems, sec._isDirty || isDirty);
                return { ...rebuilt, _key: sec._key };
            });
        } else {
            this.reviewSections = this.reviewSections.map((sec) => {
                if (sec._key !== secKey) return sec;
                const updatedItems = sec.lineItems.map((li) => {
                    if (li._key !== liKey) return li;
                    const updated = { ...li, [field]: value };
                    if (field === "Premium__c") {
                        updated.BrokerageAmt__c = this._calcBrokerage(value, updated.InsurerCommission__c);
                    }
                    return updated;
                });
                const rebuilt = this._buildSection(sec._key.replace("sec_", ""), sec.scheduleId, sec.installmentNum, sec.installmentRate, sec.installPremium, updatedItems, true);
                return { ...rebuilt, _key: sec._key };
            });
        }
    }

    /**
     * @description Review Step의 날짜 입력값을 마스킹 및 검증하여 반영한다.
     * @param {Event} event date input 이벤트
     * @return {void}
     */
    handleReviewDateInput(event) {
        const secKey = event.target.dataset.seckey;
        const liKey = event.target.dataset.likey;
        const field = event.target.dataset.field;
        const isPayment = field === "paymentDueDate";
        const numField = isPayment ? "paymentDueDateNum" : "expPaymentDateNum";
        const displayField = isPayment ? "paymentDueDateDisplay" : "expPaymentDateDisplay";
        const classField = isPayment ? "paymentDueDateClass" : "expPaymentDateClass";
        const errorField = isPayment ? "paymentDueDateError" : "expPaymentDateError";

        const digits = event.target.value.replace(/\D/g, "").slice(0, 6);
        const formatted = this._formatDateInput(digits);
        event.target.value = formatted;

        let numValue = null;
        let errorClass = "";
        let errorMsg = "";

        if (digits.length === 0) {
        } else if (digits.length < 6) {
            errorClass = "error-cell";
            errorMsg = this.labels.dateFormat;
        } else {
            const mm = parseInt(digits.slice(2, 4), 10);
            const dd = parseInt(digits.slice(4, 6), 10);
            if (mm >= 1 && mm <= 12 && dd >= 1 && dd <= 31) {
                numValue = parseInt(digits, 10);
            } else {
                errorClass = "error-cell";
                errorMsg = "Invalid date.";
            }
        }

        this.reviewSections = this.reviewSections.map((sec) => {
            if (sec._key !== secKey) return sec;
            const updatedItems = sec.lineItems.map((li) => {
                if (li._key !== liKey) return li;
                const updated = { ...li, [numField]: numValue, [displayField]: formatted, [classField]: errorClass, [errorField]: errorMsg };
                const payNum = updated.paymentDueDateNum;
                const expNum = updated.expPaymentDateNum;
                if (payNum != null && expNum != null) {
                    if (expNum > payNum) {
                        updated.paymentDueDateClass = "error-cell";
                        updated.paymentDueDateError = this.labels.dateMsg;
                    } else if (updated.paymentDueDateError === this.labels.dateMsg) {
                        updated.paymentDueDateClass = "";
                        updated.paymentDueDateError = "";
                    }
                } else if (updated.paymentDueDateError === this.labels.dateMsg) {
                    updated.paymentDueDateClass = "";
                    updated.paymentDueDateError = "";
                }
                return updated;
            });
            return { ...sec, lineItems: updatedItems };
        });
    }

    /**
     * @description Co-Broking Review Step의 Line Item 값 변경을 반영한다.
     * @param {Event} event input change 이벤트
     * @return {void}
     */
    handleCoBrokingReviewLineItemChange(event) {
        const secKey = event.target.dataset.seckey;
        const liKey = event.target.dataset.likey;
        const field = event.target.dataset.field;
        const value = event.target.value;

        if (field === "BrokerageRate__c") {
            const targetSec = this.coBrokingReviewSections.find((s) => s._key === secKey);
            const targetLi = targetSec?.lineItems.find((li) => li._key === liKey);
            const tpbId = targetLi?.TPB__c;
            const isIdRow = !!targetLi?.Id;

            this.coBrokingReviewSections = this.coBrokingReviewSections.map((sec) => {
                const updatedItems = sec.lineItems.map((li) => {
                    if (li.TPB__c !== tpbId) return li;
                    if (isIdRow) {
                        if (li._key !== liKey) return li;
                    } else {
                        if (li.Id) return li;
                    }
                    return { ...li, BrokerageRate__c: value, BrokerageAmt__c: this._calcBrokerage(sec.installPremium, value) };
                });
                return this._buildCoBrokingSection(sec._key.replace("cbsec_", ""), sec.scheduleId, sec.installmentNum, sec.installmentRate, sec.installPremium, updatedItems, true);
            });
        } else {
            this.coBrokingReviewSections = this.coBrokingReviewSections.map((sec) => {
                if (sec._key !== secKey) return sec;
                const updatedItems = sec.lineItems.map((li) => (li._key !== liKey ? li : { ...li, [field]: value }));
                return this._buildCoBrokingSection(sec._key.replace("cbsec_", ""), sec.scheduleId, sec.installmentNum, sec.installmentRate, sec.installPremium, updatedItems, true);
            });
        }
    }

    /**
     * @description Co-Broking Review Step의 날짜 입력값을 마스킹 및 검증하여 반영한다.
     * @param {Event} event date input 이벤트
     * @return {void}
     */
    handleCoBrokingReviewDateInput(event) {
        const secKey = event.target.dataset.seckey;
        const liKey = event.target.dataset.likey;
        const field = event.target.dataset.field;
        const isPayment = field === "paymentDueDate";
        const numField = isPayment ? "paymentDueDateNum" : "expPaymentDateNum";
        const displayField = isPayment ? "paymentDueDateDisplay" : "expPaymentDateDisplay";
        const classField = isPayment ? "paymentDueDateClass" : "expPaymentDateClass";
        const errorField = isPayment ? "paymentDueDateError" : "expPaymentDateError";

        const digits = event.target.value.replace(/\D/g, "").slice(0, 6);
        const formatted = this._formatDateInput(digits);
        event.target.value = formatted;

        let numValue = null;
        let errorClass = "";
        let errorMsg = "";

        if (digits.length > 0 && digits.length < 6) {
            errorClass = "error-cell";
            errorMsg = this.labels.dateFormat;
        } else if (digits.length === 6) {
            const mm = parseInt(digits.slice(2, 4), 10);
            const dd = parseInt(digits.slice(4, 6), 10);
            if (mm >= 1 && mm <= 12 && dd >= 1 && dd <= 31) {
                numValue = parseInt(digits, 10);
            } else {
                errorClass = "error-cell";
                errorMsg = "Invalid date.";
            }
        }

        this.coBrokingReviewSections = this.coBrokingReviewSections.map((sec) => {
            if (sec._key !== secKey) return sec;
            const updatedItems = sec.lineItems.map((li) => {
                if (li._key !== liKey) return li;
                const updated = { ...li, [numField]: numValue, [displayField]: formatted, [classField]: errorClass, [errorField]: errorMsg };
                const payNum = updated.paymentDueDateNum;
                const expNum = updated.expPaymentDateNum;
                if (payNum != null && expNum != null) {
                    if (expNum > payNum) {
                        updated.paymentDueDateClass = "error-cell";
                        updated.paymentDueDateError = this.labels.dateMsg;
                    } else if (updated.paymentDueDateError === this.labels.dateMsg) {
                        updated.paymentDueDateClass = "";
                        updated.paymentDueDateError = "";
                    }
                } else if (updated.paymentDueDateError === this.labels.dateMsg) {
                    updated.paymentDueDateClass = "";
                    updated.paymentDueDateError = "";
                }
                return updated;
            });
            return { ...sec, lineItems: updatedItems };
        });
    }

    /**
     * @description Co-Broking Review Step의 전체 Line Item을 저장한다.
     * @return {Promise<void>}
     */
    async handleSaveAllCoBrokingLineItems() {
        this.isLoading = true;
        try {
            const lineItems = this.coBrokingReviewSections
                .flatMap((sec) => sec.lineItems)
                .filter((li) => li.Id)
                .map((li) => ({
                    lineItemId: li.Id,
                    brokerageAmt: li.BrokerageAmt__c != null ? parseFloat(li.BrokerageAmt__c) : null,
                    paymentDueDateNum: li.paymentDueDateNum != null ? li.paymentDueDateNum : null,
                    expPaymentDateNum: li.expPaymentDateNum != null ? li.expPaymentDateNum : null
                }));

            const scheduleInstallBrokerages = {};
            this.coBrokingReviewSections.forEach((sec) => {
                if (sec.scheduleId) {
                    scheduleInstallBrokerages[sec.scheduleId] = parseFloat((sec.totalBrokerage || 0).toFixed(2));
                }
            });

            const brokerageAmt = parseFloat(this.coBrokingReviewSections.reduce((sum, sec) => sum + (sec.totalBrokerage || 0), 0).toFixed(2));
            const totalPremium = this.reviewPolicyInfo.totalPremiumAmount || 0;
            const brokerageRate = parseFloat((totalPremium > 0 ? (brokerageAmt / totalPremium) * 100 : 0).toFixed(2));

            await saveCoBrokingLineItems({
                lineItems,
                scheduleInstallBrokerages,
                policyId: this.recordId,
                brokerageAmt,
                brokerageRate
            });

            toast("Success", this.labels.lineItemSaveSuccess, "success");
            this._closeAndRefresh();
        } catch (error) {
            toast("Error", error?.body?.message || "Failed to save co-broking line items.", "error");
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Review Step의 전체 Line Item을 저장한다.
     * @return {Promise<void>}
     */
    async handleSaveAllLineItems() {
        this.isLoading = true;
        try {
            const lineItems = this.reviewSections
                .flatMap((sec) => sec.lineItems)
                .filter((li) => li.Id)
                .map((li) => ({
                    lineItemId: li.Id,
                    premium: li.Premium__c != null ? parseFloat(li.Premium__c) : null,
                    insurerCommission: li.InsurerCommission__c != null ? parseFloat(li.InsurerCommission__c) : null,
                    brokerageAmt: li.BrokerageAmt__c != null ? parseFloat(li.BrokerageAmt__c) : null,
                    paymentDueDateNum: li.paymentDueDateNum != null ? li.paymentDueDateNum : null,
                    expPaymentDateNum: li.expPaymentDateNum != null ? li.expPaymentDateNum : null
                }));

            const scheduleInstallBrokerages = {};
            this.reviewSections.forEach((sec) => {
                if (sec.scheduleId) {
                    scheduleInstallBrokerages[sec.scheduleId] = parseFloat((sec.totalBrokerage || 0).toFixed(2));
                }
            });

            await saveLineItems({ lineItems, scheduleInstallBrokerages });

            const totalBrokerage = this.reviewSections.reduce((sum, sec) => sum + (sec.totalBrokerage || 0), 0);
            const totalPremium = this.reviewPolicyInfo.totalPremiumAmount || 0;
            const brokerageRate = parseFloat((totalPremium > 0 ? (totalBrokerage / totalPremium) * 100 : 0).toFixed(2));
            console.log("Updating policy brokerage info:", { totalBrokerage, brokerageRate });
            await updatePolicyBrokerageInfo({ policyId: this.recordId, brokerageAmt: totalBrokerage, brokerageRate });

            const insurerTotals = {};
            this.reviewSections
                .flatMap((sec) => sec.lineItems)
                .forEach((li) => {
                    if (!li.Insurer__c) return;
                    if (!insurerTotals[li.Insurer__c]) {
                        insurerTotals[li.Insurer__c] = { totalPremium: 0, totalBrokerage: 0 };
                    }
                    insurerTotals[li.Insurer__c].totalPremium += parseFloat(li.Premium__c) || 0;
                    insurerTotals[li.Insurer__c].totalBrokerage += parseFloat(li.BrokerageAmt__c) || 0;
                });

            const commissionByInsurer = {};
            Object.entries(insurerTotals).forEach(([insurerId, { totalPremium: iPremium, totalBrokerage: iBrokerage }]) => {
                commissionByInsurer[insurerId] = parseFloat((iPremium > 0 ? (iBrokerage / iPremium) * 100 : 0).toFixed(2));
            });

            if (Object.keys(commissionByInsurer).length > 0) {
                await updateAllParticipantsCommission({ policyId: this.recordId, commissionJson: JSON.stringify(commissionByInsurer) });
            }

            toast("Success", this.labels.lineItemSaveSuccess, "success");
            this._closeAndRefresh();
        } catch (error) {
            console.error("[handleSaveAllLineItems] catch:", error);
            console.error("[handleSaveAllLineItems] error.body:", error?.body);
            console.error("[handleSaveAllLineItems] stack:", error?.stack);
            toast("Error", error?.body?.message || "Failed to save line items.", "error");
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description 이전 Step으로 이동한다.
     * @return {void}
     */
    handlePrev() {
        this.hasStepError = false;
        if (this.currentStep === STEP1 || this.currentStep === STEP1_PREMIUM || this.currentStep === STEP1_COBROKING) {
            this.currentStep = STEP0;
        } else if (this.currentStep === STEP2) {
            this.currentStep = this.selectedAction === "CoBroking" ? STEP1_COBROKING : STEP1;
        } else {
            const currentIndex = this._stepOrder.indexOf(this.currentStep);
            if (currentIndex > 0) {
                this.currentStep = this._stepOrder[currentIndex - 1];
            }
        }
    }

    /**
     * @description Co-Broking 신규 행을 추가한다.
     * @return {void}
     */
    handleAddCoBrokingRow() {
        const key = `cb_new_${++this._rowSeq}`;
        this.coBrokingRows = [
            ...this.coBrokingRows,
            {
                _key: key,
                Id: null,
                Insurer__c: null,
                TBD__c: null,
                coBrokerName: "",
                CoBrokingType__c: null,
                Currency__c: null,
                isCoBrokingNone: false,
                insurerClass: "",
                coBrokerClass: "",
                coBrokingTypeClass: "",
                currencyClass: ""
            }
        ];
        this._isCoBrokingSaved = false;
        this._isCoBrokingDirty = true;
    }

    /**
     * @description Co-Broking 행을 삭제하고 기존 레코드는 삭제 대상 목록에 추가한다.
     * @param {Event} event delete 버튼 클릭 이벤트
     * @return {void}
     */
    handleDeleteCoBrokingRow(event) {
        const rowKey = event.target.dataset.rowkey;
        const row = this.coBrokingRows.find((r) => r._key === rowKey);
        if (row?.Id) {
            this._coBrokingDeletedIds = [...this._coBrokingDeletedIds, row.Id];
        }
        this.coBrokingRows = this.coBrokingRows.filter((r) => r._key !== rowKey);
        this._isCoBrokingSaved = false;
        this._isCoBrokingDirty = true;
    }

    /**
     * @description Co-Broking 행의 일반 입력값 변경을 처리한다.
     * @param {Event} event input change 이벤트
     * @return {void}
     */
    handleCoBrokingRowChange(event) {
        const rowKey = event.target.dataset.rowkey;
        const field = event.target.dataset.field;
        const value = event.target.value;
        this.coBrokingRows = this.coBrokingRows.map((row) => {
            if (row._key !== rowKey) return row;
            const updated = { ...row, [field]: value || null };
            if (field === "CoBrokingType__c") {
                updated.coBrokingTypeClass = value ? "" : "error-cell";
                const isNone = value === "None";
                updated.isCoBrokingNone = isNone;
                if (isNone) {
                    updated.TBD__c = null;
                    updated.coBrokerName = "";
                    updated.coBrokerClass = "";
                }
            }
            if (field === "Currency__c") updated.currencyClass = value ? "" : "error-cell";
            return updated;
        });
        this._isCoBrokingSaved = false;
        this._isCoBrokingDirty = true;
    }

    /**
     * @description Co-Broking 행의 Insurer Lookup 변경을 처리한다.
     * @param {Event} event lookup change 이벤트
     * @return {void}
     */
    handleCoBrokingInsurerLookupChange(event) {
        const rowKey = event.target.dataset.rowkey;
        const { value, label } = event.detail;
        this.coBrokingRows = this.coBrokingRows.map((row) => {
            if (row._key !== rowKey) return row;
            return { ...row, Insurer__c: value || null, insurerName: label || "" };
        });
        this._isCoBrokingSaved = false;
        this._isCoBrokingDirty = true;
    }

    /**
     * @description Co-Broking 행의 Co-Broker Lookup 변경을 처리한다.
     * @param {Event} event lookup change 이벤트
     * @return {void}
     */
    handleCoBrokerLookupChange(event) {
        const rowKey = event.target.dataset.rowkey;
        const { value, label } = event.detail;
        this.coBrokingRows = this.coBrokingRows.map((row) => {
            if (row._key !== rowKey) return row;
            return { ...row, TBD__c: value || null, coBrokerName: label || "", coBrokerClass: value ? "" : "error-cell" };
        });
        this._isCoBrokingSaved = false;
        this._isCoBrokingDirty = true;
    }

    /**
     * @description Co-Broking 행 목록을 로컬 검증하고 저장 상태로 확정한다.
     * @return {void}
     */
    handleSaveCoBrokingRows() {
        let hasError = false;
        this.coBrokingRows = this.coBrokingRows.map((row) => {
            const updated = { ...row };
            updated.coBrokingTypeClass = !row.CoBrokingType__c ? "error-cell" : "";
            updated.currencyClass = !row.Currency__c ? "error-cell" : "";
            if (row.isCoBrokingNone) {
                updated.insurerClass = !row.Insurer__c ? "error-cell" : "";
                updated.coBrokerClass = "";
                if (!row.Insurer__c || !row.CoBrokingType__c || !row.Currency__c) hasError = true;
            } else {
                updated.coBrokerClass = !row.TBD__c ? "error-cell" : "";
                updated.insurerClass = "";
                if (!row.TBD__c || !row.CoBrokingType__c || !row.Currency__c) hasError = true;
            }
            return updated;
        });
        if (hasError) {
            toast("Validation Error", this.labels.requireField, "error");
            return;
        }
        this._isCoBrokingSaved = true;
        this._isCoBrokingDirty = false;
    }

    /**
     * @description Co-Broking 데이터를 저장한 뒤 Schedule Step으로 이동한다.
     * @return {Promise<void>}
     */
    async handleAddCoBrokingInstallments() {
        this.isLoading = true;
        try {
            const participants = this.coBrokingRows.map((row) => {
                const p = {
                    Insurer__c: row.Insurer__c || null,
                    TBD__c: row.isCoBrokingNone ? null : row.TBD__c || null,
                    CoBrokingType__c: row.CoBrokingType__c || null,
                    Currency__c: row.Currency__c || null,
                    isCoBroker__c: !row.isCoBrokingNone
                };
                if (row.Id) p.Id = row.Id;
                return p;
            });

            await saveCoBrokingParticipants({ policyId: this.recordId, participants, deletedIds: this._coBrokingDeletedIds });
            this._coBrokingDeletedIds = [];
            toast("Success", this.labels.partSaveSuccess, "success");

            const schedules = await getSchedules({ policyId: this.recordId });
            this._initScheduleRows(schedules || []);
            this.currentStep = STEP2;
        } catch (error) {
            toast("Error", error?.body?.message || "Failed to save co-broking data.", "error");
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Quick Action을 닫는다.
     * @return {void}
     */
    handleCancel() {
        this._closeAndRefresh();
    }

    // Private Methods

    /**
     * @description Policy 초기 데이터를 조회하여 내부 상태를 초기화한다.
     * @return {Promise<void>}
     */
    async _loadInitData() {
        try {
            const data = await getInitData({ policyId: this.recordId });

            this._policyTotalPremium = data.totalPremiumAmount || 0;
            this._policyTotalInstalment = data.totalInstalment || 0;
            this._policyBrokerageAmt = data.brokerageAmt || 0;
            this._policyBrokerageRate = data.brokerageRate || 0;
            this._policyWritingCarrierName = data.writingCarrierName || "";
            this._writingCarrierId = data.writingCarrierId || null;
            this._policyCurrency = data.curr || "";

            const loadedCurrency = data.curr || "";
            const loadedExchangeRate = data.exchangeRate != null ? data.exchangeRate : null;

            this.policyForm = {
                incomeClass: data.incomeClass || "",
                insurerPolicyNo: data.insurerPolicyNo || "",
                identificationValue: data.identificationValue || "",
                totalPremiumAmount: data.totalPremiumAmount ?? null,
                curr: loadedCurrency,
                totalInstalment: data.totalInstalment ?? null,
                exchangeRate: loadedExchangeRate
            };

            this.selectedAction = data.premCalcType || "Prem";
            this._incomeClassOptions = [...(data.incomeClassOptions || [])].sort((a, b) => a.label.localeCompare(b.label));
            this._currencyOptions = [...(data.currencyOptions || [])].sort((a, b) => a.label.localeCompare(b.label));
        } catch (error) {
            toast("Error", error?.body?.message || "Failed to load data.", "error");
            this.allRows = [];
        }
    }

    /**
     * @description Quick Action 종료 및 상위 리프레시 요청 이벤트를 발생시킨다.
     * @return {void}
     */
    _closeAndRefresh() {
        this.dispatchEvent(new CustomEvent("refreshrequest", { bubbles: true, composed: true }));
    }

    /**
     * @description Premium Review 화면 데이터를 조회하여 섹션 구조로 변환한다.
     * @param {Object|null} snapshot 기존 Line Item 스냅샷 맵
     * @return {Promise<void>}
     */
    async _loadReviewData(snapshot = null) {
        const data = await getReviewData({ policyId: this.recordId });
        this.reviewPolicyInfo = {
            totalPremiumAmount: data.totalPremiumAmount || 0,
            totalInstalment: data.totalInstalment || 0
        };

        const rawSections = (data.sections || []).map((sec, si) => ({
            si,
            scheduleId: sec.scheduleId,
            installmentNum: sec.installmentNum,
            installmentRate: sec.installmentRate,
            installPremium: sec.installPremium,
            items: (sec.lineItems || []).map((li, li_i) => {
                const snapKey = `${li.TPB__c}_${Math.floor(sec.installmentNum)}`;
                const snap = snapshot?.[snapKey] ?? null;
                const payNum = this._isoDateToYymmdd(li.PaymentDueDate__c);
                const expNum = snap?.expPaymentDate ? this._isoDateToYymmdd(snap.expPaymentDate) : this._isoDateToYymmdd(li.ExpPaymentDate__c);
                const dateOrderInvalid = payNum != null && expNum != null && expNum > payNum;
                return {
                    _key: `li_${si}_${li_i}`,
                    Id: li.Id,
                    Insurer__c: li.Insurer__c,
                    insurerName: li.Insurer__r ? li.Insurer__r.Name : "",
                    SignedLine__c: li.SignedLine__c,
                    Premium__c: li.Premium__c,
                    InsurerCommission__c: snap?.brokerageRate != null ? snap.brokerageRate : snap?.insurerCommission != null ? snap.insurerCommission : li.InsurerCommission__c,
                    BrokerageAmt__c: snap?.brokerageAmt != null ? snap.brokerageAmt : li.BrokerageAmt__c,
                    _hasSnapshot: !!snap,
                    paymentDueDateNum: payNum,
                    expPaymentDateNum: expNum,
                    paymentDueDateDisplay: this._yymmddToDisplay(payNum),
                    expPaymentDateDisplay: this._yymmddToDisplay(expNum),
                    paymentDueDateClass: dateOrderInvalid ? "error-cell" : "",
                    expPaymentDateClass: "",
                    paymentDueDateError: dateOrderInvalid ? this.labels.dateMsg : "",
                    expPaymentDateError: ""
                };
            })
        }));

        const nullItems = rawSections.flatMap((s) => s.items).filter((li) => li.Insurer__c && !li._hasSnapshot && (li.InsurerCommission__c == null || li.InsurerCommission__c === ""));
        const commissionMap = {};

        await Promise.all(
            [...new Set(nullItems.map((li) => li.Insurer__c))].map(async (insurerId) => {
                try {
                    const commission = await getInsurerCommission({ insurerId, policyId: this.recordId });
                    commissionMap[insurerId] = commission != null ? commission : null;
                } catch {
                    commissionMap[insurerId] = null;
                }
            })
        );

        this.reviewSections = rawSections.map(({ si, scheduleId, installmentNum, installmentRate, installPremium, items }) => {
            const resolvedItems = items.map((li) => {
                const premium = li.SignedLine__c != null && installPremium != null ? this._roundToScale((parseFloat(li.SignedLine__c) / 100) * parseFloat(installPremium)) : li.Premium__c;
                const commission = li.InsurerCommission__c == null || li.InsurerCommission__c === "" ? (li.Insurer__c ? commissionMap[li.Insurer__c] : null) : li.InsurerCommission__c;
                const brokerageAmt = li.BrokerageAmt__c != null ? li.BrokerageAmt__c : this._calcBrokerage(premium, commission);
                return { ...li, Premium__c: premium, InsurerCommission__c: commission, BrokerageAmt__c: brokerageAmt };
            });
            return this._buildSection(si, scheduleId, installmentNum, installmentRate, installPremium, resolvedItems);
        });
    }

    /**
     * @description Co-Broking Review 화면 데이터를 조회하여 섹션 구조로 변환한다.
     * @param {Object|null} snapshot 기존 Co-Broking Line Item 스냅샷 맵
     * @return {Promise<void>}
     */
    async _loadCoBrokingReviewData(snapshot = null) {
        const data = await getCoBrokingReviewData({ policyId: this.recordId });
        this.reviewPolicyInfo = {
            totalPremiumAmount: data.totalPremiumAmount || 0,
            totalInstalment: data.totalInstalment || 0
        };
        this.coBrokingReviewSections = (data.sections || []).map((sec, si) => {
            const items = (sec.lineItems || []).map((li, li_i) => {
                const snapKey = li.TPB__c ? `${li.TPB__c}_${Math.floor(sec.installmentNum)}` : `${li.Insurer__c}_${Math.floor(sec.installmentNum)}`;
                const snap = snapshot?.[snapKey] ?? null;
                const payNum = snap?.paymentDueDate ? this._isoDateToYymmdd(snap.paymentDueDate) : this._isoDateToYymmdd(li.PaymentDueDate__c);
                const expNum = snap?.expPaymentDate ? this._isoDateToYymmdd(snap.expPaymentDate) : this._isoDateToYymmdd(li.ExpPaymentDate__c);
                const dateOrderInvalid = payNum != null && expNum != null && expNum > payNum;
                return {
                    _key: `cbli_${si}_${li_i}`,
                    Id: li.Id,
                    Insurer__c: li.Insurer__c,
                    insurerName: li.Insurer__r ? li.Insurer__r.Name : "",
                    TPB__c: li.TPB__c,
                    coBrokerName: li.TPB__r ? li.TPB__r.Name : "",
                    CoBrokingType__c: li.CoBrokingType__c,
                    Currency__c: li.Currency__c,
                    BrokerageRate__c: snap?.brokerageRate != null ? snap.brokerageRate : li.BrokerageRate__c,
                    BrokerageAmt__c: snap?.brokerageAmt != null ? snap.brokerageAmt : li.BrokerageAmt__c,
                    paymentDueDateNum: payNum,
                    expPaymentDateNum: expNum,
                    paymentDueDateDisplay: this._yymmddToDisplay(payNum),
                    expPaymentDateDisplay: this._yymmddToDisplay(expNum),
                    paymentDueDateClass: dateOrderInvalid ? "error-cell" : "",
                    expPaymentDateClass: "",
                    paymentDueDateError: dateOrderInvalid ? this.labels.dateMsg : "",
                    expPaymentDateError: ""
                };
            });
            return this._buildCoBrokingSection(si, sec.scheduleId, sec.installmentNum, sec.installmentRate, sec.installPremium, items);
        });
    }

    /**
     * @description Co-Broking Review 섹션 객체를 생성한다.
     * @param {Number} si 섹션 인덱스
     * @param {String} scheduleId Schedule Id
     * @param {Number} installmentNum 분납 회차
     * @param {Number} installmentRate 분납 비율
     * @param {Number} installPremium 분납 Premium
     * @param {Array} items 섹션 Line Item 목록
     * @param {Boolean} isDirty 섹션 수정 여부
     * @return {Object} Co-Broking 섹션 객체
     */
    _buildCoBrokingSection(si, scheduleId, installmentNum, installmentRate, installPremium, items, isDirty = false) {
        const totalBrokerage = items.reduce((sum, li) => sum + (parseFloat(li.BrokerageAmt__c) || 0), 0);
        return {
            _key: `cbsec_${si}`,
            scheduleId,
            _isDirty: isDirty,
            installmentNum,
            installmentRate,
            installPremium,
            lineItems: items,
            totalBrokerage
        };
    }

    /**
     * @description Premium Review 섹션 객체를 생성한다.
     * @param {Number} si 섹션 인덱스
     * @param {String} scheduleId Schedule Id
     * @param {Number} installmentNum 분납 회차
     * @param {Number} installmentRate 분납 비율
     * @param {Number} installPremium 분납 Premium
     * @param {Array} items 섹션 Line Item 목록
     * @param {Boolean} isDirty 섹션 수정 여부
     * @return {Object} Premium Review 섹션 객체
     */
    _buildSection(si, scheduleId, installmentNum, installmentRate, installPremium, items, isDirty = false) {
        const totalSignedLine = items.reduce((sum, li) => sum + (parseFloat(li.SignedLine__c) || 0), 0);
        const totalPremium = items.reduce((sum, li) => sum + (parseFloat(li.Premium__c) || 0), 0);
        const totalBrokerage = items.reduce((sum, li) => sum + (parseFloat(li.BrokerageAmt__c) || 0), 0);
        const isPremiumValid = (installPremium || 0) > 0 && Math.abs(totalPremium - installPremium) < 0.01;
        const fmt = (v) => Number(v).toLocaleString("en-US", { minimumFractionDigits: 2, maximumFractionDigits: 2 });
        return {
            _key: `sec_${si}`,
            scheduleId,
            _isDirty: isDirty,
            isSaveDisabled: !isDirty || !isPremiumValid,
            installmentNum,
            installmentRate,
            installPremium,
            lineItems: items,
            totalSignedLine,
            totalPremium,
            totalBrokerage,
            isPremiumValid,
            premiumErrorMessage: isPremiumValid ? null : `Premium total (${fmt(totalPremium)}) does not match Install Premium (${fmt(installPremium || 0)}).`
        };
    }

    /**
     * @description Premium과 Commission으로 Brokerage Amount를 계산한다.
     * @param {Number} premium Premium 값
     * @param {Number} commission Commission 값
     * @return {Number|null} 계산된 Brokerage Amount
     */
    _calcBrokerage(premium, commission = this._insurerCommission) {
        if (premium == null || premium === "" || commission == null || commission === "") return null;
        return this._roundToScale((parseFloat(premium) * parseFloat(commission)) / 100);
    }

    /**
     * @description Schedule 날짜 필수값 및 날짜 순서를 검증한다.
     * @return {Boolean} 검증 통과 여부
     */
    _validateRequiredDates() {
        let hasError = false;
        this.scheduleRows = this.scheduleRows.map((row) => {
            const updated = { ...row };
            if (!row.CRSPaymentDueDateNum__c) {
                updated.paymentDueDateClass = "error-cell";
                updated.paymentDueDateError = "Required.";
                hasError = true;
            }
            if (!row.CRSExpPaymentDateNum__c) {
                updated.expPaymentDateClass = "error-cell";
                updated.expPaymentDateError = "Required.";
                hasError = true;
            }
            if (row.CRSPaymentDueDateNum__c && row.CRSExpPaymentDateNum__c && !updated.paymentDueDateError && row.CRSExpPaymentDateNum__c > row.CRSPaymentDueDateNum__c) {
                updated.paymentDueDateClass = "error-cell";
                updated.paymentDueDateError = this.labels.dateMsg;
                hasError = true;
            }
            return updated;
        });
        return !hasError;
    }

    /**
     * @description 모든 Participant 행의 편집 모드를 종료한다.
     * @return {void}
     */
    _exitAllEditModes() {
        if (this.allRows.some((r) => r.isEditMode)) {
            this.allRows = this.allRows.map((r) => ({ ...r, isEditMode: false }));
        }
    }

    /**
     * @description Schedule 목록을 기준으로 scheduleRows를 초기화한다.
     * @param {Array} schedules Schedule 레코드 목록
     * @return {void}
     */
    _initScheduleRows(schedules) {
        const targetCount = this._policyTotalInstalment || 0;
        const _emptyRow = (i) => ({
            _key: `new_${i}`,
            Id: null,
            CRSInstallmentRate__c: null,
            CRSInstallPremium__c: null,
            CRSInstallBrokerage__c: null,
            CRSPaymentDueDateNum__c: null,
            CRSExpPaymentDateNum__c: null,
            paymentDueDateDisplay: "",
            expPaymentDateDisplay: "",
            paymentDueDateClass: "",
            expPaymentDateClass: "",
            paymentDueDateError: "",
            expPaymentDateError: ""
        });

        if (schedules.length > 0) {
            const mapped = schedules.map((s, i) => {
                let rawPremium, premium, brokerage;
                if (s.Id) {
                    rawPremium = s.CRSInstallPremium__c != null ? parseFloat(s.CRSInstallPremium__c) : null;
                    premium = s.CRSInstallPremium__c != null ? parseFloat(s.CRSInstallPremium__c) : null;
                    brokerage = s.CRSInstallBrokerage__c != null ? parseFloat(s.CRSInstallBrokerage__c) : null;
                } else {
                    rawPremium = s.CRSInstallmentRate__c != null ? this._calcInstallPremium(s.CRSInstallmentRate__c) : s.CRSInstallPremium__c != null ? parseFloat(s.CRSInstallPremium__c) : null;
                    premium = rawPremium != null ? this._roundToScale(rawPremium) : null;
                    brokerage = this._calcBrokerage(rawPremium) ?? s.CRSInstallBrokerage__c;
                }
                return {
                    _key: s.Id ? `${s.Id}_${i}` : `row_${i}`,
                    Id: s.Id,
                    CRSInstallmentRate__c: s.CRSInstallmentRate__c,
                    _rawPremium: rawPremium,
                    CRSInstallPremium__c: premium,
                    CRSInstallBrokerage__c: brokerage,
                    CRSPaymentDueDateNum__c: s.CRSPaymentDueDateNum__c,
                    CRSExpPaymentDateNum__c: s.CRSExpPaymentDateNum__c,
                    paymentDueDateDisplay: this._yymmddToDisplay(s.CRSPaymentDueDateNum__c),
                    expPaymentDateDisplay: this._yymmddToDisplay(s.CRSExpPaymentDateNum__c),
                    paymentDueDateClass: s.CRSPaymentDueDateNum__c != null && s.CRSExpPaymentDateNum__c != null && s.CRSExpPaymentDateNum__c > s.CRSPaymentDueDateNum__c ? "error-cell" : "",
                    expPaymentDateClass: "",
                    paymentDueDateError: s.CRSPaymentDueDateNum__c != null && s.CRSExpPaymentDateNum__c != null && s.CRSExpPaymentDateNum__c > s.CRSPaymentDueDateNum__c ? this.labels.dateMsg : "",
                    expPaymentDateError: ""
                };
            });

            if (mapped.length > targetCount) {
                this._deletedScheduleIds = mapped
                    .slice(targetCount)
                    .filter((r) => r.Id)
                    .map((r) => r.Id);
                mapped.splice(targetCount);
            } else {
                this._deletedScheduleIds = [];
                while (mapped.length < targetCount) {
                    mapped.push(_emptyRow(mapped.length));
                }
            }
            this.scheduleRows = mapped;
        } else {
            this.scheduleRows = Array.from({ length: targetCount }, (_, i) => _emptyRow(i));
        }
    }

    /**
     * @description ISO 날짜 문자열을 YYMMDD 숫자로 변환한다.
     * @param {String} dateStr ISO 날짜 문자열
     * @return {Number|null} YYMMDD 숫자값
     */
    _isoDateToYymmdd(dateStr) {
        if (!dateStr) return null;
        const parts = String(dateStr).split("-");
        if (parts.length !== 3) return null;
        const yy = parts[0].slice(2);
        const mm = parts[1];
        const dd = parts[2];
        const num = parseInt(yy + mm + dd, 10);
        return isNaN(num) ? null : num;
    }

    /**
     * @description 입력 중인 숫자 문자열을 YY/MM/DD 형식으로 포맷한다.
     * @param {String} digits 숫자만 남긴 날짜 문자열
     * @return {String} YY/MM/DD 표시 문자열
     */
    _formatDateInput(digits) {
        if (digits.length <= 2) return digits;
        if (digits.length <= 4) return `${digits.slice(0, 2)}/${digits.slice(2)}`;
        return `${digits.slice(0, 2)}/${digits.slice(2, 4)}/${digits.slice(4)}`;
    }

    /**
     * @description YYMMDD 숫자를 YY/MM/DD 표시 문자열로 변환한다.
     * @param {Number} num YYMMDD 숫자값
     * @return {String} YY/MM/DD 표시 문자열
     */
    _yymmddToDisplay(num) {
        if (!num) return "";
        const s = String(Math.floor(num)).padStart(6, "0");
        return `${s.slice(0, 2)}/${s.slice(2, 4)}/${s.slice(4)}`;
    }

    /**
     * @description 현재 통화 소수점 자릿수 기준으로 값을 반올림한다.
     * @param {Number} value 반올림 대상 값
     * @return {Number} 반올림된 값
     */
    _roundToScale(value) {
        const scale = getCurrencyScale(this._policyCurrency, 2);
        const factor = Math.pow(10, scale);
        return Math.round(parseFloat(value) * factor) / factor;
    }

    /**
     * @description Install Rate와 Policy Total Premium으로 Install Premium을 계산한다.
     * @param {Number} rate Install Rate(%)
     * @return {Number|null} 계산된 Install Premium
     */
    _calcInstallPremium(rate) {
        if (rate == null || rate === "" || !this._policyTotalPremium) return null;
        return (parseFloat(rate) * this._policyTotalPremium) / 100;
    }

    /**
     * @description 숫자를 퍼센트 표시용 문자열로 포맷한다.
     * @param {Number} value 포맷할 값
     * @return {String} 소수점 2자리 퍼센트 문자열
     */
    formatPercentage(value) {
        if (!value || isNaN(value)) return "0.00";
        return Number(value).toLocaleString("en-US", {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
        });
    }

    /**
     * @description Participant 행의 필수값 유효성을 검증한다.
     * @param {Object} row Participant 행 데이터
     * @return {Boolean} 유효성 통과 여부
     */
    _isRowValid(row) {
        if (!row.Insurer__c) return false;
        const sl = row.SignedLine__c;
        if (sl === null || sl === undefined || sl === "" || parseFloat(sl) <= 0) return false;
        return true;
    }

    // Lifecycle Methods

    /**
     * @description 컴포넌트 공통 스타일을 한 번만 주입한다.
     * @return {void}
     */
    connectedCallback() {
        if (this._styleInjected) return;
        const style = document.createElement("style");
        style.innerText = [`.cus-lk-input-num-right input { text-align: right !important; }`, `.slds-modal__container { max-width: 95rem !important; width: 95vw !important; }`].join(" ");
        document.body.appendChild(style);
        this._styleInjected = true;
    }
}