/**********************************************************************************
 * @filename      : ComMultiPicklist.js
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
import {LightningElement, api} from 'lwc';

export default class ComMultiPicklist extends LightningElement {


    // 📍 1. API 속성
    @api options = [];       // [{ label, value }]
    @api values = [];        // 선택된 value 배열
    @api fieldName;
    @api placeholder = 'Select...';
    @api disabled = false;

    // 📍 2. 추적 속성 (반응형)
    isOpen = false;
    keyword = '';

    // 📍 3. Private 속성
    _ignoreBlur = false;

    // 📍 4. Getter/Setter
    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click${this.isOpen ? ' slds-is-open' : ''}`;
    }

    get optionList() {
        const selected = new Set(this.values);
        const kw = this.keyword.toLowerCase();
        return this.options
            .filter(o => !kw || o.label.toLowerCase().includes(kw))
            .map(o => ({
                ...o,
                selected: selected.has(o.value),
                itemClass: `slds-media slds-listbox__option slds-listbox__option_plain${selected.has(o.value) ? ' slds-is-selected' : ''}`
            }));
    }

    get selectedOptions() {
        const selected = new Set(this.values);
        return this.options.filter(o => selected.has(o.value));
    }

    get hasSelection() {
        return this.values && this.values.length > 0;
    }

    // 📍 5. Wire 메서드

    // 📍 6. 이벤트 핸들러
    toggleDropdown() {
        if (this.disabled) return;
        this.isOpen = !this.isOpen;
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

    handlePillRemove(event) {
        const val = event.target.name;
        const updated = this.values.filter(v => v !== val);
        this._fire(updated);
    }

    handleInput(event) {
        this.keyword = event.target.value || '';
        this.isOpen = true;
    }

    handleOptionClick(event) {
        const val = event.currentTarget.dataset.value;
        const current = new Set(this.values);

        if (current.has(val)) {
            current.delete(val);
        } else {
            current.add(val);
        }

        this.keyword = '';    // 선택 후 검색어 초기화
        this.isOpen = false;
        this._fire([...current]);
    }

    // 📍 7. Private 메서드
    _fire(values) {
        this.dispatchEvent(new CustomEvent('picklistchange', {
            detail: { fieldName: this.fieldName, values }
        }));
    }

    // 📍 8. 라이프사이클 메서드
    connectedCallback() {
    }

    disconnectedCallback() {
    }

}