@IsTest(SeeAllData=true)
private class SlipInfoProcessorTest {

    private static final String BASE_JSON = '{"Form":"Proportional","Reinsured":"Wrapper Reinsured"}';

    private static Opportunity getAnyOpp() {
        return [
            SELECT Id, CedantName_lk__r.CompanyNameEng__c
            FROM Opportunity
            LIMIT 1
        ];
    }

    private static Opportunity getOppWithoutCedantFallbackAny() {
        List<Opportunity> noCedant = [
            SELECT Id, CedantName_lk__r.CompanyNameEng__c
            FROM Opportunity
            WHERE CedantName_lk__c = NULL
            LIMIT 1
        ];
        if (!noCedant.isEmpty()) {
            return noCedant[0];
        }
        return getAnyOpp();
    }

    private static List<SlipInfoProcessor.FlowOutput> runSingle(String json, String slipType, Id oppId) {
        SlipInfoProcessor.FlowInput input = new SlipInfoProcessor.FlowInput();
        input.jsonString = json;
        input.slipType = slipType;
        input.opportunityId = oppId;
        return SlipInfoProcessor.createSlipInfo(new List<SlipInfoProcessor.FlowInput>{ input });
    }

    private static String firstPicklistValue(Schema.SObjectField fieldToken) {
        List<Schema.PicklistEntry> entries = fieldToken.getDescribe().getPicklistValues();
        if (entries == null || entries.isEmpty()) {
            return null;
        }
        return entries[0].getValue();
    }

    @IsTest
    static void testSuccess_FullPayload_ListNodesAndConversions() {
        String longText = '';
        for (Integer i = 0; i < 320; i++) {
            longText += 'A';
        }

        String json =
            '{"Form":"Proportional",' +
            '"Reinsured":"Test Reinsured Co",' +
            '"Insured":"Test Insured Co",' +
            '"Policy_Holder":"Test Policyholder",' +
            '"Policy_No":"POL-2025-001",' +
            '"PeriodFrom_c":"2025-01-01T00:00",' +
            '"PeriodTo_c":"2025-12-31T23:59:59",' +
            '"Location":"Seoul, Korea",' +
            '"Occupancy_Business":"' + longText + '",' +
            '"Covered_Risk":"Fire and Allied Perils",' +
            '"Interest":"Property Damage",' +
            '"Total_Sum_Insured":"1000000",' +
            '"Gross_Prem_100":"50000",' +
            '"Gross_Prem_DP_Applied":"' + longText + '",' +
            '"RI_Cession_Reins_Percent":"25.5%",' +
            '"RI_Comm_Percent":"10.0",' +
            '"Other_Deduction":"None",' +
            '"Limit_of_Liability":"500000 USD",' +
            '"Deductible":"10000 USD each occurrence",' +
            '"Terms_and_Conditions":"Standard T&C apply",' +
            '"Extension_Clauses":"Earthquake extension included",' +
            '"Loss_Record":"No losses in last 5 years",' +
            '"Additional_Information":"Renewal business",' +
            '"ProportionalReinsurance":[{"CurrencyVal":"WON","GrossPremium":"10000","Reins":"50","ReComm":"5","NetReInsPremium":"9500"}],' +
            '"TSIbyLocation":[{"TSI":"500000","TSI_Currency":"WON"}]}';

        Test.startTest();
        List<SlipInfoProcessor.FlowOutput> results = runSingle(json, 'offer', null);
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isSuccess, results[0].errorMessage);
        System.assertNotEquals(null, results[0].createdRecordId);

        OPP_SlipInfo__c slip = [
            SELECT Type__c, Latest_is__c, Form__c, Reinsured__c, Insured__c, PolicyHolder__c, PolicyNo__c, Location__c,
                   OccupancyBiz__c, RICession__c, RIComm__c,
                   PeriodFrom__c, PeriodTo__c
            FROM OPP_SlipInfo__c
            WHERE Id = :results[0].createdRecordId
        ];
        System.assertEquals('Cedant Offer', slip.Type__c);
        System.assertEquals(true, slip.Latest_is__c);
        System.assertEquals(25.5, slip.RICession__c);
        System.assertEquals(10.0, slip.RIComm__c);
        System.assertEquals(Datetime.newInstanceGmt(2025, 1, 1, 0, 0, 0), slip.PeriodFrom__c);
        System.assertEquals(Datetime.newInstanceGmt(2025, 12, 31, 23, 59, 59), slip.PeriodTo__c);
        System.assert(slip.OccupancyBiz__c.length() < longText.length());
        //System.assert(slip.GrossPremDP__c.length() < longText.length());

        OPP_PremiumSchedule__c ps = [
            SELECT SlipGrossPrem__c, Prem_Currency__c, SlipInfo_lk__c
            FROM OPP_PremiumSchedule__c
            WHERE SlipInfo_lk__c = :slip.Id
            LIMIT 1
        ];
        System.assertEquals(10000, ps.SlipGrossPrem__c);
        System.assertEquals('KRW', ps.Prem_Currency__c);

        OPP_TSIByLocation__c tsi = [
            SELECT SlipTSI__c, TSICurrency__c, Type__c, SlipInfo_md__c
            FROM OPP_TSIByLocation__c
            WHERE SlipInfo_md__c = :slip.Id
            LIMIT 1
        ];
        System.assertEquals(500000, tsi.SlipTSI__c);
        System.assertEquals('KRW', tsi.TSICurrency__c);
        System.assertEquals('Slip', tsi.Type__c);
    }

    @IsTest
    static void testSuccess_SingleObjectNodesAndNumericMapValues() {
        String json =
            '{"Form":"Proportional",' +
            '"Reinsured":"Wrapper Reinsured",' +
            '"RI_Cession_Reins_Percent":"1.2.3",' +
            '"RI_Comm_Percent":"-",'+
            '"PeriodFrom_c":"invalid-date",' +
            '"PeriodTo_c":"2025-06-15T10:30",' +
            '"ProportionalReinsurance":{"CurrencyVal":"USD","GrossPremium":12345.67,"Reins":50,"ReComm":5,"NetReInsPremium":11728.39},' +
            '"TSIbyLocation":{"TSI":98765,"TSI_Currency":"USD"}}';

        Test.startTest();
        List<SlipInfoProcessor.FlowOutput> results = runSingle(json, 'Closing', null);
        Test.stopTest();

        System.assertEquals(true, results[0].isSuccess, results[0].errorMessage);
        OPP_SlipInfo__c slip = [
            SELECT Type__c, RICession__c, RIComm__c, PeriodFrom__c, PeriodTo__c
            FROM OPP_SlipInfo__c
            WHERE Id = :results[0].createdRecordId
        ];
        System.assertEquals('Cedant Closing', slip.Type__c);
        System.assertEquals(null, slip.RICession__c);
        System.assertEquals(null, slip.RIComm__c);
        System.assertEquals(null, slip.PeriodFrom__c);
        System.assertEquals(Datetime.newInstanceGmt(2025, 6, 15, 10, 30, 0), slip.PeriodTo__c);

        OPP_PremiumSchedule__c ps = [
            SELECT SlipGrossPrem__c, Prem_Currency__c
            FROM OPP_PremiumSchedule__c
            WHERE SlipInfo_lk__c = :results[0].createdRecordId
            LIMIT 1
        ];
        System.assertEquals(12345.67, ps.SlipGrossPrem__c);
        System.assertEquals('USD', ps.Prem_Currency__c);
    }

    @IsTest
    static void testSuccess_WithOpportunity_CedantAndFallbackReinsured() {

        Opportunity withCedant = getAnyOpp();
        Opportunity withoutCedant = getOppWithoutCedantFallbackAny();

        Test.startTest();
        List<SlipInfoProcessor.FlowOutput> r1 = runSingle(BASE_JSON, 'Offer', withCedant.Id);
        List<SlipInfoProcessor.FlowOutput> r2 = runSingle(BASE_JSON, 'Offer', withoutCedant.Id);
        Test.stopTest();

        System.assertEquals(true, r1[0].isSuccess, r1[0].errorMessage);
        System.assertEquals(true, r2[0].isSuccess, r2[0].errorMessage);

        OPP_SlipInfo__c slipWithCedant = [
            SELECT Opportunity_lk__c, Reinsured__c
            FROM OPP_SlipInfo__c
            WHERE Id = :r1[0].createdRecordId
        ];
        System.assertEquals(withCedant.Id, slipWithCedant.Opportunity_lk__c);
        if (String.isNotBlank(withCedant.CedantName_lk__r.CompanyNameEng__c)) {
            System.assert(slipWithCedant.Reinsured__c.contains(withCedant.CedantName_lk__r.CompanyNameEng__c));
        } else {
            System.assertEquals('Wrapper Reinsured', slipWithCedant.Reinsured__c);
        }

        OPP_SlipInfo__c slipWithoutCedant = [
            SELECT Opportunity_lk__c, Reinsured__c
            FROM OPP_SlipInfo__c
            WHERE Id = :r2[0].createdRecordId
        ];
        System.assertEquals(withoutCedant.Id, slipWithoutCedant.Opportunity_lk__c);
        if (String.isBlank(withoutCedant.CedantName_lk__r.CompanyNameEng__c)) {
            System.assertEquals('Wrapper Reinsured', slipWithoutCedant.Reinsured__c);
        }
    }


    @IsTest
    static void testCoverage_OpportunityAddressAndBulkErrorPath() {
        Opportunity targetOpp = getAnyOpp();
        Account cedant = new Account(
            Name = 'Coverage Cedant',
            CompanyNameEng__c = 'Coverage Cedant Eng',
            Address__Street__s = '101 Coverage Rd',
            Address__City__s = 'Seoul',
            Address__PostalCode__s = '06111',
            Address__CountryCode__s = 'KR'
        );
        insert cedant;

        targetOpp.CedantName_lk__c = cedant.Id;
        update targetOpp;

        String validTerritory = firstPicklistValue(OPP_SlipInfo__c.TerritoryScope__c);
        String validLaw = firstPicklistValue(OPP_SlipInfo__c.GoverningLaw__c);
        if (validTerritory == null) {
            validTerritory = '';
        }
        if (validLaw == null) {
            validLaw = '';
        }
        String validJson =
            '{"Form":"Proportional","Reinsured":"Wrapper Reinsured","RI_Comm_Percent":"$$",' +
            '"Territory_Scope":"' + validTerritory + '","Choice_of_Law_and_Jurisdiction":"' + validLaw + '",' +
            '"ProportionalReinsurance":[{"CurrencyVal":"USD","GrossPremium":"100"}]}';
        String invalidJson =
            '{"Form":"Proportional","Reinsured":"Wrapper Reinsured",' +
            '"Territory_Scope":"INVALID_PICKLIST_VALUE",' +
            '"ProportionalReinsurance":[{"CurrencyVal":"USD","GrossPremium":"100"}]}';

        SlipInfoProcessor.FlowInput in1 = new SlipInfoProcessor.FlowInput();
        in1.jsonString = validJson;
        in1.slipType = 'Offer';
        in1.opportunityId = targetOpp.Id;

        SlipInfoProcessor.FlowInput in2 = new SlipInfoProcessor.FlowInput();
        in2.jsonString = invalidJson;
        in2.slipType = 'Offer';
        in2.opportunityId = targetOpp.Id;

        Test.startTest();
        List<SlipInfoProcessor.FlowOutput> outputs = SlipInfoProcessor.createSlipInfo(
            new List<SlipInfoProcessor.FlowInput>{ in1, in2 }
        );
        Test.stopTest();

        System.assertEquals(2, outputs.size());
        System.assertEquals(false, outputs[0].isSuccess);
        System.assert(outputs[0].errorMessage.contains('Bulk Insert Error'));
        System.assertEquals(false, outputs[1].isSuccess);
    }

    @IsTest
    static void testCoverage_SanitizeEscapedBackslash() {
        String json = '{"Form":"Proportional","Reinsured":"C:\\\\Temp \\"Quoted\\"","PeriodTo_c":"2025-12-31T23:59:59"}';
        List<SlipInfoProcessor.FlowOutput> out = runSingle(json, 'Offer', null);
        System.assertEquals(true, out[0].isSuccess, out[0].errorMessage);
    }

    @IsTest
    static void testCoverage_AddressNullAndStateCountryFallbackBranches() {
        Opportunity targetOpp = getAnyOpp();

        Account noAddressCedant = new Account(
            Name = 'No Address Cedant'
        );
        insert noAddressCedant;

        targetOpp.CedantName_lk__c = noAddressCedant.Id;
        update targetOpp;

        List<SlipInfoProcessor.FlowOutput> r1 = runSingle(BASE_JSON, 'Offer', targetOpp.Id);
        System.assertEquals(true, r1[0].isSuccess, r1[0].errorMessage);

        OPP_SlipInfo__c slip1 = [
            SELECT Reinsured__c
            FROM OPP_SlipInfo__c
            WHERE Id = :r1[0].createdRecordId
        ];
        System.assert(String.isNotBlank(slip1.Reinsured__c));

        Account stateCountryCedant = new Account(
            Name = 'State Country Cedant',
            CompanyNameEng__c = 'State Country Eng',
            Address__Street__s = '77 Fallback Ave',
            Address__City__s = 'Busan'
        );
        Map<String, Schema.SObjectField> accountFields = Account.SObjectType.getDescribe().fields.getMap();
        if (accountFields.containsKey('Address__State__s')) {
            stateCountryCedant.put('Address__State__s', 'Seoul');
        }
        if (accountFields.containsKey('Address__Country__s')) {
            stateCountryCedant.put('Address__Country__s', 'Korea');
        }
        insert stateCountryCedant;

        targetOpp.CedantName_lk__c = stateCountryCedant.Id;
        update targetOpp;

        List<SlipInfoProcessor.FlowOutput> r2 = runSingle(BASE_JSON, 'Offer', targetOpp.Id);
        System.assertEquals(true, r2[0].isSuccess, r2[0].errorMessage);
    }

    @IsTest
    static void testValidationAndErrorPaths() {
        SlipInfoProcessor.FlowInput valid = new SlipInfoProcessor.FlowInput();
        valid.jsonString = BASE_JSON;
        valid.slipType = 'Offer';

        SlipInfoProcessor.FlowInput blankJson = new SlipInfoProcessor.FlowInput();
        blankJson.jsonString = '';
        blankJson.slipType = 'Offer';

        SlipInfoProcessor.FlowInput blankType = new SlipInfoProcessor.FlowInput();
        blankType.jsonString = BASE_JSON;
        blankType.slipType = '';

        SlipInfoProcessor.FlowInput malformed = new SlipInfoProcessor.FlowInput();
        malformed.jsonString = '{"Form":"Broken"';
        malformed.slipType = 'Offer';

        Test.startTest();
        List<SlipInfoProcessor.FlowOutput> outputs = SlipInfoProcessor.createSlipInfo(
            new List<SlipInfoProcessor.FlowInput>{ valid, blankJson, blankType, malformed }
        );
        List<SlipInfoProcessor.FlowOutput> emptyListOutputs = SlipInfoProcessor.createSlipInfo(
            new List<SlipInfoProcessor.FlowInput>()
        );
        List<SlipInfoProcessor.FlowOutput> nullListOutputs = SlipInfoProcessor.createSlipInfo(null);
        Test.stopTest();

        System.assertEquals(4, outputs.size());
        System.assertEquals(true, outputs[0].isSuccess, outputs[0].errorMessage);
        System.assertEquals(false, outputs[1].isSuccess);
        System.assert(outputs[1].errorMessage.contains('empty'));
        System.assertEquals(false, outputs[2].isSuccess);
        System.assert(outputs[2].errorMessage.contains('Slip Type'));
        System.assertEquals(false, outputs[3].isSuccess);
        System.assert(outputs[3].errorMessage.contains('Error:'));
        System.assertEquals(0, emptyListOutputs.size());
        System.assertEquals(0, nullListOutputs.size());
    }

    @IsTest
    static void testWrapperClassesInitialization() {
        SlipInfoProcessor.FlowInput input = new SlipInfoProcessor.FlowInput();
        input.jsonString = '{}';
        input.slipType = 'Offer';

        SlipInfoProcessor.FlowOutput output = new SlipInfoProcessor.FlowOutput();
        System.assertEquals(true, output.isSuccess);
        System.assertEquals('', output.errorMessage);
        System.assertEquals('', output.debugLog);

        SlipInfoProcessor.SlipInfoWrapper wrapper = new SlipInfoProcessor.SlipInfoWrapper();
        wrapper.Form = 'Proportional';
        wrapper.Reinsured = 'Test Re';
        wrapper.Slip_Type = 'Offer';
        System.assertEquals('Proportional', wrapper.Form);
        System.assertEquals('Test Re', wrapper.Reinsured);
        System.assertEquals('Offer', wrapper.Slip_Type);
    }
}