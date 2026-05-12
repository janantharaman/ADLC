@IsTest
private class ExtractDocumentAIDetailsTest {

    @IsTest
    static void testExtractDetails_BlankPromptTemplate_ReturnsResult() {
        ExtractDocumentAIDetails.DocumentInput input = new ExtractDocumentAIDetails.DocumentInput();
        input.inputKeyValueString = '{"key": "value"}';
        input.promptTemplateApiName = '';

        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(
            new List<ExtractDocumentAIDetails.DocumentInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(null, results[0].Policy_Number, 'Policy_Number should be null when validation fails');
    }

    @IsTest
    static void testExtractDetails_NullPromptTemplate_ReturnsResult() {
        ExtractDocumentAIDetails.DocumentInput input = new ExtractDocumentAIDetails.DocumentInput();
        input.inputKeyValueString = '{"key": "value"}';
        input.promptTemplateApiName = null;

        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(
            new List<ExtractDocumentAIDetails.DocumentInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(null, results[0].Policy_Number, 'Policy_Number should be null when validation fails');
    }

    @IsTest
    static void testExtractDetails_WithInput_HandlesGracefully() {
        ExtractDocumentAIDetails.DocumentInput input = new ExtractDocumentAIDetails.DocumentInput();
        input.inputKeyValueString = '{"field1": "value1", "Policy_Number": "POL-12345"}';
        input.promptTemplateApiName = 'Test_Prompt_Template';

        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(
            new List<ExtractDocumentAIDetails.DocumentInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        // ConnectApi typically fails in test context; if it succeeds, Policy_Number would be parsed.
        // Either way, we should get a valid result object without unhandled exceptions.
        System.assertNotEquals(null, results[0], 'Result object should not be null');
    }

    @IsTest
    static void testExtractDetails_EmptyInput_HandlesGracefully() {
        ExtractDocumentAIDetails.DocumentInput input = new ExtractDocumentAIDetails.DocumentInput();
        input.inputKeyValueString = '';
        input.promptTemplateApiName = 'Valid_Template_Name';

        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(
            new List<ExtractDocumentAIDetails.DocumentInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0], 'Result object should not be null');
    }

    @IsTest
    static void testExtractDetails_MultipleRequests() {
        List<ExtractDocumentAIDetails.DocumentInput> inputs = new List<ExtractDocumentAIDetails.DocumentInput>();

        ExtractDocumentAIDetails.DocumentInput input1 = new ExtractDocumentAIDetails.DocumentInput();
        input1.inputKeyValueString = 'input1';
        input1.promptTemplateApiName = 'Template_1';
        inputs.add(input1);

        ExtractDocumentAIDetails.DocumentInput input2 = new ExtractDocumentAIDetails.DocumentInput();
        input2.inputKeyValueString = 'input2';
        input2.promptTemplateApiName = 'Template_2';
        inputs.add(input2);

        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(inputs);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return one result per request');
        System.assertNotEquals(null, results[0], 'First result should not be null');
        System.assertNotEquals(null, results[1], 'Second result should not be null');
    }

    @IsTest
    static void testExtractDetails_EmptyRequestList_ReturnsEmpty() {
        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(
            new List<ExtractDocumentAIDetails.DocumentInput>()
        );
        Test.stopTest();

        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }

    @IsTest
    static void testExtractedDetails_WrapperClass() {
        ExtractDocumentAIDetails.ExtractedDetails details = new ExtractDocumentAIDetails.ExtractedDetails();
        details.Policy_Number = 'POL-99999';

        System.assertEquals('POL-99999', details.Policy_Number, 'Policy_Number should be set correctly');
    }

    @IsTest
    static void testDocumentInput_WrapperClass() {
        ExtractDocumentAIDetails.DocumentInput input = new ExtractDocumentAIDetails.DocumentInput();
        input.inputKeyValueString = 'test data';
        input.promptTemplateApiName = 'My_Template';

        System.assertEquals('test data', input.inputKeyValueString, 'inputKeyValueString should be set');
        System.assertEquals('My_Template', input.promptTemplateApiName, 'promptTemplateApiName should be set');
    }

    @IsTest
    static void testExtractDetails_MockResponse_ParsesPolicyNumber() {
        ExtractDocumentAIDetails.mockRawResponseForTest = 'Policy_Number: POL-12345';

        ExtractDocumentAIDetails.DocumentInput input = new ExtractDocumentAIDetails.DocumentInput();
        input.inputKeyValueString = 'raw input';
        input.promptTemplateApiName = 'Test_Template';

        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(
            new List<ExtractDocumentAIDetails.DocumentInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('POL-12345', results[0].Policy_Number, 'Policy_Number should be parsed from key-value pairs');
    }

    @IsTest
    static void testExtractDetails_MockResponse_MultiplePairs() {
        ExtractDocumentAIDetails.mockRawResponseForTest = 'Policy_Number: POL-999; Other_Field: value2; Key_With_Colon: part1:part2';

        ExtractDocumentAIDetails.DocumentInput input = new ExtractDocumentAIDetails.DocumentInput();
        input.inputKeyValueString = 'input';
        input.promptTemplateApiName = 'Template';

        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(
            new List<ExtractDocumentAIDetails.DocumentInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('POL-999', results[0].Policy_Number, 'Policy_Number should be parsed');
    }

    @IsTest
    static void testExtractDetails_MockResponse_EmptyValue() {
        ExtractDocumentAIDetails.mockRawResponseForTest = 'Policy_Number: ; OtherKey: hasValue';

        ExtractDocumentAIDetails.DocumentInput input = new ExtractDocumentAIDetails.DocumentInput();
        input.inputKeyValueString = 'input';
        input.promptTemplateApiName = 'Template';

        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(
            new List<ExtractDocumentAIDetails.DocumentInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('', results[0].Policy_Number, 'Policy_Number should be empty string when value is empty');
    }

    @IsTest
    static void testExtractDetails_MockResponse_MissingPolicyNumber() {
        ExtractDocumentAIDetails.mockRawResponseForTest = 'SomeOtherKey: value; AnotherKey: value2';

        ExtractDocumentAIDetails.DocumentInput input = new ExtractDocumentAIDetails.DocumentInput();
        input.inputKeyValueString = 'input';
        input.promptTemplateApiName = 'Template';

        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(
            new List<ExtractDocumentAIDetails.DocumentInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(null, results[0].Policy_Number, 'Policy_Number should be null when key not present');
    }

    @IsTest
    static void testExtractDetails_MockEmptyGenerations_HandlesException() {
        ExtractDocumentAIDetails.mockEmptyGenerationsForTest = true;

        ExtractDocumentAIDetails.DocumentInput input = new ExtractDocumentAIDetails.DocumentInput();
        input.inputKeyValueString = 'input';
        input.promptTemplateApiName = 'Template';

        Test.startTest();
        List<ExtractDocumentAIDetails.ExtractedDetails> results = ExtractDocumentAIDetails.extractDetails(
            new List<ExtractDocumentAIDetails.DocumentInput>{ input }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result when exception is caught');
        System.assertEquals(null, results[0].Policy_Number, 'Policy_Number should be null when LLM returns no response');
    }
}