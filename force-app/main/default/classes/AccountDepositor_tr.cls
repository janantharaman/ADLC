/**
 * @description       :
 * @author            : Yugon Hwang
 * @last modified on  : 2026-04-16
 * @last modified by  : Akrom Saidkamolov
 **/
public without sharing class AccountDepositor_tr extends TriggerHandler {
    private Map<Id, AccountDepositor__c> mapNew;
    private Map<Id, AccountDepositor__c> mapOld;
    private List<AccountDepositor__c> listNew;
    private List<AccountDepositor__c> listOld;

    public AccountDepositor_tr() {
        this.mapNew = (Map<Id, AccountDepositor__c>) Trigger.newMap;
        this.mapOld = (Map<Id, AccountDepositor__c>) Trigger.oldMap;
        this.listNew = (List<AccountDepositor__c>) Trigger.new;
        this.listOld = (List<AccountDepositor__c>) Trigger.old;
    }

    public override void beforeInsert() {
        assignBizRegion();
        preventDuplicateActiveDepositor();
    }

    public override void beforeUpdate() {
        preventDuplicateActiveDepositor();
        preventDepositorNameChange();
    }

    public override void afterInsert() {
        updateAccountOfBankTransaction();
    }

    public override void afterUpdate() {
        updateAccountOfBankTransaction();
    }

    private void assignBizRegion() {
        for (AccountDepositor__c ad : listNew) {
            if (ad.BizRegion__c == null) {
                ad.BizRegion__c = Util.getBizRegion();
            }
        }
    }

    private void preventDuplicateActiveDepositor() {
        try {
            Set<String> setBizRegion = new Set<String>();
            Set<String> setDepositorName = new Set<String>();
            Set<String> setDepositorKey = new Set<String>();

            for (AccountDepositor__c depositor : listNew) {
                if (String.isNotBlank(depositor.Depositor__c) && String.isNotBlank(depositor.BizRegion__c)) {
                    setDepositorName.add(depositor.Depositor__c);
                    setBizRegion.add(depositor.BizRegion__c);
                }
                if (
                    depositor.IsActive__c &&
                    String.isNotBlank(depositor.Depositor__c) &&
                    String.isNotBlank(depositor.BizRegion__c)
                ) {
                    String key = AccountDepositorService.getDepositorKey(depositor);
                    if (setDepositorKey.contains(key)) {
                        // 동일한 Active Depositor가 두개이상 들어왔을때 에러
                        depositor.addError('Cannot Duplicate Active Depositor. Check Depositor : ' + depositor.Depositor__c);
                    }
                    setDepositorKey.add(key);
                    setDepositorName.add(depositor.Depositor__c);
                    setBizRegion.add(depositor.BizRegion__c);
                }
            }

            if (setDepositorKey.isEmpty()) {
                return;
            }

            Set<String> setExistingKey = AccountDepositorService.getExistingAccountDepositorKey(
                setBizRegion,
                setDepositorName,
                listNew
            );

            for (AccountDepositor__c depositor : listNew) {
                if (depositor.IsActive__c && setExistingKey.contains(AccountDepositorService.getDepositorKey(depositor))) {
                    depositor.addError('Cannot Duplicate Active Depositor. Check Depositor : ' + depositor.Depositor__c);
                }
            }
        } catch (Exception e) {
            Logger.error(e.getMessage() + ' :: ' + e.getStackTraceString());
            Logger.saveLog();
        }
    }

    private void preventDepositorNameChange() {
        for (AccountDepositor__c depositor : listNew) {
            if (depositor.Depositor__c != mapOld.get(depositor.Id).Depositor__c) {
                depositor.addError('Cannot Change Depositor Name. Please Delete and Create New Account Depositor.');
            }
        }
    }

    private void updateAccountOfBankTransaction() {
        try {
            Logger.info('updateAccountOfBankTransaction run');
            // Active AccountDepositor의 BizRegion + Depositor → AccountName 매핑
            Map<String, Id> mapAccountByKey = new Map<String, Id>();
            Set<String> setBizRegion = new Set<String>();
            Set<String> setDepositor = new Set<String>();

            for (AccountDepositor__c ad : listNew) {
                if (
                    ad.IsActive__c &&
                    ad.AccountName__c != null &&
                    String.isNotBlank(ad.Depositor__c) &&
                    String.isNotBlank(ad.BizRegion__c) &&
                    ad.UpdateScope__c == AccountDepositorService.DEPOSITOR_UPDATE_SCOPE_UNRECONCILED_ONLY
                ) {
                    mapAccountByKey.put(AccountDepositorService.getDepositorKey(ad), ad.AccountName__c);
                    setBizRegion.add(ad.BizRegion__c);
                    setDepositor.add(ad.Depositor__c);
                }
            }

            Logger.info('mapAccountByKey : ' + mapAccountByKey);

            if (mapAccountByKey.isEmpty()) {
                return;
            }

            // Context에 따라 BankTransaction 조회 조건 다름 (Update일 경우 전체 조회, Insert일 경우 AccountName이 Null 인 것만 조회)
            List<BankTransaction__c> listBankTransaction = Trigger.isUpdate
                ? BankTransactionService.getBankTransaction(setDepositor, setBizRegion)
                : BankTransactionService.getBankTransactionNullAccountName(setDepositor, setBizRegion);

            Logger.info('listBankTransaction : ' + listBankTransaction);

            if (listBankTransaction == null || listBankTransaction.isEmpty()) {
                return;
            }

            // Confirmed ReconciliationLineItem이 있는 BankTransaction Id를 수집
            Set<Id> setConfirmedBtId = BankTransactionService.getSetConfirmedBankTransactionId(listBankTransaction);
            Logger.info('setConfirmedBtId : ' + setConfirmedBtId);

            // Confirmed가 아닌 BankTransaction만 AccountName 업데이트
            // 현재 유저의 BizRegion과 다른 BT는 BankAccount__c Lookup Filter에 걸리므로 제외
            String currentBizRegion = Util.getBizRegion();
            List<BankTransaction__c> listToUpdate = new List<BankTransaction__c>();
            for (BankTransaction__c bt : listBankTransaction) {
                if (setConfirmedBtId.contains(bt.Id)) {
                    continue;
                }

                if (bt.BizRegion__c != currentBizRegion) {
                    continue;
                }

                String key = AccountDepositorService.getDepositorKey(
                    new AccountDepositor__c(BizRegion__c = bt.BizRegion__c, Depositor__c = bt.Depositor__c)
                );

                Logger.info('key :: ' + key);

                if (mapAccountByKey.containsKey(key)) {
                    Id newAccountId = mapAccountByKey.get(key);
                    if (bt.AccountName__c != newAccountId) {
                        bt.AccountName__c = newAccountId;
                        listToUpdate.add(bt);
                    }
                }
            }

            Logger.info('listToUpdate : ' + listToUpdate);

            if (!listToUpdate.isEmpty()) {
                update listToUpdate;
            }
        } catch (Exception e) {
            Logger.error(e.getMessage() + ' :: ' + e.getStackTraceString());
            throw e;
        } finally {
            Logger.saveLog();
        }
    }
}