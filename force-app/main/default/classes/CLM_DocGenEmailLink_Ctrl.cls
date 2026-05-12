/**********************************************************************************
 * @filename      : CLM_DocGenEmailLink_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-09 (월)
 * @group         :
 * @group-content :
 * @description   : CLM_DocGenEmailLink VF 컴포넌트 컨트롤러.
 *                  DocGenerationBatchProcess Id 기반으로 Claim 레코드 링크를 렌더링한다.
 *
 * @test-class    : CLM_DocGenEmailLink_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-09      i2max            Create
 **********************************************************************************/
public with sharing class CLM_DocGenEmailLink_Ctrl {
    // ============================================================
    // Properties
    // ============================================================
    
    /** VF component attribute assignTo 대상 (DocGenerationBatchProcess Id) */
    public Id bpId { get; set; }
    
    /** getReferenceObjectId() 결과 캐시 */
    private Id cachedReferenceObjectId;
    
    /** SOQL 중복 실행 방지 플래그 (true = 이미 조회 완료) */
    private Boolean queried = false;
    
    // ============================================================
    // Public Methods
    // ============================================================
    
    /**
     * @description bpId에 연결된 첫 번째 DocumentGenerationProcess의 ReferenceObject(Claim) Id를 반환한다.
     *              Lazy load 방식으로 SOQL은 최초 호출 시 1회만 실행한다.
     * @return Id   ReferenceObject(Claim) Id, 조회 불가 시 null
     */
    public Id getReferenceObjectId() {
        if (!queried) {
            queried = true;
            if (bpId != null) {
                List<DocumentGenerationProcess> dgps = [
                    SELECT ReferenceObject
                    FROM DocumentGenerationProcess
                    WHERE DocGenerationBatchProcessId = :bpId
                    LIMIT 1
                ];
                if (!dgps.isEmpty() && dgps[0].ReferenceObject != null) {
                    cachedReferenceObjectId = (Id) dgps[0].ReferenceObject;
                }
            }
        }
        return cachedReferenceObjectId;
    }
    
    /**
     * @description 레코드 링크 버튼 표시 여부를 반환한다.
     * @return Boolean  true = 버튼 표시, false = 버튼 미표시
     */
    public Boolean getHasLink() {
        return getReferenceObjectId() != null;
    }
}