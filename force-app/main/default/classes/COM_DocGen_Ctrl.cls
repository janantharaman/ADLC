/**********************************************************************************
 * @filename      : COM_DocGen_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-10 (화)
 * @group         :
 * @group-content :
 * @description   : 공통 문서 생성 LWC용 Apex 컨트롤러.
 *                  mode(OmniProcess.Type) 기반으로 활성 OmniProcess를 조회하여 OmniScript 설정을 반환한다.
 *
 * @test-class    : COM_DocGen_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-10      i2max            Create
 **********************************************************************************/
public with sharing class COM_DocGen_Ctrl {
    // ============================================================
    // Constants
    // ============================================================
    
    /** OmniProcess 조회 시 SubType 고정값 */
    private static final String OMNISCRIPT_SUBTYPE = 'Docgen';
    
    // ============================================================
    // Public Methods — AuraEnabled
    // ============================================================
    
    /**
     * @description mode(OmniProcess.Type)에 해당하는 활성 OmniProcess를 조회하여
     *              OmniScript 실행에 필요한 Type / SubType / Language 설정을 반환한다.
     *              조회 조건: Type=:mode AND SubType='Docgen' AND IsActive=true LIMIT 1.
     * @param  mode   LWC에서 전달하는 OmniProcess.Type 값 (예: 'Policy', 'RQ', 'Claim')
     * @return OmniScriptConfigWrapper  scriptType / scriptSubType / scriptLanguage 포함
     */
    @AuraEnabled(cacheable=true)
    public static OmniScriptConfigWrapper getOmniScriptConfig(String mode) {
        try {
            if (String.isBlank(mode)) {
                throw new AuraHandledException('mode is required.');
            }
            
            List<OmniProcess> processes = [
                SELECT Id, Type, SubType, Language
                FROM OmniProcess
                WHERE Type = :mode AND SubType = :OMNISCRIPT_SUBTYPE AND IsActive = TRUE
                LIMIT 1
            ];
            
            if (processes.isEmpty()) {
                throw new AuraHandledException('OmniScript configuration could not be found. (Type=' + mode + ', SubType=' + OMNISCRIPT_SUBTYPE + ')');
            }
            
            OmniProcess op = processes[0];
            return new OmniScriptConfigWrapper(op.Type, op.SubType, op.Language);
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    /**
     * @description COM_Note__c 레코드의 NoteType__c 값을 조회하여 반환한다.
     *              NoteDocGenWrapper 컴포넌트에서 OmniScript mode 결정에 사용한다.
     *              (예: NoteType__c='Debit' → mode='Debit Note')
     * @param  recordId  NoteType__c를 조회할 COM_Note__c 레코드 Id
     * @return String    NoteType__c 값
     */
    @AuraEnabled(cacheable=true)
    public static String getNoteType(String recordId) {
        try {
            if (String.isBlank(recordId)) {
                throw new AuraHandledException('recordId is required.');
            }
            
            List<COM_Note__c> notes = [
                SELECT NoteType__c
                FROM COM_Note__c
                WHERE Id = :recordId
                LIMIT 1
            ];
            
            if (notes.isEmpty()) {
                throw new AuraHandledException('COM_Note__c record not found. (Id=' + recordId + ')');
            }
            
            return notes[0].NoteType__c;
        } catch (AuraHandledException e) {
            throw e;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // ============================================================
    // Inner Classes
    // ============================================================
    
    /**
     * @description getOmniScriptConfig 반환 Wrapper. LWC OmniScript 동적 렌더링에 사용한다.
     */
    public class OmniScriptConfigWrapper {
        @AuraEnabled
        public String scriptType { get; set; } // OmniProcess.Type
        @AuraEnabled
        public String scriptSubType { get; set; } // OmniProcess.SubType (= 'Docgen')
        @AuraEnabled
        public String scriptLanguage { get; set; } // OmniProcess.Language
        
        /**
         * @description OmniProcess 조회 결과를 바인딩하는 생성자.
         * @param scriptType     OmniProcess.Type
         * @param scriptSubType  OmniProcess.SubType
         * @param scriptLanguage OmniProcess.Language
         */
        public OmniScriptConfigWrapper(String scriptType, String scriptSubType, String scriptLanguage) {
            this.scriptType = scriptType;
            this.scriptSubType = scriptSubType;
            this.scriptLanguage = scriptLanguage;
        }
    }
}