import {LightningElement, api, track, wire} from 'lwc';
import {getObjectInfo} from 'lightning/uiObjectInfoApi';
import {toast, callApex} from 'c/com';
import SUBJECTIVITY_OBJECT from '@salesforce/schema/OPP_Subjectivity__c';
import getSubjectivities from '@salesforce/apex/OPP_MarketLineSubjMgmtModal_Ctrl.getSubjectivities';
import saveSubjectivities from '@salesforce/apex/OPP_MarketLineSubjMgmtModal_Ctrl.saveSubjectivities';

import COM_BTN_CLOSE from '@salesforce/label/c.COM_BTN_CLOSE';
import COM_BTN_APPLY from '@salesforce/label/c.COM_BTN_APPLY';
import COM_BTN_CANCEL from '@salesforce/label/c.COM_BTN_CANCEL';
import COM_BTN_DELETE from '@salesforce/label/c.COM_BTN_DEL';
import COM_MSG_CHECK_REQUIRED from '@salesforce/label/c.COM_MSG_CHECK_REQUIRED_FIELDS';

export default class OppMarketLineSubjMgmtModal extends LightningElement {

    labels = {
        COM_BTN_CLOSE,
        COM_BTN_APPLY,
        COM_BTN_CANCEL,
        COM_BTN_DELETE,
        COM_MSG_CHECK_REQUIRED
    }

    panelId;
    reinsurerId;
    @api isReadOnly = false;
    recordId;
    _popupParams;

    @api
    get popupParams() {
        return this._popupParams;
    }
    set popupParams(value) {
        this._popupParams = value;

        if (value) {
            this.panelId = value.panelId;
            this.reinsurerId = value.reinsurerId;
            this.recordId = value.recordId;

            if (this.panelId && this.reinsurerId) {
                void this.loadData();
            }
        }
    }


    @wire(getObjectInfo, { objectApiName: SUBJECTIVITY_OBJECT })
    objectInfo;

    get labelName() {
        return this.objectInfo.data?.fields?.Name?.label || 'Name';
    }

    get labelType() {
        return this.objectInfo.data?.fields?.Type__c?.label || 'Type';
    }

    get labelDetail() {
        return this.objectInfo.data?.fields?.Detail__c?.label || 'Detail';
    }

    get labelClear() {
        return this.objectInfo.data?.fields?.Clear_is__c?.label || 'Clear';
    }

    get hasRecords() {
        return this.rows.length > 0;
    }

    @track rows = [];
    @track typeOptions = [];
    @track editingRowKey = null;
    @track tempDetail = '';
    @track popoverStyle = '';
    @track popoverClass = 'slds-popover slds-nubbin_top-left';
    deletedRows = [];
    isLoading = false;

    async loadData() {
        this.isLoading = true;

        callApex(
            this,
            getSubjectivities,
            {
                recordId: this.recordId,
                panelId: this.panelId,
                reinsurerId: this.reinsurerId
            }
        ).then(result => {
            if (result.error) {
                toast(this, 'Error', result.error, 'error');
                this.handleClose();
                return;
            }

            this.rows = (result?.records || []).map((item, index) => ({
                ...item,
                key: item.Id,
                no: index + 1,
                isEdit: false,
                recordUrl: `/lightning/r/${item.Id}/view`,
                detailStyle: this.isReadOnly?'':'padding-right: 20px;'
            }));
            this.typeOptions = result.typeOptions || [];
            if (result.panelId && result.panelId !== this.panelId) {
                this.panelId = result.panelId;
            }
        }).catch(error => {
            // toast(this, 'Error', error.body.message, 'error');
        }).finally(() => {
            this.isLoading = false;
        });
    }

    handleAddRow() {
        const newRow = {
            key: 'tmp_' + Date.now(),
            Name: '',
            Type__c: '',
            Detail__c: '',
            Clear_is__c: false,
            Panel_lk__c: this.panelId,
            no: this.rows.length + 1,
            isEdit: true,
            detailStyle: 'padding-right: 20px;'
        };
        this.rows = [...this.rows, newRow];
    }

    handleDeleteRow(event) {
        const key = event.currentTarget.dataset.id;
        const row = this.rows.find(r => r.key === key);
        if (row.Id) {
            this.deletedRows.push(row);
        }
        this.rows = this.rows.filter(r => r.key !== key).map((r, i) => ({ ...r, no: i + 1 }));
    }

    handleChange(event) {
        const key = event.currentTarget.dataset.id || event.target.dataset.id;
        const field = event.currentTarget.dataset.field || event.target.dataset.field;
        const detail = JSON.parse(JSON.stringify(event.detail))
        let value;

        if (event.target.type!==undefined && event.target.type === 'checkbox') {
            value = event.target.checked;
        }  else {
            value = detail.value;
        }

        const idx = this.rows.findIndex(r => r.key === key);
        if (idx >= 0) {
            this.rows[idx] = { ...this.rows[idx], [field]: value };
        }
    }

    // 📍 API 메서드: 부모(oppModalContainer)가 호출
    @api
    async save() {
        let isValid = true;

        // 1. Name 필드 검증
        const inputs = this.template.querySelectorAll('lightning-input[data-field="Name"]');
        inputs.forEach(input => {
            if (!input.reportValidity()) {
                isValid = false;
            }
        });

        // 2. Detail 필드 검증 (커스텀 스타일 적용)
        this.rows = this.rows.map(row => {
            const val = row.Detail__c;
            // 값이 없거나 공백만 있는 경우 에러 처리
            if (!val) {// || val.trim() === ''
                isValid = false;
                return {
                    ...row,
                    detailStyle: 'padding-right: 20px; border-color: #c23934; box-shadow: 0 0 0 1px #c23934 inset;'
                };
            }
            return {...row, detailStyle: 'padding-right: 20px;'};
        });

        if (!isValid) {
            toast(this, '확인', this.labels.COM_MSG_CHECK_REQUIRED, 'warning');
            return { success: false, message: this.labels.COM_MSG_CHECK_REQUIRED };
        }

        const upsertList = this.rows.map(r => {
            const rec = {
                sobjectType: 'OPP_Subjectivity__c',
                Name: r.Name,
                Type__c: r.Type__c,
                Detail__c: r.Detail__c,
                Clear_is__c: r.Clear_is__c,
                Panel_lk__c: this.panelId
            };
            if (r.Id) rec.Id = r.Id;
            return rec;
        });

        const deleteList = this.deletedRows.map(r => ({
            sobjectType: 'OPP_Subjectivity__c',
            Id: r.Id
        }));

        try {
            await callApex(
                this,
                saveSubjectivities,
                {
                    upsertList: upsertList,
                    deleteList: deleteList
                }
            );
            return { success: true };
        } catch (e) {
            return { success: false, message: e.body?.message || e.message };
        }
    }
    // ===== RichText Popover Logic =====
    handleOpenEdit(event) {
        const key = event.currentTarget.dataset.id;
        const row = this.rows.find(r => r.key === key);
        if (!row) return;

        this.tempDetail = row.Detail__c;
        this.editingRowKey = key;

        const popWidth = 600;

        // 화면 중앙 정렬 (좌표 계산 문제 해결 및 확실한 가시성 확보)
        this.popoverClass = 'slds-popover'; // nubbin 제거
        this.popoverStyle = `
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            width: ${popWidth}px;
            z-index: 9999;
            box-shadow: 0 4px 16px rgba(0,0,0,0.2);
        `;
    }

    handleCloseEdit() {
        this.editingRowKey = null;
        this.tempDetail = '';
    }

    handleApplyEdit() {
        if (this.isReadOnly) {
            this.handleCloseEdit();
            return;
        }
        const idx = this.rows.findIndex(r => r.key === this.editingRowKey);
        if (idx >= 0) {
            this.rows[idx] = {
                ...this.rows[idx],
                Detail__c: this.tempDetail,
                detailStyle: 'padding-right: 20px;' // 값 수정 시 에러 스타일 초기화
            };
        }
        this.handleCloseEdit();
    }

    handleDetailChange(event) {
        this.tempDetail = event.target.value;
    }

    handlePopupClick(event) {
        event.stopPropagation();
    }

    // 📍 6. 이벤트 핸들러
    handleAction(event) {
        const action = event.currentTarget?.dataset?.action || event.detail?.value;
        const key = event.currentTarget.dataset.id || event.target.dataset.id;

        switch (action) {
            case 'nameEdit': {
                const row = this.rows.find(r => r.key === key);
                if (!row) return;
                row.isEdit = true;
                break;
            }
            default:
                if (action) toast(this, `${action} 기능은 정의되어 있지 않습니다.`, 'info');
        }
    }

    connectedCallback() {
    }

}