/**********************************************************************************
 * @filename      : oppMarketLineCell.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-07 (수)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-07      i2max      Create
 **********************************************************************************/
import {LightningElement, api, wire} from 'lwc';
import {getFieldValue, getRecord} from "lightning/uiRecordApi";
import {toast, getCurrencyScale, scaleToStep} from 'c/com';

import OPP_MSG_RE_KYC_INCOMPLETE from '@salesforce/label/c.OPP_MSG_REINSURER_KYC_INCOMPLETE'
import OPP_MSG_SELECT_MARKET_TYPE_FOR_SECURITY from '@salesforce/label/c.OPP_MSG_SELECT_MARKET_TYPE_FOR_SECURITY'
import OPP_MSG_SELECT_MGA_FOR_SECURITY from '@salesforce/label/c.OPP_MSG_SELECT_MGA_FOR_SECURITY'
import OPP_MSG_MARKET_TYPE_FACILITY_REQUIRED from '@salesforce/label/c.OPP_MSG_MARKET_TYPE_FACILITY_REQUIRED'
import OPP_MSG_SELECT_FACILITY_FOR_REINSURER from '@salesforce/label/c.OPP_MSG_SELECT_FACILITY_FOR_REINSURER'
import OPP_MSG_PANEL_SAVE_REQUIRED from '@salesforce/label/c.OPP_MSG_PANEL_SAVE_REQUIRED'
import OPP_LBL_DELETE_LAYER_ITEM from '@salesforce/label/c.OPP_LBL_DELETE_LAYER_ITEM'
import OPP_LBL_ADD_PANEL_ITEM from '@salesforce/label/c.OPP_LBL_ADD_PANEL_ITEM'
import OPP_LBL_DELETE_PANEL_ITEM from '@salesforce/label/c.OPP_LBL_DELETE_PANEL_ITEM'
import COM_MSG_ENTER_NUMBER from '@salesforce/label/c.COM_MSG_ENTER_NUMBER'

const KYC_FIELD_KR = 'Account.KycCompletedKr_is__c';
const KYC_FIELD_RE = 'Account.KycCompletedRe_is__c';
const KYC_FIELD_VN = 'Account.KycCompletedVn_is__c';
const ACTIVE_FIELD_KR = 'Account.ActiveKr_is__c';
const ACTIVE_FIELD_RE = 'Account.ActiveRe_is__c';
const ACTIVE_FIELD_VN = 'Account.ActiveVn_is__c';
const KYC_FIELDS = [KYC_FIELD_KR, KYC_FIELD_RE, KYC_FIELD_VN, ACTIVE_FIELD_KR, ACTIVE_FIELD_RE, ACTIVE_FIELD_VN];

let _init = false;
export default class oppMarketLineCell extends LightningElement {

    labels = {
        OPP_MSG_RE_KYC_INCOMPLETE,
        OPP_MSG_SELECT_MARKET_TYPE_FOR_SECURITY,
        OPP_MSG_SELECT_MGA_FOR_SECURITY,
        OPP_MSG_MARKET_TYPE_FACILITY_REQUIRED,
        OPP_MSG_SELECT_FACILITY_FOR_REINSURER,
        OPP_MSG_PANEL_SAVE_REQUIRED,
        OPP_LBL_DELETE_LAYER_ITEM,
        OPP_LBL_ADD_PANEL_ITEM,
        OPP_LBL_DELETE_PANEL_ITEM,
        COM_MSG_ENTER_NUMBER
    }

    // 📍 1. API 속성 (외부에서 설정 가능)
    @api rowId;
    @api layerId;
    @api panelId;
    @api isReadOnly = false;
    @api isCiCase = false;
    @api isEdited = false; // [추가] Dirty Check UI 표시용
    _bizRegion = '';
    @api
    get bizRegion() { return this._bizRegion; }
    set bizRegion(v) {
        // const prev = this._bizRegion;
        this._bizRegion = v || '';
        if (this._wiredReinsurerData) {
            this._evaluateKyc(this._wiredReinsurerData);
        }
    }

    @api
    get row() {
        return this._row;
    }
    set row(v) {
        this._row = v || {};
        this._syncValue();
    }

    @api
    get col() {
        return this._col;
    }
    set col(v) {
        this._col = v || {};
        this._syncValue();
    }

    @api
    get errorMessage() {
        return this._errorMessage;
    }
    set errorMessage(v) {
        this._errorMessage = v;
        this.reportValidity(); // 에러 메시지 변경 시 즉시 반영
    }

    @api reportValidity() {
        const targets = this.template.querySelectorAll(
            'lightning-input, lightning-combobox, lightning-textarea, lightning-dual-listbox, c-com-lookup, c-com-picklist, lightning-input-rich-text'
        );

        let ok = true;
        targets.forEach((el) => {
            // 커스텀 에러 메시지 설정
            if (typeof el.setCustomValidity === 'function') {
                el.setCustomValidity(this._errorMessage || '');
            }

            // 유효성 검사 및 UI 표시
            if (typeof el.reportValidity === 'function') {
                ok = el.reportValidity() && ok;
            }
        });

        return ok;
    }

    @api
    validate() {
        // 읽기 전용이거나 조회 모드면 검사 패스
        if (this.isReadOnly || this.isView) return true;

        // 팝업 Lookup 필수값 체크
        if (this.isPopupLookup && this.isRequired && !this.lookupValue) {
            this._errorMessage = '필수 항목입니다.';
            return false;
        }

        // 내부 reportValidity 호출 (required 속성이 있는 input들이 빨간색으로 표시됨)
        return this.reportValidity();
    }

    @api selectedCurrency = 'USD';
    @api isBlank = false;

    // 📍 2. 추적 속성 (반응형)

    // 📍 3. Private 속성
    _row;
    _col;
    _value;
    _errorMessage;

    _marketLookupSignature;
    _isKycIncomplete = false; // 내부 상태 저장용

    // 📍 4. Getter/Setter
    // td 클래스 계산
    get tdClass() {
        const classes = [];

        // 에러가 있으면 에러 클래스
        if (this.errorMessage) classes.push('cell-error');

        // 수정되었으면 수정 클래스
        if (this.isEdited) classes.push('slds-is-edited');

        // CO 또는 Brkg Adj 행이면 연한 회색 배경
        if (this.row?.CO_is__c || this.row?.BrkgAdj_is__c) {
            classes.push('slds-theme_gray'); // slds-theme_shade SLDS 표준 회색 배경 또는 'slds-theme_gray'
        }

        return classes.join(' ');
    }

    get isView() {
        return this._col?.mode === 'view';
    }

    // 셀 편집 가능 여부
    get isCellDisabled() {
        // 1. 전체 화면이 ReadOnly이면 무조건 잠금
        if (this.isReadOnly) return true;
        // 3. Brkg Adj MarketLine 처리: Remarks__c만 수정 가능
        if (this.row?.BrkgAdj_is__c) {
            return this.col.key !== 'Remarks__c';
        }

        // QS Type일 때 LOL__c는 자동 산출이므로 수정 불가
        if (this.row?.Type__c === 'QS' && this.col.key === 'LOL__c') {
            return true;
        }
        // 4. CO MarketLine 처리
        if (this.row?.CO_is__c && !this.isCiCase) {
            const editableFields = new Set([
                'Type__c',
                'Remarks__c',
                'LKProducingSharingPct__c',
                'CoBroker_lk__c',
                'LKPlacingSharingPct__c',
                'ProducingTPPBrkg__c',
                'PlacingTPPBrkge__c',
                'RIContact_lk__c',
                'CoBrokerContact_lk__c',
                'Others__c'
            ]);
            return !editableFields.has(this.col.key);
        }
        // 2. 컬럼 자체가 View 모드이면 잠금
        if (this.isView) return true;

        // MarketType 미선택 시 Market 관련 Lookup 비활성화
        const marketFields = new Set(['Facility_lk__c', 'MGAName_lk__c', 'Reinsurer_lk__c', 'Security_lk__c']);
        return marketFields.has(this.col.key) && !this.row?.MarketType__c;
    }

    get isText() {
        return this._col?.type === 'text';
    }
    get isNum() {
        return (this._col?.type === 'num' || this._col?.type === 'percent');
    }
    get isDate() {
        return this._col?.type === 'd';
    }
    get isDatetime() {
        return this._col?.type === 'dt';
    }
    get isPicklist() {
        return this._col?.type === 'picklist' || this._col?.type === 'multipicklist';
    }
    get isCheckbox() {
        return this._col?.type === 'checkbox';
    }
    get isLookup() {
        // 팝업 Lookup 조건(isPopupLookup)을 만족하면 일반 Lookup은 숨김
        if (this.isPopupLookup) return false;
        return this._col?.type === 'lookup';
    }
    get isTextArea() {
        return this._col?.type === 'textarea';
    }
    get isRichText() {
        return this._col?.type === 'richtext';
    }
    get isPopupType() {
        return this.isTextArea || this.isRichText;
    }
    get textAreaStyle() {
        // 아이콘 공간 확보
        let css = 'padding-right: 20px;';
        // 컬럼에 설정된 너비(width)가 있다면 max-width로 제한하여 테이블 셀이 늘어나는 것을 방지
        if (this.col && this.col.width) {
            css += ` max-width: ${this.col.width}px;`;
        }
        return css;
    }
    get label() {
        return this._col?.label;
    }
    get isLayerAction() {
        return this._col?.key === 'LayerAction';
    }
    get isMarketAction() {
        return this._col?.key === 'MLAction';
    }
    get isSubjAction() {
        if (this.row?.BrkgAdj_is__c) {
            return false;
        }
        return this._col?.key === 'subAction';
    }
    get isSubjActionDisabled() {
        // 1. Brkg Adj 행이면 무조건 비활성화 (삭제/추가 불가)
        if (this.row?.BrkgAdj_is__c) {
            return true;
        }
        // 2. 그 외: 버튼은 항상 활성화하되, 클릭 시 유효성 체크 후 안내 메시지 출력
        return false;
    }
    get isPanelSaved() {
        const pid = String(this.panelId || '');
        return pid.length > 0 
            && !pid.includes('@') 
            && !pid.startsWith('tmp_')
            && this.panelId !== this.layerId; // Layer ID와 Panel ID가 같으면 빈 Layer 행(가짜 패널)이므로 저장 불가
    }
    get isRequired() {
        return this._col?.required;
    }
    get isReinsurer() {
        return this._col?.key === 'Reinsurer_lk__c';
    }
    get isActionDisabled() {
        if(this.row?.BrkgAdj_is__c) {
            return true;
        }
        return this.isView || this.isReadOnly;
    }
    get isAddActionDisabled() {
        return this.isView || this.isReadOnly || this.isCellDisabled;
    }

    get inputPlaceholder() {
        if (this.isView || this.isCellDisabled) return '';
        if (this.isNum) return this.labels.COM_MSG_ENTER_NUMBER;
        return '';
    }

    get stepValue() {
        if (!this.isNum) return 'any';

        // percent는 항상 소수점 2자리
        if (this._col?.type === 'percent' && this._col?.scale > 2) return scaleToStep(this._col?.scale);
        if (this._col?.type === 'percent') return scaleToStep(2);

        // 통화 정책 우선 적용, 통화 정책 없으면 기존 col.scale 사용
        const scale = getCurrencyScale(this.selectedCurrency, Number(this._col?.scale));
        if (isNaN(scale)) return 'any';

        return scaleToStep(scale);
    }

    get _numScale() {
        if (this._col?.type === 'percent') {
            return (this._col?.scale > 2) ? Number(this._col.scale) : 2;
        }
        const s = getCurrencyScale(this.selectedCurrency, Number(this._col?.scale));
        return isNaN(s) ? 0 : s;
    }

    get maxValue() {
        const precision = Number(this._col?.precision);
        if (!this.isNum || !precision) return undefined;
        // 정수부만 15자리로 제한
        const intDigits = Math.min(precision - this._numScale, 15);
        if (intDigits <= 0) return undefined;
        return Math.pow(10, intDigits) - 1;
    }

    get rangeOverflowMessage() {
        const precision = Number(this._col?.precision) || 0;
        const scale = this._numScale;
        // const intDigits = precision - scale;
        const intDigits = Math.min(precision - scale, 15);
        return scale > 0
            ? `정수부 최대 ${intDigits}자리, 소수점 ${scale}자리까지 입력 가능합니다.`
            : `최대 ${intDigits}자리까지 입력 가능합니다.`;
    }

    get value() {
        return this._value;
    }

    get displayValue() {

        if (this._col?.type === 'multipicklist') return (this._value || []).join(', ');
        // 팝업 Lookup(Security 등)인 경우 ID 대신 이름을 표시
        if (this.isPopupLookup) {
            // 1. __r.Name 확인 (SOQL 조회 결과)
            const relationName = this.col.key.replace('__c', '__r');
            if (this.row?.[relationName]?.Name) {
                return this.row[relationName].Name;
            }
        }

        return this._value ?? '';
    }

    get isZeroDisplayText() {
        if (this.value !== 0 && this.value !== '0') return false;
        // 기존 컬럼 레벨 zeroDisplayText (OPDs 등)
        return !!this.col?.zeroDisplayText;
    }

    get zeroDisplayText() {
        return this.col?.zeroDisplayText;
    }

    get isMarketNameCell() {
        return this.col?.key === 'Facility_lk__c';
    }

    get marketLookup() {
        // Manage 컴포넌트에서 _marketLookup을 Map 형태({ key: config })로 관리하므로
        // 현재 컬럼 키에 맞는 설정을 가져와야 함
        return this.row?._marketLookup?.[this.col.key] || null;
    }
    get lookupDisabled() {

        // view 모드이거나 Cell이 비활성화 상태이면 Lookup도 잠금
        if (this.isView || this.isCellDisabled) return true;

        // Security: MGA가 아니면 선택 불가 (Disabled)
        if (this.col.key === 'Security_lk__c' && this.row?.MarketType__c !== 'MGA') {
            return true;
        }

        // Market Rule이 적용된 컬럼인 경우 (Facility, Reinsurer 등) Rule의 disabled 속성 우선
        if (this.marketLookup) {
            return !!this.marketLookup.disabled;
        }

        // Contact 종속 Lookup: parentField가 있는데 부모 값이 없으면 비활성=> RIContact_lk__c, CoBrokerContact_lk__c
        if (this.col.lookupObject === 'Contact' && this.col.parentField) {
            return !this.row?.[this.col.parentField];
        }

        return false; // 기본값
    }

    get lookupConfig() {
        return this.marketLookup
            ? this._buildMarketLookupConfig()
            : this._buildGeneralLookupConfig();
    }

    // lookup에 바인딩할 값: MarketNameCell은 activeField 기준
    get lookupValue() {
        if (this.isMarketNameCell && this.marketLookup?.activeField) {
            return this.row?.[this.marketLookup.activeField] ?? null;
        }
        return this.row?.[this.col.key] ?? null;
    }

    // Reinsurer일 때만 wire 돌리기
    get lookupValueForWire() {
        return this.isReinsurer && this.lookupValue ? this.lookupValue : undefined;
    }

    get isKycIncomplete() {
        return this.lookupValue && this._isKycIncomplete;
    }

    get isPopupLookup() {
        // 1. Security: MarketType이 'MGA'일 때
        if (this._col?.key === 'Security_lk__c' && this.row?.MarketType__c === 'MGA') {
            return !this.isReadOnly;
        }
        // 2. Reinsurer: MarketType이 'Facility'일 때
        if (this._col?.key === 'Reinsurer_lk__c' && this.row?.MarketType__c === 'Facility') {
            return !this.isReadOnly;
        }
        return false;
    }
    get selectedRecordUrl() {
        if (this._value && this.isPopupLookup) {
            return `/lightning/r/${this._value}/view`;
        }
        return '';
    }
    get filteredOptions() {
        if (!this.col.options) return [];

        // Type__c 필드인 경우 필터링
        if (this.col.key === 'Type__c') {
            if (this.row?.BrkgAdj_is__c) {
                return this.col.options; // 'Brkg Adj' 포함된 전체 옵션
            }
            return this.col.options.filter(opt => opt.value !== 'Brkg Adj');
        }

        return this.col.options;
    }

    // 📍 5. Wire 메서드
    _wiredReinsurerData = null;

    @wire(getRecord, { recordId: '$lookupValueForWire', fields: KYC_FIELDS })
    wiredReinsurer({ error, data }) {
        if (data) {
            this._wiredReinsurerData = data;
            this._evaluateKyc(data);
        } else if (error) {
            this._wiredReinsurerData = null;
            this._emitKycStatus(false);
        } else {
            if (!this.lookupValueForWire) {
                this._wiredReinsurerData = null;
                this._emitKycStatus(false);
            }
        }
    }

    _evaluateKyc(data) {
        const regionMap = {
            'LK_KR': { active: ACTIVE_FIELD_KR, kyc: KYC_FIELD_KR },
            'LK_Re': { active: ACTIVE_FIELD_RE, kyc: KYC_FIELD_RE },
            'LK_VN': { active: ACTIVE_FIELD_VN, kyc: KYC_FIELD_VN }
        };
        const fields = regionMap[this._bizRegion];
        const isKycIncomplete = fields
            ? (getFieldValue(data, fields.active) === true && getFieldValue(data, fields.kyc) !== true)
            : false;
        this._emitKycStatus(isKycIncomplete);
    }

    // 📍 6. 이벤트 핸들러
    handleAction(event) {
        // data-action 우선순위 변경: input 계열 컴포넌트에서 detail.value에 값이 들어오는 경우(RichText 등) action으로 오인되는 문제 방지
        const action = event.currentTarget?.dataset?.action || event.detail?.value;

        // 팝업 내부 클릭 시 부모(open)로 이벤트 전파 방지
        if (['close', 'apply', 'input'].includes(action) || !action) {
            event.stopPropagation();
        }

        switch (action) {
            case 'addPanelRow':
                this.dispatchEvent(
                    new CustomEvent('addpanel', {
                        detail: { rowNo: this.row?._rowNo, layerId: this.layerId }
                    })
                );
                break;

            case 'delPanelRow':
                this.dispatchEvent(
                    new CustomEvent('delpanel', {
                        detail: { rowNo: this.row?._rowNo, panelId: this.panelId, layerId: this.layerId }
                    })
                );
                break;

            case 'delLayerRow':
                this.dispatchEvent(new CustomEvent('dellayer', {
                    detail: { layerId: this.layerId },
                    bubbles: true,
                    composed: true
                }));
                break;

            case 'openTextEditor': {
                console.log('[Cell > openTextEditor] 🦋')
                if(this.isCellDisabled && this.col.key!=='Remarks__c') return;
                this.dispatchEvent(new CustomEvent('opentexteditor', {
                    detail: {
                        rowId: this.rowId,
                        key: this.col.key,
                        value: this.value,
                        mode: this.isRichText ? 'rich' : 'text',
                        title: this.label
                    },
                    bubbles: true,
                    composed: true
                }));
                break;
            }
            case 'openMarketSearch':
                // 1. Security 처리
                if (this._col?.key === 'Security_lk__c') {
                    const parentId = this._row?.Reinsurer_lk__c;//this._row?.MGAName_lk__c;
                    if (this._row?.MarketType__c !=='MGA') {//Security를 조회하려면 먼저 Market Type을 선택해야 합니다.
                        toast(this, this.labels.OPP_MSG_SELECT_MARKET_TYPE_FOR_SECURITY, 'warning');
                        return;
                    }
                    if (!parentId) {//Security를 조회하려면 먼저 MGA Name을 선택해야 합니다.
                        toast(this, this.labels.OPP_MSG_SELECT_MGA_FOR_SECURITY, 'warning');
                        return;
                    }
                    this.dispatchEvent(new CustomEvent('openmarketsearch', {
                        detail: { rowId: this.rowId, key: this._col.key, type: 'Security', parentId: parentId },
                        bubbles: true, composed: true
                    }));
                }
                // 2. Reinsurer 처리
                else if (this._col?.key === 'Reinsurer_lk__c') {
                    const parentId = this._row?.Facility_lk__c;
                    if (this._row?.MarketType__c !=='Facility') {//Reinsurer를 조회하려면 먼저 Market Type을 "Facility"으로 선택해야 합니다.
                        toast(this,this.labels.OPP_MSG_MARKET_TYPE_FACILITY_REQUIRED, 'warning');
                        return;
                    }
                    if (!parentId) {//'Reinsurer를 조회하려면 먼저 Facility Name을 선택해야 합니다.'
                        toast(this, this.labels.OPP_MSG_SELECT_FACILITY_FOR_REINSURER, 'warning');
                        return;
                    }
                    this.dispatchEvent(new CustomEvent('openmarketsearch', {
                        detail: { rowId: this.rowId, key: this._col.key, type: 'Reinsurer', parentId: parentId  },
                        bubbles: true, composed: true
                    }));
                }
                break;

            case 'openSubjectivity': {
                // console.log('☠ ☠☠☠☠☠☠☠☠☠', this.isPanelSaved);
                if (!this.isPanelSaved) {//OPP_MSG_PANEL_SAVE_REQUIRED: Subjectivity를 관리하려면 먼저 Panel이 저장되어야 합니다.
                    toast(this, this.labels.OPP_MSG_PANEL_SAVE_REQUIRED, 'warning', 'dismissible');
                    return;
                }
                if (this._row?.Reinsurer_lk__c === null) {//Reinsurer 선택 후 등록 가능
                    toast(this, 'Reinsurer를 선택해주세요.', 'warning');
                    return;
                }
                this.dispatchEvent(new CustomEvent('opensubjectivity', {
                    detail: {panelId: this.panelId, reinsurerId: this.row?.Reinsurer_lk__c},
                    bubbles: true,
                    composed: true
                }));
                break;
            }
            default:
                if (action) toast(this, `${action} 기능은 정의되어 있지 않습니다.`, 'info');
        }
    }

    // 통합된 값 변경 핸들러
    handleChange(event) {
        let val;
        let key = this.col.key;

        // 1. Picklist
        if (this.isPicklist) {
            val = event.detail.value ?? event.detail.values;
        }
        // 2. Lookup
        else if (this.isLookup) {
            val = event.detail?.value ?? null;
            // console.log('_________________________________________________________________________________________val=['+ val +']')
            // MarketNameCell인 경우 activeField에 값 저장
            if (this.isMarketNameCell && this.marketLookup?.activeField) {
                key = this.marketLookup.activeField;
            }
        }
        // 3. 일반 Input (Text, Num, Date, Checkbox)
        else {
            if (this.isCheckbox) {
                val = !!event.target.checked;
            } else {
                const inputVal = event.target?.value ?? '';
                if (this.isNum) {
                    if (!this._validateNumByString(event.target, String(inputVal))) {
                        return;
                    }
                    val = inputVal === '' ? null : Number(inputVal);
                } else {
                    val = inputVal;
                }
            }
        }

        this._dispatchValueChange(key, val);

        // 에러 초기화
        if (this._errorMessage) {
            this._errorMessage = null;
            this.reportValidity();
        }
    }

    // 📍 7. Private 메서드
    _validateNumByString(inputEl, raw) {
        if (!inputEl) return true;
        if (raw === '' || raw == null) {
            if (typeof inputEl.setCustomValidity === 'function') inputEl.setCustomValidity('');
            return true;
        }
        const precision = Number(this._col?.precision);
        if (!precision) return true;

        const scale = this._numScale;
        const intDigitsMax = precision - scale;

        // 부호 제거 후 정수부/소수부 분리
        const m = raw.replace(/^-/, '').match(/^(\d*)(?:\.(\d*))?$/);
        if (!m) {
            inputEl.setCustomValidity?.('숫자 형식이 올바르지 않습니다.');
            inputEl.reportValidity?.();
            return false;
        }
        const intPart = (m[1] || '').replace(/^0+/, '') || '0';
        const decPart = m[2] || '';

        if (intPart !== '0' && intPart.length > intDigitsMax) {
            inputEl.setCustomValidity?.(this.rangeOverflowMessage);
            inputEl.reportValidity?.();
            return false;
        }
        if (scale > 0 && decPart.length > scale) {
            inputEl.setCustomValidity?.(this.rangeOverflowMessage);
            inputEl.reportValidity?.();
            return false;
        }
        inputEl.setCustomValidity?.('');
        inputEl.reportValidity?.();
        return true;
    }

    _emitKycStatus(isIncomplete) {
        // 상태가 변했을 때만 이벤트 발송
        if (this._isKycIncomplete === isIncomplete) return;

        this._isKycIncomplete = isIncomplete;

        this.dispatchEvent(new CustomEvent('kycstatuschange', {
            detail: {
                rowId: this.rowId,
                key: this.col.key,
                isKycIncomplete: isIncomplete
            },
            bubbles: true,
            composed: true
        }));
    }

    _syncValue() {
        if (!this._col || !this._row) return;

        const key = this._col?.key;
        if (!key) {
            this._value = undefined;
            return;
        }

        if (this._row.cells) {
            const cell = this._row.cells.find((c) => c.key === key);
            this._value = cell ? cell.value : undefined;
        } else {
            this._value = this._row[key];
        }
    }

    _dispatchValueChange(key, value) {
        // 현재 컬럼의 값인 경우 내부 변수 업데이트 (화면 표시용)
        if (key === this.col.key) {
            this._value = value;
        }

        this.dispatchEvent(
            new CustomEvent('valuechange', {
                detail: { rowId: this.rowId, layerId: this.layerId, panelId: this.panelId, key: key, value: value },
                bubbles: true,
                composed: true
            })
        );
    }

    async _resetLookupUiIfNeeded() {
        // Market Rule이 있는 경우에만 UI 리셋 체크
        if (!this.marketLookup) return;

        const m = this.marketLookup;
        const nextSignature = JSON.stringify({
            disabled: !m || !!m.disabled,
            lookupObject: m?.lookupObject || null,
            activeField: m?.activeField || null,
            filterField: m?.filterField || null,
            filterValue: m?.filterValue || null
        });

        if (this._marketLookupSignature === nextSignature) return;
        this._marketLookupSignature = nextSignature;

        await Promise.resolve();

        const lookup = this.template.querySelector('c-com-lookup');
        if (lookup && typeof lookup.resetLookup === 'function') {
            await lookup.resetLookup(false);
        }
    }

    _buildFilter(field, value, groupKey = 'base') {
        let type = 'STRING';
        if (typeof value === 'boolean') {
            type = 'BOOLEAN';
        } else if (typeof value === 'string') {
            const lower = value.toLowerCase();
            if (lower === 'true' || lower === 'false') {
                value = lower === 'true';
                type = 'BOOLEAN';
            }
        }
        return { field, op: 'EQ', value, type, groupKey };
    }

    _buildMarketLookupConfig() {
        const m = this.marketLookup;
        if (m.disabled) {
            return { objectApiName: null, labelField: 'Name', filters: [] };
        }

        const filters = [];
        if (m.filterField && m.filterValue !== null && m.filterValue !== undefined && m.filterValue !== '') {
            filters.push(this._buildFilter(m.filterField, m.filterValue));
        }
        if (this._col?.key === 'Reinsurer_lk__c' && this._bizRegion) {
            const regionActiveMap = {
                'LK_KR': 'ActiveKr_is__c',
                'LK_Re': 'ActiveRe_is__c',
                'LK_VN': 'ActiveVn_is__c'
            };
            const activeField = regionActiveMap[this._bizRegion];
            if (activeField) {
                filters.push(this._buildFilter(activeField, true));
            }
        }
        return {
            objectApiName: m.lookupObject || this.col.lookupObject,
            labelField: 'Name',
            filters
        };
    }

    _buildGeneralLookupConfig() {
        const filters = [];

        if (this.col?.filterField != null && this.col?.filterValue != null) {
            filters.push(this._buildFilter(this.col.filterField, this.col.filterValue));
        }
        if (this.col.lookupObject === 'Contact' && this.col.parentField) {
            const parentId = this.row?.[this.col.parentField];
            if (parentId) {
                filters.push(this._buildFilter('AccountId', parentId));
            }
        }
        if (this.col.key === 'Security_lk__c' && this.row?.MarketType__c === 'MGA' && this.row?.Reinsurer_lk__c) {//&& this.row?.MGAName_lk__c
            filters.push(this._buildFilter('ParentId', this.row.Reinsurer_lk__c));//filters.push(this._buildFilter('ParentId', this.row.MGAName_lk__c));
        }

        return {
            objectApiName: this.col.lookupObject,
            labelField: this.col.lookupLabelField || 'Name',
            filters,
            iconName: (this.col.lookupObject === 'Contact') ? 'standard:contact' : 'standard:account'
        };
    }

    // 📍 8. 라이프사이클 메서드
    renderedCallback() {
        void this._resetLookupUiIfNeeded();
        // 렌더링 후 에러 상태 반영
        if (this._errorMessage) {
            this.reportValidity();
        }
    }

    connectedCallback() {
        // input number right align
        if (_init) return;

        const style = document.createElement('style');
        style.innerText = `.cus-lk-input-right input { text-align: right !important; } `;
        document.body.appendChild(style);

        _init = true;
    }

}