/**********************************************************************************
 * @filename      : ComFacilityBdxLineItemList.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-22 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-22      i2max      Create
 **********************************************************************************/
import {LightningElement, api} from 'lwc';

export default class ComFacilityBdxLineItemList extends LightningElement {
    @api recordId;
    @api type = 'Premium';  // Premium / Claim

    get childObject() {
        return 'COM_FacilityBDXLineItem__c';
    }
    get parentRecordField() {
        return 'FacilityBDX_md__c';
    }
    get filterCondition() {
        return `Type__c = '${this.type}'`;
    }
    get displayFields() {
        const common = 'Note_lk__c,AccountRefNo_fm__c,OriginCurrency_fm__c,OriginAmount_fm__c,Particular_fm__c,LKRefNo_fm__c,UY_fm__c,Insured_fm__c,InsuredNm_fm__c,InceptionDate_fm__c,ExpirationDate_fm__c,TransationType_fm__c';
        if (this.type === 'Premium') {//TSIByLocation_lk__c
            return `${common},Slip_lk__c,TSICurrencySlip_fm__c,TSIAmountSlip_fm__c,PremCurrency_fm__c,GrossPrem_fm__c,TotalOrderPct_fm__c,PremOnLKShare_fm__c,TotalDeductionPct_fm__c,TotalDeduction_fm__c,NetShare_fm__c`;
        }
        return `${common},CedantClaimNo_fm__c,DateOfLoss_fm__c,Claim_lk__c`;
    }
    get fieldOverrides() {
        return {
            'InsuredNm_fm__c': {
                type: 'url',
                config: { idField: 'Insured_fm__c', objectApiName: 'Account' }
            },
            'locationOfLossLabel': {
                type: 'url',
                label: 'Location Of Loss',
                config: { urlField: 'locationOfLossUrl' }
            }
        };
    }
    get columnDefs() {
        const common = [
            // {label: 'Note No', fields: ['Note_lk__c']},
            {label: 'Note Info', fields: ['AccountRefNo_fm__c', 'OriginCurrency_fm__c', 'OriginAmount_fm__c', 'Particular_fm__c']},
            {
                label: 'Placement',
                fields: ['LKRefNo_fm__c', 'UY_fm__c', 'InsuredNm_fm__c', 'InceptionDate_fm__c', 'ExpirationDate_fm__c', 'TransationType_fm__c']
            }
        ];
        if (this.type === 'Premium') {
            return [
                ...common,
                {label: 'Slip Info', fields: ['Slip_lk__c', 'TSICurrencySlip_fm__c', 'TSIAmountSlip_fm__c']},
                {
                    label: 'Prem from Cedant',
                    fields: ['PremCurrency_fm__c', 'GrossPrem_fm__c', 'TotalOrderPct_fm__c', 'PremOnLKShare_fm__c', 'TotalDeductionPct_fm__c', 'TotalDeduction_fm__c', 'NetShare_fm__c']
                }
            ];
        }
        return [
            ...common,
            {label: 'Claim Info', fields: ['CedantClaimNo_fm__c', 'DateOfLoss_fm__c','locationOfLossLabel']}
        ];
    }
    get computedFields() {
        if (this.type !== 'Claim') return null;
        return [
            { name: 'locationOfLossUrl', sourceField: 'Claim_lk__c__id', template:
                    '/lightning/r/Claim/{value}/related/LocationsOfLoss__r/view' },
            { name: 'locationOfLossLabel', sourceField: 'Claim_lk__c__id', value: 'Locations Of Loss' }
        ];
    }

}