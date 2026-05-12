/**
 * recSchemaService — Shared utility for loading translated field labels from
 * Apex Schema describe and merging them into column / filter definitions.
 *
 * Usage:
 *   import { extractFieldPaths, loadFieldLabels, applyLabels } from "c/recSchemaService";
 *
 *   // In connectedCallback:
 *   const paths = [
 *       ...extractFieldPaths(this._sliColumnDefs),
 *       ...extractFieldPaths(this._sliFilterDefs)
 *   ];
 *   this._labelMap = await loadFieldLabels("SettlementLineItem__c", paths);
 *
 *   // In getter:
 *   get sliColumns() { return applyLabels(this._sliColumnDefs, this._labelMap); }
 */
import apexGetFieldLabels from "@salesforce/apex/REC_SchemaService.getFieldLabels";

// Module-level cache: objectApiName → Map<fieldPath, label>
const _cache = new Map();

/**
 * Recursively extracts all leaf-column field paths from a column / filter
 * definition array.  Skips button-type columns and internal names prefixed
 * with "_".  Includes filter `config.fromField` / `config.toField` for
 * date-between filters.
 *
 * @param {Object[]} defs — column or filter definition array
 * @returns {string[]} — unique field path strings
 */
export function extractFieldPaths(defs) {
    const paths = new Set();
    const walk = (items) => {
        if (!Array.isArray(items)) return;
        for (const item of items) {
            if (item.columns) {
                walk(item.columns);
            } else if (item.name && item.type !== "button" && !item.name.startsWith("_")) {
                paths.add(item.name);
            }
            // date-between filter fields
            if (item.config?.fromField) paths.add(item.config.fromField);
            if (item.config?.toField) paths.add(item.config.toField);
        }
    };
    walk(defs);
    return [...paths];
}

/**
 * Loads translated field labels for the given SObject from Apex.
 * Results are cached at module level so repeated calls for the same
 * object (even across component instances) return instantly.
 *
 * @param {string} objectApiName — e.g. "ReconciliationLineItem__c"
 * @param {string[]} fieldPaths  — field paths from extractFieldPaths
 * @returns {Promise<Object>}    — plain object { fieldPath: label }
 */
export async function loadFieldLabels(objectApiName, fieldPaths) {
    if (!objectApiName || !fieldPaths?.length) return {};

    // Determine which paths are missing from cache
    let cached = _cache.get(objectApiName);
    const missing = cached ? fieldPaths.filter((p) => !(p in cached)) : fieldPaths;

    if (missing.length) {
        const result = await apexGetFieldLabels({ objectApiName, fieldPaths: missing });
        if (!cached) {
            cached = {};
            _cache.set(objectApiName, cached);
        }
        Object.assign(cached, result);
    }

    return cached || {};
}

/**
 * Returns a new column / filter definition array with `label` populated
 * from the label map.
 *
 * Rules:
 *  - If `col.label` is already set → keep it (explicit override).
 *  - If `col.columns` exists (group header) → keep its label, recurse children.
 *  - Otherwise → set `col.label` from `labelMap[col.name]`.
 *
 * @param {Object[]} defs      — original definitions (NOT mutated)
 * @param {Object}   labelMap  — { fieldPath: translatedLabel }
 * @returns {Object[]}         — new array with labels applied
 */
export function applyLabels(defs, labelMap) {
    if (!defs || !labelMap) return defs;

    return defs.map((def) => {
        const copy = { ...def };

        if (copy.columns) {
            // Group header — preserve its own label, recurse children
            copy.columns = applyLabels(copy.columns, labelMap);
        } else if (!copy.label && copy.name && labelMap[copy.name]) {
            copy.label = labelMap[copy.name];
        }

        return copy;
    });
}