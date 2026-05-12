/**********************************************************************************
 * @filename      : clmSocPlaAllocationSummary.js
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
import { LightningElement, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import CLAIM_OBJECT from '@salesforce/schema/Claim';

import {getCurrencyScale } from 'c/com';

export default class clmSocPlaAllocationSummary extends LightningElement {

    @api recordId;
    @api records;
    @api errors;

    get displayRecords() {
        if(!this.records) return [];
        return this.records.map(table => {
            const errorMessages = this.errors ? this.errors[table.type] : null;
            return {
                ...table,
                error: errorMessages
            };
        });
    }

    get currencyScale() {
        this.claimCurrency = this.records?.[0]?.claimCurrency || '';
        return getCurrencyScale(this.claimCurrency, 2);
    }

    // 📍 Wire: Claim 객체 정보 (필드 라벨용)
    @wire(getObjectInfo, { objectApiName: CLAIM_OBJECT })
    objectInfo;

    // Field Labels (동적 바인딩)
    get labelCurrency() { return this.objectInfo?.data?.fields?.ClaimCurrency__c?.label || 'Currency'; }
    get labelType() { return this.objectInfo?.data?.fields?.ClaimDocType__c?.label || 'Type'; }
    get labelLoss() { return this.objectInfo?.data?.fields?.LossAmt__c?.label || 'Loss Amount'; }
    get labelExpense() { return this.objectInfo?.data?.fields?.ExpAmt__c?.label || 'Expense Amount'; }
    get labelTotal() { return this.objectInfo?.data?.fields?.AllocatedTotalAmt_fm__c?.label || 'Total Amount'; }
    get labelTotalLk() { return this.objectInfo?.data?.fields?.TotalAmtLK_fm__c?.label || 'Total Amount (LK)'; }



}