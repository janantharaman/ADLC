/**********************************************************************************
 * @filename      : ACC_NaverNewsFetch_sc.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2026-03-08 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : ACC_NaverNewsFetch_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-08      i2max            Create
**********************************************************************************/
public with sharing class ACC_NaverNewsFetch_sc implements Schedulable {

    // ACC_NaverNewsFetch_sc.scheduleJob('0 0 7 * * ?');
    // 배치 scope size (Account 건수/execute)
    private static final Integer BATCH_SCOPE = 1;
    private static final String JOB_NAME = '[ACC] NaverNewsFetch_Daily';

    // =========================================================================
    // Schedulable 구현
    // =========================================================================
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ACC_NaverNewsFetch_ba(), BATCH_SCOPE);
    }

    // =========================================================================
    // 스케줄 등록 (cronExp 전달)
    // =========================================================================
    public static String scheduleJob(String cronExpression) {
        return System.schedule(JOB_NAME, cronExpression, new ACC_NaverNewsFetch_sc());
    }

    // =========================================================================
    // 스케줄 삭제
    // =========================================================================
    public static void abortJob() {
        for (CronTrigger ct : [
                SELECT Id FROM CronTrigger
                WHERE CronJobDetail.Name = :JOB_NAME
        ]) {
            System.abortJob(ct.Id);
        }
    }

    // =========================================================================
    // 즉시 실행 (스케줄 없이 배치 바로 실행) ACC_NaverNewsFetch_sc.runNow();
    // =========================================================================
    public static Id runNow() {
        return Database.executeBatch(new ACC_NaverNewsFetch_ba(), BATCH_SCOPE);
    }


}