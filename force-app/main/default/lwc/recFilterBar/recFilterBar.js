import { LightningElement, api } from "lwc";
import { extractFieldPaths, loadFieldLabels, applyLabels } from "c/recSchemaService";

/**
 * recFilterBar — Declarative filter bar.
 *
 * ── Common properties ─────────────────────────────────────────────────────
 * All filter definitions share:
 * {
 *   name         : string   — field key returned by getValues()
 *   label        : string   — label shown in the left cell
 *   type         : string   — 'text' | 'number' | 'date' | 'date-range' | 'combobox' | 'lookup'
 *   size?        : number   — grid columns occupied (1–11, default: 3)
 *   defaultValue?: any      — initial value; also restored by reset()
 *   disabled?    : boolean
 *   required?    : boolean  — if true, validate() fails when the field is empty
 *   config?      : object   — type-specific settings (see below)
 * }
 *
 * ── type: 'text' ──────────────────────────────────────────────────────────
 * Single-line text input.
 * config?: { placeholder?: string }
 *
 * ── type: 'like' ──────────────────────────────────────────────────────────
 * Text input for LIKE search. Value is auto-wrapped with %value%.
 * If the user manually includes % (e.g. '%foo' or 'bar%'), their pattern is preserved.
 * config?: { placeholder?: string }
 *
 * ── type: 'number' ────────────────────────────────────────────────────────
 * Numeric input (HTML type="number").
 * config?: { placeholder?: string }
 *
 * ── type: 'date' ──────────────────────────────────────────────────────────
 * Single date picker (lightning-input type="date").
 * Returns value as 'YYYY-MM-DD' string.
 *
 * ── type: 'date-range' ────────────────────────────────────────────────────
 * Period selector (c-rec-period-selector).
 * getValues() returns { from: 'YYYY-MM-DD', to: 'YYYY-MM-DD' }.
 *
 * ── type: 'date-between' ────────────────────────────────────────────────
 * Date range (From/To) checked against two DB fields for overlap detection.
 * Uses c-rec-period-selector to collect SearchFrom and SearchTo dates.
 * config: {
 *   fromField : string  — DB field that stores the period start (e.g. 'PeriodFrom__c')
 *   toField   : string  — DB field that stores the period end   (e.g. 'PeriodTo__c')
 * }
 * getValues() expands into an overlap query:
 *   { [fromField]: { from: null, to: SearchTo }, [toField]: { from: SearchFrom, to: null } }
 * → SOQL: fromField <= SearchTo AND toField >= SearchFrom
 *
 * ── type: 'number-between' ──────────────────────────────────────────────
 * Number range (From/To) checked against two DB fields for overlap detection.
 * Works exactly like date-between but for numeric fields.
 * config: {
 *   fromField : string  — DB field that stores the period start (e.g. 'MinAmount__c')
 *   toField   : string  — DB field that stores the period end   (e.g. 'MaxAmount__c')
 * }
 *
 * ── type: 'combobox' ─────────────────────────────────────────────────────
 * Dropdown — either static options or Apex-resolved picklist values.
 *
 * Static options:
 * config: {
 *   options  : { label: string, value: string }[]
 *   multiple?: boolean   — allow multi-select (value returned as string[])
 * }
 *
 * Apex picklist:
 * config: {
 *   picklistObject : string   — Salesforce object API name, e.g. 'BankTransaction__c'
 *   picklistField  : string   — field API name, e.g. 'Status__c'
 *   multiple?      : boolean
 * }
 *
 * ── type: 'lookup' ────────────────────────────────────────────────────────
 * Record lookup (c-com-lookup). Returns selected Record ID as value.
 * config: {
 *   objectApiName : string   — Salesforce object API name (required)
 *   labelField    : string   — field displayed in results, e.g. 'Name'
 *   placeholder?  : string   — search input placeholder
 *   filters?      : { criteria: [{ fieldPath: string, operator: string, value: string }] }
 *   orderByField? : string   — field to sort results by
 * }
 *
 * ── layout helpers ────────────────────────────────────────────────────────
 * // Empty space — renders a blank div of the given width, no input
 * { blank: true, size?: number }
 *
 * // Full-width horizontal rule / row break
 * { divider: true }
 *
 * ── @api methods ─────────────────────────────────────────────────────────
 *  getValues()  → { [name]: value }    date-range field → { from: string, to: string }
 *  validate()   → boolean  — runs validation on all fields; returns true if all pass
 *  reset()      → resets all fields to their configured defaultValue (or null)
 *
 * ── Events ───────────────────────────────────────────────────────────────
 *  filterchange  { detail: { name, value } }  — fired on every field value change
 *
 * ── Slots ────────────────────────────────────────────────────────────────
 *  actions  — button group rendered to the right of the filter fields
 *
 * ── Props ────────────────────────────────────────────────────────────────
 *  filterDefs   : filterDef[]   — ordered array of field / layout descriptors
 *  filterWidth  : '1'–'11'     — grid columns for the filter area (default '10')
 *  variant      : 'label-inline' | 'label-stacked' — layout mode (default 'label-inline')
 *                  label-inline  : label left, input right (original)
 *                  label-stacked : label above input (form-style)
 */
export default class RecFilterBar extends LightningElement {
    @api filterWidth = "10";
    @api variant = "label-inline";
    @api collapsible = false;

    _collapsed = false;

    /**
     * Optional SObject API name. When provided, the filter bar automatically
     * loads translated Schema labels and merges them into filter defs
     * (only where `label` is not already set).
     */
    @api
    get objectApiName() {
        return this._objectApiName;
    }
    set objectApiName(value) {
        this._objectApiName = value;
        if (value && this._filterDefs?.length) {
            this._enrichLabelsFromSchema();
        }
    }

    _filterDefs = [];
    _fieldErrors = {};

    @api
    get filterDefs() {
        return this._filterDefs;
    }
    set filterDefs(v) {
        this._filterDefs = Array.isArray(v) ? v : [];
        if (this.objectApiName) {
            this._enrichLabelsFromSchema();
        }
    }

    /** Async — loads Schema labels and merges into filter defs. */
    async _enrichLabelsFromSchema() {
        try {
            const paths = extractFieldPaths(this._filterDefs);
            if (!paths.length) return;
            const labelMap = await loadFieldLabels(this.objectApiName, paths);
            this._filterDefs = applyLabels(this._filterDefs, labelMap);
        } catch (e) {
            console.error("recFilterBar: failed to enrich labels", e);
        }
    }

    // ── Public API ────────────────────────────────────────────────────────────

    /**
     * Collects current values from all filter fields.
     * Returns a plain object: { fieldName: value, ... }
     * For 'date-range' fields: value is { from: 'YYYY-MM-DD', to: 'YYYY-MM-DD' }
     */
    @api
    getValues() {
        const result = {};
        this.template.querySelectorAll("c-rec-filter-field").forEach((field) => {
            const entry = field.getValue();
            const { name, value } = entry;

            // date-between / number-between: overlap query using From/To range
            // fromField <= SearchTo AND toField >= SearchFrom
            if ((entry.type === "date-between" || entry.type === "number-between") && value) {
                const { fromField, toField } = entry;
                if (fromField && fromField === toField) {
                    // Same field — combine from/to into one range object
                    result[fromField] = { from: value.from || null, to: value.to || null };
                } else {
                    if (fromField && value.to) result[fromField] = { from: null, to: value.to };
                    if (toField && value.from) result[toField] = { from: value.from, to: null };
                }
            } else if (name) {
                result[name] = value;
            }
        });

        // Collect picklistExclude from filter defs and pass as __exclude keys
        // only when the user has NOT selected a value (so the query still excludes those values)
        if (this._filterDefs?.length) {
            for (const def of this._filterDefs) {
                const exclude = def.config?.picklistExclude;
                if (Array.isArray(exclude) && exclude.length && def.name) {
                    const val = result[def.name];
                    const hasValue = val !== null && val !== undefined && val !== "" && !(Array.isArray(val) && !val.length);
                    if (!hasValue) {
                        result[def.name + "__exclude"] = exclude;
                    }
                }
            }
        }

        return result;
    }

    /**
     * Validates all filter fields.
     * Returns true when every required field has a value; false otherwise.
     */
    @api
    validate() {
        const errors = {};
        this.template.querySelectorAll("c-rec-filter-field").forEach((field) => {
            if (!field.validate() && field.config?.name) {
                errors[field.config.name] = true;
            }
        });
        this._fieldErrors = errors;
        return Object.keys(errors).length === 0;
    }

    /**
     * Programmatically set or clear an error on a specific field.
     * @param {string} fieldName — the `name` of the filter definition
     * @param {string|null} message — error message to show, or null/empty to clear
     */
    @api
    setFieldError(fieldName, message) {
        if (message) {
            this._fieldErrors = { ...this._fieldErrors, [fieldName]: message };
        } else {
            const copy = { ...this._fieldErrors };
            delete copy[fieldName];
            this._fieldErrors = copy;
        }
    }

    /**
     * Resets all filter fields to their configured defaultValue (or null).
     */
    @api
    reset() {
        this._fieldErrors = {};
        this.template.querySelectorAll("c-rec-filter-field").forEach((f) => f.reset());
    }

    // ── Collapse ──────────────────────────────────────────────────────────────

    handleCollapseToggle() {
        this._collapsed = !this._collapsed;
    }

    get _fieldsClass() {
        return "rfb-fields slds-grid slds-wrap" + (this._collapsed ? " slds-hide" : "");
    }

    get _collapseIconName() {
        return this._collapsed ? "utility:chevrondown" : "utility:chevronup";
    }

    // ── Getters ───────────────────────────────────────────────────────────────

    get fieldItems() {
        return this._filterDefs.map((def, i) => {
            const key = def.name || `item-${i}`;

            // Full-width row divider/spacer
            if (def.divider) {
                return {
                    key,
                    sizeClass: "slds-size_12-of-12",
                    wrapClass: "slds-size_12-of-12",
                    isDivider: true,
                    isField: false
                };
            }

            const size = def.size || 3;
            const sizeClass = `slds-size_${size}-of-12 rfb-field-wrap`;

            // Blank spacer (empty div, no field)
            if (def.blank) {
                return { key, sizeClass, wrapClass: sizeClass, isDivider: false, isField: false };
            }

            const hasError = !!this._fieldErrors[def.name];
            const errorMessage = typeof this._fieldErrors[def.name] === "string" ? this._fieldErrors[def.name] : "";
            const wrapClass = hasError ? `${sizeClass} rfb-field--error` : sizeClass;
            return { key, sizeClass, wrapClass, isDivider: false, isField: true, config: def, hasError, errorMessage };
        });
    }

    // ── Handlers ─────────────────────────────────────────────────────────────

    handleFieldChange(event) {
        // Re-emit so the parent can track live state if desired
        this.dispatchEvent(new CustomEvent("filterchange", { detail: event.detail }));
    }

    handleFieldError(event) {
        const { name, message } = event.detail;
        this.setFieldError(name, message);
    }
}