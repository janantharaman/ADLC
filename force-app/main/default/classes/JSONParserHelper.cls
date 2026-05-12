public class JSONParserHelper {

    // Wrapper class for Flow variables
    public class PromptResult {
        @InvocableVariable(label='Response Text' description='The main answer in Korean')
        public String responseText;
        
        @InvocableVariable(label='First Source ID' description='The ID of the first source file (for single links)')
        public String firstSourceId;

        @InvocableVariable(label='All Source IDs' description='Collection of all source file IDs')
        public List<String> sourceIds;
    }

    @InvocableMethod(label = 'Parse Knowledge JSON' description = 'Extracts nested text and sources from Agentforce JSON')
    public static List<PromptResult> parseResponse(List<String> jsonResponses) {
        List<PromptResult> results = new List<PromptResult>();

        for (String jsonStr : jsonResponses) {
            PromptResult res = new PromptResult();
            res.sourceIds = new List<String>(); // Initialize the list to avoid null pointer exceptions in Flow
            
            try {
                // 1. Parse the root JSON
                Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonStr);

                // 2. Navigate into the "response" object
                if (root.containsKey('response')) {
                    Object responseObj = root.get('response');
                    
                    if (responseObj instanceof Map<String, Object>) {
                        Map<String, Object> responseMap = (Map<String, Object>) responseObj;
                        
                        // 3. Extract the "text" field
                        res.responseText = (String) responseMap.get('text');
                        
                        // 4. Extract ALL source IDs
                        if (responseMap.containsKey('source')) {
                            List<Object> sourceList = (List<Object>) responseMap.get('source');
                            
                            for (Object srcObj : sourceList) {
                                Map<String, Object> srcMap = (Map<String, Object>) srcObj;
                                if (srcMap.containsKey('source_id')) {
                                    String sId = (String) srcMap.get('source_id');
                                    res.sourceIds.add(sId);
                                }
                            }

                            // Set the "First Source ID" convenience variable
                            if (!res.sourceIds.isEmpty()) {
                                res.firstSourceId = res.sourceIds[0];
                            }
                        }
                    }
                }
            } catch (Exception e) {
                res.responseText = 'Error parsing JSON: ' + e.getMessage();
            }
            
            results.add(res);
        }
        return results;
    }
}