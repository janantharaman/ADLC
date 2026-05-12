/**********************************************************************************
 * @filename       : oppSlipInfo.js
 * @project-name  : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-07 (수)
 * @group         :
 * @group-content :
 * @description   : Opportunity/Placement/SlipInfo 페이지 Slip Info LWC 컴포넌트
 *                  - Slip Info 조회·신규·수정·비교(diff)·저장을 처리
 *                  - TSI/TSI By Location/Gross Prem mismatch 검증, 통화 중복/삭제 확인, Flow 업로드·RI 생성 액션
 *                  - Opportunity Stage/권한/페이지 기반 버튼·입력 제어
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-07     i2max      Create
 **********************************************************************************/
import {LightningElement, api, track, wire} from 'lwc';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getRecord} from 'lightning/uiRecordApi';
import {NavigationMixin} from 'lightning/navigation';
import {refreshApex} from '@salesforce/apex';
import { callApex, toast, confirm } from 'c/com';

import OPP_SLIPINFO_OBJECT from '@salesforce/schema/OPP_SlipInfo__c';
import TYPE_FIELD from '@salesforce/schema/OPP_SlipInfo__c.Type__c';
import OPPORTUNITY_STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';

import getSlipInfo from '@salesforce/apex/OPP_SlipInfo_Ctrl.getSlipInfo';
import saveSlipInfo from '@salesforce/apex/OPP_SlipInfo_Ctrl.saveSlipInfo';
import getSlipInfoBySlipId from '@salesforce/apex/OPP_SlipInfo_Ctrl.getSlipInfoBySlipId';
import createRIOfferSlipInfo from '@salesforce/apex/OPP_SlipInfo_Ctrl.createRIOfferSlipInfo';
import getSlipInfoByPlacementId from '@salesforce/apex/OPP_SlipInfo_Ctrl.getSlipInfoByPlacementId';
import validateRIClosing from '@salesforce/apex/OPP_SlipInfo_Ctrl.validateRIClosing';
import checkUploadPermission from '@salesforce/apex/OPP_SlipInfo_Ctrl.checkUploadPermission';
import getTSIByLocation from '@salesforce/apex/OPP_SlipInfo_Ctrl.getTSIByOpportunity';
import getTSIByLocationSlip from '@salesforce/apex/OPP_SlipInfo_Ctrl.getTSIBySlipId';
import saveTSIRecords from '@salesforce/apex/OPP_SlipInfo_Ctrl.saveTSIRecords';
import getTSICurrencyOptions from "@salesforce/apex/Opp_TSIByLocationTable_Ctrl.getTSICurrencyOptions";
import validateTSITotal from '@salesforce/apex/OPP_SlipInfo_Ctrl.validateTSITotal';
import getPremiumSchedule from '@salesforce/apex/OPP_SlipInfo_Ctrl.getPremiumSchedule';
import getPremiumScheduleByOpp from '@salesforce/apex/OPP_SlipInfo_Ctrl.getPremiumScheduleByOpp';
import savePremiumSchedule from '@salesforce/apex/OPP_SlipInfo_Ctrl.savePremiumSchedule';
import deletePanelsAndPremiumByCurrency from '@salesforce/apex/OPP_SlipInfo_Ctrl.deletePanelsAndPremiumByCurrency';
import runRIClosingFlow from '@salesforce/apex/OPP_SlipInfo_Ctrl.runRIClosingFlow';
import runRIClosingFlowByPlacement from '@salesforce/apex/OPP_SlipInfo_Ctrl.runRIClosingFlowByPlacement';
import runRIEndFlowByPlacement from '@salesforce/apex/OPP_SlipInfo_Ctrl.runRIEndFlowByPlacement';
import getTransactionType from "@salesforce/apex/OPP_SlipInfo_Ctrl.getTransactionType";
import hasSoaSchedule from '@salesforce/apex/OPP_SlipInfo_Ctrl.hasSoaSchedule';
import getTerritoryOptions from '@salesforce/apex/OPP_SlipInfo_Ctrl.getTerritoryOptions';
import getGoverningLawOptions from '@salesforce/apex/OPP_SlipInfo_Ctrl.getGoverningLawOptions';
import getSlipTSI from '@salesforce/apex/OPP_SlipInfo_Ctrl.getSlipTSI';
import deletePanelsAndTSIByCurrency from '@salesforce/apex/OPP_SlipInfo_Ctrl.deletePanelsAndTSIByCurrency';
import validateRIClosingByPlacement from '@salesforce/apex/OPP_SlipInfo_Ctrl.validateRIClosingByPlacement';
import validateRIEndPlacement from '@salesforce/apex/OPP_SlipInfo_Ctrl.validateRIEndPlacement';

// Custom Label
import LABEL_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import LABEL_EDIT from '@salesforce/label/c.COM_BTN_EDIT';
import LABEL_CANCEL from '@salesforce/label/c.COM_BTN_CANCEL';
import LABEL_ADD from '@salesforce/label/c.COM_BTN_ADD';
import LABEL_CEDANT_OFFER_UPLOAD from '@salesforce/label/c.OPP_BTN_CEDANT_OFFER_UPLOAD';
import LABEL_CEDANT_CLOSING_UPLOAD from '@salesforce/label/c.OPP_BTN_CEDANT_CLOSING_UPLOAD';
import LABEL_GENERATE_RI_CLOSING from '@salesforce/label/c.OPP_BTN_GENERATE_RI_CLOSING';
import LABEL_GENERATE_RI_OFFER from '@salesforce/label/c.OPP_BTN_GENERATE_RI_OFFER';
import PLA_BTN_GENERATE_RI_END from '@salesforce/label/c.PLA_BTN_GENERATE_RI_END';
import COM_MSG_SAVE_SUCCESS from '@salesforce/label/c.COM_MSG_SAVE_SUCCESS';
import OPP_MSG_TSI_MISMATCH from '@salesforce/label/c.OPP_MSG_TSI_MISMATCH';
import COM_MSG_SAVE_FAIL from '@salesforce/label/c.COM_MSG_SAVE_FAIL';
import SLIP_MSG_GROSSPREM_MISMATCH from '@salesforce/label/c.SLIP_MSG_GROSSPREM_MISMATCH';
import SLIP_MSG_SUCCESS_RI_CLOSING from '@salesforce/label/c.SLIP_MSG_SUCCESS_RI_CLOSING';
import SLIP_MSG_FAIL_RI_CLOSING from '@salesforce/label/c.SLIP_MSG_FAIL_RI_CLOSING';
import SLIP_MSG_SUCCESS_RI_END from '@salesforce/label/c.SLIP_MSG_SUCCESS_RI_END';
import SLIP_MSG_FAIL_RI_END from '@salesforce/label/c.SLIP_MSG_FAIL_RI_END';
import SLIP_MSG_DUP_CURRENCY from '@salesforce/label/c.SLIP_MSG_DUP_CURRENCY';
import SLIP_MSG_VALIDATE_SLIP_BEFORE_TSI from '@salesforce/label/c.SLIP_MSG_VALIDATE_SLIP_BEFORE_TSI';
import SLIP_MSG_VALIDATE_TSI_CURR_REQUIRED from '@salesforce/label/c.SLIP_MSG_VALIDATE_TSI_CURR_REQUIRED';
import SLIP_MSG_DELETE_PANEL_TSI_CURRENCY from '@salesforce/label/c.SLIP_MSG_DELETE_PANEL_TSI_CURRENCY';
import SLIP_MSG_VALIDATE_SLIP_BEFORE_PREM from '@salesforce/label/c.SLIP_MSG_VALIDATE_SLIP_BEFORE_PREM';
import SLIP_MSG_VALIDATE_GROSSPREM_REQUIRED from '@salesforce/label/c.SLIP_MSG_VALIDATE_GROSSPREM_REQUIRED';
import SLIP_MSG_TSI_CURRENCY_DEL from '@salesforce/label/c.SLIP_MSG_TSI_CURRENCY_DEL';
import SLIP_MSG_PANEL_PREMSCHEDULE_DEL from '@salesforce/label/c.SLIP_MSG_PANEL_PREMSCHEDULE_DEL';


export default class OppSlipInfo extends NavigationMixin(LightningElement) {

    ZERO_DECIMAL_CURRENCIES = new Set(['KRW', 'JPY']);

    @api recordId;
    @track objectFields;
    @track formData = {};
    @track originalData = {};
    @track dirtyFields = new Set();
    @track hasUploadPermission = false;
    @track TSICurrencyOptions = [];
    @track TerritoryOptions = [];
    @track GoverningLawOptions = [];

    @api pageContext;
    wiredSlipInfoResult;
    wiredTsiResult;

    @track isEditMode = false;
    @track editingField = null;
    @track fieldUI = {};
    @track isTsiExpanded = false;

    slipInfo;
    slipInfoId;
    slipTitle = 'Slip';
    mismatchError = false;

    @track mismatchSlip = false;
    @track mismatchLocation = false;

    // 데이터 비교용
    @track previousSlipInfo = null;
    @track previousValues = {};

    // flow
    showFlowModal = false; // Document Screen Flow
    flowApiName;
    uploadType;

    // tsi
    @track tsiRows = [];
    deletedIds = [];
    deletedCurrencies = [];

    // premium Schedule
    premiumList = [];
    deletedPremiumIds = [];
    deletedPremiumCurrencies = [];

    // Declaration Slip
    transactionType;
    opportunityStage;
    hasSoaSchedule = false;

    // placement New
    isCreatingNew = false;
    newModeBackup = null;

    // gross Prem 비교
    tsiCurrencyMap = {};
    isTsiCurrencyMapReady = false;
    isPremiumMismatch = false;
    mismatchCurrencies = [];
    mismatchCurrenciesGross = [];
    mismatchCurrenciesDP = [];

    isSavingGross = false;
    isSavingTSI = false;

    labels = {
        save: LABEL_SAVE,
        edit: LABEL_EDIT,
        cancel: LABEL_CANCEL,
        add: LABEL_ADD,
        offerUpload: LABEL_CEDANT_OFFER_UPLOAD,
        closingUpload: LABEL_CEDANT_CLOSING_UPLOAD,
        generateRIClosing: LABEL_GENERATE_RI_CLOSING,
        generateRIOffer: LABEL_GENERATE_RI_OFFER,
        saveSuccessMsg: COM_MSG_SAVE_SUCCESS,
        mismatchMsg: OPP_MSG_TSI_MISMATCH,
        saveFailMsg: COM_MSG_SAVE_FAIL,
        grossPremMismatchMsg: SLIP_MSG_GROSSPREM_MISMATCH,
        generateRIEND: PLA_BTN_GENERATE_RI_END,
        successRIClosing: SLIP_MSG_SUCCESS_RI_CLOSING,
        failRIClosing: SLIP_MSG_FAIL_RI_CLOSING,
        successRIEND: SLIP_MSG_SUCCESS_RI_END,
        failRIEND: SLIP_MSG_FAIL_RI_END,
        dupCurrency: SLIP_MSG_DUP_CURRENCY,
        validateSlipBeforeTSI: SLIP_MSG_VALIDATE_SLIP_BEFORE_TSI,
        validateTSICurrRequired: SLIP_MSG_VALIDATE_TSI_CURR_REQUIRED,
        deletePanelTSICurrency: SLIP_MSG_DELETE_PANEL_TSI_CURRENCY,
        validateSlipBeforePrem: SLIP_MSG_VALIDATE_SLIP_BEFORE_PREM,
        validateGrossPremRequired: SLIP_MSG_VALIDATE_GROSSPREM_REQUIRED,
        tsiCurrencyDel: SLIP_MSG_TSI_CURRENCY_DEL,
        panelPremScheduleDel: SLIP_MSG_PANEL_PREMSCHEDULE_DEL
    }

    // edit input
    FORM_FIELDS = [
        'Type__c', 'Form__c', 'Reinsured__c', 'Insured__c', 'TerritoryScope__c', 'PolicyHolder__c',
        'PeriodFrom__c', 'PeriodTo__c', 'Location__c', 'OccupancyBiz__c', 'GoverningLaw__c',
        'ENDEffectivedDate__c', 'Amendments__c', 'Prem100__c',
        'CoveredRisk__c', 'Interest__c', 'TSI__c', 'GrossPrem100__c', 'GrossPremDP__c',
        'RICession__c', 'RIComm__c', 'OtherDeduction__c', 'LimitofLiability__c', 'Deductible__c',
        'TermsConds__c', 'ExtensionClauses__c', 'LossRecord__c', 'AddInfo__c'
    ];

    static ROW_CLASS_DEFAULT = 'slds-grid slds-gutters slds-m-bottom_x-small';
    static ROW_CLASS_ERROR = 'slds-grid slds-gutters slds-m-bottom_x-small slds-has-error';

    get TypeOptions() {

        if(this.isEndTransitionPlacement) {
            return [
                {label: 'Cedant Endorsement', value: 'Cedant Endorsement'},
                {label: 'RI Endorsement', value: 'RI Endorsement'}
            ];
        }
        return [
            {label: 'Cedant Offer', value: 'Cedant Offer'},
            {label: 'Cedant Closing', value: 'Cedant Closing'}
        ];
    }

    get territoryScopeArray() {
        const val = this.formData?.TerritoryScope__c;
        if (!val) return [];
        if (Array.isArray(val)) return val;
        if (typeof val === 'string') return val.split(';').filter(v => v);
        return [];
    }

    get GoverningLawArray() {
        const val = this.formData?.GoverningLaw__c;
        if (!val) return [];
        if (Array.isArray(val)) return val;
        if (typeof val === 'string') return val.split(';').filter(v => v);
        return [];
    }

    // context에 따라 wire 파라미터를 분리
    get opportunityIdParam() {
        return this.pageContext === 'OPPORTUNITY' ? this.recordId : null;
    }

    get relatedOpportunityIdParam() {
        if (this.pageContext === 'OPPORTUNITY') {
            return this.recordId;
        }

        return this.slipInfo?.Opportunity_lk__c
            ?? this.formData?.Opportunity_lk__c
            ?? this.originalData?.Opportunity_lk__c
            ?? null;
    }

    get slipInfoIdParam() {
        return this.pageContext === 'SLIPINFO' ? this.recordId : null;
    }

    get relatedPlacementIdParam() {
        if (this.pageContext === 'PLACEMENT') {
            return this.recordId;
        }

        return this.slipInfo?.Placement_lk__c
            ?? this.formData?.Placement_lk__c
            ?? this.originalData?.Placement_lk__c
            ?? null;
    }

    get placementSlipInfoIdParam() {
        return this.pageContext === 'PLACEMENT' ? this.slipInfoId : null;
    }

    get placementIdParam() {
        return this.pageContext === 'PLACEMENT' ? this.recordId : null;
    }

    /**
     * @description TransactionType wire — Placement 의 TransactionType 조회 후 transactionType 설정
     * @param {Object} data TransactionType 문자열
     */
    @wire(getTransactionType, {recordId: '$recordId'})
    wiredTransaction({data}) {
        if (data) {
            this.transactionType = data;
        }
    }

    /**
     * @description SOA Schedule 존재 여부 wire — hasSoaSchedule 설정
     * @param {Object} data 존재 여부 Boolean
     * @param {Object} error 오류 객체
     */
    @wire(hasSoaSchedule, { opportunityId: '$relatedOpportunityIdParam', placementId: '$relatedPlacementIdParam' })
    wiredHasSoaSchedule({ data, error }) {
        if (data !== undefined) {
            this.hasSoaSchedule = data === true;
        } else if (error) {
            this.hasSoaSchedule = false;
            console.error('SOA schedule check error:', error);
        }
    }

    // Placement에서는 Transaction Type과 무관하게 Slip 신규 생성 허용
    get isDeclarationPlacement() {
        return this.transactionType === 'Declaration';
    }

    get isPlacementSlipCreateAllowed() {
        return this.isPlacementPage;
    }
    get labelPremCurrency() {
        return this.objectFields?.Prem_Currency__c?.label ?? 'Prem Currency';
    }
    get labelSlipGrossPrem() {
        return this.objectFields?.SlipGrossPrem__c?.label ?? 'Gross Premium';
    }
    get labelSlipGrossPremDP() {
        return this.objectFields?.SlipGrossPremDP__c?.label ?? 'Gross Prem(DP Applied)';
    }

    /**
     * @description TerritoryScope__c Picklist wire — TerritoryOptions 설정
     * @param {Object} data Picklist 옵션 목록
     */
    @wire(getTerritoryOptions)
    wiredTerritoryOptions({data}) {
        this.TerritoryOptions = [];
        if (data) {
            this.TerritoryOptions = data || [];
           // this.compareWithPrevious(this.slipInfo, this.previousSlipInfo);
        }
    }

    /**
     * @description GoverningLaw__c Picklist wire — GoverningLawOptions 설정 (빈 값 제외)
     * @param {Object} data Picklist 옵션 목록
     */
    @wire(getGoverningLawOptions)
    wiredGoverningLawOptions({data}) {
        this.GoverningLawOptions = [];
        if (data) {
            this.GoverningLawOptions = data.filter(opt => opt.value !== '') || [];
            //this.compareWithPrevious(this.slipInfo, this.previousSlipInfo);
        }
    }

    /**
     * @description TSI wire — slipInfoId 기준으로 TSI 데이터를 조회하여 applyTSIResult 로 처리
     * @param {Object} result wire 결과 객체
     */
    @wire(getSlipTSI, {slipInfoId: '$slipInfoId'})
    wiredTSI(result) {
        this.wiredTsiResult = result;
        this.applyTSIResult(result);
    }

    get territoryScopeValue() {
        let val = this.formData?.TerritoryScope__c;

        if (!val) return '';

        let values = [];

        if (Array.isArray(val)) {
            values = val;
        } else if (typeof val === 'string') {
            values = val.split(';');
        } else {
            return val;
        }

        if (!this.TerritoryOptions || this.TerritoryOptions.length === 0) {
            return values.join(', ');
        }

        const labels = values.map(v => {
            const option = this.TerritoryOptions.find(
                opt => opt.value === v
            );
            return option ? option.label : v;
        });

        return labels.join(', ');
    }

    get GoverningRawValue() {
        let val = this.formData?.GoverningLaw__c;

        if (!val) return '';

        let values = [];

        if (Array.isArray(val)) {
            values = val;
        } else if (typeof val === 'string') {
            values = val.split(';');
        } else {
            return val;
        }

        if (!this.GoverningLawOptions || this.GoverningLawOptions.length === 0) {
            return values.join(', ');
        }

        const labels = values.map(v => {
            const option = this.GoverningLawOptions.find(
                opt => opt.value === v
            );
            return option ? option.label : v;
        });

        return labels.join(', ');
    }

    get slipTSIMap() {
        const map = {};
        this.tsiRows.forEach(row => {
            const cur = row.TSICurrency__c;
            if (cur) map[cur] = (map[cur] || 0) + Number(row.SlipTSI__c || 0);
        });
        return map;
    }

    get resolvedSlipInfoId() {
        if (this.slipInfoId) return this.slipInfoId;
        if (this.isSlipInfoPage && this.recordId) {
            return this.recordId;
        }
        return null;
    }

    get hasSlipInfo() {
        return !!this.resolvedSlipInfoId;
    }

    get showTSIByLocation() {
        if (this.isOpportunityPage && this.isCreatingNew) {
            return false;
        }
        return (this.hasSlipInfo && this.transactionType !== 'Declaration')
            || this.isPlacementEndWithoutSlipInfo;
    }

    // Button 제어
    get showOfferClosingUpload() {
        return this.pageContext !== 'PLACEMENT';
    }

    get isOpportunityPage() {
        return this.pageContext === 'OPPORTUNITY';
    }

    get isSlipInfoPage() {
        return this.pageContext === 'SLIPINFO';
    }

    get isPlacementPage() {
        return this.pageContext === 'PLACEMENT';
    }

    get isEndPlacement() {
        return this.isPlacementPage && (this.transactionType || '').trim().toUpperCase() === 'END';
    }

    get placementTransitionType() {
        return this.slipInfo?.Placement_lk__r?.TransactionType__c
            ?? this.formData?.Placement_lk__r?.TransactionType__c
            ?? this.transactionType
            ?? '';
    }

    get isEndTransitionPlacement() {
        return (this.placementTransitionType || '').trim().toUpperCase() === 'END';
    }

    get isEndorsementSlipType() {
        const slipType = (this.formData?.Type__c || this.slipInfo?.Type__c || '').trim();
        return slipType === 'Cedant Endorsement' || slipType === 'RI Endorsement';
    }

    // Placement END 신규(무슬립) 생성 화면에서는 Type 선택 전에도 END 컴팩트 레이아웃을 우선 노출
    get isPlacementEndWithoutSlipInfo() {
        return this.isPlacementPage && !this.hasSlipInfo && this.isEndTransitionPlacement;
    }

    // Slip Info의 Type = Cedant Endorsement 인지 여부
    get isCedantEndorsementSlipType() {
        const slipType = (this.formData?.Type__c || this.slipInfo?.Type__c || '').trim();
        return slipType === 'Cedant Endorsement';
    }

    get showEndCompactLayout() {
        const hasEndorsementSlipInfo = (this.isPlacementPage || this.isSlipInfoPage)
            && this.hasSlipInfo
            && this.isCedantEndorsementSlipType;

        return hasEndorsementSlipInfo || this.isPlacementEndWithoutSlipInfo;
    }

    get showEndPlacementFinancialSection() {
        return (this.isPlacementPage || this.isSlipInfoPage)
            && this.isCedantEndorsementSlipType;
    }

    get riskReference() {
        return this.slipInfo?.Placement_lk__r?.LKRefNoh__c
            ?? this.formData?.Placement_lk__r?.LKRefNoh__c
            ?? '';
    }

    get isOpportunityClosedStage() {
        const stage = (this.opportunityStage || '').trim();
        return stage === 'Closed Won' || stage === 'Closed Lost';
    }

    get isStageLocked() {
        return this.isOpportunityPage && this.isOpportunityClosedStage;
    }

    get isSlipInfoPlacementLocked() {
        // SlipInfo 상세에서는 연결 Opportunity 가 Closed 상태여도 Placement 가 있으면 잠금하지 않음
        return this.isSlipInfoPage
            && this.hasSlipInfo
            && this.isOpportunityClosedStage
            && !this.relatedPlacementIdParam;
    }

    get isInteractionLocked() {
        return this.isStageLocked || this.isSlipInfoPlacementLocked;
    }

    get isHeaderActionDisabled() {
        return this.isInteractionLocked;
    }

    get isHeaderEditDisabled() {
        return this.isHeaderActionDisabled || this.isEditDisabled;
    }

    get isHeaderSaveDisabled() {
        return this.isInteractionLocked;
    }

    get isHeaderNewDisabled() {
        return this.isInteractionLocked;
    }

    get isGrossPremDisabled() {
        return this.isInteractionLocked;
    }

    get isGrossPremSaveDisabled() {
        return this.isGrossPremDisabled || this.isSavingGross;
    }

    get isTSISectionDisabled() {
        return this.isInteractionLocked || this.isSavingTSI;
    }

    get isTSISaveDisabled() {
        return this.isTSISectionDisabled || this.isSavingTSI;
    }

    get isTSIByLocationLocked() {
        return this.isInteractionLocked && !this.isEndTransitionPlacement;
    }

    get isOpportunityEditDisabled() {
        return this.isOpportunityPage && this.isOpportunityClosedStage;
    }

    get isSlipInfoEditDisabled() {
        return this.isSlipInfoPlacementLocked;
    }

    get isEditDisabled() {
        return this.isOpportunityEditDisabled || this.isSlipInfoEditDisabled;
    }

    get showTsiMismatchMsg() {
        return this.mismatchSlip && !this.isEndPlacement && !this.hasSoaSchedule;
    }

    get showGrossPremMismatchMsg() {
        return this.isTsiExpanded
            && this.isTsiCurrencyMapReady
            && this.mismatchCurrenciesGross.length > 0
            && !this.hasSoaSchedule;
    }

    get showGrossPremDPMismatchMsg() {
        return this.isTsiExpanded
            && this.isTsiCurrencyMapReady
            && this.mismatchCurrenciesDP.length > 0
            && !this.hasSoaSchedule;
    }

    get grossPremDPMismatchMessage() {
        const currencies = (this.mismatchCurrenciesDP || []).join(', ');
        return `The Gross Premium(DP) value in TSI by Location does not match.: ${currencies}`;
    }

    // Offer/Closing Upload 버튼이 나타나는 페이지
    get showUploadButton() {
        return this.isOpportunityPage || this.isPlacementPage;
    }

    // Opportunity 페이지
    get showOpportunityNoSlipInfo() {
        return this.isOpportunityPage && !this.hasSlipInfo && !this.isCreatingNew;
    }

    get showOpportunityCreateMode() {
        return this.isOpportunityPage && this.isCreatingNew;
    }

    get showOpportunityWithSlipInfo() {
        return this.isOpportunityPage && this.hasSlipInfo && !this.isEditMode && !this.isCreatingNew;
    }

    get showOpportunityEditMode() {
        return this.isOpportunityPage && this.hasSlipInfo && this.isEditMode && !this.isCreatingNew;
    }

    // Placement 페이지
    get showPlacementNoSlipInfo() {
        return this.isPlacementPage && !this.hasSlipInfo && this.isPlacementSlipCreateAllowed && !this.isCreatingNew;
    }

    get showPlacementWithSlipInfo() {
        return this.isPlacementPage && this.hasSlipInfo && !this.isEditMode && !this.isCreatingNew;
    }

    get showGenerateRIEndButton() {
        return this.showPlacementWithSlipInfo && this.isEndTransitionPlacement;
    }

    get showPlacementEditMode() {
        // Placement 입력 모드(기존 수정 + New 생성)에서는 공통으로 Cancel/Save 표시
        return this.isPlacementPage && ((this.hasSlipInfo && this.isEditMode) || this.isCreatingNew);
    }

    // SlipInfo 페이지
    get showSlipInfoEditMode() {
        return this.isSlipInfoPage && this.isEditMode;
    }

    get showSlipInfoNotEditMode() {
        return this.isSlipInfoPage && !this.isEditMode;
    }

    get canEdit() {
        if (this.isInteractionLocked) {
            return false;
        }

        if (this.pageContext === 'OPPORTUNITY' && this.isCreatingNew) {
            return true;
        }

        if (this.pageContext === 'PLACEMENT' && this.isPlacementSlipCreateAllowed) {
            // New 생성 도중 비동기 wire로 isEditMode가 잠시 false가 되어도 입력 가능 상태를 유지
            return this.isEditMode || this.isCreatingNew;
        }
        return this.hasSlipInfo && this.isEditMode;
    }

    get hideTypeFieldInPlacementEdit() {
        return this.isPlacementPage
            && this.hasSlipInfo
            && this.isEditMode
            && !this.isCreatingNew;
    }

    get showTypeField() {
        return !this.hideTypeFieldInPlacementEdit;
    }

    // Opportunity 신규 생성 모드에서만 Type 선택 필드 표시
    get showOpportunityTypeField() {
        return this.isOpportunityPage && this.isCreatingNew;
    }

    /**
     * @description JSON 직렬화 가능한 화면 상태 값을 깊은 복사
     * @param {*} value 복사 대상 값
     * @returns {*} 복사된 값
     */
    cloneStateValue(value) {
        if (value === null || value === undefined) return value;
        return JSON.parse(JSON.stringify(value));
    }

    /**
     * @description New 진입 직전 현재 조회 화면 상태를 백업
     * @returns {Object} 복원용 화면 상태 백업
     */
    captureCurrentViewState() {
        return {
            slipInfo: this.cloneStateValue(this.slipInfo),
            slipInfoId: this.slipInfoId,
            slipTitle: this.slipTitle,
            formData: this.cloneStateValue(this.formData),
            originalData: this.cloneStateValue(this.originalData),
            previousSlipInfo: this.cloneStateValue(this.previousSlipInfo),
            previousValues: this.cloneStateValue(this.previousValues),
            fieldUI: this.cloneStateValue(this.fieldUI),
            tsiRows: this.cloneStateValue(this.tsiRows),
            premiumList: this.cloneStateValue(this.premiumList),
            deletedIds: this.cloneStateValue(this.deletedIds),
            deletedCurrencies: this.cloneStateValue(this.deletedCurrencies),
            deletedPremiumIds: this.cloneStateValue(this.deletedPremiumIds),
            deletedPremiumCurrencies: this.cloneStateValue(this.deletedPremiumCurrencies),
            mismatchSlip: this.mismatchSlip,
            mismatchLocation: this.mismatchLocation,
            isPremiumMismatch: this.isPremiumMismatch,
            mismatchCurrencies: this.cloneStateValue(this.mismatchCurrencies),
            mismatchCurrenciesGross: this.cloneStateValue(this.mismatchCurrenciesGross),
            mismatchCurrenciesDP: this.cloneStateValue(this.mismatchCurrenciesDP),
            tsiCurrencyMap: this.cloneStateValue(this.tsiCurrencyMap),
            isTsiCurrencyMapReady: this.isTsiCurrencyMapReady,
            isEditMode: this.isEditMode,
            isTsiExpanded: this.isTsiExpanded
        };
    }

    /**
     * @description New 취소 시 백업된 조회 화면 상태 복원
     * @param {Object} backup 복원 대상 백업 데이터
     * @returns {boolean} 복원 성공 여부
     */
    restoreViewStateFromBackup(backup) {
        if (!backup) return false;

        this.slipInfo = this.cloneStateValue(backup.slipInfo);
        this.slipInfoId = backup.slipInfoId || null;
        this.slipTitle = backup.slipTitle || 'Slip';

        this.formData = this.cloneStateValue(backup.formData) || {};
        this.originalData = this.cloneStateValue(backup.originalData) || {};
        this.formData.TerritoryScope__c = this._toArray(this.formData.TerritoryScope__c);
        this.formData.GoverningLaw__c = this._toArray(this.formData.GoverningLaw__c);

        this.previousSlipInfo = this.cloneStateValue(backup.previousSlipInfo);
        this.previousValues = this.cloneStateValue(backup.previousValues) || {};
        this.fieldUI = this.cloneStateValue(backup.fieldUI) || {};

        this.tsiRows = this.cloneStateValue(backup.tsiRows) || [];
        this.premiumList = this.cloneStateValue(backup.premiumList) || [];
        this.deletedIds = this.cloneStateValue(backup.deletedIds) || [];
        this.deletedCurrencies = this.cloneStateValue(backup.deletedCurrencies) || [];
        this.deletedPremiumIds = this.cloneStateValue(backup.deletedPremiumIds) || [];
        this.deletedPremiumCurrencies = this.cloneStateValue(backup.deletedPremiumCurrencies) || [];

        this.mismatchSlip = backup.mismatchSlip === true;
        this.mismatchLocation = backup.mismatchLocation === true;
        this.isPremiumMismatch = backup.isPremiumMismatch === true;
        this.mismatchCurrencies = this.cloneStateValue(backup.mismatchCurrencies) || [];
        this.mismatchCurrenciesGross = this.cloneStateValue(backup.mismatchCurrenciesGross) || [];
        this.mismatchCurrenciesDP = this.cloneStateValue(backup.mismatchCurrenciesDP) || [];
        this.tsiCurrencyMap = this.cloneStateValue(backup.tsiCurrencyMap) || {};
        this.isTsiCurrencyMapReady = backup.isTsiCurrencyMapReady === true;
        this.isEditMode = backup.isEditMode === true;
        this.isTsiExpanded = backup.isTsiExpanded === true;

        this.dirtyFields.clear();
        if (this.slipInfo && this.previousSlipInfo) {
            this.compareWithPrevious(this.slipInfo, this.previousSlipInfo);
        }

        return true;
    }

    /**
     * @description 편집 모드 진입 — formData 를 originalData 에 백업 후 isEditMode = true 설정
     */
    handleEditMode() {
        if (!this.hasSlipInfo || this.isEditDisabled) return;

        this.originalData = {...this.formData};
        this.isEditMode = true;
    }

    /**
     * @description
     * 신규 SlipInfo 생성 모드 진입 — formData 를 빈 값으로 초기화 후 isCreatingNew = true 설정
     * - Interaction 잠금 시 차단
     */
    handleNewSlipInfo() {
        if (this.isInteractionLocked) return;

        this.newModeBackup = this.captureCurrentViewState();

        // Opportunity New 진입 시 기존 Slip 연계 데이터가 보이지 않도록 상태를 초기화
        this.slipInfo = null;
        this.slipInfoId = null;
        this.previousSlipInfo = null;
        this.previousValues = {};

        this.tsiRows = [];
        this.premiumList = [];
        this.deletedIds = [];
        this.deletedCurrencies = [];
        this.deletedPremiumIds = [];
        this.deletedPremiumCurrencies = [];

        this.isTsiCurrencyMapReady = false;
        this.tsiCurrencyMap = {};

        this.mismatchSlip = false;
        this.mismatchLocation = false;
        this.isPremiumMismatch = false;
        this.mismatchCurrencies = [];
        this.mismatchCurrenciesGross = [];
        this.mismatchCurrenciesDP = [];

        // originalData는 기존 슬립 데이터를 보존 (Cancel 시 복원 용)
        this.formData = {
            TerritoryScope__c: [],
            GoverningLaw__c: []
        };
        this.dirtyFields.clear();
        this.fieldUI = {};
        this.isCreatingNew = true;
    }

    /**
     * @description 필드 포커스 시 editingField 를 현재 필드명으로 설정
     * @param {Event} event 포커스 이벤트
     */
    handleFocus(event) {
        this.editingField = event.currentTarget.dataset.field;
    }

    /**
     * @description 필드 포커스 해제 시 editingField 초기화
     */
    handleBlur() {
        this.editingField = null;
    }

    get wrapperClassMap() {
        const base = 'slds-col slds-size_9-of-12 cell-wrap';
        const map = {};

        this.FORM_FIELDS.forEach((field) => {
            let cls = base;

            if (this.editingField === field) {
                cls += ' cell-editing';
            } else if (this.dirtyFields.has(field)) {
                cls += ' cell-edited';
            }

            map[field] = cls;
        });

        return map;
    }

    get fields() {
        if (!this.objectFields) return {};

        const fieldData = {};
        Object.keys(this.objectFields).forEach((key) => {
            fieldData[key] = {
                label: this.objectFields[key].label,
                value: this.formData[key] || "",
                isDirty: this.dirtyFields.has(key),
                className: this.getCellClass(key)
            };
        });
        return fieldData;
    }

    /**
     * @description SlipInfo Type__c wire — slipTitle 설정
     * @param {Object} data 레코드 데이터
     * @param {Object} error 오류 객체
     */
    @wire(getRecord, {
        recordId: '$slipInfoId', fields: [TYPE_FIELD]
    }) wiredSlipInfoType({data, error}) {
        if (data) {
            const typeValue = data.fields.Type__c.value;
            this.slipTitle = `${typeValue} Slip`;
        } else if (error) {
            console.error('Error loading Slip Info:', error);
        }
    }

    /**
     * @description Opportunity Stage wire — opportunityStage 설정 및 Closed 단계 시 편집 모드 종료
     * @param {Object} data 레코드 데이터
     * @param {Object} error 오류 객체
     */
    @wire(getRecord, {
        recordId: '$relatedOpportunityIdParam', fields: [OPPORTUNITY_STAGE_FIELD]
    }) wiredOpportunityStage({data, error}) {
        if (data) {
            this.opportunityStage = data.fields.StageName.value;
            if (this.isOpportunityClosedStage) {
                this.isEditMode = false;
            }
        } else if (error) {
            this.opportunityStage = null;
        }
    }

    /**
     * @description TSICurrency__c Picklist wire — TSICurrencyOptions 설정
     * @param {Object} data Picklist 옵션 목록
     * @param {Object} error 오류 객체
     */
    @wire(getTSICurrencyOptions)
    wiredTSICurrencyOptions({data, error}) {
        this.TSICurrencyOptions = [];
        if (data) {
            this.TSICurrencyOptions = data || [];
        } else if (error) {
            console.error('Error loading TSICurrency options:', error);
        }
    }

    /**
     * @description AI 업로드 권한 wire — hasUploadPermission 설정
     * @param {Object} data 권한 여부 Boolean
     * @param {Object} error 오류 객체
     */
    @wire(checkUploadPermission)
    wiredUploadPermission({data, error}) {
        if (data !== undefined) {
            this.hasUploadPermission = data;
        } else if (error) {
            this.hasUploadPermission = false;
            console.error('Error checking upload permission:', error);
        }
    }

    get isUploadDisabled() {
        return this.isStageLocked; 
        // 권한 체크 부분 주석 처리 (추후에 수정 가능)
        //return !this.hasUploadPermission || this.isStageLocked;
    }

    /**
     * @description OPP_SlipInfo__c ObjectInfo wire — objectFields 설정
     * @param {Object} data ObjectInfo 데이터
     * @param {Object} error 오류 객체
     */
    @wire(getObjectInfo, {objectApiName: OPP_SLIPINFO_OBJECT})
    wiredObjectInfo({data, error}) {
        if (data) {
            this.objectFields = data.fields;
        } else if (error) {
            console.error('Error loading object info:', error);
        }
    }

    /**
     * @description Opportunity 페이지용 SlipInfo wire — applyWiredResult 로 처리
     * @param {Object} result wire 결과 객체
     */
    @wire(getSlipInfo, {opportunityId: '$opportunityIdParam'})
    wiredSlipInfoByOpp(result) {
        if (this.pageContext !== 'OPPORTUNITY') return;
        this.applyWiredResult(result);
    }

    /**
     * @description Opportunity 페이지용 TSIByLocation wire — applyTSIResult 로 처리
     * @param {Object} result wire 결과 객체
     */
    @wire(getTSIByLocation, {opportunityId: '$opportunityIdParam'})
    wiredTsiByOpp(result) {
        if (this.pageContext !== 'OPPORTUNITY') return;
        if (this.isCreatingNew) return;
        this.wiredTsiResult = result;
        this.applyTSIResult(result);
    }

    /**
     * @description Opportunity 페이지용 PremiumSchedule wire — applyPremiumResult 로 처리
     * @param {Object} result wire 결과 객체
     */
    @wire(getPremiumScheduleByOpp, {opportunityId: '$opportunityIdParam'})
    wiredPremiumByOpp(result) {
        if (this.pageContext !== 'OPPORTUNITY') return;
        if (this.isCreatingNew) return;
        this.wiredPremResult = result;
        this.applyPremiumResult(result);
    }

    /**
     * @description SlipInfo 상세 페이지용 SlipInfo wire — applyWiredResult 로 처리
     * @param {Object} result wire 결과 객체
     */
    @wire(getSlipInfoBySlipId, {slipInfoId: '$slipInfoIdParam'})
    wiredSlipInfoBySlipId(result) {
        if (this.pageContext !== 'SLIPINFO') return;
        this.applyWiredResult(result);
    }

    /**
     * @description SlipInfo 상세 페이지용 TSIByLocation wire — applyTSIResult 로 처리
     * @param {Object} result wire 결과 객체
     */
    @wire(getTSIByLocationSlip, {slipInfoId: '$slipInfoIdParam'})
    wiredTsiBySlip(result) {
        if (this.pageContext !== 'SLIPINFO') return;
        this.wiredTsiResult = result;
        this.applyTSIResult(result);
    }

    /**
     * @description SlipInfo 상세 페이지용 PremiumSchedule wire — applyPremiumResult 로 처리
     * @param {Object} result wire 결과 객체
     */
    @wire(getPremiumSchedule, {slipInfoId: '$slipInfoIdParam'})
    wiredPremiumBySlip(result) {
        if (this.pageContext !== 'SLIPINFO') return;
        this.wiredPremResult = result;
        this.applyPremiumResult(result);
    }

    /**
     * @description
     * Placement 페이지용 SlipInfo wire — current / compareTarget 처리
     * - SlipInfo 있으면 formData 설정 및 diff 비교, 없으면 편집 모드 진입
     * - New 작성 중에는 wire 재로딩으로 입력값이 덮어쓰이지 않도록 보호
     * @param {Object} result wire 결과 객체
     */
    hasInitialized = false;
    @wire(getSlipInfoByPlacementId, { placementId: '$placementIdParam' })
    wiredSlipInfoByPlacement(result) {

        if (this.pageContext !== 'PLACEMENT') return;

        this.wiredSlipInfoResult = result;

        const { data, error } = result;

        if (error) {
            return;
        }

        if (data === undefined) return;

        // New 작성 중에는 wire 재로딩으로 입력값/상태가 덮어쓰이지 않도록 보호
        if (this.isCreatingNew) {
            return;
        }

        const current = data?.current ?? null;
        const compareTarget = this.getCompareTarget(data);

        // SlipInfo 있음
        if (current) {

            this.slipInfo = current;
            this.slipInfoId = current.Id;
            this.previousSlipInfo = compareTarget;

            this.formData = this.decodeFormData({ ...current });
            this.originalData = this.decodeFormData({ ...current });

            this.formData.TerritoryScope__c = this._toArray(this.formData.TerritoryScope__c);
            this.formData.GoverningLaw__c = this._toArray(this.formData.GoverningLaw__c);

            // 레코드 변경 시 TSI 합계 재동기화 전까지 mismatch 계산 보류
            this.isTsiCurrencyMapReady = false;
            this.tsiCurrencyMap = {};

            // Placement에서도 이전 버전 비교 하이라이트/툴팁 반영
            this.compareWithPrevious(current, compareTarget);

            this.isEditMode = false;
            this.isCreatingNew = false;
        }
        // SlipInfo 없음 (Edit 모드)
        else {
            this.slipInfo = null;
            this.slipInfoId = null;
            this.previousSlipInfo = null;
            this.previousValues = {};
            this.fieldUI = {};
            this.dirtyFields.clear();

            this.formData = {};
            this.originalData = {};

            this.formData.TerritoryScope__c = [];
            this.formData.GoverningLaw__c = [];

            this.isTsiCurrencyMapReady = false;
            this.tsiCurrencyMap = {};

            this.isEditMode = true;
        }

        if (!this.hasInitialized) {
            this.tryValidate();
            this.hasInitialized = true;
        }
    }

    /**
     * @description Placement 페이지용 PremiumSchedule wire — applyPremiumResult 로 처리
     * @param {Object} result wire 결과 객체
     */
    @wire(getPremiumSchedule, {slipInfoId: '$placementSlipInfoIdParam'})
    wiredPremiumByPlace(result) {
        if (this.pageContext !== 'PLACEMENT') return;
        this.wiredPremResult = result;
        this.applyPremiumResult(result);
    }

    /**
     * @description TSI wire 결과 적용 — 데이터를 tsiRows 로 변환, 없으면 빈 행 추가
     * @param {Object} result wire 결과 객체 (data / error)
     */
    applyTSIResult(result) {
        if (result.data) {

            this.tsiRows = result.data.map(row => ({
                key: row.Id,
                Id: row.Id,
                TSICurrency__c: row.TSICurrency__c,
                SlipTSI__c: row.SlipTSI__c,
                _isNew: false,
                _currencyError: false,
                rowClass: 'slds-grid slds-gutters slds-m-bottom_x-small'
            }));

            if (!this.tsiRows.length) {
                this.handleAddTSI();
            }
        } else if (result.error) {
            this.tsiRows = [];
        }
    }

    /**
     * @description PremiumSchedule wire 결과 적용 — 데이터를 premiumList 로 변환, 없으면 빈 행 추가 후 Gross Prem 정합성 검증
     * @param {Object} result wire 결과 객체 (data / error)
     */
    applyPremiumResult(result) {
        if (result.data) {
            const rows = this.toPremiumRows(result.data || []);

            this.premiumList = rows.length ? rows : [];

            if (this.premiumList.length === 0) {
                this.handleAddGross();
            }

            this.validatePremiumMatch();

        } else if (result.error) {
            console.error(result.error);
        }
    }

    /**
     * @description PremiumSchedule 레코드를 행 형식으로 변환
     * @param {Array} rows PremiumSchedule 레코드 목록
     * @returns {Array} 행 형식으로 변환된 premiumList
     */
    toPremiumRows(rows) {
        return (rows || []).map(row => this.normalizePremiumRow({
            key: row.Id,
            Id: row.Id,
            Prem_Currency__c: row.Prem_Currency__c,
            SlipGrossPrem__c: row.SlipGrossPrem__c,
            SlipGrossPremDP__c: row.SlipGrossPremDP__c,
            _isNew: false,
            _currencyError: false,
            rowClass: 'slds-grid slds-gutters slds-m-bottom_x-small'
        }));
    }

    isZeroDecimalCurrency(currency) {
        return this.ZERO_DECIMAL_CURRENCIES.has((currency || '').toUpperCase());
    }

    normalizeAmountByCurrency(currency, amount) {
        if (amount === null || amount === undefined || amount === '') {
            return null;
        }

        const num = Number(amount);
        if (Number.isNaN(num)) {
            return amount;
        }

        return this.isZeroDecimalCurrency(currency) ? Math.round(num) : num;
    }

    normalizePremiumRow(row) {
        const currency = row?.Prem_Currency__c;
        const isZeroScale = this.isZeroDecimalCurrency(currency);

        return {
            ...row,
            SlipGrossPrem__c: this.normalizeAmountByCurrency(currency, row?.SlipGrossPrem__c),
            SlipGrossPremDP__c: this.normalizeAmountByCurrency(currency, row?.SlipGrossPremDP__c),
            _amountStep: isZeroScale ? '1' : '0.01'
        };
    }

    normalizePremiumRows(rows) {
        return (rows || []).map(row => this.normalizePremiumRow(row));
    }

    /**
     * @description compareTarget 또는 previous 를 반환 — data 구조에 따라 유연하게 처리
     * @param {Object} data wire 결과 data
     * @returns {Object|null} 비교 대상 SlipInfo
     */
    getCompareTarget(data) {
        return data?.compareTarget ?? data?.previous ?? null;
    }

    /**
     * @description
     * Opportunity / SlipInfo 페이지용 SlipInfo wire 결과 공통 처리
     * - current 있으면 formData 설정 및 diff 비교, 없으면 편집 모드 진입
     * - New 작성 중에는 wire 재로딩으로 입력값이 덮어쓰이지 않도록 보호
     * @param {Object} result wire 결과 객체
     */
    applyWiredResult(result) {
        this.wiredSlipInfoResult = result;
        const {data, error} = result;

        if (data === undefined && error === undefined) return;

        if (error) {
            console.error('SlipInfo wire error', error);
            return;
        }

        if (!data) return;

        // Opportunity
        if (this.pageContext === 'OPPORTUNITY') {
            // New 작성 중에는 wire 재로딩으로 입력값/상태가 덮어쓰이지 않도록 보호
            if (this.isCreatingNew) {
                return;
            }

            const current = data?.current ?? null;
            const compareTarget = this.getCompareTarget(data);

            if (current) {
                this.slipInfo = current;
                this.slipInfoId = current.Id;
                this.previousSlipInfo = compareTarget;

                this.formData = this.decodeFormData({ ...current });
                this.originalData = this.decodeFormData({ ...current });

                this.formData.TerritoryScope__c = this._toArray(this.formData.TerritoryScope__c);
                this.formData.GoverningLaw__c = this._toArray(this.formData.GoverningLaw__c);

                this.isTsiCurrencyMapReady = false;
                this.tsiCurrencyMap = {};

                // 이전 버전과 비교 dirtyFields + tooltip 세팅
                this.compareWithPrevious(current, compareTarget);

                this.isEditMode = false;
                this.tryValidate();

                return;
            }

            this.slipInfo = null;
            this.slipInfoId = null;
            this.previousSlipInfo = null;
            this.previousValues = {};
            this.fieldUI = {};
            this.formData = {};
            this.originalData = {};

            this.formData.TerritoryScope__c = [];
            this.formData.GoverningLaw__c = [];

            this.isTsiCurrencyMapReady = false;
            this.tsiCurrencyMap = {};

            this.dirtyFields.clear();
            this.isEditMode = true;
            this.tryValidate();
            return;
        }

        // SlipInfo 상세
        if (this.pageContext === 'SLIPINFO') {
            const current = data?.current ?? null;
            const compareTarget = this.getCompareTarget(data);

            if (current) {
                this.slipInfo = current;
                this.slipInfoId = current.Id;

                this.previousSlipInfo = compareTarget;

                this.formData = this.decodeFormData({ ...current });
                this.originalData = this.decodeFormData({ ...current });

                this.formData.TerritoryScope__c = this._toArray(this.formData.TerritoryScope__c);
                this.formData.GoverningLaw__c = this._toArray(this.formData.GoverningLaw__c);

                this.isTsiCurrencyMapReady = false;
                this.tsiCurrencyMap = {};

                // 상세에서 비교
                this.compareWithPrevious(current, compareTarget);

                this.isEditMode = false;
                this.tryValidate();

                return;
            }

            this.slipInfo = null;
            this.slipInfoId = null;
            this.previousSlipInfo = null;
            this.previousValues = {};
            this.fieldUI = {};
            this.formData = {};
            this.originalData = {};

            this.formData.TerritoryScope__c = [];
            this.formData.GoverningLaw__c = [];

            this.isTsiCurrencyMapReady = false;
            this.tsiCurrencyMap = {};

            this.dirtyFields.clear();
            this.isEditMode = true;
            this.tryValidate();
            return;
        }

        // fallback
        this.slipInfo = null;
        this.slipInfoId = null;
        this.formData = {};
        this.originalData = {};


        this.isTsiCurrencyMapReady = false;
        this.tsiCurrencyMap = {};

        this.dirtyFields.clear();
        this.isEditMode = true;
        this.tryValidate();
    }

    /**
     * @description 값을 배열로 변환 — null/undefined 는 빈 배열, 문자열은 ';' 로 분리
     * @param {*} val 변환할 값
     * @returns {Array} 변환된 배열
     */
    _toArray(val) {
        if (!val) return [];
        if (Array.isArray(val)) return val;
        if (typeof val === 'string') return val.split(';').filter(v => v.trim() !== '');
        return [];
    }

    /**
     * @description HTML entity 를 디코딩 — &amp; → & 등
     * @param {string} str 원본 문자열
     * @returns {string} 디코딩된 문자열
     */
    decodeHtmlEntities(str) {
        if (!str || typeof str !== 'string') return str;
        return str
            .replace(/&amp;/g, '&')
            .replace(/&lt;/g, '<')
            .replace(/&gt;/g, '>')
            .replace(/&quot;/g, '"')
            .replace(/&#39;/g, "'")
            .replace(/&nbsp;/g, ' ');
    }

    /**
     * @description 레코드 객체의 모든 문자열 필드를 HTML entity 디코딩하여 반환
     * @param {Object} record 원본 레코드 객체
     * @returns {Object} 디코딩된 레코드 객체
     */
    decodeFormData(record) {
        if (!record) return record;
        const decoded = { ...record };
        Object.keys(decoded).forEach(key => {
            if (typeof decoded[key] === 'string') {
                decoded[key] = this.decodeHtmlEntities(decoded[key]);
            }
        });
        return decoded;
    }

    /**
     * @description TSI 정합성 검증 — mismatchSlip / mismatchLocation 결과를 Apex 에서 조회하여 설정
     * @returns {Promise<void>}
     */
    tryValidate() {
        if (!this.slipInfoId && !this.opportunityIdParam) {
            return Promise.resolve();
        }

        return validateTSITotal({ slipId: this.slipInfoId })
            .then(result => {
                this.mismatchSlip = result.mismatchSlip;
                this.mismatchLocation = result.mismatchLocation;
            })
            .catch(error => {
                console.error(error);
            });
    }

    /**
     * @description 필드 Label 변환 — TerritoryScope__c, GoverningLaw__c 의 API 값을 Label 로 반환
     * @param {string} field 필드 API 명
     * @param {*} apiValue 필드 API 값
     * @returns {string} Label 로 변환된 값
     */
    getFieldLabel(field, apiValue) {
        if (!apiValue) return apiValue;

        // 문자열일 때만 split, 아니면 배열로 처리
        let values = Array.isArray(apiValue)
            ? apiValue
            : typeof apiValue === 'string'
                ? apiValue.split(';')
                : [String(apiValue)];

        if (field === 'TerritoryScope__c') {
            if (!this.TerritoryOptions?.length) return values.join(', ');
            return values.map(v => this.TerritoryOptions.find(o => o.value === v)?.label ?? v).join(', ');
        }

        if (field === 'GoverningLaw__c') {
            if (!this.GoverningLawOptions?.length) return values.join(', ');
            return values.map(v => this.GoverningLawOptions.find(o => o.value === v)?.label ?? v).join(', ');
        }

        return apiValue;
    }

    /**
     * @description diff 비교 수행 — current / previous 필드 값을 비교하여 dirtyFields / fieldUI 설정
     * @param {Object} current 현재 SlipInfo 데이터
     * @param {Object} previous 비교 대상 SlipInfo 데이터
     */
    compareWithPrevious(current, previous) {
        this.dirtyFields.clear();
        this.previousValues = {};
        this.fieldUI = {};

        if (!previous || !current) return;

        // previous 데이터를 디코딩하여 표시 값이 올바르게 보이도록 처리
        const decodedPrevious = this.decodeFormData({ ...previous });

        this.FORM_FIELDS.forEach(field => {
            let currVal = current[field];
            let prevVal = decodedPrevious[field];

            if (field === 'PeriodFrom__c' || field === 'PeriodTo__c') {
                currVal = this.formatDateOnly(currVal);
                prevVal = this.formatDateOnly(prevVal);
            }

            const curr = currVal ?? '';
            const prev = prevVal ?? '';

            if (curr !== prev) {
                this.dirtyFields.add(field);
                this.previousValues[field] = prevVal;

                const prevLabel = this.getFieldLabel(field, prevVal) ?? '(empty)';

                this.fieldUI[field] = {
                    hasPrevious: true,
                    tooltip: `Previous Value : ${prevLabel}`
                 /*   tooltip: `Previous Value : ${prevVal ?? '(empty)'}`*/
                };
            }
        });
    }

    /**
     * @description input 값 변경 핸들러 — formData 업데이트, dirtyFields 추가/제거, textarea 자동 높이 조절
     * @param {Event} event input change 이벤트
     */
    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;

        this.formData = {...this.formData, [field]: value};

        if (this.originalData[field] !== value) {
            this.dirtyFields.add(field);
        } else {
            this.dirtyFields.delete(field);
        }

        // textarea auto-grow
        const textarea = event.target;
        if (textarea.tagName === 'TEXTAREA') {
            textarea.style.height = 'auto';
            textarea.style.height = textarea.scrollHeight + 'px';
        }
    }

    /**
     * @description Cedant Offer 업로드 Flow 오픈 핸들러 — Stage 잠금 시 차단
     */

    handleOfferUpload() {
        if (this.isStageLocked) return;
        this.openFlow('OFFER');
    }

    /**
     * @description Cedant Closing 업로드 Flow 오픈 핸들러 — Stage 잠금 시 차단
     */
    handleClosingUpload() {
        if (this.isStageLocked) return;
        this.openFlow('CLOSING');
    }

    /**
     * @description Document Upload Flow 모달 오픈 — uploadType / flowApiName 설정
     * @param {string} type 업로드 유형 ('OFFER' | 'CLOSING')
     */
    openFlow(type) {
        this.uploadType = type;

        this.flowApiName = type === 'CLOSING' ? 'LK_SCR_Slip_CLOSING' : 'LK_SCR_SLIP_OFFER';

        this.showFlowModal = true;
    }

    get flowInputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    /**
     * @description Flow 상태 변경 핸들러 — FINISHED 상태 시 모달 닫고 전체 데이터 새로고침
     * @param {Event} event Flow 상태 변경 이벤트
     */
    handleFlowStatus(event) {
        if (event.detail.status === 'FINISHED') {
            this.closeFlowModal();
            void this.refreshAll();
        }
    }

    /**
     * @description Flow 모달 닫기
     */
    closeFlowModal() {
        this.showFlowModal = false;
    }

    /**
     * @description Placement 용 Closing 업로드 Flow 오픈 — Stage 잠금 시 차단
     */
    handleClosingUploadByPlacement() {
        if (this.isStageLocked) return;
        this.flowApiName = 'LK_SCR_Slip_Placement_UploadOCRClosingSlip';
        this.uploadType = 'CLOSING_PLACEMENT';
        this.showFlowModal = true;
    }

    /**
     * @description 전체 데이터 새로고침 — SlipInfo / PremiumSchedule / TSI wire 를 병렬로 refreshApex
     * @returns {Promise<void>}
     */
    async refreshAll() {
        const refreshTasks = [];

        if (this.wiredSlipInfoResult) {
            refreshTasks.push(refreshApex(this.wiredSlipInfoResult));
        }
        if (this.wiredPremResult) {
            refreshTasks.push(refreshApex(this.wiredPremResult));
        }
        if (this.wiredTsiResult) {
            refreshTasks.push(refreshApex(this.wiredTsiResult));
        }

        await Promise.all(refreshTasks);
    }

    /**
     * @description
     * 편집 취소 — 편집/신규 생성 상태 초기화 및 originalData 로 formData 복원
     * - 신규 생성 중이었으면 formData 를 빈 상태로 초기화
     * - 기존 편집이었으면 originalData 로 복원 후 diff 비교 재수행
     */
    handleCancel() {
        if (this.isInteractionLocked) return;

        const wasCreatingNewOpp = this.isOpportunityPage && this.isCreatingNew;
        const wasCreatingNewPlacement = this.isPlacementPage && this.isCreatingNew;

        this.isCreatingNew = false;
        this.isEditMode = false;

        if (wasCreatingNewOpp || wasCreatingNewPlacement) {
            const restored = this.restoreViewStateFromBackup(this.newModeBackup);
            this.newModeBackup = null;

            // restoreViewStateFromBackup 내부 compareWithPrevious 결과(dirtyFields)를 유지해야
            // Cancel 후 이전 데이터 비교 색상이 그대로 표시된다.
            this.deletedCurrencies = [];
            this.deletedPremiumCurrencies = [];
            this.deletedIds = [];
            this.deletedPremiumIds = [];

            if (restored) {
                return;
            }
        }

        if (!wasCreatingNewOpp && !wasCreatingNewPlacement) {
            this.formData = {...this.originalData};
            this.formData.TerritoryScope__c = this._toArray(this.formData.TerritoryScope__c);
            this.formData.GoverningLaw__c = this._toArray(this.formData.GoverningLaw__c);
            if (this.slipInfo) {
                // compareWithPrevious 내부에서 dirtyFields를 초기화 후 재설정하므로
                // 이후 dirtyFields.clear()를 호출하지 않아야 색상 표시가 유지된다.
                this.compareWithPrevious(this.slipInfo, this.previousSlipInfo);
            } else {
                this.dirtyFields.clear();
            }
        } else {
            this.formData = { TerritoryScope__c: [], GoverningLaw__c: [] };
            this.slipInfoId = null;
            this.slipInfo = null;
            this.previousSlipInfo = null;
            this.previousValues = {};
            this.fieldUI = {};
            this.dirtyFields.clear();
        }

        this.deletedCurrencies = [];
        this.deletedPremiumCurrencies = [];
        this.deletedIds = [];
        this.deletedPremiumIds = [];

        if (this.hasSlipInfo && !this.isCreatingNew) {
            this.isEditMode = false;
        } else if (!this.hasSlipInfo && (this.isOpportunityPage || this.isPlacementPage)) {
            this.isEditMode = true;
        }
    }

    /**
     * @description 입력값 유효성 검사 — null / 빈 문자열 / 빈 배열 등 의미 없는 값이면 false 반환
     * @param {*} value 검사할 값
     * @returns {boolean} 의미 있는 값이면 true
     */
    isMeaningfulValue(value) {
        if (value === null || value === undefined) return false;
        if (typeof value === 'string') return value.trim() !== '';
        if (Array.isArray(value)) return value.some(item => this.isMeaningfulValue(item));
        if (typeof value === 'number') return true;
        if (typeof value === 'boolean') return true;
        if (value instanceof Date) return !Number.isNaN(value.getTime());
        if (typeof value === 'object') {
            return Object.values(value).some(item => this.isMeaningfulValue(item));
        }
        return false;
    }

    /**
     * @description formData 에 입력된 값이 하나라도 있는지 확인
     * @param {Object} record 검사할 레코드 객체
     * @returns {boolean} 의미 있는 입력값이 있으면 true
     */

    hasAnyMeaningfulInput(record = {}) {
        return Object.values(record).some(value => this.isMeaningfulValue(value));
    }

    /**
     * @description SlipInfo 저장 — 신규/수정 공통 처리
     * - 신규 생성 시 입력값 존재 여부 검증
     * - Multi Picklist 를 ';' 구분 문자열로 변환 후 Apex 저장 호출
     * - 저장 성공 시 wire 새로고침
     * @returns {Promise<void>}
     */
    async handleSave() {

        if (this.isInteractionLocked) {
            return;
        }

        // 모든 신규 생성 건은 입력값이 하나도 없으면 저장 차단
        const isNewSave = this.isCreatingNew || !this.hasSlipInfo;
        if (isNewSave) {
            if (!this.hasAnyMeaningfulInput(this.formData)) {
                toast(this, 'Error', 'Please enter value before saving.', 'error');
                return;
            }
        }

        try {
            const slipInfoRecord = {
                ...this.formData
            };

            // Multi Picklist 변환
            if (Array.isArray(slipInfoRecord.TerritoryScope__c)) {
                slipInfoRecord.TerritoryScope__c = slipInfoRecord.TerritoryScope__c.join(';');
            }

            this.slipInfoId = await saveSlipInfo({
                slipInfo: slipInfoRecord,
                parentId: this.recordId,
                contextType: this.pageContext
            });

            this.isEditMode = false;
            this.isCreatingNew = false;
            this.newModeBackup = null;

            await refreshApex(this.wiredSlipInfoResult);

            toast(this, 'Success', this.labels.saveSuccessMsg, 'success');

        } catch (error) {
            console.error(error);
            toast(this, 'Error', this.labels.saveFailMsg, 'error');
        }
    }

    /**
     * @description RI Offer SlipInfo 생성 — 현재 SlipInfo 를 기반으로 복사 후 상세 페이지로 이동
     * @returns {Promise<void>}
     */
    async handleGenerateRIOffer() {
        if (this.isStageLocked) return;

        try {
            const newSlipInfoId = await createRIOfferSlipInfo({
                opportunityId: this.isPlacementPage ? null : this.recordId,
                sourceSlipInfoId: this.slipInfoId,
                placementId: this.isPlacementPage ? this.placementIdParam : null
            });

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: newSlipInfoId,
                    objectApiName: 'OPP_SlipInfo__c',
                    actionName: 'view'
                }
            });
        } catch (error) {
            toast(this, 'Error', error?.body?.message ?? error.message, 'error');
        }
    }

    /**
     * @description
     * Opportunity 기준 RI Closing 생성 — 유효성 검증 후 Flow 실행
     * - 검증 실패 시 오류 Toast 표시
     * @returns {Promise<void>}
     */
    async handleGenerateRIClosingOffer() {
        if (this.isStageLocked) return;

        try {
            const errors = await validateRIClosing({
                opportunityId: this.recordId
            });

            if (errors && errors.length > 0) {
                errors.forEach(msg => {
                    toast(this, 'Error', `• ${msg}`, 'error');
                });
                return;
            }

            // Validation 성공 → Flow 실행
            await runRIClosingFlow({
                opportunityId: this.recordId
            });

            toast(this, 'Success', this.labels.successRIClosing, 'success');

        } catch (error) {
            console.error(error);
            toast(this, 'Error', this.labels.failRIClosing, 'error');
        }
    }

    /**
     * @description
     * Placement 기준 RI Closing 생성 — 유효성 검증 후 Flow 실행
     * - 검증 실패 시 오류 Toast 표시
     * @returns {Promise<void>}
     */
    async handleGenerateRIClosingOfferByPlacement() {
        if (this.isStageLocked) return;

        try {
            const errors = await validateRIClosingByPlacement({
                placementId: this.placementIdParam
            });

            if (errors && errors.length > 0) {
                errors.forEach(msg => {
                    toast(this, 'Error', `• ${msg}`, 'error');
                });
                return;
            }

            await runRIClosingFlowByPlacement({ placementId: this.placementIdParam });
            toast(this, 'Success', this.labels.successRIClosing, 'success');

        } catch (error) {
            console.error(error);
            toast(this, 'Error', this.labels.failRIClosing, 'error');
        }
    }

    /**
     * @description
     * Placement 기준 RI END(배서) 생성 — Cedant Endorsement 존재 여부 검증 후 Flow 실행
     * - 검증 실패 시 오류 Toast 표시
     * @returns {Promise<void>}
     */
    async handleGenerateRIEndByPlacement() {
        if (this.isStageLocked) return;

        try {
            const errorMsg = await validateRIEndPlacement({
                placementId: this.placementIdParam
            });

            if (errorMsg) {
                toast(this, 'Error', errorMsg, 'error');
                return;
            }

            await runRIEndFlowByPlacement({ placementId: this.placementIdParam });
            toast(this, 'Success', this.labels.successRIEND, 'success');
        } catch (error) {
            console.error(error);
            toast(this, 'Error', this.labels.failRIEND, 'error');
        }
    }

    /**
     * @description DateTime 에서 날짜만 추출 — UTC 기준 YYYY-MM-DD 형식으로 반환
     * @param {string} value ISO 형식 DateTime 문자열
     * @returns {string} YYYY-MM-DD 형식 날짜 문자열
     */
    formatDateOnly(value) {
        if (!value) return '';

        try {
            const dateObj = new Date(value);

            if (isNaN(dateObj.getTime())) {
                return value;
            }

            const year = dateObj.getUTCFullYear();
            const month = String(dateObj.getUTCMonth() + 1).padStart(2, '0');
            const day = String(dateObj.getUTCDate()).padStart(2, '0');

            return `${year}-${month}-${day}`;
        } catch (e) {
            return value;
        }
    }

    /**
     * @description DateTime 을 분 단위로 포맷 — 'YYYY-MM-DD HH:mm' 형식으로 반환
     * @param {string} rawDate ISO 형식 DateTime 문자열
     * @returns {string} 분 단위까지 포맷된 DateTime 문자열
     */
    formatDateTimeToMinute(rawDate) {
        if (!rawDate) return '';
        return rawDate.replace('T', ' ').replace('Z', '').substring(0, 16);
    }

    get periodFromFormatted() {
        return this.formatDateTimeToMinute(this.formData?.PeriodFrom__c);
    }

    get periodToFormatted() {
        return this.formatDateTimeToMinute(this.formData?.PeriodTo__c);
    }

    /**
     * @description TSI 새로고침 — refreshApex 후 서버에서 최신 데이터를 재조회하여 화면 갱신
     * @returns {Promise<void>}
     */
    async handleRefreshTSI() {
        if (this.isInteractionLocked) return;

        this.deletedIds = [];

        const resolvedSlipInfoId = this.isSlipInfoPage ? this.recordId : this.slipInfoId;

        try {
            // refreshApex 로 wire 갱신 시도
            if (this.wiredTsiResult) {
                await refreshApex(this.wiredTsiResult);
            }

            // Refresh 클릭 시에는 항상 서버에서 최신 데이터를 재조회해 화면에 반영
            if (resolvedSlipInfoId) {
                const rows = await getSlipTSI({ slipInfoId: resolvedSlipInfoId });
                this.applyTSIResult({ data: rows });
            }
        } catch (error) {
            console.error('TSI refresh error', error);
            if (resolvedSlipInfoId) {
                const rows = await getSlipTSI({ slipInfoId: resolvedSlipInfoId });
                this.applyTSIResult({ data: rows });
            }
        }
    }

    /**
     * @description Gross Prem 새로고침 — refreshApex 후 서버에서 최신 데이터를 재조회하여 화면 갱신
     * @returns {Promise<void>}
     */
    async handleRefreshGross() {
        if (this.isInteractionLocked) return;

        this.deletedPremiumIds = [];
        this.deletedPremiumCurrencies = [];

        const resolvedSlipInfoId = this.isSlipInfoPage ? this.recordId : this.slipInfoId;

        try {
            // refreshApex 로 wire 갱신 시도
            if (this.wiredPremResult) {
                await refreshApex(this.wiredPremResult);
            }

            // Refresh 클릭 시에는 항상 서버에서 최신 데이터를 재조회해 화면에 반영
            if (resolvedSlipInfoId) {
                const rows = await getPremiumSchedule({ slipInfoId: resolvedSlipInfoId });
                this.applyPremiumResult({ data: rows });
            }
        } catch (error) {
            console.error('Gross refresh error', error);
            if (resolvedSlipInfoId) {
                const rows = await getPremiumSchedule({ slipInfoId: resolvedSlipInfoId });
                this.applyPremiumResult({ data: rows });
            }
        }
    }

    /**
     * @description TSI 빈 행 추가 — UUID 키를 생성하여 tsiRows 끝에 신규 빈 행 추가
     */
    handleAddTSI() {

        if (this.isInteractionLocked) return;

        const newKey = crypto.randomUUID();

        this.tsiRows = [
            ...this.tsiRows,
            {
                key: newKey,
                Id: null,
                TSICurrency__c: '',
                SlipTSI__c: null,
                _isNew: true,
                _currencyError: false,
                rowClass: 'slds-grid slds-gutters slds-m-bottom_x-small'
            }
        ];
    }

    /**
     * @description Gross Prem 빈 행 추가 — timestamp 키를 생성하여 premiumList 끝에 신규 빈 행 추가
     */
    handleAddGross() {
        if (this.isInteractionLocked) return;

        const newRow = {
            key: 'new_' + Date.now(),
            Id: null,
            Prem_Currency__c: '',
            SlipGrossPrem__c: null,
            SlipGrossPremDP__c: null,
            _isNew: true,
            _currencyError: false,
            _amountStep: '0.01',
            rowClass: 'slds-grid slds-gutters slds-m-bottom_x-small'
        };

        this.premiumList = [...this.premiumList, newRow];
    }

    /**
     * @description Type__c 값 변경 핸들러 — formData 의 Type__c 업데이트
     * @param {Event} event change 이벤트
     */
    handleTypeChange(event) {
        const value = event.detail.value;

        this.formData = {
            ...this.formData,
            Type__c: value
        };
    }

    /**
     * @description TSI 행 필드 값 변경 핸들러 — TSICurrency__c 중복 검증 후 tsiRows 업데이트
     * @param {Event} event change 이벤트 (data-key, data-field 속성 포함)
     */
    handleRowChange(event) {
        if (this.isInteractionLocked) return;

        const key = event.target.dataset.key;
        const field = event.target.dataset.field;

        let value = event.detail.value;
        if (Array.isArray(value)) {
            value = [...value];
        }

        this.tsiRows = this.checkCurrencyDuplicate(this.tsiRows, key, field, 'TSICurrency__c', value);
    }

    /**
     * @description DualListbox 값 변경 핸들러 — formData 의 다중 선택 필드 업데이트
     * @param {Event} event change 이벤트
     */
    handleDualListChange(event) {
        const field = event.target.dataset.field;
        const value = event.detail.value;
        this.formData = {
            ...this.formData,
            [field]: [...value]
        };
    }

    /**
     * @description
     * 통화 중복 여부 검증 및 행 상태 업데이트 — 중복 시 오류 Toast 표시 및 행 오류 클래스 적용
     * @param {Array} rows 대상 행 목록
     * @param {string} key 변경된 행의 key
     * @param {string} field 변경된 필드명
     * @param {string} currencyField 통화 필드명
     * @param {*} value 변경된 값
     * @returns {Array} 업데이트된 행 목록
     */
    checkCurrencyDuplicate(rows, key, field, currencyField, value) {
        let hasCurrencyError = false;
        if (field === currencyField && value) {
            const isDuplicate = rows.some(row => row.key !== key && row[currencyField] === value);
            if (isDuplicate) {
                toast(this, 'Error', this.labels.dupCurrency, 'error');
                hasCurrencyError = true;
            }
        }
        return rows.map(row => {
            if (row.key === key) {
                const err = field === currencyField ? hasCurrencyError : row._currencyError;
                return {
                    ...row,
                    [field]: value,
                    _currencyError: err,
                    rowClass: err ? OppSlipInfo.ROW_CLASS_ERROR : OppSlipInfo.ROW_CLASS_DEFAULT
                };
            }
            return row;
        });
    }

    /**
     * @description
     * 저장 시 통화 중복 검증 — 중복 행에 오류 클래스 적용 및 오류 Toast 표시
     * @param {Array} rows 검증할 행 목록
     * @param {string} currencyField 통화 필드명
     * @returns {{ rows: Array, hasDuplicate: boolean }} 검증 결과
     */
    validateCurrencyDuplicateOnSave(rows, currencyField) {
        const currencySet = new Set();
        let hasDuplicate = false;
        const updated = rows.map(row => {
            const cur = row[currencyField];
            const isDup = cur && currencySet.has(cur);
            if (isDup) hasDuplicate = true;
            if (cur) currencySet.add(cur);
            return {
                ...row,
                _currencyError: isDup,
                rowClass: isDup ? OppSlipInfo.ROW_CLASS_ERROR : OppSlipInfo.ROW_CLASS_DEFAULT
            };
        });
        if (hasDuplicate) {
            toast(this, 'Error', this.labels.dupCurrency, 'error');
        }
        return { rows: updated, hasDuplicate };
    }

    /**
     * @description TSI 행 삭제 핸들러 — deletedIds / deletedCurrencies 에 추가 후 tsiRows 에서 제거
     * @param {Event} event 클릭 이벤트 (data-key 속성 포함)
     */
    handleDeleteRow(event) {
        if (this.isInteractionLocked) return;

        const key = event.currentTarget.dataset.key;

        const currentRows = Array.isArray(this.tsiRows) ? [...this.tsiRows] : [];

        const rowToDelete = currentRows.find(r => r.key === key);

        if (!rowToDelete) return;

        const currency = rowToDelete.TSICurrency__c;

        if (currency) {
            this.deletedCurrencies = [...this.deletedCurrencies, currency];
        }

        if (rowToDelete.Id) {
            this.deletedIds = [...this.deletedIds, rowToDelete.Id];
        }

        this.tsiRows = currentRows.filter(row => row.key !== key);
    }

    /**
     * @description
     * TSI 저장 — 필수 값 및 중복 통화 검증 후 Panel/TSIByLocation 삭제 확인 및 INSERT / UPDATE / DELETE 처리
     * - Panel 존재 시 Confirm 모달 표시 후 사용자 선택에 따라 삭제 수행
     * - 저장 성공 후 TSIByLocation 테이블 및 wire 새로고침
     * @returns {Promise<void>}
     */
    async handleSaveTSI() {

        if (this.isInteractionLocked) {
            return;
        }

        if (this.isSavingTSI) return;
        this.isSavingTSI = true;

        try {
            // Slip Info 체크
            if (!this.slipInfoId) {
                toast(this, 'Error', this.labels.validateSlipBeforeTSI, 'error');
                return;
            }

            // 필수값 체크 (Currency, Amount)
            const hasEmpty = this.tsiRows.some(row => !row.TSICurrency__c || row.SlipTSI__c == null || row.SlipTSI__c === '');
            if (hasEmpty) {
                toast(this, 'Error', this.labels.validateTSICurrRequired, 'error');
                return;
            }

            const { rows: validatedTsiRows, hasDuplicate } = this.validateCurrencyDuplicateOnSave(this.tsiRows, 'TSICurrency__c');
            this.tsiRows = validatedTsiRows;
            if (hasDuplicate) return;

            if (this.deletedCurrencies.length > 0) {

                // Panel 존재 여부 체크
                const hasPanel = await callApex(this, deletePanelsAndTSIByCurrency, {
                    placementId: this.placementId,
                    opportunityId: this.recordId,
                    slipInfoId: this.slipInfoId,
                    tsiCurrencies: this.deletedCurrencies,
                    doDelete: false
                });

                // deletePanelTSICurrency => Panel & TSI By Location 레코드 삭제 안내 MSG
                // tsiCurrencyDel => TSI By Location 레코드 삭제 안내 MSG
                const confirmMessage = hasPanel
                    ? this.labels.deletePanelTSICurrency : this.labels.tsiCurrencyDel;

                const confirmed = await confirm(confirmMessage, 'Confirm Delete');
                if (!confirmed) {
                    // Confirm 취소 시 삭제 대기 상태를 비우고 서버 조회값으로 화면 복원
                    this.deletedIds = [];
                    this.deletedCurrencies = [];
                    await this.handleRefreshTSI();
                    return;
                }

                await callApex(this, deletePanelsAndTSIByCurrency, {
                    placementId: this.placementId,
                    opportunityId: this.recordId,
                    slipInfoId: this.slipInfoId,
                    tsiCurrencies: this.deletedCurrencies,
                    doDelete: true
                });

                // TSIByLocation 테이블 갱신
                const child = this.template.querySelector('c-opp-t-s-i-by-location-table');
                if (child) await child.refresh();
            }

            const insertList = [];
            const updateList = [];

            this.tsiRows.forEach(row => {

                const record = {
                    Id: row.Id,
                    TSICurrency__c: row.TSICurrency__c,
                    SlipTSI__c: row.SlipTSI__c,
                    SlipInfo_md__c: this.slipInfoId,
                    Type__c: 'Slip'
                };

                if (!row.Id) {
                    delete record.Id;
                    insertList.push(record);
                } else {
                    updateList.push(record);
                }
            });

            const result = await callApex(this, saveTSIRecords, {
                slipInfoId: this.slipInfoId,
                insertList,
                updateList,
                deleteIds: this.deletedIds
            });

            const child = this.template.querySelector('c-opp-t-s-i-by-location-table');
            if (child) await child.refresh();

            // 초기화
            this.deletedIds = [];
            this.deletedCurrencies = [];

            this.tsiRows = this.tsiRows.map(row => ({
                ...row,
                _currencyError: false,
                rowClass: 'slds-grid slds-gutters slds-m-bottom_x-small'
            }));

            this.mismatchSlip = result.mismatchSlip;
            this.mismatchLocation = result.mismatchLocation;

            // 저장 직후 서버 상태로 동기화해 임시(_isNew) 행이 재삽입되지 않도록 보장
            if (this.wiredTsiResult) {
                await refreshApex(this.wiredTsiResult);
            }

            await this.tryValidate();

            toast(this, 'Success', this.labels.saveSuccessMsg, 'success');

        } catch (error) {
            console.error(error);
        } finally {
            this.isSavingTSI = false;
        }
    }

    /**
     * @description Gross Prem 행 삭제 핸들러 — deletedPremiumIds / deletedPremiumCurrencies 에 추가 후 premiumList 에서 제거
     * @param {Event} event 클릭 이벤트 (data-key 속성 포함)
     */
    handleDeleteGrossRow(event) {
        if (this.isInteractionLocked) return;

        const key = event.currentTarget.dataset.key;

        const row = this.premiumList.find(r => r.key === key);

        if (row.Id) {
            this.deletedPremiumIds.push(row.Id);
        }

        if (row?.Prem_Currency__c) {
            this.deletedPremiumCurrencies = [...new Set([
                ...(this.deletedPremiumCurrencies || []),
                row.Prem_Currency__c
            ])];
        }

        this.premiumList = this.premiumList.filter(r => r.key !== key);
    }

    /**
     * @description Gross Prem 행 필드 값 변경 핸들러 — 통화 중복 검증 후 premiumList 업데이트 및 Gross Prem 정합성 재검증
     * @param {Event} event change 이벤트 (data-key, data-field 속성 포함)
     */
    handleGrossRowChange(event) {
        if (this.isInteractionLocked) return;

        const key = event.target.dataset.key;
        const field = event.target.dataset.field;

        let value = event.target.value;

        if (event.target.type === 'number') {
            value = value === '' ? null : Number(value);
        }

        const updatedRows = this.checkCurrencyDuplicate(this.premiumList, key, field, 'Prem_Currency__c', value);
        this.premiumList = this.normalizePremiumRows(updatedRows);

        this.validatePremiumMatch();
    }

    /**
     * @description
     * Gross Prem 저장 — 필수 값 및 중복 통화 검증 후 연관 Panel / PremiumSchedule 삭제 확인 및 INSERT / UPDATE / DELETE 처리
     * - 연관 데이터 존재 시 Confirm 모달 표시 후 사용자 선택에 따라 삭제 수행
     * - 저장 성공 후 premiumList 갱신 및 wire 새로고침
     * @returns {Promise<void>}
     */
    async handleSaveGross() {

        if (this.isInteractionLocked) {
            return;
        }

        // SlipInfo 없는 상태에서는 저장 시도 후 버튼이 잠기지 않도록 먼저 차단
        if (!this.slipInfoId) {
            toast(this, 'Error', this.labels.validateSlipBeforePrem, 'error');
            return;
        }

        if (this.isSavingGross) return;
        this.isSavingGross = true;

        try {

            // 신규 행 값 체크
            const invalidRow = this.premiumList.find(row =>
                    !row.Id && (
                        !row.Prem_Currency__c ||
                        row.SlipGrossPrem__c == null ||
                        row.SlipGrossPremDP__c == null
                    )
            );

            if (invalidRow) {
                toast(this, 'Error', this.labels.validateGrossPremRequired, 'error');
                return;
            }

            const { rows: validatedPremRows, hasDuplicate } = this.validateCurrencyDuplicateOnSave(this.premiumList, 'Prem_Currency__c');
            this.premiumList = validatedPremRows;
            if (hasDuplicate) return;

            const insertList = [];
            const updateList = [];

            if ((this.deletedPremiumCurrencies || []).length > 0) {
                const resolvedPlacementId = this.isPlacementPage
                    ? this.placementIdParam
                    : (this.slipInfo?.Placement_lk__c || null);

                const resolvedOpportunityId = this.isOpportunityPage
                    ? this.recordId
                    : (this.slipInfo?.Opportunity_lk__c
                        || this.formData?.Opportunity_lk__c
                        || this.originalData?.Opportunity_lk__c
                        || null);

                const hasRelatedData = await callApex(this, deletePanelsAndPremiumByCurrency, {
                    placementId: resolvedPlacementId,
                    opportunityId: resolvedOpportunityId,
                    slipInfoId: this.slipInfoId,
                    premCurrencies: this.deletedPremiumCurrencies,
                    doDelete: false
                });

                if (hasRelatedData) {
                    const confirmed = await confirm(
                        this.labels.panelPremScheduleDel,
                        'Confirm Delete'
                    );

                    if (!confirmed) {
                        return;
                    }

                    await callApex(this, deletePanelsAndPremiumByCurrency, {
                        placementId: resolvedPlacementId,
                        opportunityId: resolvedOpportunityId,
                        slipInfoId: this.slipInfoId,
                        premCurrencies: this.deletedPremiumCurrencies,
                        doDelete: true
                    });
                }
            }

            this.premiumList.forEach(row => {
                const record = {
                    Prem_Currency__c: row.Prem_Currency__c,
                    SlipGrossPremDP__c: row.SlipGrossPremDP__c,
                    SlipGrossPrem__c: row.SlipGrossPrem__c,
                    SlipInfo_lk__c: this.slipInfoId,
                    Type__c: 'Slip'
                };

                // 실제 컨텍스트 id 기준으로 lookup 설정
                if (this.placementIdParam) {
                    record.Placement_lk__c = this.placementIdParam;
                } else if (this.opportunityIdParam) {
                    record.Opportunity_lk__c = this.opportunityIdParam;
                }

                if (!row.Id) {
                    insertList.push(record);
                } else {
                    record.Id = row.Id;
                    updateList.push(record);
                }
            });

            console.log('insertList:', JSON.stringify(insertList));
            console.log('updateList:', JSON.stringify(updateList));

            const savedRows = await savePremiumSchedule({
                slipInfoId: this.slipInfoId,
                insertList: insertList,
                updateList: updateList,
                // Todo : 수정 사항 반영 주석처리
                // deleteIds: this.deletedPremiumIds,
                deleteIds: this.deletedPremiumIds
            });

            this.premiumList = this.toPremiumRows(savedRows || []);

            if (this.premiumList.length === 0) {
                this.handleAddGross();
            }

            this.validatePremiumMatch();

            if (this.wiredPremResult && this.pageContext !== 'PLACEMENT') {
                await refreshApex(this.wiredPremResult);
            }

            // 삭제 배열 초기화
            this.deletedPremiumIds = [];
            this.deletedPremiumCurrencies = [];

            toast(this, 'Success', this.labels.saveSuccessMsg, 'success');

        } catch (error) {

            console.error(error);
            toast(this, 'Error', error?.body?.message || error?.message || this.labels.saveFailMsg, 'error');
        } finally {
            this.isSavingGross = false;
        }
    }

    /**
     * @description 신규 생성 폼의 시각적 상태 초기화 — dirtyFields / fieldUI / previousValues / editingField 초기화
     */
    resetNewFormVisualState() {
        this.dirtyFields.clear();
        this.fieldUI = {};
        this.previousValues = {};
        this.previousSlipInfo = null;
        this.editingField = null;
    }

    /**
     * @description Placement 신규 SlipInfo 생성 모드 진입 — formData 를 빈 값으로 초기화 후 편집 모드 전환
     */
    handleNew() {
        if (this.isStageLocked) return;

        if (!this.hasSlipInfo) return;

        this.newModeBackup = this.captureCurrentViewState();
        this.originalData = {...this.formData};

        this.isCreatingNew = true;
        this.isEditMode = true;
        this.resetNewFormVisualState();

        this.formData = {
            Type__c: '',
            Form__c: '',
            Reinsured__c: '',
            Insured__c: '',
            PeriodFrom__c: null,
            PeriodTo__c: null,
            Location__c: '',
            TerritoryScope__c: [],
            GoverningLaw__c: [],
            OccupancyBiz__c: '',
            CoveredRisk__c: '',
            Interest__c: '',
            TSI__c: '',
            GrossPrem100__c: '',
            GrossPremDP100__c: '',
            RICession__c: '',
            RIComm__c: '',
            OtherDeduction__c: '',
            LimitofLiability__c: '',
            Deductible__c: '',
            TermsConds__c: '',
            ExtensionClauses__c: '',
            LossRecord__c: '',
            AddInfo__c: ''
        };

    }

    /**
     * @description TSI by Location 변경 이벤트 핸들러 — tsiCurrencyMap 업데이트 후 Gross Prem 정합성 재검증
     * @param {CustomEvent} event TSI 변경 이벤트 (detail: tsiCurrencyMap)
     */
    handlePremChange(event) {
        this.tsiCurrencyMap = event.detail;
        this.isTsiCurrencyMapReady = true;

        this.validatePremiumMatch();
    }

    /**
     * @description
     * Gross Prem 정합성 검증 — premiumList 와 tsiCurrencyMap 의 통화별 합계를 비교하여 mismatchCurrencies 설정
     * - 0.01 이상 차이가 있는 통화를 불일치로 판단
     */
    validatePremiumMatch() {

        // TSI by Location 합계 이벤트가 오기 전에는 오탐 방지를 위해 비교하지 않음
        if (!this.isTsiCurrencyMapReady || !this.premiumList?.length || !this.tsiCurrencyMap) {
            this.isPremiumMismatch = false;
            this.mismatchCurrencies = [];
            this.mismatchCurrenciesGross = [];
            this.mismatchCurrenciesDP = [];
            return;
        }

        // premiumList → currency별 합산
        const premiumMap = {};
        this.premiumList.forEach(row => {
            const cur = row.Prem_Currency__c;
            if (!cur) return;
            if (!premiumMap[cur]) {
                premiumMap[cur] = { gross: 0, dp: 0 };
            }
            premiumMap[cur].gross += Number(row.SlipGrossPrem__c || 0);
            premiumMap[cur].dp += Number(row.SlipGrossPremDP__c || 0);
        });

        // tsiMap → currency별 합산
        const tsiTotalMap = {};
        Object.entries(this.tsiCurrencyMap).forEach(([cur, tsi]) => {
            if (!tsiTotalMap[cur]) {
                tsiTotalMap[cur] = { sumBfDP: 0, sumDP: 0 };
            }
            tsiTotalMap[cur].sumBfDP += Number(tsi.sumBfDP || 0);
            tsiTotalMap[cur].sumDP += Number(tsi.sumDP || 0);
        });

        console.log('premiumMap:', JSON.stringify(premiumMap));
        console.log('tsiTotalMap:', JSON.stringify(tsiTotalMap));

        // 양쪽 currency 합집합으로 체크
        const currencySet = new Set([
            ...Object.keys(premiumMap),
            ...Object.keys(tsiTotalMap)
        ]);

        const mismatchList = [];
        const mismatchGrossList = [];
        const mismatchDPList = [];
        currencySet.forEach(cur => {
            const prem = premiumMap[cur] || { gross: 0, dp: 0 };
            const tsi = tsiTotalMap[cur] || { sumBfDP: 0, sumDP: 0 };

            const isZeroScale = this.isZeroDecimalCurrency(cur);

            const normalizedPremGross = this.normalizeAmountByCurrency(cur, prem.gross) ?? 0;
            const normalizedPremDp = this.normalizeAmountByCurrency(cur, prem.dp) ?? 0;
            const normalizedTsiGross = this.normalizeAmountByCurrency(cur, tsi.sumBfDP) ?? 0;
            const normalizedTsiDp = this.normalizeAmountByCurrency(cur, tsi.sumDP) ?? 0;

            const isGrossMismatch = isZeroScale
                ? normalizedPremGross !== normalizedTsiGross
                : Math.abs(normalizedPremGross - normalizedTsiGross) > 0.01;
            const isDPMismatch = isZeroScale
                ? normalizedPremDp !== normalizedTsiDp
                : Math.abs(normalizedPremDp - normalizedTsiDp) > 0.01;

            if (isGrossMismatch || isDPMismatch) {
                mismatchList.push(cur);
                if (isGrossMismatch) mismatchGrossList.push(cur);
                if (isDPMismatch) mismatchDPList.push(cur);
                console.log(`❌ Mismatch [${cur}]`);
                console.log('PremGross:', prem.gross, 'TSI sumBfDP:', tsi.sumBfDP);
                console.log('PremDP:', prem.dp, 'TSI sumDP:', tsi.sumDP);
            }
        });

        this.mismatchCurrencies = mismatchList;
        this.mismatchCurrenciesGross = mismatchGrossList;
        this.mismatchCurrenciesDP = mismatchDPList;
        this.isPremiumMismatch = mismatchList.length > 0;
    }

    get TypeLabel() {
        return this.objectFields?.Type__c?.label ?? 'Type';
    }

    get FormLabel() {
        return this.objectFields?.Form__c?.label ?? 'Form';
    }

    get ReinsuredLabel() {
        return this.objectFields?.Reinsured__c?.label ?? 'Reinsured';
    }

    get InsuredLabel() {
        return this.objectFields?.Insured__c?.label ?? 'Insured';
    }

    get PeriodFromLabel() {
        return this.objectFields?.PeriodFrom__c?.label ?? 'Period From';
    }

    get PeriodToLabel() {
        return this.objectFields?.PeriodTo__c?.label ?? 'Period To';
    }

    get LocationLabel() {
        return this.objectFields?.Location__c?.label ?? 'Location';
    }

    get TerritoryScopeLabel() {
        return this.objectFields?.TerritoryScope__c?.label ?? 'Territory Scope';
    }

    get GoverningLawLabel() {
        return this.objectFields?.GoverningLaw__c?.label ?? 'Choice of Law and Jurisdiction';
    }

    get OccupancyLabel() {
        return this.objectFields?.OccupancyBiz__c?.label ?? 'Occupancy (business)';
    }

    get CoveredRiskLabel() {
        return this.objectFields?.CoveredRisk__c?.label ?? 'Covered Risk';
    }

    get InterestLabel() {
        return this.objectFields?.Interest__c?.label ?? 'Interest';
    }

    get TSILabel() {
        return this.objectFields?.TSI__c?.label ?? 'Total Sum Insured';
    }

    get RICessionLabel() {
        return this.objectFields?.RICession__c?.label ?? 'RI Cession(Reins.) (%)';
    }

    get RICommLabel() {
        return this.objectFields?.RIComm__c?.label ?? 'RI Comm (%)';
    }

    get OtherDeductionLabel() {
        return this.objectFields?.OtherDeduction__c?.label ?? 'Other Deduction';
    }

    get LimitOfLiabilityLabel() {
        return this.objectFields?.LimitofLiability__c?.label ?? 'Limit of Liability';
    }

    get DeductibleLabel() {
        return this.objectFields?.Deductible__c?.label ?? 'Deductible';
    }

    get TermsCondsLabel() {
        return this.objectFields?.TermsConds__c?.label ?? 'Terms and Conditions';
    }

    get ExtensionClausesLabel() {
        return this.objectFields?.ExtensionClauses__c?.label ?? 'Extension Clauses';
    }

    get LossRecordLabel() {
        return this.objectFields?.LossRecord__c?.label ?? 'Loss Record';
    }

    get AddInfoLabel() {
        return this.objectFields?.AddInfo__c?.label ?? 'Additional Information';
    }

    get ENDEffectivedDateLabel() {
        return this.objectFields?.ENDEffectivedDate__c?.label ?? 'END Effective Date';
    }

    get AmendmentsLabel() {
        return this.objectFields?.Amendments__c?.label ?? 'Amendments';
    }

    get Prem100Label() {
        return this.objectFields?.Prem100__c?.label ?? 'PREMIUM (100%)';
    }

    get endEffectiveDateFormatted() {
        return this.formatDateTimeToMinute(this.formData?.ENDEffectivedDate__c);
    }

    get TypeUI() { return this.fieldUI.Type__c || {}; }

    get ENDEffectivedDateUI() {
        return this.fieldUI.ENDEffectivedDate__c || {};
    }

    get AmendmentsUI() {
        return this.fieldUI.Amendments__c || {};
    }

    get Prem100UI() {
        return this.fieldUI.Prem100__c || {};
    }

    get formUI() {
        return this.fieldUI.Form__c || {};
    }

    get ReinsuredUI() {
        return this.fieldUI.Reinsured__c || {};
    }

    get InsuredUI() {
        return this.fieldUI.Insured__c || {};
    }

    get PolicyHolderUI() {
        return this.fieldUI.PolicyHolder__c || {};
    }

    get PeriodFromUI() {
        return this.fieldUI.PeriodFrom__c || {};
    }

    get PeriodToUI() {
        return this.fieldUI.PeriodTo__c || {};
    }

    get LocationUI() {
        return this.fieldUI.Location__c || {};
    }

    get TerritoryScopeUI() {
        return this.fieldUI.TerritoryScope__c || {};
    }

    get GoverningLawUI() {
        return this.fieldUI.GoverningLaw__c || {};
    }

    get OccupancyBizUI() {
        return this.fieldUI.OccupancyBiz__c || {};
    }

    get TSIUI() {
        return this.fieldUI.TSI__c || {};
    }

    get CoveredRiskUI() {
        return this.fieldUI.CoveredRisk__c || {};
    }

    get InterestUI() {
        return this.fieldUI.Interest__c || {};
    }

    get RICessionUI() {
        return this.fieldUI.RICession__c || {};
    }

    get RICommUI() {
        return this.fieldUI.RIComm__c || {};
    }

    get OtherDeductionUI() {
        return this.fieldUI.OtherDeduction__c || {};
    }

    get LimitofLiabilityUI() {
        return this.fieldUI.LimitofLiability__c || {};
    }

    get DeductibleUI() {
        return this.fieldUI.Deductible__c || {};
    }

    get TermsCondsUI() {
        return this.fieldUI.TermsConds__c || {};
    }

    get ExtensionClausesUI() {
        return this.fieldUI.ExtensionClauses__c || {};
    }

    get LossRecordUI() {
        return this.fieldUI.LossRecord__c || {};
    }

    get AddInfoUI() {
        return this.fieldUI.AddInfo__c || {};
    }

    get tsiIconName() {
        return this.isTsiExpanded ? 'utility:chevrondown' : 'utility:chevronright';
    }

    /**
     * @description TSI 섹션 펼침/접힘 토글
     */
    handleTsiCollapse() {
        this.isTsiExpanded = !this.isTsiExpanded;
    }

    /**
     * @description 컴포넌트 초기화 — TSI 정합성 검증 및 CSS 스타일 주입
     */
    connectedCallback() {
        this.tryValidate();
        console.log('objectApiName:', this.objectApiName);
        console.log('recordId:', this.recordId);
        const style = document.createElement('style');
        style.innerText = `.cus-lk-input-right input { text-align: right !important; } `;
        document.body.appendChild(style);
    }


}