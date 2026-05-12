/**********************************************************************************
 * @filename       : oppRISlipInfo.js
 * @project-name  : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-28 (수)
 * @group         :
 * @group-content :
 * @description   : RI Slip Info 상세 조회·편집·저장을 처리하는 LWC 컴포넌트
 *                  - RI SlipInfo(current/previous) 로드 및 Cedant Slip과 필드 diff 비교(하이라이트·툴팁)
 *                  - TSI 행 추가·수정·삭제·저장, 다국어 커스텀 라벨 로드, 각종 Picklist 옵션 wire 조회
 *                  - PremiumSchedule 존재 여부에 따른 PremiumPaymentTerms 제어, END/배서 타입 레이아웃 분기
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-28     i2max      Create
 **********************************************************************************/

import {api, LightningElement, track, wire} from 'lwc';
import {getObjectInfo, getPicklistValues} from "lightning/uiObjectInfoApi";
import {getRecord} from 'lightning/uiRecordApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {refreshApex} from '@salesforce/apex';
import OPP_SLIPINFO_OBJECT from "@salesforce/schema/OPP_SlipInfo__c";
import TYPE_FIELD from '@salesforce/schema/OPP_SlipInfo__c.Type__c';
import OPPORTUNITY_STAGE_FIELD from '@salesforce/schema/Opportunity.StageName';
import getRISlipInfo from '@salesforce/apex/OPP_RISlipInfo_Ctrl.getRISlipInfo';
import saveSlip from '@salesforce/apex/OPP_RISlipInfo_Ctrl.saveSlip';
import getPremiumPaymentDaysOptions from '@salesforce/apex/OPP_RISlipInfo_Ctrl.getPremiumPaymentDaysOptions';
import getRITypeOptions from '@salesforce/apex/OPP_RISlipInfo_Ctrl.getRITypeOptions';
import getTorLswOptions from '@salesforce/apex/OPP_RISlipInfo_Ctrl.getTorLswOptions';
import hasValidPremiumSchedule from '@salesforce/apex/OPP_RISlipInfo_Ctrl.hasValidPremiumSchedule';
import getTerritoryOptions from "@salesforce/apex/OPP_SlipInfo_Ctrl.getTerritoryOptions";
import getGoverningLawOptions from '@salesforce/apex/OPP_SlipInfo_Ctrl.getGoverningLawOptions';
import getTexts from '@salesforce/apex/OPP_RISlipInfo_Ctrl.getTexts';
import getCountryOriginLabel from '@salesforce/apex/OPP_RISlipInfo_Ctrl.getCountryOriginLabel'
import getSlipTSI from '@salesforce/apex/OPP_RISlipInfo_Ctrl.getSlipTSI';
import getTSICurrencyOptions from "@salesforce/apex/Opp_TSIByLocationTable_Ctrl.getTSICurrencyOptions";
import saveTSIRecords from '@salesforce/apex/OPP_SlipInfo_Ctrl.saveTSIRecords';

// Custom Label
import SLIP_CLAUSE_FOREX_REINS from '@salesforce/label/c.SLIP_CLAUSE_FOREX_REINS';
import SLIP_CLAUSE_INTERMEDIARY_SG from '@salesforce/label/c.SLIP_CLAUSE_INTERMEDIARY_SG';
import SLIP_DOC_BASIS_OF_SIGNED_LINES from '@salesforce/label/c.SLIP_DOC_BASIS_OF_SIGNED_LINES';
import SLIP_DOC_BASIS_OF_WRITTEN_LINES from '@salesforce/label/c.SLIP_DOC_BASIS_OF_WRITTEN_LINES';
import SLIP_DOC_RECORDING_ETC from '@salesforce/label/c.SLIP_DOC_RECORDING_ETC';
import SLIP_DOC_REINSURER_CONDITION from '@salesforce/label/c.SLIP_DOC_REINSURER_CONDITION';
import SLIP_DOC_REINSURER_CONTACT from '@salesforce/label/c.SLIP_DOC_REINSURER_CONTACT';
import SLIP_DOC_SIGNING_PROVISIONS from '@salesforce/label/c.SLIP_DOC_SIGNING_PROVISIONS';
import SLIP_DOC_WRITTEN_LINES from '@salesforce/label/c.SLIP_DOC_WRITTEN_LINES';
import SLIP_SANCTION_EXCL_CLAUSE from '@salesforce/label/c.SLIP_SANCTION_EXCL_CLAUSE';
import SLIP_LBL_REINSURER_LIABILITY from '@salesforce/label/c.SLIP_LBL_REINSURER_LIABILITY';
import SLIP_LBL_BASIS_WRITTEN from '@salesforce/label/c.SLIP_LBL_BASIS_WRITTEN';
import SLIP_LBL_BASIS_SIGNED from '@salesforce/label/c.SLIP_LBL_BASIS_SIGNED';
import SLIP_LBL_PROVISIONS from '@salesforce/label/c.SLIP_LBL_PROVISIONS';
import SLIP_LBL_WRITTEN_LINES from '@salesforce/label/c.SLIP_LBL_WRITTEN_LINES';
import SLIP_LBL_SANCTION_LIMIT from '@salesforce/label/c.SLIP_LBL_SANCTION_LIMIT';
import SLIP_LBL_INTERMEDIARY from '@salesforce/label/c.SLIP_LBL_INTERMEDIARY';
import SLIP_LBL_FOREIGN_EX_REINS from '@salesforce/label/c.SLIP_LBL_FOREIGN_EX_REINS';
import SLIP_LBL_SECURITY_CANCEL from '@salesforce/label/c.SLIP_LBL_SECURITY_CANCEL';
import SLIP_LBL_RECORDING from '@salesforce/label/c.SLIP_LBL_RECORDING';
import SLIP_LBL_CONTRACT_DOC from '@salesforce/label/c.SLIP_LBL_CONTRACT_DOC';
import SLIP_LBL_REINS_CONDITION from '@salesforce/label/c.SLIP_LBL_REINS_CONDITION';
import LABEL_ADD from '@salesforce/label/c.COM_BTN_ADD';
import LABEL_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import SLIP_PREM_PAYMENT_TERM_1 from '@salesforce/label/c.SLIP_PREM_PAYMENT_TERM_1';
import SLIP_PREM_PAYMENT_TERM_2 from '@salesforce/label/c.SLIP_PREM_PAYMENT_TERM_2';
import SLIP_PREM_PAYMENT_TERM_3 from '@salesforce/label/c.SLIP_PREM_PAYMENT_TERM_3';
import SLIP_PREM_PAYMENT_TERM_4 from '@salesforce/label/c.SLIP_PREM_PAYMENT_TERM_4';
import SLIP_MSG_DUP_CURRENCY from '@salesforce/label/c.SLIP_MSG_DUP_CURRENCY';
import SLIP_MSG_VALIDATE_TSI_CURR_REQUIRED from '@salesforce/label/c.SLIP_MSG_VALIDATE_TSI_CURR_REQUIRED';
import SLIP_MSG_SUCCESS_RI_UPDATE from '@salesforce/label/c.SLIP_MSG_SUCCESS_RI_UPDATE';
import SLIP_MSG_SUCCESS_TSI from '@salesforce/label/c.SLIP_MSG_SUCCESS_TSI';
import SLIP_MSG_FAIL_TSI from '@salesforce/label/c.SLIP_MSG_FAIL_TSI';

export default class oppRiSlipInfo extends LightningElement {
    @api recordId;
    @track objectFields;
    @track formData = {};
    @track previousData = {};    // Cedant
    @track fieldUI = {};
    @track PremiumPaymentDaysOptions = [];
    @track RITypeOptions = [];
    @track TorLswOptions = [];
    @track TerritoryOptions = [];
    @track GoverningLawOptions = [];
    @track isTsiExpanded = false;
    @track TSICurrencyOptions = [];

    @track tsiRows = [];
    deletedIds = [];
    deletedCurrencies = [];
    isSavingTSI = false;

    isEditMode = false;     // 실제 값
    originalData = {};
    typeLabelMap = {};
    wiredSlipInfoResult;

    showPremiumTerms = false;

    isScheduleRestricted = false;
    opportunityStage;


    editingField = null;
    dirtyFields = new Set();
    editedFields = new Set();

    DATE_TIME_FIELDS = ['PeriodFrom__c', 'PeriodTo__c'];
    customLabels={};

    labels = {
        foreignExReins: SLIP_CLAUSE_FOREX_REINS,
        intermediaryClause: SLIP_CLAUSE_INTERMEDIARY_SG,
        basisSinged: SLIP_DOC_BASIS_OF_SIGNED_LINES,
        basisWritten: SLIP_DOC_BASIS_OF_WRITTEN_LINES,
        recording: SLIP_DOC_RECORDING_ETC,
        reinsCondition: SLIP_DOC_REINSURER_CONDITION,
        contractDoc: SLIP_DOC_REINSURER_CONTACT,
        provision: SLIP_DOC_SIGNING_PROVISIONS,
        writtenLines: SLIP_DOC_WRITTEN_LINES,
        sanctionLimit:SLIP_SANCTION_EXCL_CLAUSE,

        reinsurerLiabilityLabel: SLIP_LBL_REINSURER_LIABILITY,
        basisSignedLabel: SLIP_LBL_BASIS_SIGNED,
        basisWrittenLabel: SLIP_LBL_BASIS_WRITTEN,
        provisionsLabel: SLIP_LBL_PROVISIONS,
        writtenLinesLabel: SLIP_LBL_WRITTEN_LINES,
        sanctionLimitLabel: SLIP_LBL_SANCTION_LIMIT,
        intermediaryClauseLabel: SLIP_LBL_INTERMEDIARY,
        foreignExReinsLabel: SLIP_LBL_FOREIGN_EX_REINS,
        securityCancelLabel: SLIP_LBL_SECURITY_CANCEL,
        recordingLabel: SLIP_LBL_RECORDING,
        contractDocLabel: SLIP_LBL_CONTRACT_DOC,
        reinsConditionLabel: SLIP_LBL_REINS_CONDITION,

        save: LABEL_SAVE,
        add: LABEL_ADD,

        paymentTerm1: SLIP_PREM_PAYMENT_TERM_1,
        paymentTerm2: SLIP_PREM_PAYMENT_TERM_2,
        paymentTerm3: SLIP_PREM_PAYMENT_TERM_3,
        paymentTerm4: SLIP_PREM_PAYMENT_TERM_4,

        dupCurrency: SLIP_MSG_DUP_CURRENCY,
        validateTSICurrRequired: SLIP_MSG_VALIDATE_TSI_CURR_REQUIRED,
        riUpdateSuccess: SLIP_MSG_SUCCESS_RI_UPDATE,
        tsiSuccess: SLIP_MSG_SUCCESS_TSI,
        tsiFail: SLIP_MSG_FAIL_TSI
    }

    /**
     * @description 컴포넌트 초기화 — SlipInfo, CountryOrigin, TSI 데이터를 순차적으로 로드
     */
    async connectedCallback() {
        await this.loadSlipInfo();
        await this.loadCountryOrigin();
        await this.loadTSI();
    }

    /**
     * @description TSI 목록 로드 — SlipInfo 에 연결된 TSI(Type='Slip') 행을 tsiRows 에 설정
     */
    async loadTSI() {
        try {
            const rows = await getSlipTSI({ slipInfoId: this.recordId });
            this.tsiRows = rows.length ? rows.map(row => ({
                key: row.Id,
                Id: row.Id,
                TSICurrency__c: row.TSICurrency__c,
                SlipTSI__c: row.SlipTSI__c,
                _isNew: false,
                _currencyError: false,
                rowClass: 'slds-grid slds-gutters slds-m-bottom_x-small'
            })) : [this.newEmptyRow()];
        } catch (error) {
            console.error('TSI Load Error', error);
        }
    }

    /**
     * @description OPP_SlipInfo__c ObjectInfo wire — defaultRecordTypeId 설정
     * @param {Object} data ObjectInfo 데이터
     * @param {Object} error 오류 객체
     */
    @wire(getObjectInfo, { objectApiName: OPP_SLIPINFO_OBJECT })
    wiredObjectInfo({ data, error }) {
        if (data) {
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            console.error('ObjectInfo error', error);
        }
    }

    /**
     * @description RI SlipInfo 로드 — current / previous 데이터 조회 후 diff 비교 수행
     */
    async loadSlipInfo() {
        try {
            const data = await getRISlipInfo({ recordId: this.recordId });
            if (!data) return;

            this.formData = this.decodeFormData({ ...data.current });
            this.previousData = this.decodeFormData({ ...data.previous });

            if (this.formData.TerritoryScope__c && typeof this.formData.TerritoryScope__c === 'string') {
                this.formData.TerritoryScope__c = this.formData.TerritoryScope__c.split(';');
            } else if (!this.formData.TerritoryScope__c) {
                this.formData.TerritoryScope__c = [];
            }

            if (this.formData.GoverningLaw__c && typeof this.formData.GoverningLaw__c === 'string') {
                this.formData.GoverningLaw__c = this.formData.GoverningLaw__c.split(';');
            } else if (!this.formData.GoverningLaw__c) {
                this.formData.GoverningLaw__c = [];
            }

            this.normalizePicklist(this.formData);
            this.normalizePicklist(this.previousData);
            this.compareWithPrevious(this.formData, this.previousData);

        } catch (error) {
            console.error('loadSlipInfo error:', error);
        }
    }

    /**
     * @description TSI wire — recordId 기준으로 TSI 데이터를 조회하여 applyTSIResult 로 처리
     * @param {Object} result wire 결과 객체
     */
    @wire(getSlipTSI, {slipInfoId: '$recordId'})
    wiredTSI(result) {
        this.applyTSIResult(result);
    }

    /**
     * @description Type__c Picklist wire — API 값 → Label 매핑 Map(typeLabelMap) 생성
     * @param {Object} data Picklist 데이터
     * @param {Object} error 오류 객체
     */
    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: TYPE_FIELD
    })
    wiredTypePicklist({ data, error }) {
        if (error) {
            console.error('Type picklist load error', error);
            return;
        }

        if (!data) return;

        const map = {};
        data.values.forEach(v => {
            map[v.value] = v.label;
        });
        this.typeLabelMap = map;
    }

    /**
     * @description TerritoryScope__c Picklist wire — TerritoryOptions 설정
     * @param {Object} data Picklist 옵션 목록
     */
    @wire(getTerritoryOptions)
    wiredTerritoryOptions({ data }) {
        this.TerritoryOptions = [];
        if (data) {
            this.TerritoryOptions = data || [];
        }
    }

    /**
     * @description GoverningLaw__c Picklist wire — GoverningLawOptions 설정
     * @param {Object} data Picklist 옵션 목록
     */
    @wire(getGoverningLawOptions)
    wiredGoverningLawOptions({data}) {
        this.GoverningLawOptions = [];
        if (data) {
            this.GoverningLawOptions = data || [];
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
     * @description PremiumPaymentTermDays__c Picklist wire — PremiumPaymentDaysOptions 설정
     * @param {Object} data Picklist 옵션 목록
     * @param {Object} error 오류 객체
     */
    @wire(getPremiumPaymentDaysOptions)
    wiredPremiumPaymentDaysOptions({ data, error }) {
        this.PremiumPaymentDaysOptions = [];
        if (data) {
            this.PremiumPaymentDaysOptions = data || [];
        } else if (error) {
            console.error('Error loading Premium Payment Term Days options' , error);
        }
    }

    /**
     * @description RIType__c Picklist wire — RITypeOptions 설정
     * @param {Object} data Picklist 옵션 목록
     * @param {Object} error 오류 객체
     */
    @wire(getRITypeOptions)
    wiredRITypeOptions({ data, error }) {
        this.RITypeOptions = [];
        if (data) {
            this.RITypeOptions = data || [];
        } else if (error) {
            console.error('Error loading RI Type options', error);
        }
    }

    /**
     * @description TorLsw__c Picklist wire — TorLswOptions 설정
     * @param {Object} data Picklist 옵션 목록
     * @param {Object} error 오류 객체
     */
    @wire(getTorLswOptions)
    wiredTorLswOptions({ data, error }) {
        this.TorLswOptions = [];
        if (data) {
            this.TorLswOptions = data || [];
        } else if (error) {
            console.error('Error loading TorLsw options', error);
        }
    }

    /**
     * @description 다국어 텍스트 wire — MultilingualText__mdt 에서 조회한 텍스트를 customLabels 에 설정
     * @param {Object} data 텍스트 Map
     * @param {Object} error 오류 객체
     */
    @wire(getTexts, {
        keys: [
            'SLIP_DOC_REINSURERS_LIABILITY',
            'SLIP_CLAUSE_SEC_CANCEL'
        ]
    })
    wiredTexts({ data, error }) {
        if (data) {
            this.customLabels = data;
        } else if (error) {
            console.error(error);
        }
    }

    /**
     * @description PremiumSchedule 존재 여부 wire — isScheduleRestricted 설정 및 PremiumPaymentTerms__c 초기화
     * @param {Object} data 존재 여부 Boolean
     */
    @wire(hasValidPremiumSchedule, { slipInfoId: '$recordId' })
    wiredPremium({ data }) {
        if (data !== undefined) {
            this.isScheduleRestricted = data;

            if (data) {
                this.formData = {
                    ...this.formData,
                    PremiumPaymentTerms__c: null,
                };
            }
        }
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

            console.error('TSI Load Error', result.error);
            this.tsiRows = [];
        }
    }

    /**
     * @description CountryOrigin 로드 — CedantName Account 의 Country 를 Label 로 변환하여 formData 에 설정
     */
    async loadCountryOrigin() {
        try {
            const label = await getCountryOriginLabel({
                slipInfoId: this.recordId
            });

            this.formData = {
                ...this.formData,
                CountryOrigin_fm__c: label
            };

        } catch (error) {
            console.error('Country Origin load error', error);
        }
    }

    get taxPayableDisplay() {
        return this.formData.TaxPayable__c || 'Nil';
    }

    get premPaymentClauseFormatted() {
        const days = this.formData.PremiumPaymentTermDays__c || '';

        const fullText = SLIP_PREM_PAYMENT_TERM_1 + days + SLIP_PREM_PAYMENT_TERM_2 + days + SLIP_PREM_PAYMENT_TERM_3 + SLIP_PREM_PAYMENT_TERM_4;
        // 라벨/데이터의 \r\n, \n 케이스를 모두 처리해 문단을 안정적으로 분리
        const normalizedText = (fullText || '').replace(/\r\n/g, '\n');

        return normalizedText
            .split(/\n{2,}/)
            .map((text, i) => ({ id: String(i), text: text.trim() }))
            .filter(line => line.text);
    }


    FORM_FIELDS = [
        'Type__c', 'Form__c', 'Reinsured__c', 'Insured__c', 'RIType__c', 'PolicyHolder__c', 'PolicyNo__c', 'PeriodFrom__c', 'PeriodTo__c',
        'CoveredRisk__c', 'Interest__c', 'Location__c', 'LimitofLiability__c', 'Deductible__c', 'Prem100__c', 'DepositPrem__c', 'TorLsw__c', 'TaxPayable__c',
        'OccupancyBiz__c', 'TSI__c', 'TerritoryScope__c', 'GoverningLaw__c', 'TermsConds__c', 'LossRecord__c', 'AddPhrase_is__c',
        'RIAddInfo__c', 'OrderHereon__c', 'PremiumPaymentTerms__c', 'ExtensionClauses__c', 'TaxPayable__c', 'TaxPayableReinAdmin__c', 'ENDEffectivedDate__c',
        'PremiumPaymentTermDays__c', 'PremPaymentClause_fm__c', 'CountryOrigin_fm__c', 'TotalDeduction__c', 'RIOtherDeduction__c', 'Amendments__c'
    ];

    get lkRefNo() {
        return this.formData?.Placement_lk__r?.LKRefNoh__c || '';
    }

    get placementTransitionType() {
        return this.formData?.Placement_lk__r?.TransactionType__c || '';
    }

    get isEndTransitionPlacement() {
        return (this.placementTransitionType || '').trim().toUpperCase() === 'END';
    }

    get isEndorsementSlipType() {
        const slipType = (this.formData?.Type__c || '').trim();
        return slipType === 'Cedant Endorsement' || slipType === 'RI Endorsement';
    }

    get isRIEndorsementSlipType() {
        return (this.formData?.Type__c || '').trim() === 'RI Endorsement';
    }

    get relatedOpportunityIdParam() {
        return this.formData?.Opportunity_lk__c
            ?? this.originalData?.Opportunity_lk__c
            ?? null;
    }

    get resolvedPlacementId() {
        return this.formData?.Placement_lk__c
            ?? this.formData?.SlipInfo_lk__r?.Placement_lk__c
            ?? this.originalData?.Placement_lk__c
            ?? this.originalData?.SlipInfo_lk__r?.Placement_lk__c
            ?? null;
    }

    get isSlipWithoutPlacement() {
        return !this.resolvedPlacementId;
    }

    get isOpportunityClosedStage() {
        const stage = (this.opportunityStage || '').trim();
        return stage === 'Closed Won' || stage === 'Closed Lost';
    }

    get isInteractionLocked() {
        return this.isOpportunityClosedStage && this.isSlipWithoutPlacement;
    }

    get isHeaderActionDisabled() {
        return this.isInteractionLocked;
    }

    get isTSISectionDisabled() {
        return this.isInteractionLocked || this.isSavingTSI;
    }

    get isTSISaveDisabled() {
        return this.isTSISectionDisabled || this.isSavingTSI;
    }

    get showEndCompactLayout() {
        return this.isRIEndorsementSlipType || (this.isEndTransitionPlacement && this.isEndorsementSlipType);
    }

    /**
     * @description 연결 Opportunity 의 StageName 을 조회하고 Closed 단계 + Placement 미연결인 경우 편집 상태를 잠금 처리
     * @param {Object} data 레코드 데이터
     * @param {Object} error 오류 객체
     */
    @wire(getRecord, {
        recordId: '$relatedOpportunityIdParam',
        fields: [OPPORTUNITY_STAGE_FIELD]
    })
    wiredOpportunityStage({data, error}) {
        if (data) {
            this.opportunityStage = data.fields.StageName.value;

            if (this.isInteractionLocked) {
                if (this.isEditMode && this.originalData && Object.keys(this.originalData).length > 0) {
                    this.formData = JSON.parse(JSON.stringify(this.originalData));
                }
                this.isEditMode = false;
                this.showPremiumTerms = false;
                this.editingField = null;
            }
        } else if (error) {
            this.opportunityStage = null;
        }
    }

    /**
     * @description Type__c API 값을 Label 로 변환 — typeLabelMap 기준, 없으면 원본 유지
     * @param {Object} record 변환할 SlipInfo 레코드
     */
    normalizePicklist(record) {

        if (record?.Type__c) {
            record.Type__c =
                this.typeLabelMap?.[record.Type__c] ?? record.Type__c;
        }

    }

    /**
     * @description 체크박스 값 변경 핸들러 — data-field 기준으로 formData 업데이트
     * @param {Event} event change 이벤트
     */
    handleCheckboxChange(event) {
        if (this.isInteractionLocked) return;
        const field = event.target.dataset.field;

        this.formData = {
            ...this.formData,
            [field]: event.target.checked
        };
    }

    /**
     * @description 읽기 전용 체크박스 토글 방지 — 현재 formData 값으로 원복
     * @param {Event} event 클릭 이벤트
     */
    preventCheckboxToggle(event) {
        event.preventDefault();
        event.stopPropagation();

        event.target.checked = this.formData.AddPhrase_is__c;
    }

    get fields() {
        if (!this.objectFields || !this.formData) return {};

        const fieldData = {};

        this.FORM_FIELDS.forEach((key) => {
            fieldData[key] = {
                label: this.objectFields[key]?.label,
                value: this.formData[key] ?? '',
                previous: this.previousData?.[key],
                isDirty: this.dirtyFields?.has(key)
            };
        });

        return fieldData;
    }

    /**
     * @description 필드 포커스 시 editingField 를 현재 필드명으로 설정
     * @param {Event} event 포커스 이벤트
     */
    handleFocus(event) {
        this.editingField = event.target.dataset.field || event.currentTarget.dataset.field;
    }

    /**
     * @description 필드 포커스 해제 시 editingField 초기화
     */
    handleBlur() {
        this.editingField = null;
    }

    /**
     * @description 편집 모드 진입 — formData 를 originalData 에 백업
     */
    handleEdit() {
        if (this.isInteractionLocked) return;
        this.originalData = JSON.parse(JSON.stringify(this.formData));
        this.isEditMode = true;
        this.showPremiumTerms = true;
    }

    /**
     * @description 편집 취소 — originalData 로 formData 복원 및 편집 상태 초기화
     */
    handleCancel() {
        if (this.isInteractionLocked) return;
        this.formData = JSON.parse(JSON.stringify(this.originalData));
        // 편집 상태 초기화
        this.editedFields.clear();
        this.editingField = null;

        this.isEditMode = false;
    }

    /**
     * @description SlipInfo 저장 — PremiumSchedule 제한 시 PremiumPaymentTerms 강제 설정 후 Apex 저장 호출
     * @returns {Promise<void>}
     */
    async handleSave() {
        if (this.isInteractionLocked) return;
        try {
            if (this.isScheduleRestricted) {
                this.formData = {
                    ...this.formData,
                    PremiumPaymentTerms__c: 'NULL'
                };
            }

            await saveSlip({ slip: this.formData });

            this.editedFields.clear();
            this.editingField = null;

            await refreshApex(this.wiredSlipInfoResult);

            // diff / 상태 초기화
            this.dirtyFields.clear();
            this.compareWithPrevious(this.formData, this.previousData);

            this.isEditMode = false;
            this.showPremiumTerms = false;

            this.showToast(
                'Saved',
                this.labels.riUpdateSuccess,
                'success'
            );

        } catch (error) {
            console.error('Save error', error);

            const message =
                error?.body?.message ||
                error?.message ||
                'An unexpected error occurred while saving.';

            this.showToast(
                'Save Failed',
                message,
                'error'
            );
        }

    }

    /**
     * @description 일반 필드 값 변경 핸들러 — formData 업데이트 및 editedFields 에 추가
     * @param {Event} event change 이벤트
     */
    handleChange(event) {
        if (this.isInteractionLocked) return;
        const field = event.target.dataset.field;
       // const value = event.target.value;
        let value = event.detail.value;

        if (Array.isArray(value)) {
            value = [...value];
        }

        this.formData = {
            ...this.formData,
            [field]: value
        };

        this.editedFields.add(field);
    }

    get territoryScopeArray() {
        const val = this.formData?.TerritoryScope__c;

        if (!val) return [];
        return Array.isArray(val) ? val : val.split(';');
    }

    get GoverningLawArray() {
        const val = this.formData?.GoverningLaw__c;

        if (!val) return [];
        return Array.isArray(val) ? val : val.split(';');
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

    /**
     * @description TSI 행 필드 값 변경 핸들러 — TSICurrency__c 변경 시 중복 통화 검증 후 tsiRows 업데이트
     * @param {Event} event change 이벤트 (data-key, data-field 속성 포함)
     */
    handleRowChange(event) {
        if (this.isInteractionLocked) return;
        const key = event.target.dataset.key;
        const field = event.target.dataset.field;
        let value = event.detail.value;

        if (Array.isArray(value)) value = [...value];

        if (field === 'TSICurrency__c' && value) {
            const isDuplicate = this.tsiRows.some(r => r.key !== key && r.TSICurrency__c === value);
            if (isDuplicate) {
                this.showToast('Error', this.labels.dupCurrency, 'error');
                return;
            }
        }

        this.tsiRows = this.tsiRows.map(row =>
            row.key === key ? { ...row, [field]: value } : row
        );

    }

    /**
     * @description DualListbox 값 변경 핸들러 — formData 의 다중 선택 필드 업데이트
     * @param {Event} event change 이벤트
     */
    handleDualListChange(event) {
        if (this.isInteractionLocked) return;
        const field = event.target.dataset.field;
        const value = event.detail.value;

        this.formData = {
            ...this.formData,
            [field]: [...value]
        };
    }

    /**
     * @description 필드 Label 변환 — TerritoryScope__c, GoverningLaw__c 의 API 값을 Label 로 반환
     * @param {string} field 필드 API 명
     * @param {*} apiValue 필드 API 값
     * @returns {string} Label 로 변환된 값
     */
    getFieldLabel(field, apiValue) {
        if (!apiValue) return apiValue;

        const values = Array.isArray(apiValue)
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
     * @description diff 비교용 값 변환 — 필드 타입에 따라 날짜 포맷, Label 변환 등을 적용하여 반환
     * @param {string} field 필드 API 명
     * @param {Object} record 비교할 레코드
     * @returns {*} 비교 가능한 형식으로 변환된 값
     */
    getComparableValue(field, record) {
        const rawValue = record?.[field];

        // Picklist (Type__c)
        if (field === 'RIType__c') {
            return this.typeLabelMap?.[rawValue] ?? rawValue ?? '';
        }

        // DateTime
        if (this.DATE_TIME_FIELDS.includes(field)) {
            return this.formatDateOnly(rawValue);
        }

        // Multi-select Picklist → label로 변환
        if (field === 'TerritoryScope__c' || field === 'GoverningLaw__c') {
            return this.getFieldLabel(field, rawValue) ?? '';
        }

        // 일반 필드
        return rawValue ?? '';
    }

    /**
     * @description diff 비교 수행 — current / previous 필드 값을 비교하여 fieldUI 에 diff 상태 설정
     * @param {Object} current 현재 SlipInfo 데이터
     * @param {Object} previous 비교 대상 Cedant Slip 데이터
     */
    compareWithPrevious(current, previous) {
        this.fieldUI = {};
        this.dirtyFields.clear();

        if (!current || !previous) return;

        // previous 데이터를 디코딩하여 표시 값이 올바르게 보이도록 처리
        const decodedPrevious = this.decodeFormData({ ...previous });

        const newFieldUI = {};

        this.FORM_FIELDS.forEach(field => {
            const curr = this.getComparableValue(field, current);
            const prev = this.getComparableValue(field, decodedPrevious);

            if (curr !== prev) {
                this.dirtyFields.add(field);

                const diffSnippet = this.getDiffSnippet(curr, prev);

                newFieldUI[field] = {
                    hasPrevious: true,
                    tooltip: `Previous Value : ${diffSnippet}`,
                    cellClass: 'cell-wrap cell-diff'
                };
            } else {
                newFieldUI[field] = {
                    hasPrevious: false,
                    cellClass: 'cell-wrap'
                };
            }
        });

        this.fieldUI = newFieldUI;
    }

    /**
     * @description diff 툴팁 요약 문자열 반환 — 200자 초과 시 변경 시작점 기준으로 잘라서 반환
     * @param {string} currentVal 현재 값
     * @param {string} previousVal 이전 값
     * @param {number} maxLength 최대 표시 길이 (기본 200)
     * @returns {string} 툴팁에 표시할 이전 값 요약
     */
    getDiffSnippet(currentVal, previousVal, maxLength = 200) {
        const curr = (currentVal ?? '').toString();
        const prev = (previousVal ?? '').toString();

        // previous가 없으면 그대로
        if (!prev) {
            return '(empty)';
        }

        // 200자 이하면 전체 그대로 노출
        if (prev.length <= maxLength) {
            return prev;
        }

        // 200자 초과인 경우만 처리
        let diffIndex = 0;
        const minLen = Math.min(curr.length, prev.length);

        // 공통 prefix 스킵
        while (diffIndex < minLen && curr[diffIndex] === prev[diffIndex]) {
            diffIndex++;
        }

        // diff 시작점 앞 5글자부터
        const startIndex = Math.max(0, diffIndex - 5);
        let diffText = prev.slice(startIndex, startIndex + maxLength);

        if (startIndex + maxLength < prev.length) {
            diffText += '…';
        }

        return diffText;
    }

    get wrapperClassMap() {
        const base = 'slds-col slds-size_9-of-12 cell-wrap';
        const map = {};

        this.FORM_FIELDS.forEach((field) => {
            let cls = base;

            if (this.editedFields.has(field)) {
                cls += ' cell-edited';
            }

            if (this.dirtyFields.has(field)) {
                cls += ' cell-diff';
            }

            if (this.editingField === field) {
                cls += ' cell-editing';
            }

            map[field] = cls;
        });

        return map;
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
     * @description DateTime 을 분 단위로 포맷 — 'YYYY-MM-DD HH:mm' 형식으로 반환
     * @param {string} rawDate ISO 형식 DateTime 문자열
     * @returns {string} 분 단위까지 포맷된 DateTime 문자열
     */
    formatDateTimeToMinute(rawDate) {
        if (!rawDate) return '';

        if (typeof rawDate === 'string' && rawDate.includes('T')) {
            return rawDate.replace('T', ' ').substring(0, 16);
        }

        return rawDate;
    }

    get periodFromFormatted() {
        return this.formatDateTimeToMinute(this.formData?.PeriodFrom__c);
    }

    get periodToFormatted() {
        return this.formatDateTimeToMinute(this.formData?.PeriodTo__c);
    }

    get endEffectiveDateFormatted() {
        return this.formatDateTimeToMinute(this.formData?.ENDEffectivedDate__c);
    }

    /**
     * @description Toast 메시지 표시
     * @param {string} title Toast 제목
     * @param {string} message Toast 메시지
     * @param {string} variant Toast 유형 ('success' | 'error' | 'warning' | 'info')
     */
    showToast(title, message, variant = 'info') {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    /**
     * @description TSI 새로고침 — 삭제 목록 초기화 후 신규 행 제거 및 서버 데이터 재로드
     */
    async handleRefreshTSI() {
        if (this.isInteractionLocked) return;
        this.deletedIds = [];
        this.deletedCurrencies = [];
        this.tsiRows = this.tsiRows.filter(r => !r._isNew);
        await this.loadTSI();
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
     * @description TSI 저장 — 필수 값 검증 후 insert / update / delete 분류하여 Apex 저장 호출
     * @returns {Promise<void>}
     */
    async handleSaveTSI() {

        if (this.isInteractionLocked) return;

        if (this.isSavingTSI) return;
        this.isSavingTSI = true;

        try {
            const hasEmpty = this.tsiRows.some(
                row => !row.TSICurrency__c || row.SlipTSI__c === null || row.SlipTSI__c === undefined || row.SlipTSI__c === ''
            );
            if (hasEmpty) {
                this.showToast('Error', this.labels.validateTSICurrRequired, 'error');
                return;
            }

            const insertList = [];
            const updateList = [];

            this.tsiRows.forEach(row => {
                const record = {
                    Id: row.Id,
                    TSICurrency__c: row.TSICurrency__c,
                    SlipTSI__c: row.SlipTSI__c,
                    SlipInfo_md__c: this.recordId,
                    Type__c: 'Slip'
                };

                if (!row.Id) {
                    delete record.Id;
                    insertList.push(record);
                } else {
                    updateList.push(record);
                }
            });

            await saveTSIRecords({
                slipInfoId: this.recordId,
                insertList,
                updateList,
                deleteIds: this.deletedIds
            });

            this.deletedIds = [];
            this.tsiRows = this.tsiRows.map(row => ({
                ...row,
                _isNew: false,
                _currencyError: false,
                rowClass: 'slds-grid slds-gutters slds-m-bottom_x-small'
            }));


            this.showToast('Success', this.labels.tsiSuccess, 'success');

        } catch (error) {
            console.error(error);
            this.showToast('Error', this.labels.tsiFail, 'error');
        } finally {
            this.isSavingTSI = false;
            await this.loadTSI();
        }
    }

    /**
     * @description TSI 행 삭제 — deletedIds / deletedCurrencies 에 추가 후 tsiRows 에서 제거
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

    get typeUI() {
        return this.fieldUI.RIType__c || {};
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

    get PeriodFromUI() {
        return this.fieldUI.PeriodFrom__c || {};
    }

    get PeriodToUI() {
        return this.fieldUI.PeriodTo__c || {};
    }

   get AddPhraseUI() {
        return this.fieldUI.AddPhrase_is__c || {};
    }

    get CoveredRiskUI() {
        return this.fieldUI.CoveredRisk__c || {};
    }

    get InterestUI() {
        return this.fieldUI.Interest__c || {};
    }

    get LocationUI() {
        return this.fieldUI.Location__c || {};
    }

    get LimitofLiabilityUI() {
        return this.fieldUI.LimitofLiability__c || {};
    }

    get DeductibleUI() {
        return this.fieldUI.Deductible__c || {};
    }

    get TerritoryScopeUI() {
        return this.fieldUI.TerritoryScope__c || {};
    }

    get GoverningLawUI() {
        return this.fieldUI.GoverningLaw__c || {};
    }

    get Prem100UI() {
        return this.fieldUI.Prem100__c || {};
    }

    get TypeEndUI() {
        return this.fieldUI.Type__c || {};
    }

    get ENDEffectivedDateUI() {
        return this.fieldUI.ENDEffectivedDate__c || {};
    }

    get AmendmentsUI() {
        return this.fieldUI.Amendments__c || {};
    }

    get TorLswUI() {
        return this.fieldUI.TorLsw__c || {};
    }

    get PremiumPaymentDaysUI() {
        return this.fieldUI.PremiumPaymentTermDays__c || {};
    }

    get TaxPayableUI() {
        return this.fieldUI.TaxPayable__c || {};
    }

    get OccupancyBizUI() {
        return this.fieldUI.OccupancyBiz__c || {};
    }

    get TSIUI() {
        return this.fieldUI.TSI__c || {};
    }

    get TermsCondsUI() {
        return this.fieldUI.TermsConds__c || {};
    }

    get LossRecordUI() {
        return this.fieldUI.LossRecord__c || {};
    }

    get AddInfoUI() {
        return this.fieldUI.RIAddInfo__c || {};
    }

    get OrderHereonUI() {
        return this.fieldUI.OrderHereon__c || {};
    }

    get PremiumPaymentClauseUI() {
        return this.fieldUI.PremPaymentClause_fm__c || {};
    }

    get CountryOriginUI() {
        return this.fieldUI.CountryOrigin_fm__c || {};
    }

    get otherDeductionUI() {
        return this.fieldUI.RIOtherDeduction__c || {};
    }

    get TotalDeductionUI() {
        return this.fieldUI.TotalDeduction__c || {};
    }

    get FormLabel() {
        return this.objectFields?.Form__c?.label ?? 'Form';
    }

    get TypeLabel() {
        return this.objectFields?.RIType__c?.label ?? 'Type';
    }

    get ReinsurerLabel() {
        return this.objectFields?.Reinsured__c?.label ?? 'Reinsurer';
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

    get AddPhraseLabel() {
        return this.objectFields?.AddPhrase_is__c?.label ?? 'Add Phrase : "Both dates inclusive"';
    }

    get CoveredRiskLabel() {
        return this.objectFields?.CoveredRisk__c?.label ?? 'Covered Risk';
    }

    get InterestLabel() {
        return this.objectFields?.Interest__c?.label ?? 'Interest';
    }

    get LocationLabel() {
        return this.objectFields?.Location__c?.label ?? 'Location';
    }

    get LimitOfLiabilityLabel() {
        return this.objectFields?.LimitofLiability__c?.label ?? 'Limit Of Liability';
    }

    get DeductibleLabel() {
        return this.objectFields?.Deductible__c?.label ?? 'Deductible';
    }

   get TerritoryScopeLabel() {
        return this.objectFields?.TerritoryScope__c?.label ?? 'Territorial Scope';
    }

    get GoverningLawLabel() {
        return this.objectFields?.GoverningLaw__c?.label ?? 'Choice of Law and Jurisdiction';
    }

    get Prem100Label() {
        return this.objectFields?.Prem100__c?.label ?? 'PREMIUM (100%)';
    }

    get DepositPremLabel() {
        return this.objectFields?.DepositPrem__c?.label ?? 'Deposit Premium (100%)';
    }

    get TorLswLabel() {
        return this.objectFields?.TorLsw__c?.label ?? 'TOR/LSW';
    }

    get PremiumPaymentTermsLabel() {
        return this.objectFields?.PremiumPaymentTerms__c?.label ?? 'Premium Payment Terms';
    }

    get PremiumPaymentDaysLabel() {
        return this.objectFields?.PremiumPaymentTermDays__c?.label ?? 'Days';
    }

    get TaxPayableLabel () {
        return this.objectFields?.TaxPayable__c?.label ?? 'Tax Payable By Reinsurer';
    }

    get OccupancyLabel() {
        return this.objectFields?.OccupancyBiz__c?.label ?? 'Occupancy';
    }

    get TSILabel() {
        return this.objectFields?.TSI__c?.label ?? 'Total Sum Insured';
    }

    get TermsCondsLabel() {
        return this.objectFields?.TermsConds__c?.label ?? 'Original Policy Terms and Conditions';
    }

    get LossRecordLabel() {
        return this.objectFields?.LossRecord__c?.label ?? 'Loss Record';
    }

    get AddInfoLabel() {
        return this.objectFields?.RIAddInfo__c?.label ?? 'Additional Information';
    }

    get OrderHereonLabel() {
        return this.objectFields?.OrderHereon__c?.label ?? 'Order Hereon';
    }

    get PremiumPaymentClauseLabel() {
        return this.objectFields?.PremPaymentClause_fm__c?.label ?? 'Premium Payment Clause';
    }

    get CountryOriginLabel() {
        return this.objectFields?.CountryOrigin_fm__c?.label ?? 'Country of Origin';
    }

    get otherDeductionLabel() {
        return this.objectFields?.RIOtherDeduction__c?.label ?? 'Other Deduction From Premium';
    }

    get TotalDeductionLabel() {
        return this.objectFields?.TotalDeduction__c?.label ?? 'Total Deductions';
    }

    get ExtensionClausesUI() {
        return this.fieldUI.ExtensionClauses__c || {};
    }

    get ExtensionClausesLabel() {
        return this.objectFields?.ExtensionClauses__c?.label ?? 'Extension Clauses';
    }

    get ENDEffectivedDateLabel() {
        return this.objectFields?.ENDEffectivedDate__c?.label ?? 'END Effective Date';
    }

    get AmendmentsLabel() {
        return this.objectFields?.Amendments__c?.label ?? 'Amendments';
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

    get TaxPayableReinAdminLabel() {
        return this.objectFields?.TaxPayableReinAdmin__c?.label ?? 'Taxes payable by the reinsured and administered by reinsurers';
    }

    get TaxPayableReinAdminUI() {
        return this.fieldUI.TaxPayableReinAdmin__c || {};
    }



}