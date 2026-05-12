public class PolicyDataProcessor {

    private static final String CURRENCY_WON = 'WON';
    private static final String CURRENCY_KRW = 'KRW';

    // --- 1. Flow Input & Output Wrappers ---
    
    public class FlowInput { 
        
        @InvocableVariable(label='Policy Data JSON' description='JSON string representing a SINGLE Policy object' required=true)
        public String jsonString; 
        
        @InvocableVariable(label='Insurance Policy ID' description='Optional: Provide to update existing, leave blank to create new')
        public Id insurancePolicyId;
    }

    public class FlowOutput {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        
        @InvocableVariable(label='Processed Policy ID')
        public Id processedPolicyId;
        
        @InvocableVariable(label='Debug Log')
        public String debugLog;

        public FlowOutput() {
            this.isSuccess = true;
            this.errorMessage = '';
            this.debugLog = '';
        }
    }

    // --- 2. Data Structure Classes ---

    public class PolicyRecord {
        @InvocableVariable @AuraEnabled public String Name;
        @InvocableVariable @AuraEnabled public Date EffectiveDate;
        @InvocableVariable @AuraEnabled public Date EffectiveFromDate;
        @InvocableVariable @AuraEnabled public Date EffectiveToDate;
        @InvocableVariable @AuraEnabled public String NameContractor;
        @InvocableVariable @AuraEnabled public String NameContractorNumber;
        @InvocableVariable @AuraEnabled public String NameInsuredName; 
        @InvocableVariable @AuraEnabled public String NameInsuredNumber;
        @InvocableVariable @AuraEnabled public Decimal TotalSumInsured;
        @InvocableVariable @AuraEnabled public Decimal PremiumAmount;
        @InvocableVariable @AuraEnabled public Decimal TermPremiumAmount;
        @InvocableVariable @AuraEnabled public Decimal Commission;
        @InvocableVariable @AuraEnabled public String PremiumFrequency;
        @InvocableVariable @AuraEnabled public String CurrencyVal;
        @InvocableVariable @AuraEnabled public String LineOfBusiness;
        @InvocableVariable @AuraEnabled public String PolicyType;
        @InvocableVariable @AuraEnabled public String Facility_lk; 
        @InvocableVariable @AuraEnabled public String WritingCarrierAccountId; 
        
        // Children
       
        @InvocableVariable @AuraEnabled public List<AssetRecord> assets;
        @InvocableVariable @AuraEnabled public List<ClauseRecord> productClauses;
        @InvocableVariable @AuraEnabled public List<CoverageRecord> coverages;
    }
    
   
    
    public class AssetRecord { 
        @InvocableVariable @AuraEnabled public String AssetName; 
        @InvocableVariable @AuraEnabled public String AssetCode; 
        @InvocableVariable @AuraEnabled public String AssetLocation; 
        @InvocableVariable @AuraEnabled public Date EffectiveFromDate;
        @InvocableVariable @AuraEnabled public Date EffectiveToDate;
        @InvocableVariable @AuraEnabled public Decimal TermPremiumAmount; 
    }
    
    public class ClauseRecord { 
        @InvocableVariable @AuraEnabled public String Name; 
        @InvocableVariable @AuraEnabled public String Section; 
        @InvocableVariable @AuraEnabled public String Details; 
    }
    
    public class CoverageRecord {
        @InvocableVariable @AuraEnabled public String Name;
        @InvocableVariable @AuraEnabled public String CategoryGroup;
        @InvocableVariable @AuraEnabled public String Description;
        @InvocableVariable @AuraEnabled public String CurrencyVal;
        @InvocableVariable @AuraEnabled public Decimal CoverageSumInsured;
        @InvocableVariable @AuraEnabled public Decimal SectionSumInsured;
        @InvocableVariable @AuraEnabled public Decimal CoveragePremiumAmount;
        @InvocableVariable @AuraEnabled public Decimal SectionPremiumAmount;
        @InvocableVariable @AuraEnabled public Decimal CoverageDeductibleAmount;
        @InvocableVariable @AuraEnabled public Decimal LimitAmount;
        @InvocableVariable @AuraEnabled public String LinkedAssetName;
        @InvocableVariable @AuraEnabled public String LinkedParticipantName;
        @InvocableVariable @AuraEnabled public List<LineItemRecord> coverageLineItems;
    }
    
    public class LineItemRecord {
        @InvocableVariable @AuraEnabled public String Risk_Name;
        @InvocableVariable @AuraEnabled public String Risk_Type;
        @InvocableVariable @AuraEnabled public String Risk_Details;
        @InvocableVariable @AuraEnabled public Decimal Risk_Premium_Amount;
        @InvocableVariable @AuraEnabled public Decimal Risk_Deductible;
        @InvocableVariable @AuraEnabled public String Category_Group;
        @InvocableVariable @AuraEnabled public String Category_Group_Type;
        @InvocableVariable @AuraEnabled public Decimal Risk_Insured_Amount;
        @InvocableVariable @AuraEnabled public Decimal Risk_Rate;
    }

    private static String normalizeCurrency(String currencyVal) {
        if (String.isBlank(currencyVal)) {
            return currencyVal;
        }
        return currencyVal.trim().equalsIgnoreCase(CURRENCY_WON) ? CURRENCY_KRW : currencyVal;
    }

    private static void populateAssetAddressFromLocation(InsurancePolicyAsset asset, String assetLocation) {
        if (String.isBlank(assetLocation)) {
            return;
        }

        List<String> locationParts = assetLocation.split(' ');
        if (locationParts.size() < 5) {
            return;
        }

        String zipCode = locationParts[0];
        String city = locationParts[1];
        String streetCore = locationParts[3] + ' ' + locationParts[4];

        String detailAddress = '';
        if (locationParts.size() > 5) {
            List<String> detailParts = new List<String>();
            for (Integer i = 5; i < locationParts.size(); i++) {
                detailParts.add(locationParts[i]);
            }
            detailAddress = String.join(detailParts, ' ');
        }

        asset.Asset_Address__Street__s = String.isNotBlank(detailAddress)
            ? streetCore + '\n' + detailAddress
            : streetCore;
        asset.Asset_Address__City__s = city;
        asset.Asset_Address__PostalCode__s = zipCode;
        asset.Asset_Address__CountryCode__s = 'KR';
    }
    
    // --- Main Logic ---
    
    @InvocableMethod(label='Create Single Policy Record' description='Parses JSON String (Single Object), creates records, and returns status + ID')
    public static List<FlowOutput> createRecords(List<FlowInput> inputs) {
        
        List<FlowOutput> results = new List<FlowOutput>();

        for (FlowInput input : inputs) {
            FlowOutput output = new FlowOutput();
            Savepoint sp = Database.setSavepoint();

            try {
                // 1. Validate Input
                if (String.isBlank(input.jsonString)) {
                    throw new CalloutException('Input JSON is empty.');
                }
                output.debugLog += '[STEP 1] Input Received. Length: ' + input.jsonString.length() + '. ';
                
                // --- NEW LOGIC START: Check for Error JSON format ---
                try {
                    Object parsedUntyped = JSON.deserializeUntyped(input.jsonString);
                    if (parsedUntyped instanceof Map<String, Object>) {
                        Map<String, Object> jsonMap = (Map<String, Object>) parsedUntyped;
                        
                        // Check if "Error" key exists and contains specific text
                        if (jsonMap.containsKey('Error')) {
                            String errorVal = String.valueOf(jsonMap.get('Error'));
                            if (String.isNotBlank(errorVal) && errorVal.containsIgnoreCase('pdf not supported')) {
                                throw new CalloutException('Validation Error: ' + errorVal);
                            }
                        }
                    }
                } catch (CalloutException ce) {
                    throw ce; // Re-throw the specific validation error to be caught by main catch block
                } catch (Exception ignore) {
                    // Ignore JSON parsing errors here, strict parsing happens in Step 2
                }
                // --- NEW LOGIC END ---
                
                // 2. Deserialize JSON
                PolicyRecord rec;
                try {
                    rec = (PolicyRecord) JSON.deserialize(input.jsonString, PolicyRecord.class);
                } catch(Exception jsonEx) {
                    throw new CalloutException('JSON Parsing Failed: ' + jsonEx.getMessage());
                }

                if(rec == null) {
                    throw new CalloutException('JSON deserialized to NULL. Check JSON syntax.');
                }
                output.debugLog += '[STEP 2] JSON Parsed. Policy Name in JSON: ' + rec.Name + '. ';

                // 3. Process The Single Record
                
                // --- Create Policy ---
                InsurancePolicy pol = new InsurancePolicy();
                if(input.insurancePolicyId != null) {
                    pol.Id = input.insurancePolicyId;
                    output.debugLog += 'Mode: UPDATE existing ID. ';
                } else {
                    output.debugLog += 'Mode: CREATE new. ';
                }
                
                // Assertion: Ensure Name Exists
                if(String.isBlank(rec.Name)) {
                    rec.Name = 'AutoGenerated-' + String.valueOf(Datetime.now().getTime());
                    output.debugLog += '(Warning: JSON Name was blank, auto-generated: ' + rec.Name + '). ';
                }
                
                pol.put('Application_Name__c', rec.Name);
                pol.EffectiveDate = rec.EffectiveDate;
 
                pol.put('Total_Sum_Insured_Amount__c', rec.TotalSumInsured);

                pol.put('Total_Premium_Amount__c', rec.PremiumAmount);

                pol.put('Term_Premium_Amount__c', rec.TermPremiumAmount);

                //pol.put('Commission__c', rec.Commission);

                pol.put('PremiumFrequency', rec.PremiumFrequency);
                pol.put('Currency__c', normalizeCurrency(rec.CurrencyVal));

                //pol.put('LineOfBusiness', rec.LineOfBusiness);

                //pol.put('PolicyType', rec.PolicyType);
                
                // Persist policy first so child records can safely reference InsurancePolicyId
                upsert pol;
                if (pol.Id == null) {
                    throw new CalloutException('CRITICAL FAILURE: Policy Upsert failed to generate an ID.');
                }
               
               

                // --- Create Assets & Build Map ---
                Map<String, Id> assetMap = new Map<String, Id>();
                if (rec.assets != null && !rec.assets.isEmpty()) {
                    List<InsurancePolicyAsset> assets = new List<InsurancePolicyAsset>();
                    for (AssetRecord a : rec.assets) {
                        InsurancePolicyAsset asset = new InsurancePolicyAsset();
                        asset.InsurancePolicyId = pol.Id;
                        asset.put('AssetName', a.AssetName); 
                        asset.put('AssetCode', a.AssetCode);
                       // asset.put('AssetCode', a.AssetLocation);
                        
                        populateAssetAddressFromLocation(asset, a.AssetLocation);
                        
                        //asset.put('Asset_Address__c', a.AssetLocation);//Asset_Location__c

                        // Effective From/To Dates
                        asset.EffectiveFromDate = a.EffectiveFromDate;
                        asset.EffectiveToDate = a.EffectiveToDate;

                        // Term Premium Amount
                        asset.put('TermPremium__c', a.TermPremiumAmount);

                        assets.add(asset);
                    }
                    if(!assets.isEmpty()) {
                        insert assets;
                        output.debugLog += '[STEP 5] Assets inserted: ' + assets.size() + '. ';
                        
                        for(InsurancePolicyAsset a : assets) {
                             String aName = (String) a.get('AssetName'); 
                             if(aName != null) assetMap.put(aName, a.Id);
                        }
                    }
                } else {
                    output.debugLog += '[INFO] No Assets in JSON. ';
                }

                // --- Create Product Clauses ---
                if (rec.productClauses != null && !rec.productClauses.isEmpty()) {
                    List<InsurancePolicyProductClause> clauses = new List<InsurancePolicyProductClause>();
                    for (ClauseRecord c : rec.productClauses) {
                        InsurancePolicyProductClause clause = new InsurancePolicyProductClause();
                        clause.InsurancePolicyId = pol.Id;
                        clause.Name = c.Name;
                        clause.put('AppliedSection__c', c.Section);
                        clause.put('ClauseText', c.Details);
                        clauses.add(clause);
                    }
                    if(!clauses.isEmpty()) {
                        insert clauses;
                        output.debugLog += '[STEP 6] Clauses inserted: ' + clauses.size() + '. ';
                    }
                } else {
                     output.debugLog += '[INFO] No Clauses in JSON. ';
                }

                // --- Create Coverages & Line Items ---
                if (rec.coverages != null && !rec.coverages.isEmpty()) {
                    List<InsurancePolicyCoverage> covList = new List<InsurancePolicyCoverage>();
                    Map<Integer, List<LineItemRecord>> lineItemsMap = new Map<Integer, List<LineItemRecord>>();
                    
                    for (Integer i = 0; i < rec.coverages.size(); i++) {
                        CoverageRecord c = rec.coverages[i];
                        InsurancePolicyCoverage cov = new InsurancePolicyCoverage();
                        cov.InsurancePolicyId = pol.Id;
                        cov.CategoryGroup = c.CategoryGroup;
                        cov.put('Description', c.Description);
                        cov.put('Currency__c', c.CurrencyVal);
                        cov.put('Coverage_Sum_Insured__c', c.CoverageSumInsured);
                        cov.put('Section_Sum_Insured__c', c.SectionSumInsured);
                        cov.put('Coverage_Premium_Amount__c', c.CoveragePremiumAmount);
                        cov.put('Section_Premium_Amount__c', c.SectionPremiumAmount);
                        cov.put('Coverage_Deductible_Amount__c', c.CoverageDeductibleAmount);
                        cov.put('Limit_Amount__c', c.LimitAmount); 

                        if (c.LinkedAssetName != null && assetMap.containsKey(c.LinkedAssetName)) {
                            cov.InsurancePolicyAssetId = assetMap.get(c.LinkedAssetName);
                        }
                        
                        covList.add(cov);
                        lineItemsMap.put(i, c.coverageLineItems);
                    }
                    if(!covList.isEmpty()) {
                        insert covList;
                        output.debugLog += '[STEP 7] Coverages inserted: ' + covList.size() + '. ';
                    }

                    // --- Create Coverage Line Items ---
                    List<SObject> allItems = new List<SObject>(); 
                    Schema.SObjectType targetType = Schema.getGlobalDescribe().get('Insurance_Policy_Coverage_Lineitem__c');//InsurancePolicycoveragelineitem

                    if(targetType == null) {
                           output.debugLog += '[WARNING] Object InsurancePolicycoveragelineitem not found in Org. ';
                    }

                    for (Integer i = 0; i < covList.size(); i++) {
                        Id covId = covList[i].Id;
                        Id assetId = covList[i].InsurancePolicyAssetId; 
                        
                        List<LineItemRecord> items = lineItemsMap.get(i);
                        if (items != null && targetType != null) {
                            for (LineItemRecord item : items) {
                                SObject line = targetType.newSObject();
                                
                                line.put('Insurance_Policy_Coverage__c', covId);
                                if(assetId != null) {
                                    line.put('Insurance_Policy_Asset__c', assetId);
                                }
                                
                                line.put('Risk_Name__c', item.Risk_Name);
                                line.put('Risk_Type__c', item.Risk_Type);
                                line.put('Risk_Details__c', item.Risk_Details);
                                line.put('Risk_Premium_Amount__c', item.Risk_Premium_Amount);
                                line.put('Risk_Deductible__c', item.Risk_Deductible);
                                line.put('Risk_Insured_Amount__c', item.Risk_Insured_Amount);
                                line.put('Risk_Rate__c', item.Risk_Rate);

                                line.put('Category_Group__c', item.Category_Group);
                                line.put('Category_Group_Type__c', item.Category_Group_Type);
                                
                                allItems.add(line);
                            }
                        }
                    }
                    if (!allItems.isEmpty()) {
                        insert allItems;
                        pol.IS_OCR_Lineitem_Complted__c =true;
                        pol.IsOCRComplated__c  =true;
                        output.debugLog += '[STEP 8] LineItems inserted: ' + allItems.size() + '. ';
                    }
                } else {
                     output.debugLog += '[INFO] No Coverages in JSON. ';
                }
                
                update pol;
                output.processedPolicyId = pol.Id;
                output.debugLog += '[STEP 3] Policy Upserted SUCCESS. ID: ' + pol.Id + '. ';   
                output.isSuccess = true;
                
                // FINAL VERIFICATION (Runtime Assertion)
                // This checks what is actually in the DB right now before the method finishes
                Integer countAssets = [SELECT count() FROM InsurancePolicyAsset WHERE InsurancePolicyId = :pol.Id];
           
                Integer countCovs = [SELECT count() FROM InsurancePolicyCoverage WHERE InsurancePolicyId = :pol.Id];
               // Integer countCovlineItems = [SELECT count() FROM Insurance_Policy_Coverage_Lineitem__c WHERE Insurance_Policy_Coverage__c = :covList[0].Ids];
                output.debugLog += ' || FINAL DB CHECK: Assets=' + countAssets + ', Coverages=' + countCovs;

            } catch (Exception e) {
                Database.rollback(sp);
                output.isSuccess = false;
                output.processedPolicyId = null; 
                output.errorMessage = 'Error: ' + e.getMessage();
                output.debugLog += ' [CRITICAL EXCEPTION] ' + e.getMessage() + ' | Stack: ' + e.getStackTraceString();
                System.debug(output.debugLog);
            }
            results.add(output);
        }
        return results;
    }
}