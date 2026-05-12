/**
 * REC_ISelector — Interface contract for the Selector layer.
 *
 * Every object-specific Selector implements this interface so that
 * infrastructure code can work with any Selector generically.
 */
public interface REC_ISelector {
    /** SObjectType this selector operates on. */
    Schema.SObjectType getSObjectType();

    /** Default field tokens used for standard queries. */
    List<Schema.SObjectField> getDefaultFields();

    /** Field tokens the UI is allowed to write back. */
    List<Schema.SObjectField> getUpdatableFields();

    /** Accessible field API names derived from getDefaultFields(). */
    List<String> getFieldNames();

    /** Comma-separated field list string for SOQL SELECT clause. */
    String getFieldCsv();

    /** Accessible field API names derived from getUpdatableFields(). */
    List<String> getUpdatableFieldNames();

    /**
     * Returns default field names prefixed with the relationship name
     * derived from the given lookup/master-detail field token.
     * e.g. passing ReconciliationLineItem__c.RefBankTransaction__c
     *   yields ['RefBankTransaction__r.Id', 'RefBankTransaction__r.Name', …]
     */
    List<String> getFieldNamesWithRelationship(Schema.SObjectField lookupFieldToken);

    /** Map of field API name → translated label from Schema describe. */
    Map<String, String> getFieldLabelMap();

    /** Dynamic-filter query using REC_FilterBuilder. */
    List<SObject> queryByFilter(String filtersJson);

    /** Dynamic-filter query with UI column field validation (JSON string array). */
    List<SObject> queryByFilter(String filtersJson, String columnFieldsJson);
}