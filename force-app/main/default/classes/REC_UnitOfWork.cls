/**
 * REC_UnitOfWork — Common DML utilities for the REC module.
 *
 * Centralises the duplicated JSON→SObject parsing and partial-success
 * Database.update pattern that was copy-pasted across every Ctrl class.
 */
public inherited sharing class REC_UnitOfWork {
    // ═════════════════════════════════════════════════════════════════════════
    //  JSON → SObject Parsing
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Deserialises dirty-row JSON from recTable.getDirtyRows() into concrete
     * SObject records, populating only the supplied updatable fields.
     *
     * @param rowsJson        JSON array string from the LWC
     * @param sobjType        Schema.SObjectType of the target object
     * @param updatableFields List of SObjectField tokens that may be written
     * @return                Typed SObject list ready for DML
     */
    public static List<SObject> parseRows(
        String rowsJson,
        Schema.SObjectType sobjType,
        List<Schema.SObjectField> updatableFields
    ) {
        List<Object> rawRows = (List<Object>) JSON.deserializeUntyped(rowsJson);
        List<SObject> records = new List<SObject>();

        for (Object rawRow : rawRows) {
            Map<String, Object> row = (Map<String, Object>) rawRow;

            SObject rec = sobjType.newSObject();

            // Extract record Id (LWC may serialise as 'Id' or 'id')
            rec.put('Id', (Id) String.valueOf(row.containsKey('Id') ? row.get('Id') : row.get('id')));

            // Set only updatable fields
            for (Schema.SObjectField ft : updatableFields) {
                String fn = ft.getDescribe().getName();
                if (row.containsKey(fn)) {
                    rec.put(fn, row.get(fn));
                }
            }

            records.add(rec);
        }

        return records;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Partial-Success DML
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Runs Database.update with allOrNone = false and returns a SaveResponse
     * with per-cell error mapping.
     */
    public static REC_TableHelper.SaveResponse updatePartial(List<SObject> records) {
        List<Database.SaveResult> results = Database.update(records, false);
        return REC_TableHelper.buildSaveResponse(records, results);
    }

    /**
     * Runs Database.insert with allOrNone = false and returns a SaveResponse
     * with per-cell error mapping.
     */
    public static REC_TableHelper.SaveResponse insertPartial(List<SObject> records) {
        List<Database.SaveResult> results = Database.insert(records, false);
        return REC_TableHelper.buildSaveResponse(records, results);
    }
}