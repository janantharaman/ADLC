/**********************************************************************************
 * @filename      : ACC_News_Ctrl.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2026-03-08 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : ACC_News_Ctrl_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-08      i2max            Create
**********************************************************************************/
public with sharing class ACC_News_Ctrl {

    @AuraEnabled(Cacheable=true)
    public static List<ACC_News__c> getNewsByAccountId(Id accountId, Integer limitCount) {

        if (accountId == null) throw new AuraHandledException('AccountId is required.');
        Integer maxCount = (limitCount != null && limitCount > 0) ? limitCount : 1000;

        return [
                SELECT Id, Title__c, Description__c, Link__c, OriginalLink__c,
                        PubDate__c, TitleOriginal__c
                FROM ACC_News__c
                WHERE Account_lk__c = :accountId
                ORDER BY PubDate__c DESC
                LIMIT :maxCount
        ];
    }

}