public with sharing class REC_ReverseOffsetCtrl {
    private static final REC_SettlementLIneItemSelector SLI_SEL = REC_SettlementLineItemSelector.getInstance();

    public class ReverseOffsetRequest {
        @InvocableVariable(label='List of all Settlement Line Item IDs, both Reversed and Reversing.' required=true)
        public List<Id> sliIds;
    }

    public class ReverseOffsetResult {
        @InvocableVariable(label='Reconciliation ID')
        public Id reconciliationId;
    }

    @InvocableMethod(
        label='Process Reverse Offset'
        description='Creates a Confirmed Reconciliation for the given Reversed/Reversing Settlement Line Item IDs.'
    )
    public static List<ReverseOffsetResult> processReverseOffset(List<ReverseOffsetRequest> requests) {
        List<ReverseOffsetResult> results = new List<ReverseOffsetResult>();
        for (ReverseOffsetRequest req : requests) {
            ReverseOffsetResult res = new ReverseOffsetResult();
            try {
                res.reconciliationId = REC_ReconciliationDomain.processReverseOffset(req.sliIds);
            } catch (Exception e) {
                Logger.error(e.getMessage(), e);
                Logger.saveLog();
                throw new AuraHandledException(e.getMessage());
            }
            results.add(res);
        }
        return results;
    }

    /**
     *	Gets the list of SettlementLineItem__c records that are referenced as offsets in the given reconciliation.
     *
     * @param reconId
     * @return        `List<SettlementLineItem__c>`
     * @exception
     */
    @AuraEnabled
    public static List<SettlementLineItem__c> getOffsetSlis(String reconId) {
        try {
            if (String.isBlank(reconId)) {
                throw new AuraHandledException('Reconciliation Id is required');
            }

            return SLI_SEL.queryOffsetSlisByReconId(reconId);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }
}