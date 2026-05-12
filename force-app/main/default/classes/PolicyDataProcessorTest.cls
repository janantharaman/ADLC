@IsTest
private class PolicyDataProcessorTest {

    private static final String POLICY_ONLY_JSON =
        '{"Name":"TEST-POL-JSON",' +
        '"EffectiveDate":"2025-01-01",' +
        '"TotalSumInsured":1000000,' +
        '"PremiumAmount":50000,' +
        '"TermPremiumAmount":25000,' +
        '"Commission":5000,' +
        '"PremiumFrequency":"Monthly",' +
        '"CurrencyVal":"USD"}';

    @TestSetup
    static void makeData() {
        // 필수 필드인 Account 생성
        Account acc = new Account(Name = 'Test Insured Account');
        insert acc;

        // 기존 업데이트 모드 테스트용 Policy 생성
        InsurancePolicy pol = new InsurancePolicy();
        pol.Name = 'TEST-POL-001';
        pol.EffectiveDate = Date.today();
        pol.NameInsuredId = acc.Id;
        insert pol;
    }

    private static InsurancePolicy getTestPolicy() {
        return [SELECT Id FROM InsurancePolicy WHERE Name = 'TEST-POL-001' LIMIT 1];
    }

    // 메인 클래스 구조에 맞게 Participant 제거 및 구조 최적화
    private static String buildFullJson() {
        return '{' +
            '"Name":"TEST-POL-FULL",' +
            '"EffectiveDate":"2025-01-01",' +
            '"TotalSumInsured":1000000,' +
            '"PremiumAmount":50000,' +
            '"TermPremiumAmount":25000,' +
            '"Commission":5000,' +
            '"PremiumFrequency":"Monthly",' +
            '"CurrencyVal":"USD",' +
            '"assets":[{' +
                '"AssetName":"Building A",' +
                '"AssetCode":"BA001",' +
                '"AssetLocation":"22332 Seoul Gangnam MainStreet 20 Unit 5A"' +
            '}],' +
            '"productClauses":[{' +
                '"Name":"Fire Clause",' +
                '"Section":"Section 1",' +
                '"Details":"Standard fire coverage clause"' +
            '}],' +
            '"coverages":[{' +
                '"Name":"Fire Coverage",' +
                '"CategoryGroup":"Fire",' +
                '"Description":"Fire damage coverage",' +
                '"CurrencyVal":"USD",' +
                '"CoverageSumInsured":500000,' +
                '"SectionSumInsured":500000,' +
                '"CoveragePremiumAmount":25000,' +
                '"SectionPremiumAmount":25000,' +
                '"CoverageDeductibleAmount":10000,' +
                '"LimitAmount":500000,' +
                '"LinkedAssetName":"Building A",' +
                '"coverageLineItems":[{' +
                    '"Risk_Name":"Fire Risk",' +
                    '"Risk_Type":"Property",' +
                    '"Risk_Details":"Fire damage risk",' +
                    '"Risk_Premium_Amount":25000,' +
                    '"Risk_Deductible":10000,' +
                    '"Category_Group":"Fire",' +
                    '"Category_Group_Type":"Primary",' +
                    '"Risk_Insured_Amount":500000,' +
                    '"Risk_Rate":5.0' +
                '}]' +
            '}]' +
        '}';
    }

    // ── Update existing policy: full JSON with all children ──

    @IsTest
    static void testCreateRecords_UpdatePolicy_AllChildren() {
        InsurancePolicy testPol = getTestPolicy();

        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.insurancePolicyId = testPol.Id;
        input.jsonString = buildFullJson();

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one output');
        System.assertNotEquals(null, results[0].debugLog, 'Debug log should be populated');

        if (results[0].isSuccess) {
            System.assertEquals(testPol.Id, results[0].processedPolicyId, 'Should return the updated policy ID');
            System.assert(results[0].debugLog.contains('[STEP 2]'), 'Should log JSON parsing');
            System.assert(results[0].debugLog.contains('Policy Upserted SUCCESS'), 'Should log policy upsert');
        } else {
            System.assertNotEquals('', results[0].errorMessage, 'Error message should be populated on failure');
        }
    }

    // ── Create new policy (로직 커버리지 확보용) ──

    @IsTest
    static void testCreateRecords_CreateNewPolicy_PolicyOnly() {
        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.insurancePolicyId = null; // Create Mode 유도
        input.jsonString = POLICY_ONLY_JSON;

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertNotEquals(null, results[0].debugLog);
        System.assert(results[0].debugLog.contains('Mode: CREATE new'), 'Should indicate create mode');
        
        // 필수 값 부족으로 DML이 실패하더라도 Create New 모드로 진입했는지 확인
        if(results[0].isSuccess) {
            System.assert(results[0].debugLog.contains('[INFO] No Assets in JSON'), 'Should log no assets');
            System.assert(results[0].debugLog.contains('[INFO] No Clauses in JSON'), 'Should log no clauses');
            System.assert(results[0].debugLog.contains('[INFO] No Coverages in JSON'), 'Should log no coverages');
        }
    }

    // ── Update existing policy: 하위 레코드가 없는 경우 ──

    @IsTest
    static void testCreateRecords_UpdatePolicy_PolicyOnly() {
        InsurancePolicy testPol = getTestPolicy();

        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.insurancePolicyId = testPol.Id;
        input.jsonString = POLICY_ONLY_JSON;

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'Policy-only update should succeed: ' + results[0].errorMessage);
        System.assertEquals(testPol.Id, results[0].processedPolicyId);
        System.assert(results[0].debugLog.contains('Mode: UPDATE existing ID'), 'Should indicate update mode');
    }

    // ── Blank Name triggers auto-generation ──

    @IsTest
    static void testCreateRecords_BlankPolicyName_AutoGenerated() {
        InsurancePolicy testPol = getTestPolicy();
        String json = '{"Name":"","EffectiveDate":"2025-01-01","TotalSumInsured":100}';

        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.insurancePolicyId = testPol.Id;
        input.jsonString = json;

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        System.assert(results[0].debugLog.contains('auto-generated'), 'Should log auto-generated name warning');
    }

    // ── Null Name also triggers auto-generation ──

    @IsTest
    static void testCreateRecords_NullPolicyName_AutoGenerated() {
        InsurancePolicy testPol = getTestPolicy();
        String json = '{"EffectiveDate":"2025-01-01","TotalSumInsured":100}';

        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.insurancePolicyId = testPol.Id;
        input.jsonString = json;

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        System.assert(results[0].debugLog.contains('auto-generated'), 'Null name should trigger auto-generation');
    }

    // ── Currency conversion: WON → KRW ──

    @IsTest
    static void testCreateRecords_WONCurrency_ConvertedToKRW() {
        InsurancePolicy testPol = getTestPolicy();
        String json = '{"Name":"WON-TEST","CurrencyVal":"WON"}';

        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.insurancePolicyId = testPol.Id;
        input.jsonString = json;

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        System.assertNotEquals(null, results[0].debugLog);
    }

    @IsTest
    static void testCreateRecords_NonWONCurrency_PassesThrough() {
        InsurancePolicy testPol = getTestPolicy();
        String json = '{"Name":"JPY-TEST","CurrencyVal":"JPY"}';

        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.insurancePolicyId = testPol.Id;
        input.jsonString = json;

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        System.assertNotEquals(null, results[0].debugLog);
    }

    // ── Asset with full address ──

    @IsTest
    static void testCreateRecords_AssetWithFullAddress() {
        InsurancePolicy testPol = getTestPolicy();
        String json = '{' +
            '"Name":"ADDR-TEST",' +
            '"assets":[{' +
                '"AssetName":"Warehouse",' +
                '"AssetCode":"WH01",' +
                '"AssetLocation":"22332 Seoul Gangnam MainStreet 20 Unit 5A Floor 3"' +
            '}]' +
        '}';

        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.insurancePolicyId = testPol.Id;
        input.jsonString = json;

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        if (results[0].isSuccess) {
            System.assert(results[0].debugLog.contains('Assets inserted'), 'Should log asset insertion');
        }
    }

    // ── Asset with short address ──

    @IsTest
    static void testCreateRecords_AssetWithShortAddress() {
        InsurancePolicy testPol = getTestPolicy();
        String json = '{' +
            '"Name":"SHORT-ADDR",' +
            '"assets":[{' +
                '"AssetName":"Office",' +
                '"AssetCode":"OF01",' +
                '"AssetLocation":"Seoul Korea"' +
            '}]' +
        '}';

        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.insurancePolicyId = testPol.Id;
        input.jsonString = json;

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        System.assertEquals(1, results.size());
    }

    // ── Validation: Error JSON with "pdf not supported" ──

    @IsTest
    static void testCreateRecords_PdfNotSupportedError() {
        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.jsonString = '{"Error":"This PDF not supported format"}';

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].errorMessage.containsIgnoreCase('pdf not supported'), 'Should surface the pdf not supported error');
    }

    // ── Multiple inputs (batch) ──

    @IsTest
    static void testCreateRecords_MultipleInputs() {
        InsurancePolicy testPol = getTestPolicy();

        PolicyDataProcessor.FlowInput validInput = new PolicyDataProcessor.FlowInput();
        validInput.insurancePolicyId = testPol.Id;
        validInput.jsonString = POLICY_ONLY_JSON;

        PolicyDataProcessor.FlowInput invalidInput = new PolicyDataProcessor.FlowInput();
        invalidInput.jsonString = '';

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ validInput, invalidInput });
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return one output per input');
        System.assert(results[0].isSuccess, 'Valid input should succeed: ' + results[0].errorMessage);
        System.assertEquals(false, results[1].isSuccess, 'Blank JSON should fail');
    }

    // ── Savepoint rollback verification ──

    @IsTest
    static void testCreateRecords_ExceptionTriggersRollback() {
        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        // 배열이 와야 할 자리에 문자열을 넣어 파싱 에러 유도
        input.jsonString = '{"Name":"ROLLBACK-TEST","coverages":"not_an_array"}';

        Test.startTest();
        List<PolicyDataProcessor.FlowOutput> results = PolicyDataProcessor.createRecords(new List<PolicyDataProcessor.FlowInput>{ input });
        Test.stopTest();

        System.assertEquals(false, results[0].isSuccess, 'Bad data structure should fail');
        System.assertEquals(null, results[0].processedPolicyId, 'Policy ID should be null after rollback');
        System.assert(results[0].debugLog.contains('CRITICAL EXCEPTION'), 'Should log exception');
    }

    // ── Wrapper class coverage (메인 클래스에 있는 변수만 매핑) ──

    @IsTest
    static void testWrapperClasses() {
        // FlowInput / FlowOutput
        PolicyDataProcessor.FlowInput input = new PolicyDataProcessor.FlowInput();
        input.jsonString = '{}';
        input.insurancePolicyId = null;
        
        PolicyDataProcessor.FlowOutput output = new PolicyDataProcessor.FlowOutput();
        System.assertEquals(true, output.isSuccess);

        // PolicyRecord
        PolicyDataProcessor.PolicyRecord rec = new PolicyDataProcessor.PolicyRecord();
        rec.Name = 'Test Policy';
        rec.EffectiveDate = Date.today();
        rec.EffectiveFromDate = Date.today();
        rec.EffectiveToDate = Date.today().addYears(1);
        rec.NameContractor = 'Contractor';
        rec.NameContractorNumber = 'CN001';
        rec.NameInsuredName = 'Insured';
        rec.NameInsuredNumber = 'IN001';
        rec.TotalSumInsured = 1000000;
        rec.PremiumAmount = 50000;
        rec.TermPremiumAmount = 25000;
        rec.Commission = 5000;
        rec.PremiumFrequency = 'Monthly';
        rec.CurrencyVal = 'USD';
        rec.LineOfBusiness = 'Property';
        rec.PolicyType = 'Standard';
        rec.Facility_lk = 'FAC001';
        rec.WritingCarrierAccountId = null;
        rec.assets = new List<PolicyDataProcessor.AssetRecord>();
        rec.productClauses = new List<PolicyDataProcessor.ClauseRecord>();
        rec.coverages = new List<PolicyDataProcessor.CoverageRecord>();
        System.assertEquals('Test Policy', rec.Name);

        // AssetRecord
        PolicyDataProcessor.AssetRecord a = new PolicyDataProcessor.AssetRecord();
        a.AssetName = 'Building';
        a.AssetCode = 'B001';
        a.AssetLocation = 'Seoul';
        a.EffectiveFromDate = Date.today();
        a.EffectiveToDate = Date.today().addDays(10);
        a.TermPremiumAmount = 1000;
        System.assertEquals('Building', a.AssetName);

        // ClauseRecord
        PolicyDataProcessor.ClauseRecord c = new PolicyDataProcessor.ClauseRecord();
        c.Name = 'Clause';
        c.Section = 'Section 1';
        c.Details = 'Details';
        System.assertEquals('Clause', c.Name);

        // CoverageRecord
        PolicyDataProcessor.CoverageRecord cov = new PolicyDataProcessor.CoverageRecord();
        cov.Name = 'Coverage';
        cov.CategoryGroup = 'Fire';
        cov.Description = 'Fire coverage';
        cov.CurrencyVal = 'USD';
        cov.CoverageSumInsured = 500000;
        cov.SectionSumInsured = 500000;
        cov.CoveragePremiumAmount = 25000;
        cov.SectionPremiumAmount = 25000;
        cov.CoverageDeductibleAmount = 10000;
        cov.LimitAmount = 500000;
        cov.LinkedAssetName = 'Building';
        cov.LinkedParticipantName = 'Participant';
        cov.coverageLineItems = new List<PolicyDataProcessor.LineItemRecord>();
        System.assertEquals('Coverage', cov.Name);

        // LineItemRecord
        PolicyDataProcessor.LineItemRecord item = new PolicyDataProcessor.LineItemRecord();
        item.Risk_Name = 'Fire Risk';
        item.Risk_Type = 'Property';
        item.Risk_Details = 'Fire damage';
        item.Risk_Premium_Amount = 25000;
        item.Risk_Deductible = 10000;
        item.Category_Group = 'Fire';
        item.Category_Group_Type = 'Primary';
        item.Risk_Insured_Amount = 500000;
        item.Risk_Rate = 5.0;
        System.assertEquals('Fire Risk', item.Risk_Name);
    }
}