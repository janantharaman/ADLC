public with sharing class ExtractDocumentAIDetails {

    // Wrapper for Flow Output
    public class ExtractedDetails {
        @InvocableVariable(label='Policy Number')
        public String Policy_Number;
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
                Map<String, String> kvMap = new Map<String, String>();

                for (String pair : pairs) {
                    pair = pair.trim();
                    if (String.isNotBlank(pair) && pair.contains(':')) {
                        List<String> kv = pair.split(':', 2); // split only on first colon
                        String key = kv[0].trim();
                        String value = kv.size() > 1 ? kv[1].trim() : '';
                        kvMap.put(key, value);
                    }
                }
                System.debug('kvMap -- ' + kvMap);

                // === 3. Map values to output fields ===
                output.Policy_Number = kvMap.get('Policy_Number');

            } catch (Exception e) {
                System.debug('❌ Error processing Document AI details: ' + e.getMessage());
                System.debug('❌ Stack trace: ' + e.getStackTraceString());
            }
            results.add(output);
        }
        return results;
    }
}