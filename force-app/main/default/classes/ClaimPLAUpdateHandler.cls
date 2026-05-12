public with sharing class ClaimPLAUpdateHandler {

    // Input wrapper: Variables passed FROM the Flow
    public class FlowInput {
        @InvocableVariable(Label='Claim Record ID' Required=true Description='Salesforce ID of the Claim record')
        public String claimId;

        @InvocableVariable(Label='JSON Response' Required=true Description='The JSON string output from the Prompt Template')
        public String jsonResponse;
    }

    // Output wrapper: Variables returned TO the Flow
    public class FlowOutput {
        @InvocableVariable(Label='Is Success' Description='True if the update was successful')
        public Boolean isSuccess;

        @InvocableVariable(Label='Message' Description='Success message or error details')
        public String message;
    }

    @InvocableMethod(Label='Update Claim PLA Details' Description='Parses PLA JSON and updates the Claim record with error handling')
    public static List<FlowOutput> updateClaimPLA(List<FlowInput> inputs) {
        List<FlowOutput> outputs = new List<FlowOutput>();
        List<Claim> claimsToUpdate = new List<Claim>();
        
        // Map to track which input index corresponds to which Claim record in the update list
        Map<Integer, Integer> claimIndexToOutputIndex = new Map<Integer, Integer>();

        for (Integer i = 0; i < inputs.size(); i++) {
            FlowInput input = inputs[i];
            FlowOutput out = new FlowOutput();
            
            // 1. Basic Input Validation
            if (String.isBlank(input.jsonResponse) || String.isBlank(input.claimId)) {
                out.isSuccess = false;
                out.message = 'Error: Missing Claim ID or JSON Response.';
                System.debug('ClaimPLAUpdateHandler Error: ' + out.message);
                outputs.add(out);
                continue;
            }

            try {
                System.debug('ClaimPLAUpdateHandler: Processing Claim ID: ' + input.claimId);
                System.debug('ClaimPLAUpdateHandler: Raw JSON: ' + input.jsonResponse);

                // 2. Parse JSON
                Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(input.jsonResponse);
                system.debug('jsonMap -- '+jsonMap);

                // 3. Initialize Record
                // NOTE: Use Claim__c if you are using a custom object.
                Claim c = new Claim(); 
                c.Id = input.claimId;
                
                // 4. Map Fields (String, Picklist & Text Area)
                if (jsonMap.containsKey('ClaimDocType__c')) c.ClaimDocType__c = (String) jsonMap.get('ClaimDocType__c');
                if (jsonMap.containsKey('CedantClaimNo__c')) c.CedantClaimNo__c = (String) jsonMap.get('CedantClaimNo__c');
                if (jsonMap.containsKey('CedantPolicyNo__c')) c.CedantPolicyNo__c = (String) jsonMap.get('CedantPolicyNo__c');
                if (jsonMap.containsKey('ClaimCurrency__c')) c.ClaimCurrency__c = (String) jsonMap.get('ClaimCurrency__c');
                if (jsonMap.containsKey('LossDesc__c')) c.LossDesc__c = (String) jsonMap.get('LossDesc__c');
                if (jsonMap.containsKey('Summary')) c.Summary = (String) jsonMap.get('Summary');
                if (jsonMap.containsKey('ClaimCurrency__c')) c.ClaimCurrency__c = (String) jsonMap.get('ClaimCurrency__c');
                
                if (jsonMap.containsKey('FXRateToSettlementCurrency__c'))
                {
                    Object FXRateToSettlementCurrency = jsonMap.get('FXRateToSettlementCurrency__c');
                    c.FXRateToSettleCurrency__c = (FXRateToSettlementCurrency == null) ? 1.0 : (Decimal) FXRateToSettlementCurrency;
                }
                else
                {
                    c.FXRateToSettleCurrency__c = 1.0;
                }
                
                if (jsonMap.containsKey('SettlementCurrency__c'))
                {
                    Object settlementCurrency = jsonMap.get('SettlementCurrency__c');
                    c.SettlementCurrency__c = (settlementCurrency == null) ? c.ClaimCurrency__c : (String) jsonMap.get('SettlementCurrency__c');
                }
                else
                {
                    c.SettlementCurrency__c = c.ClaimCurrency__c;
                }
                
                //if (jsonMap.containsKey('FXRateToSettlementCurrency__c')) c.FXRateToSettleCurrency__c = (Decimal) jsonMap.get('FXRateToSettlementCurrency__c');
                //if (jsonMap.containsKey('SettlementCurrency__c')) c.SettlementCurrency__c = (String) jsonMap.get('SettlementCurrency__c');
                
                if (jsonMap.containsKey('LossLocation__c')) c.LossLocation__c = (String) jsonMap.get('LossLocation__c');
                if (jsonMap.containsKey('LossLocationEn__c')) c.LossLocationEn__c = (String) jsonMap.get('LossLocationEn__c');
                if (jsonMap.containsKey('InsuredOrigin__c')) c.InsuredOrigin__c = (String) jsonMap.get('InsuredOrigin__c');
                if (jsonMap.containsKey('InsuredEn__c')) c.InsuredEn__c = (String) jsonMap.get('InsuredEn__c');
                if (jsonMap.containsKey('LossParticular__c')) c.LossParticular__c = (String) jsonMap.get('LossParticular__c');
                if (jsonMap.containsKey('LossParticularEn__c')) c.LossParticularEn__c = (String) jsonMap.get('LossParticularEn__c');
                
                system.debug('c.SettlementCurrency__c -- '+c.SettlementCurrency__c);
                system.debug('c.ClaimCurrency__c -- '+c.ClaimCurrency__c);
                system.debug('c.FXRateToSettleCurrency__c -- '+c.FXRateToSettleCurrency__c);
                
                // Handle Remarks (Rich Text) - Check for null specifically
                if (jsonMap.containsKey('Remarks__c')) {
                    Object remarksVal = jsonMap.get('Remarks__c');
                    c.Remarks__c = (remarksVal == null) ? null : (String) remarksVal;
                }

                // 5. Map Fields (Date) - Wrapped in try/catch for specific field safety
                if (jsonMap.containsKey('LossDate__c') && jsonMap.get('LossDate__c') != null) {
                    try {
                        c.LossDate__c = (String) jsonMap.get('LossDate__c');
                    } catch(Exception e) {
                        System.debug('Date Parse Error (LossDate__c): ' + e.getMessage());
                    }
                }
                
                if (jsonMap.containsKey('InceptionDate__c') && jsonMap.get('InceptionDate__c') != null) {
                    try {
                        c.InceptionDate__c = Date.valueOf((String) jsonMap.get('InceptionDate__c'));
                    } catch(Exception e) {
                        System.debug('Date Parse Error (InceptionDate__c): ' + e.getMessage());
                    }
                }
                if (jsonMap.containsKey('ExpirationDate__c') && jsonMap.get('ExpirationDate__c') != null) {
                    try {
                        c.ExpirationDate__c = Date.valueOf((String) jsonMap.get('ExpirationDate__c'));
                    } catch(Exception e) {
                        System.debug('Date Parse Error (ExpirationDate__c): ' + e.getMessage());
                    }
                }

                // 6. Map Fields (Decimal/Currency/Percent)
                // Using generic Object logic to safely cast integer/decimals from JSON
                if (jsonMap.containsKey('TotalAmt__c')) c.TotalAmt__c = (Decimal) jsonMap.get('TotalAmt__c');
                if (jsonMap.containsKey('LKShare__c')) c.LKShare__c = (Decimal) jsonMap.get('LKShare__c');
                
                // PLA Specific Reserves
                //if (jsonMap.containsKey('LossRsvRem__c')) c.LossRsvRem__c = (Decimal) jsonMap.get('LossRsvRem__c');
                //if (jsonMap.containsKey('ExpRsvRem__c')) c.ExpRsvRem__c = (Decimal) jsonMap.get('ExpRsvRem__c');

                if (jsonMap.containsKey('LossAmt__c')) c.LossAmt__c = (Decimal) jsonMap.get('LossAmt__c');
                if (jsonMap.containsKey('ExpAmt__c')) c.ExpAmt__c = (Decimal) jsonMap.get('ExpAmt__c');
                
                // Add to list for update
                claimsToUpdate.add(c);
                claimIndexToOutputIndex.put(claimsToUpdate.size() - 1, i);
                
                // Pre-set success state (will be confirmed after DB update)
                out.isSuccess = true; 
                out.message = 'PLA JSON parsed. Updating record...';

            } catch (Exception e) {
                out.isSuccess = false;
                out.message = 'JSON Parse Exception: ' + e.getMessage();
                System.debug('ClaimPLAUpdateHandler Exception: ' + e.getMessage());
            }

            outputs.add(out);
        }

        // 7. Perform Database Update (Partial Success Allowed)
        if (!claimsToUpdate.isEmpty()) {
            Database.SaveResult[] results = Database.update(claimsToUpdate, false);

            for (Integer k = 0; k < results.size(); k++) {
                Database.SaveResult sr = results[k];
                Integer originalIndex = claimIndexToOutputIndex.get(k);
                FlowOutput relatedOutput = outputs[originalIndex];

                if (sr.isSuccess()) {
                    relatedOutput.isSuccess = true;
                    relatedOutput.message = 'Success: PLA updated successfully. ID: ' + sr.getId();
                    System.debug(relatedOutput.message);
                } else {
                    relatedOutput.isSuccess = false;
                    List<String> errorMsgs = new List<String>();
                    for(Database.Error err : sr.getErrors()) {
                        errorMsgs.add(err.getMessage());
                    }
                    relatedOutput.message = 'DB Update Failed: ' + String.join(errorMsgs, ', ');
                    System.debug(relatedOutput.message);
                }
            }
        }

        return outputs;
    }
}