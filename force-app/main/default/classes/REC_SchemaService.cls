/**
 * REC_SchemaService — Provides translated field / object labels from Schema describe.
 *
 * Called by LWC components to replace hard-coded column & filter labels with
 * user-language-aware values resolved at runtime via DescribeFieldResult.getLabel().
 *
 * Relationship field paths (e.g. "RefBankTransaction__r.Currency__c") are resolved
 * by walking the lookup chain: base SObject → lookup field → referenced SObject → target field.
 */
public with sharing class REC_SchemaService {
    /**
     * Returns a map of field-path → translated label for the given SObject and field paths.
     *
     * Supports both direct fields ("ClosingType__c") and relationship fields
     * ("RefBankTransaction__r.Currency__c").
     *
     * @param objectApiName  API name of the base SObject (e.g. "ReconciliationLineItem__c")
     * @param fieldPaths     List of field paths used in LWC column / filter definitions
     * @return Map<String, String>  field-path (as supplied) → translated label
     */
    @AuraEnabled(Cacheable=true)
    public static Map<String, String> getFieldLabels(String objectApiName, List<String> fieldPaths) {
        if (String.isBlank(objectApiName) || fieldPaths == null || fieldPaths.isEmpty()) {
            return new Map<String, String>();
        }

        Schema.SObjectType baseType = Schema.getGlobalDescribe().get(objectApiName);
        if (baseType == null) {
            throw new AuraHandledException('Unknown SObject: ' + objectApiName);
        }

        Map<String, Schema.SObjectField> baseFieldMap = baseType.getDescribe().fields.getMap();

        // Pre-build relationship name → SObjectField map for the base object
        Map<String, Schema.SObjectField> relNameToField = new Map<String, Schema.SObjectField>();
        for (Schema.SObjectField f : baseFieldMap.values()) {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            String relName = dfr.getRelationshipName();
            if (relName != null) {
                relNameToField.put(relName.toLowerCase(), f);
            }
        }

        // Cache for referenced SObject field maps (avoids repeated describes)
        Map<String, Map<String, Schema.SObjectField>> refFieldMapCache = new Map<String, Map<String, Schema.SObjectField>>();

        Map<String, String> result = new Map<String, String>();

        for (String path : fieldPaths) {
            if (String.isBlank(path)) {
                continue;
            }

            String label = resolveLabel(path, baseFieldMap, relNameToField, refFieldMapCache);
            if (label != null) {
                result.put(path, label);
            }
        }

        return result;
    }

    /**
     * Returns the translated label for a single SObject.
     */
    @AuraEnabled(Cacheable=true)
    public static String getObjectLabel(String objectApiName) {
        if (String.isBlank(objectApiName)) {
            return null;
        }
        Schema.SObjectType sot = Schema.getGlobalDescribe().get(objectApiName);
        if (sot == null) {
            throw new AuraHandledException('Unknown SObject: ' + objectApiName);
        }
        return sot.getDescribe().getLabel();
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Private helpers
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Resolves a single field path to its translated label.
     *
     * Direct field:       "ClosingType__c"  → base SObject describe
     * Relationship field: "RefBankTransaction__r.Currency__c"
     *   → find lookup field whose relationshipName == "RefBankTransaction__r" (without __r suffix
     *     matched case-insensitively)
     *   → getReferenceTo()[0] → describe that SObject → find "Currency__c" label
     */
    private static String resolveLabel(
        String path,
        Map<String, Schema.SObjectField> baseFieldMap,
        Map<String, Schema.SObjectField> relNameToField,
        Map<String, Map<String, Schema.SObjectField>> refFieldMapCache
    ) {
        if (!path.contains('.')) {
            // Direct field on the base SObject
            Schema.SObjectField field = baseFieldMap.get(path.toLowerCase());
            if (field == null) {
                return null;
            }
            return field.getDescribe().getLabel();
        }

        // Relationship field — split into segments and walk the chain
        List<String> segments = path.split('\\.');
        Map<String, Schema.SObjectField> currentFieldMap = baseFieldMap;
        Map<String, Schema.SObjectField> currentRelMap = relNameToField;

        // Walk all relationship segments except the last (which is the leaf field)
        for (Integer i = 0; i < segments.size() - 1; i++) {
            String relSegment = segments[i];
            Schema.SObjectField lookupField = currentRelMap.get(relSegment.toLowerCase());
            if (lookupField == null) {
                return null;
            }

            List<Schema.SObjectType> refs = lookupField.getDescribe().getReferenceTo();
            if (refs == null || refs.isEmpty()) {
                return null;
            }

            // Use the first referenced SObject (handles polymorphic lookups by taking primary)
            Schema.SObjectType refType = refs[0];
            String refTypeName = refType.getDescribe().getName().toLowerCase();

            if (!refFieldMapCache.containsKey(refTypeName)) {
                refFieldMapCache.put(refTypeName, refType.getDescribe().fields.getMap());
            }
            currentFieldMap = refFieldMapCache.get(refTypeName);

            // Rebuild relationship map for the next hop (if multi-level)
            if (i < segments.size() - 2) {
                currentRelMap = new Map<String, Schema.SObjectField>();
                for (Schema.SObjectField f : currentFieldMap.values()) {
                    Schema.DescribeFieldResult dfr = f.getDescribe();
                    String rn = dfr.getRelationshipName();
                    if (rn != null) {
                        currentRelMap.put(rn.toLowerCase(), f);
                    }
                }
            }
        }

        // Resolve the leaf field
        String leafField = segments[segments.size() - 1];
        Schema.SObjectField targetField = currentFieldMap.get(leafField.toLowerCase());
        if (targetField == null) {
            return null;
        }
        return targetField.getDescribe().getLabel();
    }
}