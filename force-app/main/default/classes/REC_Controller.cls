public with sharing class REC_Controller {
    /**
     * Get picklist options for a given object and field.
     *
     * @param objectApiName
     * @param fieldApiName
     * @return              `List<COM_Option>`
     */
    @AuraEnabled(cacheable=true)
    public static List<COM_Option> getPicklistOptions(String objectApiName, String fieldApiName) {
        if (String.isBlank(objectApiName) || String.isBlank(fieldApiName)) {
            return new List<COM_Option>();
        }

        Schema.DescribeSObjectResult objectDesc = Schema.describeSObjects(new List<String>{ objectApiName })[0];
        Schema.DescribeFieldResult fieldDesc = objectDesc.fields.getMap().get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldDesc.getPicklistValues();

        List<COM_Option> options = new List<COM_Option>();

        for (Schema.PicklistEntry picklistEntry : picklistEntries) {
            options.add(new COM_Option(picklistEntry.getLabel(), picklistEntry.getValue()));
        }

        return options;
    }

    /**
     * Get field labels for given object API names.
     *
     * @param objectApiNames
     * @return               `Map<String, Map<String, String>>`
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Map<String, String>> getFieldLabels(List<String> objectApiNames) {
        Map<String, Map<String, String>> labels = new Map<String, Map<String, String>>();

        for (String objectApiName : objectApiNames) {
            Schema.DescribeSObjectResult objectDesc = Schema.describeSObjects(new List<String>{ objectApiName })[0];

            Map<String, String> fieldLabels = new Map<String, String>();
            for (Schema.SObjectField field : objectDesc.fields.getMap().values()) {
                Schema.DescribeFieldResult fieldDesc = field.getDescribe();
                fieldLabels.put(fieldDesc.getName(), fieldDesc.getLabel());
            }

            labels.put(objectApiName, fieldLabels);
        }

        return labels;
    }


    ///**
    // * Search Settlement Line Items based on given filters.
    // *
    // * @param searchFilters
    // * @return              `List<SettlementLineItem__c>`
    // * @exception
    // */
    //@AuraEnabled
    //public static List<SettlementLineItem__c> searchSettlementLineItems(List<String> searchFilters) {
    //    try {
    //        // Guard null param
    //        if (searchFilters == null || searchFilters.isEmpty()) {
    //            searchFilters = new List<String>{ 'Id != NULL' };
    //        }

    //        // QUERY
    //        String queryBase = 'SELECT {0} FROM SettlementLineItem__c WHERE {1} ORDER BY Name DESC LIMIT 2000';
    //        // SELECT
    //        String selectClause = new REC_Repository.SettlementLineItem().toSelectClause();
    //        // WHERE
    //        String whereClause = String.join(searchFilters, ' AND ');
    //        // BUILD
    //        String queryString = String.format(queryBase, new List<String>{ selectClause, whereClause });

    //        return Database.query(queryString, AccessLevel.USER_MODE);
    //    } catch (Exception e) {
    //        throw new AuraHandledException(e.getMessage());
    //    }
    //}

    //public class DuplicateResponse {
    //    @AuraEnabled
    //    public String id { get; set; }
    //    @AuraEnabled
    //    public String name { get; set; }

    //    public DuplicateResponse(SObject record) {
    //        this.id = record.Id;
    //        this.name = (String) record.get('Name');
    //    }
    //}

    ///**
    // * Check for existing draft Reconciliation or Reconciliation Line Item for given record ID.
    // *
    // * @param recordId
    // * @return         `DuplicateResponse`
    // */
    //@AuraEnabled
    //public static DuplicateResponse checkDuplicate(String recordId) {
    //    ReconciliationLineItem__c existingRli = [
    //        SELECT Id, Name, SettlementLineItem_lk__c, BankTransaction_lk__c, Reconciliation_md__r.Name
    //        FROM ReconciliationLineItem__c
    //        WHERE
    //            Reconciliation_md__r.Status__c = 'Draft'
    //            AND (SettlementLineItem_lk__c = :recordId
    //            OR BankTransaction_lk__c = :recordId)
    //        WITH SYSTEM_MODE
    //        ORDER BY Name DESC
    //        LIMIT 1
    //    ] ?? null;

    //    if (existingRli != null) {
    //        return new DuplicateResponse(existingRli);
    //    }

    //    Reconciliation__c existingRecon = [
    //        SELECT Id, Name
    //        FROM Reconciliation__c
    //        WHERE Status__c = 'Draft' AND BaseRecordId__c = :recordId
    //        WITH SYSTEM_MODE
    //        ORDER BY Name DESC
    //        LIMIT 1
    //    ] ?? null;

    //    if (existingRecon != null) {
    //        return new DuplicateResponse(existingRecon);
    //    }

    //    return null;
    //}

    ///**
    // * Create a new Reconciliation record for given base record ID.
    // *
    // * @param baseRecordId
    // * @return             `Reconciliation__c`
    // * @exception
    // */
    //@AuraEnabled
    //public static Reconciliation__c createReconciliation(Id baseRecordId) {
    //    SavePoint sp = Database.setSavepoint();

    //    try {
    //        Reconciliation__c recon = new Reconciliation__c();

    //        recon.Base__c = baseRecordId.getSObjectType().getDescribe().getName();
    //        recon.BaseRecordId__c = baseRecordId;
    //        recon.Status__c = 'Draft';

    //        insert as system recon;
    //        return recon;
    //    } catch (Exception e) {
    //        Database.rollback(sp);

    //        throw new AuraHandledException(e.getMessage());
    //    }
    //}
}