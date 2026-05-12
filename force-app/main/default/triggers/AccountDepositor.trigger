trigger AccountDepositor on AccountDepositor__c(before insert, before update, after insert, after update) {
    new AccountDepositor_tr().run();
}