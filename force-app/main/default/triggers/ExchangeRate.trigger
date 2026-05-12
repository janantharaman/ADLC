trigger ExchangeRate on ExchangeRate__c(before insert, before update, after insert, after update) {
    new ExchangeRate_tr().run();
}