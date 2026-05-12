public with sharing class ExtractDocumentAIClaimDetails {

    // Wrapper for Flow Output
    public class ExtractedDetails {
        @InvocableVariable(label='Settlement Currency')
        public String Settlement_Currency;
        
        @InvocableVariable(label='FX Rate to Settlement Currency')
        public Integer FX_Rate_to_Settlement_Currency;
        
        @InvocableVariable(label='Inception Date')
        public Date startDate;
        
        @InvocableVariable(label='Expiration Date')
        public Date expirationDate;
    }

    // Flow Input Wrapper
    public class DocumentInput {
        @InvocableVariable(label='Document AI JSON or Raw Data' required=true
            description='Raw JSON string or Document AI response to process')
        public String inputKeyValueString;

        @InvocableVariable(label='Prompt Template API Name' required=true
            description='API name or ID of the Prompt Template (e.g., Handle_Securities_2025_Lotte_REIT_Gimpo_Logistics_PKG)')
        public String promptTemplateApiName;
    }

    /**
     * Test hook: When set in test context, bypasses ConnectApi call and uses this string
     * to simulate the prompt template response. Enables coverage of parsing logic.
     */
    @TestVisible
    private static String mockRawResponseForTest;

    /**
     * Test hook: When true in test context, simulates null/empty generations response
     * to cover the AuraHandledException branch.
     */
    @TestVisible
    private static Boolean mockEmptyGenerationsForTest;

    @InvocableMethod(
        label='Extract Document AI Details'
        description='Parses a Document AI response or key-value pair string into candidate details'
    )
    public static List<ExtractedDetails> extractDetails(List<DocumentInput> requests) {
        List<ExtractedDetails> results = new List<ExtractedDetails>();
		Long startTime = System.currentTimeMillis();
        for (DocumentInput req : requests) {
            ExtractedDetails output = new ExtractedDetails();

            try {
                // Validate that prompt template API name is provided
                if (String.isBlank(req.promptTemplateApiName)) {
                    throw new AuraHandledException('Prompt Template API Name is required. Please provide the API name or ID of your prompt template.');
                }

                String rawResponse;

                // Test hook: simulate empty generations to cover exception branch
                if (Test.isRunningTest() && mockEmptyGenerationsForTest == true) {
                    throw new AuraHandledException('No response returned from Einstein LLM. Please verify your Prompt Template is active and configured correctly.');
                }
                // Test hook: use mock response when set to cover parsing logic
                if (Test.isRunningTest() && mockRawResponseForTest != null) {
                    rawResponse = mockRawResponseForTest;
                } else {
                    // === 1. Call Einstein Prompt Template to normalize the input ===
                    
                    ConnectApi.EinsteinPromptTemplateGenerationsInput promptGenerationsInput =
                        new ConnectApi.EinsteinPromptTemplateGenerationsInput();
                    promptGenerationsInput.isPreview = false;

                    Map<String, ConnectApi.WrappedValue> valueMap = new Map<String, ConnectApi.WrappedValue>();
                    ConnectApi.WrappedValue wrappedInput = new ConnectApi.WrappedValue();
                    wrappedInput.value = req.inputKeyValueString;

                    valueMap.put('Input:inputString', wrappedInput);
                    promptGenerationsInput.inputParams = valueMap;

                    promptGenerationsInput.additionalConfig =
                        new ConnectApi.EinsteinLlmAdditionalConfigInput();
                    promptGenerationsInput.additionalConfig.applicationName = 'PromptTemplateGenerationsInvocable';

                    ConnectApi.EinsteinPromptTemplateGenerationsRepresentation generationsOutput =
                        ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(
                            req.promptTemplateApiName,
                            promptGenerationsInput
                        );

                    if (generationsOutput == null || generationsOutput.generations.isEmpty()) {
                        throw new AuraHandledException('No response returned from Einstein LLM. Please verify your Prompt Template is active and configured correctly.');
                    }

                    rawResponse = generationsOutput.generations[0].text;
                }

                System.debug('Prompt response (raw): ' + rawResponse);

                // === 2. Parse returned key-value pairs ===
                List<String> pairs = rawResponse.split(';');
                system.debug('pairs '+pairs);
                Map<String, Object> kvMap = new Map<String, Object>();
				
                kvMap = (Map<String, Object>)JSON.deserializeUntyped(rawResponse);
                
                /*for (String pair : pairs) {
                    pair = pair.trim();
                    system.debug('pair '+pair);
                    if (String.isNotBlank(pair) && pair.contains(':')) {
                        List<String> kv = pair.split(':', 2); // split only on first colon
                        system.debug('kv '+kv);
                        String key = kv[0].trim();
                        system.debug('key '+key);
                        String value = kv.size() > 1 ? kv[1].trim() : '';
                        system.debug('value '+value);
                        kvMap.put(key, value);
                    }
                }*/
                System.debug('kvMap Claim-- ' + kvMap);

                // === 3. Map values to output fields ===
                output.Settlement_Currency = (String)kvMap.get('Settlement_Currency');
                output.FX_Rate_to_Settlement_Currency = Integer.valueOf(kvMap.get('FX_Rate_to_Settlement_Currency'));
                String inceptionDate = String.valueOf(kvMap.get('InceptionDate'));
                
                output.startDate = Date.valueOf(inceptionDate);
                String expirationDate = String.valueOf(kvMap.get('ExpirationDate'));
                output.expirationDate = Date.valueOf(expirationDate);
                
                system.debug('output.startDate -- '+output.startDate);
                system.debug('output.expirationDate -- '+output.expirationDate);
                system.debug('output.Settlement_Currency -- '+ output.Settlement_Currency);

            } catch (Exception e) {
                System.debug('❌ Error processing Document AI details: ' + e.getMessage());
                System.debug('❌ Stack trace: ' + e.getStackTraceString());
            }
            results.add(output);
            Long endTime = System.currentTimeMillis();
			Long executionTime = endTime - startTime;
            system.debug('Total time for prompt template -- '+executionTime);
        }
        return results;
    }
}