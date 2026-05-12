/**********************************************************************************
 * @filename      : comNoteList.js
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
import {api, LightningElement, track, wire} from 'lwc';

import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {getRecord} from 'lightning/uiRecordApi';
import COM_NOTE_OBJECT from '@salesforce/schema/COM_Note__c';
import FACILITY_FIELD from '@salesforce/schema/COM_FacilityBDX__c.Facility_lk__c';
import FACILITY_UY_FIELD from '@salesforce/schema/COM_FacilityBDX__c.FacilityUY_fm__c';
import ACCOUNT_FIELD from '@salesforce/schema/COM_FacilityBDX__c.Account_lk__c';
import BDXTYPE_FIELD from '@salesforce/schema/COM_FacilityBDX__c.BDXType__c';

import COM_MSG_SAVE_SUCCESS from '@salesforce/label/c.COM_MSG_SAVE_SUCCESS'

import {callApex, getFieldValue, toast} from 'c/com';

import {NOTE_COLUMNS} from './comNoteListColumns';
import getNotes from '@salesforce/apex/COM_Note_Ctrl.getNotes';
import createRecords from '@salesforce/apex/COM_Note_Ctrl.createRecords';

export default class ComNoteList extends LightningElement {

    // 📍 1. API 속성 (외부에서 설정 가능)
    @api recordId

    // 📍 2. 추적 속성 (반응형)
    tableColumns = [];
    tableData = [];
    isLoading = false;
    _selectedCount = 0;
    @track _defaultFilter = {}


    // 📍 3. Private 속성
    _filterCondition = {}
    labels = {
        COM_MSG_SAVE_SUCCESS
    }


    // 📍 4. Getter/Setter
    get isCreateDisabled() {
        return this._selectedCount === 0;
    }

    get totalCount() {
        return this.tableData?.length || 0;
    }

    // 📍 5. Wire 메서드
    @wire(getObjectInfo, { objectApiName: COM_NOTE_OBJECT })
    wiredObjectInfo({ data }) {
        if (data) {
            this.tableColumns = this._applyLabels(NOTE_COLUMNS, data.fields);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [FACILITY_FIELD, FACILITY_UY_FIELD, ACCOUNT_FIELD, BDXTYPE_FIELD] })
    wiredRecord({ data }) {
        if (data) {
            this._defaultFilter = {
                facilityId: getFieldValue(data, FACILITY_FIELD),
                facilityUY: getFieldValue(data, FACILITY_UY_FIELD),
                accountId: getFieldValue(data, ACCOUNT_FIELD),
                bdxType: getFieldValue(data, BDXTYPE_FIELD)
            };
        }
    }


    // 📍 6. 이벤트 핸들러
    handleSearch(event) {
        this._filterCondition = event.detail;
        console.log('[Search] this._filterCondition=', this._filterCondition);
        void this._loadData();
    }

    handleReset() {
        this._filterCondition = {};
        this.tableData = [];
    }

    async handleCreate() {
        const selectedRows = this.refs.table.getSelectedRows();
        if (!selectedRows?.length) {
            toast(this, 'Warning', 'Please select records.', 'warning');
            return;
        }

        const items = selectedRows.map(row => ({
            Id: row.Id,
            Account_lk__c: row.Account_lk__c,
            FacilityParticipant_lk__c: row.FacilityParticipant_lk__c,
            BDXPeriod__c: row.BDXPeriod__c,
            IssueFrom__c: row.IssueFrom__c,
            IssueTo__c: row.IssueTo__c,
            BDXType__c: row.BDXType__c,
            Facility_lk__c: row.Facility_lk__c,
            Slip_lk__c: row.Slip_lk__c,
            OriginCurrency__c: row.OriginCurrency__c
        }));

        console.log('JSON.stringify(items)', JSON.stringify(items))

        try {
            this.isLoading = true;
            await callApex(this, createRecords, { recordId: this.recordId, selectedRowsStr: JSON.stringify(items) });
            toast(this, 'Success', this.labels.COM_MSG_SAVE_SUCCESS, 'success');
            void this._loadData();
        } catch (e) {
            // callApex handles error toast
        } finally {
            this.isLoading = false;
        }
    }

    handleRowSelection(event) {
        this._selectedCount = event.detail.selectedRows.length;
    }

    handleExpandAll() {
        this.refs.table.expandAll();
    }

    handleCollapseAll() {
        this.refs.table.collapseAll();
    }

    // 📍 7. Private 메서드
    async _loadData() {
        try {
            this.tableData = [];
            this.refs.table.clearSelection();
            this.isLoading = true;
            const results = await callApex(this, getNotes, {
                recordId: this.recordId,
                filterCondition: JSON.stringify(this._filterCondition)
            });
            // console.log('_loadData >>>>>>>>>>>>>>> results', results)

            this.tableData = results.map(row => ({
                ...row,
                locationOfLossUrl: row.ChildClaim_lk__c
                    ? `/lightning/r/Claim/${row.ChildClaim_lk__c}/related/LocationsOfLoss__r/view`
                    : null,
                locationOfLossLabel: row.ChildClaim_lk__c ? 'Locations Of Loss' : null
            }));

        } catch (e) {
            this.tableData = [];
        } finally {
            this.isLoading = false;
        }
    }

    _applyLabels(columns, fields) {
        return columns.map(col => {
            const result = { ...col };
            if (col.columns) {
                result.columns = this._applyLabels(col.columns, fields);
            }
            if (!col.label && col.name && fields[col.name]) {
                result.label = fields[col.name].label;
            }
            return result;
        });
    }

    // 📍 8. 라이프사이클 메서드
    connectedCallback() {
    }

    disconnectedCallback() {
    }


}