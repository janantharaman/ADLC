/**
 * REC_SelectorBase — Abstract base implementation of REC_ISelector.
 *
 * Provides all the boilerplate that every concrete Selector would otherwise
 * duplicate:
 *   - Field-token → accessible-name conversion
 *   - CSV field list generation
 *   - REC_FilterBuilder-powered dynamic query
 *   - Id-based query
 *
 * Concrete subclasses only need to override:
 *   - getSObjectType()
 *   - getDefaultFields()
 *   - getUpdatableFields()     (optional — defaults to empty list)
 *   - getDefaultOrderBy()      (optional — defaults to 'Name DESC')
 */
public abstract inherited sharing class REC_SelectorBase implements REC_ISelector {
    // ═════════════════════════════════════════════════════════════════════════
    //  Abstract — must be overridden
    // ═════════════════════════════════════════════════════════════════════════

    public abstract Schema.SObjectType getSObjectType();
    public abstract List<Schema.SObjectField> getDefaultFields();

    // ═════════════════════════════════════════════════════════════════════════
    //  Virtual — may be overridden
    // ═════════════════════════════════════════════════════════════════════════

    /** Fields the UI is allowed to write back. Override per object. */
    public virtual List<Schema.SObjectField> getUpdatableFields() {
        return new List<Schema.SObjectField>();
    }

    /** Lightweight field set for counterpart/summary queries. Override per object. */
    public virtual List<Schema.SObjectField> getCompactFields() {
        return new List<Schema.SObjectField>();
    }

    /** Default ORDER BY clause. Override if a different sort is needed. */
    protected virtual String getDefaultOrderBy() {
        return 'Name DESC';
    }

    /** Default LIMIT. Override to change. */
    protected virtual Integer getDefaultLimit() {
        return 2000;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Concrete — inherited by all subclasses
    // ═════════════════════════════════════════════════════════════════════════

    /** Accessible field API names derived from getDefaultFields(). */
    public List<String> getFieldNames() {
        return toAccessibleNames(getDefaultFields());
    }

    /** Comma-separated field list for SOQL SELECT. */
    public String getFieldCsv() {
        return String.join(getFieldNames(), ', ');
    }

    /** Accessible field API names derived from getUpdatableFields(). */
    public List<String> getUpdatableFieldNames() {
        return toAccessibleNames(getUpdatableFields());
    }

    /** Accessible field API names derived from getCompactFields(). */
    public List<String> getCompactFieldNames() {
        return toAccessibleNames(getCompactFields());
    }

    /** Comma-separated compact field list for SOQL SELECT. */
    public String getCompactFieldCsv() {
        return String.join(getCompactFieldNames(), ', ');
    }

    /**
     * Returns default field names prefixed with the child-to-parent relationship
     * name derived from the given lookup / master-detail field token.
     *
     * The relationship name is resolved automatically via
     * DescribeFieldResult.getRelationshipName(), so callers never need to
     * hard-code '__r' strings.
     *
     * Example:
     *   REC_BankTransactionSelector.getInstance()
     *       .getFieldNamesWithRelationship(ReconciliationLineItem__c.RefBankTransaction__c);
     *   // → ['RefBankTransaction__r.Id', 'RefBankTransaction__r.Name', …]
     */
    public List<String> getFieldNamesWithRelationship(Schema.SObjectField lookupFieldToken) {
        String relationshipName = lookupFieldToken.getDescribe().getRelationshipName();

        if (String.isBlank(relationshipName)) {
            throw new REC_SelectorBaseException(
                'Field ' + lookupFieldToken.getDescribe().getName() + ' is not a relationship field'
            );
        }

        List<String> prefixed = new List<String>();
        for (String fn : getFieldNames()) {
            prefixed.add(relationshipName + '.' + fn);
        }
        return prefixed;
    }

    /**
     * Returns a map of field API name → user-language label for every
     * field declared in getDefaultFields().
     */
    public Map<String, String> getFieldLabelMap() {
        Map<String, String> labels = new Map<String, String>();
        for (Schema.SObjectField f : getDefaultFields()) {
            Schema.DescribeFieldResult d = f.getDescribe();
            labels.put(d.getName(), d.getLabel());
        }
        return labels;
    }

    /** Dynamic-filter query powered by REC_FilterBuilder. */
    public List<SObject> queryByFilter(String filtersJson) {
        return queryByFilter(filtersJson, null);
    }

    /**
     * Dynamic-filter query with additional UI column fields.
     *
     * Column fields supplied by the LWC are validated and classified:
     *   - Relationship (dot-notation) fields → appended to SELECT
     *   - Direct fields → must already exist in getDefaultFields(); throws if missing
     *
     * Relationship fields are collected from three sources:
     *   1. Filter keys — auto-extracted by REC_FilterBuilder (e.g. 'RefClaim__r.LossDate__c')
     *   2. columnFieldsJson — JSON string array supplied by LWC (table column + filter field names)
     *
     * @param filtersJson        JSON filter string from LWC
     * @param columnFieldsJson   JSON string array of UI column field paths (nullable)
     */
    public List<SObject> queryByFilter(String filtersJson, String columnFieldsJson) {
        REC_FilterBuilder fb = new REC_FilterBuilder(filtersJson, getSObjectType());

        // Merge relationship fields: auto-detected from filters + explicitly requested
        Set<String> relFields = fb.getRelationshipFields();
        if (String.isNotBlank(columnFieldsJson)) {
            List<String> uiFields = (List<String>) JSON.deserialize(columnFieldsJson, List<String>.class);

            Set<String> defaultFieldNames = new Set<String>();
            for (String fn : getFieldNames()) {
                defaultFieldNames.add(fn.toLowerCase());
            }

            List<String> missingFields = new List<String>();

            for (String field : uiFields) {
                if (field.contains('.')) {
                    relFields.add(field);
                } else if (!defaultFieldNames.contains(field.toLowerCase())) {
                    missingFields.add(field);
                }
            }

            if (!missingFields.isEmpty()) {
                throw new REC_SelectorBaseException(
                    'The following fields are referenced by the UI but not declared in ' +
                        getSObjectType().getDescribe().getName() +
                        ' selector\'s getDefaultFields(): ' +
                        String.join(missingFields, ', ')
                );
            }
        }

        // Build SELECT: default fields + relationship fields
        String fieldsCsv = getFieldCsv();
        if (!relFields.isEmpty()) {
            fieldsCsv += ', ' + String.join(new List<String>(relFields), ', ');
        }

        String soql = String.format(
            'SELECT {0} FROM {1} WHERE {2} ORDER BY {3} LIMIT {4}',
            new List<String>{
                fieldsCsv,
                getSObjectType().getDescribe().getName(),
                fb.toWhereClause(),
                getDefaultOrderBy(),
                String.valueOf(getDefaultLimit())
            }
        );

        System.debug('queryByFilter ::: ' + soql);

        return Database.queryWithBinds(soql, fb.getBinds(), AccessLevel.USER_MODE);
    }

    /**
     * Queries records by a set of Ids using the default field list.
     */
    public List<SObject> queryByIds(Set<Id> recordIds) {
        String soql = String.format(
            'SELECT {0} FROM {1} WHERE Id IN :recordIds ORDER BY {2} LIMIT {3}',
            new List<String>{
                getFieldCsv(),
                getSObjectType().getDescribe().getName(),
                getDefaultOrderBy(),
                String.valueOf(getDefaultLimit())
            }
        );

        return Database.queryWithBinds(soql, new Map<String, Object>{ 'recordIds' => recordIds }, AccessLevel.USER_MODE);
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Utility
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Converts SObjectField tokens to their API names, enforcing FLS accessibility.
     * Throws REC_SelectorBaseException if a field is not accessible by the running user.
     */
    private static List<String> toAccessibleNames(List<Schema.SObjectField> tokens) {
        List<String> names = new List<String>();

        for (Schema.SObjectField f : tokens) {
            Schema.DescribeFieldResult d = f.getDescribe();
            if (!d.isAccessible()) {
                throw new REC_SelectorBaseException('Field ' + d.getName() + ' is not accessible');
            }
            names.add(d.getName());
        }

        return names;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Exception
    // ═════════════════════════════════════════════════════════════════════════

    public class REC_SelectorBaseException extends Exception {
    }
}