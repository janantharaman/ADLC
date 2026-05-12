/**********************************************************************************
 * @filename      : SoaNoteManageFilter.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-20 (금)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-20      i2max      Create
 **********************************************************************************/
import { LightningElement, wire, api } from 'lwc';
import { toast } from 'c/com';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import COM_NOTE_OBJECT from '@salesforce/schema/COM_Note__c';

import getPicklistOptions from '@salesforce/apex/SOA_NoteManager_Ctrl.initData';
import COM_MSG_DATE_RANGE_INVALID from '@salesforce/label/c.COM_MSG_DATE_RANGE_INVALID';

export default class SoaNoteManageFilter extends LightningElement {


    // 📍 1. API 속성

    // 📍 2. 추적 속성 (반응형)
    searchParams = {
        noteStatus: 'Non-Available',        // 고정값
        accountId: null,                     // 필수
        creditNoteSeq: '',                   // Debit/Credit No. (like)
        facilityId: null,                    // Facility Name
        facilityBDXPeriodFrom: null,         // Facility BDX Period From
        facilityBDXPeriodTo: null,           // Facility BDX Period To
        lkRefNo: '',                         // LK Ref No.
        placementId: null,                   // Placement No.
        insuredId: null,                     // Insured
        inceptionDate: null,                 // Inception Date
        installmentNo: null,                 // No of Installment
        ppwDate: null,                       // PPW Date
        dateOfLoss: null,                    // Date of Loss
        socSeq: '',                          // SOC Seq.
        noteType: null                       // Note Type (Debit/Credit)
    };

    noteTypeOptions = [];

    // 📍 3. Private 속성
    fieldLabels = {};

    lookupConfig = (ctx) => {
        const map = {
            accountId:     { objectApiName: 'Account', labelField: 'Name' },
            facilityId:    { objectApiName: 'COM_Facility__c', labelField: 'Name' },
            insuredId:     { objectApiName: 'Account', labelField: 'Name' },
            placementId:   { objectApiName: 'Placement__c', labelField: 'Name' }
        };
        return map[ctx.fieldName] || {};
    };

    labels = {
        COM_MSG_DATE_RANGE_INVALID
    };

    // 📍 4. Getter/Setter

    // 📍 5. Wire 메서드
    @wire(getObjectInfo, { objectApiName: COM_NOTE_OBJECT })
    wiredObjectInfo({ data }) {
        if (data) {
            const fields = data.fields;
            this.fieldLabels = {
                NoteStatus__c:            fields.NoteStatus__c?.label || 'Note Status',
                Account_lk__c:            fields.Account_lk__c?.label || 'Account',
                NoteType__c:              fields.NoteType__c?.label || 'Note Type',
                CreditNoteSeq_fm__c:      fields.CreditNoteSeq_fm__c?.label || 'Debit/Credit No.',
                Facility_lk__c:           fields.Facility_lk__c?.label || 'Facility',
                LKRefNo__c:               fields.LKRefNo__c?.label || 'LK Ref No.',
                Placement_lk__c:          fields.Placement_lk__c?.label || 'Placement',
                Insured_lk__c:            fields.Insured_lk__c?.label || 'Insured',
                InceptionDate__c:         fields.InceptionDate__c?.label || 'Inception Date',
                InstallmentNo__c:         fields.InstallmentNo__c?.label || 'No of Installment',
                PPWDate__c:               fields.PPWDate__c?.label || 'PPW Date',
                DateOfLoss__c:            fields.DateOfLoss__c?.label || 'Date of Loss',
                SOCSeq__c:                fields.SOCSeq__c?.label || 'SOC Seq.'
            };
        }
    }

    @wire(getPicklistOptions)
    wiredNoteType({ data, error }) {
        if (data) this.noteTypeOptions = data.noteTypeOptions || [];
    }

    // 📍 6. 이벤트 핸들러
    handleInputChange(event) {
        const field = event.target.dataset.field;
        this.searchParams = { ...this.searchParams, [field]: event.target.value };
    }

    handleLookupChange(event) {
        const { fieldName, value } = event.detail;
        this.searchParams = { ...this.searchParams, [fieldName]: value };
    }

    handlePicklistChange(event) {
        const { fieldName, value, values } = event.detail;
        this.searchParams = { ...this.searchParams, [fieldName]: value ?? values };
    }

    handleSearch() {
        if (!this.validate()) return;
        this.dispatchEvent(new CustomEvent('search', { detail: { ...this.searchParams } }));
    }

    handleReset() {
        this.searchParams = {
            noteStatus: 'Non-Available',
            accountId: null,
            creditNoteSeq: '',
            facilityId: null,
            facilityBDXPeriodFrom: null,
            facilityBDXPeriodTo: null,
            lkRefNo: '',
            placementId: null,
            insuredId: null,
            inceptionDate: null,
            installmentNo: null,
            ppwDate: null,
            dateOfLoss: null,
            socSeq: '',
            noteType: null
        };
        this.template.querySelectorAll('c-com-lookup').forEach(el => el.resetLookup(true));
        this.dispatchEvent(new CustomEvent('reset'));
    }

    // 📍 7. Private 메서드 + Public API
    @api
    getValues() {
        return { ...this.searchParams };
    }

    @api
    validate() {
        if (!this.searchParams.accountId) {
            toast(this, 'Warning', 'Account is required.', 'warning');
            return false;
        }
        if (this.searchParams.facilityBDXPeriodFrom && this.searchParams.facilityBDXPeriodTo
            && this.searchParams.facilityBDXPeriodFrom > this.searchParams.facilityBDXPeriodTo) {
            toast(this, 'Warning', this.labels.COM_MSG_DATE_RANGE_INVALID.replace(/\{0\}/g, 'Facility BDX Period'), 'warning');
            return false;
        }
        return true;
    }

    @api
    reset() {
        this.handleReset();
    }

    // 📍 8. 라이프사이클 메서드
    connectedCallback() {
    }

    disconnectedCallback() {
    }

}