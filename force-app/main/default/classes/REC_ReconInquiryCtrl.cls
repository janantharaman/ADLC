public with sharing class REC_ReconInquiryCtrl {
    private static final REC_ReconciliationLineItemSelector SEL = REC_ReconciliationLineItemSelector.getInstance();

    /**
     * Retrieves ReconciliationLineItem records based on the given filters.
     * Uses REC_ReconciliationLineItemSelector.queryByFilter, simulating the
     * behavior seen in SLI and BT inquiries.
     *
     * @param filterMap      Map of filter conditions (parsed from JSON in the controller)
     * @param relFieldsList  List of relationship fields to include in the query
     * @return               List of ReconciliationLineItem__c matching the criteria
     */
    @AuraEnabled
    public static List<ReconciliationLineItem__c> inquiryReconciliationData(String filters, String relFields) {
        try {
            ExceptionSimulator.throwIfActive();
            return (List<ReconciliationLineItem__c>) SEL.queryByFilter(filters, relFields);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
}