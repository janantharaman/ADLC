/**********************************************************************************
 * @filename      : NumberCounterFlowAction.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-12-29 (월)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : NumberCounterFlowAction_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-12-29      i2max     Create
**********************************************************************************/
public without sharing class NumberCounterFlowAction {

    public class Request {
        @InvocableVariable(Required=true)
        public Id recordId;
    }

    public class Result {
        @InvocableVariable public Id recordId;
        @InvocableVariable public Decimal issuedNo;
        @InvocableVariable public String status;   // ASSIGNED / ERROR
        @InvocableVariable public String message;
    }

    public class NumberCounterException extends Exception {}

    /* =============================================================================
     * [현재 사용] CMDT 기반 버전
     * - Contract_No_Management__mdt 레코드가 "반드시 1건 존재"한다고 가정
     * - Latest_Sequence_No__c를 읽고 +1
     * - Contract.DocumentNo__c 즉시 업데이트
     * - CMDT Latest_Sequence_No__c 업데이트는 Queueable에서 Metadata Deploy로 비동기 수행
     *   (같은 트랜잭션에서 Contract DML + DeployRequest 생성 시 Mixed DML 발생)
     * ========================================================================== */
    @InvocableMethod(label='Issue Next Sequence (CMDT)')
    public static List<Result> issueNext(List<Request> requests) {
        List<Result> results = new List<Result>();
        if (requests == null || requests.isEmpty()) return results;

        // 1) CMDT 1건 조회 (무조건 존재 가정)
        Contract_No_Management__mdt cfg = [
                SELECT DeveloperName, MasterLabel, Latest_Sequence_No__c
                FROM Contract_No_Management__mdt
                LIMIT 1
        ];

        Decimal current = (cfg.Latest_Sequence_No__c == null) ? 0 : cfg.Latest_Sequence_No__c;

        // 2) 요청별 시퀀스 할당 (current+1 ...)
        Decimal seq = current;
        Map<Id, Decimal> issuedById = new Map<Id, Decimal>();
        List<Contract> toUpdate = new List<Contract>();

        for (Request req : requests) {
            Result r = new Result();
            r.recordId = (req == null) ? null : req.recordId;
            r.status = 'ERROR';
            r.message = 'Not processed';
            results.add(r);

            if (req == null || req.recordId == null) {
                r.message = 'recordId is null';
                continue;
            }

            seq++;
            issuedById.put(req.recordId, seq);

            r.issuedNo = seq;
            r.status = 'ASSIGNED';
            r.message = 'OK';

            // 3) Contract 문서번호 생성 (CON_00001 형태, 5자리)
            String docNo = buildContractDocNo(seq);

            toUpdate.add(new Contract(
                    Id = req.recordId,
                    DocumentNo__c = docNo
            ));
        }

        if (toUpdate.isEmpty()) return results;

        // 4) Contract 업데이트 (Non-Setup DML)
        update toUpdate;

        // 5) CMDT Latest_Sequence_No__c 갱신은 Queueable에서 수행 (Setup 작업 분리)
        Decimal newLatest = current + toUpdate.size();
        //System.enqueueJob(new CmdtUpdateJob(cfg.DeveloperName, newLatest));
        System.enqueueJob(new CmdtUpdateJob(cfg.DeveloperName, cfg.MasterLabel, newLatest));

        return results;
    }

    /**
     * CMDT 업데이트 Job
     * - Mixed DML 회피를 위해 Contract DML 트랜잭션과 분리
     * - Custom Metadata "레코드 fullName"은 __mdt를 붙이지 않습니다.
     *   예) Contract_No_Management.<RecordDeveloperName>
     */
    public class CmdtUpdateJob implements Queueable {
        private final String recordDeveloperName;
        private final String masterLabel;
        private final Decimal newLatest;

        public CmdtUpdateJob(String recordDeveloperName, String masterLabel, Decimal newLatest) {
            this.recordDeveloperName = recordDeveloperName;
            this.masterLabel = masterLabel;
            this.newLatest = newLatest;
        }

        public void execute(QueueableContext qc) {
            Metadata.DeployContainer dc = new Metadata.DeployContainer();

            Metadata.CustomMetadata cmd = new Metadata.CustomMetadata();
            cmd.fullName = 'Contract_No_Management.' + recordDeveloperName;
            cmd.label = masterLabel;

            Metadata.CustomMetadataValue v = new Metadata.CustomMetadataValue();
            v.field = 'Latest_Sequence_No__c';
            v.value = Integer.valueOf(newLatest); // Number(5,0)면 정수로

            cmd.values.add(v);
            dc.addMetadata(cmd);

            Metadata.Operations.enqueueDeployment(dc, null);
        }
    }

    private static String buildContractDocNo(Decimal seq) {
        // Decimal -> Long -> String : "1.0" 같은 문자열 방지
        String padded = String.valueOf(seq).leftPad(5, '0');
        return 'CON_' + padded;
    }

    /* =============================================================================
     * [복원용] Custom Object 기반 버전 (필요 시 주석 해제 후 사용)
     * - COM_NumberCounter__c(Key__c Unique) + Sequence__c
     * - FOR UPDATE로 락 걸어서 동시성 중복 방지 가능
     * ========================================================================== */
//    @InvocableMethod(label='Issue Next Sequence (NumberCounter - Custom Object)')
//    public static List<Result> issueNext2(List<Request> requests) {
//        List<Result> results = new List<Result>();
//        if (requests == null || requests.isEmpty()) return results;
//
//        // 0) Picklist 허용값(= 등록된 Object 목록)
//        Set<String> allowedKeys = COM_MetaUtil.getPicklistLabels('COM_NumberCounter__c','Object__c').keySet();
//
//        // 1) recordId -> objectKey 정규화
//        Map<String, List<Id>> idsByKey = new Map<String, List<Id>>();
//
//        for (Request request : requests) {
//            Result result = new Result();
//            result.recordId = (request == null) ? null : request.recordId;
//            result.status = 'ERROR';
//            result.message = 'Not processed';
//            results.add(result);
//
//            if (request == null || request.recordId == null) {
//                result.message = 'recordId is null';
//                continue;
//            }
//
//            String apiName = request.recordId.getSObjectType().getDescribe().getName();
//            String objectKey = normalizeKey(apiName);
//
//            if (!allowedKeys.contains(objectKey)) {
//                throw new NumberCounterException('등록된 정보가 없어서 등록불가 (Object=' + objectKey + ')');
//            }
//
//            if (!idsByKey.containsKey(objectKey)) idsByKey.put(objectKey, new List<Id>());
//            idsByKey.get(objectKey).add(request.recordId);
//
//            result.status = 'ASSIGNED';
//            result.message = 'OK';
//        }
//
//        if (idsByKey.isEmpty()) return results;
//
//        // 2) Counter 레코드 선생성(없으면 insert 시도)
//        List<COM_NumberCounter__c> toInsert = new List<COM_NumberCounter__c>();
//        for (String key : idsByKey.keySet()) {
//            toInsert.add(new COM_NumberCounter__c(
//                Key__c = key,
//                Object__c = key,
//                Sequence__c = 0
//            ));
//        }
//        Database.insert(toInsert, false); // 중복이면 DUPLICATE_VALUE 나도 무시
//
//        // 3) Counter 락 조회 (FOR UPDATE)
//        Map<String, COM_NumberCounter__c> counterByKey = new Map<String, COM_NumberCounter__c>();
//        for (COM_NumberCounter__c obj : [
//            SELECT Id, Key__c, Sequence__c
//            FROM COM_NumberCounter__c
//            WHERE Key__c IN :idsByKey.keySet()
//            FOR UPDATE
//        ]) {
//            counterByKey.put(obj.Key__c, obj);
//        }
//
//        // 4) 키별로 시퀀스 할당(벌크 대비)
//        Map<Id, Decimal> issuedById = new Map<Id, Decimal>();
//        List<COM_NumberCounter__c> countersToUpdate = new List<COM_NumberCounter__c>();
//
//        for (String key : idsByKey.keySet()) {
//            COM_NumberCounter__c counter = counterByKey.get(key);
//            if (counter == null) {
//                throw new NumberCounterException('Counter 레코드 조회 실패 (Key=' + key + ')');
//            }
//
//            Decimal seq = (counter.Sequence__c == null) ? 0 : counter.Sequence__c;
//            for (Id rid : idsByKey.get(key)) {
//                seq++;
//                issuedById.put(rid, seq);
//            }
//            counter.Sequence__c = seq;
//            countersToUpdate.add(counter);
//        }
//
//        if (!countersToUpdate.isEmpty()) update countersToUpdate;
//
//        // 5) 대상 레코드 문서번호 반영(예: DocumentNo__c)
//        Map<String, List<SObject>> updatesByObj = new Map<String, List<SObject>>();
//        for (Id recordId : issuedById.keySet()) {
//            String objApi = recordId.getSObjectType().getDescribe().getName();
//
//            Schema.SObjectType sType = Schema.getGlobalDescribe().get(objApi);
//            if (sType == null) throw new NumberCounterException('지원하지 않는 Object 입니다: ' + objApi);
//
//            SObject s = sType.newSObject();
//            s.put('Id', recordId);
//
//            // 필요 시 objApi별 prefix 규칙 반영
//            String padded = String.valueOf(Long.valueOf(issuedById.get(recordId))).leftPad(5, '0');
//            s.put('DocumentNo__c', objApi.left(3).toUpperCase() + '_' + padded);
//
//            if (!updatesByObj.containsKey(objApi)) updatesByObj.put(objApi, new List<SObject>());
//            updatesByObj.get(objApi).add(s);
//        }
//        for (String objApi : updatesByObj.keySet()) update updatesByObj.get(objApi);
//
//        // 6) 결과 매핑
//        for (Result result : results) {
//            if (result.recordId != null && issuedById.containsKey(result.recordId) && result.status == 'ASSIGNED') {
//                result.issuedNo = issuedById.get(result.recordId);
//            } else if (result.status == 'ASSIGNED') {
//                result.status = 'ERROR';
//                if (result.message == 'OK') result.message = 'Failed to issue sequence';
//            }
//        }
//
//        return results;
//    }

    private static String normalizeKey(String apiName) {
        if (String.isBlank(apiName)) return apiName;
        if (apiName.endsWith('__c')) return apiName.substring(0, apiName.length() - 3);
        return apiName;
    }
}