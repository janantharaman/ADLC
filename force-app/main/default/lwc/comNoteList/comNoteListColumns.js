/**********************************************************************************
 * @filename      : comNoteListColumns.js
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
// import LBL_PLACEMENT from '@salesforce/label/c.COM_LBL_PLACEMENT';
// import LBL_CLAIM from '@salesforce/label/c.COM_LBL_CLAIM';
// import LBL_PPW_DATE from '@salesforce/label/c.COM_LBL_PPW_DATE';
// import LBL_NOTE_DETAILS from '@salesforce/label/c.COM_LBL_NOTE_DETAILS';

export const NOTE_COLUMNS = [
    /*
        그룹의 collapsed: true → 초기 상태가 접힌 상태
        하위 컬럼의 collapsible: true → 그룹이 접히면 이 컬럼은 숨김
     */
    { label: 'Note No', name: 'Name' },
    { label: 'Placement', name: 'placement', collapsible: true, collapsed: false, columns: [
            { name: 'LKRefNReins__c', collapsible: true },
            { name: 'FacilityUY_fm__c', collapsible: true },
            { name: 'CedantFacility_lk__r.Name', label: 'Cedant', collapsible: true, type: 'url' },
            { name: 'Insured_lk__r.Name', label: 'Insured', collapsible: true, type: 'url' },
            { name: 'PeriodFrom_fm__c', type: 'date', collapsible: true },//Inception Date
            { name: 'PeriodTo_fm__c', type: 'date', collapsible: true },//Expiration Date
            { name: 'LOB_fm__c', collapsible: true},
            { name: 'TransactionType_fm__c' }
        ]},
    { label: 'Claim', name: 'claim', collapsible: true, collapsed: false, columns: [
            { name: 'ParentClaimNo_fm__c', collapsible: true },
            { name: 'CedantClaimNo_fm__c', collapsible: true },
            { name: 'DateOfLoss_fm__c', collapsible: true },
            { name: 'locationOfLossLabel', label: 'Location Of Loss', type: 'url', config: { urlField: 'locationOfLossUrl' }, collapsible: true },//Location Of Loss
            { name: 'SOCSeq__c', label: 'SOC Seq.', collapsible: true },
            { name: 'ChildClaim_lk__r.Name', label: 'Child Claim', type: 'url', config: { idField: 'ChildClaim_lk__c', objectApiName: 'Claim' } },
        ]},
    { label: 'PPW Date', name: 'ppwDate', collapsible: true, collapsed: false, columns: [
            { name: 'PPWType__c', collapsible: true },
            { name: 'PPWDays_fm__c', type: 'number', collapsible: true },
            { name: 'InstallmentNo__c', type: 'number', collapsible: true },
            { name: 'InstallmentSeq__c', type: 'number', collapsible: true },
            { name: 'InstallPct__c', type: 'number', collapsible: true },
            { name: 'PPWDate__c', type: 'date' }
        ]}
];