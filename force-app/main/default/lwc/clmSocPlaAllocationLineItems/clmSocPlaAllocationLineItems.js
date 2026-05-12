/**********************************************************************************
 * @filename      : clmSocPlaAllocationLineItems.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-26 (월)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-26      i2max      Create
 **********************************************************************************/
import { LightningElement, api, wire, track } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import {getCurrencyScale } from 'c/com';
import ALLOC_OBJECT from '@salesforce/schema/CLM_Allocation__c';
import COM_BTN_REFRESH from '@salesforce/label/c.COM_BTN_REFRESH';
import COM_BTN_DEL from '@salesforce/label/c.COM_BTN_DEL';

export default class clmSocPlaAllocationLineItems extends LightningElement {

    labels = {
        COM_BTN_REFRESH,
        COM_BTN_DEL
    }

    _items = [];
    @track _displayItems = [];

    @api
    get items() { return this._items; }
    set items(value) {
        this._items = value;
        // console.log('[LineItems] Received items:', JSON.stringify(this._items))
        this.initDisplayItems();
    }
    @api isDisabled;

    _claimCurrency;
    @api
    get claimCurrency() { return this._claimCurrency; }
    set claimCurrency(value) {
        this._claimCurrency = value;
    }


    initDisplayItems() {

        this._displayItems = this._items.filter(item => !item.isDeleted).map((item, index) => {
            // console.log('initDisplayItems items:', JSON.stringify(item))
            let rowClass = 'slds-hint-parent';
            // tmp로 시작하면 slds-is-edited 추가
            if (String(item.Id).startsWith('tmp')) {
                rowClass += ' slds-is-edited';
            }
            return {
                ...item,
                _rowNo: index + 1,
                isSelected: false,
                rowClass: rowClass
            };
        });
    }

    // 📍 Wire: CLM_Allocation__c 객체 정보 (필드 라벨용)
    @wire(getObjectInfo, { objectApiName: ALLOC_OBJECT })
    objectInfo;

    // 📍 Getters for Labels
    get labelSeq() { return this.objectInfo?.data?.fields?.PanelGroupSeq__c?.label || 'Seq.'; }
    get labelNo() { return 'No.'; } // 화면상 순번
    get labelType() { return this.objectInfo?.data?.fields?.ClaimDocType__c?.label || 'SOC/PLA'; }
    get labelLoss() { return this.objectInfo?.data?.fields?.LossAmt__c?.label || 'Loss Amount'; }
    get labelExpense() { return this.objectInfo?.data?.fields?.ExpAmt__c?.label || 'Expense Amount'; }
    get labelTotal() { return this.objectInfo?.data?.fields?.AllocatedTotalAmt_fm__c?.label || 'Total Amount'; }
    get labelReinsurer() { return this.objectInfo?.data?.fields?.Reinsurer_lk__c?.label || 'Reinsurer'; }
    get labelSigned() { return this.objectInfo?.data?.fields?.SignedLine__c?.label || 'Signed Line(%)'; }
    get labelTotalRI() { return this.objectInfo?.data?.fields?.TotalAmtForRI__c?.label || 'Total Amount (for Reinsurer)'; }
    get labelSettlementCurr() { return this.objectInfo?.data?.fields?.SettlementCurrency__c?.label || 'Settlement Currency'; }
    get labelTotalRISettled() { return 'Total Amount(for Reinsurer) Settlement Currency'; }
    get labelIssueDate() { return this.objectInfo?.data?.fields?.IssueDate_fm__c?.label || 'SOC/PLA Issue Date'; }
    get labelFacility() { return 'Facility/MGA Name'; }
    get labelOffset() { return 'Facility BOX Offset'; } //

    // 📍 Getters for Data
    get hasItems() {
        return this._displayItems && this._displayItems.length > 0;
    }

    get displayItems() {
        return this._displayItems;
    }

    get isAllSelected() {
        return this.hasItems && this._displayItems.every(item => item.isSelected);
    }

    get isDeleteDisabled() {
        return !this._displayItems.some(item => item.isSelected);
    }

    get currencyScale() {
        return getCurrencyScale(this.claimCurrency, 2);
    }

    handleSelectAll(event) {
        const checked = event.target.checked;
        this._displayItems = this._displayItems.map(item => ({ ...item, isSelected: checked }));
    }

    handleRowSelect(event) {
        const id = event.target.dataset.id;
        const checked = event.target.checked;

        // 1. 클릭된 행 찾기
        const targetItem = this._displayItems.find(item => item.Id === id);
        if (!targetItem) return;

        const targetSeq = targetItem.PanelGroupSeq__c;

        // 2. 같은 Seq를 가진 모든 행의 isSelected 업데이트
        this._displayItems = this._displayItems.map(item => {
            if (item.PanelGroupSeq__c === targetSeq) {
                return { ...item, isSelected: checked };
            }
            return item;
        });
    }

    handleRefresh() {
        this.dispatchEvent(new CustomEvent('refresh'));
    }

    handleDelete() {
        const selectedIds = this._displayItems.filter(item => item.isSelected).map(item => item.Id);
        if (selectedIds.length === 0) return;

        // 다건 삭제 이벤트 발송
        this.dispatchEvent(new CustomEvent('delete', { detail: { ids: selectedIds } }));
    }

}