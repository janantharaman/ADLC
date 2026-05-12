/**
 * REC_TableHelper
 *
 * Shared utilities for LWC table controllers.
 *
 * Provides:
 *  - FilterSpec    : Fluent builder for queryByFilter-compatible JSON filters.
 *  - SaveResponse  : AuraEnabled wrapper returned to the LWC after a save call.
 *  - CellError     : Per-cell error descriptor (rowId + fieldName + message).
 *  - buildSaveResponse() : Converts Database.SaveResult list → SaveResponse,
 *                          mapping field-level DML errors down to individual cells.
 */
public with sharing class REC_TableHelper {
    // ═════════════════════════════════════════════════════════════════════════
    //  Filter Builder — Fluent API for programmatic queryByFilter usage
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Creates a new empty FilterSpec.
     *
     * Usage:
     *   String json = REC_TableHelper.filter()
     *       .eq('RefReconciliation__c', reconId)
     *       .notNull('RefSettlementLineItem__c')
     *       .toJson();
     */
    public static FilterSpec filter() {
        return new FilterSpec();
    }

    /**
     * Fluent filter builder that produces a JSON string compatible with
     * REC_FilterBuilder / REC_SelectorBase.queryByFilter().
     */
    public class FilterSpec {
        private final Map<String, Object> filterMap = new Map<String, Object>();

        /** field = value (equality, IN for lists) */
        public FilterSpec eq(String field, Object value) {
            filterMap.put(field, value);
            return this;
        }

        /** field IN (values) — alias for eq() with a list */
        public FilterSpec isIn(String field, List<Object> values) {
            filterMap.put(field, values);
            return this;
        }

        /** field IN (ids) — convenience overload for Id lists */
        public FilterSpec isIn(String field, List<Id> values) {
            filterMap.put(field, values);
            return this;
        }

        /** field NOT IN (values) */
        public FilterSpec notIn(String field, List<String> values) {
            filterMap.put(field + '__exclude', values);
            return this;
        }

        /** field >= from AND field <= to */
        public FilterSpec between(String field, Object fromVal, Object toVal) {
            Map<String, Object> range = new Map<String, Object>();
            if (fromVal != null)
                range.put('from', fromVal);
            if (toVal != null)
                range.put('to', toVal);
            filterMap.put(field, range);
            return this;
        }

        /** field != null */
        public FilterSpec notNull(String field) {
            filterMap.put(field + '__notnull', true);
            return this;
        }

        /** OR group — (sub1 OR sub2) */
        public FilterSpec orGroup(FilterSpec sub1, FilterSpec sub2) {
            List<Object> orList = getOrCreateOrList();
            orList.add(sub1.filterMap);
            orList.add(sub2.filterMap);
            return this;
        }

        /** OR group — varargs-style with list */
        public FilterSpec orGroup(List<FilterSpec> subs) {
            List<Object> orList = getOrCreateOrList();
            for (FilterSpec sub : subs) {
                orList.add(sub.filterMap);
            }
            return this;
        }

        /** Serializes to JSON string for queryByFilter(). */
        public String toJson() {
            return JSON.serialize(filterMap);
        }

        private List<Object> getOrCreateOrList() {
            List<Object> orList;
            if (filterMap.containsKey('__or')) {
                orList = (List<Object>) filterMap.get('__or');
            } else {
                orList = new List<Object>();
                filterMap.put('__or', orList);
            }
            return orList;
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  DML Result Builder
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Converts Database.SaveResult list into a SaveResponse with per-cell error mapping.
     *
     * Field-specific DML errors (validation rules, triggers, required-field violations, etc.)
     * are mapped to CellError with the exact field name so the LWC table can highlight the
     * responsible cell.  Row-level errors (no specific field) use fieldName = null and are
     * typically surfaced via a toast in the parent component.
     *
     * @param records   SObjects passed to Database.update — used to look up record Ids by index.
     * @param results   Parallel list of SaveResult returned by Database.update(records, false).
     * @return          SaveResponse with success flag, counts, and per-cell errors.
     */
    public static SaveResponse buildSaveResponse(List<SObject> records, List<Database.SaveResult> results) {
        List<CellError> cellErrors = new List<CellError>();
        Integer successCount = 0;
        Integer errorCount = 0;

        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult sr = results[i];
            String rowId = (String) records[i].get('Id');

            if (sr.isSuccess()) {
                successCount++;
                continue;
            }

            errorCount++;
            for (Database.Error err : sr.getErrors()) {
                List<String> fields = err.getFields();

                if (fields != null && !fields.isEmpty()) {
                    // Field-specific — one CellError per affected field
                    for (String fieldName : fields) {
                        cellErrors.add(new CellError(rowId, fieldName, err.getMessage()));
                    }
                } else {
                    // Row-level error — no specific field
                    cellErrors.add(new CellError(rowId, null, err.getMessage()));
                }
            }
        }

        return new SaveResponse(successCount, errorCount, cellErrors);
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Response Wrappers
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Top-level response wrapper returned from any @AuraEnabled save method.
     *
     * Fields:
     *   success      — true only when errorCount == 0
     *   successCount — number of rows persisted successfully
     *   errorCount   — number of rows that failed
     *   cellErrors   — list of per-cell errors to be passed to recTable.setCellErrors()
     */
    public class SaveResponse {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public Integer successCount;
        @AuraEnabled
        public Integer errorCount;
        @AuraEnabled
        public List<CellError> cellErrors;

        public SaveResponse(Integer successCount, Integer errorCount, List<CellError> cellErrors) {
            this.success = (errorCount == 0);
            this.successCount = successCount;
            this.errorCount = errorCount;
            this.cellErrors = cellErrors;
        }
    }

    /**
     * Describes a single cell-level error.
     * Matches the shape expected by recTable.setCellErrors():
     *   { rowId: string, fieldName: string, message: string }
     *
     * fieldName may be null for row-level errors that cannot be attributed to a specific field.
     */
    public class CellError {
        @AuraEnabled
        public String rowId;
        @AuraEnabled
        public String fieldName;
        @AuraEnabled
        public String message;

        public CellError(String rowId, String fieldName, String message) {
            this.rowId = rowId;
            this.fieldName = fieldName;
            this.message = message;
        }
    }
}