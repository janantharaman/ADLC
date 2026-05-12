/**********************************************************************************
 * @filename      : comLookup.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-11-04 (화)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2025-11-04      i2max      Create
 **********************************************************************************/
import { LightningElement, api, track } from 'lwc';
import search from '@salesforce/apex/COM_Lookup_Ctrl.search';
import getOptionsByIds from '@salesforce/apex/COM_Lookup_Ctrl.getOptionsByIds';
import NO_RESULTS_MSG from '@salesforce/label/c.COM_MSG_NORECORDS';
import COM_LBL_SEARCH_RECORDS from '@salesforce/label/c.COM_LBL_SEARCH_RECORDS';
import COM_MSG_COMPLETE_FIELD from '@salesforce/label/c.COM_MSG_COMPLETE_FIELD';
const DEFAULT_ICON = 'standard:search';
const DEFAULT_SUB_LABEL_FIELDS = {
    Account: 'Country__c'
};

export default class ComLookup extends LightningElement {
    labels = {
        NO_RESULTS_MSG,
        COM_LBL_SEARCH_RECORDS,
        COM_MSG_COMPLETE_FIELD
    }
    // API 속성
    @api disabled = false;
    @api required = false;
    @api fieldName;
    @api parentId;
    @api marketType;
    @api config;
    @api minKeywordLen = 2;
    @api pageSize = 50;
    @api orderByField;
    @api orderDir = 'ASC';
    @api recordTypeDeveloperNames = [];
    @api iconName;
    @api isFixed = false;

    // 추적 속성 (반응형)
    @track menuPos = 'bottom';
    @track errorMessage = '';
    @track dropdownStyle = '';

    // Private 속성
    _focusNext = false;
    _multi = false;
    _value;
    _placeholder = this.labels.COM_LBL_SEARCH_RECORDS;
    _values = [];
    keyword = '';
    options = [];
    selected = [];
    isOpen = false;
    hasMore = false;
    afterLabel;
    afterId;
    _Init = false;
    hasSearched = false;

    // Getter/Setter
    @api
    get placeholder() {
        return this.disabled ? '' : this._placeholder;
    }
    set placeholder(v) {
        this._placeholder = v;
    }

    @api get multi() { return this._multi; }
    set multi(v) { this._multi = !!v; }

    @api get value() { return this._value; }
    set value(v) {
        this._value = v || null;
        if (!this._multi) this._hydrate();
    }

    @api get values() { return this._values; }
    set values(v) {
        this._values = Array.isArray(v) ? v : [];
        if (this._multi) this._hydrate();
    }

    get hasSingleSelection() {
        return !this._multi && this.selected && this.selected.length === 1;
    }

    get selectedLabel() {
        return this.hasSingleSelection ? this.selected[0].label : '';
    }

    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ${this.isOpen ? 'slds-is-open' : ''}`;
    }

    get dropdownClass() {
        return `slds-dropdown slds-dropdown_length-with-icon-7  dropdown-base ${this.menuPos}`;//slds-dropdown_fluid
    }

    get ctx() {
        return { fieldName: this.fieldName, parentId: this.parentId, marketType: this.marketType, keyword: this.keyword };
    }

    get hasSelection() {
        return (!!this._value || this._values.length > 0);
    }

    get getSelectIconName() {
        return (this.hasSelection && this.iconName) ? this.iconName : DEFAULT_ICON;
    }

    get showNoResults() {
        return this.isOpen && this.hasSearched && (!this.options || this.options.length === 0);
    }

    get noResultsMsg() {
        return NO_RESULTS_MSG;
    }

    /**
     * 선택된 레코드의 상세 페이지 URL을 반환
     * @returns {string}
     */
    get selectedRecordUrl() {
        if (this._value) {
            // this.objectApiName이 있다면 사용, 없다면 상황에 맞게 수정
            return `/lightning/r/${this._value}/view`;
        }
        return '#';
    }


    // Public API 메서드 추가 2025-12-17 by leejh@i2max.co.kr
    @api
    focus() {
        const input = this.template.querySelector('input.slds-input, input.slds-combobox__input');
        if (input) {
            input.focus();
        }
    }

    /**
     * Public API 메서드 추가 2025-12-23
     * - 검색어/검색결과/드롭다운 상태 초기화
     * - clearSelection=true면 선택값(value/values)까지 초기화
     * - 변수명/구조는 기존 로직 유지
     */
    @api
    async resetLookup(clearSelection = false) {
        // 검색 상태 초기화
        this._clearError();
        this.keyword = '';
        this._resetResults();

        // 선택값 초기화(선택)
        if (clearSelection) {
            this.selected = [];
            if (this._multi) this._values = [];
            else this._value = null;

            if (this._multi) this._fire({ values: this._values });
            else this._fire({ value: this._value });
        }

        // 필요 시 포커스
        await Promise.resolve();
        const el = this.template.querySelector('input.slds-combobox__input');
        if (el && !this.disabled) el.focus();
    }

    @api
    reportValidity() {
        // 에러 스타일을 적용할 컨테이너 찾기 (Combobox 래퍼 또는 Form Element)
        const container = this.template.querySelector('.slds-combobox') 
                       || this.template.querySelector('.slds-combobox__form-element')
                       || this.template.querySelector('.slds-form-element');

        if (this.disabled) {
             if (container) container.classList.remove('slds-has-error');
             return true;
        }

        // 선택된 값이 없고 필수인 경우
        if (this.required && !this.hasSelection) {
            const input = this.template.querySelector('input');
            const msg = this.labels.COM_MSG_COMPLETE_FIELD;
            if (input) {
                input.setCustomValidity(msg);
                input.reportValidity();
            }
            this.errorMessage = msg;
            if (container) container.classList.add('slds-has-error');
            return false;
        }

        // 유효하거나 선택값이 있는 경우 에러 초기화
        const input = this.template.querySelector('input');
        if (input) {
            input.setCustomValidity('');
            input.reportValidity();
        }
        this.errorMessage = '';
        if (container) container.classList.remove('slds-has-error');
        return true;
    }

    // 이벤트 핸들러
    handleInput = (e) => {
        this._clearError();
        this.keyword = e.target.value || '';
        if (this.keyword.length < this.minKeywordLen) {
            this._resetResults();
            return;
        }
        // this._reposition();
        void this.runSearch({ reset: true });
    };

    _ignoreBlur = false;

    handleBlur = () => {
        // console.log('[Lookup] blur', { keyword: this.keyword, isOpen: this.isOpen });
        // if (this.isOpen) return;
        if (this._ignoreBlur) {
            this._ignoreBlur = false;
            return;
        }
        this._resetResults();
    };

    handleDropdownMouseDown = (e) => {
        // input blur가 먼저 일어나지 않도록
        e.preventDefault();
        e.stopPropagation();
        this._ignoreBlur = true;
    };

    handleKeydown = (e) => {
        if (e.key === 'Escape') {
            this._resetResults();
        }
    };

    stopEvent(e) {
        e.preventDefault();
        e.stopPropagation();
    }

    onPick = (e) => {
        e.preventDefault();
        e.stopPropagation();
        this._clearError();
        const id = e.currentTarget.dataset.id;
        const label = e.currentTarget.dataset.label;
        if (this._multi) {
            if (!this.selected.find(s => s.value === id)) {
                this.selected = [...this.selected, { label, value: id }];
            }
            this._values = this.selected.map(s => s.value);
            this._fire({ values: this._values });
        } else {
            this.selected = [{ label, value: id }];
            this._value = id;
            this._fire({ value: id, label });
            this._resetResults();
        }
        this.keyword = '';
    };

    onRemove = (e) => {
        const id = e.detail.name;
        this.selected = this.selected.filter(s => s.value !== id);
        this._values = this.selected.map(s => s.value);
        this._fire({ values: this._values });
    };

    async clearSelection() {
        // console.log('_________________________________________________________________________________________val=['+ val +']')
        this._clearError();
        if (this._multi) return;
        this.selected = [];
        this._value = null;
        this.keyword = '';
        this._fire({ value: null });

        await Promise.resolve();
        const el = this.template.querySelector('input.slds-combobox__input');
        if (el) el.focus();
    }

    loadMore = () => {
        void this.runSearch({ reset: false });
    };

    // Private 메서드
    getConfig() {
        const c = this.config;
        if (!c) return {};
        return typeof c === 'function' ? c(this.ctx) : c;
    }

    _reposition = () => {
        const el = this.template.querySelector('.slds-combobox__form-element');
        const dd = this.template.querySelector('.dropdown-base');

        if (!el) return;

        const r = el.getBoundingClientRect();
        const vh = (window.visualViewport && window.visualViewport.height)
            ? window.visualViewport.height
            : (window.innerHeight || document.documentElement.clientHeight);

        const ddHeightRaw = dd ? (dd.scrollHeight || dd.offsetHeight || 0) : 0;
        const ddHeight = Math.min(240, Math.max(ddHeightRaw, 180));

        const below = vh - r.bottom;
        const above = r.top;

        this.menuPos = (below >= ddHeight || below >= above) ? 'bottom' : 'top';

        this._placeDropdownFixed();
        // console.log('[pos]', { menuPos: this.menuPos, below, above, ddHeight });
    };

    _searchSeq = 0;
    _needsReposition = false;
    async runSearch({ reset }) {

        const seq = ++this._searchSeq;

        const cfg = this.getConfig();
        if (!cfg.objectApiName || !cfg.labelField || this.disabled) {
            this._resetResults();
            return;
        }
        if (cfg.multi !== undefined) this._multi = !!cfg.multi;

        if (reset) {
            this.options = [];
            this.afterLabel = undefined;
            this.afterId = undefined;
            this.hasSearched = false;
        }

        let result = [];
        try {
            result = await search({
                objectApiName: cfg.objectApiName,
                labelField: cfg.labelField,
                subLabelField: cfg.subLabelField || DEFAULT_SUB_LABEL_FIELDS[cfg.objectApiName] || '',
                keyword: this.keyword,
                limitSize: this.pageSize,
                filters: cfg.filters || [],
                minKeywordLen: this.minKeywordLen,
                orderByField: cfg.orderByField || this.orderByField || cfg.labelField,
                orderDir: (cfg.orderDir || this.orderDir || 'ASC').toUpperCase() === 'DESC' ? 'DESC' : 'ASC',
                afterLabel: this.afterLabel,
                afterId: this.afterId,
                recordTypeDeveloperNames: cfg.recordTypeDeveloperNames || this.recordTypeDeveloperNames || []
            }) || [];
        } catch (e) {
            console.error(e);
            this._resetResults();
            return;
        }

        if (seq !== this._searchSeq) return;

        this.hasSearched = true;
        const newOpts = Array.isArray(result) ? result : [];
        this.options = reset ? newOpts : [...this.options, ...newOpts];

        if (newOpts.length) {
            const last = newOpts[newOpts.length - 1];
            this.afterLabel = last.label;
            this.afterId = last.value;
        }

        this.hasMore = newOpts.length === this.pageSize;
        this.isOpen = true;

        // 렌더 후 1회만 위치 계산하도록 플래그
        this._needsReposition = true;

        // 로그는 유지(렌더 전이라 style이 빈 값일 수 있음)
        console.log('[Lookup] open=', this.isOpen, 'opts=', this.options?.length, 'style=', this.dropdownStyle);
    }

    async _hydrate() {
        const ids = this._multi ? this._values : (this._value ? [this._value] : []);
        if (!ids || !ids.length) {
            this.selected = [];
            return;
        }
        const cfg = this.getConfig();
        if (!cfg.objectApiName || !cfg.labelField) return;
        try {
            const rows = await getOptionsByIds({ objectApiName: cfg.objectApiName, labelField: cfg.labelField, ids });
            if (this._multi) {
                this.selected = (rows || []).map(r => ({ label: r.label, value: r.value }));
            } else {
                this.selected = rows && rows.length ? [{ label: rows[0].label, value: rows[0].value }] : [];
            }
        } catch (e) {
            /* ignore */
        }
    }

    _fire(payload) {
        this.dispatchEvent(new CustomEvent('lookupchange', {
            detail: { fieldName: this.fieldName, ...payload },
            bubbles: true,
            composed: true
        }));
    }

    _resetResults() {
        // console.log('[Lookup] _resetResults()', { keyword: this.keyword, isOpen: this.isOpen });
        this.isOpen = false;
        this.options = [];
        this.hasMore = false;
        this.afterLabel = undefined;
        this.afterId = undefined;
        this.hasSearched = false;
        this._needsReposition = false;
        this.dropdownStyle = '';
    }

    _clearError() {
        const input = this.template.querySelector('input');
        if (input) {
            input.setCustomValidity('');
            input.reportValidity();
        }
        this.errorMessage = '';
        const container = this.template.querySelector('.slds-combobox') 
                       || this.template.querySelector('.slds-combobox__form-element')
                       || this.template.querySelector('.slds-form-element');
        if (container) container.classList.remove('slds-has-error');
    }

    _findTableContainer() {
        let node = this.template.host;

        while (node) {
            if (node instanceof HTMLElement && node.classList?.contains('table-container')) {
                return node;
            }
            const root = node.getRootNode && node.getRootNode();
            node = node.parentNode || (root && root.host) || null;
        }
        return null;
    }

    _placeDropdownFixed() {
        if (!this.isOpen) return;

        const el = this.template.querySelector('.slds-combobox__form-element');
        if (!el) return;

        const r = el.getBoundingClientRect();

        // 일반 폼 (isFixed=false)일 때 -> absolute 스타일 적용
        if (!this.isFixed) {

            const parent = el.offsetParent || document.body;
            const pRect = parent.getBoundingClientRect();
            const relativeLeft = r.left - pRect.left;
            /* left: ${relativeLeft}px; */
            this.dropdownStyle = `
            position: absolute;
            top: 100%;
            left: 140px; 
            width: 100%;
            z-index: 9999999;
            max-height: 240px;
            overflow: auto; `;
            return;
        }

        const vh = window.innerHeight || document.documentElement.clientHeight;

        // 위/아래 공간 계산 (160px 기준)
        const spaceBelow = vh - r.bottom;
        const openDown = spaceBelow >= 160 || spaceBelow >= r.top;

        // 스타일 생성
        let style = `position:fixed; left:${r.left}px; width:${r.width}px; z-index:9999999; max-height:240px; overflow:auto;`;
        style += openDown ? `top:${r.bottom + 2}px;` : `bottom:${vh - r.top + 2}px;`;

        this.dropdownStyle = style;
    }
    // 라이프사이클 메서드
    connectedCallback() {
        if (this._Init) return;

        void this._hydrate();
        window.addEventListener('resize', this._reposition); // 선택
        this._Init = true;
    }
    _tableContainer;
    _onTableScroll;

    disconnectedCallback() {

        window.removeEventListener('resize', this._reposition);

        if (this._tableContainer && this._onTableScroll) {
            this._tableContainer.removeEventListener('scroll', this._onTableScroll);
        }
        this._tableContainer = null;
        this._onTableScroll = null;
    }

    renderedCallback() {

        if (this._focusNext) {
            this._focusNext = false;
            const el = this.template.querySelector('input.slds-combobox__input');
            if (el) el.focus();
        }

        if (!this._tableContainer) {
            this._tableContainer = this._findTableContainer();
            if (this._tableContainer) {
                this._onTableScroll = () => {
                    if (this.isOpen) this._reposition();
                };
                this._tableContainer.addEventListener('scroll', this._onTableScroll);
            }
        }

        if (this.isOpen && this._needsReposition) {
            this._needsReposition = false;
            this._reposition();
            // console.log('[Lookup][rendered] open=', this.isOpen, 'opts=', this.options?.length, 'style=', this.dropdownStyle);
            const dd = this.template.querySelector('.dropdown-base');
            if (dd) {
                const rect = dd.getBoundingClientRect();
                console.log('[ddRect]', rect);
            }
        }
    }


}