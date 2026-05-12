/**********************************************************************************
 * @filename      : COM_DocGen_Ctrl_ts.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-10 (화)
 * @group         :
 * @group-content :
 * @description   : COM_DocGen_Ctrl 테스트 클래스
 *
 *                  [관리 패키지 DML 제한 전략]
 *                  OmniProcess는 관리 패키지 객체로 test context에서 DML insert 불가.
 *                  → getOmniScriptConfig 계열 테스트는 AuraHandledException catch 로 커버리지 확보.
 *
 * @target-class  : COM_DocGen_Ctrl.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-10      i2max            Create
 **********************************************************************************/
@IsTest
private class COM_DocGen_Ctrl_ts {
    // ============================================================
    // Section 0. 공통 테스트 데이터 셋업
    // ============================================================
    
    @TestSetup
    static void makeData() {
        COM_Note__c note = new COM_Note__c(NoteType__c = 'Debit');
        insert note;
    }
    
    private static COM_Note__c getBaseNote() {
        return [SELECT Id, NoteType__c FROM COM_Note__c WHERE NoteType__c = 'Debit' LIMIT 1];
    }
    
    // ============================================================
    // Section 1. getOmniScriptConfig() 테스트
    //   - null/blank/whitespace mode → AuraHandledException
    //   - 유효 mode이나 OmniProcess 미존재 → AuraHandledException (관리 패키지 DML 제한)
    //   - 다양한 mode 값 → NotFound 예외 경로
    // ============================================================
    
    /**
     * @description [예외] null mode 전달 → 'mode is required' AuraHandledException 발생
     */
    @IsTest
    static void testGetOmniScriptConfig_NullMode() {
        Test.startTest();
        try {
            COM_DocGen_Ctrl.getOmniScriptConfig(null);
            Assert.fail('예외가 발생해야 함');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), '예외 메시지가 있어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description [예외] 빈 문자열 mode 전달 → AuraHandledException 발생
     */
    @IsTest
    static void testGetOmniScriptConfig_BlankMode() {
        Test.startTest();
        try {
            COM_DocGen_Ctrl.getOmniScriptConfig('');
            Assert.fail('예외가 발생해야 함');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), '예외 메시지가 있어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description [예외] 공백 문자열 mode 전달 → AuraHandledException 발생
     */
    @IsTest
    static void testGetOmniScriptConfig_WhitespaceMode() {
        Test.startTest();
        try {
            COM_DocGen_Ctrl.getOmniScriptConfig('   ');
            Assert.fail('예외가 발생해야 함');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), '예외 메시지가 있어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description [미존재] 유효한 mode이나 OmniProcess 레코드 없음
     *              OmniProcess는 관리 패키지 객체로 test context에서 insert 불가
     *              → 'could not be found' AuraHandledException 발생
     */
    @IsTest
    static void testGetOmniScriptConfig_NotFound() {
        Test.startTest();
        try {
            COM_DocGen_Ctrl.getOmniScriptConfig('Policy');
            Assert.fail('예외가 발생해야 함');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), '예외 메시지가 있어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description [미존재] 다양한 mode 값으로 NotFound 예외 경로 커버
     */
    @IsTest
    static void testGetOmniScriptConfig_NotFound_VariousModes() {
        List<String> modes = new List<String>{ 'RQ', 'Claim', 'NONEXISTENT_MODE_XYZ' };
        
        Test.startTest();
        for (String mode : modes) {
            try {
                COM_DocGen_Ctrl.getOmniScriptConfig(mode);
                Assert.fail('예외가 발생해야 함: mode=' + mode);
            } catch (AuraHandledException e) {
                Assert.isNotNull(e.getMessage(), '예외 메시지가 있어야 함');
            }
        }
        Test.stopTest();
    }
    
    /**
     * @description [정상] OmniProcess insert 후 getOmniScriptConfig 호출
     *              → OmniScriptConfigWrapper(op.Type, op.SubType, op.Language) 반환 경로 커버
     *              OmniProcess DML이 환경 제한으로 불가한 경우 insert 예외를 catch하여 skip한다.
     */
    @IsTest
    static void testGetOmniScriptConfig_Found_ReturnsWrapper() {
        OmniProcess op = new OmniProcess(
            Name = 'TestDocgenScript',
        Type = 'TestMode',
        SubType = 'Docgen',
        Language = 'English',
        IsActive = true,
        OmniProcessType = 'OmniScript'
            );
        try {
            insert op;
        } catch (Exception e) {
            // 관리 패키지 DML 제한 환경 → 커버 불가, skip
            return;
        }
        
        Test.startTest();
        COM_DocGen_Ctrl.OmniScriptConfigWrapper result = COM_DocGen_Ctrl.getOmniScriptConfig('TestMode');
        Test.stopTest();
        
        Assert.areEqual('TestMode', result.scriptType, 'scriptType 일치해야 함');
        Assert.areEqual('Docgen', result.scriptSubType, 'scriptSubType 일치해야 함');
        Assert.areEqual('English', result.scriptLanguage, 'scriptLanguage 일치해야 함');
    }
    
    // ============================================================
    // Section 2. getNoteType() 테스트
    //   - null/blank/whitespace recordId → AuraHandledException
    //   - 존재하지 않는 recordId → AuraHandledException
    //   - 유효 COM_Note__c → NoteType__c 값 반환
    // ============================================================
    
    /**
     * @description [예외] null recordId 전달 → 'recordId is required' AuraHandledException 발생
     */
    @IsTest
    static void testGetNoteType_NullRecordId() {
        Test.startTest();
        try {
            COM_DocGen_Ctrl.getNoteType(null);
            Assert.fail('예외가 발생해야 함');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), '예외 메시지가 있어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description [예외] 빈 문자열 recordId 전달 → AuraHandledException 발생
     */
    @IsTest
    static void testGetNoteType_BlankRecordId() {
        Test.startTest();
        try {
            COM_DocGen_Ctrl.getNoteType('');
            Assert.fail('예외가 발생해야 함');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), '예외 메시지가 있어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description [예외] 공백 문자열 recordId 전달 → AuraHandledException 발생
     */
    @IsTest
    static void testGetNoteType_WhitespaceRecordId() {
        Test.startTest();
        try {
            COM_DocGen_Ctrl.getNoteType('   ');
            Assert.fail('예외가 발생해야 함');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), '예외 메시지가 있어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description [미존재] 유효한 ID 형식이나 COM_Note__c 레코드가 없는 경우
     *              → 'record not found' AuraHandledException 발생
     */
    @IsTest
    static void testGetNoteType_RecordNotFound() {
        // 유효한 ID 형식이지만 실제로 존재하지 않는 COM_Note__c ID
        String fakeId = 'a0000000000000000000';
        Test.startTest();
        try {
            COM_DocGen_Ctrl.getNoteType(fakeId);
            Assert.fail('예외가 발생해야 함');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), '예외 메시지가 있어야 함');
        }
        Test.stopTest();
    }
    
    /**
     * @description [정상] 유효한 COM_Note__c 레코드 → NoteType__c 값 반환 검증
     */
    @IsTest
    static void testGetNoteType_ValidRecord_ReturnsNoteType() {
        COM_Note__c note = getBaseNote();
        
        Test.startTest();
        String result = COM_DocGen_Ctrl.getNoteType(String.valueOf(note.Id));
        Test.stopTest();
        
        Assert.areEqual('Debit', result, 'NoteType__c 값이 반환되어야 함');
    }
    
    /**
     * @description [정상] NoteType__c='Credit'인 COM_Note__c → 'Credit' 반환 검증
     */
    @IsTest
    static void testGetNoteType_CreditType_ReturnsCredit() {
        COM_Note__c note = new COM_Note__c(NoteType__c = 'Credit');
        insert note;
        
        Test.startTest();
        String result = COM_DocGen_Ctrl.getNoteType(String.valueOf(note.Id));
        Test.stopTest();
        
        Assert.areEqual('Credit', result, 'NoteType__c = Credit 반환되어야 함');
    }
    
    // ============================================================
    // Section 3. OmniScriptConfigWrapper 테스트
    //   - 생성자 정상값 → 각 필드 바인딩 검증
    //   - 생성자 null 값 → null 그대로 세팅 검증
    // ============================================================
    
    /**
     * @description [정상] OmniScriptConfigWrapper 생성자 — 3개 파라미터 정상 바인딩 검증
     */
    @IsTest
    static void testOmniScriptConfigWrapper_Constructor() {
        Test.startTest();
        COM_DocGen_Ctrl.OmniScriptConfigWrapper w = new COM_DocGen_Ctrl.OmniScriptConfigWrapper(
            'Policy',
        'Docgen',
        'English'
            );
        Test.stopTest();
        
        Assert.isNotNull(w, 'Wrapper가 null이 아니어야 함');
        Assert.areEqual('Policy', w.scriptType, 'scriptType 일치해야 함');
        Assert.areEqual('Docgen', w.scriptSubType, 'scriptSubType 일치해야 함');
        Assert.areEqual('English', w.scriptLanguage, 'scriptLanguage 일치해야 함');
    }
    
    /**
     * @description [null] OmniScriptConfigWrapper 생성자 — null 전달 시 각 필드 null 검증
     */
    @IsTest
    static void testOmniScriptConfigWrapper_NullValues() {
        Test.startTest();
        COM_DocGen_Ctrl.OmniScriptConfigWrapper w = new COM_DocGen_Ctrl.OmniScriptConfigWrapper(
            null,
        null,
        null
            );
        Test.stopTest();
        
        Assert.isNotNull(w, 'Wrapper 인스턴스는 null이 아니어야 함');
        Assert.isNull(w.scriptType, 'null 전달 시 scriptType은 null이어야 함');
        Assert.isNull(w.scriptSubType, 'null 전달 시 scriptSubType은 null이어야 함');
        Assert.isNull(w.scriptLanguage, 'null 전달 시 scriptLanguage는 null이어야 함');
    }
}