/**
 * @description       :
 * @author            :
 * @last modified on  : 2026-04-24
 * @last modified by  : Akrom Saidkamolov
 **/
trigger BankTransaction on BankTransaction__c(before insert, before update, before delete) {
    new BankTransaction_tr().run();
}