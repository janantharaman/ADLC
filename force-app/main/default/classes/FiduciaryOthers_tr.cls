/**
 * @description       :
 * @author            : Akrom Saidkamolov
 * @last modified on  : 2026-03-23
 * @last modified by  : Akrom Saidkamolov
 **/
public without sharing class FiduciaryOthers_tr extends TriggerHandler {
    private Map<Id, FiduciaryOthers__c> mapNew;
    private Map<Id, FiduciaryOthers__c> mapOld;
    private List<FiduciaryOthers__c> listNew;
    private List<FiduciaryOthers__c> listOld;

    public FiduciaryOthers_tr() {
        this.mapNew = (Map<Id, FiduciaryOthers__c>) Trigger.newMap;
        this.mapOld = (Map<Id, FiduciaryOthers__c>) Trigger.oldMap;
        this.listNew = (List<FiduciaryOthers__c>) Trigger.new;
        this.listOld = (List<FiduciaryOthers__c>) Trigger.old;
    }

    public override void beforeUpdate() {
        validateAccountName();
    }

    private void validateAccountName() {
        List<FiduciaryOthers__c> recordsWithAccountUpdate = new List<FiduciaryOthers__c>();
        Set<String> depositors = new Set<String>();
        Set<String> bizRegions = new Set<String>();

        for (FiduciaryOthers__c fo : listNew) {
            FiduciaryOthers__c oldFo = mapOld.get(fo.Id);
            if (fo.AccountName__c != oldFo.AccountName__c && String.isNotBlank(fo.AccountName__c)) {
                recordsWithAccountUpdate.add(fo);
                depositors.add(fo.Depositor__c);
                bizRegions.add(fo.BizRegion__c);
            }
        }

        if (recordsWithAccountUpdate.isEmpty()) {
            return;
        }

        depositors.remove(null);
        bizRegions.remove(null);

        List<AccountDepositor__c> depositorMasterData = [
            SELECT BizRegion__c, Depositor__c, AccountName__c
            FROM AccountDepositor__c
            WHERE
                Depositor__c IN :depositors
                AND AccountName__c != NULL
                AND IsActive__c = TRUE
                AND BizRegion__c IN :bizRegions
        ];

        Map<String, String> accountByDepositorAndRegion = new Map<String, String>();
        for (AccountDepositor__c ad : depositorMasterData) {
            accountByDepositorAndRegion.put(ad.BizRegion__c + '_' + ad.Depositor__c, ad.AccountName__c);
        }

        for (FiduciaryOthers__c fo : recordsWithAccountUpdate) {
            String key = fo.BizRegion__c + '_' + fo.Depositor__c;
            if (!accountByDepositorAndRegion.containsKey(key) || accountByDepositorAndRegion.get(key) != fo.AccountName__c) {
                fo.AccountName__c.addError(
                    'Invalid Account Name for the given Depositor and Biz Region. Please check the Account Depositor.'
                );
            }
        }
    }
}