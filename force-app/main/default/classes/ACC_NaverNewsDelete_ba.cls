/**********************************************************************************
 * @filename      : ACC_NaverNewsDelete_ba.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2026-03-08 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : ACC_NaverNewsDelete_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-08      i2max            Create
**********************************************************************************/
public with sharing class ACC_NaverNewsDelete_ba  implements Database.Batchable<SObject> {

    private final Integer retentionDays;
    private Integer totalSuccess = 0;
    private Integer totalFail = 0;

    public ACC_NaverNewsDelete_ba() {
        NewsConfig__mdt config = NewsConfig__mdt.getInstance('Default');
        this.retentionDays = (config.RetentionDays__c != null) ? Integer.valueOf(config.RetentionDays__c) : 90;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {

        Logger.setScenario('ACC_NaverNewsDelete_ba');
        Logger.info('Batch 시작');
        Logger.saveLog();

        Datetime cutoff = Datetime.now().addDays(-retentionDays);
        return Database.getQueryLocator([
                SELECT Id
                FROM ACC_News__c
                WHERE PubDate__c < :cutoff
        ]);
    }

    public void execute(Database.BatchableContext bc, List<ACC_News__c> scope) {

        Logger.setScenario('ACC_NaverNewsDelete_ba');
        Logger.info('execute 시작 - scope size: ' + scope.size());

        List<Database.DeleteResult> deleteResults = Database.delete(scope);
        for(Database.DeleteResult deleteResult : deleteResults) {
            if(deleteResult.isSuccess()) totalSuccess++;
            if(!deleteResult.isSuccess()) totalFail++;
        }
        Logger.info('Delete 건수: ' + deleteResults.size());
        Logger.saveLog();
    }

    public void finish(Database.BatchableContext bc) {
        Logger.setScenario('ACC_NaverNewsDelete_ba');
        Logger.info('Batch 완료 - 성공: ' + totalSuccess + ', 실패: ' + totalFail);
        Logger.saveLog();

        System.debug('[ACC_NaverNewsDelete_ba] 완료 - 삭제 대상 처리 완료');
    }
}