public class SlipInfoProcessor {

    // --- Constants ---
    private static final String RECORD_TYPE_SLIP = 'Slip';
    private static final String TYPE_CEDANT_OFFER = 'Cedant Offer';
    private static final String TYPE_CEDANT_CLOSING = 'Cedant Closing';
    private static final String SLIP_TYPE_OFFER = 'Offer';
    private static final String CURRENCY_WON = 'WON';
    private static final String CURRENCY_KRW = 'KRW';

    // Cached field lengths
    private static Integer grossPremDpMaxLength;
    private static Integer occupancyBizMaxLength;
    private static Id slipRecordTypeId;

    // --- 1. Flow Input & Output Wrappers ---

    public class FlowInput {
        @InvocableVariable(label='JSON String' description='The JSON payload containing Slip Information' required=true)
        public String jsonString;

        @InvocableVariable(label='Parent Opportunity ID' description='Optional: Link this Slip Info to an Opportunity')
        public Id opportunityId;

        @InvocableVariable(label='Slip Type' description='Slip type from the screen')
        public String slipType;
    }

    public class FlowOutput {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;

        @InvocableVariable(label='Error Message')
        public String errorMessage;

        @InvocableVariable(label='Created Record ID')
        public Id createdRecordId;

        @InvocableVariable(label='Debug Log')
        public String debugLog;

        public FlowOutput() {
            this.isSuccess = true;
            this.errorMessage = '';
            this.debugLog = '';
        }
    }

    // --- 2. JSON Wrapper Classes ---

    public class ProportionalReinsuranceWrapper {
        public String CurrencyVal;
        public String GrossPremium;
        public String Reins;
        public String ReComm;
        public String NetReInsPremium;
        public String Type;
    }

    public class TSIbyLocationWrapper {
        public String TSI;
        public String TSI_Currency;
        public String Type;
    }

    public class SlipInfoWrapper {
        public String Form;
        public String Reinsured;
        public String Insured;
        public String Policy_Holder;
        public String Policy_No;
        public String PeriodFrom_c;
        public String PeriodTo_c;
        public String Location;
        public String Territory_Scope;
        public String Choice_of_Law_and_Jurisdiction;
        public String Occupancy_Business;
        public String Covered_Risk;
        public String Interest;
        public String Gross_Prem_100;
        public String Gross_Prem_DP_Applied;
        public String RI_Cession_Reins_Percent;
        public String RI_Comm_Percent;
        public String Other_Deduction;
        public String Limit_of_Liability;
        public String Deductible;
        public String Terms_and_Conditions;
        public String Extension_Clauses;
        public String Loss_Record;
        public String Additional_Information;
        public String Slip_Type;
        public String Total_Sum_Insured_Currency;
        public String Total_Sum_Insured;
        public List<ProportionalReinsuranceWrapper> ProportionalReinsurance;
        public List<TSIbyLocationWrapper> TSIbyLocation;
    }

    // --- Helper Methods ---

    private static String sanitizeJson(String rawJson) {
        if (String.isBlank(rawJson)) {
            return rawJson;
        }
        String result = '';
        Boolean inQuotes = false;
        Boolean escaped = false;

        for (Integer i = 0; i < rawJson.length(); i++) {
            String ch = rawJson.substring(i, i + 1);
            if (ch == '\\' && !escaped) {
                escaped = true;
            } else if (ch == '"' && !escaped) {
                inQuotes = !inQuotes;
            } else {
                escaped = false;
            }
            result += ch;
        }
        return result;
    }

    private static Decimal parseNumericString(String val) {
        if (String.isBlank(val)) {
            return null;
        }
        String cleaned = val.replaceAll('[^0-9.\\-]', '');
        if (String.isBlank(cleaned)) {
            return null;
        }
        try {
            return Decimal.valueOf(cleaned);
        } catch (Exception e) {
            return null;
        }
    }

    private static String getStringFromMap(Map<String, Object> m, String key) {
        if (m == null || !m.containsKey(key) || m.get(key) == null) {
            return null;
        }
        Object v = m.get(key);
        System.debug(LoggingLevel.DEBUG, 'getStringFromMap - key: ' + key + ', value: ' + v);
        // Use JSON serialization and deserialization to preserve special characters for all types
        String result = (String) JSON.deserialize(JSON.serialize(v), String.class);
        System.debug(LoggingLevel.DEBUG, 'getStringFromMap - key: ' + key + ', result after JSON processing: ' + result);
        return result;
    }

    private static List<ProportionalReinsuranceWrapper> parseProportionalReinsurance(Object prNode) {
        List<ProportionalReinsuranceWrapper> prList = new List<ProportionalReinsuranceWrapper>();
        if (prNode == null) {
            return prList;
        }
        if (prNode instanceof Map<String, Object>) {
            prList.add(proportionalFromMap((Map<String, Object>) prNode));
            return prList;
        }
        if (prNode instanceof List<Object>) {
            for (Object o : (List<Object>) prNode) {
                if (o instanceof Map<String, Object>) {
                    prList.add(proportionalFromMap((Map<String, Object>) o));
                }
            }
        }
        return prList;
    }

    private static ProportionalReinsuranceWrapper proportionalFromMap(Map<String, Object> m) {
        ProportionalReinsuranceWrapper w = new ProportionalReinsuranceWrapper();
        w.CurrencyVal = getStringFromMap(m, 'CurrencyVal');
        w.GrossPremium = getStringFromMap(m, 'GrossPremium');
        w.Reins = getStringFromMap(m, 'Reins');
        w.ReComm = getStringFromMap(m, 'ReComm');
        w.NetReInsPremium = getStringFromMap(m, 'NetReInsPremium');
        w.Type = RECORD_TYPE_SLIP;
        return w;
    }

    private static List<TSIbyLocationWrapper> parseTSIbyLocation(Object node) {
        List<TSIbyLocationWrapper> tsiByLocationList = new List<TSIbyLocationWrapper>();
        if (node == null) {
            return tsiByLocationList;
        }
        if (node instanceof Map<String, Object>) {
            tsiByLocationList.add(tsibyLocationFromMap((Map<String, Object>) node));
            return tsiByLocationList;
        }
        if (node instanceof List<Object>) {
            for (Object o : (List<Object>) node) {
                if (o instanceof Map<String, Object>) {
                    tsiByLocationList.add(tsibyLocationFromMap((Map<String, Object>) o));
                }
            }
        }
        return tsiByLocationList;
    }

    private static TSIbyLocationWrapper tsibyLocationFromMap(Map<String, Object> m) {
        TSIbyLocationWrapper w = new TSIbyLocationWrapper();
        w.TSI = getStringFromMap(m, 'TSI');
        w.TSI_Currency = getStringFromMap(m, 'TSI_Currency');
        w.Type = RECORD_TYPE_SLIP;
        return w;
    }

    private static String convertCurrency(String curr) {
        if (String.isNotBlank(curr) && curr.trim().equalsIgnoreCase(CURRENCY_WON)) {
            return CURRENCY_KRW;
        }
        return curr;
    }
     //260423
    //private static Integer getGrossPremDpMaxLength() {
      //  if (grossPremDpMaxLength == null) {
        //    grossPremDpMaxLength = Integer.valueOf(OPP_SlipInfo__c.GrossPremDP__c.getDescribe().getLength());
        //}
        //return grossPremDpMaxLength;
    //}

    private static Integer getOccupancyBizMaxLength() {
        if (occupancyBizMaxLength == null) {
        occupancyBizMaxLength = Integer.valueOf(OPP_SlipInfo__c.OccupancyBiz__c.getDescribe().getLength());
        }
        return occupancyBizMaxLength;
    }

    private static Id getSlipRecordTypeId() {
        if (slipRecordTypeId == null) {
            Schema.RecordTypeInfo rti = Schema.SObjectType.OPP_SlipInfo__c.getRecordTypeInfosByDeveloperName().get(RECORD_TYPE_SLIP);
            if (rti != null) {
                slipRecordTypeId = rti.getRecordTypeId();
            }
            if (slipRecordTypeId == null) {
                throw new CalloutException('Record type ' + RECORD_TYPE_SLIP + ' not found for OPP_SlipInfo__c.');
            }
        }
        return slipRecordTypeId;
    }

    private static String truncateToMaxLength(String value, Integer maxLen) {
        if (String.isBlank(value) || maxLen == null || maxLen <= 0) {
            return value;
        }
        return value.length() > maxLen ? value.left(maxLen) : value;
    }

    private static Datetime parseDatetime(String dtStr) {
        if (String.isBlank(dtStr)) {
            return null;
        }
        dtStr = dtStr.replace('T', ' ');
        if (dtStr.length() == 16) {
            dtStr += ':00';
        }
        try {
            Integer year = Integer.valueOf(dtStr.substring(0, 4));
            Integer month = Integer.valueOf(dtStr.substring(5, 7));
            Integer day = Integer.valueOf(dtStr.substring(8, 10));
            Integer hour = Integer.valueOf(dtStr.substring(11, 13));
            Integer minute = Integer.valueOf(dtStr.substring(14, 16));
            Integer second = Integer.valueOf(dtStr.substring(17, 19));
            return Datetime.newInstanceGmt(year, month, day, hour, minute, second);
        } catch (Exception e) {
            return null;
        }
    }

    private static String compoundAddressToString(Address addr) {
        if (addr == null) {
            return '';
        }
        List<String> parts = new List<String>();
        if (String.isNotBlank(addr.getStreet())) {
            parts.add(addr.getStreet());
        }
        if (String.isNotBlank(addr.getCity())) {
            parts.add(addr.getCity());
        }
        if (String.isNotBlank(addr.getStateCode())) {
            parts.add(addr.getStateCode());
        } else if (String.isNotBlank(addr.getState())) {
            parts.add(addr.getState());
        }
        if (String.isNotBlank(addr.getPostalCode())) {
            parts.add(addr.getPostalCode());
        }
        if (String.isNotBlank(addr.getCountryCode())) {
            parts.add(addr.getCountryCode());
        } else if (String.isNotBlank(addr.getCountry())) {
            parts.add(addr.getCountry());
        }
        return String.join(parts, ', ');
    }

    private static String ConvertTSICurrencyString(String TSI, String tsiCurrency) {
        if (String.isBlank(TSI) || String.isBlank(tsiCurrency)) {
            return TSI;
        }
        String cleanedTSI = TSI.replaceAll('[^0-9.\\-]', '');
        if (String.isBlank(cleanedTSI)) {
            return TSI;
        }

        Decimal value = Decimal.valueOf(cleanedTSI);
        return convertCurrency(tsiCurrency) + ' ' + value.format();
    }

    private static String buildTSIByLocationSummary(List<TSIbyLocationWrapper> tsiByLocationList) {
        if (tsiByLocationList == null || tsiByLocationList.isEmpty()) {
            return null;
        }

        List<String> formattedItems = new List<String>();
        for (TSIbyLocationWrapper tsiRow : tsiByLocationList) {
            if (tsiRow == null) {
                continue;
            }
            Decimal tsiValue = parseNumericString(tsiRow.TSI);
            String tsiCurrency = convertCurrency(tsiRow.TSI_Currency);
            if (tsiValue == null || String.isBlank(tsiCurrency)) {
                continue;
            }
            formattedItems.add(tsiCurrency + ' ' + tsiValue.format());
        }

        return formattedItems.isEmpty() ? null : String.join(formattedItems, ' / ');
    }

    // --- 3. Main Invocable Method ---

    @InvocableMethod(label='Create Slip Info' description='Deserializes JSON and creates an OPP_SlipInfo__c record')
    public static List<FlowOutput> createSlipInfo(List<FlowInput> inputs) {
        if (inputs == null || inputs.isEmpty()) {
            return new List<FlowOutput>();
        }

        List<FlowOutput> results = new List<FlowOutput>();
        for (Integer i = 0; i < inputs.size(); i++) {
            results.add(new FlowOutput());
        }

        // Bulk query Opportunities
        Map<Id, Opportunity> oppMap = bulkQueryOpportunities(inputs);

        // Prepare collections for bulk DML
        List<OPP_SlipInfo__c> slipsToInsert = new List<OPP_SlipInfo__c>();
        List<OPP_PremiumSchedule__c> premSchedulesToInsert = new List<OPP_PremiumSchedule__c>();
        List<OPP_TSIByLocation__c> tsiByLocationToInsert = new List<OPP_TSIByLocation__c>();
        Map<Integer, List<SObject>> recordsByInputIndex = new Map<Integer, List<SObject>>();

        // Process each input
        for (Integer i = 0; i < inputs.size(); i++) {
            processInput(inputs[i], results[i], oppMap, slipsToInsert, premSchedulesToInsert, tsiByLocationToInsert, recordsByInputIndex, i);
        }

        // Perform bulk DML
        performBulkDml(slipsToInsert, premSchedulesToInsert, tsiByLocationToInsert, recordsByInputIndex, results);

        return results;
    }

    private static Map<Id, Opportunity> bulkQueryOpportunities(List<FlowInput> inputs) {
        Set<Id> opportunityIds = new Set<Id>();
        for (FlowInput input : inputs) {
            if (input.opportunityId != null) {
                opportunityIds.add(input.opportunityId);
            }
        }
        if (opportunityIds.isEmpty()) {
            return new Map<Id, Opportunity>();
        }
        return new Map<Id, Opportunity>([
            SELECT Id, CedantName_lk__r.CompanyNameEng__c, CedantName_lk__r.Address__c
            FROM Opportunity
            WHERE Id IN :opportunityIds
        ]);
    }

    private static void processInput(FlowInput input, FlowOutput output, Map<Id, Opportunity> oppMap,
                                     List<OPP_SlipInfo__c> slipsToInsert, List<OPP_PremiumSchedule__c> premSchedulesToInsert,
                                     List<OPP_TSIByLocation__c> tsiByLocationToInsert, Map<Integer, List<SObject>> recordsByInputIndex, Integer index) {
        Savepoint sp = Database.setSavepoint();
        String fullDebugLog = '=== SlipInfoProcessor Execution Log ===\n';
        fullDebugLog += 'Execution Time: ' + Datetime.now().format() + '\n\n';
        fullDebugLog += '--- Starting processing for input ' + index + ' ---\n';
        fullDebugLog += 'Input slipType: ' + input.slipType + '\n';
        fullDebugLog += 'Input opportunityId: ' + input.opportunityId + '\n';

        try {
            if (String.isBlank(input.jsonString)) {
                throw new CalloutException('Input JSON string is empty.');
            }

            SlipInfoWrapper wrapper = parseJson(input.jsonString, fullDebugLog);

            if (String.isBlank(input.slipType)) {
                throw new CalloutException('Input Slip Type string is empty.');
            }

            OPP_SlipInfo__c newSlip = createSlipRecord(wrapper, input, oppMap);
            slipsToInsert.add(newSlip);

            List<SObject> recordsForThisInput = new List<SObject>{newSlip};

            // Create related records
            createRelatedRecords(wrapper, input.opportunityId, premSchedulesToInsert, tsiByLocationToInsert, recordsForThisInput);

            recordsByInputIndex.put(index, recordsForThisInput);

            output.isSuccess = true;
            fullDebugLog += '>> Processing Completed Successfully for this input.\n\n';

        } catch (Exception e) {
            Database.rollback(sp);
            output.isSuccess = false;
            output.errorMessage = 'Error: ' + e.getMessage();
            fullDebugLog += '\n[FATAL ERROR]\n';
            fullDebugLog += 'Message: ' + e.getMessage() + '\n';
            fullDebugLog += 'Line Number: ' + e.getLineNumber() + '\n';
            fullDebugLog += 'Stack Trace: ' + e.getStackTraceString() + '\n\n';
        }

        output.debugLog = fullDebugLog;
    }

    private static SlipInfoWrapper parseJson(String jsonString, String debugLog) {
        String sanitizedJson = sanitizeJson(jsonString);
        debugLog += '>> Sanitized JSON successfully.\n';

        Map<String, Object> rawMap = (Map<String, Object>) JSON.deserializeUntyped(sanitizedJson);
        debugLog += '>> Deserialized Untyped successfully.\n';

        Object prNode = rawMap.get('ProportionalReinsurance');
        List<ProportionalReinsuranceWrapper> prList = parseProportionalReinsurance(prNode);
        rawMap.remove('ProportionalReinsurance');

        Object tsiByLocationNode = rawMap.get('TSIbyCurrency');
        List<TSIbyLocationWrapper> tsiByLocationList = parseTSIbyLocation(tsiByLocationNode);
        rawMap.remove('TSIbyCurrency');

        SlipInfoWrapper wrapper = new SlipInfoWrapper();
        wrapper.Form = getStringFromMap(rawMap, 'Form');
        wrapper.Reinsured = getStringFromMap(rawMap, 'Reinsured');
        wrapper.Insured = getStringFromMap(rawMap, 'Insured');
        wrapper.Policy_Holder = getStringFromMap(rawMap, 'Policy_Holder');
        wrapper.Policy_No = getStringFromMap(rawMap, 'Policy_No');
        wrapper.PeriodFrom_c = getStringFromMap(rawMap, 'PeriodFrom_c');
        wrapper.PeriodTo_c = getStringFromMap(rawMap, 'PeriodTo_c');
        wrapper.Location = getStringFromMap(rawMap, 'Location');
        wrapper.Territory_Scope = getStringFromMap(rawMap, 'Territory_Scope');
        wrapper.Choice_of_Law_and_Jurisdiction = getStringFromMap(rawMap, 'Choice_of_Law_and_Jurisdiction');
        wrapper.Occupancy_Business = getStringFromMap(rawMap, 'Occupancy_Business');
        wrapper.Covered_Risk = getStringFromMap(rawMap, 'Covered_Risk');
        wrapper.Interest = getStringFromMap(rawMap, 'Interest');
        wrapper.Gross_Prem_100 = getStringFromMap(rawMap, 'Gross_Prem_100');
        wrapper.Gross_Prem_DP_Applied = getStringFromMap(rawMap, 'Gross_Prem_DP_Applied');
        wrapper.RI_Cession_Reins_Percent = getStringFromMap(rawMap, 'RI_Cession_Reins_Percent');
        wrapper.RI_Comm_Percent = getStringFromMap(rawMap, 'RI_Comm_Percent');
        wrapper.Other_Deduction = getStringFromMap(rawMap, 'Other_Deduction');
        wrapper.Limit_of_Liability = getStringFromMap(rawMap, 'Limit_of_Liability');
        
        wrapper.Deductible = getStringFromMap(rawMap, 'Deductible');
        wrapper.Terms_and_Conditions = getStringFromMap(rawMap, 'Terms_and_Conditions');
        wrapper.Extension_Clauses = getStringFromMap(rawMap, 'Extension_Clauses');
        wrapper.Loss_Record = getStringFromMap(rawMap, 'Loss_Record');
        wrapper.Additional_Information = getStringFromMap(rawMap, 'Additional_Information');
        wrapper.Slip_Type = getStringFromMap(rawMap, 'Slip_Type');
        wrapper.Total_Sum_Insured_Currency = getStringFromMap(rawMap, 'Total_Sum_Insured_Currency');
        wrapper.Total_Sum_Insured = getStringFromMap(rawMap, 'Total_Sum_Insured');
        wrapper.ProportionalReinsurance = prList;
        wrapper.TSIbyLocation = tsiByLocationList;

        return wrapper;
    }

    private static OPP_SlipInfo__c createSlipRecord(SlipInfoWrapper wrapper, FlowInput input, Map<Id, Opportunity> oppMap) {
        OPP_SlipInfo__c newSlip = new OPP_SlipInfo__c();

        // Set Opportunity and related fields
        if (input.opportunityId != null && oppMap.containsKey(input.opportunityId)) {
            Opportunity opp = oppMap.get(input.opportunityId);
            newSlip.Opportunity_lk__c = input.opportunityId;
            if (opp.CedantName_lk__r != null) {
                String eng = opp.CedantName_lk__r.CompanyNameEng__c;
                String addr = compoundAddressToString(opp.CedantName_lk__r.Address__c);
                newSlip.Reinsured__c = (String.isNotBlank(eng) ? eng : '') +
                     (String.isNotBlank(addr) ? ' ' + addr : '');
                 newSlip.Reinsured__c = newSlip.Reinsured__c.trim();
                if (String.isBlank(newSlip.Reinsured__c) && String.isNotBlank(wrapper.Reinsured)) {
                     newSlip.Reinsured__c = wrapper.Reinsured;
                }
            } else if (String.isNotBlank(wrapper.Reinsured)) {
                newSlip.Reinsured__c = wrapper.Reinsured;
            }
        }

        newSlip.Type__c = (String.isNotBlank(input.slipType) && input.slipType.trim().equalsIgnoreCase(SLIP_TYPE_OFFER)) ? TYPE_CEDANT_OFFER : TYPE_CEDANT_CLOSING;
        newSlip.Latest_is__c = true;
        newSlip.RecordTypeId = getSlipRecordTypeId();

        // Map fields
        newSlip.Form__c = wrapper.Form;
        newSlip.Insured__c = wrapper.Insured;
        newSlip.PolicyHolder__c = wrapper.Policy_Holder;
        newSlip.PolicyNo__c = wrapper.Policy_No;
        newSlip.PeriodFrom__c = parseDatetime(wrapper.PeriodFrom_c);
        newSlip.PeriodTo__c = parseDatetime(wrapper.PeriodTo_c);
        newSlip.Location__c = wrapper.Location;
        if (String.isNotBlank(wrapper.Territory_Scope)) {
            newSlip.TerritoryScope__c = wrapper.Territory_Scope.replaceAll('\\s*,\\s*', ';');
        }
        if (String.isNotBlank(wrapper.Choice_of_Law_and_Jurisdiction)) {
            newSlip.GoverningLaw__c = wrapper.Choice_of_Law_and_Jurisdiction.replaceAll('\\s*,\\s*', ';');
        }
        newSlip.OccupancyBiz__c = truncateToMaxLength(wrapper.Occupancy_Business, getOccupancyBizMaxLength());
        newSlip.CoveredRisk__c = wrapper.Covered_Risk;
        newSlip.Interest__c = wrapper.Interest;
        newSlip.OtherDeduction__c = wrapper.Other_Deduction;
        newSlip.LimitofLiability__c = wrapper.Limit_of_Liability;
        newSlip.Deductible__c = wrapper.Deductible;
        newSlip.TermsConds__c = wrapper.Terms_and_Conditions;
        newSlip.ExtensionClauses__c = wrapper.Extension_Clauses;
        newSlip.LossRecord__c = wrapper.Loss_Record;
        newSlip.AddInfo__c = wrapper.Additional_Information;
        String tsiByLocationSummary = buildTSIByLocationSummary(wrapper.TSIbyLocation);
        newSlip.TSI__c = String.isNotBlank(tsiByLocationSummary)
            ? tsiByLocationSummary
            : ConvertTSICurrencyString(wrapper.Total_Sum_Insured, wrapper.Total_Sum_Insured_Currency);
        newSlip.RICession__c = parseNumericString(wrapper.RI_Cession_Reins_Percent);
        newSlip.RIComm__c = parseNumericString(wrapper.RI_Comm_Percent);
        //newSlip.GrossPrem100__c = wrapper.Gross_Prem_100;
        //newSlip.GrossPremDP__c = truncateToMaxLength(wrapper.Gross_Prem_DP_Applied, getGrossPremDpMaxLength());

        System.debug(LoggingLevel.DEBUG, 'createSlipRecord : ' + newSlip); 

        return newSlip;
    }

    private static void createRelatedRecords(SlipInfoWrapper wrapper, Id opportunityId,
                                             List<OPP_PremiumSchedule__c> premSchedulesToInsert,
                                             List<OPP_TSIByLocation__c> tsiByLocationToInsert,
                                             List<SObject> recordsForThisInput) {
        if (wrapper.ProportionalReinsurance != null && !wrapper.ProportionalReinsurance.isEmpty()) {
            for (ProportionalReinsuranceWrapper prRow : wrapper.ProportionalReinsurance) {
                OPP_PremiumSchedule__c ps = new OPP_PremiumSchedule__c();
                ps.SlipGrossPrem__c = parseNumericString(prRow.GrossPremium);
                ps.Prem_Currency__c = convertCurrency(prRow.CurrencyVal);
                if (opportunityId != null) {
                    ps.Opportunity_lk__c = opportunityId;
                }
                ps.Type__c = prRow.Type;
                premSchedulesToInsert.add(ps);
                recordsForThisInput.add(ps);
            }
        }

        if (wrapper.TSIbyLocation != null && !wrapper.TSIbyLocation.isEmpty()) {
            for (TSIbyLocationWrapper tsiRow : wrapper.TSIbyLocation) {
                OPP_TSIByLocation__c tsiByLocation = new OPP_TSIByLocation__c();
                tsiByLocation.SlipTSI__c = parseNumericString(tsiRow.TSI);
                tsiByLocation.TSICurrency__c = convertCurrency(tsiRow.TSI_Currency);
                tsiByLocation.Type__c = tsiRow.Type;
                tsiByLocationToInsert.add(tsiByLocation);
                recordsForThisInput.add(tsiByLocation);
            }
        }
    }

    private static void performBulkDml(List<OPP_SlipInfo__c> slipsToInsert, List<OPP_PremiumSchedule__c> premSchedulesToInsert,
                                       List<OPP_TSIByLocation__c> tsiByLocationToInsert, Map<Integer, List<SObject>> recordsByInputIndex,
                                       List<FlowOutput> results) {
        Savepoint bulkSp = Database.setSavepoint();
        try {
            if (!slipsToInsert.isEmpty()) {
                insert slipsToInsert;
                // Set lookup fields after insert
                for (Integer i = 0; i < slipsToInsert.size(); i++) {
                    OPP_SlipInfo__c slip = slipsToInsert[i];
                    List<SObject> records = recordsByInputIndex.get(i);
                    if (records != null) {
                        for (SObject rec : records) {
                            if (rec instanceof OPP_PremiumSchedule__c) {
                                ((OPP_PremiumSchedule__c) rec).SlipInfo_lk__c = slip.Id;
                            } else if (rec instanceof OPP_TSIByLocation__c) {
                                ((OPP_TSIByLocation__c) rec).SlipInfo_md__c = slip.Id;
                            }
                        }
                    }
                }
            }

            if (!premSchedulesToInsert.isEmpty()) {
                insert premSchedulesToInsert;
            }

            if (!tsiByLocationToInsert.isEmpty()) {
                insert tsiByLocationToInsert;
            }

            // Update results with created IDs
            for (Integer i = 0; i < results.size(); i++) {
                if (results[i].isSuccess && i < slipsToInsert.size()) {
                    results[i].createdRecordId = slipsToInsert[i].Id;
                    results[i].debugLog += '>> Successfully inserted OPP_SlipInfo__c. Record ID: ' + slipsToInsert[i].Id + '\n';
                    results[i].debugLog += '>> Successfully inserted related records.\n';
                }
            }

        } catch (Exception e) {
            Database.rollback(bulkSp);
            for (FlowOutput output : results) {
                if (output.isSuccess) {
                    output.isSuccess = false;
                    output.errorMessage = 'Bulk Insert Error: ' + e.getMessage();
                    output.debugLog += '\n[BULK INSERT ERROR]\n';
                    output.debugLog += 'Message: ' + e.getMessage() + '\n';
                    output.debugLog += 'Stack Trace: ' + e.getStackTraceString() + '\n\n';
                }
            }
        }
    }
}