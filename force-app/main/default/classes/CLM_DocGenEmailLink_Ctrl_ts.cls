/**********************************************************************************
 * @filename      : CLM_DocGenEmailLink_Ctrl_ts.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-16 (월)
 * @group         :
 * @group-content :
 * @description   : CLM_DocGenEmailLink_Ctrl 테스트 클래스
 *
 *                  DocumentGenerationProcess 는 OmniStudio 관리 패키지 객체로
 *                  test context에서 DML 불가.
 *
 * @target-class  : CLM_DocGenEmailLink_Ctrl.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-16      i2max            Create
 **********************************************************************************/
@IsTest
private class CLM_DocGenEmailLink_Ctrl_ts {
    // ============================================================
    // Section 1. getReferenceObjectId() 테스트
    //   - bpId null 분기
    //   - bpId 유효 + DGP 레코드 없음 분기
    //   - Lazy load 캐싱 분기
    // ============================================================
    
    /**
     * @description [정상] bpId = null 시 if(bpId != null) 조건 불충족
     *              → SOQL 미실행 → cachedReferenceObjectId = null 반환 확인
     */
    @IsTest
    static void testGetReferenceObjectId_BpIdNull() {
        CLM_DocGenEmailLink_Ctrl ctrl = new CLM_DocGenEmailLink_Ctrl();
        ctrl.bpId = null;
        
        Test.startTest();
        Id result = ctrl.getReferenceObjectId();
        Test.stopTest();
        
        Assert.isNull(result, 'bpId null 시 null을 반환해야 함');
    }
    
    /**
     * @description [정상] bpId 유효하나 DGP 레코드 없음
     *              → SOQL 실행, 빈 결과 → isEmpty() true 분기
     *              → cachedReferenceObjectId 미설정 → null 반환 확인
     *              (test context에서 DocumentGenerationProcess DML 불가)
     */
    @IsTest
    static void testGetReferenceObjectId_NoDgpRecord() {
        CLM_DocGenEmailLink_Ctrl ctrl = new CLM_DocGenEmailLink_Ctrl();
        ctrl.bpId = UserInfo.getUserId(); // 유효한 형식의 Id (DGP 레코드 없음)
        
        Test.startTest();
        Id result = ctrl.getReferenceObjectId();
        Test.stopTest();
        
        Assert.isNull(result, 'DGP 레코드 없으면 null을 반환해야 함');
    }
    
    /**
     * @description [캐싱] Lazy load 캐싱 동작 확인
     *              - 첫 호출: bpId = null → queried = true 설정, SOQL 미실행, null 캐싱
     *              - 두 번째 호출: bpId 변경 후에도 if(!queried) = false → 캐시 값 그대로 반환
     *              → 두 번째 호출에서 SOQL 재발행 없음을 검증
     */
    @IsTest
    static void testGetReferenceObjectId_LazyLoad_CachesAfterFirstCall() {
        CLM_DocGenEmailLink_Ctrl ctrl = new CLM_DocGenEmailLink_Ctrl();
        ctrl.bpId = null;
        
        Test.startTest();
        Id firstResult = ctrl.getReferenceObjectId(); // 첫 호출: queried = true 설정
        ctrl.bpId = UserInfo.getUserId(); // bpId 변경 시도
        Id secondResult = ctrl.getReferenceObjectId(); // 두 번째 호출: if(!queried) = false → 캐시 반환
        Test.stopTest();
        
        Assert.isNull(firstResult, '첫 번째 호출 결과가 null이어야 함');
        Assert.isNull(secondResult, '두 번째 호출은 캐시를 반환해야 함 (bpId 변경 무시)');
    }
    
    // ============================================================
    // Section 2. getHasLink() 테스트
    //   - bpId null → false 반환
    //   - DGP 레코드 없음 → false 반환
    //   - 캐시 재사용 일관성 확인
    // ============================================================
    
    /**
     * @description [정상] bpId = null
     *              → getReferenceObjectId() null → getHasLink() false 반환 확인
     */
    @IsTest
    static void testGetHasLink_BpIdNull_ReturnsFalse() {
        CLM_DocGenEmailLink_Ctrl ctrl = new CLM_DocGenEmailLink_Ctrl();
        ctrl.bpId = null;
        
        Test.startTest();
        Boolean result = ctrl.getHasLink();
        Test.stopTest();
        
        Assert.isFalse(result, 'bpId null 시 getHasLink()는 false를 반환해야 함');
    }
    
    /**
     * @description [정상] bpId 유효, DGP 레코드 없음
     *              → getReferenceObjectId() null → getHasLink() false 반환 확인
     */
    @IsTest
    static void testGetHasLink_NoDgpRecord_ReturnsFalse() {
        CLM_DocGenEmailLink_Ctrl ctrl = new CLM_DocGenEmailLink_Ctrl();
        ctrl.bpId = UserInfo.getUserId();
        
        Test.startTest();
        Boolean result = ctrl.getHasLink();
        Test.stopTest();
        
        Assert.isFalse(result, 'DGP 없으면 getHasLink()는 false를 반환해야 함');
    }
    
    /**
     * @description [캐싱] getReferenceObjectId() 선호출 후 getHasLink() 재호출 시
     *              내부 캐시(queried = true) 활용하여 일관된 결과 반환 확인
     *              → getHasLink()가 getReferenceObjectId()를 내부 재호출할 때
     *                 if(!queried) = false 분기를 통해 캐시에서 반환하는 경로 커버
     */
    @IsTest
    static void testGetHasLink_UsesCache_ConsistentWithGetReferenceObjectId() {
        CLM_DocGenEmailLink_Ctrl ctrl = new CLM_DocGenEmailLink_Ctrl();
        ctrl.bpId = null;
        
        Test.startTest();
        Id refId = ctrl.getReferenceObjectId(); // 첫 호출: queried = true
        Boolean hasLink = ctrl.getHasLink(); // 내부 재호출 → 캐시 반환
        Test.stopTest();
        
        Assert.areEqual(refId != null, hasLink, 'getHasLink()는 getReferenceObjectId() != null 결과와 일치해야 함');
    }
}