/**********************************************************************************
 * @filename      : comNoteListFilter.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-10 (화)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-10      i2max      Create
 **********************************************************************************/
import {LightningElement, wire, api} from 'lwc';
import {toast} from 'c/com'
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import COM_NOTE_OBJECT from '@salesforce/schema/COM_Note__c';

import COM_MSG_DATE_RANGE_INVALID from '@salesforce/label/c.COM_MSG_DATE_RANGE_INVALID'
import getPicklistOptions from "@salesforce/apex/COM_Note_Ctrl.initData";

export default class ComNoteListFilter extends LightningElement {

    // 📍 1. API 속성 (외부에서 설정 가능)
    @api
    get defaultFilter() { return this._defaultFilter; }
    set defaultFilter(val) {
        if (!val) return;
        this._defaultFilter = val;
        this.searchParams = { ...this.searchParams, ...val };
    }

    // 📍 2. 추적 속성 (반응형)
    searchParams = {
        bdxType: '',
        facilityId: null,
        facilityUY: '',
        accountId: '',
        insured: null,
        issueDateFrom: null,
        issueDateTo: null,
        inceptionDateFrom: null,
        inceptionDateTo: null,
        ppwDateFrom: null,
        ppwDateTo: null,
        lob: null,
        transactionType: null,
    };
    transactionTypeOption = [];

    // 📍 3. Private 속성
    fieldLabels = {};
    _defaultFilter = {};

    lookupConfig = (ctx) => {
        const map = {
            Facility_lk__c: { objectApiName: 'COM_Facility__c', labelField: 'Name' },
            Account_lk__c:  { objectApiName: 'Account', labelField: 'Name' },
            Insured_lk__c:  { objectApiName: 'Account', labelField: 'Name' },
        };
        return map[ctx.fieldName] || {};
    };

    labels = {
        COM_MSG_DATE_RANGE_INVALID
    }
    lobFields = ['LOB1__c', 'LOB2__c', 'LOB3__c'];

    // 📍 4. Getter/Setter

    // 📍 5. Wire 메서드
    @wire(getObjectInfo, { objectApiName: COM_NOTE_OBJECT })
    wiredObjectInfo({ data }) {
        if (data) {
            const fields = data.fields;
            this.fieldLabels = {
                Account_lk__c: fields.Account_lk__c?.label || 'Account',
                Facility_lk__c: fields.Facility_lk__c?.label || 'Facility',
                FacilityUY_fm__c: fields.FacilityUY_fm__c?.label || 'Facility UY',
                IssueDate__c: fields.IssueDate__c?.label || 'Issue Date',
                PERIODFrom_fm__c: fields.PERIODFrom_fm__c?.label || 'Inception Date (From)',
                PERIODTo_fm__c: fields.PERIODTo_fm__c?.label || 'Inception Date (To)',
                PPWDateFrom__c: fields.PPWDateFrom__c?.label || 'PPW Date (From)',
                PPWDateTo__c: fields.PPWDateTo__c?.label || 'PPW Date (To)',
                TransactionType_fm__c: fields.TransactionType_fm__c?.label || 'Transaction Type',
                Insured_lk__c: fields.Insured_lk__c?.label || 'Insured',
                LOB_fm__c: fields.LOB_fm__c?.label || 'LOB'
            };
        }
    }

    @wire(getPicklistOptions)
    wiredPicklistOptions({ data, error }) {
        if (data) {
            this.transactionTypeOption = data.Options || [];
        } else if (error) {
            console.error("[getPicklistOptions] getPicklistOptions error:", error);
            this.transactionTypeOption = [];
        }
    }

    // 📍 6. 이벤트 핸들러
    handleLookupChange(event) {
        const { fieldName, value } = event.detail;
        this.searchParams = { ...this.searchParams, [fieldName]: value };
    }

    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.searchParams = { ...this.searchParams, [field]: event.target.value };
    }

    handlePicklistChange(event) {
        const { fieldName, value, values } = event.detail;
        // console.log('[handlePicklistChange] 🍏 fieldName=', fieldName, 'value', value, 'values', values, 'event.detail', JSON.stringify(event.detail));
        this.searchParams = { ...this.searchParams, [fieldName]: value ?? values };
    }

    handleSearch() {
        if (!this._validateDates()) return;
        console.log('[Filter] searchParams=', JSON.stringify(this.searchParams));
        this.dispatchEvent(new CustomEvent('search', { detail: { ...this.searchParams } }));
    }

    handleReset() {
        const defaults = this._defaultFilter || {};
        this.searchParams = {
            bdxType: defaults.bdxType || '',
            facilityId: defaults.facilityId || null,
            facilityUY: defaults.facilityUY || '',
            accountId: defaults.accountId || null,
            insured: null,
            issueDateFrom: null,
            issueDateTo: null,
            inceptionDateFrom: null,
            inceptionDateTo: null,
            ppwDateFrom: null,
            ppwDateTo: null,
            lob: '',
            transactionType: null,
        };
        this.template.querySelectorAll('c-com-lookup').forEach(el => {
            if (!el.disabled) el.resetLookup(true);
        });
        const typeahead = this.template.querySelector('c-com-typeahead-picklist');
        if (typeahead?.reset) typeahead.reset();

        this.dispatchEvent(new CustomEvent('reset'));
    }

    // 📍 7. Private 메서드
    _validateDates() {
        const param = this.searchParams;
        if (param.issueDateFrom && param.issueDateTo && param.issueDateFrom > param.issueDateTo) {
            toast(this, 'Warning', this.labels.COM_MSG_DATE_RANGE_INVALID.replace(/\{0\}/g, 'issue Date'), 'warning');
            return false;
        }
        if (param.inceptionDateFrom && param.inceptionDateTo && param.inceptionDateFrom > param.inceptionDateTo) {
            toast(this, 'Warning', this.labels.COM_MSG_DATE_RANGE_INVALID.replace(/\{0\}/g, 'Inception Date'), 'warning');
            return false;
        }
        if (param.ppwDateFrom && param.ppwDateTo && param.ppwDateFrom > param.ppwDateTo) {
            toast(this, 'Warning', this.labels.COM_MSG_DATE_RANGE_INVALID.replace(/\{0\}/g, 'PPW Date'), 'warning');
            return false;
        }
        return true;
    }


    // 📍 8. 라이프사이클 메서드
    connectedCallback() {
    }

    disconnectedCallback() {
    }


}