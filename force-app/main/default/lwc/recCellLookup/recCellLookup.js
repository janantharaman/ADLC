/**
 * @component    recCellLookup
 * @description  Table-cell-safe lookup with a position:fixed dropdown.
 *               Escapes any ancestor overflow:hidden/auto (e.g. table scroll containers).
 *               Uses the same Apex controller as c-com-lookup.
 *
 * @api config       — { objectApiName, labelField, filters?, orderByField? }
 * @api value        — selected Record ID (string | null)
 * @api fieldName    — echoed in the change event
 * @api placeholder  — input placeholder text (default: 'Search…')
 * @api disabled     — boolean
 *
 * @fires lookupchange  — detail: { fieldName, value, label }
 */
import { LightningElement, api } from "lwc";
import search from "@salesforce/apex/REC_Lookup_Ctrl.search";
import getOptionsByIdsBulk from "@salesforce/apex/REC_Lookup_Ctrl.getOptionsByIdsBulk";

const PAGE_SIZE = 50;
const MIN_KW = 2;

// ── Module-level hydration batching ─────────────────────────────────────
// Every recCellLookup instance on the page queues its _hydrate() request
// here.  A single microtask flushes the queue into ONE getOptionsByIdsBulk
// Apex call, eliminating N individual calls when a table renders N cells.
let _pendingBatch = [];
let _flushTimer = null;

function _scheduleFlush() {
    if (_flushTimer !== null) return;
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    _flushTimer = setTimeout(() => {
        _flushTimer = null;
        _flushBatch();
    }, 0);
}

async function _flushBatch() {
    const batch = _pendingBatch;
    _pendingBatch = [];
    if (!batch.length) return;

    // Group by (objectApiName + labelField + subLabelFields + delimiter)
    const groups = new Map();
    for (const entry of batch) {
        const c = entry.config;
        const gKey =
            `${c.objectApiName}::${c.labelField || "Name"}` +
            `::${(c.subLabelFields || []).join(",")}` +
            `::${c.subLabelDelimiter || ""}`;
        if (!groups.has(gKey)) {
            groups.set(gKey, {
                key: gKey,
                objectApiName: c.objectApiName,
                labelField: c.labelField || "Name",
                subLabelFields: c.subLabelFields || [],
                subLabelDelimiter: c.subLabelDelimiter || "",
                idSet: new Set(),
                callbacks: []
            });
        }
        const g = groups.get(gKey);
        g.idSet.add(entry.id);
        g.callbacks.push(entry);
    }

    const requests = [];
    for (const g of groups.values()) {
        requests.push({
            key: g.key,
            objectApiName: g.objectApiName,
            labelField: g.labelField,
            subLabelFields: g.subLabelFields,
            subLabelDelimiter: g.subLabelDelimiter,
            ids: [...g.idSet]
        });
    }

    try {
        const resultMap = await getOptionsByIdsBulk({
            requestsJson: JSON.stringify(requests)
        });
        for (const g of groups.values()) {
            const options = resultMap[g.key] || [];
            const labelById = new Map();
            for (const opt of options) {
                // Apex may return 15-char IDs; normalize to 15-char for matching
                const key15 = opt.value ? opt.value.substring(0, 15) : opt.value;
                labelById.set(key15, opt.label);
            }
            for (const entry of g.callbacks) {
                const key15 = entry.id ? entry.id.substring(0, 15) : entry.id;
                const resolved = labelById.get(key15);
                if (resolved !== undefined) {
                    entry.resolve(resolved);
                }
            }
        }
    } catch (e) {
        console.error("[recCellLookup] bulk hydration error", e);
    }
}

export default class RecCellLookup extends LightningElement {
    @api fieldName;
    @api disabled = false;

    // ── reactive fields (LWC API 39+: all fields are reactive) ──────────────
    keyword = "";
    options = [];
    isOpen = false;
    hasMore = false;
    dropdownStyle = "";
    selectedLabel = "";

    // ── private ──────────────────────────────────────────────────────────────
    _placeholder = "Search…";
    _config = null;
    _value = null;
    _hasSearched = false;
    _afterLabel;
    _afterId;
    _resolvedLabel = null;
    _needsReposition = false;

    // ── @api props ────────────────────────────────────────────────────────────

    /** Pre-resolved label supplied by recTable hydration. Skips per-cell _hydrate(). */
    @api
    get resolvedLabel() {
        return this._resolvedLabel;
    }
    set resolvedLabel(v) {
        this._resolvedLabel = v || null;
        if (v) {
            this.selectedLabel = v;
        }
    }

    @api
    get placeholder() {
        return this.disabled ? "" : this._placeholder;
    }
    set placeholder(v) {
        this._placeholder = v;
    }

    @api
    get config() {
        return this._config;
    }
    set config(v) {
        this._config = v || null;
        // Only hydrate if value is set but label hasn't been resolved yet
        if (v && this._value && !this.selectedLabel) this._hydrate();
    }

    @api
    get value() {
        return this._value;
    }
    set value(v) {
        const next = v || null;
        if (next === this._value) return;
        this._value = next;
        if (next) {
            this._hydrate();
        } else {
            this.selectedLabel = "";
            this.keyword = "";
        }
    }

    // ── getters ───────────────────────────────────────────────────────────────

    get hasSelection() {
        return !!this._value;
    }

    /** URL to the selected record's detail page (Lightning) */
    get recordUrl() {
        const objApi = this._config?.objectApiName;
        const id = this._value;
        if (!objApi || !id) return null;
        return `/lightning/r/${objApi}/${id}/view`;
    }

    get showNoResults() {
        return this.isOpen && this._hasSearched && this.options.length === 0;
    }

    /** searchOnFocus enabled only when config explicitly opts in AND filters are present */
    get _searchOnFocus() {
        const c = this._config;
        return !!c?.searchOnFocus && Array.isArray(c.filters) && c.filters.length > 0;
    }

    // ── handlers ─────────────────────────────────────────────────────────────

    renderedCallback() {
        // Deferred dropdown positioning — runs after backdrop is in the DOM
        if (this._needsReposition && this.isOpen) {
            this._reposition();
            this._needsReposition = false;
        }
    }

    handleInput(event) {
        this.keyword = event.target.value || "";
        // When searchOnFocus opened the dropdown, keep it open while user is typing < MIN_KW
        if (this.keyword.length < MIN_KW) {
            if (this._searchOnFocus && this.isOpen) {
                this._search(true, 0);
            } else {
                this._reset();
            }
            return;
        }
        this._search(true);
    }

    handleKeydown(event) {
        if (event.key === "Escape") this._reset();
    }

    handleSelect(event) {
        const id = event.currentTarget.dataset.id;
        const label = event.currentTarget.dataset.label;
        this._value = id;
        this.selectedLabel = label;
        this.keyword = "";
        this._reset();
        this._fire({ value: id, label });
    }

    /** Clicking the link: let the browser open the new tab (default <a> behavior) */
    handleLinkClick(event) {
        // Stop propagation to prevent cell-level click handlers from interfering
        event.stopPropagation();
    }

    handleClear() {
        this._value = null;
        this.selectedLabel = "";
        this.keyword = "";
        this._reset();
        this._fire({ value: null, label: "" });
    }

    handleClose() {
        this._reset();
    }

    handleLoadMore() {
        this._search(false);
    }

    handleFocus() {
        if (this.isOpen || this.disabled || this._value || !this._searchOnFocus) return;
        this.keyword = "";
        this._search(true, 0);
    }

    // ── private ───────────────────────────────────────────────────────────────

    /**
     * Calculates viewport-relative position for the dropdown.
     * Uses position:fixed so it escapes any overflow:auto scroll container.
     * Opens below when there is enough space, otherwise opens above.
     */
    _reposition() {
        const wrap = this.template.querySelector(".lkp-wrap");
        const backdrop = this.template.querySelector(".lkp-backdrop");
        if (!wrap || !backdrop) return;
        const r = wrap.getBoundingClientRect();
        // Backdrop (position:fixed;inset:0) reveals the containing-block offset
        // introduced by any ancestor with a CSS transform (e.g. lightning-modal).
        const b = backdrop.getBoundingClientRect();
        const left = r.left - b.left;
        const topBelow = r.bottom - b.top + 2;
        const spaceBelow = b.height - (r.bottom - b.top);
        const spaceAbove = r.top - b.top;
        const openDown = spaceBelow >= 160 || spaceBelow >= spaceAbove;
        const minW = Math.max(r.width, 200);
        let style = `position:fixed;left:${left}px;width:${minW}px;z-index:9999999;`;
        style += openDown ? `top:${topBelow}px;` : `bottom:${b.height - (r.top - b.top) + 2}px;`;
        this.dropdownStyle = style;
    }

    async _search(reset, minKw) {
        const c = this._config;
        if (!c?.objectApiName || !c?.labelField) return;
        const effectiveMinKw = minKw ?? MIN_KW;
        if (reset) {
            this.options = [];
            this._afterLabel = undefined;
            this._afterId = undefined;
            this._hasSearched = false;
        }
        try {
            const result =
                (await search({
                    objectApiName: c.objectApiName,
                    labelField: c.labelField,
                    subLabelFields: c.subLabelFields || [],
                    subLabelDelimiter: c.subLabelDelimiter || "",
                    keyword: this.keyword,
                    limitSize: PAGE_SIZE,
                    filters: c.filters || [],
                    minKeywordLen: effectiveMinKw,
                    orderByField: c.orderByField || c.labelField,
                    orderDir: "ASC",
                    afterLabel: this._afterLabel,
                    afterId: this._afterId,
                    recordTypeDeveloperNames: c.recordTypeDeveloperNames || []
                })) || [];
            this._hasSearched = true;
            const rows = Array.isArray(result) ? result : [];
            this.options = reset ? rows : [...this.options, ...rows];
            if (rows.length) {
                const last = rows[rows.length - 1];
                this._afterLabel = last.label;
                this._afterId = last.value;
            }
            this.hasMore = rows.length === PAGE_SIZE;
            this.isOpen = true;
            this.dropdownStyle = "position:fixed;visibility:hidden;z-index:9999999;";
            this._needsReposition = true;
        } catch (e) {
            console.error("[recCellLookup] search error", e);
            this._reset();
        }
    }

    _hydrate() {
        if (!this._value || !this._config?.objectApiName) return;
        if (this.selectedLabel) return; // Already resolved (e.g. pre-hydrated by recTable)
        _pendingBatch.push({
            config: this._config,
            id: this._value,
            resolve: (label) => {
                this.selectedLabel = label;
            }
        });
        _scheduleFlush();
    }

    _reset() {
        this.isOpen = false;
        this.options = [];
        this.hasMore = false;
        this._hasSearched = false;
        this._afterLabel = undefined;
        this._afterId = undefined;
    }

    _fire(payload) {
        this.dispatchEvent(
            new CustomEvent("lookupchange", {
                detail: { fieldName: this.fieldName, ...payload },
                bubbles: true,
                composed: true
            })
        );
    }
}