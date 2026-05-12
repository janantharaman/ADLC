/**
 * REC_SettlementLineItemDomain — Business logic for SettlementLineItem__c.
 */
public inherited sharing class REC_SettlementLineItemDomain {
    // ═════════════════════════════════════════════════════════════════════════
    //  Validation
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Server-side validation before DML.
     */
    public static List<REC_TableHelper.CellError> validate(List<SettlementLineItem__c> records) {
        List<REC_TableHelper.CellError> errors = new List<REC_TableHelper.CellError>();

        for (SettlementLineItem__c rec : records) {
            // ── Add business rules below ──────────────────────────────

            String stError = getSettlementTypeError(rec.SettlementType__c, rec);
            if (stError != null) {
                errors.add(new REC_TableHelper.CellError(rec.Id, 'SettlementType__c', stError));
            }
        }

        return errors;
    }

    /**
     * Business rule: only Line Items with (positive Origin Amount and Not-Available status) or (negative Origin Amount and Available status) can be marked as Normal.
     *
     * @param sli
     * @return    `Boolean`
     */
    public static Boolean isNormalTypeSelectable(SettlementLineItem__c sli) {
        Boolean conditionA =
            (sli.OriginAmount__c ?? 0) > 0 &&
            sli.SettlementStatus__c == REC_Consts.SettlementStatus.NOT_AVAILABLE;

        Boolean conditionB =
            (sli.OriginAmount__c ?? 0) < 0 &&
            sli.SettlementStatus__c == REC_Consts.SettlementStatus.AVAILABLE;

        return conditionA || conditionB;
    }

    /**
     * Business rule: only Line Items with negative Origin Amount and Not-Available status can be marked as Funded.
     *
     * @param sli
     * @return    `Boolean`
     */
    public static Boolean isFundedTypeSelectable(SettlementLineItem__c sli) {
        return (sli.OriginAmount__c ?? 0) < 0 && sli.SettlementStatus__c == REC_Consts.SettlementStatus.NOT_AVAILABLE;
    }

    /**
     * Case 1 OR Case 2: determines whether the counterpart should receive the main
     * field updates (OtherCharges, SettlementStatus, SettlementType, etc.).
     *
     * Case 1: (Normal OR Off-set) AND OriginAmount > 0 AND CounterSLI.SettlementStatus = Not-Available
     * Case 2: Off-set AND OriginAmount < 0 AND CounterSLI.SettlementStatus = Not-Available
     */
    public static Boolean isCounterpartCase1Or2(
        String originSettlementType,
        Decimal originAmount,
        SettlementLineItem__c counterSli
    ) {
        Boolean counterNotAvailable = counterSli.SettlementStatus__c == REC_Consts.SettlementStatus.NOT_AVAILABLE;
        if (!counterNotAvailable) {
            return false;
        }

        Decimal amt = originAmount != null ? originAmount : 0;

        // Case 1: (Normal OR Off-set) AND OriginAmount > 0
        Boolean case1 =
            (originSettlementType == REC_Consts.SettlementType.NORMAL ||
            originSettlementType == REC_Consts.SettlementType.OFFSET) && amt > 0;

        // Case 2: Off-set AND OriginAmount < 0
        Boolean case2 = originSettlementType == REC_Consts.SettlementType.OFFSET && amt < 0;

        return case1 || case2;
    }

    /**
     * Case 4: determines whether the counterpart's DueDate should be recalculated.
     * Used in conjunction with Case 1/2: (Case1 OR Case2) AND Case4.
     *
     * Conditions: OriginAmount > 0, Status = Confirm, SettlementStatus = Clear,
     * CounterSLI.ClosingType ≠ P_B, CounterSLI.ClosingType ≠ P_C.
     */
    public static Boolean isDueDateUpdatable(SettlementLineItem__c originSli, SettlementLineItem__c counterSli) {
        return (originSli.OriginAmount__c > 0) &&
            (originSli.Status__c == REC_Consts.STCStatus.CONFIRM) &&
            (originSli.SettlementStatus__c == REC_Consts.SettlementStatus.CLEAR) &&
            (counterSli.ClosingType__c != REC_Consts.ClosingType.P_C) &&
            (counterSli.ClosingType__c != REC_Consts.ClosingType.P_B);
    }

    /**
     * Validates SettlementType__c for each detail RLI based on the referenced SLI's
     * OriginAmount__c and SettlementStatus__c.
     *
     * Returns CellError list with rowId = RefSettlementLineItem__c (SLI Id).
     */
    public static List<REC_TableHelper.CellError> validateSettlementType(
        Map<Id, ReconciliationLineItem__c> newSliRefs,
        Map<Id, SettlementLineItem__c> refSLIs
    ) {
        List<REC_TableHelper.CellError> errors = new List<REC_TableHelper.CellError>();

        for (Id sliId : newSliRefs.keySet()) {
            ReconciliationLineItem__c detail = newSliRefs.get(sliId);
            SettlementLineItem__c refSLI = refSLIs.get(sliId);
            if (refSLI == null || String.isBlank(detail.SettlementType__c)) {
                continue;
            }

            String stError = getSettlementTypeError(detail.SettlementType__c, refSLI);
            if (stError != null) {
                errors.add(new REC_TableHelper.CellError(String.valueOf(sliId), 'SettlementType__c', stError));
            }
        }

        return errors;
    }

    /**
     * Core SettlementType validation. Returns error message or null.
     */
    private static String getSettlementTypeError(String settlementType, SettlementLineItem__c sli) {
        if (String.isBlank(settlementType)) {
            return null;
        }

        if (settlementType == REC_Consts.SettlementType.NORMAL && !isNormalTypeSelectable(sli)) {
            return Label.REC_MSG_SLITYPE_INVALID_NORMAL;
        }

        if (settlementType == REC_Consts.SettlementType.FUNDED && !isFundedTypeSelectable(sli)) {
            return Label.REC_MSG_SLITYPE_INVALID_FUNDED;
        }

        return null;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Split
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Clones a SettlementLineItem, linking original and clone via SplitKey.
     */
    public static List<SettlementLineItem__c> split(Id recordId, Decimal amount1, Decimal amount2) {
        REC_SettlementLineItemSelector sel = REC_SettlementLineItemSelector.getInstance();
        String fields = 'Name, ' + String.join(sel.getCloneableFieldNames(), ', ');

        // ── 1. Load target ────────────────────────────────────────────────
        List<SettlementLineItem__c> rows = (List<SettlementLineItem__c>) Database.queryWithBinds(
            'SELECT ' + fields + ' FROM SettlementLineItem__c WHERE Id = :recordId LIMIT 1',
            new Map<String, Object>{ 'recordId' => recordId },
            AccessLevel.SYSTEM_MODE
        );

        if (rows.isEmpty()) {
            throw new REC_SettlementLineItemDomainException(Label.REC_MSG_SLI_NOT_FOUND + ' ' + recordId);
        }

        SettlementLineItem__c target = rows[0];
        Boolean hasSplitKey = String.isNotBlank(target.SplitKey__c);

        // ── 2. Load counterpart ───────────────────────────────────────────
        // Split records match by SplitKey; unsplit records match by NULL SplitKey + non-P_C ClosingType
        String counterpartWhere = hasSplitKey
            ? 'AND SplitKey__c = :splitKey'
            : 'AND SplitKey__c = NULL AND ClosingType__c != :closingType';

        List<SettlementLineItem__c> counterparts = (List<SettlementLineItem__c>) Database.queryWithBinds(
            'SELECT ' +
                fields +
                ' FROM SettlementLineItem__c ' +
                'WHERE RefSettlement__c = :refSettlementId ' +
                'AND Id != :targetId ' +
                counterpartWhere,
            new Map<String, Object>{
                'refSettlementId' => target.RefSettlement__c,
                'targetId' => target.Id,
                'splitKey' => target.SplitKey__c, // used when hasSplitKey = true
                'closingType' => REC_Consts.ClosingType.P_C // used when hasSplitKey = false
            },
            AccessLevel.SYSTEM_MODE
        );

        if (counterparts.isEmpty()) {
            throw new REC_SettlementLineItemDomainException(
                hasSplitKey
                    ? 'Cannot split: no counterpart found with SplitKey "' + target.SplitKey__c + '".'
                    : 'Cannot split: no eligible counterpart found (SplitKey is blank and not of type P_C).'
            );
        }

        // ── 3. Assign split keys and amounts ──────────────────────────────
        String splitKeyA = target.Name + 'A';
        String splitKeyB = target.Name + 'B';

        SettlementLineItem__c counterpart = counterparts[0];
        SettlementLineItem__c targetClone = target.clone(false, true, false, false);
        SettlementLineItem__c counterpartClone = counterpart.clone(false, true, false, false);

        target.SplitKey__c = splitKeyA;
        target.OriginAmount__c = amount1;

        targetClone.SplitKey__c = splitKeyB;
        targetClone.OriginAmount__c = amount2;

        counterpart.SplitKey__c = splitKeyA;
        counterpart.OriginAmount__c = -1 * amount1;

        counterpartClone.SplitKey__c = splitKeyB;
        counterpartClone.OriginAmount__c = -1 * amount2;

        // ── 4. Persist ───────────────────────────────────────────────────
        List<SettlementLineItem__c> toUpsert = new List<SettlementLineItem__c>{
            target,
            targetClone,
            counterpart,
            counterpartClone
        };
        upsert toUpsert;

        return toUpsert;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Counterpart Search
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * For each given SLI record, finds its single counterpart within the same Settlement.
     *
     * Rule A (SplitKey set)   : same Settlement + same SplitKey + different Id
     * Rule B (SplitKey blank) : same Settlement + SplitKey blank + ClosingType != 'P_C' + different Id
     *
     * P_C records have no counterpart by definition.
     */
    public static Map<Id, SettlementLineItem__c> searchCounterparts(List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, SettlementLineItem__c>();
        }

        REC_SettlementLineItemSelector sel = REC_SettlementLineItemSelector.getInstance();
        Map<Id, SettlementLineItem__c> targetMap = sel.queryTargetsForCounterpart(recordIds);
        Set<Id> settlementIds = collectSettlementIds(targetMap);

        if (settlementIds.isEmpty()) {
            return new Map<Id, SettlementLineItem__c>();
        }

        Map<Id, List<SettlementLineItem__c>> candidatesBySettlement = loadCandidates(settlementIds, recordIds);
        return resolveCounterparts(targetMap, candidatesBySettlement);
    }

    // ── Counterpart helpers ───────────────────────────────────────────────

    private static Set<Id> collectSettlementIds(Map<Id, SettlementLineItem__c> targetMap) {
        Set<Id> ids = new Set<Id>();
        for (SettlementLineItem__c t : targetMap.values()) {
            if (t.RefSettlement__c != null) {
                ids.add(t.RefSettlement__c);
            }
        }
        return ids;
    }

    private static Map<Id, List<SettlementLineItem__c>> loadCandidates(Set<Id> settlementIds, List<Id> excludeIds) {
        REC_SettlementLineItemSelector sel = REC_SettlementLineItemSelector.getInstance();
        String compactCsv = sel.getCompactFieldCsv();

        String soql =
            'SELECT Id, (SELECT ' +
            compactCsv +
            ' FROM SettlementLineItems_RefSettlement__r WHERE Id NOT IN :excludeIds)' +
            ' FROM Settlement__c WHERE Id IN :settlementIds';

        Map<Id, List<SettlementLineItem__c>> bySettlement = new Map<Id, List<SettlementLineItem__c>>();

        for (
            Settlement__c s : (List<Settlement__c>) Database.queryWithBinds(
                soql,
                new Map<String, Object>{ 'excludeIds' => excludeIds, 'settlementIds' => settlementIds },
                AccessLevel.SYSTEM_MODE
            )
        ) {
            bySettlement.put(s.Id, s.SettlementLineItems_RefSettlement__r ?? new List<SettlementLineItem__c>());
        }

        return bySettlement;
    }

    private static Map<Id, SettlementLineItem__c> resolveCounterparts(
        Map<Id, SettlementLineItem__c> targetMap,
        Map<Id, List<SettlementLineItem__c>> candidatesBySettlement
    ) {
        Map<Id, SettlementLineItem__c> result = new Map<Id, SettlementLineItem__c>();

        for (SettlementLineItem__c target : targetMap.values()) {
            if (target.ClosingType__c == REC_Consts.ClosingType.P_C) {
                continue;
            }

            List<SettlementLineItem__c> pool = candidatesBySettlement.get(target.RefSettlement__c) ??
                new List<SettlementLineItem__c>();

            SettlementLineItem__c counterpart = matchCounterpart(target, pool);

            if (counterpart == null) {
                throw new REC_SettlementLineItemDomainException(
                    String.format(
                        'No counterpart found for "{0}". A non-P_C Settlement Line Item must have exactly one counterpart.',
                        new List<Object>{ target.Name }
                    )
                );
            }

            result.put(target.Id, counterpart);
        }

        return result;
    }

    @TestVisible
    private static SettlementLineItem__c matchCounterpart(SettlementLineItem__c target, List<SettlementLineItem__c> pool) {
        Boolean hasSplitKey = String.isNotBlank(target.SplitKey__c);
        SettlementLineItem__c matched = null;

        for (SettlementLineItem__c c : pool) {
            Boolean isMatch = hasSplitKey
                ? target.SplitKey__c == c.SplitKey__c
                : String.isBlank(c.SplitKey__c) && c.ClosingType__c != REC_Consts.ClosingType.P_C;

            if (!isMatch)
                continue;

            if (matched != null) {
                throw new REC_SettlementLineItemDomainException(
                    String.format(
                        'Multiple counterparts found for "{0}". Expected at most 1.',
                        new List<Object>{ target.Name }
                    )
                );
            }
            matched = c;
        }

        return matched;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Settlement Calculation Helpers
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * SettlementAmountSLI (detail) = OriginAmount × FXRate
     */
    public static Decimal calculateSettlementAmountSLI(Decimal originAmount, Decimal fxRate) {
        Decimal oa = originAmount != null ? originAmount : 0;
        Decimal fx = fxRate != null ? fxRate : 0;
        return oa * fx;
    }

    /**
     * SettlementAmountSLI (detail) = round(OriginAmount × FXRate, currency)
     */
    public static Decimal calculateSettlementAmountSLI(Decimal originAmount, Decimal fxRate, String settlementCurrency) {
        return REC_Utils.CCY.round(calculateSettlementAmountSLI(originAmount, fxRate), settlementCurrency);
    }

    /**
     * SettlementAmountSLI (base) = Σ ReconciledAmt + OtherCharges + Σ P_C OtherCharges
     */
    public static Decimal calculateSettlementAmountSLI(
        Decimal sumReconciledAmt,
        Decimal otherCharges,
        Decimal sumOtherChargesPC
    ) {
        Decimal sr = sumReconciledAmt != null ? sumReconciledAmt : 0;
        Decimal oc = otherCharges != null ? otherCharges : 0;
        Decimal pc = sumOtherChargesPC != null ? sumOtherChargesPC : 0;
        return sr + oc + pc;
    }

    /**
     * SettlementAmountTTL = a + b
     * Detail: SettlementAmountSLI + OtherCharges
     * Base:   Σ ReconciledAmt + Σ P_C OtherCharges
     */
    public static Decimal calculateSettlementAmountTTL(Decimal a, Decimal b) {
        Decimal va = a != null ? a : 0;
        Decimal vb = b != null ? b : 0;
        return va + vb;
    }

    /**
     * SettlementAmountTTL = round(a + b, currency)
     */
    public static Decimal calculateSettlementAmountTTL(Decimal a, Decimal b, String settlementCurrency) {
        return REC_Utils.CCY.round(calculateSettlementAmountTTL(a, b), settlementCurrency);
    }

    /**
     * SettlementAmountTTL (detail) = SettlementAmountSLI − OtherCharges
     */
    public static Decimal calculateDetailTTL(Decimal settlementAmountSLI, Decimal otherCharges) {
        Decimal sli = settlementAmountSLI != null ? settlementAmountSLI : 0;
        Decimal oc = otherCharges != null ? otherCharges : 0;
        return sli - oc;
    }

    /**
     * SettlementAmountTTL (detail) = round(SettlementAmountSLI − OtherCharges, currency)
     */
    public static Decimal calculateDetailTTL(Decimal settlementAmountSLI, Decimal otherCharges, String settlementCurrency) {
        return REC_Utils.CCY.round(calculateDetailTTL(settlementAmountSLI, otherCharges), settlementCurrency);
    }

    /**
     * FXRateOrigintoSettlement:
     *   - same currency → 1
     *   - different currency → settlementAmountSLI / originAmount
     *   - no originAmount   → null
     */
    public static Decimal calculateFXRate(
        String settlementCurrency,
        String originCurrency,
        Decimal settlementAmountSLI,
        Decimal originAmount
    ) {
        if (settlementCurrency != null && settlementCurrency == originCurrency) {
            return 1;
        } else if (originAmount != null && originAmount != 0) {
            return settlementAmountSLI / originAmount;
        }
        return null;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Funded P_C Creation (Trigger Handler)
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Funded P_C Creation — invoked from SettlementLineItem afterUpdate trigger.
     *
     * Condition 1: SettlementStatus changed to Clear AND SettlementType changed to Funded
     *   → Creates P_C with SettlementStatus = Not-Available
     *
     * Condition 2: SettlementStatus changed to Clear AND counterpart has
     *              (SettlementStatus = Clear AND SettlementType = Funded)
     *   → Creates P_C with SettlementStatus = Available
     *
     * Constraint: No queries executed when no records qualify.
     */
    public static void processFundedPcCreation(
        List<SettlementLineItem__c> triggerNew,
        Map<Id, SettlementLineItem__c> triggerOldMap
    ) {
        // ── 1. Classify trigger records (no queries) ─────────────────────
        List<SettlementLineItem__c> condition1Records = new List<SettlementLineItem__c>();
        List<SettlementLineItem__c> condition2Candidates = new List<SettlementLineItem__c>();

        for (SettlementLineItem__c newSli : triggerNew) {
            // P_C records are never eligible for Funded P_C creation
            if (newSli.ClosingType__c == REC_Consts.ClosingType.P_C) {
                continue;
            }

            SettlementLineItem__c oldSli = triggerOldMap.get(newSli.Id);

            Boolean statusChangedToClear =
                newSli.SettlementStatus__c == REC_Consts.SettlementStatus.CLEAR &&
                oldSli.SettlementStatus__c != REC_Consts.SettlementStatus.CLEAR;

            if (!statusChangedToClear) {
                continue;
            }

            Boolean typeChangedToFunded =
                newSli.SettlementType__c == REC_Consts.SettlementType.FUNDED &&
                oldSli.SettlementType__c != REC_Consts.SettlementType.FUNDED;

            if (typeChangedToFunded) {
                condition1Records.add(newSli);
            } else {
                condition2Candidates.add(newSli);
            }
        }

        if (condition1Records.isEmpty() && condition2Candidates.isEmpty()) {
            return;
        }

        // ── 2. Resolve Condition 2: check counterparts ───────────────────
        List<SettlementLineItem__c> condition2Records = resolveCondition2Counterparts(condition2Candidates);

        if (condition1Records.isEmpty() && condition2Records.isEmpty()) {
            return;
        }

        // ── 3. Create P_C SLIs ───────────────────────────────────────────
        buildAndInsertFundedPcSlis(condition1Records, condition2Records);
    }

    /**
     * For condition 2 candidates, finds counterparts that are Funded + Clear.
     * Returns the candidates whose counterpart meets the condition.
     */
    private static List<SettlementLineItem__c> resolveCondition2Counterparts(List<SettlementLineItem__c> candidates) {
        List<SettlementLineItem__c> result = new List<SettlementLineItem__c>();
        if (candidates.isEmpty()) {
            return result;
        }

        Set<Id> candidateIds = new Set<Id>();
        Set<Id> settlementIds = new Set<Id>();

        for (SettlementLineItem__c sli : candidates) {
            if (sli.RefSettlement__c == null) {
                continue;
            }
            candidateIds.add(sli.Id);
            settlementIds.add(sli.RefSettlement__c);
        }

        if (settlementIds.isEmpty()) {
            return result;
        }

        // Single bulkified query: counterparts that are Funded + Clear
        String clearStatus = REC_Consts.SettlementStatus.CLEAR;
        String fundedType = REC_Consts.SettlementType.FUNDED;

        List<SettlementLineItem__c> potentials = [
            SELECT Id, Name, SplitKey__c, ClosingType__c, RefSettlement__c
            FROM SettlementLineItem__c
            WHERE
                RefSettlement__c IN :settlementIds
                AND Id NOT IN :candidateIds
                AND SettlementStatus__c = :clearStatus
                AND SettlementType__c = :fundedType
            WITH SYSTEM_MODE
        ];

        if (potentials.isEmpty()) {
            return result;
        }

        // Group potentials by Settlement
        Map<Id, List<SettlementLineItem__c>> potentialBySettlement = new Map<Id, List<SettlementLineItem__c>>();
        for (SettlementLineItem__c pc : potentials) {
            if (!potentialBySettlement.containsKey(pc.RefSettlement__c)) {
                potentialBySettlement.put(pc.RefSettlement__c, new List<SettlementLineItem__c>());
            }
            potentialBySettlement.get(pc.RefSettlement__c).add(pc);
        }

        // Match candidates to funded counterparts using existing counterpart matching rules
        for (SettlementLineItem__c candidate : candidates) {
            if (candidate.RefSettlement__c == null) {
                continue;
            }
            List<SettlementLineItem__c> pool = potentialBySettlement.get(candidate.RefSettlement__c);
            if (pool == null) {
                continue;
            }

            SettlementLineItem__c matched = matchCounterpart(candidate, pool);
            if (matched != null) {
                result.add(candidate);
            }
        }

        return result;
    }

    /**
     * Creates and inserts P_C Settlement Line Items for qualifying SLIs.
     * Condition 1 records → SettlementStatus = Not-Available
     * Condition 2 records → SettlementStatus = Available
     */
    private static void buildAndInsertFundedPcSlis(
        List<SettlementLineItem__c> condition1Records,
        List<SettlementLineItem__c> condition2Records
    ) {
        List<SettlementLineItem__c> allRecords = new List<SettlementLineItem__c>();
        allRecords.addAll(condition1Records);
        allRecords.addAll(condition2Records);

        // Collect unique BizRegions and AccountingDates for bulk queries
        Set<String> bizRegions = new Set<String>();
        Set<Date> accountingDates = new Set<Date>();

        for (SettlementLineItem__c sli : allRecords) {
            if (sli.BizRegion__c != null) {
                bizRegions.add(sli.BizRegion__c);
            }
            if (sli.AccountingDate__c != null) {
                accountingDates.add(sli.AccountingDate__c);
            }
        }

        // Resolve Account by BizRegion (cached)
        Map<String, Id> accountByRegion = REC_Utils.getAccountIdsByRegions(bizRegions);

        // Resolve COA by BizRegion (cached)
        Map<String, Id> coaIdByRegion = REC_Utils.getCoaIdsByRegions(bizRegions);

        // Query PeriodClose by AccountingDate (bulkified)
        Map<Date, Id> periodCloseByDate = queryPeriodCloseByDates(accountingDates);

        // Build condition 1 Id set for SettlementStatus determination
        Set<Id> condition1Ids = new Set<Id>();
        for (SettlementLineItem__c sli : condition1Records) {
            condition1Ids.add(sli.Id);
        }

        Date today = Date.today();
        List<SettlementLineItem__c> pcSlis = new List<SettlementLineItem__c>();

        for (SettlementLineItem__c sliOrg : allRecords) {
            String bizRegion = sliOrg.BizRegion__c;

            Id coaId = coaIdByRegion.get(bizRegion);
            Id periodCloseId = sliOrg.AccountingDate__c != null ? periodCloseByDate.get(sliOrg.AccountingDate__c) : null;

            // Condition 1 → Not-Available; Condition 2 → Available
            String pcSettlementStatus = condition1Ids.contains(sliOrg.Id)
                ? REC_Consts.SettlementStatus.NOT_AVAILABLE
                : REC_Consts.SettlementStatus.AVAILABLE;

            pcSlis.add(
                new SettlementLineItem__c(
                    OriginSettlementLineItem__c = sliOrg.Id,
                    OriginAmount__c = sliOrg.OriginAmount__c * (-1),
                    AccountingDate__c = today,
                    AccountName__c = accountByRegion.get(bizRegion),
                    COA_lk__c = coaId,
                    PeriodClose__c = periodCloseId,
                    ClosingType__c = REC_Consts.ClosingType.P_C,
                    Status__c = REC_Consts.STCStatus.CONFIRM,
                    SettlementStatus__c = pcSettlementStatus,
                    RefSettlement__c = sliOrg.RefSettlement__c,
                    OriginCurrency__c = sliOrg.OriginCurrency__c,
                    SettlementCurrency__c = sliOrg.SettlementCurrency__c,
                    RefReinsurance__c = sliOrg.RefReinsurance__c,
                    RefReinsuranceDetail__c = sliOrg.RefReinsuranceDetail__c,
                    RefClaim__c = sliOrg.RefClaim__c,
                    RefClaimAllocation__c = sliOrg.RefClaimAllocation__c,
                    BizRegion__c = sliOrg.BizRegion__c,
                    OriginalFXRateDate__c = today,
                    SendtoCloseDate__c = today,
                    AccountingFXRate__c = FX.rate(today, sliOrg.BizRegion__c, sliOrg.OriginCurrency__c)
                )
            );
        }

        if (!pcSlis.isEmpty()) {
            insert as user pcSlis;
        }
    }

    /**
     * Bulkified PeriodClose lookup by AccountingDate.
     */
    private static Map<Date, Id> queryPeriodCloseByDates(Set<Date> accountingDates) {
        Map<Date, Id> periodCloseByDate = new Map<Date, Id>();
        if (accountingDates.isEmpty()) {
            return periodCloseByDate;
        }

        Date minDate;
        Date maxDate;
        for (Date d : accountingDates) {
            if (minDate == null || d < minDate) {
                minDate = d;
            }
            if (maxDate == null || d > maxDate) {
                maxDate = d;
            }
        }

        for (PeriodClose__c pc : [
            SELECT Id, StartDate__c, EndDate__c
            FROM PeriodClose__c
            WHERE StartDate__c <= :maxDate AND EndDate__c >= :minDate
            WITH SYSTEM_MODE
        ]) {
            for (Date d : accountingDates) {
                if (d >= pc.StartDate__c && d <= pc.EndDate__c && !periodCloseByDate.containsKey(d)) {
                    periodCloseByDate.put(d, pc.Id);
                }
            }
        }

        return periodCloseByDate;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Note Status Update (Trigger Handler)
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Note Status Update — invoked from SettlementLineItem afterInsert / afterDelete / afterUndelete trigger.
     * Collects Note_lk__c from the given SLI list and recalculates NoteStatus.
     *
     * Constraint: No queries executed when no records have Note_lk__c.
     */
    public static void processNoteStatusUpdate(List<SettlementLineItem__c> triggerRecords) {
        Set<Id> noteIds = new Set<Id>();
        for (SettlementLineItem__c sli : triggerRecords) {
            if (sli.Note_lk__c != null) {
                noteIds.add(sli.Note_lk__c);
            }
        }
        updateNoteStatus(noteIds);
    }

    /**
     * Note Status Update — invoked from SettlementLineItem afterUpdate trigger.
     * Collects Note_lk__c (old and new) for SLIs whose SettlementStatus__c or Note_lk__c changed,
     * then recalculates NoteStatus.
     *
     * Constraint: No queries executed when no records qualify.
     */
    public static void processNoteStatusUpdate(
        List<SettlementLineItem__c> triggerNew,
        Map<Id, SettlementLineItem__c> triggerOldMap
    ) {
        Set<Id> noteIds = new Set<Id>();
        for (SettlementLineItem__c newSli : triggerNew) {
            SettlementLineItem__c oldSli = triggerOldMap.get(newSli.Id);

            Boolean statusChanged = newSli.SettlementStatus__c != oldSli.SettlementStatus__c;
            Boolean noteChanged = newSli.Note_lk__c != oldSli.Note_lk__c;

            if (statusChanged || noteChanged) {
                if (newSli.Note_lk__c != null) {
                    noteIds.add(newSli.Note_lk__c);
                }
                if (oldSli.Note_lk__c != null) {
                    noteIds.add(oldSli.Note_lk__c);
                }
            }
        }
        updateNoteStatus(noteIds);
    }

    /**
     * Recalculates COM_Note__c.NoteStatus__c based on the SettlementStatus__c
     * values of child SettlementLineItem__c records.
     *
     * Priority (Case 0 → 1 → 2 → 3):
     *   Case 0: Any child SLI has NULL SettlementStatus → skip (no update)
     *   Case 1: Any child SLI is Not-Available          → Non-Available
     *   Case 2: Any child SLI is Available               → Available
     *   Case 3: All child SLIs are Clear                 → Clear
     *
     * Tracks processed Note Ids per transaction to avoid redundant queries/DML.
     */
    private static Set<Id> processedNoteIds = new Set<Id>();

    private static void updateNoteStatus(Set<Id> noteIds) {
        if (noteIds == null || noteIds.isEmpty()) {
            return;
        }

        noteIds.remove(null);
        noteIds.removeAll(processedNoteIds);

        if (noteIds.isEmpty()) {
            return;
        }

        // Query all child SLIs grouped by Note
        List<SettlementLineItem__c> slis = [
            SELECT Id, Note_lk__c, SettlementStatus__c
            FROM SettlementLineItem__c
            WHERE Note_lk__c IN :noteIds
            WITH SYSTEM_MODE
        ];

        // Build status sets per Note
        Map<Id, Set<String>> statusesByNote = new Map<Id, Set<String>>();
        Map<Id, Boolean> hasNullByNote = new Map<Id, Boolean>();

        for (Id noteId : noteIds) {
            statusesByNote.put(noteId, new Set<String>());
            hasNullByNote.put(noteId, false);
        }

        for (SettlementLineItem__c sli : slis) {
            Id noteId = sli.Note_lk__c;

            if (sli.SettlementStatus__c == null) {
                hasNullByNote.put(noteId, true);
            } else {
                statusesByNote.get(noteId).add(sli.SettlementStatus__c);
            }
        }

        // Determine new NoteStatus per Note
        List<COM_Note__c> notesToUpdate = new List<COM_Note__c>();

        for (Id noteId : noteIds) {
            Set<String> statuses = statusesByNote.get(noteId);
            Boolean hasNull = hasNullByNote.get(noteId);

            // No child SLIs remain → skip
            if (statuses.isEmpty() && !hasNull) {
                continue;
            }

            // Case 0: any NULL → skip
            if (hasNull) {
                continue;
            }

            // Case 1: any Not-Available → Non-Available
            if (statuses.contains(REC_Consts.SettlementStatus.NOT_AVAILABLE)) {
                notesToUpdate.add(new COM_Note__c(Id = noteId, NoteStatus__c = REC_Consts.NoteStatus.NON_AVAILABLE));
                continue;
            }

            // Case 2: any Available → Available
            if (statuses.contains(REC_Consts.SettlementStatus.AVAILABLE)) {
                notesToUpdate.add(new COM_Note__c(Id = noteId, NoteStatus__c = REC_Consts.NoteStatus.AVAILABLE));
                continue;
            }

            // Case 3: all Clear
            if (statuses.contains(REC_Consts.SettlementStatus.CLEAR) && statuses.size() == 1) {
                notesToUpdate.add(new COM_Note__c(Id = noteId, NoteStatus__c = REC_Consts.NoteStatus.CLEAR));
            }
        }

        if (!notesToUpdate.isEmpty()) {
            update as system notesToUpdate;
        }

        processedNoteIds.addAll(noteIds);
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Exception
    // ═════════════════════════════════════════════════════════════════════════

    public class REC_SettlementLineItemDomainException extends Exception {
    }
}