import { LightningElement, api, wire } from "lwc";
import tmplText from "./recFilterField.html";
import tmplNumber from "./renderTypes/recFilterFieldNumber.html";
import tmplNumberRange from "./renderTypes/recFilterFieldNumberRange.html";
import tmplDate from "./renderTypes/recFilterFieldDate.html";
import tmplDateRange from "./renderTypes/recFilterFieldDateRange.html";
import tmplCombobox from "./renderTypes/recFilterFieldCombobox.html";
import tmplLookup from "./renderTypes/recFilterFieldLookup.html";

import getPicklistOptions from "@salesforce/apex/REC_Utils.getPicklistOptions";

/**
 * recFilterField — Single filter input cell.
 * Uses render() to swap template per type (same pattern as recTableCell).
 *
 * @api config  — filterDef object (see recFilterBar JSDoc for full schema)
 *
 * @api getValue()  → { name, value }
 * @api reset()     → resets to defaultValue; clears recPeriodSelector for date-range
 *
 * @fires fieldchange  { detail: { name, value } }  bubbles+composed
 *
 * Wire note:
 *   When config.picklistObject + config.picklistField are set, this component
 *   automatically wires REC_Utils.getPicklistOptions to load combobox options.
 *   Wire does NOT fire when _picklistObject is null (non-combobox types).
 */
export default class RecFilterField extends LightningElement {
    // ── Reactive wire targets (must be real fields, not getters) ─────────────
    // IMPORTANT: must be `undefined` (not null) — LWC wire suppresses the call
    // only when the reactive property is undefined. null still fires the wire.
    _picklistObject = undefined;
    _picklistField = undefined;

    // ── Private state ─────────────────────────────────────────────────────────
    _config = {};
    _value = null;
    _wireOptions = [];

    // ── Combobox position:fixed dropdown state ────────────────────────────────
    _cmbOpen = false;
    _cmbStyle = "";

    // ── @api ──────────────────────────────────────────────────────────────────

    @api variant = "label-inline";

    @api
    get config() {
        return this._config;
    }
    set config(v) {
        this._config = v || {};
        const c = v?.config;
        // Extract wire targets — must be undefined (not null) to suppress wire when absent
        this._picklistObject = c?.picklistObject || undefined;
        this._picklistField = c?.picklistField || undefined;
        // Initialise value — multiple:true starts as [], number-range as {from,to}, otherwise null
        if (v?.type === "number-range" || v?.type === "number-between") {
            this._value = v?.defaultValue ?? { from: null, to: null };
        } else {
            this._value = v?.defaultValue ?? (c?.multiple ? [] : null);
        }
    }

    // ── @wire: picklist options via Apex ─────────────────────────────────────
    // Wire does NOT fire when _picklistObject is null/undefined (non-combobox types).
    @wire(getPicklistOptions, {
        objectApiName: "$_picklistObject",
        fieldApiName: "$_picklistField"
    })
    wiredPicklistOptions({ data, error }) {
        if (data) {
            this._wireOptions = [...data];
        } else if (error) {
            console.error("[recFilterField] getPicklistOptions error:", error);
            this._wireOptions = [];
        }
    }

    // ── render() ─────────────────────────────────────────────────────────────

    render() {
        switch (this._config?.type) {
            case "number":
                return tmplNumber;
            case "number-range":
            case "number-between":
                return tmplNumberRange;
            case "date":
                return tmplDate;
            case "date-range":
                return tmplDateRange;
            case "date-between":
                return tmplDateRange;
            case "combobox":
                return tmplCombobox;
            case "lookup":
            case "record-picker": // alias for lookup
                return tmplLookup;
            case "like":
                return tmplText;
            default:
                return tmplText;
        }
    }

    // ── @api methods ──────────────────────────────────────────────────────────

    /**
     * Returns { name, value }.
     * For 'date-range': reads directly from c-rec-period-selector.
     * For 'date-between': reads from c-rec-period-selector (From/To),
     *   additionally returns { type, fromField, toField } so that
     *   recFilterBar can expand it into an overlap query:
     *   fromField <= SearchTo AND toField >= SearchFrom
     */
    @api
    getValue() {
        if (this._config?.type === "date-range") {
            const ps = this.template.querySelector("c-rec-period-selector");
            return {
                name: this._config.name,
                value: ps ? { from: ps.periodFromDate ?? null, to: ps.periodToDate ?? null } : { from: null, to: null }
            };
        }
        if (this._config?.type === "date-between") {
            const ps = this.template.querySelector("c-rec-period-selector");
            const from = ps?.periodFromDate ?? null;
            const to = ps?.periodToDate ?? null;
            return {
                name: this._config.name,
                value: { from, to },
                type: "date-between",
                fromField: this._config?.config?.fromField,
                toField: this._config?.config?.toField
            };
        }
        if (this._config?.type === "number-between") {
            const val = this._value ?? { from: null, to: null };
            return {
                name: this._config.name,
                value: val,
                type: "number-between",
                fromField: this._config?.config?.fromField,
                toField: this._config?.config?.toField
            };
        }
        if (this._config?.type === "number-range") {
            return {
                name: this._config.name,
                value: this._value ?? { from: null, to: null }
            };
        }
        if (this._config?.type === "like") {
            const raw = this._value;
            if (raw == null || raw === "") return { name: this._config?.name, value: null };
            const str = String(raw);
            const wrapped = str.startsWith("%") || str.endsWith("%") ? str : `%${str}%`;
            return { name: this._config?.name, value: wrapped };
        }
        return { name: this._config?.name, value: this._value };
    }

    /**
     * Resets the field to its defaultValue (or null).
     * For 'date-range', also calls recPeriodSelector.reset().
     */
    @api
    reset() {
        const def = this._config?.defaultValue ?? (this.isMultiple ? [] : null);
        this._value =
            this._config?.type === "number-range" || this._config?.type === "number-between"
                ? { from: null, to: null }
                : def;
        this._emitError(null);
        this._cmbOpen = false;
        if (this._config?.type === "date-range" || this._config?.type === "date-between") {
            const ps = this.template.querySelector("c-rec-period-selector");
            if (ps) ps.reset();
        }
    }

    /**
     * Validates this field. Returns true if valid.
     * For required fields, returns false when the value is empty.
     */
    @api
    validate() {
        return !this.isRequired || !this._isEmpty();
    }

    // ── Shared getters (available to all render templates) ───────────────────

    get label() {
        return this._config?.label || "";
    }

    get placeholder() {
        return this._config?.config?.placeholder || this._config?.placeholder || "";
    }

    get isDisabled() {
        return !!this._config?.disabled;
    }

    get isRequired() {
        return !!this._config?.required;
    }

    get isStacked() {
        return this.variant === "label-stacked";
    }

    get labelClass() {
        if (this.isStacked) {
            return "slds-p-horizontal_xx-small slds-truncate";
        }
        return "slds-align_absolute-center slds-theme_shade slds-p-vertical_medium slds-border_bottom slds-truncate";
    }

    /** Safe string/number value for lightning-input */
    get inputValue() {
        return this._value ?? "";
    }

    /** True when config.multiple === true */
    get isMultiple() {
        return !!this._config?.config?.multiple;
    }

    /**
     * Label column size within this field's own 12-col grid.
     * Formula: 12 / config.size
     *   e.g. size=3 → 4/12, size=4 → 3/12, size=6 → 2/12
     * This makes the label always occupy exactly 1/12 of the full row,
     * keeping label widths visually consistent across all field sizes.
     */
    get labelSize() {
        if (this.isStacked) return 12;
        const s = parseInt(this._config?.size, 10) || 3;
        return 12 / s;
    }

    /** Content column: fills the rest of the field */
    get contentSize() {
        if (this.isStacked) return 12;
        return 12 - this.labelSize;
    }

    /** True when there is at least one selected value (used to show clear button) */
    get cmbHasSelection() {
        if (this.isMultiple) return Array.isArray(this._value) && this._value.length > 0;
        return this._value !== null && this._value !== undefined && this._value !== "";
    }

    // ── Combobox getters ──────────────────────────────────────────────────────

    /** Merged options: wire data takes priority over static options. Excludes values in picklistExclude. */
    get cmbOptions() {
        const raw = this._wireOptions.length
            ? this._wireOptions
            : this._config?.config?.options || this._config?.options || [];
        const exclude = this._config?.config?.picklistExclude;
        if (Array.isArray(exclude) && exclude.length) {
            const excludeSet = new Set(exclude);
            return raw.filter((o) => !excludeSet.has(o.value));
        }
        return raw;
    }

    get cmbSelectedLabel() {
        if (this.isMultiple) {
            const arr = Array.isArray(this._value) ? this._value : [];
            if (!arr.length) return this.placeholder || "-- Select --";
            const labels = arr.map((v) => {
                const found = this.cmbOptions.find((o) => o.value === v);
                return found ? found.label : v;
            });
            return labels.length === 1 ? labels[0] : `${labels.length} selected`;
        }
        const found = this.cmbOptions.find((o) => o.value === this._value);
        return found ? found.label : this.placeholder || "-- Select --";
    }

    get cmbTriggerClass() {
        return `slds-input cmb-trigger${this.isDisabled ? " cmb-trigger--disabled" : ""}`;
    }

    get cmbTabIndex() {
        return this.isDisabled ? "-1" : "0";
    }

    get cmbIsOpen() {
        return this._cmbOpen;
    }

    get cmbDropdownStyle() {
        return this._cmbStyle;
    }

    get cmbItems() {
        const isMulti = this.isMultiple;
        const val = this._value;
        return this.cmbOptions.map((o) => {
            const isSelected = isMulti ? Array.isArray(val) && val.includes(o.value) : o.value === val;
            return {
                ...o,
                cls: `cmb-opt${isSelected ? " cmb-opt--selected" : ""}`,
                isChecked: isSelected,
                showCheck: isMulti
            };
        });
    }

    // ── Lookup getters ────────────────────────────────────────────────────────

    get lookupConfig() {
        return this._config?.config || this._config?.lookupConfig || null;
    }

    get lookupPlaceholder() {
        return this._config?.config?.placeholder || this._config?.placeholder || "Search\u2026";
    }

    // ── Event handlers ────────────────────────────────────────────────────────

    handleTextChange(event) {
        this._value = event.target.value ?? "";
        this._emit(this._value);
    }

    handleNumberChange(event) {
        const v = event.target.value;
        this._value = v === "" ? null : Number(v);
        this._emit(this._value);
    }

    // ── Number-range getters & handler ────────────────────────────────────────

    get numberRangeFrom() {
        const v = this._value?.from;
        return v != null ? v : "";
    }

    get numberRangeTo() {
        const v = this._value?.to;
        return v != null ? v : "";
    }

    handleNumberRangeChange(event) {
        const which = event.currentTarget.dataset.range; // 'from' or 'to'
        const raw = event.target.value;
        const num = raw === "" ? null : Number(raw);
        const prev = this._value && typeof this._value === "object" ? this._value : { from: null, to: null };
        this._value = { ...prev, [which]: num };
        this._emit(this._value);
    }

    handleNumberRangeBlur(event) {
        const which = event.currentTarget.dataset.range; // 'from' or 'to'
        const { from, to } = this._value && typeof this._value === "object" ? this._value : { from: null, to: null };

        if (from != null && to != null && from > to) {
            const clearField = which; // clear the field that was just edited
            this._value = { ...this._value, [clearField]: from };
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            Promise.resolve().then(() => {
                this._value = { ...this._value, [clearField]: null };
                this._emit(this._value);
            });
        }
    }

    handleDateChange(event) {
        this._value = event.target.value || null;
        this._emit(this._value);
    }

    /** c-rec-cell-lookup fires 'lookupchange' → detail: { name, value, label } */
    handleLookupChange(event) {
        this._value = event.detail.value ?? null;
        this._emit(this._value);
    }

    // ── Combobox inline handlers (position:fixed dropdown) ───────────────────

    handleComboboxToggle() {
        if (this.isDisabled) return;
        if (this._cmbOpen) {
            this._cmbOpen = false;
            return;
        }
        this._calcCmbPos();
        this._cmbOpen = true;
    }

    handleComboboxClose() {
        this._cmbOpen = false;
    }

    handleComboboxSelect(event) {
        const val = event.currentTarget.dataset.value;
        if (this.isMultiple) {
            // Toggle the value in/out of the array; keep dropdown open
            const arr = Array.isArray(this._value) ? [...this._value] : [];
            const idx = arr.indexOf(val);
            if (idx === -1) arr.push(val);
            else arr.splice(idx, 1);
            this._value = arr;
            this._emit(arr);
            return;
        }
        this._cmbOpen = false;
        this._value = val;
        this._emit(val);
    }

    /** Clear button inside trigger: resets selection without toggling dropdown */
    handleComboboxClear(event) {
        event.stopPropagation();
        this._value = this.isMultiple ? [] : null;
        this._cmbOpen = false;
        this._emit(this._value);
    }

    handleComboboxKeydown(event) {
        if (event.key === "Escape") {
            this._cmbOpen = false;
        } else if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            this.handleComboboxToggle();
        }
    }

    // ── Private ───────────────────────────────────────────────────────────────

    _isEmpty() {
        const { value } = this.getValue();
        if (value == null || value === "") return true;
        if (Array.isArray(value)) return value.length === 0;
        if (typeof value === "object") {
            // range objects: { from, to } — at least one must be filled
            return Object.values(value).every((v) => v == null || v === "");
        }
        return false;
    }

    /**
     * Calculates position:fixed coordinates for the combobox dropdown,
     * opening below the trigger when there is space, otherwise above.
     */
    _calcCmbPos() {
        const trigger = this.template.querySelector(".cmb-trigger");
        if (!trigger) return;
        const r = trigger.getBoundingClientRect();
        const spaceBelow = window.innerHeight - r.bottom;
        const openDown = spaceBelow >= 160 || spaceBelow >= r.top;
        let style = `position:fixed;left:${r.left}px;min-width:${r.width}px;z-index:9999999;`;
        style += openDown ? `top:${r.bottom + 2}px;` : `bottom:${window.innerHeight - r.top + 2}px;`;
        this._cmbStyle = style;
    }

    _emit(value) {
        this.dispatchEvent(
            new CustomEvent("fieldchange", {
                detail: { name: this._config?.name, value },
                bubbles: true,
                composed: true
            })
        );
    }

    _emitError(message) {
        this.dispatchEvent(
            new CustomEvent("fielderror", {
                detail: { name: this._config?.name, message },
                bubbles: true,
                composed: true
            })
        );
    }
}