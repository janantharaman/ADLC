/**********************************************************************************
 * @filename      : OPP_TestDataFactory.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-14 (수)
 * @group         :
 * @group-content :
 * @description   : Opportunity Domain Test Data Factory
 * @test-class    : OPP_TestDataFactory_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-14      i2max     Create
 * 1.1   2026-01-14      i2max     Add OwnerId to Opportunity
 **********************************************************************************/
@IsTest
public class OPP_TestDataFactory {

    final static Datetime dt = Datetime.now();
    final static Date BASE_START_DATE = Date.newInstance(dt.year(), 1, 1);
    final static Date BASE_END_DATE   = Date.newInstance(dt.year(), 12, 31);

    /**
     * @description Create Opportunity
     * @param accountId (Id): Account Id
     * @param name (String): Opportunity Name (If null, random name generated)
     * @param isInsert (Boolean): Insert flag
     * @return Opportunity
     */
    public static Opportunity createOpportunity(Id accountId, String name, Boolean isInsert) {
        return createOpportunity(accountId, name, isInsert, 'Reinsurance');
    }
    /**
     * @description Create Opportunity
     * @param accountId (Id): Account Id
     * @param name (String): Opportunity Name (If null, random name generated)
     * @param isInsert (Boolean): Insert flag
     * @param rtDevNm (String): Insert recordTypeDevName
     * @return Opportunity
     */
    public static Opportunity createOpportunity(Id accountId, String name, Boolean isInsert, String rtDevNm) {

        rtDevNm = String.isBlank(rtDevNm) ? 'Reinsurance' :rtDevNm ;
        Id recordTypeId = COM_MetaUtil.getRecordTypeIdByDeveloperName('Opportunity', rtDevNm);

        return createOpportunity(accountId, name, recordTypeId, isInsert);
    }
    
    /**
     * @description Create Opportunity with RecordType
     * @param accountId (Id): Account Id
     * @param name (String): Opportunity Name (If null, random name generated)
     * @param recordTypeId (Id): Record Type Id
     * @param isInsert (Boolean): Insert flag
     * @return Opportunity
     */
    public static Opportunity createOpportunity(Id accountId, String name, Id recordTypeId, Boolean isInsert) {
        String oppName = String.isNotBlank(name) ? name : 'TestOpp_' + COM_TestDataFactory.generateRandomString(5);
        
        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
            Opportunity.Name => oppName,
            Opportunity.AccountId => accountId,
            Opportunity.OwnerId => UserInfo.getUserId(),
            Opportunity.StageName => 'Qualification',
            Opportunity.CloseDate => BASE_END_DATE
        };
        
        // RecordType에 따라 추가 필드 설정
        if (recordTypeId != null) {
            fields.put(Opportunity.RecordTypeId, recordTypeId);
            
            // RecordType 이름 조회
            String recordTypeName = null;
            for (RecordTypeInfo rti : Schema.SObjectType.Opportunity.getRecordTypeInfos()) {
                if (rti.getRecordTypeId() == recordTypeId) {
                    recordTypeName = rti.getName();
                    break;
                }
            }
            
            // RecordType별 필수 필드 추가
            if (recordTypeName == 'Retail(Bidding)' || recordTypeName == 'Retail(Private/Renewal)') {
                fields.put(Opportunity.CRSInceptionDatedt__c, BASE_START_DATE);
            } else if (recordTypeName == 'Reinsurance') {
                fields.put(Opportunity.PeriodFrom__c, BASE_START_DATE);
                fields.put(Opportunity.PeriodTo__c, BASE_END_DATE);
            }
        }
        
        return (Opportunity) COM_TestDataFactory.createSObject('Opportunity', fields, isInsert);
    }
    
    /**
     * @description Create OPP_Layer__c
     * @param oppId (Id): Opportunity Id
     * @param isInsert (Boolean): Insert flag
     * @return OPP_Layer__c
     */
    public static OPP_Layer__c createLayer(Id oppId, Boolean isInsert) {
        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
            OPP_Layer__c.Opportunity_md__c => oppId,
            OPP_Layer__c.Type__c => 'Primary',
            OPP_Layer__c.LayerCurrency__c => 'USD',
            OPP_Layer__c.LOL__c => 100,
            OPP_Layer__c.Excess__c => 0
        };
        return (OPP_Layer__c) COM_TestDataFactory.createSObject('OPP_Layer__c', fields, isInsert);
    }

    // ── Bulk Create: OPP_Layer__c ──
    public static List<OPP_Layer__c> createLayers(Id oppId, Integer count, Boolean isInsert) {
        List<OPP_Layer__c> layers = new List<OPP_Layer__c>();
        for (Integer i = 0; i < count; i++) {
            layers.add(createLayer(oppId, false));
        }
        if (isInsert) insert layers;
        return layers;
    }


    /**
     * @description Create OPP_Panel__c
     * @param layerId (Id): Layer Id
     * @param isInsert (Boolean): Insert flag
     * @return OPP_Panel__c
     */
    public static OPP_Panel__c createPanel(Id layerId, Boolean isInsert) {
        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
            OPP_Panel__c.Layer_md__c => layerId,
            OPP_Panel__c.Currency__c => 'USD',
            OPP_Panel__c.MarketType__c => 'Facility',
            OPP_Panel__c.DPPct__c => 100
        };
        return (OPP_Panel__c) COM_TestDataFactory.createSObject('OPP_Panel__c', fields, isInsert);
    }

    public static List<OPP_Panel__c> createPanels(Id layerId, Integer count, Boolean isInsert) {
        List<OPP_Panel__c> panels = new List<OPP_Panel__c>();
        for (Integer i = 0; i < count; i++) {
            panels.add(createPanel(layerId, false));
        }
        if (isInsert) insert panels;
        return panels;
    }

    /**
     * @description Create OPP_Cobroker__c
     * @param oppId (Id): Opportunity Id
     * @param isInsert (Boolean): Insert flag
     * @return OPP_Cobroker__c
     */

    /**
   * @description Cobroker preset별 필드 매핑 (공통: SharingPct = 50)
   * 1. LK_PLACING                    — Placing  / Together / LK
   * 2. LK_PRODUCING_SEP_CLIENT       — Producing / Separate / LK / Client
   * 3. EXT_PLACING_SEP               — Placing  / Separate / External
   * 4. EXT_PRODUCING_SEP_CLIENT      — Producing / Separate / External / Client
   * 5. EXT_PRODUCING_TOGETHER        — Producing / Together
   * 6. EXT_PRODUCING_TOGETHER_CLIENT — Producing / Together / External / Client
   */
    public static final String COBROKER_LK_PLACING                    = 'LK_PLACING';
    public static final String COBROKER_LK_PRODUCING_SEP_CLIENT       = 'LK_PRODUCING_SEP_CLIENT';
//    public static final String COBROKER_LK_PRODUCING_SEP_NON_CLIENT   = 'LK_PRODUCING_SEP_NON_CLIENT';
//    public static final String COBROKER_LK_PRODUCING_TOGETHER_CLIENT  = 'LK_PRODUCING_TOGETHER_CLIENT';
    public static final String COBROKER_EXT_PLACING_SEP                   = 'EXT_PLACING_SEP';
    public static final String COBROKER_EXT_PRODUCING_SEP_CLIENT      = 'EXT_PRODUCING_SEP_CLIENT';
//    public static final String COBROKER_EXT_PRODUCING_SEP_NON_CLIENT  = 'EXT_PRODUCING_SEP_NON_CLIENT';
    public static final String COBROKER_EXT_PRODUCING_TOGETHER_CLIENT = 'EXT_PRODUCING_TOGETHER_CLIENT';
    public static final String COBROKER_EXT_PRODUCING_TOGETHER = 'EXT_PRODUCING_TOGETHER';

    /**
     * @description Create OPP_Cobroker__c with preset pattern
     * @param oppId (Id): Opportunity Id
     * @param preset (String): Cobroker preset constant (COBROKER_* )
     * @param isInsert (Boolean): Insert flag
     * @return OPP_Cobroker__c
     */
    public static OPP_Cobroker__c createCobroker(Id oppId, String preset, Boolean isInsert) {
        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
                OPP_Cobroker__c.Opportunity_md__c => oppId
        };
        fields.putAll(getCobrokerPreset(preset));
        return (OPP_Cobroker__c) COM_TestDataFactory.createSObject('OPP_Cobroker__c', fields, isInsert);
    }

    private static Map<Schema.SObjectField, Object> getCobrokerPreset(String preset) {
        Map<Schema.SObjectField, Object> m = new Map<Schema.SObjectField, Object>{
                OPP_Cobroker__c.SharingPct__c => 50
        };
        if (COBROKER_LK_PLACING.equals(preset)) {
            m.put(OPP_Cobroker__c.CobrokingType__c, 'Placing');
            m.put(OPP_Cobroker__c.SettlementType__c, 'Together');
            m.put(OPP_Cobroker__c.LKCobroking_is__c, true);
        } else if (COBROKER_LK_PRODUCING_SEP_CLIENT.equals(preset)) {
            m.put(OPP_Cobroker__c.CobrokingType__c, 'Producing');
            m.put(OPP_Cobroker__c.SettlementType__c, 'Separate');
            m.put(OPP_Cobroker__c.LKCobroking_is__c, true);
            m.put(OPP_Cobroker__c.Client__c, true);
//        } else if (COBROKER_LK_PRODUCING_SEP_NON_CLIENT.equals(preset)) {
//            m.put(OPP_Cobroker__c.CobrokingType__c, 'Producing');
//            m.put(OPP_Cobroker__c.SettlementType__c, 'Separate');
//            m.put(OPP_Cobroker__c.LKCobroking_is__c, true);
//            m.put(OPP_Cobroker__c.Client__c, false);
//        } else if (COBROKER_LK_PRODUCING_TOGETHER_CLIENT.equals(preset)) {
//            m.put(OPP_Cobroker__c.CobrokingType__c, 'Producing');
//            m.put(OPP_Cobroker__c.SettlementType__c, 'Together');
//            m.put(OPP_Cobroker__c.LKCobroking_is__c, true);
//            m.put(OPP_Cobroker__c.Client__c, true);
        } else if (COBROKER_EXT_PLACING_SEP.equals(preset)) {
            m.put(OPP_Cobroker__c.CobrokingType__c, 'Placing');
            m.put(OPP_Cobroker__c.SettlementType__c, 'Separate');
            m.put(OPP_Cobroker__c.LKCobroking_is__c, false);
        } else if (COBROKER_EXT_PRODUCING_SEP_CLIENT.equals(preset)) {
            m.put(OPP_Cobroker__c.CobrokingType__c, 'Producing');
            m.put(OPP_Cobroker__c.SettlementType__c, 'Separate');
            m.put(OPP_Cobroker__c.LKCobroking_is__c, false);
            m.put(OPP_Cobroker__c.Client__c, true);
//        } else if (COBROKER_EXT_PRODUCING_SEP_NON_CLIENT.equals(preset)) {
//            m.put(OPP_Cobroker__c.CobrokingType__c, 'Producing');
//            m.put(OPP_Cobroker__c.SettlementType__c, 'Separate');
//            m.put(OPP_Cobroker__c.LKCobroking_is__c, false);
//            m.put(OPP_Cobroker__c.Client__c, false);
        } else if (COBROKER_EXT_PRODUCING_TOGETHER.equals(preset)) {
            m.put(OPP_Cobroker__c.CobrokingType__c, 'Producing');
            m.put(OPP_Cobroker__c.SettlementType__c, 'Together');
        }
        else if (COBROKER_EXT_PRODUCING_TOGETHER_CLIENT.equals(preset)) {
            m.put(OPP_Cobroker__c.CobrokingType__c, 'Producing');
            m.put(OPP_Cobroker__c.SettlementType__c, 'Together');
            m.put(OPP_Cobroker__c.LKCobroking_is__c, false);
            m.put(OPP_Cobroker__c.Client__c, true);
        }
        return m;
    }

    // ── Create: Claim ──
    public static Claim createClaim(String name, Boolean isInsert) {
        String clmName = String.isNotBlank(name) ? name : 'TestCLM_' + COM_TestDataFactory.generateRandomString(5);
        Claim c = new Claim(Name = clmName);
        if (isInsert) insert c;
        return c;
    }

    public static OPP_PremiumSchedule__c createPremiumSchedule(Id oppId, String name, Boolean isInsert) {
        String objNm = String.isNotBlank(name) ? name : 'TestPremSche_' + COM_TestDataFactory.generateRandomString(5);
        OPP_PremiumSchedule__c c = new OPP_PremiumSchedule__c(Name = objNm, Opportunity_lk__c=oppId);
        if (isInsert) insert c;
        return c;
    }

    // ── Single Create: CLM_Allocation__c ──
    public static CLM_Allocation__c createClaimAllocation(Id claimId, Id panelId, Id reinsurerId, Boolean isInsert) {
        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
                CLM_Allocation__c.Claim_md__c => claimId,
                CLM_Allocation__c.Panel_lk__c => panelId,
                CLM_Allocation__c.Reinsurer_lk__c => reinsurerId,
                CLM_Allocation__c.ClaimDocType__c => 'SOC',
                CLM_Allocation__c.LossAmt__c => 1000,
                CLM_Allocation__c.ExpAmt__c => 500,
                CLM_Allocation__c.SignedLine__c => 10,
                CLM_Allocation__c.TotalAmtForRI__c => 150,
                CLM_Allocation__c.SettlementCurrency__c => 'USD'
        };
        return (CLM_Allocation__c) COM_TestDataFactory.createSObject('CLM_Allocation__c', fields, isInsert);
    }

    // ── Bulk Create: CLM_Allocation__c ──
    public static List<CLM_Allocation__c> createClaimAllocations(Id claimId, List<Id> panelIds, Id reinsurerId, Boolean isInsert) {
        List<CLM_Allocation__c> objs = new List<CLM_Allocation__c>();
        for (Integer i = 0; i < panelIds.size(); i++) {
            objs.add(createClaimAllocation(claimId, panelIds[i], reinsurerId, false));
        }
        if (isInsert) insert objs;
        return objs;
    }

    // ── Create: Placement__c ──
    public static Placement__c createPlacement(Id oppId, Boolean isInsert) {
        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
                Placement__c.Opportunity_lk__c => oppId,
                Placement__c.OwnerId => UserInfo.getUserId()
        };
        return (Placement__c) COM_TestDataFactory.createSObject('Placement__c', fields, isInsert);
    }

    // ── Create: PlacementLineItem__c ──
    public static PlacementLineItem__c createPlacementLineItem(Id placementId, Boolean isInsert) {
        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
                PlacementLineItem__c.RefPlacement__c => placementId,
                PlacementLineItem__c.Currency__c => 'USD'
        };
        return (PlacementLineItem__c) COM_TestDataFactory.createSObject('PlacementLineItem__c', fields, isInsert);
    }

    // ── Create: Placement__c ──
    public static OPP_SlipInfo__c createSlipInfo(Id oppId, Boolean isInsert) {
        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
                OPP_SlipInfo__c.Opportunity_lk__c => oppId,
                OPP_SlipInfo__c.OwnerId => UserInfo.getUserId()
        };
        return (OPP_SlipInfo__c) COM_TestDataFactory.createSObject('OPP_SlipInfo__c', fields, isInsert);
    }

    public static COM_Facility__c createFacility(Boolean isInsert) {
        String name = 'FA_' + COM_TestDataFactory.generateRandomString(5);
        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
                COM_Facility__c.Name => 'FA_' + COM_TestDataFactory.generateRandomString(5),
                COM_Facility__c.PeriodFromDate__c => BASE_START_DATE,
                COM_Facility__c.PeriodToDate__c => BASE_END_DATE,
                COM_Facility__c.UY__c => BASE_START_DATE.year().toString(),
                COM_Facility__c.Status__c => 'Active'
        };
        return (COM_Facility__c) COM_TestDataFactory.createSObject('COM_Facility__c', fields, isInsert);
    }



}