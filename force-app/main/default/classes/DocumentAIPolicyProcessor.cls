public class DocumentAIPolicyProcessor 
{
    public static final string INSURANCE_POLICY = 'InsurancePolicy';
    
    @InvocableMethod(label='Run DataCloud IDP File Recognition with Schema Configuration')
    public static List<Result> runImageProcessing(List<Request> requests) {
        List<Result> results = new List<Result>();

        for (Request req : requests) {
            Result result = new Result();
            try {
                String llmModel    = req.LLM_Model;
                String idpConfigId = req.IDPConfigId;
                Integer startPage = req.startPage;
                Integer endPage = req.endPage;
                
                system.debug('req.ContentDocumentId '+req.ContentDocumentId);

                ContentVersion cv = [
                    SELECT Id, RelFiles__Category__c  
                    FROM ContentVersion 
                    WHERE ContentDocumentId = :req.ContentDocumentId 
                    ORDER BY VersionNumber DESC 
                    LIMIT 1
                ];
                String fileId = cv.Id;
                System.debug('Using fileId >> ' + fileId);

                String schemaJson;
                String finalResponse;
                Long startTime = System.currentTimeMillis();
                if (String.isBlank(idpConfigId)) {
                    schemaJson = getSchemaJson(fileId, llmModel);
                    System.debug('Decoded Schema JSON >> ' + schemaJson);

                    finalResponse = extractData(fileId, schemaJson, llmModel, null, startPage, endPage);
                } else {
                    finalResponse = extractData(fileId, null, llmModel, idpConfigId, startPage, endPage);
                }
                system.debug('finalResponse -- '+finalResponse);
                result.Status = 'Success';
                result.ExtractedDataJson = finalResponse;
                Long endTime = System.currentTimeMillis();
                Long executionTime = endTime - startTime;
                system.debug('Total time for both APIs -- '+executionTime);
                cv.RelFiles__Category__c = INSURANCE_POLICY;
                update cv;

            } catch (Exception e) {
                result.Status = 'Failed';
                result.ErrorMessage = e.getMessage();
                System.debug('Error >> ' + e.getMessage());
            }
            results.add(result);
        }
        return results;
    }

    public class Request {        
        @InvocableVariable(label='Document Type' required=true) public String Document_Type;
        @InvocableVariable(label='LLM Model') public String LLM_Model;
        @InvocableVariable(label='Content Document Id' required=true) public Id ContentDocumentId;
        @InvocableVariable(label='IDPConfigId') public String IDPConfigId;
        @InvocableVariable(label='startPage') public Integer startPage;
        @InvocableVariable(label='endPage') public Integer endPage;
    }
    public class Result {
        @InvocableVariable(label='Status') public String Status;
        @InvocableVariable(label='Extracted Data (JSON)') public String ExtractedDataJson;
        @InvocableVariable(label='Error Message (if any)') public String ErrorMessage;
    }
    
    private static String getSchemaJson(String fileId, String llmModel) {
        try {
            HttpRequest req = new HttpRequest();        
            req.setEndpoint('callout:Document_AI_Credentials/services/data/v63.0/ssot/document-processing/actions/generate-schema');
            req.setMethod('POST');        
            req.setHeader('Content-Type','application/json');
            req.setHeader('Accept','application/json');
            req.setHeader('Sforce-Call-Options','client=SchemaTest');
            req.setTimeout(120000);

            llmModel = 'llmgateway__OpenAIGPT4Omni_08_06';

            Map<String,Object> payload = new Map<String,Object>{
                'mlModel' => llmModel,
                'files'   => new List<Object>{ new Map<String,Object>{ 'fileId' => fileId } }
            };

            String body = JSON.serialize(payload);
            System.debug('Sending Schema Payload: ' + body);

            req.setBody(body);

            HttpResponse res = new Http().send(req);
            System.debug('Schema Status Code: ' + res.getStatusCode());
            System.debug('Schema Response: ' + res.getBody());

            if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                Map<String,Object> bodyMap = (Map<String,Object>) JSON.deserializeUntyped(res.getBody());
                String schemaRaw = (String) bodyMap.get('schema');
                if (schemaRaw == null) {
                    throw new CalloutException('Schema Error: No "schema" field in response');
                }
                String schemaDecoded = schemaRaw.replaceAll('&quot;', '"').replaceAll('&amp;', '&');
                return schemaDecoded;
            } else {
                throw new CalloutException('Schema Error(' + res.getStatusCode() + '): ' + res.getBody());
            }
        } catch (CalloutException ce) {
            throw ce;
        } catch (Exception e) {
            throw new CalloutException('Schema Generation Failed: ' + e.getMessage());
        }
    }

    private static String extractData(String fileId, String schemaJson,
                                      String llmModel, String idpConfigId, Integer startPage, Integer endPage) {
        try {
            HttpRequest req = new HttpRequest();
            String endPoint = 'callout:Document_AI_Credentials/services/data/v63.0/ssot/document-processing/actions/extract-data';
            String queryParameters = '?startPage='+startPage+'&endPage='+endPage;        
            String completeEndPoint = endPoint + queryParameters;                                          
            req.setEndpoint(completeEndPoint);
            req.setMethod('POST');        
            req.setHeader('Content-Type','application/json');
            req.setHeader('Accept','application/json');
            req.setTimeout(120000);
                                              
            system.debug('schemaJson -- '+schemaJson);
            system.debug('fileId - '+fileId);   
            system.debug('llmModel -- '+ llmModel); 
            llmModel = 'llmgateway__OpenAIGPT4Omni_08_06';

            Map<String,Object> payload;
            if (!String.isBlank(schemaJson)) {
                payload = new Map<String,Object>{
                    'mlModel'=>llmModel,
                    'files'=>new List<Object>{ new Map<String,Object>{ 'fileId'=>fileId } },
                    'schemaConfig'=>schemaJson
                };
            } else {
                payload = new Map<String,Object>{
                    'idpConfigurationIdOrName'=>idpConfigId,
                    'files'=>new List<Object>{ new Map<String,Object>{ 'fileId'=>fileId } }
                };
            }

            System.debug('Extract Payload >> '+JSON.serializePretty(payload));
            req.setBody(JSON.serialize(payload));

            HttpResponse res = new Http().send(req);
            System.debug('Extract Status >> '+res.getStatusCode());
            System.debug('Extract Response >> '+res.getBody());

            if (res.getStatusCode()>=200 && res.getStatusCode()<300) {
                Map<String,Object> bodyMap = (Map<String,Object>)JSON.deserializeUntyped(res.getBody());
                if (bodyMap.containsKey('data')) {
                    return JSON.serialize(bodyMap.get('data'));
                }
                return 'No data field in response';
            }
            throw new CalloutException('Extract Error('+res.getStatusCode()+'): '+res.getBody());
        } catch (CalloutException ce) {
            throw ce;
        } catch (Exception e) {
            throw new CalloutException('Data Extraction Failed: ' + e.getMessage());
        }
    }
}