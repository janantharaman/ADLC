/**********************************************************************************
 * @filename      : soaNoteManageColumns.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-18 (수)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-18      i2max      Create
 **********************************************************************************/
export const NOTE_COLUMNS = [
    /*
        그룹의 collapsed: true → 초기 상태가 접힌 상태
        하위 컬럼의 collapsible: true → 그룹이 접히면 이 컬럼은 숨김
     */
    { label: 'Note', name: 'Name', type: 'url', config: { idField: 'Id', objectApiName: 'COM_Note__c' } },
    { name: 'SettlementLineItem__r.ClosingOrign__c', label: 'Closing Orign' },
    { name: 'NoteType__c' },
    { label: 'Note Details', name: 'noteDetails', collapsible: true, collapsed: false, columns: [
            { name: 'Account_lk__r.Name', label: 'Account', type: 'url', config: { idField: 'Account_lk__c', objectApiName: 'Account' } },
            { name: 'OriginCurrency__c' },
            { name: 'NoteAmount__c', type: 'number' },
            { name: 'IssueDate__c', type: 'date' },
            { name: 'NoteContact_lk__r.Name', label: 'Contact', type: 'url', config: { idField: 'NoteContact_lk__c', objectApiName: 'Contact' } },
            { name: 'NoteParticular__c' },
            { name: 'NoteAmtSettled__c'},
            { name: 'NoteAmtBalance__c' },
            { name: 'NoteStatus__c' }
        ]},
    { label: 'PPW Date', name: 'ppwDate', collapsible: true, collapsed: false, columns: [
            { name: 'PPWType__c' },
            { name: 'InstallmentNo__c', type: 'number'  },
            { name: 'InstallPct__c', type: 'number', collapsible: true  },
            { name: 'PPWDate__c', type: 'date'}
        ]},
    { label: 'Placement', name: 'placement', collapsible: true, collapsed: false, columns: [
            { name: 'LKRefNReins__c', label: 'LK Ref No.' },
            { name: 'PolicyNo__c', label: 'Cedant Ref No.', collapsible: true },
            { name: 'Reinsured_lk__r.Name', label: 'Cedant', collapsible: true, type: 'url', config: { idField: 'Reinsured_lk__c', objectApiName: 'Account' } },
            { name: 'CedantFacility_lk__r.Name', label: 'Cedant Facility Name', collapsible: true, type: 'url', config: { idField: 'CedantFacility_lk__c', objectApiName: 'Account' } },
            { name: 'Insured_lk__r.Name', label: 'Insured', type: 'url', config: { idField: 'Insured_lk__c', objectApiName: 'Account' } },
            { name: 'PeriodFrom_fm__c', label: 'Inception Date', type: 'date' },//Inception Date
            { name: 'PeriodTo_fm__c', label: 'Expiration Date', type: 'date' },//Expiration Date
            { name: 'LOB_fm__c', collapsible: true},
            { name: 'Type_fm__c', collapsible: true }
        ]},
    { label: 'Claim', name: 'claim', collapsible: true, collapsed: false, columns: [
            { name: 'ParentClaimNo_fm__c', collapsible: true },
            { name: 'CedantClaimNo_fm__c', collapsible: true },
            { name: 'DateOfLoss_fm__c' },
            { name: 'locationOfLossLabel', label: 'Location Of Loss', type: 'url', config: { urlField: 'locationOfLossUrl' } },
            { name: 'SOCSeq__c', label: 'SOC Seq' },
            { name: 'ChildClaim_lk__r.Name', label: 'Child Claim No.', collapsible: true, type: 'url', config: { idField: 'ChildClaim_lk__c', objectApiName: 'Claim' } },
        ]},
    { label: 'Debit/Credit/SOC Note', name: 'debitNote', collapsible: true, collapsed: false, columns: [
            { name: 'debitNoteChecked',  label: 'Select',   type: 'boolean', editable: true },
            { name: 'debitNoteFileName', label: 'File Name', collapsible: true }
        ]},
    { label: 'Cover Note', name: 'coverNote', collapsible: true, collapsed: false, columns: [
            { name: 'coverNoteChecked',  label: 'Select',   type: 'boolean', editable: true },
            { name: 'coverNoteFileName', label: 'File Name', collapsible: true }
        ]}
];

export const EXCEL_GROUPS = [
    {
        label: 'Note Details',
        visible: 'always',
        columns: [
            { label: 'Note No',         field: 'Name' },
            { label: 'Note Type',       field: 'NoteType__c' },
            { label: 'Origin Currency', field: 'OriginCurrency__c' },
            { label: 'Origin Amount',   field: 'OriginAmount__c' },
        ]
    },
    {
        label: 'Placement',
        visible: 'hiddenIfClaimOnly',   // Claim만 있으면 숨김
        columns: [
            { label: 'LK Ref No',       field: 'LKRefNReins__c' },
            { label: 'Account Ref No.', field: '' },  // TODO: 필드 확인
            { label: 'Type',            field: 'Type_fm__c' },
            { label: 'END No. or Declaration Period', field: '' },  // TODO: 필드 확인
            { label: 'Insured',         field: 'Insured_lk__r.Name' },
            { label: 'Cedant',          field: 'CedantFacility_lk__r.Name' },
            { label: 'Inception Date',  field: 'PeriodFrom_fm__c' },
            { label: 'Expiration Date', field: 'PeriodTo_fm__c' },
        ]
    },
    {
        label: 'Claim',
        visible: 'hiddenIfPremOnly',    // Prem만 있으면 숨김
        columns: [
            { label: 'Date of Loss',     field: 'DateOfLoss_fm__c' },
            { label: 'Location of Loss', field: 'locationOfLossLabel' },
            { label: 'Cedant Claim No.', field: 'CedantClaimNo_fm__c' },
            { label: 'SOC Seq',          field: 'SOCSeq__c' },
        ]
    }
];