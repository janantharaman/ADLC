/**********************************************************************************
 * @filename      : comPicklist.js
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
import { LightningElement, api } from 'lwc';

export default class ComPicklist extends LightningElement {

    _placeholder = 'Select an option...';
    isOpen = false;
    _ignoreBlur = false;

    @api multi = false;
    @api options = [];
    @api value;
    @api label;
    @api values = [];
    @api disabled;
    @api required;
    @api fieldName;
    @api multiRowCnt = 5;

    @api
    get placeholder() {
        return this.disabled ? '' : this._placeholder;
    }
    set placeholder(v) {
        this._placeholder = v;
    }

    @api
    reportValidity() {
        if (this.multi) {
            const el = this.template.querySelector('lightning-dual-listbox');
            return el ? el.reportValidity() : true;
        }
        return !(this.required && !this.value);
    }

    get comboboxClass() {
        return `slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click${this.isOpen ? ' slds-is-open' : ''}`;
    }

    get displayValue() {
        const match = this.options?.find(o => o.value === this.value);
        return match ? match.label : '';
    }

    get optionList() {
        return (this.options || []).map(o => ({
            ...o,
            selected: o.value === this.value,
            itemClass: `slds-media slds-listbox__option slds-listbox__option_plain${o.value === this.value ? ' slds-is-selected' : ''}`
        }));
    }

    handleSingleChange(e) {
        this.dispatchEvent(new CustomEvent('picklistchange', {
            detail: { fieldName: this.fieldName, value: e.detail.value }
        }));
    }
    handleMultiChange(e) {
        this.dispatchEvent(new CustomEvent('picklistchange', {
            detail: { fieldName: this.fieldName, values: e.detail.value }
        }));
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

    handleOptionClick(event) {
        const val = event.currentTarget.dataset.value;
        this.isOpen = false;
        this.dispatchEvent(new CustomEvent('picklistchange', {
            detail: { fieldName: this.fieldName, value: val }
        }));
    }

    toggleDropdown() {
        if (this.disabled) return;
        this.isOpen = !this.isOpen;
    }


}