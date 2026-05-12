/**
 * @description       :
 * @author            : shkang@trestle.co.kr
 * @last modified on  : 2026-04-03
 * @last modified by  : Akrom Saidkamolov
 **/
import { LightningElement, api, track, wire } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import getPicklistOptions from "@salesforce/apex/REC_Utils.getPicklistOptions";
import getOptionsByIdsBulk from "@salesforce/apex/REC_Lookup_Ctrl.getOptionsByIdsBulk";
import getCurrencyConfigs from "@salesforce/apex/REC_Utils.getCurrencyConfigs";
import { extractFieldPaths, loadFieldLabels, applyLabels } from "c/recSchemaService";
import USER_LOCALE from "@salesforce/i18n/locale";

import SheetJs from "@salesforce/resourceUrl/sheetjs";

// ── Module-level constants ──────────────────────────────────────────────
const SPECIALIZED_TYPES = new Set([
    "currency",
    "combobox",
    "badge",
    "boolean",
    "record-picker",
    "url",
    "button",
    "custom",
    "element"
]);
const INTERACTIVE_TAGS = new Set(["input", "button", "a", "select"]);
const VIEW_CLASS_EDITABLE = "slds-truncate rec-table__cell_editable";
const VIEW_CLASS_READONLY = "slds-truncate";

/**
 * recTable — Reusable hierarchical-header data table.
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *  Column Definition (unified — `type` + `config`)
 * ═══════════════════════════════════════════════════════════════════════════
 *
 * ── Shared fields (all types) ─────────────────────────────────────────────
 * {
 *   label       : string    — header label
 *   name        : string    — row data field key
 *   type        : string    — 'text'(default) | 'number' | 'date' | 'boolean'
 *                              | 'currency' | 'combobox' | 'record-picker'
 *                              | 'badge' | 'button' | 'custom'
 *   editable    : boolean   — always-on edit control for text/number/date
 *   disabled    : boolean   — disable all cells in this column
 *   disableWhen : (row) => boolean — per-row callback to conditionally disable this cell
 *   sortable    : boolean   — enable sort on this column (hover arrow, click to toggle asc/desc)
 *   highlight   : boolean   — paint all cells in this column with a light-yellow background
 *   collapsible : boolean   — leaf hides when parent group is collapsed
 *   collapsed   : boolean   — (group only) initial collapsed state. Default: false (expanded)
 *   width       : string    — CSS width, e.g. '8rem'
 *   align       : string    — 'center' | 'left' | 'right'  (default: 'right' for number, 'center' for others)
 *   columns     : Column[]  — child columns (group header)
 *   config      : object    — type-specific settings (see below)
 *                              — config.sorter : (a, b) => number  (custom sort comparator for sortable columns)
 * }
 *
 * ── type: 'text' / 'number' / 'date' ─────────────────────────────────────
 *   editable: false → read-only formatted text
 *   editable: true  → always-visible inline input
 * config: { decimalPlaces?: number }   — (number only) display decimal places.
 *          Internal value keeps full precision; only the displayed text is rounded.
 *
 * ── type: 'boolean' ──────────────────────────────────────────────────────
 * Checkbox. config: (none required)
 *
 * ── type: 'currency' ─────────────────────────────────────────────────────
 * Symbol + formatted amount with decimal alignment.
 * config: { ccyField: string }
 *
 * ── type: 'combobox' ─────────────────────────────────────────────────────
 * Dropdown. Supports static options or Apex picklist.
 * config: { options?, picklistObject?, picklistField? }
 *
 * ── type: 'record-picker' ────────────────────────────────────────────────
 * Lookup search. Stores selected Record ID.
 * config: { objectApiName, labelField?, placeholder?, filters?, searchOnFocus? }
 *   searchOnFocus : boolean — when true AND filters are present, clicking the
 *                   input triggers an immediate search without typing. Default: false.
 *
 * ── type: 'badge' ────────────────────────────────────────────────────────
 * Colored pill.
 * config: { variantMap: Record<cellValue, slds-theme-class> }
 *
 * ── type: 'button' ───────────────────────────────────────────────────────
 * Action button. Fires cellbuttonclick.
 * config: { label?, variant?, iconName? }
 *
 * ── type: 'custom' ───────────────────────────────────────────────────────
 * Named slot. config: (none required)
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *  Events
 * ═══════════════════════════════════════════════════════════════════════════
 *  rowselection      { detail: { selectedRows: Object[] } }
 *  cellchange        { detail: { rowId, fieldName, value, oldValue, row } }
 *  cellbuttonclick   { detail: { rowId, fieldName, value, row } }
 *  groupcollapse     { detail: { groupName, collapsed: boolean } }
 *  dirtystatechange  { detail: { hasDirty: boolean } }
 *  sort              { detail: { fieldName, direction: 'asc'|'desc'|null } }
 *
 * ═══════════════════════════════════════════════════════════════════════════
 *  Public API
 * ═══════════════════════════════════════════════════════════════════════════
 *  Methods:
 *   getSelectedRows()  / getSelectedRowIds()  / clearSelection()
 *   getData()  / resetData(newData)
 *   setCellDisabled(rowId, field, bool)  / setGroupCollapsed(groupName, bool)
 *   collapseAll()  / expandAll()
 *   getDirtyRows() / markSaved() / setCellErrors(errors)
 *   setSortField(fieldName, direction) / clearSort()
 *
 *  Tree Methods (enableTreeGrid=true):
 *   toggleTreeRow(rowId) / expandAllTreeRows() / collapseAllTreeRows()
 *   getTreeData()
 *
 *  Properties:
 *   keyField, hideCheckboxColumn, enableRowClick, currencyConfig
 *   enableTreeGrid, childrenField
 */
export default class RecTable extends LightningElement {
    // ═══════════════════════════════════════════════════════════════════════
    //  Public API — Properties
    // ═══════════════════════════════════════════════════════════════════════

    /** Field name used as the unique row key. Default: 'id' */
    @api keyField = "id";

    /** When true, the leading checkbox column is hidden */
    @api
    get hideCheckboxColumn() {
        return this._hideCheckboxColumn;
    }
    set hideCheckboxColumn(value) {
        const v = !!value;
        if (this._hideCheckboxColumn === v) return;
        this._hideCheckboxColumn = v;
        if (this._processedRows.length) this._rebuildProcessedRows();
    }
    _hideCheckboxColumn = false;

    /** When true, clicking anywhere on a row toggles its selection. Default: false */
    @api enableRowClick = false;

    /** Array of row key values that should be fully disabled (all cells). */
    @api
    get disabledRowIds() {
        return this._disabledRowIds;
    }
    set disabledRowIds(value) {
        this._disabledRowIds = value || [];
        this._disabledRowIdSet = new Set(this._disabledRowIds.map(String));
        this._rebuildSelectableCount();
        this._rebuildProcessedRows();
    }

    /**
     * Optional SObject API name. When provided, the table automatically
     * loads translated Schema labels and merges them into column defs
     * (only where `label` is not already set).
     */
    @api
    get objectApiName() {
        return this._objectApiName;
    }
    set objectApiName(value) {
        this._objectApiName = value;
        if (value && this._rawColumnDefs?.length) {
            this._enrichLabelsFromSchema();
        }
    }

    /** Enable tree grid mode. Data rows may contain a children array to form a hierarchy. */
    @api enableTreeGrid = false;

    /** When true, tree rows start collapsed instead of expanded. Default: false */
    @api treeDefaultCollapsed = false;

    /** Field name that holds the children array on each row. Default: '_children' */
    @api childrenField = "_children";

    /**
     * Override or extend the CCY symbol config.
     * Merged on top of the CMDT-loaded config — only keys you provide are overwritten.
     * e.g. <c-rec-table currency-config={myCurrencyConfig}>
     */
    @api
    get currencyConfig() {
        return this._currencyConfig;
    }
    set currencyConfig(value) {
        this._userCurrencyConfig = value ?? {};
        this._currencyConfig = { ...this._cmdtCurrencyConfig, ...this._userCurrencyConfig };
        this._rebuildMaxDecimalMap();
        this._rebuildProcessedRows();
    }

    @wire(getCurrencyConfigs)
    _wiredCurrencyConfigs({ data }) {
        if (data) {
            this._cmdtCurrencyConfig = data;
            this._currencyConfig = { ...data, ...(this._userCurrencyConfig ?? {}) };
            this._rebuildMaxDecimalMap();
            this._rebuildProcessedRows();
        }
    }

    @api
    get columns() {
        return this._columns;
    }
    set columns(value) {
        this._rawColumnDefs = value || [];
        this._applyColumnPipeline(this._rawColumnDefs);
        if (this.objectApiName) {
            this._enrichLabelsFromSchema();
        }
    }

    /** Internal — runs the full column-processing pipeline. */
    _applyColumnPipeline(cols) {
        this._columns = cols;
        this._allLeafColConfig = this._extractLeafConfig(this._columns);
        this._initCollapseState(this._columns);
        this._rebuildVisibleLeaves();
        this._resolvePicklistOptions();
    }

    /** Async — loads Schema labels and re-applies the column pipeline. */
    async _enrichLabelsFromSchema() {
        try {
            const paths = extractFieldPaths(this._rawColumnDefs);
            if (!paths.length) return;
            const labelMap = await loadFieldLabels(this.objectApiName, paths);
            this._applyColumnPipeline(applyLabels(this._rawColumnDefs, labelMap));
        } catch (e) {
            console.error("recTable: failed to enrich labels", e);
        }
    }

    @api
    get data() {
        return this._data;
    }
    set data(value) {
        const newData = value || [];

        // ── Smart edit-map reconciliation ────────────────────────────────────
        // In tree mode, extract ALL rows (parent+child) for flat comparison.
        const extractAll = (d) => (this.enableTreeGrid ? this._extractAllRowsFromTree(d) : d);
        const oldFlat = extractAll(this._data);
        const newFlat = extractAll(newData);
        const childField = this.childrenField;

        const oldDataMap = new Map(oldFlat.map((r) => [String(r[this.keyField]), r]));
        const newIds = new Set(newFlat.map((r) => String(r[this.keyField])));

        newFlat.forEach((newRow) => {
            const id = String(newRow[this.keyField]);
            const oldRow = oldDataMap.get(id);
            if (oldRow) {
                const sourceChanged = Object.keys(newRow).some((k) => k !== childField && newRow[k] !== oldRow[k]);
                if (sourceChanged) {
                    this._rowEditMap.delete(id);
                }
            }
        });

        for (const id of this._rowEditMap.keys()) {
            if (!newIds.has(id)) this._rowEditMap.delete(id);
        }
        for (const key of this._cellErrorMap.keys()) {
            const rowId = key.split("::")[0];
            if (!newIds.has(rowId)) this._cellErrorMap.delete(key);
        }
        // ─────────────────────────────────────────────────────────────────────

        if (this.enableTreeGrid) this._initTreeExpandState(newData);

        this._data = newData;
        this._selectedRowIds = this._selectedRowIds.filter((id) => newIds.has(id));
        this._editingCellKey = null;

        const requests = this._collectLookupRequests(newData);
        if (requests.length) {
            this._internalData = [];
            this._isHydrating = true;
            this._preHydrateAndBuild(requests);
        } else {
            this._buildInternalData();
            this._dispatchDirtyStateIfChanged();
        }
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Public API — Methods
    // ═══════════════════════════════════════════════════════════════════════

    /** Returns data objects for currently selected rows (with edits applied). Internal tree metadata stripped. */
    @api
    getSelectedRows() {
        const set = new Set(this._selectedRowIds);
        return this._internalData
            .filter((r) => set.has(String(r[this.keyField])))
            .map(({ __treeLevel, __treeHasChildren, __treeExpanded, ...rest }) => rest);
    }

    @api
    getSelectedRowIds() {
        return [...this._selectedRowIds];
    }

    @api
    clearSelection() {
        this._selectedRowIds = [];
        this._rebuildProcessedRows();
    }

    /**
     * Returns current data merged with all pending edits.
     * In tree mode: returns ALL rows (including collapsed children) as a flat array.
     * Internal tree metadata fields (__treeLevel etc.) are stripped from results.
     */
    @api
    getData() {
        if (this.enableTreeGrid) {
            const childField = this.childrenField;
            const flatten = (rows) =>
                rows.flatMap((r) => {
                    const { [childField]: children, __treeLevel, __treeHasChildren, __treeExpanded, ...rest } = r;
                    return [rest, ...(Array.isArray(children) && children.length ? flatten(children) : [])];
                });
            return flatten(this._applyEditsToTree(this._data));
        }
        return this._internalData.map(({ __treeLevel, __treeHasChildren, __treeExpanded, ...rest }) => rest);
    }

    /**
     * Hard-resets the table with entirely new data.
     * Clears all pending edits, selection, and edit state — use when
     * the parent performs a full re-query and wants a clean slate.
     * (Contrast with `data` setter, which preserves edits for unchanged rows.)
     *
     * @param {Object[]} newData — replacement dataset
     */
    @api
    resetData(newData) {
        this._data = newData || [];
        this._rowEditMap = new Map();
        this._cellErrorMap = new Map();
        if (this.enableTreeGrid) {
            this._expandedRowIds = new Set();
            this._treeKnownParentIds = new Set();
            this._initTreeExpandState(this._data);
        }
        this._selectedRowIds = [];
        this._editingCellKey = null;

        const requests = this._collectLookupRequests(this._data);
        if (requests.length) {
            this._internalData = [];
            this._isHydrating = true;
            this._preHydrateAndBuild(requests);
        } else {
            this._buildInternalData();
            this._dispatchDirtyStateIfChanged();
        }
    }

    /**
     * Programmatically disable/enable a specific cell.
     * Persisted in _cellDisableMap so it survives collapse/expand cycles.
     */
    @api
    setCellDisabled(rowId, fieldName, disabled) {
        const key = `${rowId}::${fieldName}`;
        if (disabled) {
            this._cellDisableMap.set(key, true);
        } else {
            this._cellDisableMap.delete(key);
        }
        this._rebuildProcessedRows();
    }

    /**
     * Programmatically collapse or expand a group column.
     */
    @api
    setGroupCollapsed(groupName, collapsed) {
        if (!this._collapseState.has(groupName)) return;
        this._collapseState.set(groupName, collapsed);
        this._rebuildVisibleLeaves();
        this.dispatchEvent(new CustomEvent("groupcollapse", { detail: { groupName, collapsed } }));
    }

    /**
     * Collapses all collapsible group columns.
     */
    @api
    collapseAll() {
        for (const key of this._collapseState.keys()) {
            this._collapseState.set(key, true);
        }
        this._rebuildVisibleLeaves();
        this.dispatchEvent(new CustomEvent("groupcollapse", { detail: { groupName: null, collapsed: true } }));
    }

    /**
     * Expands all collapsible group columns.
     */
    @api
    expandAll() {
        for (const key of this._collapseState.keys()) {
            this._collapseState.set(key, false);
        }
        this._rebuildVisibleLeaves();
        this.dispatchEvent(new CustomEvent("groupcollapse", { detail: { groupName: null, collapsed: false } }));
    }

    /**
     * Returns rows that have been modified (dirty).
     * Each returned object is the full row merged with pending edits,
     * plus a `_dirtyFields` array listing the field names that were changed.
     */
    @api
    getDirtyRows() {
        const dirtyIds = [...this._rowEditMap.keys()];
        return this._internalData
            .filter((r) => dirtyIds.includes(String(r[this.keyField])))
            .map((r) => {
                const id = String(r[this.keyField]);
                const edits = this._rowEditMap.get(id);
                return {
                    ...r,
                    _dirtyFields: edits ? [...edits.keys()] : []
                };
            });
    }

    /**
     * Marks the current edits as saved — clears all dirty state and error indicators.
     * Call this after the parent has successfully persisted the data.
     */
    @api
    markSaved() {
        // Commit pending edits into _data so values persist after clearing the edit map
        this._data = this.enableTreeGrid
            ? this._applyEditsToTree(this._data)
            : this._data.map((row) => {
                  const id = String(row[this.keyField]);
                  const edits = this._rowEditMap.get(id);
                  if (!edits || edits.size === 0) return row;
                  const merged = { ...row };
                  edits.forEach((val, field) => {
                      merged[field] = val;
                  });
                  return merged;
              });
        this._rowEditMap = new Map();
        this._cellErrorMap = new Map();
        this._buildInternalData();
        this._dispatchDirtyStateIfChanged();
    }

    /**
     * Programmatically set the sort column and direction.
     * @param {string} fieldName — column name to sort by
     * @param {'asc'|'desc'} direction — sort direction
     */
    @api
    setSortField(fieldName, direction) {
        if (!fieldName || (direction !== "asc" && direction !== "desc")) return;
        this._sortState = { fieldName, direction };
        this._buildInternalData();
    }

    /** Clears any active sort, restoring original data order. */
    @api
    clearSort() {
        this._sortState = { fieldName: null, direction: null };
        this._buildInternalData();
    }

    /**
     * Sets cell-level validation errors.
     * Replaces the entire error map — pass an empty array to clear all errors.
     *
     * @param {Array<{rowId: string, fieldName: string, message: string}>} errors
     */
    @api
    setCellErrors(errors) {
        this._cellErrorMap = new Map();
        if (Array.isArray(errors)) {
            errors.forEach(({ rowId, fieldName, message }) => {
                this._cellErrorMap.set(`${rowId}::${fieldName}`, message);
            });
        }
        this._rebuildProcessedRows();
    }

    // ═════════════════════════════════════════════════════════════════════
    //  Public API — Tree Methods
    // ═════════════════════════════════════════════════════════════════════

    /** Programmatically toggle expand/collapse of a tree parent row. */
    @api
    toggleTreeRow(rowId) {
        if (!this.enableTreeGrid) return;
        const id = String(rowId);
        if (this._expandedRowIds.has(id)) {
            this._expandedRowIds.delete(id);
        } else {
            this._expandedRowIds.add(id);
        }
        this._buildInternalData();
    }

    /** Expands all tree parent rows. */
    @api
    expandAllTreeRows() {
        if (!this.enableTreeGrid) return;
        const walk = (rows) => {
            rows.forEach((row) => {
                const children = row[this.childrenField];
                if (children?.length) {
                    this._expandedRowIds.add(String(row[this.keyField]));
                    walk(children);
                }
            });
        };
        walk(this._data);
        this._buildInternalData();
    }

    /** Collapses all tree parent rows. */
    @api
    collapseAllTreeRows() {
        if (!this.enableTreeGrid) return;
        this._expandedRowIds.clear();
        this._buildInternalData();
    }

    /**
     * Returns the original tree-structured data with all pending edits applied.
     * Only meaningful in tree mode; falls back to flat getData() otherwise.
     */
    @api
    getTreeData() {
        if (!this.enableTreeGrid) return this.getData();
        return this._applyEditsToTree(this._data);
    }

    /**
     * Exports the current table data (with pending edits) to an Excel file.
     * Supports multi-level headers (merged cells) and tree-grid grouping.
     *
     * @param {Object}  [options]           — export options
     * @param {string}  [options.filename]  — file name (default: 'export.xlsx')
     * @param {string}  [options.sheetName] — sheet name (default: 'Sheet1')
     * @param {boolean} [options.allColumns] — true = export ALL columns incl. collapsed (default: true)
     */
    @api
    async exportToExcel(options = {}) {
        const { filename = "export.xlsx", sheetName = "Sheet1", allColumns = true } = options;

        // Load SheetJS library if not yet loaded
        if (!this._xlsxLoaded) {
            await loadScript(this, SheetJs);
            this._xlsxLoaded = true;
        }
        const XLSX = window.XLSX;

        // ── Resolve columns & data ─────────────────────────────────────────
        const leafCols = allColumns ? this._allLeafColConfig : this._visibleLeafConfig;
        const cols = this._columns; // header tree always uses full column structure

        // Flat rows with edits applied (tree mode: ALL rows expanded)
        let flatRows;
        if (this.enableTreeGrid) {
            const allTree = this._applyEditsToTree(this._data);
            flatRows = this._flattenTreeForExport(allTree, 0);
        } else {
            flatRows = this.getData();
        }

        // ── Build header rows (AOA) + merge descriptors ────────────────────
        const maxDepth = this._calcMaxDepth(cols);
        const { headerAoa, merges } = this._buildExcelHeaders(cols, leafCols, maxDepth);

        // ── Build body rows (AOA) ──────────────────────────────────────────
        const bodyAoa = flatRows.map((row) => leafCols.map((col) => this._exportCellValue(row, col)));

        // ── Assemble worksheet ──────────────────────────────────────────────
        const aoa = [...headerAoa, ...bodyAoa];
        const ws = XLSX.utils.aoa_to_sheet(aoa);

        // Merged cells (multi-level headers)
        if (merges.length > 0) ws["!merges"] = merges;

        // Column widths — auto-fit based on header label + data
        ws["!cols"] = leafCols.map((col, ci) => {
            let maxLen = col.label ? col.label.length : 4;
            bodyAoa.forEach((r) => {
                const v = r[ci];
                const len = v != null ? String(v).length : 0;
                if (len > maxLen) maxLen = len;
            });
            return { wch: Math.min(Math.max(maxLen + 2, 8), 50) };
        });

        // Tree-grid row grouping (Excel outline levels)
        if (this.enableTreeGrid) {
            ws["!rows"] = [];
            // Skip header rows
            for (let i = 0; i < headerAoa.length; i++) {
                ws["!rows"].push({});
            }
            flatRows.forEach((row) => {
                const level = row.__treeLevel || 0;
                ws["!rows"].push(level > 0 ? { outlineLevel: level } : {});
            });
        }

        // ── Write & download ────────────────────────────────────────────────
        const wb = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(wb, ws, sheetName);
        XLSX.writeFile(wb, filename);
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Private State
    // ═══════════════════════════════════════════════════════════════════════

    _columns = [];
    _data = [];
    _internalData = [];

    /** All leaf columns regardless of collapse (source of truth for column config) */
    _allLeafColConfig = [];

    /** Leaf columns currently visible (collapse-aware) */
    @track _visibleLeafConfig = [];

    /** Map<groupName, isCollapsed:boolean> — source of truth for collapse state */
    _collapseState = new Map();

    /** Map<rowId, Map<fieldName, editedValue>> — source of truth for all cell edits */
    _rowEditMap = new Map();

    /** Map<"rowId::fieldName", boolean> — programmatic per-cell disable */
    _cellDisableMap = new Map();

    /** Map<"rowId::fieldName", string> — cell-level validation error messages */
    _cellErrorMap = new Map();

    // (tooltip state removed — managed imperatively by c-rec-table-error-tooltip child component)

    /** Cached Set from disabledRowIds for O(1) lookup — rebuilt in disabledRowIds setter */
    _disabledRowIdSet = new Set();
    _disabledRowIds = [];

    /** Tracks last dispatched dirty state to avoid duplicate dirtystatechange events */
    _lastDirtyState = false;

    /** Map<colName, options[]> — resolved picklist options for combobox columns */
    _picklistOptionsMap = new Map();

    _expandedRowIds = new Set();

    _treeKnownParentIds = new Set();

    /** CMDT-loaded CCY config (symbol etc.) */
    _cmdtCurrencyConfig = {};
    /** User-provided override via @api currencyConfig */
    _userCurrencyConfig = {};
    /** Merged CCY config (CMDT + user-provided currencyConfig) */
    @track _currencyConfig = {};

    /** Column-wide max decimal places per currency column — rebuilt in _buildInternalData / _rebuildVisibleLeaves */
    _maxDecimalMap = new Map();

    _selectedRowIds = [];
    _editingCellKey = null;

    /** Current sort state: { fieldName, direction } — direction is 'asc' | 'desc' | null */
    @track _sortState = { fieldName: null, direction: null };

    /** Whether SheetJS library has been loaded */
    _xlsxLoaded = false;

    /** Built-in export formatter presets, keyed by string name. */
    _builtinExportFormatters = {
        /** Strips HTML tags / extracts text from HTMLElement — returns plain text only. */
        innerText: (value) => {
            if (value instanceof HTMLElement) {
                return value.innerText || value.textContent || "";
            }
            if (typeof value === "string" && value.includes("<")) {
                const tmp = document.createElement("div");
                tmp.innerHTML = value;
                const text = tmp.textContent || "";
                tmp.remove();
                return text;
            }
            return String(value);
        },
        /** Returns the raw value as-is (no String coercion). */
        raw: (value) => value
    };

    /** Pre-hydration state for record-picker labels */
    _isHydrating = false;
    _lookupLabelCache = new Map();
    _hydrateGeneration = 0;

    /** Cached processedRows — rebuilt explicitly via _rebuildProcessedRows() */
    _processedRows = [];
    _isAllSelected = false;
    _isIndeterminate = false;
    _hasData = false;
    /** Cached selectable row count — rebuilt when data or disabledRowIds change */
    _selectableCount = 0;
    /** Flag to recalculate sticky header offsets only on structural header changes */
    _headersDirty = true;

    // ── Auto column width (Canvas measureText) ──────────────────────────
    /** Map<colName, px number> — auto-measured min-width per column */
    _autoWidthMap = new Map();
    /** Cached canvas 2D context for text measurement */
    _measureCtx = null;
    /** Cached body/bold font strings — resolved from actual DOM in renderedCallback */
    _measureFont = '13px "Salesforce Sans", Arial, sans-serif';
    _measureFontBold = 'bold 13px "Salesforce Sans", Arial, sans-serif';

    // ── Virtual scroll state ──────────────────────────────────────────────
    /** Estimated row height in px — used for spacer sizing */
    _VS_ROW_HEIGHT = 32;
    /** Extra rows rendered above/below the viewport to prevent blank flashes */
    _VS_OVERSCAN = 10;
    /** Index of first rendered row (inclusive) */
    _vsStart = 0;
    /** Index of last rendered row (exclusive) */
    _vsEnd = 50;
    /** rAF guard to throttle scroll recalculations */
    _vsRafId = 0;

    // ═══════════════════════════════════════════════════════════════════════
    //  Computed: Header rows
    // ═══════════════════════════════════════════════════════════════════════

    get processedHeaders() {
        const visibleNames = new Set(this._visibleLeafConfig.map((c) => c.name));
        const maxDepth = this._calcMaxDepth(this._columns);

        const rows = Array.from({ length: maxDepth }, (_, i) => ({
            key: `hrow-${i}`,
            cells: []
        }));

        if (!this.hideCheckboxColumn || this.enableTreeGrid) {
            rows[0].cells.push({
                key: "h-__chk",
                isCheckbox: true,
                showCheckbox: !this.hideCheckboxColumn,
                isGroup: false,
                colspan: 1,
                rowspan: maxDepth,
                label: "",
                style: this.enableTreeGrid
                    ? this.hideCheckboxColumn
                        ? "width:2.5rem;min-width:2.5rem;"
                        : "width:4.5rem;min-width:4.5rem;"
                    : "width:2.5rem;min-width:2.5rem;"
            });
        }

        this._fillHeaderCells(this._columns, rows, 0, maxDepth, visibleNames);
        return rows;
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Computed: Body rows (cached — rebuilt via _rebuildProcessedRows)
    // ═══════════════════════════════════════════════════════════════════════

    get processedRows() {
        return this._processedRows;
    }

    /** Rows actually rendered in the DOM — a slice of processedRows with overscan. */
    get visibleRows() {
        return this._processedRows.slice(this._vsStart, this._vsEnd);
    }

    /** Top spacer height to maintain correct scroll position. */
    get _vsTopSpacerStyle() {
        return `height:${this._vsStart * this._VS_ROW_HEIGHT}px;`;
    }

    /** Bottom spacer height to maintain correct scroll dimensions. */
    get _vsBotSpacerStyle() {
        const remaining = Math.max(0, this._processedRows.length - this._vsEnd);
        return `height:${remaining * this._VS_ROW_HEIGHT}px;`;
    }

    get _selectableRows() {
        return this._internalData.filter((r) => !this._disabledRowIdSet.has(String(r[this.keyField])));
    }

    /** Rebuild cached selectable count. Called when _internalData or _disabledRowIdSet changes. */
    _rebuildSelectableCount() {
        const disabledSet = this._disabledRowIdSet;
        this._selectableCount = this._internalData.filter((r) => !disabledSet.has(String(r[this.keyField]))).length;
    }

    get isAllSelected() {
        return this._isAllSelected;
    }

    get isIndeterminate() {
        return this._isIndeterminate;
    }

    get hasData() {
        return this._hasData;
    }

    /**
     * Full rebuild of _processedRows + cached selection state.
     * Called when _internalData, _visibleLeafConfig, _selectedRowIds,
     * _editingCellKey, or disable/error state changes.
     */
    _rebuildProcessedRows() {
        this._rebuildSelectableCount();
        this._updateSelectionFlags();
        this._hasData = this._internalData.length > 0;
        this._processedRows = this._computeProcessedRows();
        this._recalcVirtualWindow();
    }

    /** Update isAllSelected / isIndeterminate from cached _selectableCount. */
    _updateSelectionFlags() {
        const selectedCount = this._selectedRowIds.length;
        this._isAllSelected = this._selectableCount > 0 && selectedCount === this._selectableCount;
        this._isIndeterminate = selectedCount > 0 && selectedCount < this._selectableCount;
    }

    _computeProcessedRows() {
        const selectedSet = new Set(this._selectedRowIds);
        const editKey = this._editingCellKey;
        const leafCols = this._visibleLeafConfig;
        const disabledSet = this._disabledRowIdSet;

        // Row-level checkbox / tree props — constant across all rows
        const showChkColumn = !this.hideCheckboxColumn || this.enableTreeGrid;
        const showCheckbox = !this.hideCheckboxColumn;
        const chkCellClass = showChkColumn
            ? `rec-table__td rec-table__td_chk${this.enableTreeGrid ? " rec-table__td_tree" : ""}`
            : "";
        const isTreeGrid = this.enableTreeGrid;
        const chkCtx = { showChkColumn, showCheckbox, chkCellClass, isTreeGrid };

        // treePadStyle cache (only ~5 unique levels)
        const treePadCache = new Map();

        return this._internalData.map((row) =>
            this._computeSingleProcessedRow(row, selectedSet, editKey, leafCols, disabledSet, chkCtx, treePadCache)
        );
    }

    _computeSingleProcessedRow(row, selectedSet, editKey, leafCols, disabledSet, chkCtx, treePadCache) {
        const id = String(row[this.keyField]);
        const isSelected = selectedSet.has(id);
        const isRowDisabled = disabledSet.has(id);
        const cells = [];

        const treeLevel = row.__treeLevel ?? 0;
        const hasChildren = row.__treeHasChildren ?? false;
        const isExpanded = row.__treeExpanded ?? false;

        leafCols.forEach((col) => {
            const cellKey = `${id}-${col.name}`;
            const disableKey = `${id}::${col.name}`;
            const isDisabled =
                isRowDisabled ||
                col.isDisabled ||
                this._cellDisableMap.has(disableKey) ||
                (col.disableWhen !== null && col.disableWhen(row));
            const rawVal = this._resolvePath(row, col.name) ?? "";
            const canEdit = col.isEditable && !isDisabled;
            const isEditing = canEdit && editKey === cellKey;

            const rowEdits = this._rowEditMap.get(id);
            const isDirty = !!(rowEdits && rowEdits.has(col.name));
            const hasError = this._cellErrorMap.has(disableKey);
            const errorMessage = hasError ? this._cellErrorMap.get(disableKey) : "";
            const isHighlighted = !!col.highlight;

            const displayValue =
                col.renderType === "button"
                    ? col.buttonLabel || ""
                    : col.renderType === "element"
                      ? ""
                      : this._formatValue(rawVal, col.type, col.numberDecimalPlaces);

            cells.push({
                key: cellKey,
                rowId: id,
                fieldName: col.name,
                isDisabled,
                isEditable: canEdit,
                isEditMode: isEditing,
                renderType: col.renderType,
                value: rawVal,
                displayValue,
                title:
                    col.type === "number" && col.numberDecimalPlaces != null
                        ? this._formatValue(rawVal, "number", null)
                        : displayValue,
                inputType: col.inputType,
                badgeClass: ["slds-badge", col.badgeVariantMap?.[rawVal]].filter(Boolean).join(" "),
                symbol: this._resolveSymbol(col, row),
                decimalPoint: this._resolveDecimalPoint(col),
                maxDecimalPoint: this._maxDecimalMap.get(col.name) ?? 2,
                comboboxOptions: col.options ?? this._picklistOptionsMap.get(col.name) ?? [],
                recordPickerConfig: this._resolveRecordPickerConfig(col, row, rowEdits),
                resolvedLabel:
                    col.renderType === "record-picker" && rawVal
                        ? (this._lookupLabelCache.get(String(rawVal).substring(0, 15)) ?? null)
                        : null,
                buttonVariant: col.buttonVariant ?? "neutral",
                buttonIconName: col.buttonIconName ?? "",
                buttonIconSize: col.buttonIconSize ?? "medium",
                isButtonIconOnly: !col.buttonLabel && !!col.buttonIconName,
                urlHref: this._resolveUrlHref(col, row, rawVal),
                isDirty,
                hasError,
                errorMessage,
                cellClass: this._buildCellClass(isDisabled, canEdit, col.renderType, isDirty, hasError, isHighlighted),
                cellAlignStyle: col.cellAlignStyle,
                viewClass: canEdit ? VIEW_CLASS_EDITABLE : VIEW_CLASS_READONLY
            });
        });

        return {
            id,
            rowClass: this._buildRowClass(isSelected, isRowDisabled, treeLevel),
            // ── Row-level checkbox / tree properties ──────────────────────
            showChkColumn: chkCtx.showChkColumn,
            checked: isSelected,
            showCheckbox: chkCtx.showCheckbox,
            chkCellClass: chkCtx.chkCellClass,
            isTreeGrid: chkCtx.isTreeGrid,
            treeLevel,
            hasChildren,
            isExpanded,
            treePadStyle: chkCtx.isTreeGrid
                ? treePadCache.has(treeLevel)
                    ? treePadCache.get(treeLevel)
                    : (() => {
                          const s = `padding-left:${treeLevel * 1.25}rem;`;
                          treePadCache.set(treeLevel, s);
                          return s;
                      })()
                : "",
            treeToggleIcon: hasChildren ? (isExpanded ? "utility:chevrondown" : "utility:chevronright") : null,
            // ── Data cells (checkbox excluded → reference stays stable) ──
            cells
        };
    }

    /**
     * Bulk selection patch (Select All / Deselect All).
     * Updates only row-level checked + rowClass — cells array is never touched,
     * so LWC skips diffing all c-rec-table-cell components entirely.
     */
    _patchSelectionAll() {
        this._updateSelectionFlags();
        const selectedSet = new Set(this._selectedRowIds);
        const disabledSet = this._disabledRowIdSet;

        this._processedRows = this._processedRows.map((pRow) => {
            const isSelected = selectedSet.has(pRow.id);
            const isRowDisabled = disabledSet.has(pRow.id);
            const newRowClass = this._buildRowClass(isSelected, isRowDisabled, pRow.treeLevel);

            if (pRow.rowClass === newRowClass && pRow.checked === isSelected) return pRow;

            return { ...pRow, rowClass: newRowClass, checked: isSelected };
        });
    }

    /**
     * Single-row selection patch. O(1) computation + O(N) shallow copy.
     * Cells array reference is never changed — only row-level checked + rowClass.
     */
    _patchSingleRowSelection(rowId) {
        this._updateSelectionFlags();
        const rowIdx = this._processedRows.findIndex((r) => r.id === rowId);
        if (rowIdx < 0) return;

        const pRow = this._processedRows[rowIdx];
        const isSelected = this._selectedRowIds.includes(rowId);
        const isRowDisabled = this._disabledRowIdSet.has(rowId);
        const newRowClass = this._buildRowClass(isSelected, isRowDisabled, pRow.treeLevel);

        if (pRow.rowClass === newRowClass && pRow.checked === isSelected) return;

        const newArr = [...this._processedRows];
        newArr[rowIdx] = { ...pRow, rowClass: newRowClass, checked: isSelected };
        this._processedRows = newArr;
    }

    /**
     * Updates a single row in _processedRows without recomputing the entire array.
     */
    _patchSingleProcessedRow(rowId) {
        const rowIdx = this._processedRows.findIndex((r) => r.id === rowId);
        const dataRow = this._internalData.find((r) => String(r[this.keyField]) === rowId);
        if (rowIdx < 0 || !dataRow) {
            this._rebuildProcessedRows();
            return;
        }
        const selectedSet = new Set(this._selectedRowIds);
        const showChkColumn = !this.hideCheckboxColumn || this.enableTreeGrid;
        const chkCtx = {
            showChkColumn,
            showCheckbox: !this.hideCheckboxColumn,
            chkCellClass: showChkColumn
                ? `rec-table__td rec-table__td_chk${this.enableTreeGrid ? " rec-table__td_tree" : ""}`
                : "",
            isTreeGrid: this.enableTreeGrid
        };
        const newRow = this._computeSingleProcessedRow(
            dataRow,
            selectedSet,
            this._editingCellKey,
            this._visibleLeafConfig,
            this._disabledRowIdSet,
            chkCtx,
            new Map()
        );
        const newArr = [...this._processedRows];
        newArr[rowIdx] = newRow;
        this._processedRows = newArr;
    }

    // ── Cell descriptor helpers (extracted from IIFEs) ───────────────────

    _resolveSymbol(col, row) {
        if (col.renderType !== "currency") return "";
        const code = col.ccyField ? this._resolvePath(row, col.ccyField) : null;
        return this._currencyConfig[code]?.symbol ?? "";
    }

    _resolveDecimalPoint(col) {
        if (col.renderType !== "currency") return 2;
        return 2;
    }

    _resolveRecordPickerConfig(col, row, rowEdits) {
        const cfg = col.recordPickerConfig;
        if (!cfg) return null;
        const hasRowFilters = cfg.filters?.some((f) => f.filterFromRowField);
        if (!hasRowFilters) return cfg;
        return {
            ...cfg,
            filters: cfg.filters.map((f) => {
                if (!f.filterFromRowField) return f;
                const rowVal =
                    (rowEdits && rowEdits.has(f.filterFromRowField)
                        ? rowEdits.get(f.filterFromRowField)
                        : this._resolvePath(row, f.filterFromRowField)) ?? null;
                const { filterFromRowField: _omit, ...rest } = f;
                return { ...rest, value: rowVal };
            })
        };
    }

    _resolveUrlHref(col, row, rawVal) {
        if (col.renderType !== "url") return null;
        const c = col.urlConfig;
        if (!c) return String(rawVal) || null;
        if (c.urlField) return this._resolvePath(row, c.urlField) ?? null;
        if (c.idField && c.objectApiName) {
            const rid = this._resolvePath(row, c.idField);
            return rid ? `/lightning/r/${c.objectApiName}/${rid}/view` : null;
        }
        return String(rawVal) || null;
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Lifecycle
    // ═══════════════════════════════════════════════════════════════════════

    renderedCallback() {
        const chk = this.template.querySelector(".rec-table__header-chk");
        if (chk) chk.indeterminate = this.isIndeterminate;
        if (this._headersDirty) {
            this._updateStickyHeaderOffsets();
            this._headersDirty = false;
        }
        // Measure actual row height once after first render for accurate spacer sizing
        if (this._hasData && this._VS_ROW_HEIGHT === 32) {
            const firstRow = this.template.querySelector("tbody tr[data-row-id]");
            if (firstRow) {
                const h = firstRow.offsetHeight;
                if (h > 0 && h !== 32) {
                    this._VS_ROW_HEIGHT = h;
                    this._recalcVirtualWindow();
                }
            }
        }
        // Cache actual font from the rendered table for accurate Canvas measureText
        if (this._hasData && !this._fontCached) {
            const td = this.template.querySelector("tbody td");
            if (td) {
                const cs = getComputedStyle(td);
                this._measureFont = `${cs.fontSize} ${cs.fontFamily}`;
                this._measureFontBold = `bold ${cs.fontSize} ${cs.fontFamily}`;
                this._fontCached = true;
            }
        }
    }

    // ── Virtual scroll ────────────────────────────────────────────────────

    /**
     * Scroll handler — recalculates the visible row window.
     * Throttled via requestAnimationFrame to avoid layout thrashing.
     */
    handleTableScroll() {
        if (this._vsRafId) return;
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this._vsRafId = requestAnimationFrame(() => {
            this._vsRafId = 0;
            this._recalcVirtualWindow();
        });
    }

    /**
     * Recompute _vsStart / _vsEnd based on current scroll position.
     * Called from handleTableScroll and after _rebuildProcessedRows.
     */
    _recalcVirtualWindow() {
        const container = this.template.querySelector(".rec-table-scroll");
        if (!container) return;

        const totalRows = this._processedRows.length;
        if (totalRows === 0) {
            this._vsStart = 0;
            this._vsEnd = 0;
            return;
        }

        const rh = this._VS_ROW_HEIGHT || 32;
        const overscan = this._VS_OVERSCAN;

        // Account for sticky thead height
        const thead = this.template.querySelector("thead");
        const theadH = thead ? thead.offsetHeight : 0;

        const scrollTop = Math.max(0, container.scrollTop - theadH);
        const viewportH = container.clientHeight;

        // Cap firstVisible to totalRows-1 so that when data shrinks (e.g. collapseAllTreeRows)
        // but scrollTop hasn't been reset yet, newStart never exceeds newEnd → no blank rows.
        const firstVisible = Math.min(Math.floor(scrollTop / rh), totalRows - 1);
        const visibleCount = Math.ceil(viewportH / rh);

        const newStart = Math.max(0, firstVisible - overscan);
        const newEnd = Math.min(totalRows, firstVisible + visibleCount + overscan);

        if (newStart !== this._vsStart || newEnd !== this._vsEnd) {
            this._vsStart = newStart;
            this._vsEnd = newEnd;
        }
    }

    /**
     * Multi-row sticky header 지원.
     * <thead> 내 각 <tr>의 실제 렌더링 높이를 측정해서
     * --rec-hrow-top CSS 커스텀 프로퍼티를 직접 설정한다.
     * <th>는 top: var(--rec-hrow-top, 0) 으로 이 값을 소비한다.
     */
    _updateStickyHeaderOffsets() {
        const thead = this.template.querySelector("thead");
        if (!thead) return;
        let accumulated = 0;
        thead.querySelectorAll("tr").forEach((tr) => {
            tr.style.setProperty("--rec-hrow-top", `${accumulated}px`);
            accumulated += tr.offsetHeight;
        });
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Event Handlers
    // ═══════════════════════════════════════════════════════════════════════

    handleErrorMouseEnter(event) {
        const rect = event.currentTarget.getBoundingClientRect();
        this.refs.errorTooltip.show(event.currentTarget.dataset.errorMessage, rect.left + 12, rect.bottom + 4);
    }

    handleErrorMouseLeave() {
        this.refs.errorTooltip.hide();
    }

    handleHeaderCheckboxChange(event) {
        const checked = event.target.checked;
        this._selectedRowIds = checked ? this._selectableRows.map((r) => String(r[this.keyField])) : [];
        this._patchSelectionAll();
        this._dispatchRowSelectionEvent();
    }

    handleRowCheckboxChange(event) {
        const rowId = event.currentTarget.dataset.rowId;
        const checked = event.target.checked;
        this._selectedRowIds = checked
            ? [...this._selectedRowIds, rowId]
            : this._selectedRowIds.filter((id) => id !== rowId);
        this._patchSingleRowSelection(rowId);
        this._dispatchRowSelectionEvent();
    }

    /** Toggle collapse for a header group. */
    handleGroupToggle(event) {
        const groupName = event.currentTarget.dataset.groupName;
        if (!this._collapseState.has(groupName)) return;
        const next = !this._collapseState.get(groupName);
        this.setGroupCollapsed(groupName, next);
    }

    /** Click on a sortable column header — cycles: asc → desc → none */
    handleSortClick(event) {
        const fieldName = event.currentTarget.dataset.fieldName;
        if (!fieldName) return;
        let direction;
        if (this._sortState.fieldName === fieldName) {
            direction = this._sortState.direction === "asc" ? "desc" : this._sortState.direction === "desc" ? null : "asc";
        } else {
            direction = "asc";
        }
        this._sortState = { fieldName: direction ? fieldName : null, direction };
        this._buildInternalData();
        this.dispatchEvent(new CustomEvent("sort", { detail: { fieldName, direction } }));
    }

    /** Toggle expand/collapse for a tree parent row. */
    handleTreeToggle(event) {
        event.stopPropagation();
        const rowId = event.currentTarget.dataset.rowId;
        this.toggleTreeRow(rowId);
    }

    // ── Handlers for events bubbled up from recTableCell ─────────────────────

    /**
     * Bubbled from recTableCell. _applyEdit handles data update + cellchange dispatch.
     * stopPropagation prevents the raw event from leaking to the parent.
     */
    handleCellChangeFromCell(event) {
        event.stopPropagation();
        const { rowId, fieldName, value } = event.detail;
        this._applyEdit(rowId, fieldName, value);
    }

    /** Bubbled from recTableCell: button cell was clicked */
    handleCellButtonClick(event) {
        event.stopPropagation();
        const { rowId, fieldName, value } = event.detail;
        const row = this._internalData.find((r) => String(r[this.keyField]) === String(rowId));
        this.dispatchEvent(
            new CustomEvent("cellbuttonclick", {
                detail: { rowId, fieldName, value, row: row ? { ...row } : null },
                bubbles: true,
                composed: true
            })
        );
    }

    /** Bubbled from recTableCell: user clicked an editable text cell → enter edit mode */
    handleCellEditStart(event) {
        event.stopPropagation();
        const { rowId, fieldName } = event.detail;
        this._editingCellKey = `${rowId}-${fieldName}`;
        this._rebuildProcessedRows();
    }

    /** Bubbled from recTableCell: edit was committed or cancelled */
    handleCellEditEnd(event) {
        event.stopPropagation();
        this._editingCellKey = null;
        this._rebuildProcessedRows();
    }

    /**
     * Row click — toggle selection when enableRowClick is true.
     * Ignores clicks originating from interactive elements (inputs, buttons,
     * SLDS checkbox faux spans) so the checkbox handler doesn’t double-fire.
     */
    handleRowClick(event) {
        if (!this.enableRowClick) return;
        const isInteractive = event
            .composedPath()
            .some(
                (el) =>
                    el instanceof Element &&
                    (INTERACTIVE_TAGS.has(el.tagName?.toLowerCase()) || el.classList?.contains("slds-checkbox"))
            );
        if (isInteractive) return;

        const rowId = event.currentTarget.dataset.rowId;
        const isSelected = this._selectedRowIds.includes(rowId);
        this._selectedRowIds = isSelected
            ? this._selectedRowIds.filter((id) => id !== rowId)
            : [...this._selectedRowIds, rowId];
        this._patchSingleRowSelection(rowId);
        this._dispatchRowSelectionEvent();
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  _rowEditMap is the SOLE source of truth for all mutations.
    //  _internalData is derived from _data + _rowEditMap.
    // ═══════════════════════════════════════════════════════════════════════

    _applyEdit(rowId, fieldName, newValue) {
        // Find original row value — in tree mode, search all nested rows
        const allRows = this.enableTreeGrid ? this._extractAllRowsFromTree(this._data) : this._data;
        const origRow = allRows.find((r) => String(r[this.keyField]) === String(rowId));
        if (!origRow) return;
        const oldValue = this._rowEditMap.get(rowId)?.get(fieldName) ?? this._resolvePath(origRow, fieldName);

        if (newValue === oldValue) return;

        // Clear any validation error on this cell (user is correcting it)
        this._cellErrorMap.delete(`${rowId}::${fieldName}`);

        // If the new value matches the original, remove the edit (no longer dirty)
        const originalValue = this._resolvePath(origRow, fieldName);
        if (newValue === originalValue || (newValue === "" && (originalValue === null || originalValue === undefined))) {
            const rowEdits = this._rowEditMap.get(rowId);
            if (rowEdits) {
                rowEdits.delete(fieldName);
                if (rowEdits.size === 0) this._rowEditMap.delete(rowId);
            }
        } else {
            // Persist in edit map
            if (!this._rowEditMap.has(rowId)) this._rowEditMap.set(rowId, new Map());
            this._rowEditMap.get(rowId).set(fieldName, newValue);
        }

        // ── Targeted update for non-tree, non-sorted tables ──────────────
        if (!this.enableTreeGrid && !this._sortState.fieldName) {
            const dataIdx = this._data.findIndex((r) => String(r[this.keyField]) === rowId);
            if (dataIdx >= 0) {
                const edits = this._rowEditMap.get(rowId);
                const merged = { ...this._data[dataIdx] };
                if (edits && edits.size > 0) {
                    edits.forEach((v, f) => {
                        merged[f] = v;
                    });
                }
                const newInternal = [...this._internalData];
                newInternal[dataIdx] = merged;
                this._internalData = newInternal;
            }
            const prevEntries = [...this._maxDecimalMap.entries()];
            this._rebuildMaxDecimalMap();
            const maxDecimalChanged =
                prevEntries.length !== this._maxDecimalMap.size ||
                prevEntries.some(([k, v]) => this._maxDecimalMap.get(k) !== v);
            if (maxDecimalChanged) {
                this._rebuildProcessedRows();
            } else {
                this._patchSingleProcessedRow(rowId);
            }
        } else {
            this._buildInternalData();
        }

        this._dispatchDirtyStateIfChanged();

        const updatedRow = this._internalData.find((r) => String(r[this.keyField]) === String(rowId));
        this.dispatchEvent(
            new CustomEvent("cellchange", {
                detail: { rowId, fieldName, value: newValue, oldValue, row: { ...updatedRow } }
            })
        );
    }

    /**
     * Dispatches dirtystatechange only when dirty state actually transitions.
     * Prevents duplicate events on every keystroke.
     */
    _dispatchDirtyStateIfChanged() {
        const hasDirty = this._rowEditMap.size > 0;
        if (hasDirty === this._lastDirtyState) return;
        this._lastDirtyState = hasDirty;
        // eslint-disable-next-line @lwc/lwc/ssr-no-unsupported-properties
        this.dispatchEvent(new CustomEvent("dirtystatechange", { detail: { hasDirty } }));
    }

    /**
     * Resolve a dot-notation path (e.g. "RefBankTransaction__r.Name") from an object.
     * Flat key takes precedence so that edits stored by _buildInternalData
     * (which writes "A.B" as a single property) are picked up before
     * falling back to nested traversal.
     */
    _resolvePath(obj, path) {
        if (!path || !obj) return undefined;
        // Flat key takes precedence (edit override stored by _buildInternalData)
        if (Object.prototype.hasOwnProperty.call(obj, path)) return obj[path];
        // Fall back to dot-notation traversal for nested source data
        if (path.includes(".")) {
            return path.split(".").reduce((o, key) => (o != null ? o[key] : undefined), obj);
        }
        return undefined;
    }

    /**
     * Merges _data with _rowEditMap → _internalData.
     * Called whenever either source changes.
     */
    _buildInternalData() {
        if (this.enableTreeGrid) {
            this._internalData = this._flattenTree(this._data, 0);
        } else {
            this._internalData = this._data.map((row) => {
                const id = String(row[this.keyField]);
                const edits = this._rowEditMap.get(id);
                if (!edits || edits.size === 0) return { ...row };
                const merged = { ...row };
                edits.forEach((val, field) => {
                    merged[field] = val;
                });
                return merged;
            });
            this._applySortToInternalData();
        }
        this._rebuildMaxDecimalMap();
        this._computeAutoColumnWidths();
        this._rebuildProcessedRows();
    }

    /**
     * Sorts _internalData in place based on current _sortState.
     * Uses a custom sorter from column config if provided, otherwise a type-aware default.
     */
    _applySortToInternalData() {
        const { fieldName, direction } = this._sortState;
        if (!fieldName || !direction) return;
        const col = this._allLeafColConfig.find((c) => c.name === fieldName);
        if (!col || !col.sortable) return;
        const sorter = col.customSorter || this._defaultSorter(col.type);
        const mult = direction === "desc" ? -1 : 1;
        this._internalData.sort((a, b) => mult * sorter(this._resolvePath(a, fieldName), this._resolvePath(b, fieldName)));
    }

    /**
     * Returns a default comparator function for the given column type.
     */
    _defaultSorter(type) {
        return (a, b) => {
            if (a == null && b == null) return 0;
            if (a == null) return -1;
            if (b == null) return 1;
            if (type === "number" || type === "currency") return Number(a) - Number(b);
            if (type === "date") return new Date(a) - new Date(b);
            return String(a).localeCompare(String(b));
        };
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Private — Lookup pre-hydration (방안 C)
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Scans visible record-picker columns and collects unique IDs from the data,
     * grouped by (objectApiName + labelField + subLabel config) to form bulk requests.
     */
    _collectLookupRequests(data) {
        const leafCols = this._visibleLeafConfig;
        const pickerCols = leafCols.filter((c) => c.renderType === "record-picker" && c.recordPickerConfig);
        if (!pickerCols.length || !data.length) return [];

        const groups = new Map();
        for (const col of pickerCols) {
            const cfg = col.recordPickerConfig;
            const gKey =
                `${cfg.objectApiName}::${cfg.labelField || "Name"}` +
                `::${(cfg.subLabelFields || []).join(",")}` +
                `::${cfg.subLabelDelimiter || ""}`;
            if (!groups.has(gKey)) {
                groups.set(gKey, {
                    key: gKey,
                    objectApiName: cfg.objectApiName,
                    labelField: cfg.labelField || "Name",
                    subLabelFields: cfg.subLabelFields || [],
                    subLabelDelimiter: cfg.subLabelDelimiter || "",
                    idSet: new Set()
                });
            }
            const g = groups.get(gKey);
            for (const row of data) {
                const val = this._resolvePath(row, col.name);
                if (val) g.idSet.add(String(val));
            }
        }

        return [...groups.values()]
            .filter((g) => g.idSet.size > 0)
            .map((g) => ({
                key: g.key,
                objectApiName: g.objectApiName,
                labelField: g.labelField,
                subLabelFields: g.subLabelFields,
                subLabelDelimiter: g.subLabelDelimiter,
                ids: [...g.idSet]
            }));
    }

    /**
     * Async pre-hydration: calls getOptionsByIdsBulk, builds _lookupLabelCache,
     * then runs the normal _buildInternalData pipeline.
     * Uses _hydrateGeneration to discard stale responses when data changes rapidly.
     */
    async _preHydrateAndBuild(requests) {
        const gen = ++this._hydrateGeneration;
        try {
            const resultMap = await getOptionsByIdsBulk({
                requestsJson: JSON.stringify(requests)
            });
            if (gen !== this._hydrateGeneration) return; // stale

            this._lookupLabelCache = new Map();
            for (const options of Object.values(resultMap || {})) {
                for (const opt of options) {
                    const id15 = opt.value ? opt.value.substring(0, 15) : null;
                    if (id15) this._lookupLabelCache.set(id15, opt.label);
                }
            }
        } catch (e) {
            if (gen !== this._hydrateGeneration) return;
            console.error("recTable: lookup pre-hydration failed", e);
        }
        this._isHydrating = false;
        this._buildInternalData();
        this._dispatchDirtyStateIfChanged();
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Private — Tree grid helpers
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Recursively flattens tree data into a flat array for rendering.
     * Adds __treeLevel, __treeHasChildren, __treeExpanded metadata.
     * Children of collapsed parents are excluded from the output.
     */
    _flattenTree(rows, level) {
        const result = [];
        const childField = this.childrenField;

        // Sort siblings at this level if sort is active
        let sorted = rows;
        const { fieldName, direction } = this._sortState;
        if (fieldName && direction) {
            const col = this._allLeafColConfig.find((c) => c.name === fieldName);
            if (col?.sortable) {
                const sorter = col.customSorter || this._defaultSorter(col.type);
                const mult = direction === "desc" ? -1 : 1;
                sorted = [...rows].sort(
                    (a, b) => mult * sorter(this._resolvePath(a, fieldName), this._resolvePath(b, fieldName))
                );
            }
        }

        sorted.forEach((row) => {
            const id = String(row[this.keyField]);
            const children = row[childField];
            const hasChildren = Array.isArray(children) && children.length > 0;
            const isExpanded = hasChildren && this._expandedRowIds.has(id);

            // Merge edits
            const edits = this._rowEditMap.get(id);
            const merged = { ...row };
            if (edits && edits.size > 0) {
                edits.forEach((val, field) => {
                    merged[field] = val;
                });
            }
            // Remove children field from flattened row to avoid data leakage
            delete merged[childField];

            merged.__treeLevel = level;
            merged.__treeHasChildren = hasChildren;
            merged.__treeExpanded = isExpanded;
            result.push(merged);

            if (isExpanded && hasChildren) {
                result.push(...this._flattenTree(children, level + 1));
            }
        });
        return result;
    }

    /**
     * Extracts all rows (parent + children) from tree data into a flat array.
     * Used for edit reconciliation when new data is set.
     */
    _extractAllRowsFromTree(rows) {
        const result = [];
        const childField = this.childrenField;
        const walk = (items) => {
            items.forEach((row) => {
                result.push(row);
                const children = row[childField];
                if (Array.isArray(children) && children.length > 0) {
                    walk(children);
                }
            });
        };
        walk(rows);
        return result;
    }

    /**
     * Initialises expand state for newly discovered parent rows.
     * Existing expand states are preserved; new parents default to expanded.
     */
    _initTreeExpandState(rows) {
        const childField = this.childrenField;
        const walk = (items) => {
            items.forEach((row) => {
                const id = String(row[this.keyField]);
                const children = row[childField];
                if (Array.isArray(children) && children.length > 0) {
                    if (!this._treeKnownParentIds.has(id)) {
                        this._treeKnownParentIds.add(id);
                        if (!this.treeDefaultCollapsed) {
                            this._expandedRowIds.add(id);
                        }
                    }
                    walk(children);
                }
            });
        };
        walk(rows);
    }

    /**
     * Applies pending edits to tree-structured data (for markSaved / getTreeData).
     * Returns a deep copy with edits merged.
     */
    _applyEditsToTree(rows) {
        const childField = this.childrenField;
        return rows.map((row) => {
            const id = String(row[this.keyField]);
            const edits = this._rowEditMap.get(id);
            const merged = { ...row };
            if (edits && edits.size > 0) {
                edits.forEach((val, field) => {
                    merged[field] = val;
                });
            }
            const children = row[childField];
            if (Array.isArray(children) && children.length > 0) {
                merged[childField] = this._applyEditsToTree(children);
            }
            return merged;
        });
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Private — Collapse state management
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Walk the column tree and register groups that have collapsible children.
     * Existing entries are NOT overwritten, so runtime state is preserved on columns re-set.
     */
    _initCollapseState(nodes) {
        nodes.forEach((node) => {
            if (node.columns?.length) {
                const hasCollapsible = node.columns.some((c) => c.collapsible);
                if (hasCollapsible && !this._collapseState.has(node.name)) {
                    // Default: expanded (false); honour node.collapsed for initial state
                    this._collapseState.set(node.name, node.collapsed === true);
                }
                this._initCollapseState(node.columns);
            }
        });
    }

    /**
     * Rebuild _visibleLeafConfig based on current collapse state.
     * Collapsed leaves are excluded from rendering but edits are kept in _rowEditMap.
     */
    _rebuildVisibleLeaves() {
        this._visibleLeafConfig = this._extractLeafConfig(this._columns, this._collapseState);
        this._rebuildMaxDecimalMap();
        this._headersDirty = true;
        this._rebuildProcessedRows();
    }

    /**
     * Pre-computes column-wide max decimal places for each currency column.
     * Cached in _maxDecimalMap so processedRows getter never needs to iterate all rows.
     * Must be called after _internalData or _visibleLeafConfig changes.
     */
    _rebuildMaxDecimalMap() {
        this._maxDecimalMap = new Map();
        this._visibleLeafConfig.forEach((col) => {
            if (col.renderType !== "currency") return;
            this._maxDecimalMap.set(col.name, 2);
        });
    }

    /** Dispatches rowselection with lazy selectedRows to avoid eager O(N×cols) spread. */
    _dispatchRowSelectionEvent() {
        const table = this;
        let cached;
        this.dispatchEvent(
            new CustomEvent("rowselection", {
                detail: {
                    get selectedRows() {
                        if (!cached) cached = table.getSelectedRows();
                        return cached;
                    },
                    selectedRowIds: [...this._selectedRowIds]
                }
            })
        );
    }

    /**
     * Resolve picklist options for combobox columns that specify picklistObject + picklistField.
     * Uses imperative Apex call — results stored in _picklistOptionsMap.
     */
    async _resolvePicklistOptions() {
        const leaves = this._allLeafColConfig;
        const promises = leaves
            .filter(
                (col) =>
                    col.renderType === "combobox" &&
                    col.picklistObject &&
                    col.picklistField &&
                    !col.options &&
                    !this._picklistOptionsMap.has(col.name)
            )
            .map(async (col) => {
                try {
                    const options = await getPicklistOptions({
                        objectApiName: col.picklistObject,
                        fieldApiName: col.picklistField
                    });
                    this._picklistOptionsMap.set(col.name, options);
                } catch (e) {
                    console.error(`[recTable] getPicklistOptions error for ${col.name}:`, e);
                }
            });
        if (promises.length === 0) return;
        await Promise.all(promises);
        this._rebuildProcessedRows();
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Private — Auto column width (Canvas measureText)
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Scans ALL rows in _internalData and measures the widest text per column
     * using an offscreen Canvas. Results stored in _autoWidthMap as px values.
     * Skips columns that have an explicit `width` in the column definition.
     * Caps at 400px max-width.
     */
    _computeAutoColumnWidths() {
        const MAX_COL_WIDTH = 400;
        const PAD = 28; // cell padding + border + buffer

        if (!this._measureCtx) {
            this._measureCtx = document.createElement("canvas").getContext("2d");
        }
        const ctx = this._measureCtx;
        const bodyFont = this._measureFont;
        const boldFont = this._measureFontBold;
        const map = new Map();

        for (const col of this._visibleLeafConfig) {
            // Skip types where text measurement is meaningless
            if (["boolean", "button", "custom", "element"].includes(col.renderType)) continue;

            // 1) Header label (bold)
            ctx.font = boldFont;
            let maxW = ctx.measureText(col.label || "").width;

            // 2) All data rows (body font)
            ctx.font = bodyFont;
            for (const row of this._internalData) {
                const raw = this._resolvePath(row, col.name) ?? "";
                let text = String(this._formatValue(raw, col.type, col.numberDecimalPlaces));
                // Currency: prepend symbol
                if (col.renderType === "currency") {
                    const sym = this._resolveSymbol(col, row);
                    if (sym) text = sym + " " + text;
                }
                const w = ctx.measureText(text).width;
                if (w > maxW) maxW = w;
            }

            map.set(col.name, Math.min(Math.ceil(maxW) + PAD, MAX_COL_WIDTH));
        }
        this._autoWidthMap = map;
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Private — Column tree traversal
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Fills header cell arrays, respecting collapse state.
     * A group header with all-hidden children is itself hidden.
     */
    _fillHeaderCells(nodes, rows, depth, maxDepth, visibleNames) {
        nodes.forEach((node) => {
            if (node.columns?.length) {
                const isCollapsible = node.columns.some((c) => c.collapsible);
                const isCollapsed = this._collapseState.get(node.name) === true;
                const visibleLeafCount = this._countVisibleLeaves(node, visibleNames);

                if (visibleLeafCount === 0) return; // entire group hidden

                rows[depth].cells.push({
                    key: `h-${node.name}-${depth}`,
                    isCheckbox: false,
                    isGroup: isCollapsible,
                    isCollapsed,
                    label: node.label,
                    groupName: node.name,
                    colspan: visibleLeafCount,
                    rowspan: 1,
                    style: node.width ? `width:${node.width};` : "",
                    toggleIconName: isCollapsed ? "utility:add" : "utility:dash"
                });
                this._fillHeaderCells(node.columns, rows, depth + 1, maxDepth, visibleNames);
            } else {
                if (!visibleNames.has(node.name)) return; // hidden by collapse

                const isSortable = !!node.sortable;
                const isSorted = isSortable && this._sortState.fieldName === node.name;
                const sortDir = isSorted ? this._sortState.direction : null;

                rows[depth].cells.push({
                    key: `h-${node.name}-${depth}`,
                    isCheckbox: false,
                    isGroup: false,
                    isSortable,
                    isSorted,
                    sortDirection: sortDir,
                    fieldName: node.name,
                    sortIconName:
                        sortDir === "asc"
                            ? "utility:arrowup"
                            : sortDir === "desc"
                              ? "utility:arrowdown"
                              : "utility:arrowdown",
                    sortHeaderClass: `rec-table__th-sortable${isSorted ? " rec-table__th-sortable_active" : ""}`,
                    label: node.label,
                    colspan: 1,
                    rowspan: maxDepth - depth,
                    style: [
                        node.width
                            ? `width:${node.width};min-width:${node.width};`
                            : this._autoWidthMap.has(node.name)
                              ? `min-width:${this._autoWidthMap.get(node.name)}px;`
                              : "",
                        node.align && node.align !== "center" ? `text-align:${node.align};` : ""
                    ]
                        .filter(Boolean)
                        .join("")
                });
            }
        });
    }

    /**
     * Extracts leaf column configs.
     * When collapseState is provided, collapsed collapsible leaves are excluded.
     *
     * Unified model: `type` determines the renderType, `config` holds type-specific settings.
     * Backward-compat: still reads legacy top-level props (renderType, ccyField, options, etc.)
     */
    _extractLeafConfig(nodes, collapseState = null, parentCollapsed = false) {
        return nodes.reduce((acc, node) => {
            if (node.columns?.length) {
                const collapsed = collapseState?.get(node.name) === true;
                return [...acc, ...this._extractLeafConfig(node.columns, collapseState, collapsed)];
            }
            // Skip collapsible leaf if its parent group is collapsed
            if (collapseState && node.collapsible && parentCollapsed) return acc;

            const cfg = node.config || {};
            const type = node.type || "text";
            const editable = !!node.editable;

            // Derive renderType from unified type + editable
            let renderType;
            if (node.renderType) {
                // Legacy: explicit renderType still honoured
                renderType = node.renderType;
            } else if (SPECIALIZED_TYPES.has(type)) {
                renderType = type;
            } else if (editable) {
                renderType = type === "date" ? "date-input" : "input";
            } else {
                renderType = "text";
            }

            const inputType = type === "number" || type === "currency" ? "number" : type === "date" ? "date" : "text";

            // Default alignment per type: number → right, others → center
            const defaultAlign = type === "number" ? "right" : "center";

            acc.push({
                name: node.name,
                label: node.label || node.name,
                type,
                renderType,
                inputType,
                isEditable: editable && (renderType === "text" || renderType === "currency"),
                // combobox / record-picker / boolean: editable:false → disabled (these types have no click-to-edit mode)
                isDisabled: !!node.disabled || (!editable && ["combobox", "record-picker", "boolean"].includes(renderType)),
                disableWhen: typeof node.disableWhen === "function" ? node.disableWhen : null,
                collapsible: !!node.collapsible,
                align: node.align || defaultAlign,
                cellAlignStyle: `text-align:${node.align || defaultAlign};`,

                // Type-specific — from config (preferred) or legacy top-level props
                ccyField: cfg.ccyField || node.ccyField || null,
                options: cfg.options || node.options || null,
                picklistObject: cfg.picklistObject || null,
                picklistField: cfg.picklistField || null,
                badgeVariantMap: cfg.variantMap || node.badgeVariantMap || null,
                recordPickerConfig: cfg.objectApiName
                    ? {
                          objectApiName: cfg.objectApiName,
                          labelField: cfg.labelField || "Name",
                          subLabelFields: cfg.subLabelFields || [],
                          subLabelDelimiter: cfg.subLabelDelimiter || "",
                          placeholder: cfg.placeholder || "Search...",
                          filters: cfg.filters || [],
                          searchOnFocus: !!cfg.searchOnFocus
                      }
                    : node.recordPickerConfig || node.pickerConfig || null,
                buttonLabel: cfg.label || node.buttonLabel || "",
                buttonVariant: cfg.variant || node.buttonVariant || "neutral",
                buttonIconName: cfg.iconName || node.buttonIconName || "",
                buttonIconSize: cfg.size || node.buttonIconSize || "medium",
                urlConfig:
                    cfg.urlField || cfg.idField
                        ? {
                              urlField: cfg.urlField || null,
                              idField: cfg.idField || null,
                              objectApiName: cfg.objectApiName || null
                          }
                        : null,
                numberDecimalPlaces: type === "number" && cfg.decimalPlaces != null ? cfg.decimalPlaces : null,
                sortable: !!node.sortable,
                customSorter: typeof cfg.sorter === "function" ? cfg.sorter : null,
                exportFormatter: node.exportFormatter ?? null,
                highlight: !!node.highlight
            });
            return acc;
        }, []);
    }

    _calcMaxDepth(nodes, depth = 1) {
        return nodes.reduce((max, node) => {
            if (node.columns?.length) return Math.max(max, this._calcMaxDepth(node.columns, depth + 1));
            return max;
        }, depth);
    }

    _countLeaves(node) {
        if (!node.columns?.length) return 1;
        return node.columns.reduce((sum, c) => sum + this._countLeaves(c), 0);
    }

    _countVisibleLeaves(node, visibleNames) {
        if (!node.columns?.length) return visibleNames.has(node.name) ? 1 : 0;
        return node.columns.reduce((sum, c) => sum + this._countVisibleLeaves(c, visibleNames), 0);
    }

    _formatValue(value, type, numberDecimalPlaces) {
        if (value === null || value === undefined || value === "") return "";
        switch (type) {
            case "date":
                try {
                    return new Date(value).toLocaleDateString(USER_LOCALE);
                } catch {
                    return String(value);
                }
            case "number": {
                const num = Number(value);
                if (isNaN(num)) return String(value);
                if (numberDecimalPlaces != null) {
                    return num.toLocaleString(undefined, {
                        minimumFractionDigits: numberDecimalPlaces,
                        maximumFractionDigits: numberDecimalPlaces
                    });
                }
                // Determine decimal places from the raw value to avoid
                // toLocaleString() truncating precision (default max 3 digits).
                const str = String(value);
                const di = str.indexOf(".");
                const fracLen = di >= 0 ? str.length - di - 1 : 0;
                return num.toLocaleString(undefined, {
                    minimumFractionDigits: 0,
                    maximumFractionDigits: Math.max(fracLen, 3)
                });
            }
            case "currency":
                return isNaN(Number(value))
                    ? String(value)
                    : Number(value).toLocaleString(undefined, { minimumFractionDigits: 2 });
            case "boolean":
                return value ? "true" : "false";
            default:
                return String(value);
        }
    }

    _buildRowClass(isSelected, isRowDisabled, treeLevel) {
        return `slds-hint-parent${isSelected ? " slds-is-selected" : ""}${this.enableRowClick ? " rec-table__tr_clickable" : ""}${isRowDisabled ? " rec-table__tr_disabled" : ""}${treeLevel > 0 ? " rec-table__tr_child" : ""}`;
    }

    _buildCellClass(isDisabled, canEdit, renderType, isDirty, hasError, isHighlighted) {
        let cls = "rec-table__td";
        if (renderType === "currency") cls += " rec-table__td_currency" + (canEdit ? " rec-table__td_editable" : "");
        else if (renderType === "input" || renderType === "combobox" || renderType === "record-picker")
            cls += " rec-table__td_input";
        else if (renderType === "button") cls += " rec-table__td_button";
        else if (canEdit) cls += " rec-table__td_editable";
        if (isDisabled) cls += " rec-table__td_disabled";
        if (isHighlighted) cls += " rec-table__td_highlight";
        if (isDirty) cls += " rec-table__td_dirty";
        if (hasError) cls += " rec-table__td_error";
        if (renderType === "url" || renderType === "record-picker") cls += " rec-table__td_linkable";
        return cls;
    }

    // ═══════════════════════════════════════════════════════════════════════
    //  Private — Excel Export helpers
    // ═══════════════════════════════════════════════════════════════════════

    /**
     * Builds multi-level header AOA (array-of-arrays) and SheetJS merge descriptors
     * from the hierarchical column definition.
     */
    _buildExcelHeaders(columns, leafCols, maxDepth) {
        const headerAoa = Array.from({ length: maxDepth }, () => []);
        const merges = [];
        const leafNames = new Set(leafCols.map((c) => c.name));

        const walk = (nodes, depth) => {
            nodes.forEach((node) => {
                if (node.columns?.length) {
                    // Group header — count visible leaves under this group
                    const span = this._countExportLeaves(node, leafNames);
                    if (span === 0) return;

                    const colStart = headerAoa[depth].length;
                    headerAoa[depth].push(node.label || "");
                    // Pad remaining span cells with empty strings
                    for (let i = 1; i < span; i++) headerAoa[depth].push("");

                    // Register merge if spanning multiple columns
                    if (span > 1) {
                        merges.push({ s: { r: depth, c: colStart }, e: { r: depth, c: colStart + span - 1 } });
                    }

                    // Recurse into children
                    walk(node.columns, depth + 1);
                } else {
                    if (!leafNames.has(node.name)) return;

                    const colIdx = headerAoa[depth].length;
                    headerAoa[depth].push(node.label || node.name);

                    // Leaf spanning rows down to maxDepth
                    if (maxDepth - depth > 1) {
                        merges.push({ s: { r: depth, c: colIdx }, e: { r: maxDepth - 1, c: colIdx } });
                    }
                    // Pad the same column index in lower header rows
                    for (let r = depth + 1; r < maxDepth; r++) {
                        headerAoa[r].push("");
                    }
                }
            });
        };

        walk(columns, 0);
        return { headerAoa, merges };
    }

    /**
     * Counts the number of export-eligible leaves under a node.
     */
    _countExportLeaves(node, leafNames) {
        if (!node.columns?.length) return leafNames.has(node.name) ? 1 : 0;
        return node.columns.reduce((sum, c) => sum + this._countExportLeaves(c, leafNames), 0);
    }

    /**
     * Extracts a cell value for Excel export.
     * Returns typed values (number, Date, boolean) so SheetJS can apply proper Excel types.
     */
    _exportCellValue(row, col) {
        const raw = this._resolvePath(row, col.name);
        if (raw === null || raw === undefined || raw === "") return "";

        // ── exportFormatter takes precedence over type-based formatting ──
        if (col.exportFormatter) {
            if (typeof col.exportFormatter === "function") {
                return col.exportFormatter(raw, row);
            }
            const preset = this._builtinExportFormatters[col.exportFormatter];
            if (preset) return preset(raw, row);
        }

        switch (col.type) {
            case "number":
            case "currency": {
                const num = Number(raw);
                return isNaN(num) ? raw : num;
            }
            case "date": {
                try {
                    const d = new Date(raw);
                    if (isNaN(d.getTime())) return raw;
                    const yyyy = d.getFullYear();
                    const mm = String(d.getMonth() + 1).padStart(2, "0");
                    const dd = String(d.getDate()).padStart(2, "0");
                    return `${yyyy}-${mm}-${dd}`;
                } catch {
                    return raw;
                }
            }
            case "boolean":
                return !!raw;
            case "combobox": {
                // Resolve display label from options
                const opts = col.options ?? this._picklistOptionsMap.get(col.name) ?? [];
                const match = opts.find((o) => o.value === raw);
                return match ? match.label : String(raw);
            }
            default:
                return String(raw);
        }
    }

    /**
     * Flattens tree data for export — always fully expanded (all children included).
     * Preserves __treeLevel metadata for Excel outline grouping.
     */
    _flattenTreeForExport(rows, level) {
        const result = [];
        const childField = this.childrenField;
        rows.forEach((row) => {
            const merged = { ...row };
            delete merged[childField];
            merged.__treeLevel = level;
            result.push(merged);

            const children = row[childField];
            if (Array.isArray(children) && children.length > 0) {
                result.push(...this._flattenTreeForExport(children, level + 1));
            }
        });
        return result;
    }
}

// TREE DATA
//data = [
//    {
//        Id: 'R-0001',
//        Name: 'R-0001-251225',
//        Status: 'Confirmed',
//        _children: [
//            { Id: 'RLI-001', Name: 'RLI-00000001', ClosingType: 'P_FA' },
//            { Id: 'RLI-002', Name: 'RLI-00000002', ClosingType: 'P_FA' },
//            { Id: 'RLI-003', Name: 'RLI-00000003', ClosingType: 'P_FA' }
//        ]
//    },
//    {
//        Id: 'R-0002',
//        Name: 'R-0002-251225',
//        Status: 'Draft',
//        _children: [
//            { Id: 'RLI-004', Name: 'RLI-00000004', ClosingType: 'P_FL' }
//        ]
//    }
//];