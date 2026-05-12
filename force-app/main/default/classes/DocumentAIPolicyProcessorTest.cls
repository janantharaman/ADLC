@IsTest
private class DocumentAIPolicyProcessorTest {

    /**
     * Mock that returns appropriate responses for generate-schema and extract-data endpoints
     */
    private class DocumentAIMockSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            String endpoint = req.getEndpoint();
            if (endpoint != null && endpoint.contains('generate-schema')) {
                res.setStatusCode(200);
                // Schema with HTML escapes to test decoding
                res.setBody('{"schema": "{\\"type\\":\\"object\\",\\"properties\\":{\\"field1\\":{\\"type\\":\\"string\\"}}}"}');
            } else if (endpoint != null && endpoint.contains('extract-data')) {
                res.setStatusCode(200);
                res.setBody('{"data": {"field1": "extracted_value", "field2": "value2"}}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"error": "Unknown endpoint"}');
            }
            return res;
        }
    }

    /**
     * Mock that returns error from generate-schema endpoint
     */
    private class DocumentAIMockSchemaError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();
            if (endpoint != null && endpoint.contains('generate-schema')) {
                res.setStatusCode(400);
                res.setBody('{"error": "Schema generation failed"}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"data": {}}');
            }
            return res;
        }
    }

    /**
     * Mock that returns null schema from generate-schema endpoint
     */
    private class DocumentAIMockSchemaNull implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();
            if (endpoint != null && endpoint.contains('generate-schema')) {
                res.setStatusCode(200);
                res.setBody('{}');
            } else {
                res.setStatusCode(200);
                res.setBody('{"data": {}}');
            }
            return res;
        }
    }

    /**
     * Mock that returns error from extract-data endpoint
     */
    private class DocumentAIMockExtractError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String endpoint = req.getEndpoint();
            if (endpoint != null && endpoint.contains('generate-schema')) {
                res.setStatusCode(200);
                res.setBody('{"schema": "{\\"type\\":\\"object\\"}"}');
            } else {
                res.setStatusCode(500);
                res.setBody('{"error": "Extract failed"}');
            }
            return res;
        }
    }

    /**
     * Helper to create a ContentVersion and return its ContentDocumentId
     */
    private static Id createTestContentDocument() {
        ContentVersion cv = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'test.txt',
            VersionData = Blob.valueOf('Test file content for IDP')
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        return cv.ContentDocumentId;
    }

    @IsTest
    static void testRunImageProcessing_Success_WithSchema() {
        Test.setMock(HttpCalloutMock.class, new DocumentAIMockSuccess());
        Id contentDocId = createTestContentDocument();

        DocumentAIPolicyProcessor.Request req = new DocumentAIPolicyProcessor.Request();
        req.Document_Type = 'Invoice';
        req.ContentDocumentId = contentDocId;
        req.LLM_Model = 'test-model';
        req.IDPConfigId = null;

        Test.startTest();
        List<DocumentAIPolicyProcessor.Result> results = DocumentAIPolicyProcessor.runImageProcessing(
            new List<DocumentAIPolicyProcessor.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Success', results[0].Status, 'Status should be Success');
        System.assertNotEquals(null, results[0].ExtractedDataJson, 'Should have extracted data');
        System.assert(results[0].ExtractedDataJson.contains('field1'), 'Should contain extracted field');
    }

    @IsTest
    static void testRunImageProcessing_Success_WithIDPConfig() {
        Test.setMock(HttpCalloutMock.class, new DocumentAIMockSuccess());
        Id contentDocId = createTestContentDocument();

        DocumentAIPolicyProcessor.Request req = new DocumentAIPolicyProcessor.Request();
        req.Document_Type = 'Invoice';
        req.ContentDocumentId = contentDocId;
        req.IDPConfigId = 'my-idp-config-123';

        Test.startTest();
        List<DocumentAIPolicyProcessor.Result> results = DocumentAIPolicyProcessor.runImageProcessing(
            new List<DocumentAIPolicyProcessor.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Success', results[0].Status, 'Status should be Success');
        System.assertNotEquals(null, results[0].ExtractedDataJson, 'Should have extracted data');
    }

    @IsTest
    static void testRunImageProcessing_InvalidContentDocument() {
        Test.setMock(HttpCalloutMock.class, new DocumentAIMockSuccess());

        DocumentAIPolicyProcessor.Request req = new DocumentAIPolicyProcessor.Request();
        req.Document_Type = 'Invoice';
        req.ContentDocumentId = '069000000000000AAA';
        req.IDPConfigId = null;

        Test.startTest();
        List<DocumentAIPolicyProcessor.Result> results = DocumentAIPolicyProcessor.runImageProcessing(
            new List<DocumentAIPolicyProcessor.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Failed', results[0].Status, 'Status should be Failed');
        System.assertNotEquals(null, results[0].ErrorMessage, 'Should have error message');
    }

    @IsTest
    static void testRunImageProcessing_SchemaError() {
        Test.setMock(HttpCalloutMock.class, new DocumentAIMockSchemaError());
        Id contentDocId = createTestContentDocument();

        DocumentAIPolicyProcessor.Request req = new DocumentAIPolicyProcessor.Request();
        req.Document_Type = 'Invoice';
        req.ContentDocumentId = contentDocId;
        req.IDPConfigId = null;

        Test.startTest();
        List<DocumentAIPolicyProcessor.Result> results = DocumentAIPolicyProcessor.runImageProcessing(
            new List<DocumentAIPolicyProcessor.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Failed', results[0].Status, 'Status should be Failed');
        System.assert(results[0].ErrorMessage.contains('Schema Error'), 'Error should mention Schema');
    }

    @IsTest
    static void testRunImageProcessing_SchemaNull() {
        Test.setMock(HttpCalloutMock.class, new DocumentAIMockSchemaNull());
        Id contentDocId = createTestContentDocument();

        DocumentAIPolicyProcessor.Request req = new DocumentAIPolicyProcessor.Request();
        req.Document_Type = 'Invoice';
        req.ContentDocumentId = contentDocId;
        req.IDPConfigId = null;

        Test.startTest();
        List<DocumentAIPolicyProcessor.Result> results = DocumentAIPolicyProcessor.runImageProcessing(
            new List<DocumentAIPolicyProcessor.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Failed', results[0].Status, 'Status should be Failed');
        System.assert(results[0].ErrorMessage.contains('schema'), 'Error should mention schema');
    }

    @IsTest
    static void testRunImageProcessing_ExtractError() {
        Test.setMock(HttpCalloutMock.class, new DocumentAIMockExtractError());
        Id contentDocId = createTestContentDocument();

        DocumentAIPolicyProcessor.Request req = new DocumentAIPolicyProcessor.Request();
        req.Document_Type = 'Invoice';
        req.ContentDocumentId = contentDocId;
        req.IDPConfigId = null;

        Test.startTest();
        List<DocumentAIPolicyProcessor.Result> results = DocumentAIPolicyProcessor.runImageProcessing(
            new List<DocumentAIPolicyProcessor.Request>{ req }
        );
        Test.stopTest();

        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals('Failed', results[0].Status, 'Status should be Failed');
        System.assert(results[0].ErrorMessage.contains('Extract Error'), 'Error should mention Extract');
    }

    @IsTest
    static void testRunImageProcessing_MultipleRequests() {
        Test.setMock(HttpCalloutMock.class, new DocumentAIMockSuccess());
        Id contentDocId1 = createTestContentDocument();
        Id contentDocId2 = createTestContentDocument();

        List<DocumentAIPolicyProcessor.Request> requests = new List<DocumentAIPolicyProcessor.Request>();
        DocumentAIPolicyProcessor.Request req1 = new DocumentAIPolicyProcessor.Request();
        req1.Document_Type = 'Invoice';
        req1.ContentDocumentId = contentDocId1;
        requests.add(req1);

        DocumentAIPolicyProcessor.Request req2 = new DocumentAIPolicyProcessor.Request();
        req2.Document_Type = 'Receipt';
        req2.ContentDocumentId = contentDocId2;
        req2.IDPConfigId = 'config-2';
        requests.add(req2);

        Test.startTest();
        List<DocumentAIPolicyProcessor.Result> results = DocumentAIPolicyProcessor.runImageProcessing(requests);
        Test.stopTest();

        System.assertEquals(2, results.size(), 'Should return two results');
        System.assertEquals('Success', results[0].Status, 'First result should succeed');
        System.assertEquals('Success', results[1].Status, 'Second result should succeed');
    }
}