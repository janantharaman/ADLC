/**
 * REC_SettlementLineItemSelector — Selector for SettlementLineItem__c.
 */
public inherited sharing class REC_SettlementLineItemSelector extends REC_SelectorBase {
    // ── Singleton ────────────────────────────────────────────────────────
    private static final REC_SettlementLineItemSelector INSTANCE = new REC_SettlementLineItemSelector();
    public static REC_SettlementLineItemSelector getInstance() {
        return INSTANCE;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Abstract Overrides
    // ═════════════════════════════════════════════════════════════════════════

    public override Schema.SObjectType getSObjectType() {
        return SettlementLineItem__c.SObjectType;
    }

    public override List<Schema.SObjectField> getDefaultFields() {
        List<Schema.SObjectField> fields = new List<Schema.SObjectField>();

        // ── Identity ───────────────────────────────────────────────────────
        fields.add(SettlementLineItem__c.Id);
        fields.add(SettlementLineItem__c.Name);

        // ── SLI Details ────────────────────────────────────────────────────
        fields.add(SettlementLineItem__c.ClosingType__c);
        fields.add(SettlementLineItem__c.COA_lk__c);
        fields.add(SettlementLineItem__c.COAName_fm__c);
        fields.add(SettlementLineItem__c.AccountName__c);
        fields.add(SettlementLineItem__c.OriginCurrency__c);
        fields.add(SettlementLineItem__c.OriginAmount__c);

        // ── Settlement Details ─────────────────────────────────────────────
        fields.add(SettlementLineItem__c.Status__c);
        fields.add(SettlementLineItem__c.SettlementStatus__c);
        fields.add(SettlementLineItem__c.SettlementCurrency__c);
        fields.add(SettlementLineItem__c.SettlementDate__c);
        fields.add(SettlementLineItem__c.FXRateOrigintoSettlement__c);
        fields.add(SettlementLineItem__c.SettlementAmountSLI__c);
        fields.add(SettlementLineItem__c.OtherCharges__c);
        fields.add(SettlementLineItem__c.SettlementAmountTTL__c);
        fields.add(SettlementLineItem__c.SettlementAmountPremium__c);
        fields.add(SettlementLineItem__c.SettlementType__c);
        fields.add(SettlementLineItem__c.RemittanceOnHold__c);
        fields.add(SettlementLineItem__c.HoldReason__c);
        fields.add(SettlementLineItem__c.SettlementDateCounterparty__c);

        // ── PPW Date ───────────────────────────────────────────────────────
        fields.add(SettlementLineItem__c.PPWType_fm__c);
        fields.add(SettlementLineItem__c.InstallmentNo__c);
        fields.add(SettlementLineItem__c.PPWDate_fm__c);
        fields.add(SettlementLineItem__c.PPWDate__c);

        // ── Placement ──────────────────────────────────────────────────────
        fields.add(SettlementLineItem__c.LKRefNoPolicy_fm__c);
        fields.add(SettlementLineItem__c.LKRefNoReins_fm__c);
        fields.add(SettlementLineItem__c.RefReinsurance__c);
        fields.add(SettlementLineItem__c.CedantRefNo__c);
        fields.add(SettlementLineItem__c.CedantFacilityName__c);
        fields.add(SettlementLineItem__c.Insured__c);
        fields.add(SettlementLineItem__c.Insured_fm__c);
        fields.add(SettlementLineItem__c.InceptionDate__c);
        fields.add(SettlementLineItem__c.ExpirationDate__c);
        fields.add(SettlementLineItem__c.LOB3__c);

        // ── Market Line ────────────────────────────────────────────────────
        fields.add(SettlementLineItem__c.Layer__c);
        fields.add(SettlementLineItem__c.Reinsurer__c);
        fields.add(SettlementLineItem__c.MarketFacilityName__c);
        fields.add(SettlementLineItem__c.CoBrokingType__c);

        // ── Claim ──────────────────────────────────────────────────────────
        fields.add(SettlementLineItem__c.ParentClaimNo__c);
        fields.add(SettlementLineItem__c.CedantClaimNo__c);
        fields.add(SettlementLineItem__c.DateOfLoss__c);
        fields.add(SettlementLineItem__c.LocationOfLoss__c);
        fields.add(SettlementLineItem__c.SOCSeq__c);
        fields.add(SettlementLineItem__c.RefClaim__c);

        // ── Facility BDX ───────────────────────────────────────────────────
        fields.add(SettlementLineItem__c.FacilityName__c);
        fields.add(SettlementLineItem__c.Facility_UY__c);
        fields.add(SettlementLineItem__c.FacilityBDX_lk__c);
        fields.add(SettlementLineItem__c.FacilityBDXPeriodFrom__c);
        fields.add(SettlementLineItem__c.FacilityBDXPeriodTo__c);

        // ── FX Details ─────────────────────────────────────────────────────
        fields.add(SettlementLineItem__c.ExchangeDate__c);
        fields.add(SettlementLineItem__c.ExchangeCurrency__c);
        fields.add(SettlementLineItem__c.ExchangeAmount__c);
        fields.add(SettlementLineItem__c.ExchangeRate__c);

        // ── Other ──────────────────────────────────────────────────────────
        fields.add(SettlementLineItem__c.BizRegion__c);
        fields.add(SettlementLineItem__c.SplitKey__c);
        fields.add(SettlementLineItem__c.PremiumNoteNo_fm__c);
        fields.add(SettlementLineItem__c.Transaction_Type__c);
        fields.add(SettlementLineItem__c.FXAmountPremiumLocal__c);
        fields.add(SettlementLineItem__c.BrokerageRatePct_fm__c);
        fields.add(SettlementLineItem__c.AMTPremium_fm__c);
        fields.add(SettlementLineItem__c.AMTSales__c);
        fields.add(SettlementLineItem__c.Remark__c);
        fields.add(SettlementLineItem__c.AccountingCurrency_fm__c);

        // ── Refs & Accounting ──────────────────────────────────────────────
        fields.add(SettlementLineItem__c.RefSettlement__c);
        fields.add(SettlementLineItem__c.AccountingDate__c);
        fields.add(SettlementLineItem__c.RefReinsuranceDetail__c);
        fields.add(SettlementLineItem__c.RefClaimAllocation__c);

        // ── Evaluation ──────────────────────────────────────────────
        fields.add(SettlementLineItem__c.AMTSettled__c);
        fields.add(SettlementLineItem__c.EvaluationDate__c);
        fields.add(SettlementLineItem__c.AccountingFXRate__c);
        fields.add(SettlementLineItem__c.EvaluationFXRate__c);
        fields.add(SettlementLineItem__c.AmtAPAR__c);
        fields.add(SettlementLineItem__c.UnrealizedFXGainLoss__c);

        return fields;
    }

    /**
     * Evaluation-specific query.
     */
    public List<SettlementLineItem__c> queryByFilterForEvaluation(String filtersJson, String columnFieldsJson) {
        String periodCloseIdStr;
        Date periodCloseEndDate;

        if (String.isNotBlank(filtersJson)) {
            Map<String, Object> filterMap = (Map<String, Object>) JSON.deserializeUntyped(filtersJson);
            if (filterMap.containsKey('PeriodClose__c')) {
                Object pcVal = filterMap.remove('PeriodClose__c');
                if (pcVal instanceof String) {
                    periodCloseIdStr = (String) pcVal;
                } else if (pcVal instanceof List<Object>) {
                    List<Object> pcListObj = (List<Object>) pcVal;
                    if (!pcListObj.isEmpty()) {
                        periodCloseIdStr = String.valueOf(pcListObj[0]);
                    }
                }

                filtersJson = JSON.serialize(filterMap);
            }
        }

        REC_FilterBuilder fb = new REC_FilterBuilder(filtersJson, getSObjectType());

        if (String.isNotBlank(periodCloseIdStr)) {
            List<PeriodClose__c> pcList = [SELECT EndDate__c FROM PeriodClose__c WHERE Id = :periodCloseIdStr LIMIT 1];
            if (!pcList.isEmpty()) {
                periodCloseEndDate = pcList[0].EndDate__c;
                fb.addBind('pcEndDate', periodCloseEndDate);
            }
        }

        Set<String> relFields = fb.getRelationshipFields();
        if (String.isNotBlank(columnFieldsJson)) {
            List<String> uiFields = (List<String>) JSON.deserialize(columnFieldsJson, List<String>.class);
            Set<String> defaultFieldNames = new Set<String>();
            for (String fn : getFieldNames()) {
                defaultFieldNames.add(fn.toLowerCase());
            }
            for (String field : uiFields) {
                if (field.contains('.')) {
                    relFields.add(field);
                }
            }
        }

        String fieldsCsv = getFieldCsv();
        if (!relFields.isEmpty()) {
            fieldsCsv += ', ' + String.join(new List<String>(relFields), ', ');
        }

        String baseWhere = fb.toWhereClause();
        String evalConditions = 'ClosingType__c NOT IN (\'P_A\', \'P_B\', \'P_C\')';
        if (periodCloseEndDate != null) {
            evalConditions += ' AND (SettlementDate__c = NULL OR SettlementDate__c > :pcEndDate) AND AccountingDate__c != null AND AccountingDate__c <= :pcEndDate';
        }

        String whereClause = String.isNotBlank(baseWhere) && baseWhere != 'Id != null'
            ? '(' + baseWhere + ') AND ' + evalConditions
            : evalConditions;

        String soql = String.format(
            'SELECT {0} FROM {1} WHERE {2} ORDER BY {3} LIMIT {4}',
            new List<String>{
                fieldsCsv,
                getSObjectType().getDescribe().getName(),
                whereClause,
                getDefaultOrderBy(),
                String.valueOf(getDefaultLimit())
            }
        );

        System.debug('queryByFilterForEvaluation ::: ' + soql);

        return (List<SettlementLineItem__c>) Database.queryWithBinds(soql, fb.getBinds(), AccessLevel.USER_MODE);
    }

    public override List<Schema.SObjectField> getUpdatableFields() {
        return new List<Schema.SObjectField>{
            SettlementLineItem__c.OtherCharges__c,
            SettlementLineItem__c.RemittanceOnHold__c,
            SettlementLineItem__c.HoldReason__c,
            SettlementLineItem__c.ExchangeDate__c,
            SettlementLineItem__c.ExchangeCurrency__c,
            SettlementLineItem__c.ExchangeAmount__c,
            SettlementLineItem__c.ExchangeRate__c
        };
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Queries
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Returns all SLI field API names that are safe to clone (isCreateable = true).
     */
    public List<String> getCloneableFieldNames() {
        List<String> names = new List<String>{ 'Id' };

        for (Schema.SObjectField f : Schema.SObjectType.SettlementLineItem__c.fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = f.getDescribe();
            if (dfr.isCreateable()) {
                names.add(dfr.getName());
            }
        }

        return names;
    }

    public override List<Schema.SObjectField> getCompactFields() {
        return new List<Schema.SObjectField>{
            SettlementLineItem__c.Id,
            SettlementLineItem__c.Name,
            SettlementLineItem__c.SplitKey__c,
            SettlementLineItem__c.ClosingType__c,
            SettlementLineItem__c.SettlementStatus__c,
            SettlementLineItem__c.RefSettlement__c
        };
    }

    /**
     * Returns compact-field SLIs for the given Ids.
     */
    public Map<Id, SettlementLineItem__c> queryCompactByIds(Set<Id> recordIds) {
        return new Map<Id, SettlementLineItem__c>(
            (List<SettlementLineItem__c>) Database.queryWithBinds(
                'SELECT ' + getCompactFieldCsv() + ' FROM SettlementLineItem__c WHERE Id IN :recordIds',
                new Map<String, Object>{ 'recordIds' => recordIds },
                AccessLevel.USER_MODE
            )
        );
    }

    /**
     * Returns Other Charges SLIs linked to a Reconciliation.
     * Criteria: OriginReconciliationNo__c = reconId AND ClosingType__c = 'P_C'
     */
    public List<SettlementLineItem__c> queryOtherChargesByRecon(Id reconciliationId) {
        return [
            SELECT
                Id,
                Name,
                COA_lk__c,
                COAName_fm__c,
                ClosingType__c,
                OriginCurrency__c,
                OriginAmount__c,
                OriginReconciliationNo__c,
                OriginSettlementLineItem__c,
                OriginBankTransaction__c,
                Remark__c
            FROM SettlementLineItem__c
            WHERE OriginReconciliationNo__c = :reconciliationId AND ClosingType__c = 'P_C'
            WITH USER_MODE
            ORDER BY Name DESC
            LIMIT 2000
        ];
    }

    /**
     * Loads target SLIs for counterpart resolution (lightweight field set).
     */
    public Map<Id, SettlementLineItem__c> queryTargetsForCounterpart(List<Id> recordIds) {
        return queryCompactByIds(new Set<Id>(recordIds));
    }

    /**
     * Returns SLIs linked to a Reconciliation that are eligible for offset reversal.
     *
     * @param reconId
     * @return        `List<SettlementLineItem__c>`
     */
    public List<SettlementLineItem__c> queryOffsetSlisByReconId(String reconId) {
        String query = '';
        query += 'SELECT {0} FROM SettlementLineItem__c ';
        query += 'WHERE ReconcileNo__c = :reconciliationId ';
        query += 'ORDER BY Name DESC ';
        query += 'LIMIT 5000';

        return (List<SettlementLineItem__c>) Database.queryWithBinds(
            String.format(query, new List<String>{ getFieldCsv() }),
            new Map<String, Object>{ 'reconciliationId' => reconId },
            AccessLevel.USER_MODE
        );
    }
}