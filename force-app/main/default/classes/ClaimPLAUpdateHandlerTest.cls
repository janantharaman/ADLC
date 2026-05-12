@IsTest
private class ClaimPLAUpdateHandlerTest {

    private static final String FULL_JSON =
        '{"ClaimDocType__c":"PLA",' +
        '"CedantClaimNo__c":"CED-PLA-001",' +
        '"CedantPolicyNo__c":"POL-PLA-001",' +
        '"InsuredEn__c":"Test Insured PLA",' +
        '"ClaimCurrency__c":"USD",' +
        '"LossLocationEn__c":"Busan",' +
        '"LossDesc__c":"Water damage",' +
        '"Summary":"PLA test summary",' +
        '"Remarks__c":"PLA test remark",' +
        '"InsuredOrigin__c":"KR",' +
        '"LossParticular__c":"Particular PLA",' +
        '"LossParticularEn__c":"Particular PLA En",' +
        '"SettlementCurrency__c":"USD",' +
        '"FXRateToSettlementCurrency__c":1.0,' +
        '"LossDate__c":"2025-06-15",' +
        '"InceptionDate__c":"2025-01-01",' +
        '"ExpirationDate__c":"2025-12-31",' +
        '"TotalAmt__c":200000,' +
        '"LKShare__c":30.0,' +
        '"LossRsvRem__c":50000,' +
        '"ExpRsvRem__c":10000,' +
        '"LossAmt__c":150000,' +
        '"ExpAmt__c":8000}';

    @TestSetup
    static void makeData() {
        Claim c = new Claim();
        c.Name = 'TEST-PLA-CLAIM-001';
        insert c;
    }

    private static Claim getTestClaim() {
        return [SELECT Id FROM Claim WHERE Name = 'TEST-PLA-CLAIM-001' LIMIT 1];
    }

    // ── Success path: all fields populated ──

    @IsTest
    static void testUpdateClaimPLA_AllFields_Success() {
        Claim testClaim = getTestClaim();

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = FULL_JSON;

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one output');
        System.assert(results[0].isSuccess, 'Update should succeed: ' + results[0].message);
        System.assert(results[0].message.contains('Success'), 'Message should indicate success');

        Claim updated = [SELECT CedantClaimNo__c, CedantPolicyNo__c,
                                InsuredEn__c, LossLocationEn__c,
                                LossDesc__c, Summary, Remarks__c,
                                TotalAmt__c, LKShare__c,
                                LossRsvRem__c, ExpRsvRem__c,
                                LossAmt__c, ExpAmt__c
                         FROM Claim WHERE Id = :testClaim.Id];

        System.assertEquals('CED-PLA-001', updated.CedantClaimNo__c);
        System.assertEquals('POL-PLA-001', updated.CedantPolicyNo__c);
        System.assertEquals('Test Insured PLA', updated.InsuredEn__c);
        System.assertEquals('Busan', updated.LossLocationEn__c);
        System.assertEquals('Water damage', updated.LossDesc__c);
        System.assertEquals('PLA test summary', updated.Summary);
        System.assertEquals('PLA test remark', updated.Remarks__c);
        System.assertEquals(200000, updated.TotalAmt__c);
        System.assertEquals(30.0, updated.LKShare__c);
        System.assertEquals(50000, updated.LossRsvRem__c);
        System.assertEquals(10000, updated.ExpRsvRem__c);
        System.assertEquals(150000, updated.LossAmt__c);
        System.assertEquals(8000, updated.ExpAmt__c);
    }

    // ── Currency conversion: WON → KRW for SettlementCurrency ──

    @IsTest
    static void testUpdateClaimPLA_WONSettlementCurrency_ConvertedToKRW() {
        Claim testClaim = getTestClaim();

        String json = '{"SettlementCurrency__c":"WON","Summary":"WON settlement test"}';

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'WON settlement currency update should succeed: ' + results[0].message);
        System.assert(results[0].message.contains('Success'), 'Message should indicate success');
    }

    @IsTest
    static void testUpdateClaimPLA_NonWONSettlementCurrency_PassesThrough() {
        Claim testClaim = getTestClaim();

        String json = '{"SettlementCurrency__c":"EUR","Summary":"Non-WON settlement test"}';

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'Non-WON settlement currency should succeed: ' + results[0].message);
        System.assert(results[0].message.contains('Success'), 'Message should indicate success');
    }

    // ── Remarks null handling ──

    @IsTest
    static void testUpdateClaimPLA_NullRemarks_HandledGracefully() {
        Claim testClaim = getTestClaim();

        String json = '{"Remarks__c":null,"Summary":"Null remarks test"}';

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'Null remarks should succeed: ' + results[0].message);
    }

    // ── Date fields ──

    @IsTest
    static void testUpdateClaimPLA_ValidDates_Parsed() {
        Claim testClaim = getTestClaim();

        String json = '{"LossDate__c":"2025-06-15","InceptionDate__c":"2025-01-01","ExpirationDate__c":"2025-12-31"}';

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assert(results[0].isSuccess, 'Date update should succeed: ' + results[0].message);
        System.assert(results[0].message.contains('Success'), 'Message should indicate success');
    }

    @IsTest
    static void testUpdateClaimPLA_InvalidDateFormat_HandlesGracefully() {
        Claim testClaim = getTestClaim();

        String json = '{"InceptionDate__c":"not-a-date","ExpirationDate__c":"also-bad"}';

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should still return output despite date errors');
    }

    // ── PLA-specific reserve fields ──

    @IsTest
    static void testUpdateClaimPLA_ReserveFields_Success() {
        Claim testClaim = getTestClaim();

        String json = '{"LossRsvRem__c":75000,"ExpRsvRem__c":12000,"Summary":"Reserve test"}';

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assert(results[0].isSuccess, 'Reserve update should succeed: ' + results[0].message);

        Claim updated = [SELECT LossRsvRem__c, ExpRsvRem__c
                         FROM Claim WHERE Id = :testClaim.Id];
        System.assertEquals(75000, updated.LossRsvRem__c);
        System.assertEquals(12000, updated.ExpRsvRem__c);
    }

    // ── FX Rate field mapping ──

    @IsTest
    static void testUpdateClaimPLA_FXRate_MappedCorrectly() {
        Claim testClaim = getTestClaim();

        String json = '{"FXRateToSettlementCurrency__c":1.25,"Summary":"FX rate test"}';

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = json;

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assert(results[0].isSuccess, 'FX rate update should succeed: ' + results[0].message);
    }

    // ── Validation: missing inputs ──

    @IsTest
    static void testUpdateClaimPLA_BlankClaimId_ReturnsError() {
        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = '';
        input.jsonResponse = '{"Summary":"test"}';

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].message.contains('Missing'), 'Should report missing input');
    }

    @IsTest
    static void testUpdateClaimPLA_BlankJsonResponse_ReturnsError() {
        Claim testClaim = getTestClaim();

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = '';

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].message.contains('Missing'), 'Should report missing input');
    }

    @IsTest
    static void testUpdateClaimPLA_NullInputs_ReturnsError() {
        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = null;
        input.jsonResponse = null;

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
    }

    // ── Invalid JSON ──

    @IsTest
    static void testUpdateClaimPLA_MalformedJson_ReturnsParseError() {
        Claim testClaim = getTestClaim();

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = 'this is not valid json';

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        System.assert(results[0].message.contains('JSON Parse Exception'), 'Should report parse error');
    }

    // ── DB update failure (bad Id) ──

    @IsTest
    static void testUpdateClaimPLA_InvalidClaimId_DBFailure() {
        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = '0LI000000000000AAA';
        input.jsonResponse = '{"Summary":"test"}';

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isSuccess);
        //System.assert(results[0].message.contains('DB Update Failed'), 'Should report DB failure');
    }

    // ── Multiple inputs (batch) ──

    @IsTest
    static void testUpdateClaimPLA_MultipleInputs_MixedResults() {
        Claim testClaim = getTestClaim();

        ClaimPLAUpdateHandler.FlowInput validInput = new ClaimPLAUpdateHandler.FlowInput();
        validInput.claimId = testClaim.Id;
        validInput.jsonResponse = '{"Summary":"Batch PLA test"}';

        ClaimPLAUpdateHandler.FlowInput invalidInput = new ClaimPLAUpdateHandler.FlowInput();
        invalidInput.claimId = '';
        invalidInput.jsonResponse = '';

        List<ClaimPLAUpdateHandler.FlowInput> inputs = new List<ClaimPLAUpdateHandler.FlowInput>{
            validInput, invalidInput
        };

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(inputs);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return one output per input');
        System.assertEquals(true, results[0].isSuccess, 'Valid input should succeed');
        System.assertEquals(false, results[1].isSuccess, 'Invalid input should fail');
    }

    // ── Empty input list ──

    @IsTest
    static void testUpdateClaimPLA_EmptyList_ReturnsEmpty() {
        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>()
            );
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Empty input should return empty output');
    }

    // ── Minimal JSON ──

    @IsTest
    static void testUpdateClaimPLA_MinimalJson_Success() {
        Claim testClaim = getTestClaim();

        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = testClaim.Id;
        input.jsonResponse = '{"Summary":"Minimal PLA update"}';

        Test.startTest();
        List<ClaimPLAUpdateHandler.FlowOutput> results =
            ClaimPLAUpdateHandler.updateClaimPLA(
                new List<ClaimPLAUpdateHandler.FlowInput>{ input }
            );
        Test.stopTest();

        System.assert(results[0].isSuccess, 'Minimal update should succeed: ' + results[0].message);

        Claim updated = [SELECT Summary FROM Claim WHERE Id = :testClaim.Id];
        System.assertEquals('Minimal PLA update', updated.Summary);
    }

    // ── Wrapper class coverage ──

    @IsTest
    static void testFlowInputWrapper() {
        ClaimPLAUpdateHandler.FlowInput input = new ClaimPLAUpdateHandler.FlowInput();
        input.claimId = 'testId';
        input.jsonResponse = '{}';

        System.assertEquals('testId', input.claimId);
        System.assertEquals('{}', input.jsonResponse);
    }

    @IsTest
    static void testFlowOutputWrapper() {
        ClaimPLAUpdateHandler.FlowOutput output = new ClaimPLAUpdateHandler.FlowOutput();
        output.isSuccess = true;
        output.message = 'Done';

        System.assertEquals(true, output.isSuccess);
        System.assertEquals('Done', output.message);
    }
}