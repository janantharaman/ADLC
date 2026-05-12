/**
 * @description       :
 * @author            : Akrom Saidkamolov
 * @last modified on  : 2026-03-30
 * @last modified by  : Akrom Saidkamolov
 **/
import { LightningElement, api } from "lwc";
import tmplText from "./recTableCell.html";
import tmplClickEdit from "./renderTypes/recTableCellClickEdit.html";
import tmplInput from "./renderTypes/recTableCellInput.html";
import tmplBadge from "./renderTypes/recTableCellBadge.html";
import tmplBoolean from "./renderTypes/recTableCellBoolean.html";
import tmplCurrency from "./renderTypes/recTableCellCurrency.html";
import tmplCurrencyInput from "./renderTypes/recTableCellCurrencyInput.html";
import tmplCombobox from "./renderTypes/recTableCellCombobox.html";
import tmplRecordPicker from "./renderTypes/recTableCellRecordPicker.html";
import tmplUrl from "./renderTypes/recTableCellUrl.html";
import tmplButton from "./renderTypes/recTableCellButton.html";
import tmplCustom from "./renderTypes/recTableCellCustom.html";
import tmplElement from "./renderTypes/recTableCellElement.html";
import tmplDateInput from "./renderTypes/recTableCellDateInput.html";

/**
 * recTableCell — renders a single body cell.
 * Uses render() to swap the entire template per renderType,
 * eliminating all if:true/if:false branching.
 *
 * Receives a single `cell` descriptor object (built by recTable.processedRows)
 * instead of individual @api props — mirrors the recFilterField/recFilterBar pattern.
 *
 * Fires (bubbles + composed):
 *   cellchange      { rowId, fieldName, value, oldValue }
 *   celleditstart   { rowId, fieldName }   — text cell clicked while editable
 *   celleditend     {}                     — edit committed or escaped
 *   cellbuttonclick { rowId, fieldName, value }   — button cell clicked
 */
export default class RecTableCell extends LightningElement {
    /**
     * Single cell descriptor — supplied by recTable from processedRows.
     * Bundles all rendering properties so no individual @api props are needed.
     *
     * {
     *   rowId            : string   — unique row key value
     *   fieldName        : string   — column field name
     *   value            : *        — raw cell value (from source data + edits)
     *   displayValue     : string   — pre-formatted display string
     *   renderType       : string   — which template to use (see recTable JSDoc)
     *   inputType        : string   — 'text' | 'number' | 'date'
     *   isDisabled       : boolean
     *   isEditable       : boolean  — click-to-edit enabled
     *   isEditMode       : boolean  — currently in edit mode
     *   badgeClass       : string   — full SLDS badge class string
     *   viewClass        : string   — CSS class for view-mode span
     *   symbol           : string   — currency symbol (e.g. '₩', '$')
     *   decimalPoint     : number   — decimal places for this row's CCY
     *   maxDecimalPoint  : number   — max decimal places across all rows (column-wide)
     *   comboboxOptions  : { label, value }[]
     *   recordPickerConfig : { objectApiName, placeholder?, matchingInfo?, filter? }
     *   buttonVariant    : string   — SLDS button variant
     *   buttonIconName   : string   — optional icon name
     * }
     */
    @api cell = {};

    // ── Prop getters — derived from cell config ───────────────────────────────
    // Templates continue to use {value}, {isDisabled}, etc. without change.
    get rowId() {
        return this.cell?.rowId;
    }
    get fieldName() {
        return this.cell?.fieldName;
    }
    get value() {
        return this.cell?.value;
    }
    get displayValue() {
        return this.cell?.displayValue ?? "";
    }
    get cellTitle() {
        return this.cell?.title ?? this.displayValue;
    }
    get inputType() {
        return this.cell?.inputType ?? "text";
    }
    get isDisabled() {
        return this.cell?.isDisabled ?? false;
    }
    get isEditable() {
        return this.cell?.isEditable ?? false;
    }
    get isEditMode() {
        return this.cell?.isEditMode ?? false;
    }
    get renderType() {
        return this.cell?.renderType ?? "text";
    }
    get badgeClass() {
        return this.cell?.badgeClass ?? "";
    }
    get viewClass() {
        return this.cell?.viewClass ?? "slds-truncate";
    }
    get symbol() {
        return this.cell?.symbol ?? "";
    }
    get decimalPoint() {
        return this.cell?.decimalPoint ?? 2;
    }
    get maxDecimalPoint() {
        return this.cell?.maxDecimalPoint ?? 2;
    }
    get comboboxOptions() {
        return this.cell?.comboboxOptions ?? [];
    }
    get recordPickerConfig() {
        return this.cell?.recordPickerConfig ?? null;
    }
    get urlHref() {
        return this.cell?.urlHref ?? null;
    }
    get buttonVariant() {
        return this.cell?.buttonVariant ?? "neutral";
    }
    get buttonIconName() {
        return this.cell?.buttonIconName ?? "";
    }
    get isButtonIconOnly() {
        return !this.cell?.displayValue && !!this.cell?.buttonIconName;
    }
    get buttonIconSize() {
        return this.cell?.buttonIconSize ?? "medium";
    }

    // ── Combobox inline state (position:fixed dropdown) ───────────────────
    _cmbOpen = false;
    _cmbStyle = "";
    _cmbPositioned = false;

    // ── render() — picks the right template, no if:true needed ──────────────

    render() {
        switch (this.renderType) {
            case "input":
                return tmplInput;
            case "badge":
                return tmplBadge;
            case "boolean":
                return tmplBoolean;
            case "currency":
                if (this.isEditable && !this.isDisabled) return tmplCurrencyInput;
                return this.isEditMode ? tmplClickEdit : tmplCurrency;
            case "combobox":
                return tmplCombobox;
            case "record-picker":
                return tmplRecordPicker;
            case "url":
                return tmplUrl;
            case "button":
                return tmplButton;
            case "element":
                return tmplElement;
            case "date-input":
                return tmplDateInput;
            case "custom":
                return tmplCustom;
            default:
                return this.isEditMode ? tmplClickEdit : tmplText;
        }
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    renderedCallback() {
        // When render() switches to tmplClickEdit, auto-focus the input.
        if (this.isEditMode) {
            const input = this.template.querySelector("input");
            if (input) input.focus();
        }

        // element type: inject HTML string or HTMLElement into lwc:dom="manual" container
        if (this.renderType === "element") {
            this._renderElementContent();
        }

        // Deferred combobox positioning — runs after backdrop is in the DOM
        if (this._cmbOpen && !this._cmbPositioned) {
            this._calcCmbPos();
            this._cmbPositioned = true;
        }
    }

    /**
     * Imperatively injects value into the lwc:dom="manual" container.
     * Accepts either:
     *   - HTML string  → set via innerHTML
     *   - HTMLElement   → appended as child node
     */
    _renderElementContent() {
        const container = this.template.querySelector("div");
        if (!container) return;

        const content = this.value;
        // Clear previous content
        container.innerHTML = "";

        if (content == null || content === "") return;

        if (typeof content === "string") {
            container.innerHTML = content;
        } else if (content instanceof HTMLElement) {
            container.appendChild(content);
        }
    }

    // ── Derived ──────────────────────────────────────────────────────────────

    get boolChecked() {
        return !!this.value;
    }

    get boolWrapperStyle() {
        const style = this.cell?.cellAlignStyle ?? "";
        if (style.includes("right")) return "display:flex;justify-content:flex-end;width:100%;";
        if (style.includes("left")) return "display:flex;justify-content:flex-start;width:100%;";
        // Default: center
        return "display:flex;justify-content:center;width:100%;";
    }

    // ── Combobox inline getters ──────────────────────────────────────────────

    get cmbIsOpen() {
        return this._cmbOpen;
    }

    get cmbDropdownStyle() {
        return this._cmbStyle;
    }

    get cmbSelectedLabel() {
        const found = (this.comboboxOptions || []).find((o) => o.value === this.value);
        return found ? found.label : "-- Select --";
    }

    get cmbTriggerClass() {
        return `cmb-trigger${this.isDisabled ? " cmb-trigger--disabled" : ""}`;
    }

    get cmbTabIndex() {
        return this.isDisabled ? "-1" : "0";
    }

    get cmbItems() {
        return (this.comboboxOptions || []).map((o) => ({
            ...o,
            cls: `cmb-opt${o.value === this.value ? " cmb-opt--selected" : ""}`
        }));
    }

    // ── Currency helpers ─────────────────────────────────────────────────────

    get _resolvedDecimalPoint() {
        const n = parseInt(this.decimalPoint, 10);
        return isNaN(n) ? 2 : n;
    }

    /**
     * Splits value into { sign, integer (formatted, sign-prefixed), decimal (dot + digits) }.
     * Uses toFixed() for rounding, then strips trailing zeros.
     * e.g. 1234.50 (dp=2) → ".5",  1234.00 (dp=2) → ""
     */
    get _currencyParts() {
        const raw = this.value;
        if (raw === null || raw === undefined || raw === "") return null;
        const n = Number(raw);
        if (isNaN(n)) return null;
        const dp = this._resolvedDecimalPoint;
        const absFixed = Math.abs(n).toFixed(dp); // e.g. "12345.67"
        const dotIdx = absFixed.indexOf(".");
        const intStr = dotIdx >= 0 ? absFixed.slice(0, dotIdx) : absFixed;
        const decStr = dotIdx >= 0 ? absFixed.slice(dotIdx) : ""; // includes "."
        const sign = n < 0 ? "-" : "";
        return {
            integer: sign + Number(intStr).toLocaleString(),
            decimal: decStr
        };
    }

    /** Integer portion including sign prefix, thousands-separated. e.g. "-1,234" */
    get currencyInteger() {
        return this._currencyParts?.integer ?? "";
    }

    /** Decimal portion including leading dot. e.g. ".57" — empty when decimalPoint is 0 */
    get currencyDecimal() {
        if (this._resolvedDecimalPoint === 0) return "";
        return this._currencyParts?.decimal ?? "";
    }

    /**
     * Passes the column's max decimal width as a CSS custom property.
     * Custom properties are single tokens — never affected by LWC shorthand
     * parsing issues. The CSS class then uses `flex: 0 0 var(--dec-w)` safely.
     *
     * KRW-only column (maxDp=0) → --dec-w:0ch → decimal span collapses.
     */
    get decimalPlaceholderStyle() {
        const maxDp = parseInt(this.maxDecimalPoint, 10);
        const colMaxDp = isNaN(maxDp) ? this._resolvedDecimalPoint : maxDp;
        if (colMaxDp === 0) return "--dec-w:0ch";
        return `--dec-w:${colMaxDp + 1}ch`;
    }

    // ── Event handlers ───────────────────────────────────────────────────────

    /** Text cell clicked — notify parent to enter edit mode */
    handleViewClick() {
        if (!this.isEditable || this.isDisabled) return;
        this.dispatchEvent(
            new CustomEvent("celleditstart", {
                detail: { rowId: this.rowId, fieldName: this.fieldName },
                bubbles: true,
                composed: true
            })
        );
    }

    /** click-to-edit input: Enter commits, Escape cancels */
    handleEditKeyDown(event) {
        if (event.key === "Enter") this._commit(event.target.value);
        else if (event.key === "Escape") this._cancelEdit();
    }

    handleEditBlur(event) {
        this._commit(event.target.value);
    }

    /** Always-on input changed */
    handleInlineInputChange(event) {
        const raw = event.target.value;
        const newValue = this.inputType === "number" ? (raw === "" ? "" : Number(raw)) : raw;
        this._emit(newValue);
    }

    /** Formatted display value for editable currency input (unfocused state). */
    get currencyInputDisplayValue() {
        const parts = this._currencyParts;
        if (!parts) return "";
        const dp = this._resolvedDecimalPoint;
        return dp > 0 ? parts.integer + parts.decimal : parts.integer;
    }

    /** On focus: show raw numeric value so the user can edit it cleanly. */
    handleCurrencyInputFocus(event) {
        const n = this.value;
        event.target.value = n === null || n === undefined || n === "" ? "" : String(n);
    }

    /** On change (blur): strip any commas the user may have typed, parse, emit. */
    handleCurrencyInputChange(event) {
        const raw = event.target.value.replace(/,/g, "");
        const newValue = raw === "" ? "" : Number(raw);
        this._emit(isNaN(newValue) ? "" : newValue);
    }

    /** On blur: restore formatted display even when the value was not changed. */
    handleCurrencyInputBlur(event) {
        event.target.value = this.currencyInputDisplayValue;
    }

    handleLightningDateChange(event) {
        this._emit(event.detail.value);
    }

    /** Boolean (checkbox) toggled */
    handleBooleanChange(event) {
        this._emit(event.target.checked);
    }

    // ── Combobox inline handlers ────────────────────────────────────────────

    handleComboboxToggle() {
        if (this.isDisabled) return;
        if (this._cmbOpen) {
            this._cmbOpen = false;
            this._cmbPositioned = false;
            return;
        }
        this._cmbStyle = "position:fixed;visibility:hidden;z-index:9999999;";
        this._cmbPositioned = false;
        this._cmbOpen = true;
    }

    handleComboboxClose() {
        this._cmbOpen = false;
        this._cmbPositioned = false;
    }

    handleComboboxSelect(event) {
        const val = event.currentTarget.dataset.value;
        this._cmbOpen = false;
        this._cmbPositioned = false;
        this._emit(val);
    }

    handleComboboxKeydown(event) {
        if (event.key === "Escape") {
            this._cmbOpen = false;
            this._cmbPositioned = false;
        } else if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            this.handleComboboxToggle();
        }
    }

    _calcCmbPos() {
        const trigger = this.template.querySelector(".cmb-trigger");
        const backdrop = this.template.querySelector(".cmb-backdrop");
        if (!trigger || !backdrop) return;
        const r = trigger.getBoundingClientRect();
        // Backdrop (position:fixed;inset:0) reveals the containing-block offset
        // introduced by any ancestor with a CSS transform (e.g. lightning-modal).
        const b = backdrop.getBoundingClientRect();
        const left = r.left - b.left;
        const topBelow = r.bottom - b.top + 2;
        const spaceBelow = b.height - (r.bottom - b.top);
        const spaceAbove = r.top - b.top;
        const openDown = spaceBelow >= 160 || spaceBelow >= spaceAbove;
        let style = `position:fixed;left:${left}px;min-width:${r.width}px;z-index:9999999;`;
        style += openDown ? `top:${topBelow}px;` : `bottom:${b.height - (r.top - b.top) + 2}px;`;
        this._cmbStyle = style;
    }

    /**
     * Button cell clicked — fires 'cellbuttonclick' with row context.
     * Parent listens with oncellbuttonclick.
     * detail: { rowId, fieldName, value }
     */
    handleButtonClick() {
        this.dispatchEvent(
            new CustomEvent("cellbuttonclick", {
                detail: { rowId: this.rowId, fieldName: this.fieldName, value: this.value },
                bubbles: true,
                composed: true
            })
        );
    }

    /**
     * c-com-lookup fires 'lookupchange': detail → { fieldName, value, label }
     * value is the selected Record ID (null when cleared).
     */
    handleRecordPickerChange(event) {
        this._emit(event.detail.value ?? null);
    }

    // ── Record Picker / comLookup derived props ───────────────────────────

    /** Placeholder text forwarded to c-com-lookup */
    get recordPickerPlaceholder() {
        return this.recordPickerConfig?.placeholder ?? "Search...";
    }

    /**\n     * Adapts recordPickerConfig → comLookup config format.\n     * Supports both unified config (flat) and legacy format (nested matchingInfo/filter).\n     */
    get comLookupConfig() {
        const c = this.recordPickerConfig;
        if (!c?.objectApiName) return null;
        return {
            objectApiName: c.objectApiName,
            labelField: c.labelField || c.matchingInfo?.primaryField?.fieldPath || "Name",
            subLabelFields: c.subLabelFields || [],
            subLabelDelimiter: c.subLabelDelimiter || "",
            filters: c.filters || c.filter?.criteria || [],
            searchOnFocus: !!c.searchOnFocus
        };
    }

    /** Pre-resolved label from recTable hydration cache */
    get resolvedLabel() {
        return this.cell?.resolvedLabel ?? null;
    }

    // ── Private ──────────────────────────────────────────────────────────────

    _commit(rawInput) {
        const newValue = this.inputType === "number" ? (rawInput === "" ? "" : Number(rawInput)) : rawInput;
        this._emit(newValue);
        this._cancelEdit();
    }

    _cancelEdit() {
        this.dispatchEvent(new CustomEvent("celleditend", { bubbles: true, composed: true }));
    }

    _emit(newValue) {
        if (newValue === this.value) return;
        this.dispatchEvent(
            new CustomEvent("cellchange", {
                detail: {
                    rowId: this.rowId,
                    fieldName: this.fieldName,
                    value: newValue,
                    oldValue: this.value
                },
                bubbles: true,
                composed: true
            })
        );
    }
}