trigger SettlementLineItem on SettlementLineItem__c(
    after insert,
    before update,
    after update,
    after delete,
    after undelete
) {
    new SettlementLineItem_tr().run();
}