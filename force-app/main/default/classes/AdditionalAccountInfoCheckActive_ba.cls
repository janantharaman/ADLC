/**********************************************************************************
 * @filename       : AdditionalAccountInfoCheckActive_ba.cls
 * @projectname   : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-06 (화)
 * @group         :
 * @group-content :
 * @description   : ACC_AdditionalInfo__c 레코드 중 BindingTo__c가
 *                  오늘 이전이고 ActiveRe_is__c 가 true 인 레코드를 일괄 조회하여
 *                  ActiveRe_is__c 를 false 로 업데이트하는 배치 클래스
 * @test-class    : AdditionalAccountInfoCheckActive_ba_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-06      i2max            Create
**********************************************************************************/

public with sharing class AdditionalAccountInfoCheckActive_ba implements Database.Batchable<SObject> {

    /**
     * @description 배치 시작 메서드
     *              BindingTo__c < TODAY AND ActiveRe_is__c = TRUE 조건의
     *              ACC_AdditionalInfo__c 레코드를 QueryLocator 로 반환
     * @param bc BatchableContext
     * @return 처리 대상 레코드의 QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Logger.info('Batch Started: AdditionalAccountInfoCheckActive_ba');
        Logger.saveLog();
       /* Logger.getTransactionId();*/

        String query = 'SELECT Id, BindingTo__c, ActiveRe_is__c FROM ACC_AdditionalInfo__c WHERE BindingTo__c < TODAY AND ActiveRe_is__c = TRUE';
        return Database.getQueryLocator(query);
    }

    /**
     * @description 배치 실행 메서드
     *              조회된 레코드의 ActiveRe_is__c 를 false 로 변경하고 Database.update 로 저장
     *              업데이트 실패 시 오류 내용을 Logger 에 기록
     * @param bc    BatchableContext
     * @param scope 처리 대상 ACC_AdditionalInfo__c 레코드 목록
     */
    public void execute(Database.BatchableContext bc, List<ACC_AdditionalInfo__c> scope) {
        Logger.info('Batch Execution: Processing ' + scope.size() + ' records');

        for(ACC_AdditionalInfo__c info : scope) {
            info.ActiveRe_is__c = false;
        }

        try {
            Database.SaveResult[] results = Database.update(scope, false);

            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results[i];
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        Logger.error('Update failed for Record ID: ' + scope[i].Id + '. Error: ' + err.getMessage());
                    }
                }
            }
        } catch (Exception e) {
            Logger.error('Batch execution exception', e);
        } finally {
          /*  Logger.setParentLogTransactionId();*/
            Logger.saveLog();
        }
    }

    /**
     * @description 배치 완료 메서드
     *              배치 종료 로그를 Logger 에 기록
     * @param bc BatchableContext
     */
    public void finish(Database.BatchableContext bc) {
        Logger.info('Batch Finished: AdditionalAccountInfoCheckActive_ba');
        Logger.saveLog();
    }
}