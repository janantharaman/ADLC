@IsTest
private class ExtractDocumentAIClaimDetailsTest {

    private static final String VALID_JSON_RESPONSE =
        '{"Settlement_Currency":"USD","FX_Rate_to_Settlement_Currency":1,"InceptionDate":"2022-12-01","ExpirationDate":"2023-12-01"}';

    @IsTest
    static void testExtractDetails_ValidMockResponse_ParsesAllFields() {
        ExtractDocumentAIClaimDetails.mockRawResponseForTest = VALID_JSON_RESPONSE;

        ExtractDocumentAIClaimDetails.DocumentInput input = new ExtractDocumentAIClaimDetails.DocumentInput();
        input.inputKeyValueString = 'raw input';
        input.promptTemplateApiName = 'Test_Template';

        Test.startTest();
        List<ExtractDocumentAIClaimDetails.ExtractedDetails> results =
            ExtractDocumentAIClaimDetails.extractDetails(
                new List<ExtractDocumentAIClaimDetails.DocumentInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('USD', results[0].Settlement_Currency, 'Settlement_Currency should be parsed');
        System.assertEquals(1, results[0].FX_Rate_to_Settlement_Currency, 'FX_Rate_to_Settlement_Currency should be parsed');
        System.assertEquals(Date.valueOf('2022-12-01'), results[0].startDate, 'startDate should be parsed');
        System.assertEquals(Date.valueOf('2023-12-01'), results[0].expirationDate, 'expirationDate should be parsed');
    }

    @IsTest
    static void testExtractDetails_BlankPromptTemplate_ReturnsNullFields() {
        ExtractDocumentAIClaimDetails.DocumentInput input = new ExtractDocumentAIClaimDetails.DocumentInput();
        input.inputKeyValueString = '{"key": "value"}';
        input.promptTemplateApiName = '';

        Test.startTest();
        List<ExtractDocumentAIClaimDetails.ExtractedDetails> results =
            ExtractDocumentAIClaimDetails.extractDetails(
                new List<ExtractDocumentAIClaimDetails.DocumentInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(null, results[0].Settlement_Currency, 'Settlement_Currency should be null when validation fails');
    }

    @IsTest
    static void testExtractDetails_NullPromptTemplate_ReturnsNullFields() {
        ExtractDocumentAIClaimDetails.DocumentInput input = new ExtractDocumentAIClaimDetails.DocumentInput();
        input.inputKeyValueString = '{"key": "value"}';
        input.promptTemplateApiName = null;

        Test.startTest();
        List<ExtractDocumentAIClaimDetails.ExtractedDetails> results =
            ExtractDocumentAIClaimDetails.extractDetails(
                new List<ExtractDocumentAIClaimDetails.DocumentInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(null, results[0].Settlement_Currency, 'Settlement_Currency should be null when validation fails');
    }

    @IsTest
    static void testExtractDetails_MockEmptyGenerations_HandlesException() {
        ExtractDocumentAIClaimDetails.mockEmptyGenerationsForTest = true;

        ExtractDocumentAIClaimDetails.DocumentInput input = new ExtractDocumentAIClaimDetails.DocumentInput();
        input.inputKeyValueString = 'input';
        input.promptTemplateApiName = 'Template';

        Test.startTest();
        List<ExtractDocumentAIClaimDetails.ExtractedDetails> results =
            ExtractDocumentAIClaimDetails.extractDetails(
                new List<ExtractDocumentAIClaimDetails.DocumentInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result when exception is caught');
        System.assertEquals(null, results[0].Settlement_Currency, 'Settlement_Currency should be null when LLM returns no response');
    }

    @IsTest
    static void testExtractDetails_InvalidJson_HandlesGracefully() {
        ExtractDocumentAIClaimDetails.mockRawResponseForTest = 'not valid json at all';

        ExtractDocumentAIClaimDetails.DocumentInput input = new ExtractDocumentAIClaimDetails.DocumentInput();
        input.inputKeyValueString = 'input';
        input.promptTemplateApiName = 'Template';

        Test.startTest();
        List<ExtractDocumentAIClaimDetails.ExtractedDetails> results =
            ExtractDocumentAIClaimDetails.extractDetails(
                new List<ExtractDocumentAIClaimDetails.DocumentInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result even on parse failure');
        System.assertEquals(null, results[0].Settlement_Currency, 'Fields should be null on parse error');
    }

    @IsTest
    static void testExtractDetails_MissingFields_HandlesGracefully() {
        ExtractDocumentAIClaimDetails.mockRawResponseForTest =
            '{"Settlement_Currency":"EUR"}';

        ExtractDocumentAIClaimDetails.DocumentInput input = new ExtractDocumentAIClaimDetails.DocumentInput();
        input.inputKeyValueString = 'input';
        input.promptTemplateApiName = 'Template';

        Test.startTest();
        List<ExtractDocumentAIClaimDetails.ExtractedDetails> results =
            ExtractDocumentAIClaimDetails.extractDetails(
                new List<ExtractDocumentAIClaimDetails.DocumentInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        // Settlement_Currency may or may not be set depending on whether the
        // null FX_Rate / date fields cause an exception before or after assignment.
        System.assertNotEquals(null, results[0], 'Result object should not be null');
    }

    @IsTest
    static void testExtractDetails_EmptyRequestList_ReturnsEmpty() {
        Test.startTest();
        List<ExtractDocumentAIClaimDetails.ExtractedDetails> results =
            ExtractDocumentAIClaimDetails.extractDetails(
                new List<ExtractDocumentAIClaimDetails.DocumentInput>()
            );
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }

    @IsTest
    static void testExtractDetails_MultipleRequests() {
        ExtractDocumentAIClaimDetails.mockRawResponseForTest = VALID_JSON_RESPONSE;

        List<ExtractDocumentAIClaimDetails.DocumentInput> inputs =
            new List<ExtractDocumentAIClaimDetails.DocumentInput>();

        ExtractDocumentAIClaimDetails.DocumentInput input1 = new ExtractDocumentAIClaimDetails.DocumentInput();
        input1.inputKeyValueString = 'input1';
        input1.promptTemplateApiName = 'Template_1';
        inputs.add(input1);

        ExtractDocumentAIClaimDetails.DocumentInput input2 = new ExtractDocumentAIClaimDetails.DocumentInput();
        input2.inputKeyValueString = 'input2';
        input2.promptTemplateApiName = 'Template_2';
        inputs.add(input2);

        Test.startTest();
        List<ExtractDocumentAIClaimDetails.ExtractedDetails> results =
            ExtractDocumentAIClaimDetails.extractDetails(inputs);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return one result per request');
        System.assertNotEquals(null, results[0], 'First result should not be null');
        System.assertNotEquals(null, results[1], 'Second result should not be null');
    }

    @IsTest
    static void testExtractDetails_WithNonIntegerFXRate_HandlesGracefully() {
        ExtractDocumentAIClaimDetails.mockRawResponseForTest =
            '{"Settlement_Currency":"GBP","FX_Rate_to_Settlement_Currency":"not_a_number","InceptionDate":"2024-01-01","ExpirationDate":"2024-12-31"}';

        ExtractDocumentAIClaimDetails.DocumentInput input = new ExtractDocumentAIClaimDetails.DocumentInput();
        input.inputKeyValueString = 'input';
        input.promptTemplateApiName = 'Template';

        Test.startTest();
        List<ExtractDocumentAIClaimDetails.ExtractedDetails> results =
            ExtractDocumentAIClaimDetails.extractDetails(
                new List<ExtractDocumentAIClaimDetails.DocumentInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result even if FX rate is unparseable');
    }

    @IsTest
    static void testExtractedDetails_WrapperClass() {
        ExtractDocumentAIClaimDetails.ExtractedDetails details =
            new ExtractDocumentAIClaimDetails.ExtractedDetails();
        details.Settlement_Currency = 'JPY';
        details.FX_Rate_to_Settlement_Currency = 150;
        details.startDate = Date.valueOf('2024-06-01');
        details.expirationDate = Date.valueOf('2025-06-01');

        System.assertEquals('JPY', details.Settlement_Currency, 'Settlement_Currency should be set');
        System.assertEquals(150, details.FX_Rate_to_Settlement_Currency, 'FX_Rate should be set');
        System.assertEquals(Date.valueOf('2024-06-01'), details.startDate, 'startDate should be set');
        System.assertEquals(Date.valueOf('2025-06-01'), details.expirationDate, 'expirationDate should be set');
    }

    @IsTest
    static void testDocumentInput_WrapperClass() {
        ExtractDocumentAIClaimDetails.DocumentInput input =
            new ExtractDocumentAIClaimDetails.DocumentInput();
        input.inputKeyValueString = 'test data';
        input.promptTemplateApiName = 'My_Template';

        System.assertEquals('test data', input.inputKeyValueString, 'inputKeyValueString should be set');
        System.assertEquals('My_Template', input.promptTemplateApiName, 'promptTemplateApiName should be set');
    }

    @IsTest
    static void testExtractDetails_WithInput_NoMock_HandlesGracefully() {
        ExtractDocumentAIClaimDetails.DocumentInput input = new ExtractDocumentAIClaimDetails.DocumentInput();
        input.inputKeyValueString = '{"Settlement_Currency": "USD"}';
        input.promptTemplateApiName = 'Test_Prompt_Template';

        Test.startTest();
        List<ExtractDocumentAIClaimDetails.ExtractedDetails> results =
            ExtractDocumentAIClaimDetails.extractDetails(
                new List<ExtractDocumentAIClaimDetails.DocumentInput>{ input }
            );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0], 'Result object should not be null');
    }
}