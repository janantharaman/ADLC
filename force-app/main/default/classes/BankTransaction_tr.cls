/**
 * @description       :
 * @author            : Yugon Hwang
 * @last modified on  : 2026-04-24
 * @last modified by  : Akrom Saidkamolov
 **/
public without sharing class BankTransaction_tr extends TriggerHandler {
    private Map<Id, BankTransaction__c> mapNew;
    private Map<Id, BankTransaction__c> mapOld;
    private List<BankTransaction__c> listNew;
    private List<BankTransaction__c> listOld;

    public BankTransaction_tr() {
        this.mapNew = (Map<Id, BankTransaction__c>) Trigger.newMap;
        this.mapOld = (Map<Id, BankTransaction__c>) Trigger.oldMap;
        this.listNew = (List<BankTransaction__c>) Trigger.new;
        this.listOld = (List<BankTransaction__c>) Trigger.old;
    }

    public override void beforeInsert() {
        assignBizRegion();
        assignMatchAccount();
        setInitialValues();
    }

    public override void beforeUpdate() {
        calculateNotReconciledAmount();
    }

    public override void beforeDelete() {
        //- BT 삭제 시 Status 확인
        for (BankTransaction__c bt : listOld) {
            if (bt.Status__c != REC_Consts.BankTransactionStatus.NONE) {
                bt.addError('Cannot delete Bank Transaction with Status other than None');
            }
        }
    }

    private void calculateNotReconciledAmount() {
        for (BankTransaction__c bt : listNew) {
            //- 해당 BT의 Reconciled Amount = 0인 경우 Origin Amount 변경 시 Not-Reconciled AMT 값도 업데이트
            //- 해당 BT의 Reconciled Amount ≠ 0인 경우, 수정 저장 시 오류 표시
            if (mapOld.get(bt.Id).OriginAmount__c != bt.OriginAmount__c) {
                if (bt.TotalClearedAmount__c != null && bt.TotalClearedAmount__c != 0) {
                    bt.addError('Cannot update Origin Amount when Total Cleared Amount is not 0');
                } else {
                    bt.NetBalanceAftCleared__c = bt.OriginAmount__c;
                }
            }
        }
    }

    private void assignBizRegion() {
        for (BankTransaction__c bt : listNew) {
            if (bt.BizRegion__c == null) {
                bt.BizRegion__c = Util.getBizRegion();
            }
        }
    }

    private void assignMatchAccount() {
        Set<String> setBizRegion = new Set<String>();
        Set<String> setDepositor = new Set<String>();

        for (BankTransaction__c bt : listNew) {
            if (String.isNotBlank(bt.Depositor__c) && String.isNotBlank(bt.BizRegion__c) && bt.AccountName__c == null) {
                setDepositor.add(bt.Depositor__c);
                setBizRegion.add(bt.BizRegion__c);
            }
        }

        if (setDepositor.isEmpty()) {
            return;
        }

        Map<String, Id> mapAccountByKey = new Map<String, Id>();
        for (AccountDepositor__c ad : [
            SELECT BizRegion__c, Depositor__c, AccountName__c
            FROM AccountDepositor__c
            WHERE
                Depositor__c IN :setDepositor
                AND AccountName__c != NULL
                AND IsActive__c = TRUE
                AND BizRegion__c IN :setBizRegion
        ]) {
            mapAccountByKey.put(ad.BizRegion__c + '_' + ad.Depositor__c, ad.AccountName__c);
        }

        for (BankTransaction__c bt : listNew) {
            if (String.isNotBlank(bt.Depositor__c) && String.isNotBlank(bt.BizRegion__c) && bt.AccountName__c == null) {
                String key = bt.BizRegion__c + '_' + bt.Depositor__c;
                if (mapAccountByKey.containsKey(key)) {
                    bt.AccountName__c = mapAccountByKey.get(key);
                }
            }
        }
    }

    private void setInitialValues() {
        for (BankTransaction__c bt : listNew) {
            if (bt.TransactionType__c == BankTransactionService.TRANSACTION_TYPE_WITHDRAWAL && bt.OriginAmount__c > 0) {
                bt.OriginAmount__c = bt.OriginAmount__c * -1;
            }
            if (bt.NetBalanceAftCleared__c == null) {
                bt.NetBalanceAftCleared__c = bt.OriginAmount__c;
            }
        }
    }
}