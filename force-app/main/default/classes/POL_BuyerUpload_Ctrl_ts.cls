/**********************************************************************************
 * @filename      : POL_BuyerUpload_Ctrl_ts.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-20
 * @description   : Test class for POL_BuyerUpload_Ctrl
 *                  - getBuyerFieldMetadata: 필드 메타데이터 조회 검증
 *                  - savePOLBuyers: Insert/Update/History Tracking/Deduplication 검증
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-20      i2max              Create
 **********************************************************************************/
@IsTest
private class POL_BuyerUpload_Ctrl_ts {
    // ===================================================================
    // Test Setup
    // ===================================================================
    
    /**
     * @description 테스트 공통 데이터 셋업
     *              InsurancePolicy 1건, 기존 POL_Buyer__c 1건 생성
     */
    @TestSetup
    static void setupTestData() {
        Account namedInsured = ACC_TestDataFactory.createAccount('Test Named Insured', 'General', true);
        
        InsurancePolicy policy = new InsurancePolicy(
            Name = 'Test Policy',
        NameInsuredId = namedInsured.Id,
        Status = 'InForce',
        EffectiveDate = Date.today()
            );
        insert policy;
        
        POL_Buyer__c buyer = new POL_Buyer__c(
            Policy_lk__c = policy.Id,
        CompanyName__c = 'Existing Company',
        EasyNo__c = 'EASY001',
        BuyerNo__c = 'BUYER001',
        LegalIdentValue1__c = 'LEGAL001',
        RequestDate__c = Date.today().addDays(-10),
        AmountAsked__c = 1000
            );
        insert buyer;
    }
    
    // ===================================================================
    // getBuyerFieldMetadata
    // ===================================================================
    
    /**
     * @description getBuyerFieldMetadata 정상 호출 시 핵심 필드 메타데이터 반환 검증
     */
    @IsTest
    static void testGetBuyerFieldMetadata_Success() {
        Test.startTest();
        Map<String, Object> result = POL_BuyerUpload_Ctrl.getBuyerFieldMetadata();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(!result.isEmpty(), 'Result should not be empty');
        System.assert(result.containsKey('EasyNo__c'), 'Should contain EasyNo__c');
        System.assert(result.containsKey('BuyerNo__c'), 'Should contain BuyerNo__c');
        System.assert(result.containsKey('CompanyName__c'), 'Should contain CompanyName__c');
        System.assert(result.containsKey('RequestDate__c'), 'Should contain RequestDate__c');
        System.assert(result.containsKey('AmountAsked__c'), 'Should contain AmountAsked__c');
    }
    
    /**
     * @description getBuyerFieldMetadata 반환된 필드 정보 구조 검증 (label, type, required 포함)
     */
    @IsTest
    static void testGetBuyerFieldMetadata_FieldInfoStructure() {
        Test.startTest();
        Map<String, Object> result = POL_BuyerUpload_Ctrl.getBuyerFieldMetadata();
        Test.stopTest();
        
        Map<String, Object> companyNameInfo = (Map<String, Object>) result.get('CompanyName__c');
        System.assertNotEquals(null, companyNameInfo, 'CompanyName__c metadata should exist');
        System.assert(companyNameInfo.containsKey('label'), 'Field info should have label');
        System.assert(companyNameInfo.containsKey('type'), 'Field info should have type');
        System.assert(companyNameInfo.containsKey('required'), 'Field info should have required');
        System.assert(companyNameInfo.containsKey('length'), 'Field info should have length');
    }
    
    // ===================================================================
    // savePOLBuyers - 입력값 검증 (Validation)
    // ===================================================================
    
    /**
     * @description savePOLBuyers null 입력 시 AuraHandledException 발생 검증
     */
    @IsTest
    static void testSavePOLBuyers_NullInput() {
        Test.startTest();
        try {
            POL_BuyerUpload_Ctrl.savePOLBuyers(null);
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException thrown as expected');
        }
        Test.stopTest();
    }
    
    /**
     * @description savePOLBuyers 빈 리스트 입력 시 AuraHandledException 발생 검증
     */
    @IsTest
    static void testSavePOLBuyers_EmptyInput() {
        Test.startTest();
        try {
            POL_BuyerUpload_Ctrl.savePOLBuyers(new List<Map<String, Object>>());
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(true, 'AuraHandledException thrown as expected');
        }
        Test.stopTest();
    }
    
    // ===================================================================
    // savePOLBuyers - 신규 Insert
    // ===================================================================
    
    /**
     * @description savePOLBuyers 신규 Buyer 단건 Insert 및 결과 메시지 검증
     */
    @IsTest
    static void testSavePOLBuyers_InsertNew() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'CompanyName__c' => 'New Company',
                'EasyNo__c' => 'EASY999'
            }
        };
        
        Test.startTest();
        String result = POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        System.assert(result.contains('inserted'), 'Result should say inserted');
        List<POL_Buyer__c> inserted = [SELECT Id, CompanyName__c FROM POL_Buyer__c WHERE EasyNo__c = 'EASY999'];
        System.assertEquals(1, inserted.size(), 'Should insert 1 new buyer');
        System.assertEquals('New Company', inserted[0].CompanyName__c, 'CompanyName should match');
    }
    
    /**
     * @description savePOLBuyers Policy_lk__c 없을 때 기존 키 매칭 없이 항상 신규 Insert 검증
     */
    @IsTest
    static void testSavePOLBuyers_NoPolicyId_AlwaysInsert() {
        Integer beforeCount = [SELECT COUNT() FROM POL_Buyer__c];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{ 'CompanyName__c' => 'No Policy Company', 'EasyNo__c' => 'EASY001' }
        };
        
        Test.startTest();
        String result = POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        Integer afterCount = [SELECT COUNT() FROM POL_Buyer__c];
        System.assertEquals(beforeCount + 1, afterCount, 'Should insert new buyer when no policyId');
        System.assert(result.contains('inserted'), 'Result should say inserted');
    }
    
    // ===================================================================
    // savePOLBuyers - 기존 레코드 Update (키 필드 우선순위)
    // ===================================================================
    
    /**
     * @description savePOLBuyers EasyNo__c 키 매칭(최우선)으로 기존 레코드 Update 검증
     */
    @IsTest
    static void testSavePOLBuyers_UpdateByEasyNo() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'CompanyName__c' => 'Updated By EasyNo',
                'EasyNo__c' => 'EASY001'
            }
        };
        
        Test.startTest();
        String result = POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        System.assert(result.contains('updated'), 'Result should say updated');
        POL_Buyer__c updated = [SELECT Id, CompanyName__c FROM POL_Buyer__c WHERE EasyNo__c = 'EASY001'];
        System.assertEquals('Updated By EasyNo', updated.CompanyName__c, 'CompanyName should be updated via EasyNo');
    }
    
    /**
     * @description savePOLBuyers BuyerNo__c 키 매칭으로 기존 레코드 Update 검증
     */
    @IsTest
    static void testSavePOLBuyers_UpdateByBuyerNo() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'CompanyName__c' => 'Updated By BuyerNo',
                'BuyerNo__c' => 'BUYER001'
            }
        };
        
        Test.startTest();
        String result = POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        System.assert(result.contains('updated'), 'Result should say updated');
        POL_Buyer__c updated = [SELECT Id, CompanyName__c FROM POL_Buyer__c WHERE BuyerNo__c = 'BUYER001'];
        System.assertEquals('Updated By BuyerNo', updated.CompanyName__c, 'CompanyName should be updated via BuyerNo');
    }
    
    /**
     * @description savePOLBuyers LegalIdentValue1__c 키 매칭으로 기존 레코드 Update 검증
     */
    @IsTest
    static void testSavePOLBuyers_UpdateByLegalIdentValue() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'CompanyName__c' => 'Updated By Legal',
                'LegalIdentValue1__c' => 'LEGAL001'
            }
        };
        
        Test.startTest();
        String result = POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        System.assert(result.contains('updated'), 'Result should say updated');
        POL_Buyer__c updated = [SELECT Id, CompanyName__c FROM POL_Buyer__c WHERE LegalIdentValue1__c = 'LEGAL001'];
        System.assertEquals(
            'Updated By Legal',
        updated.CompanyName__c,
        'CompanyName should be updated via LegalIdentValue1'
            );
    }
    
    // ===================================================================
    // savePOLBuyers - History Tracking
    // ===================================================================
    
    /**
     * @description savePOLBuyers AmountAsked__c 값 변경 시 AmtAskedOld__c에 이전값 저장 검증
     */
    @IsTest
    static void testSavePOLBuyers_HistoryTracking_AmountChanged() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{ 'Policy_lk__c' => policy.Id, 'EasyNo__c' => 'EASY001', 'AmountAsked__c' => 9999 }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c updated = [SELECT AmountAsked__c, AmtAskedOld__c FROM POL_Buyer__c WHERE EasyNo__c = 'EASY001'];
        System.assertEquals(9999, updated.AmountAsked__c, 'AmountAsked__c should be updated to 9999');
        System.assertEquals(1000, updated.AmtAskedOld__c, 'AmtAskedOld__c should hold previous value 1000');
    }
    
    /**
     * @description savePOLBuyers RequestDate__c 값 변경 시 RequestDateOld__c에 이전값 저장 검증
     */
    @IsTest
    static void testSavePOLBuyers_HistoryTracking_RequestDateChanged() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        POL_Buyer__c existing = [SELECT RequestDate__c FROM POL_Buyer__c WHERE EasyNo__c = 'EASY001'];
        Date oldDate = existing.RequestDate__c;
        Date newDate = Date.today();
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'EASY001',
                'RequestDate__c' => newDate
            }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c updated = [SELECT RequestDate__c, RequestDateOld__c FROM POL_Buyer__c WHERE EasyNo__c = 'EASY001'];
        System.assertEquals(newDate, updated.RequestDate__c, 'RequestDate__c should be updated');
        System.assertEquals(oldDate, updated.RequestDateOld__c, 'RequestDateOld__c should hold previous date');
    }
    
    /**
     * @description savePOLBuyers 동일한 값으로 업데이트 시 Old 필드가 변경되지 않음을 검증
     */
    @IsTest
    static void testSavePOLBuyers_HistoryTracking_SameValue_NoChange() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{ 'Policy_lk__c' => policy.Id, 'EasyNo__c' => 'EASY001', 'AmountAsked__c' => 1000 }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c updated = [SELECT AmtAskedOld__c FROM POL_Buyer__c WHERE EasyNo__c = 'EASY001'];
        System.assertEquals(null, updated.AmtAskedOld__c, 'AmtAskedOld__c should remain null when value is unchanged');
    }
    
    // ===================================================================
    // savePOLBuyers - 중복 제거 (Deduplication)
    // ===================================================================
    
    /**
     * @description savePOLBuyers 동일 EasyNo__c 중복 데이터 입력 시 단건만 upsert 검증
     */
    @IsTest
    static void testSavePOLBuyers_Deduplication() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'EASY001',
                'CompanyName__c' => 'First Update'
            },
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'EASY001',
                'CompanyName__c' => 'Second Update'
            }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        List<POL_Buyer__c> result = [SELECT Id FROM POL_Buyer__c WHERE EasyNo__c = 'EASY001'];
        System.assertEquals(1, result.size(), 'Should have only 1 buyer with EASY001 after deduplication');
    }
    
    // ===================================================================
    // savePOLBuyers - 타입 변환 (Type Conversion)
    // ===================================================================
    
    /**
     * @description savePOLBuyers String → Date 타입 변환 후 정상 저장 검증
     */
    @IsTest
    static void testSavePOLBuyers_StringToDateConversion() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'CompanyName__c' => 'Date Conversion Company',
                'EasyNo__c' => 'DATE001',
                'RequestDate__c' => '2025-06-15'
            }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c inserted = [SELECT RequestDate__c FROM POL_Buyer__c WHERE EasyNo__c = 'DATE001'];
        System.assertEquals(
            Date.newInstance(2025, 6, 15),
        inserted.RequestDate__c,
        'String date should be converted to Date'
            );
    }
    
    /**
     * @description savePOLBuyers Decimal 타입 값 정상 저장 검증
     */
    @IsTest
    static void testSavePOLBuyers_DecimalTypeValue() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'CompanyName__c' => 'Decimal Company',
                'EasyNo__c' => 'DEC001',
                'AmountAsked__c' => 12345.67
            }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c inserted = [SELECT AmountAsked__c FROM POL_Buyer__c WHERE EasyNo__c = 'DEC001'];
        System.assertEquals(12345.67, inserted.AmountAsked__c, 'Decimal value should be saved correctly');
    }
    
    // ===================================================================
    // savePOLBuyers - Insert + Update 혼합
    // ===================================================================
    
    /**
     * @description savePOLBuyers Insert + Update 혼합 처리 시 결과 메시지에 양쪽 카운트 반영 검증
     */
    @IsTest
    static void testSavePOLBuyers_InsertAndUpdate_Mixed() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'EASY001',
                'CompanyName__c' => 'Updated Existing'
            },
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'EASY_NEW',
                'CompanyName__c' => 'Brand New Company'
            }
        };
        
        Test.startTest();
        String result = POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        System.assert(result.contains('2'), 'Result should mention 2 total buyers');
        System.assert(result.contains('inserted'), 'Result should mention inserted');
        System.assert(result.contains('updated'), 'Result should mention updated');
        
        List<POL_Buyer__c> newBuyer = [SELECT Id FROM POL_Buyer__c WHERE EasyNo__c = 'EASY_NEW'];
        System.assertEquals(1, newBuyer.size(), 'New buyer should be inserted');
    }
    
    /**
     * @description savePOLBuyers 복수 신규 Insert 시 결과 메시지에 inserted 카운트만 반영 검증
     */
    @IsTest
    static void testSavePOLBuyers_MultipleInsert_MessageCheck() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'NEW001',
                'CompanyName__c' => 'New Company 1'
            },
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'NEW002',
                'CompanyName__c' => 'New Company 2'
            }
        };
        
        Test.startTest();
        String result = POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        System.assert(result.contains('2'), 'Result should mention 2 buyers');
        System.assert(result.contains('inserted'), 'Result should say inserted only');
        System.assert(!result.contains('updated'), 'Result should not say updated');
    }
    
    // ===================================================================
    // 추가 커버리지 향상 테스트
    // ===================================================================
    
    /**
     * @description savePOLBuyers Update만 있을 때 결과 메시지에 'updated'만 포함 검증
     *              (else if updateCount > 0 분기 커버)
     */
    @IsTest
    static void testSavePOLBuyers_UpdateOnly_MessageCheck() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'EASY001',
                'CompanyName__c' => 'Update Only Company'
            }
        };
        
        Test.startTest();
        String result = POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        System.assert(result.contains('updated'), 'Result should say updated');
        System.assert(!result.contains('inserted'), 'Result should NOT say inserted');
    }
    
    /**
     * @description savePOLBuyers String 타입 이력 필드(CurrencyAmtAsked__c) 변경 시
     *              CurrencyAmtAskedOld__c에 이전값 저장 검증 (history tracking else-String 분기 커버)
     */
    @IsTest
    static void testSavePOLBuyers_HistoryTracking_StringFieldChanged() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        // 기존 레코드에 CurrencyAmtAsked__c 값 세팅 후 변경
        POL_Buyer__c existing = [SELECT Id FROM POL_Buyer__c WHERE EasyNo__c = 'EASY001'];
        existing.CurrencyAmtAsked__c = 'USD';
        update existing;
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'EASY001',
                'CurrencyAmtAsked__c' => 'EUR'
            }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c updated = [
            SELECT CurrencyAmtAsked__c, CurrencyAmtAskedOld__c
            FROM POL_Buyer__c
            WHERE EasyNo__c = 'EASY001'
        ];
        System.assertEquals('EUR', updated.CurrencyAmtAsked__c, 'CurrencyAmtAsked__c should be updated');
        System.assertEquals('USD', updated.CurrencyAmtAskedOld__c, 'CurrencyAmtAskedOld__c should hold previous value');
    }
    
    /**
     * @description savePOLBuyers Date 타입 값을 Date 객체로 직접 전달 시 정상 저장 검증
     *              (value instanceof Date 분기 커버)
     */
    @IsTest
    static void testSavePOLBuyers_DateObjectDirectValue() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        Date targetDate = Date.newInstance(2025, 9, 30);
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'DATEOBJ001',
                'RequestDate__c' => targetDate
            }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c inserted = [SELECT RequestDate__c FROM POL_Buyer__c WHERE EasyNo__c = 'DATEOBJ001'];
        System.assertEquals(targetDate, inserted.RequestDate__c, 'Date object should be saved correctly');
    }
    
    /**
     * @description savePOLBuyers 이력 추적 시 RequestDate__c를 String으로 전달하여
     *              DATE 비교 로직의 newValue instanceof String 분기 커버
     */
    @IsTest
    static void testSavePOLBuyers_HistoryTracking_RequestDate_AsString() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        POL_Buyer__c existing = [SELECT RequestDate__c FROM POL_Buyer__c WHERE EasyNo__c = 'EASY001'];
        Date oldDate = existing.RequestDate__c;
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'EASY001',
                'RequestDate__c' => '2025-06-15'
            }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c updated = [SELECT RequestDate__c, RequestDateOld__c FROM POL_Buyer__c WHERE EasyNo__c = 'EASY001'];
        System.assertEquals(
            Date.newInstance(2025, 6, 15),
        updated.RequestDate__c,
        'RequestDate__c should be updated from string'
            );
        System.assertEquals(oldDate, updated.RequestDateOld__c, 'RequestDateOld__c should hold previous date');
    }
    
    /**
     * @description savePOLBuyers 기존 Date 필드가 null인 레코드 업데이트 시
     *              currentDate == null로 비교 조건 false → 이력 미저장 검증
     *              (if (currentDate != null && newDate != null) false 분기 커버)
     */
    @IsTest
    static void testSavePOLBuyers_HistoryTracking_NullExistingDate() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        POL_Buyer__c nullDateBuyer = new POL_Buyer__c(Policy_lk__c = policy.Id, EasyNo__c = 'NULLDATE001');
        insert nullDateBuyer;
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'NULLDATE001',
                'RequestDate__c' => Date.today()
            }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c updated = [
            SELECT RequestDate__c, RequestDateOld__c
            FROM POL_Buyer__c
            WHERE EasyNo__c = 'NULLDATE001'
        ];
        System.assertEquals(Date.today(), updated.RequestDate__c, 'RequestDate__c should be set');
        System.assertEquals(
            null,
        updated.RequestDateOld__c,
        'RequestDateOld__c should remain null when existing was null'
            );
    }
    
    /**
     * @description savePOLBuyers 기존 Decimal 필드가 null인 레코드 업데이트 시
     *              currentDecimal == null로 비교 조건 false → 이력 미저장 검증
     *              (if (currentDecimal != null && newDecimal != null) false 분기 커버)
     */
    @IsTest
    static void testSavePOLBuyers_HistoryTracking_NullExistingDecimal() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        POL_Buyer__c nullDecBuyer = new POL_Buyer__c(Policy_lk__c = policy.Id, EasyNo__c = 'NULLMIN001');
        insert nullDecBuyer;
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{ 'Policy_lk__c' => policy.Id, 'EasyNo__c' => 'NULLMIN001', 'MinShipAmt__c' => 500 }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c updated = [
            SELECT MinShipAmt__c, MinShipAmtOld__c
            FROM POL_Buyer__c
            WHERE EasyNo__c = 'NULLMIN001'
        ];
        System.assertEquals(500, updated.MinShipAmt__c, 'MinShipAmt__c should be updated');
        System.assertEquals(
            null,
        updated.MinShipAmtOld__c,
        'MinShipAmtOld__c should remain null when existing was null'
            );
    }
    
    /**
     * @description savePOLBuyers 이력 추적 시 신규값을 Decimal 타입으로 전달하여
     *              newValue instanceof Decimal 분기 커버
     */
    @IsTest
    static void testSavePOLBuyers_HistoryTracking_AmountAsDecimal() {
        InsurancePolicy policy = [SELECT Id FROM InsurancePolicy LIMIT 1];
        
        List<Map<String, Object>> buyers = new List<Map<String, Object>>{
            new Map<String, Object>{
                'Policy_lk__c' => policy.Id,
                'EasyNo__c' => 'EASY001',
                'AmountAsked__c' => 8888.88
            }
        };
        
        Test.startTest();
        POL_BuyerUpload_Ctrl.savePOLBuyers(buyers);
        Test.stopTest();
        
        POL_Buyer__c updated = [SELECT AmountAsked__c, AmtAskedOld__c FROM POL_Buyer__c WHERE EasyNo__c = 'EASY001'];
        System.assertEquals(8888.88, updated.AmountAsked__c, 'AmountAsked__c should be updated to Decimal value');
        System.assertEquals(
            1000,
        updated.AmtAskedOld__c,
        'AmtAskedOld__c should hold previous value when Decimal passed'
            );
    }
}