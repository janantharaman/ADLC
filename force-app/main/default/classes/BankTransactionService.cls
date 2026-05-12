public without sharing class BankTransactionService {
    public static final String TRANSACTION_TYPE_DEPOSIT = 'Deposit';
    public static final String TRANSACTION_TYPE_WITHDRAWAL = 'Withdrawal';

    public static List<BankTransaction__c> getBankTransaction(Set<String> setDepositor, Set<String> setBizRegion) {
        return [
            SELECT Id, BizRegion__c, Depositor__c, AccountName__c
            FROM BankTransaction__c
            WHERE Depositor__c IN :setDepositor AND BizRegion__c IN :setBizRegion
        ] ?? null;
    }

    public static List<BankTransaction__c> getBankTransactionNullAccountName(
        Set<String> setDepositor,
        Set<String> setBizRegion
    ) {
        return [
            SELECT Id, BizRegion__c, Depositor__c, AccountName__c
            FROM BankTransaction__c
            WHERE AccountName__c = NULL AND Depositor__c IN :setDepositor AND BizRegion__c IN :setBizRegion
        ] ?? null;
    }

    public static Set<Id> getSetConfirmedBankTransactionId(List<BankTransaction__c> listBankTransaction) {
        Set<Id> setConfirmedBtId = new Set<Id>();
        for (ReconciliationLineItem__c rli : getConfirmedReconLineItemRelatedBankTrnasaction(listBankTransaction)) {
            setConfirmedBtId.add(rli.RefBankTransaction__c);
        }

        return setConfirmedBtId;
    }

    public static List<ReconciliationLineItem__c> getConfirmedReconLineItemRelatedBankTrnasaction(
        List<BankTransaction__c> listBankTransaction
    ) {
        return new List<ReconciliationLineItem__c>(
            [
                SELECT RefBankTransaction__c
                FROM ReconciliationLineItem__c
                WHERE
                    RefBankTransaction__c IN :listBankTransaction
                    AND RLIStatus__c = 'Confirmed'
                    AND BizRegion__c = :Util.getBizRegion()
            ]
        );
    }
}