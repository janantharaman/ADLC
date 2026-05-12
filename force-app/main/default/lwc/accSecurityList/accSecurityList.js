/**********************************************************************************
 * @filename      : accSecurityList.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-12-09 (화)
 * @group         :
 * @group-content :
 * @description   : Account 기준 Security(ACC_AdditionalInfo__c) 목록을 조회/검색하고,
 *                  수정·신규 추가·삭제·저장 및 파일 개수 표시/상세 이동을 제공하는 LWC 컴포넌트
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2025-12-09      i2max      Create
 **********************************************************************************/

import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getObjectInfo, getPicklistValues } from 'lightning/uiObjectInfoApi';

import LOCALE from '@salesforce/i18n/locale';
import ACC_SECURITY_OBJECT from '@salesforce/schema/ACC_AdditionalInfo__c';
import COUNTRY_FIELD from '@salesforce/schema/ACC_AdditionalInfo__c.Country__c';

import searchSecurityData from '@salesforce/apex/AccSecurityListAction_Ctrl.searchSecurityData';
import insertNewRecords from '@salesforce/apex/AccSecurityListAction_Ctrl.insertNewRecords';
import deleteRecords from '@salesforce/apex/AccSecurityListAction_Ctrl.deleteRecords';
import updateSecurityRecords from '@salesforce/apex/AccSecurityListAction_Ctrl.updateSecurityRecords';
import getFileCounts from '@salesforce/apex/AccSecurityListAction_Ctrl.getFileCounts';
//import getSecurityPermission from '@salesforce/apex/AccSecurityListAction_Ctrl.getSecurityPermission';
import getAccountType from '@salesforce/apex/AccSecurityListAction_Ctrl.getAccountType';
import getCountry from '@salesforce/apex/AccSecurityListAction_Ctrl.getCountry';

const EDITABLE_FIELDS = [
    'Reinsurer_lk__c', 'Country__c', 'BindingFrom__c', 'BindingTo__c', 'Remarks__c'
];

import LABEL_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import LABEL_DELETE from "@salesforce/label/c.COM_BTN_DEL";
import LABEL_ADD from "@salesforce/label/c.COM_BTN_ADD";
import LABEL_NORECORDS from '@salesforce/label/c.COM_MSG_NORECORDS';
import LABEL_SEARCH from '@salesforce/label/c.COM_LBL_SEARCH';
import LABEL_RESET from '@salesforce/label/c.COM_BTN_RESET';
import LABEL_VIEW_ALL from '@salesforce/label/c.COM_LBL_VIEW_ALL';
import LABEL_ACTIVE from '@salesforce/label/c.ACC_LBL_ACTIVE';
import LABEL_LETTER_OF_AUTHORITY from '@salesforce/label/c.ACC_LBL_LETTER_OF_AUTHORITY';

export default class AccSecurityList extends NavigationMixin(LightningElement) {

    @api recordId;

    @track records = []; // 화면에 실제로 보여줄 레코드
    @track deletedRecordIds = []; // 실제로 삭제 레코드 Ids
    @track allRecords = []; // 전체 레코드
    @track newRecords = [];
    @track selectedIds = [];
    @track reinsurerOptions = [];
    @track isLoading = false;

    @track countryOptions = []; // Country picklist options
    recordTypeId;
    countryLabelMap = {}; // Country 라벨 매핑용
    objectFields;
    countryDisplay;

    @track searchParams = {
        accountId : null,
        reinsurer : null,
        periodFrom : null,
        periodTo : null
    };

    // 현재 수정 중
    editingCell = {
        rowId: null,
        field: null
    }
    editingRowId = null;
    // 저장 되지 않은 수정된 셀
    dirtyCells = new Set();
    // update 전용
    updatedRecordMap = {};

    visibleCount = 10; // 화면에 보여줄 레코드 수
    pageSize = 10; // view all 시 증가할 레코드 수

    labels = {
        save: LABEL_SAVE,
        delete: LABEL_DELETE,
        add: LABEL_ADD,
        noRecords: LABEL_NORECORDS,
        search: LABEL_SEARCH,
        reset: LABEL_RESET,
        viewAll: LABEL_VIEW_ALL,
        active: LABEL_ACTIVE,
        letterOfAuthority: LABEL_LETTER_OF_AUTHORITY
    };

    accountInsuredType; // 'Reinsurer' | 'MGA'

    /**
     * @description Reinsurer Lookup 컴포넌트 설정 반환 — InsuredType__c = 'Reinsurer' 필터 적용
     * @returns {Object} Lookup 컴포넌트 설정 객체
     */
    get reinsurerLookupConfig() {
        const config = {
            objectApiName: 'Account',
            labelField: 'Name',
            filters: [
                {
                    field: 'InsuredType__c',
                    op: 'INCLUDES',
                    value: 'Reinsurer',
                    type: 'MULTIPICKLIST',
                    groupKey: 'base'
                }
            ]
        };

        return config;
    }


    /**
     * @description ACC_AdditionalInfo__c ObjectInfo wire — objectFields / recordTypeId 설정
     * @param {Object} data ObjectInfo 데이터
     * @param {Object} error 오류 객체
     */
    @wire(getObjectInfo, { objectApiName: ACC_SECURITY_OBJECT })
    wiredObjectInfo({ data, error }) {
        if (data?.fields) {
            this.objectFields = data.fields;
            this.recordTypeId = data.defaultRecordTypeId;
        } else if (error) {
            this.objectFields = null;
            console.error('Error loading object info:', error);
        }
    }

    /**
     * @description Country__c Picklist wire — countryOptions / countryLabelMap 설정
     * @param {Object} data Picklist 데이터
     * @param {Object} error 오류 객체
     */
    @wire(getPicklistValues, {
        recordTypeId: '$recordTypeId',
        fieldApiName: COUNTRY_FIELD
    })
    wiredCountryPicklist({ data, error }) {
        if (data) {
            this.countryOptions = data.values.map(item => ({
                label: item.label,
                value: item.value
            }));

            // value → label 매핑
            this.countryLabelMap = {};
            data.values.forEach(item => {
                this.countryLabelMap[item.value] = item.label;
            });
        } else if (error) {
            console.error('Country Picklist Error', error);
        }
    }

    /*
        get reinsurerLookupConfig() {
            return this.getReinsurerLookupConfig('Reinsurer');
        }

        get mgaLookupConfig() {
            return this.getReinsurerLookupConfig('MGA');
        }*/

    get ACCNameLabel() {
        return this.objectFields?.Name?.label ?? 'Name';
    }

    get MGANameLabel() {
        return this.objectFields?.Account_lk__c?.label ?? 'MGA';
    }

    get ReinsurerNameLabel() {
        return this.objectFields?.Reinsurer_lk__c?.label ?? 'Reinsurer';
    }

    get CountryLabel() {
        return this.objectFields?.Country__c?.label ?? 'Country';
    }

    get BindingFromLabel() {
        return this.objectFields?.BindingFrom__c?.label ?? 'Binding From';
    }

    get BindingToLabel() {
        return this.objectFields?.BindingTo__c?.label ?? 'Binding To';
    }

    get RemarksLabel() {
        return this.objectFields?.Remarks__c?.label ?? 'Remarks';
    }

    /**
     * @description 표시할 레코드가 없는지 여부 반환
     * @returns {boolean} allRecords / newRecords 모두 비어있으면 true
     */
    get noData() {
        return (
            (!this.allRecords || this.allRecords.length === 0) &&
            (!this.newRecords || this.newRecords.length === 0)
        );
    }

    /**
     * @description 읽기 전용 여부 반환 (현재 항상 false)
     * @returns {boolean}
     */
    get isReadOnly() {
        //return !this.isEditable;
        return false;
    }

    /*handleReinsurerChange(event) {
        const accountId = event.detail.value;

        this.searchParams.reinsurer = accountId;

        if (!accountId) {
            this.countryDisplay = '';
            return;
        }

        getCountry({ accountId })
            .then(country => {
                this.countryDisplay = country || '';

                this.searchParams.country = this.countryDisplay;
            })
            .catch(err => {
                console.error('Country load error', err);
                this.countryDisplay = '';
            });
    }*/

    /**
     * @description Account InsuredType 조회 — accountInsuredType 설정
     */
    loadAccountType() {
        getAccountType({ accountId: this.recordId })
            .then(acc => {
                this.accountInsuredType = acc?.InsuredType__c;
            })
            .catch(err => {
                console.error(err);
            });
    }

    /**
     * @description 컴포넌트 초기화 — Account Type 조회 및 레코드 자동 검색 수행
     */
    connectedCallback() {
        // Account Type 조회
        this.loadAccountType();

        // related 레코드 자동 조회
        if (this.recordId) {
            this.searchParams.accountId = this.recordId;

       /*     // 권한 체크
            getSecurityPermission({ accountId : this.recordId }).
                then(result => {
                    this.isEditable = result;
                    console.log('Permission Check Result', result);
            })
                .catch(error => {
                    console.error('Permission Check Error', error);
                    this.isEditable = false;
                });*/
            this.handleSearch();
        }
    }

    /**
     * @description 신규 행의 필수 입력값이 모두 비어있는지 확인
     * @param {Object} row 신규 행 레코드
     * @returns {boolean} 필수 입력값이 모두 비어있으면 true
     */
    isEmptyNewRow(row) {
        return (
            !row.Reinsurer__c &&
            !row.Country__c &&
            !row.BindingFrom__c &&
            !row.BindingTo__c
        );
    }

    /**
     * @description
     * 인라인 셀 값 변경 핸들러 — records 즉시 반영 및 updatedRecordMap 에 변경 내용 누적
     * - 신규 행(newRecords) 은 updatedRecordMap 에서 제외
     * @param {Event} event change 이벤트 (data-id, data-field 속성 포함)
     */
    handleInlineChange(event) {
        const recordId = event.target.dataset.id;
        const field = event.target.dataset.field;
        const value = event.target.value;

        const rowKey = event.detail.rowKeyValue;   // ★ 임시 key

        // 화면상 값 바로 반영
        this.records = this.records.map(rec =>
            rec.Id === recordId ? { ...rec, [field]: value } : rec
        );

        // 신규 행이면 무조건 update 제외
        const isNewRow = this.newRecords.some(r => String(r.key) === String(rowKey));

        if (isNewRow) {
            return;
        }

        // 수정 상태 표시용
        const cellKey = `${recordId}_${field}`;
        this.dirtyCells.add(cellKey);

        // 업데이트용 map
        if (!this.updatedRecordMap[recordId]) {
            this.updatedRecordMap[recordId] = { Id: recordId };
        }
        this.updatedRecordMap[recordId][field] = value;
    }

    /**
     * @description
     * Lookup 값 변경 핸들러 — newRecords 업데이트 및 Reinsurer 변경 시 Country 자동 조회
     * - Reinsurer 선택 해제 시 Country / CountryLabel 초기화
     * @param {Event} event change 이벤트 (data-key 또는 data-rowkey, data-field 속성 포함)
     */
    handleLookupChange(event) {
        const newKey =
            event.target.dataset.key ||
            event.target.dataset.rowkey;

        const field =
            event.target.dataset.field ||
            event.target.fieldName;

        const value =
            event.detail?.value?.id ||
            event.detail?.value ||
            event.detail?.selectedId ||
            event.detail?.recordId ||
            null;

        const lookup = event.target;

        if (value) {
            lookup.classList.add('hide-icon');
        } else {
            lookup.classList.remove('hide-icon');
        }

        if (newKey) {
            this.newRecords = this.newRecords.map(rec => {
                if (String(rec.key) !== String(newKey)) return rec;

                const updated = {
                    ...rec,
                    [field]: value,
                    Account_lk__c: this.recordId,
                    _hasError: !value,
                    hasErrorClass: value ? '' : 'cell-error'
                };

                if (typeof field === 'string' && field.includes('Reinsurer') && !value) {
                    updated.Country__c   = '';
                    updated.CountryLabel = '';
                }

                return updated;
            });
        }

        if (typeof field === 'string' && field.includes('Reinsurer') && value) {
            getCountry({ accountId: value })
                .then(country => {
                    this.newRecords = this.newRecords.map(rec =>
                        String(rec.key) === String(newKey)
                            ? {
                                ...rec,
                                Country__c: country,
                                CountryLabel:
                                    this.countryLabelMap[country] || country || ''
                            }
                            : rec
                    );
                })
                .catch(e => console.error(e));
        }
    }

    /**
     * @description 검색 조건 입력 변경 핸들러 — searchParams 업데이트
     * @param {Event} event change 이벤트 (data-field 속성 포함)
     */
    handleInputChange(event) {
        const field = event.target.dataset.field;
        const value = event.target.value;

        if (field === 'name') this.searchParams.reinsurer = value;
        if (field === 'from') this.searchParams.periodFrom = value;
        if (field === 'to') this.searchParams.periodTo = value;
    }

    /**
     * @description From / To 날짜 범위 유효성 검증 — To 가 From 보다 이전이면 오류 Toast 표시
     * @param {string} fromValue From 날짜 문자열
     * @param {string} toValue To 날짜 문자열
     * @param {string} contextLabel 오류 메시지에 표시할 컨텍스트 레이블
     * @returns {boolean} 유효하면 true, 유효하지 않으면 false
     */
    validateFromToRange(fromValue, toValue, contextLabel) {
        // 둘 다 비어있으면 OK
        if (!fromValue && !toValue) {
            return true;
        }

        if (fromValue && toValue) {
            const from = new Date(fromValue);
            const to = new Date(toValue);

            if (to < from) {
                this.showToast(
                    'Error',
                    `${contextLabel}: To date cannot be earlier than From date.`,
                    'error'
                );
                return false;
            }
        }


        return true;
    }

    /**
     * @description 신규 행 전체에 대한 날짜 범위 유효성 검증
     * @returns {boolean} 모든 신규 행이 유효하면 true
     */
    validateDateRangeForInsert() {
        for (const rec of this.newRecords) {
            if (!this.validateFromToRange(
                rec.BindingFrom__c,
                rec.BindingTo__c,
                'Insert'
            )) {
                return false;
            }
        }
        return true;
    }

    /**
     * @description 수정 중인 기존 행 전체에 대한 날짜 범위 유효성 검증
     * - 수정된 From / To 값이 없으면 원본 레코드 값으로 대체하여 검증
     * @returns {boolean} 모든 수정 행이 유효하면 true
     */
    validateDateRangeForUpdate() {
        for (const recordId in this.updatedRecordMap) {
            const updated = this.updatedRecordMap[recordId];
            const original = this.records.find(r => r.Id === recordId);

            const fromValue =
                updated.BindingFrom__c ?? original?.BindingFrom__c;
            const toValue =
                updated.BindingTo__c ?? original?.BindingTo__c;

            if (!this.validateFromToRange(
                fromValue,
                toValue,
                'Update'
            )) {
                return false;
            }
        }
        return true;
    }

    /**
     * @description
     * 신규 행 입력 유효성 검증 — Reinsurer_lk__c / BindingFrom__c / BindingTo__c 필수 입력 검증
     * - 오류 행에 셀 오류 클래스 설정
     * @returns {{ isValid: boolean, validRecords: Array }} 검증 결과 및 유효한 레코드 목록
     */
    validateNewRows() {
        let isValid = true;

        this.newRecords = this.newRecords.map(rec => {
            const hasReinsurerError = !rec.Reinsurer_lk__c;
            const hasFromDateError = !rec.BindingFrom__c;
            const hasToDateError = !rec.BindingTo__c;

            if (hasReinsurerError || hasFromDateError || hasToDateError) {
                isValid = false;
            }

            return {
                ...rec,
                _hasError_Reinsurer: hasReinsurerError,
                _hasError_From: hasFromDateError,
                _hasError_To: hasToDateError,
                hasErrorClassReinsurer: hasReinsurerError ? 'cell-error' : '',
                hasErrorClassFrom: hasFromDateError ? 'cell-error' : '',
                hasErrorClassTo: hasToDateError ? 'cell-error' : ''
            };
        });

        const validRecords = this.newRecords.filter(r =>
        r.Reinsurer_lk__c && r.BindingFrom__c && r.BindingTo__c).map(r => ({
            Reinsurer_lk__c: r.Reinsurer_lk__c,
            BindingFrom__c: r.BindingFrom__c,
            BindingTo__c: r.BindingTo__c,
            Country__c: r.Country__c,
            Remarks__c: r.Remarks__c,
            Account_lk__c: this.recordId
        }));

        return { isValid, validRecords };
    }

    /**
     * @description 검색 후 화면 상태 초기화 — visibleCount 초기화, records / selectedIds 갱신
     */
    afterSearchRender() {
        this.visibleCount = 10;
        this.records = this.allRecords.slice(0, this.visibleCount);
        this.selectedIds = [];
    }

    /**
     * @description
     * 검색 조건 기반 Security 레코드 조회 — 검색 결과를 allRecords 에 설정 후 파일 개수 조회
     * - 날짜 범위 유효성 검증 후 Apex 호출
     * - 조회 완료 후 레코드별 첨부 파일 개수 및 파일 URL 설정
     * @returns {Promise<void>}
     */
    handleSearch() {
        // 날짜 범위 검증
        const {periodFrom, periodTo} = this.searchParams;

        if (!this.validateFromToRange(periodFrom, periodTo, 'Search')) {
            return Promise.resolve();
        }

        const params = {
            accountId: this.searchParams.accountId,
            reinsurer: this.searchParams.reinsurer,
            periodFrom: this.searchParams.periodFrom,
            periodTo: this.searchParams.periodTo,
        };

        this.isLoading = true;

        return searchSecurityData({ searchParams: params })
            .then(result => {
                const list = result || [];

                this.allRecords = list.map((rec, index) => ({
                    ...rec,
                    rowNo: index + 1,
                    ReinsurerName: rec.Reinsurer_lk__r
                        ? rec.Reinsurer_lk__r.Name
                        : '',
                    CountryLabel: this.countryLabelMap[rec.Country__c] || '',
                    fileCount: 0,
                    filesUrl: '',
                    isEditing: this.editingCell.rowId === rec.Id
                }));

                this.afterSearchRender();

                const recordIds = this.allRecords.map(r => r.Id);

                if (recordIds.length === 0) {
                    return;
                }

                // 파일 개수 조회
                return getFileCounts({ recordIds })
                    .then(countMap => {

                        this.allRecords = this.allRecords.map(rec => ({
                            ...rec,
                            fileCount: countMap && countMap[rec.Id]
                                ? countMap[rec.Id]
                                : 0,
                            filesUrl: `/lightning/r/ACC_AdditionalInfo__c/${rec.Id}/related/AttachedContentDocuments/view`
                        }));

                        this.afterSearchRender();
                    });
            })
            .catch(error => {
                console.error('SEARCH ERROR >>>', error);
                this.records = [];
                this.allRecords = [];
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    /**
     * @description 검색 조건 초기화 후 재검색 — accountId 만 유지
     */
    handleReset() {
        // 검색 조건 초기화
        this.searchParams = {
            accountId : this.recordId,
            reinsurer : null,
            periodFrom : null,
            periodTo : null
        };

        this.handleSearch();
    }

    /**
     * @description
     * 화면 전체 새로고침 — 검색 입력값 / 편집 상태 / 신규 행 / 체크박스 초기화 후 재검색
     */
    handleRefresh() {
        const searchInputs = this.template.querySelectorAll('lightning-input[data-role="search"], lightning-combobox[data-role="search"]');
        searchInputs.forEach(input => {
            input.value = null;
        });

        this.editingCell = { rowId: null, field: null };
        this.editingRowId = null;
        this.dirtyCells = new Set();
        this.updatedRecordMap = {};
        this.newRecords = [];

        this.selectedIds = [];
        this.resetTableCheckboxes();

        this.records = this.records.map(r => ({
            ...r,
            isEditing: false
        }));

        Promise.resolve(this.handleSearch())
            .then(() => {
                console.log('REFRESH DONE (file counts updated)');
            });
    }

    /**
     * @description 신규 행 추가 — 기본값으로 초기화된 빈 행을 newRecords 끝에 추가
     */
    handleAdd() {
        const baseRowNo = this.allRecords.length; // 기존 레코드 수
        const nextRowNo = this.allRecords.length + this.newRecords.length + 1; // 행 추가된 레코드 수

        const newRow = {
            key: Date.now(),
            rowNo: nextRowNo,
            isNew: true,
            isSelected: false,
            disableSelect: false,
            Account_lk__c: this.recordId,
            ActiveSecurity_is__c: false,
            Reinsurer_lk__c: null
            // Account_lk__c: null
        };

       /* if (this.accountInsuredType.includes('Reinsurer')) {
            newRow.Reinsurer_lk__c = this.recordId;
        } else if (this.accountInsuredType.includes('MGA')) {
            newRow.Account_lk__c = this.recordId;
        }*/

        this.newRecords = [...this.newRecords, newRow];
    }

    /**
     * @description
     * 신규 행 필드 값 변경 핸들러 — newRecords 업데이트 및 필드별 오류 상태 설정
     * - BindingFrom__c / BindingTo__c 변경 시 오류 클래스 갱신
     * @param {Event} event change 이벤트 (data-key, data-field 속성 포함)
     */
    handleNewFieldChange(event) {
        const key = Number(event.target.dataset.key);
        const field = event.target.dataset.field;

        const value =
            event.target.type === 'checkbox'
                ? event.target.checked
                : event.target.value;

        this.newRecords = this.newRecords.map(rec => {
            if (rec.key !== key) return rec;

            const updated = { ...rec, [field]: value };

            // 필드별 에러 처리
            if (field === 'PeriodFrom__c') {
                updated._hasError_From   = !value;
                updated.hasErrorClassFrom = !value ? 'cell-error' : '';
            }

            if (field === 'PeriodTo__c') {
                updated._hasError_To   = !value;
                updated.hasErrorClassTo = !value ? 'cell-error' : '';
            }

            return updated;
        });

    }

    /**
     * @description 레코드 유효성 확인 — Reinsurer_lk__c / BindingFrom__c / BindingTo__c 필수 입력 여부
     * @param {Object} rec 확인할 레코드
     * @returns {boolean} 유효하면 true
     */
    isValidRecord(rec) {
        // 실제 입력 필드 기준으로 체크
        if (!rec.Reinsurer_lk__c) return false;
        if (!rec.BindingFrom__c) return false;
        if (!rec.BindingTo__c) return false;
        return true;
    }

    /**
     * @description
     * 저장 처리 — UPDATE / INSERT / DELETE 분리하여 순차적으로 Apex 호출
     * - 변경 사항이 없으면 안내 Toast 표시 후 종료
     * - UPDATE : 날짜 검증 후 기존 레코드 수정
     * - INSERT : 날짜 검증 및 필수값 검증 후 신규 레코드 등록
     * - DELETE : 선택된 레코드 삭제
     * - 저장 완료 후 상태 초기화 및 최신 데이터 재조회
     * @returns {Promise<void>}
     */
    async handleSave() {
        try {
            let isSave = false;

            const hasUpdate =
                this.dirtyCells && this.dirtyCells.size > 0 && this.updatedRecordMap &&
                Object.keys(this.updatedRecordMap).length > 0;

            const hasInsert = this.newRecords && this.newRecords.length > 0;
            const hasDelete = this.deletedRecordIds && this.deletedRecordIds.length > 0;

            if (!hasUpdate && !hasInsert && !hasDelete)  {
                this.showToast(
                    'Info',
                    'No changes to save.',
                    'info'
                );
                return;
            }

            // 기존 레코드 업데이트
            if (hasUpdate) {
                // 날짜 검증
                if (!this.validateDateRangeForUpdate()) return;

                const recordsToUpdate = Object.values(this.updatedRecordMap);

                await updateSecurityRecords({
                    records: recordsToUpdate
                });

                isSave = true;

                await this.handleSearch();
            }

            // 신규 레코드 생성
            if (hasInsert) {
                // 날짜 검증
                if (!this.validateDateRangeForInsert()) return;

                const filtered = this.newRecords.filter(r => !this.isEmptyNewRow(r));

                if (filtered.length === 0) {
                    // 업데이트/삭제도 없는 경우에만 안내 표시
                    if (!isSave) {
                        this.showToast(
                            'Info',
                            'No new data to save.',
                            'info'
                        );
                    }
                }
                else {

                    const { isValid, validRecords } = this.validateNewRows(filtered);

                    if (!isValid || validRecords.length === 0) {
                        this.showToast(
                            'Error',
                            'Invalid new rows exist.',
                            'error'
                        );
                        return;
                    }

                    await insertNewRecords({
                        records: validRecords
                    });

                    isSave = true;
                }
            }

            // 삭제 레코드 처리
            if (hasDelete) {

                await deleteRecords({
                    recordIds: this.deletedRecordIds
                });

                isSave = true;
            }

            // 저장 후 상태 초기화
            this.updatedRecordMap = {};
            this.dirtyCells.clear();
            this.newRecords = [];
            this.deletedRecordIds = [];
            // 수정 중인 UI 초기화
            this.editingCell = { rowId: null, field: null };
            this.editingRowId = null;

            if (isSave) {
                this.showToast(
                    'Success',
                    'Changes saved successfully.',
                    'success'
                );
            }

            // 최신 데이터 재조회
            await this.handleSearch();

        } catch (error) {
            console.error('Save Error:', error);
            this.showToast(
                'Error',
                'Failed to save changes.',
                'error'
            );
        }
    }

    /**
     * @description
     * 선택된 신규 행 삭제 — selectedIds 기준으로 newRecords 에서 제거 후 rowNo 재정렬
     */
    handleDeleteNewRows() {
        if (!this.selectedIds || this.selectedIds.length === 0) {
            this.showToast('Warning', 'No rows selected for delete.', 'warning');
            return;
        }

        this.newRecords = this.newRecords.filter(
            r => !this.selectedIds.includes(String(r.key))
        );

        // rowNo 다시 정렬
        let rowIndex = this.allRecords.length + 1;
        this.newRecords = this.newRecords.map(r => ({
            ...r,
            rowNo: rowIndex++
        }));

        this.selectedIds = [];
        this.resetTableCheckboxes();

        this.showToast('Success', 'Selected new rows deleted.', 'success');
    }

    /**
     * @description 삭제 버튼 비활성화 여부 반환 — 신규 행이 없으면 비활성화
     * @returns {boolean} 신규 행이 없으면 true
     */
    get isDeleteDisabled() {
        // 신규 행 없는 경우
        if (!this.newRecords || this.newRecords.length === 0) {
            return true;
        }

        // 신규 행 있는 경우, 버튼 활성화
        return false;
    }


    /**
     * @description
     * 선택된 레코드 삭제 처리 — selectedIds 기준으로 신규/기존 행 분리 삭제 후 rowNo 재정렬
     * - 기존 행은 deletedRecordIds 에 추가
     * - 데이터 삭제는 일단 사용하지 않음, 추후 추가될 수도 있어서 남겨놓은 상황
     */
    handleDelete() {
        if (!this.selectedIds || this.selectedIds.length === 0) {
            this.showToast('Warning', 'No records selected for delete.', 'warning');
            return;
        }

        // 신규 행 제거
        this.newRecords = this.newRecords.filter( rec => !this.selectedIds.includes(String(rec.key)));
        // 기존 행 제거 (UI에서)
        const remainRecords = [];
        this.deletedRecordIds = this.deletedRecordIds || [];

        this.allRecords.forEach(rec => {
            if (this.selectedIds.includes(rec.Id)) {
                this.deletedRecordIds.push(rec.Id);
            } else {
                remainRecords.push(rec);
            }
        });

        let rowIndex = 1;
        remainRecords.forEach(rec => {
            rec.rowNo = rowIndex++;
        });

        this.newRecords.forEach(rec => {
            rec.rowNo = rowIndex++;
        });

        this.allRecords = [...remainRecords];
        this.records = remainRecords.slice(0, this.visibleCount);

        this.allRecords = remainRecords;
        this.records = remainRecords.slice(0, this.visibleCount);

        this.selectedIds = [];
        this.resetTableCheckboxes();
    }

    /**
     * @description 선택된 레코드를 즉시 Apex 삭제 API 로 삭제 후 재조회
     * @returns {Promise<void>}
     */
    async deleteSelectedRecords () {
        try {
            await deleteRecords({
                recordIds: this.selectedIds
            });

            this.showToast(
                'Success',
                `${this.selectedIds.length} record(s) deleted.`,
                'success'
            );
            this.selectedIds = [];
            this.resetTableCheckboxes();

            this.handleSearch()
        } catch (error) {
            console.error('Delete Error: ', error);
            this.showToast(
                'Error',
                'Failed to delete records.',
                'error'
            );
        }
    }

    /**
     * @description 테이블 체크박스 전체 초기화 — 헤더 / 행 체크박스를 모두 unchecked 상태로 설정
     */
    resetTableCheckboxes() {
        // 헤더 체크박스
        const selectAll = this.template.querySelector(
            'input[data-role="selectAll"]'
        );
        if (selectAll) {
            selectAll.checked = false;
        }

        // Row 체크박스
        const rowCheckboxes = this.template.querySelectorAll(
            'input[data-role="rowCheckbox"]'
        );
        rowCheckboxes.forEach(cb => {
            cb.checked = false;
        });
    }

    /**
     * @description
     * 전체 선택/해제 핸들러 — 기존 행은 선택 불가, 신규 행만 전체 선택/해제
     * - selectedIds 를 신규 행 key 기준으로 갱신
     * @param {Event} event change 이벤트
     */
    handleSelectAll(event) {
        const checked = event.target.checked;

        // 기존 행은 선택 불가
        this.records = this.records.map(r => ({
            ...r,
            isSelected: false,
            disableSelect: true
        }));

        // 신규 행만 전체 선택
        this.newRecords = this.newRecords.map(r => ({
            ...r,
            isSelected: checked,
            disableSelect: false
        }));

        // 삭제 대상 갱신
        this.selectedIds = this.newRecords
            .filter(r => r.isSelected)
            .map(r => String(r.key));
    }

    /**
     * @description
     * 개별 행 체크박스 선택/해제 핸들러 — selectedIds 업데이트 및 전체 선택 체크박스 상태 동기화
     * @param {Event} event change 이벤트 (data-id 속성 포함)
     */
    handleRowSelect(event) {
        if (event.target.disabled) return;

        const recordId = String(event.target.dataset.id);
        const isChecked = event.target.checked;

        // 선택 배열 업데이트
        if (isChecked) {
            if (!this.selectedIds.includes(recordId)) {
                this.selectedIds = [...this.selectedIds, recordId];
            }
        } else {
            this.selectedIds = this.selectedIds.filter(id => id !== recordId);
        }

        // 레코드 상태 반영
        this.newRecords = this.newRecords.map(r =>
            String(r.key) === recordId ? { ...r, isSelected: isChecked } : r
        );

        this.records = this.records.map(r =>
            String(r.key) === recordId ? { ...r, isSelected: isChecked } : r
        );

        // 전체 선택 체크박스 반응형 업데이트
        const allSelectable = [...this.records, ...this.newRecords].filter(
            r => !r.disableSelect
        );

        const allChecked =
            allSelectable.length > 0 &&
            allSelectable.every(r => r.isSelected);

        const selectAll = this.template.querySelector(
            'input[data-role="selectAll"]'
        );

        if (selectAll) selectAll.checked = allChecked;
    }

    /**
     * @description View All 핸들러 — visibleCount 를 pageSize 만큼 증가시켜 더 많은 레코드 표시
     */
    handleViewAll() {
        this.visibleCount = Math.min(
            this.visibleCount + this.pageSize,
            this.allRecords.length
        );

        this.records = this.allRecords.slice(0, this.visibleCount);
    }

    /**
     * @description
     * 화면에 표시할 레코드 데이터를 구성하여 반환
     * - 편집 중인 셀 / 수정된 셀 상태에 따라 CSS 클래스 설정
     * - BindingFrom / BindingTo 날짜를 사용자 로케일 형식으로 변환
     * - Country API 값을 Label 로 변환
     * @returns {Array} 화면 표시용 레코드 목록
     */
    get displayRecords() {
        return this.records.map(rec => {
            const isRowEditing = this.editingRowId === rec.Id;

            const hasDirty = Array.from(this.dirtyCells || [])
                .some(key => key.startsWith(`${rec.Id}_`));

            const cellFlags = EDITABLE_FIELDS.reduce((acc, field) => {
                const cellKey = `${rec.Id}_${field}`;

                const isEditingCell =
                    isRowEditing && this.editingCell?.field === field;

                const isDirty =
                    this.dirtyCells?.has(cellKey);
                acc[`${field}CellClass`] =
                    isEditingCell
                        ? 'cell-editing'
                        : isDirty
                            ? 'cell-edited'
                            : '';


                return acc;
            }, {});

            return {
                ...rec,
                isEditing: isRowEditing,
                hasDirty,
                disableSelect: !rec.isNew,
                hasErrorClass: rec._hasError ? 'cell-error' : '',

                BindingFromDisplay: this.formatDateByUserLocale(rec.BindingFrom__c),
                BindingToDisplay: this.formatDateByUserLocale(rec.BindingTo__c),
                CountryLabel: this.countryLabelMap[rec.Country__c] || rec.Country__c,
                ...cellFlags
            };
        });
    }

    /**
     * @description 행 편집 모드 진입 핸들러 — 클릭한 행의 Id 를 editingRowId 로 설정
     * @param {Event} event 클릭 이벤트 (data-id 속성 포함)
     */
    handleRowEdit(event) {
        this.editingRowId = event.currentTarget.dataset.id;
    }

    /**
     * @description 편집 버튼 클릭 핸들러 — 해당 행을 편집 모드로 전환
     * @param {Event} event 클릭 이벤트 (data-row-id 속성 포함)
     */
    handleEditClick(event) {
        const rowId = event.currentTarget.dataset.rowId;
        this.editingRowId = rowId;
    }

    /**
     * @description 날짜 값을 사용자 로케일 형식(년/월/일)으로 변환
     * @param {string} dateValue 날짜 문자열
     * @returns {string} 로케일 형식으로 변환된 날짜 문자열
     */
    formatDateByUserLocale(dateValue) {
        if (!dateValue) return '';
        const date = new Date(dateValue);

        return new Intl.DateTimeFormat(LOCALE, {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }).format(date);
    }

    /**
     * @description
     * 레코드 상세 페이지 이동 핸들러 — NavigationMixin 으로 새 탭에서 레코드 상세 페이지 열기
     * @param {Event} event 클릭 이벤트 (data-record-id, data-object-api-name 속성 포함)
     */
    handleNavigateToRecord(event) {
        event.preventDefault();
        event.stopPropagation();

        const recordId = event.currentTarget.dataset.recordId;
        const objectApiName = event.currentTarget.dataset.objectApiName;

        if (!recordId || !objectApiName) return;

        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName,
                actionName: 'view'
            }
        }).then(url => {
            // 새 탭으로 열기
            window.open(url, '_blank');
        });
    }

    /**
     * @description 첨부 파일 목록 페이지를 새 탭으로 열기
     * @param {Event} event 클릭 이벤트 (data-id 속성 포함)
     */
    handleOpenFiles(event) {
        const recordId = event.currentTarget.dataset.id;
        if (!recordId) return;

        const url = `/lightning/r/ACC_AdditionalInfo__c/${recordId}/related/AttachedContentDocuments/view`;

        window.open(url, '_blank');
    }

    /**
     * @description View All 버튼 표시 여부 반환 — 전체 레코드 수가 현재 표시 수보다 많을 때 true
     * @returns {boolean}
     */
    get showViewAll() {
        return (
            this.records &&
            this.records.length > 0 &&
            this.allRecords &&
            this.allRecords.length > this.records.length
        );
    }

    /**
     * @description Toast 메시지 표시
     * @param {string} title Toast 제목
     * @param {string} message Toast 메시지
     * @param {string} variant Toast 유형 ('success' | 'error' | 'warning' | 'info')
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}