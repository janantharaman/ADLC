/**********************************************************************************
 * @filename      : ACC_AdditionalAccountInfo_tr.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2026-01-02 (금)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : ACC_AdditionalAccountInfo_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-12-23      i2max            Create
**********************************************************************************/

public without sharing class ACC_AdditionalAccountInfo_tr extends TriggerHandler {

    /** @description Name 필드 최대 허용 길이 */
    private static final Integer ADDITIONAL_INFO_NAME_MAX_LENGTH = 80;

    public override void beforeInsert() {
        this.setAdditionalInfoName(Trigger.new);
    }

    /**
   * @description
   * Before Insert 시 Name 필드를 자동 설정
   * Account 약어 + Reinsurer 약어 + BindingFrom 날짜(YYMMDD)를 조합
   * 최대 80자 이내로 구성 (약어 부분 73자 + '_' + 6자리 날짜)
   * @param newList Trigger.new
   */
    private void setAdditionalInfoName(List<ACC_AdditionalInfo__c> newList) {
        Set<Id> acctIds = new Set<Id>();
        for (ACC_AdditionalInfo__c newObj : newList) {
            if (newObj.Account_lk__c <> null) acctIds.add(newObj.Account_lk__c);
            if (newObj.Reinsurer_lk__c <> null) acctIds.add(newObj.Reinsurer_lk__c);
            if (newObj.Account_lk__c == null && newObj.Reinsurer_lk__c == null) newObj.Name = COM_Util.getDateYYMMDD(newObj.BindingFrom__c);
        }

        if (!acctIds.isEmpty()) {
            Map<Id, String> coAcrByAcctId = new Map<Id, String>();
            for (Account acct : [SELECT CompanyAcronym__c FROM Account WHERE Id IN :acctIds AND CompanyAcronym__c != '']) {
                coAcrByAcctId.put(acct.Id, acct.CompanyAcronym__c);
            }

            for (ACC_AdditionalInfo__c newObj : newList) {
                String accNm = '';
                if (coAcrByAcctId.containsKey(newObj.Account_lk__c)) accNm = coAcrByAcctId.get(newObj.Account_lk__c);
                if (coAcrByAcctId.containsKey(newObj.Reinsurer_lk__c)) accNm += (String.isBlank(accNm) ? '' : '_') + coAcrByAcctId.get(newObj.Reinsurer_lk__c);
                accNm = accNm.left(73);
                if (newObj.BindingFrom__c <> null) accNm += (String.isBlank(accNm) ? '' : '_') + COM_Util.getDateYYMMDD(newObj.BindingFrom__c);
                newObj.Name = accNm;
            }
        }
    }


}