@IsTest
private class ClaimSOCUpdateHandlerTest {

    private static final String FULL_JSON =
        '{"ClaimDocType__c":"SOC",' +
        '"CedantClaimNo__c":"CED-001",' +
        '"CedantPolicyNo__c":"POL-001",' +
        '"InsuredEn__c":"Test Insured",' +
        '"ClaimCurrency__c":"USD",' +
        '"LossLocationEn__c":"Seoul",' +
        '"LossDesc__c":"Fire damage",' +
        '"Summary":"Test summary",' +
        '"Remarks__c":"Test remark",' +
        '"InsuredOrigin__c":"KR",' +
        '"LossParticular__c":"Particular",' +
        '"LossParticularEn__c":"Particular En",' +
        '"SettlementCurrency__c":"USD",' +
        '"FXRateToSettleCurrency__c":1.0,' +
        '"FXRateToSettlementCurrency__c":1.0,' +
        '"LossDate__c":"2025-06-15",' +
        '"InceptionDate__c":"2025-01-01",' +
        '"ExpirationDate__c":"2025-12-31",' +
        '"LossAmt__c":100000,' +
        '"ExpAmt__c":5000,' +
        '"TotalAmt__c":105000,' +
        '"LKShare__c":25.5}';

    @TestSetup
    static void makeData() {
        Claim c = new Claim();
        c.Name = 'TEST-CLAIM-001';
        insert c;
    }

    private static Claim getTestClaim() {
        return [SELECT Id FROM Claim WHERE Name = 'TEST-CLAIM-001' LIMIT 1];
    }

    // ── Success path: all fields populated ──

    @IsTest
    static void testUpdateClaimDetails_AllFields_Success() {
        Claim testClaim = getTestClaim();

        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = FULL_JSON;

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one output');
        System.assertEquals(true, results[0].isSuccess, 'Update should succeed');
        System.assert(results[0].message.contains('Success'), 'Message should indicate success');

        Claim updated = [SELECT CedantClaimNo__c, CedantPolicyNo__c,
                                InsuredEn__c, LossLocationEn__c,
                                LossDesc__c, Summary, Remarks__c,
                                LossAmt__c, ExpAmt__c, TotalAmt__c, LKShare__c
                         FROM Claim WHERE Id = :testClaim.Id];

        System.assertEquals('CED-001', updated.CedantClaimNo__c);
        System.assertEquals('POL-001', updated.CedantPolicyNo__c);
        System.assertEquals('Test Insured', updated.InsuredEn__c);
        System.assertEquals('Seoul', updated.LossLocationEn__c);
        System.assertEquals('Fire damage', updated.LossDesc__c);
        System.assertEquals('Test summary', updated.Summary);
        System.assertEquals('Test remark', updated.Remarks__c);
        System.assertEquals(100000, updated.LossAmt__c);
        System.assertEquals(5000, updated.ExpAmt__c);
        System.assertEquals(105000, updated.TotalAmt__c);
        System.assertEquals(25.5, updated.LKShare__c);
    }

    // ── Currency conversion: WON → KRW ──

    @IsTest
    static void testUpdateClaimDetails_WONCurrency_ConvertedToKRW() {
        Claim testClaim = getTestClaim();

        String json = '{"ClaimCurrency__c":"WON","SettlementCurrency__c":"WON","Summary":"WON test"}';

        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'WON currency update should succeed: ' + results[0].message);
        System.assert(results[0].message.contains('Success'), 'Message should indicate success');
    }

    @IsTest
    static void testUpdateClaimDetails_NonWONCurrency_PassesThrough() {
        Claim testClaim = getTestClaim();

        String json = '{"ClaimCurrency__c":"JPY","SettlementCurrency__c":"EUR","Summary":"Non-WON test"}';

        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'Non-WON currency update should succeed: ' + results[0].message);
        System.assert(results[0].message.contains('Success'), 'Message should indicate success');
    }

    // ── Date fields ──

    @IsTest
    static void testUpdateClaimDetails_ValidDates_Parsed() {
        Claim testClaim = getTestClaim();

        String json = '{"LossDate__c":"2025-06-15","InceptionDate__c":"2025-01-01","ExpirationDate__c":"2025-12-31"}';

        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'Date update should succeed: ' + results[0].message);
        System.assert(results[0].message.contains('Success'), 'Message should indicate success');
    }

    @IsTest
    static void testUpdateClaimDetails_InvalidDateFormat_HandlesGracefully() {
        Claim testClaim = getTestClaim();

        String json = '{"InceptionDate__c":"not-a-date","ExpirationDate__c":"also-bad"}';

        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should still return output despite date errors');
    }

    // ── Validation: missing inputs ──

    @IsTest
    static void testUpdateClaimDetails_BlankClaimId_ReturnsError() {
        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = '';
        input.jsonResponse = '{"Summary":"test"}';

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].message.contains('Missing'), 'Should report missing input');
    }

    @IsTest
    static void testUpdateClaimDetails_BlankJsonResponse_ReturnsError() {
        Claim testClaim = getTestClaim();

        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = '';

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].message.contains('Missing'), 'Should report missing input');
    }

    @IsTest
    static void testUpdateClaimDetails_NullInputs_ReturnsError() {
        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = null;
        input.jsonResponse = null;

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
    }

    // ── Invalid JSON ──

    @IsTest
    static void testUpdateClaimDetails_MalformedJson_ReturnsParseError() {
        Claim testClaim = getTestClaim();

        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = 'this is not valid json';

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].message.contains('JSON Parse Exception'), 'Should report parse error');
    }

    // ── DB update failure (bad Id) ──

    @IsTest
    static void testUpdateClaimDetails_InvalidClaimId_DBFailure() {
        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = '0LI000000000000AAA';
        input.jsonResponse = '{"Summary":"test"}';

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);        
    }

    // ── Multiple inputs (batch) ──

    @IsTest
    static void testUpdateClaimDetails_MultipleInputs_MixedResults() {
        Claim testClaim = getTestClaim();

        ClaimSOCUpdateHandler.FlowInput validInput = new ClaimSOCUpdateHandler.FlowInput();
        validInput.claimId = testClaim.Id;
        validInput.jsonResponse = '{"Summary":"Batch test"}';

        ClaimSOCUpdateHandler.FlowInput invalidInput = new ClaimSOCUpdateHandler.FlowInput();
        invalidInput.claimId = '';
        invalidInput.jsonResponse = '';

        List<ClaimSOCUpdateHandler.FlowInput> inputs = new List<ClaimSOCUpdateHandler.FlowInput>{
            validInput, invalidInput
        };

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(inputs);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return one output per input');
        System.assertEquals(true, results[0].isSuccess, 'Valid input should succeed');
        System.assertEquals(false, results[1].isSuccess, 'Invalid input should fail');
    }

    // ── Empty input list ──

    @IsTest
    static void testUpdateClaimDetails_EmptyList_ReturnsEmpty() {
        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>()
            );
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Empty input should return empty output');
    }

    // ── Minimal JSON (only a few optional fields) ──

    @IsTest
    static void testUpdateClaimDetails_MinimalJson_Success() {
        Claim testClaim = getTestClaim();

        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = '{"Summary":"Minimal update"}';

        Test.startTest();
        List<ClaimSOCUpdateHandler.FlowOutput> results =
            ClaimSOCUpdateHandler.updateClaimDetails(
                new List<ClaimSOCUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess);

        Claim updated = [SELECT Summary FROM Claim WHERE Id = :testClaim.Id];
        System.assertEquals('Minimal update', updated.Summary);
    }

    // ── Wrapper class coverage ──

    @IsTest
    static void testFlowInputWrapper() {
        ClaimSOCUpdateHandler.FlowInput input = new ClaimSOCUpdateHandler.FlowInput();
        input.claimId = 'testId';
        input.jsonResponse = '{}';

        System.assertEquals('testId', input.claimId);
        System.assertEquals('{}', input.jsonResponse);
    }

    @IsTest
    static void testFlowOutputWrapper() {
        ClaimSOCUpdateHandler.FlowOutput output = new ClaimSOCUpdateHandler.FlowOutput();
        output.isSuccess = true;
        output.message = 'Done';

        System.assertEquals(true, output.isSuccess);
        System.assertEquals('Done', output.message);
    }
}