/**********************************************************************************
 * @filename      : ComTypeaheadPicklist.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-15 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-15      i2max      Create
 **********************************************************************************/
import {LightningElement, api, track, wire} from 'lwc';
import getOptions from '@salesforce/apex/COM_TypeaheadPicklist_Ctrl.getOptions';

export default class ComTypeaheadPicklist extends LightningElement {

    // 📍 1. API 속성
    @api objectApiName;
    /** @type {string[]} */
    @api fieldApiNames = [];
    @api displaySeparator = ' > ';
    @api valueSeparator = '_';
    @api fieldName;
    @api placeholder = 'Search...';
    @api disabled = false;
    @api value;
    @api minKeywordLen = 2;
    @api reset() {
        this.handleClear();
    }

    // 📍 2. 추적 속성 (반응형)
    @track options = [];
    isOpen = false;
    keyword = '';
    hasSearched = false;
    validationMessage = '';


    // 📍 3. Private 속성
    _selected = null;
    _searchSeq = 0;
    _ignoreBlur = false;


    // 📍 4. Getter/Setter
    get filteredOptions() {
        if (!this.keyword) return [];
        const kw = this.keyword.toLowerCase();
        return this.options.filter(opt => opt.label.toLowerCase().includes(kw));
    }
    get formElementClass() {
        return `slds-input-has-icon_right slds-form-element${this.validationMessage ? ' slds-has-error' : ''}`;
    }
    get hasSelection() {
        return this._selected != null;
    }
    get selectedLabel() {
        return this._selected ? this._selected.label : '';
    }
    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click${this.isOpen ? ' slds-is-open' : ''}`;
    }
    get showNoResults() {
        return this.isOpen && this.filteredOptions.length === 0;
    }

    // 📍 5. Wire 메서드
    @wire(getOptions, {
        objectApiName: '$objectApiName',
        fieldApiNames: '$fieldApiNames',
        displaySeparator: '$displaySeparator',
        valueSeparator: '$valueSeparator'
    })
    wiredOptions({ data, error }) {
        console.log('[ComTypeaheadPicklist > getOptions] data', data)
        if (data) {
            this.options = data;
        } else if (error) {
            this.options = [];
            console.error('getOptions', error)
        }
    }


    // 📍 6. 이벤트 핸들러
    handleInput(event) {
        this.keyword = event.target.value || '';

        console.log('[ComTypeaheadPicklist > handleInput] keyword', this.keyword)
        if (this.keyword.length > 0 && this.keyword.length < this.minKeywordLen) {
            this.validationMessage = `${this.minKeywordLen}자 이상 입력해주세요.`;
            this.isOpen = false;
            return;
        }

        this.validationMessage = '';
        this.isOpen = this.keyword.length >= this.minKeywordLen;
    }
    handleBlur() {
        if (this._ignoreBlur) {
            this._ignoreBlur = false;
            return;
        }
        this.isOpen = false;
    }

    handleDropdownMouseDown(event) {
        event.preventDefault();
        this._ignoreBlur = true;
    }

    handleKeydown(event) {
        if (event.key === 'Escape') {
            this.isOpen = false;
        }
    }

    handleSelect(event) {
        const value = event.currentTarget.dataset.value;
        const label = event.currentTarget.dataset.label;
        this._selected = { label, value };
        this.keyword = '';
        this.isOpen = false;
        this.validationMessage = '';
        this._fire({ value, label });
    }

    handleClear() {
        this._selected = null;
        this.keyword = '';
        this._fire({ value: null, label: null });
    }


    // 📍 7. Private 메서드
    _fire(payload) {
        this.dispatchEvent(new CustomEvent('picklistchange', {
            detail: { fieldName: this.fieldName, ...payload }
        }));

    }

    // 📍 8. 라이프사이클 메서드
    connectedCallback() {
    }

    disconnectedCallback() {
    }


}