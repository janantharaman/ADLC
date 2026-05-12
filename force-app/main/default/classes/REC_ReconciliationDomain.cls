/**
 * REC_ReconciliationDomain — Business logic for Reconciliation__c.
 */
public inherited sharing class REC_ReconciliationDomain {
    private static final SObjectType SETTLEMENT_LINE_ITEM_TYPE = Schema.SettlementLineItem__c.getSObjectType();
    private static final SObjectType BANK_TRANSACTION_TYPE = Schema.BankTransaction__c.getSObjectType();
    private static final SObjectType FIDUCIARY_OTHERS_TYPE = Schema.FiduciaryOthers__c.getSObjectType();

    // ═════════════════════════════════════════════════════════════════════════
    //  Create Reconciliation
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Creates a new Reconciliation__c + its first ReconciliationLineItem__c
     * linked to the given base record (SLI or BT).
     *
     * @param baseRecordId  Id of SettlementLineItem__c or BankTransaction__c
     * @return              Id of the newly created Reconciliation__c
     */
    public static Id createNewReconciliation(Id baseRecordId) {
        if (baseRecordId == null) {
            throw new REC_ReconciliationDomainException('Base Record ID cannot be null.');
        }

        Savepoint sp = Database.setSavepoint();
        try {
            ExceptionSimulator.throwIfActive();
            SObjectType objectType = baseRecordId.getSObjectType();
            Reconciliation__c newRecon = buildReconciliation(baseRecordId, objectType);

            Database.SaveResult reconSr = Database.insert(newRecon);
            if (!reconSr.isSuccess()) {
                throw new REC_ReconciliationDomainException(formatDmlErrors(reconSr));
            }

            ReconciliationLineItem__c newRli = buildLineItem(reconSr.getId(), baseRecordId, objectType);

            Database.SaveResult rliSr = Database.insert(newRli);
            if (!rliSr.isSuccess()) {
                throw new REC_ReconciliationDomainException(formatDmlErrors(rliSr));
            }

            return reconSr.getId();
        } catch (REC_ReconciliationDomainException e) {
            Database.rollback(sp);
            throw e;
        } catch (Exception e) {
            Database.rollback(sp);
            throw new REC_ReconciliationDomainException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Status Transitions
    // ═════════════════════════════════════════════════════════════════════════

    /** Sets status to 'Draft'. */
    public static void setDraft(Id reconciliationId) {
        update as system new Reconciliation__c(Id = reconciliationId, Status__c = REC_Consts.ReconciliationStatus.DRAFT);
    }

    /** Sets status to 'Confirmed'. */
    public static void confirm(Id reconciliationId, String reconciledCurrency) {
        if (String.isBlank(reconciliationId)) {
            throw new REC_ReconciliationDomainException('Reconciliation Id is required');
        }
        update as system new Reconciliation__c(
            Id = reconciliationId,
            Status__c = REC_Consts.ReconciliationStatus.CONFIRMED,
            ReconciledDate__c = Date.today(),
            ReconciledCurrency__c = reconciledCurrency,
            ConfirmedDate__c = Datetime.now(),
            ConfirmedBy__c = UserInfo.getUserId()
        );
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  SLI-Based Shared Helpers
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Container for categorised RLIs (existing and new).
     */
    @TestVisible
    private class RliContext {
        Map<Id, ReconciliationLineItem__c> existingBtRefs = new Map<Id, ReconciliationLineItem__c>();
        Map<Id, ReconciliationLineItem__c> existingFoRefs = new Map<Id, ReconciliationLineItem__c>();
        ReconciliationLineItem__c baseSliRli;
        Map<Id, ReconciliationLineItem__c> newBtRefs = new Map<Id, ReconciliationLineItem__c>();
        Map<Id, ReconciliationLineItem__c> newFoRefs = new Map<Id, ReconciliationLineItem__c>();
    }

    /**
     * Categorises existing RLIs and new detail records into an RliContext.
     */
    private static RliContext buildRliContext(
        List<ReconciliationLineItem__c> rliExisting,
        List<ReconciliationLineItem__c> details
    ) {
        RliContext ctx = new RliContext();

        for (ReconciliationLineItem__c rli : rliExisting) {
            if (rli.RefBankTransaction__c != null) {
                ctx.existingBtRefs.put(rli.RefBankTransaction__c, rli);
            } else if (rli.RefFiduciaryOthers__c != null) {
                ctx.existingFoRefs.put(rli.RefFiduciaryOthers__c, rli);
            } else if (rli.RefSettlementLineItem__c != null) {
                ctx.baseSliRli = rli;
            }
        }

        if (details != null) {
            for (ReconciliationLineItem__c detail : details) {
                if (detail.RefBankTransaction__c != null) {
                    ctx.newBtRefs.put(detail.RefBankTransaction__c, detail);
                } else if (detail.RefFiduciaryOthers__c != null) {
                    ctx.newFoRefs.put(detail.RefFiduciaryOthers__c, detail);
                }
            }
        }

        return ctx;
    }

    /**
     * Identifies and deletes RLIs that exist but are no longer in the new detail set.
     */
    private static void deleteOrphanedRlis(List<ReconciliationLineItem__c> rliExisting, Set<Id> newBtIds, Set<Id> newFoIds) {
        List<ReconciliationLineItem__c> orphans = new List<ReconciliationLineItem__c>();
        for (ReconciliationLineItem__c rli : rliExisting) {
            if (rli.RefBankTransaction__c != null && !newBtIds.contains(rli.RefBankTransaction__c)) {
                orphans.add(rli);
            }
            if (rli.RefFiduciaryOthers__c != null && !newFoIds.contains(rli.RefFiduciaryOthers__c)) {
                orphans.add(rli);
            }
        }
        if (!orphans.isEmpty()) {
            delete as system orphans;
        }
    }

    /**
     * Resolves the correct RLI Id for upsert:
     *   - detail already has a persisted Id → use it
     *   - matching existing record found     → inherit its Id (update)
     *   - otherwise                          → leave null (insert), set parent
     */
    private static ReconciliationLineItem__c resolveRliId(
        ReconciliationLineItem__c rli,
        ReconciliationLineItem__c detail,
        ReconciliationLineItem__c existing,
        String reconciliationId
    ) {
        if (detail.Id != null) {
            rli.Id = detail.Id;
        } else if (existing != null) {
            rli.Id = existing.Id;
        } else {
            rli.RefReconciliation__c = reconciliationId;
        }
        return rli;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  SLI-Based Draft
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Draft operation for SLI-based reconciliation.
     * Calculates RLI fields based on user-entered Reconciled AMT, then
     * creates / updates / deletes ReconciliationLineItems accordingly.
     *
     * @param reconciliationId    Parent Reconciliation Id
     * @param details             BT/FO-referenced RLIs with user-entered ReconciledAMT__c
     * @param otherCharges        User-entered Other Charges from the base SLI table (nullable)
     * @param otherChargeRliItems P_C Other Charges RLI rows from the table (nullable)
     * @return                    Upserted BT/FO-referenced RLIs
     */
    public static List<ReconciliationLineItem__c> draftSettlementLineItemBased(
        String reconciliationId,
        List<ReconciliationLineItem__c> details,
        Decimal otherCharges,
        List<ReconciliationLineItem__c> otherChargeRliItems
    ) {
        SavePoint sp = Database.setSavepoint();

        try {
            if (String.isBlank(reconciliationId)) {
                throw new REC_ReconciliationDomainException('Reconciliation Id is required');
            }

            REC_ReconciliationLineItemSelector rliSel = REC_ReconciliationLineItemSelector.getInstance();
            REC_BankTransactionSelector btSel = REC_BankTransactionSelector.getInstance();
            REC_FiduciaryOthersSelector foSel = REC_FiduciaryOthersSelector.getInstance();

            // ── 1. Fetch existing RLIs & build context ───────────────────────
            List<ReconciliationLineItem__c> rliExisting = rliSel.queryForDraft(reconciliationId);

            if (rliExisting.isEmpty()) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_RLI_NOT_FOUND);
            }

            RliContext ctx = buildRliContext(rliExisting, details);

            if (ctx.baseSliRli == null) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_BASE_SLI_RLI_NOT_FOUND);
            }

            // ── 2. DELETE: RLIs no longer in the new detail set ──────────────
            deleteOrphanedRlis(rliExisting, ctx.newBtRefs.keySet(), ctx.newFoRefs.keySet());

            // ── 3. Handle empty details → clear base SLI RLI ────────────────
            if (details == null || details.isEmpty()) {
                ReconciliationLineItem__c clearRli = new ReconciliationLineItem__c(Id = ctx.baseSliRli.Id);
                clearRli.SettlementCurrency__c = null;
                clearRli.SettlementDate__c = null;
                clearRli.SettlementAmountSLI__c = null;
                clearRli.SettlementAmountTTL__c = null;
                clearRli.FXRateOrigintoSettlement__c = null;
                clearRli.OtherCharges__c = null;
                update as system clearRli;
                processPcRlis(reconciliationId, otherChargeRliItems);
                setDraft(reconciliationId);
                return new List<ReconciliationLineItem__c>();
            }

            // ── 4. UPSERT: BT/FO-referenced RLIs with calculated fields ─────
            List<ReconciliationLineItem__c> rliToUpsert = new List<ReconciliationLineItem__c>();
            Decimal sumReconciledAmt = 0;
            Date latestTransactionDate;
            String settlementCurrency;

            // ── A. BT-referenced RLIs ────────────────────────────────────────
            if (!ctx.newBtRefs.isEmpty()) {
                String btFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(ctx.newBtRefs.keySet())).toJson();
                Map<Id, BankTransaction__c> refBTs = new Map<Id, BankTransaction__c>();
                for (SObject s : btSel.queryByFilter(btFilter)) {
                    BankTransaction__c bt = (BankTransaction__c) s;
                    refBTs.put(bt.Id, bt);
                }

                for (Id btId : ctx.newBtRefs.keySet()) {
                    ReconciliationLineItem__c detail = ctx.newBtRefs.get(btId);
                    BankTransaction__c refBT = refBTs.get(btId);
                    Decimal ramt = detail.ReconciledAMT__c != null ? detail.ReconciledAMT__c : 0;

                    // C. Validate detail ReconciledAMT
                    Decimal btNetBefore =
                        (refBT.OriginAmount__c != null ? refBT.OriginAmount__c : 0) -
                        (refBT.TotalClearedAmount__c != null ? refBT.TotalClearedAmount__c : 0);
                    validateSliDetailReconciledAmount(refBT.OriginAmount__c, ramt, btNetBefore);

                    // a-2. TotalClearedAmount__c
                    Decimal totalCleared = (refBT.TotalClearedAmount__c != null ? refBT.TotalClearedAmount__c : 0) + ramt;
                    // a-3. NetAmountAfterClearing__c
                    Decimal netAmount = (refBT.OriginAmount__c != null ? refBT.OriginAmount__c : 0) - totalCleared;
                    // a-4. BTStatus__c
                    String btStatus = REC_BankTransactionDomain.decideStatus(netAmount);

                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();
                    resolveRliId(rli, detail, ctx.existingBtRefs.get(btId), reconciliationId);

                    rli.RefBankTransaction__c = btId;
                    rli.BizRegion__c = refBT.BizRegion__c;
                    rli.ReconciledAMT__c = ramt;
                    rli.TotalClearedAmount__c = totalCleared;
                    rli.NetAmountAfterClearing__c = netAmount;
                    rli.BTStatus__c = btStatus;

                    rliToUpsert.add(rli);
                    sumReconciledAmt += ramt;

                    if (settlementCurrency == null) {
                        settlementCurrency = refBT.Currency__c;
                    }
                    if (
                        refBT.TransactionDate__c != null &&
                        (latestTransactionDate == null ||
                        refBT.TransactionDate__c > latestTransactionDate)
                    ) {
                        latestTransactionDate = refBT.TransactionDate__c;
                    }
                }
            }

            // ── B. FO-referenced RLIs ────────────────────────────────────────
            if (!ctx.newFoRefs.isEmpty()) {
                String foFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(ctx.newFoRefs.keySet())).toJson();
                Map<Id, FiduciaryOthers__c> refFOs = new Map<Id, FiduciaryOthers__c>();
                for (SObject s : foSel.queryByFilter(foFilter)) {
                    FiduciaryOthers__c fo = (FiduciaryOthers__c) s;
                    refFOs.put(fo.Id, fo);
                }

                for (Id foId : ctx.newFoRefs.keySet()) {
                    ReconciliationLineItem__c detail = ctx.newFoRefs.get(foId);
                    FiduciaryOthers__c refFO = refFOs.get(foId);
                    Decimal ramt = detail.ReconciledAMT__c != null ? detail.ReconciledAMT__c : 0;

                    // C. Validate detail ReconciledAMT
                    Decimal foNetBefore =
                        (refFO.OriginAmount__c != null ? refFO.OriginAmount__c : 0) -
                        (refFO.ReconciledAMT__c != null ? refFO.ReconciledAMT__c : 0);
                    validateSliDetailReconciledAmount(refFO.OriginAmount__c, ramt, foNetBefore);

                    // b-2. TotalClearedAmount__c
                    Decimal totalCleared = (refFO.ReconciledAMT__c != null ? refFO.ReconciledAMT__c : 0) + ramt;
                    // b-3. NetAmountAfterClearing__c
                    Decimal netAmount = (refFO.OriginAmount__c != null ? refFO.OriginAmount__c : 0) - totalCleared;
                    // b-4. BTStatus__c
                    String btStatus = REC_BankTransactionDomain.decideStatus(netAmount);

                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();
                    resolveRliId(rli, detail, ctx.existingFoRefs.get(foId), reconciliationId);

                    rli.RefFiduciaryOthers__c = foId;
                    rli.BizRegion__c = refFO.BizRegion__c;
                    rli.ReconciledAMT__c = ramt;
                    rli.TotalClearedAmount__c = totalCleared;
                    rli.NetAmountAfterClearing__c = netAmount;
                    rli.BTStatus__c = btStatus;

                    rliToUpsert.add(rli);
                    sumReconciledAmt += ramt;

                    if (settlementCurrency == null) {
                        settlementCurrency = refFO.SettlementCurrency__c;
                    }
                    if (
                        refFO.TransactionDate__c != null &&
                        (latestTransactionDate == null ||
                        refFO.TransactionDate__c > latestTransactionDate)
                    ) {
                        latestTransactionDate = refFO.TransactionDate__c;
                    }
                }
            }

            upsert as system rliToUpsert;

            // ── 4.5. Process P_C Other Charges RLIs ──────────────────────────
            Decimal sumOtherChargesPC = processPcRlis(reconciliationId, otherChargeRliItems);

            // ── 5. C. Update Base SLI RLI ────────────────────────────────────
            Decimal otherChargesVal = otherCharges != null ? otherCharges : 0;
            Decimal originAmount = ctx.baseSliRli.RefSettlementLineItem__r?.OriginAmount__c;

            // Build a clean SObject to avoid FLS issues with non-updateable fields (e.g. RefReconciliation__c)
            ReconciliationLineItem__c baseSliUpdate = new ReconciliationLineItem__c(Id = ctx.baseSliRli.Id);
            // c-1. SettlementCurrency__c
            baseSliUpdate.SettlementCurrency__c = settlementCurrency;
            // c-2. SettlementDate__c
            baseSliUpdate.SettlementDate__c = latestTransactionDate != null ? latestTransactionDate : Date.today();
            // c-3. SettlementAmountSLI__c
            baseSliUpdate.SettlementAmountSLI__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                sumReconciledAmt,
                otherChargesVal,
                sumOtherChargesPC
            );
            // c-4. SettlementAmountTTL__c
            baseSliUpdate.SettlementAmountTTL__c = REC_SettlementLineItemDomain.calculateSettlementAmountTTL(
                sumReconciledAmt,
                sumOtherChargesPC,
                settlementCurrency
            );
            // c-5. FXRateOrigintoSettlement__c
            String originCurrency = ctx.baseSliRli.RefSettlementLineItem__r?.OriginCurrency__c;
            baseSliUpdate.FXRateOrigintoSettlement__c = REC_SettlementLineItemDomain.calculateFXRate(
                settlementCurrency,
                originCurrency,
                baseSliUpdate.SettlementAmountSLI__c,
                originAmount
            );
            // Persist user-entered Other Charges
            baseSliUpdate.OtherCharges__c = otherChargesVal;

            update as system baseSliUpdate;
            setDraft(reconciliationId);

            return rliToUpsert;
        } catch (Exception e) {
            Database.rollback(sp);
            if (e instanceof REC_ReconciliationDomainException || e instanceof REC_ValidationException) {
                throw e;
            }
            throw new REC_ReconciliationDomainException('Error drafting settlement line items: ' + e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  SLI-Based Confirm
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Confirm operation for SLI-based reconciliation.
     * Unlike draft, this actually updates BankTransaction / FiduciaryOthers records,
     * updates the base SettlementLineItem and its counterpart, handles Other Charges
     * (P_C SLIs), and sets the Reconciliation status to 'Confirmed'.
     *
     * @param reconciliationId    Parent Reconciliation Id
     * @param details             BT/FO-referenced RLIs with user-entered ReconciledAMT__c
     * @param otherCharges        User-entered Other Charges from the base SLI table
     * @param baseSliInput        User-entered SLI fields (exchange, hold, etc.)
     * @param otherChargeItems    Other Charges table rows (P_C Settlement Line Items)
     * @param otherChargeRliItems P_C Other Charges RLI rows from the table (nullable)
     */
    public static void confirmSettlementLineItemBased(
        String reconciliationId,
        List<ReconciliationLineItem__c> details,
        Decimal otherCharges,
        SettlementLineItem__c baseSliInput,
        List<SettlementLineItem__c> otherChargeItems,
        List<ReconciliationLineItem__c> otherChargeRliItems
    ) {
        SavePoint sp = Database.setSavepoint();

        try {
            if (String.isBlank(reconciliationId)) {
                throw new REC_ReconciliationDomainException('Reconciliation Id is required');
            }
            if (details == null || details.isEmpty()) {
                throw new REC_ReconciliationDomainException('Selected items are required for confirmation');
            }

            REC_ReconciliationLineItemSelector rliSel = REC_ReconciliationLineItemSelector.getInstance();
            REC_BankTransactionSelector btSel = REC_BankTransactionSelector.getInstance();
            REC_FiduciaryOthersSelector foSel = REC_FiduciaryOthersSelector.getInstance();

            // ── 1. Fetch existing RLIs & build context ───────────────────────
            List<ReconciliationLineItem__c> rliExisting = rliSel.queryForDraft(reconciliationId);

            if (rliExisting.isEmpty()) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_RLI_NOT_FOUND);
            }

            RliContext ctx = buildRliContext(rliExisting, details);

            if (ctx.baseSliRli == null) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_BASE_SLI_RLI_NOT_FOUND);
            }

            // ── 2. DELETE: orphaned RLIs ─────────────────────────────────────
            deleteOrphanedRlis(rliExisting, ctx.newBtRefs.keySet(), ctx.newFoRefs.keySet());

            List<ReconciliationLineItem__c> rliToUpsert = new List<ReconciliationLineItem__c>();
            Decimal sumReconciledAmt = 0;
            Date latestTransactionDate;
            String settlementCurrency;

            // ── Step 1: Bank Transaction ─────────────────────────────────────
            if (!ctx.newBtRefs.isEmpty()) {
                String btFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(ctx.newBtRefs.keySet())).toJson();
                Map<Id, BankTransaction__c> refBTs = new Map<Id, BankTransaction__c>();
                for (SObject s : btSel.queryByFilter(btFilter)) {
                    BankTransaction__c bt = (BankTransaction__c) s;
                    refBTs.put(bt.Id, bt);
                }

                List<BankTransaction__c> btsToUpdate = new List<BankTransaction__c>();

                for (Id btId : ctx.newBtRefs.keySet()) {
                    ReconciliationLineItem__c detail = ctx.newBtRefs.get(btId);
                    BankTransaction__c refBT = refBTs.get(btId);
                    Decimal ramt = detail.ReconciledAMT__c != null ? detail.ReconciledAMT__c : 0;

                    // C. Validate detail ReconciledAMT
                    Decimal btNetBefore =
                        (refBT.OriginAmount__c != null ? refBT.OriginAmount__c : 0) -
                        (refBT.TotalClearedAmount__c != null ? refBT.TotalClearedAmount__c : 0);
                    validateSliDetailReconciledAmount(refBT.OriginAmount__c, ramt, btNetBefore);

                    // Update BT: TotalClearedAmount += RAMT, recalc NetBalance & Status
                    REC_BankTransactionDomain.applyReconciledAmount(refBT, ramt);
                    btsToUpdate.add(refBT);

                    // Build RLI from updated BT values
                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();
                    resolveRliId(rli, detail, ctx.existingBtRefs.get(btId), reconciliationId);

                    rli.RefBankTransaction__c = btId;
                    rli.BizRegion__c = refBT.BizRegion__c;
                    rli.ReconciledAMT__c = ramt;
                    rli.TotalClearedAmount__c = refBT.TotalClearedAmount__c;
                    rli.NetAmountAfterClearing__c = refBT.NetBalanceAftCleared__c;
                    rli.BTStatus__c = refBT.Status__c;

                    rliToUpsert.add(rli);
                    sumReconciledAmt += ramt;

                    if (settlementCurrency == null) {
                        settlementCurrency = refBT.Currency__c;
                    }
                    if (
                        refBT.TransactionDate__c != null &&
                        (latestTransactionDate == null ||
                        refBT.TransactionDate__c > latestTransactionDate)
                    ) {
                        latestTransactionDate = refBT.TransactionDate__c;
                    }
                }

                update as system btsToUpdate;
            }

            // ── Step 2: Fiduciary Others ─────────────────────────────────────
            if (!ctx.newFoRefs.isEmpty()) {
                String foFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(ctx.newFoRefs.keySet())).toJson();
                Map<Id, FiduciaryOthers__c> refFOs = new Map<Id, FiduciaryOthers__c>();
                for (SObject s : foSel.queryByFilter(foFilter)) {
                    FiduciaryOthers__c fo = (FiduciaryOthers__c) s;
                    refFOs.put(fo.Id, fo);
                }

                List<FiduciaryOthers__c> fosToUpdate = new List<FiduciaryOthers__c>();

                for (Id foId : ctx.newFoRefs.keySet()) {
                    ReconciliationLineItem__c detail = ctx.newFoRefs.get(foId);
                    FiduciaryOthers__c refFO = refFOs.get(foId);
                    Decimal ramt = detail.ReconciledAMT__c != null ? detail.ReconciledAMT__c : 0;

                    // C. Validate detail ReconciledAMT
                    Decimal foNetBefore =
                        (refFO.OriginAmount__c != null ? refFO.OriginAmount__c : 0) -
                        (refFO.ReconciledAMT__c != null ? refFO.ReconciledAMT__c : 0);
                    validateSliDetailReconciledAmount(refFO.OriginAmount__c, ramt, foNetBefore);

                    // Update FO: ReconciledAMT += RAMT, recalc NotReconciledAMT & Status
                    REC_FiduciaryOthersDomain.applyReconciledAmount(refFO, ramt);
                    fosToUpdate.add(refFO);

                    // Build RLI from updated FO values
                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();
                    resolveRliId(rli, detail, ctx.existingFoRefs.get(foId), reconciliationId);

                    rli.RefFiduciaryOthers__c = foId;
                    rli.BizRegion__c = refFO.BizRegion__c;
                    rli.ReconciledAMT__c = ramt;
                    rli.TotalClearedAmount__c = refFO.ReconciledAMT__c;
                    rli.NetAmountAfterClearing__c = refFO.NotReconciledAMT__c;
                    rli.BTStatus__c = refFO.Status__c;

                    rliToUpsert.add(rli);
                    sumReconciledAmt += ramt;

                    if (settlementCurrency == null) {
                        settlementCurrency = refFO.SettlementCurrency__c;
                    }
                    if (
                        refFO.TransactionDate__c != null &&
                        (latestTransactionDate == null ||
                        refFO.TransactionDate__c > latestTransactionDate)
                    ) {
                        latestTransactionDate = refFO.TransactionDate__c;
                    }
                }

                update as system fosToUpdate;
            }

            // Upsert BT/FO-referenced RLIs
            upsert as system rliToUpsert;

            // ── Step 3: Other Charges (P_C Settlement Line Items) ────────────
            // Other Charges are only created at Confirm and immutable afterwards,
            // so we always insert fresh records (no existing OCs to reconcile).
            Decimal sumOtherChargesPC = 0;
            Date settlementDate = latestTransactionDate != null ? latestTransactionDate : Date.today();
            String baseSli_BizRegion = ctx.baseSliRli.RefSettlementLineItem__r?.BizRegion__c;

            if (otherChargeItems != null && !otherChargeItems.isEmpty()) {
                // Query RefSettlement__c from OriginSettlementLineItem for each P_C SLI
                Map<Id, SettlementLineItem__c> originSliMap = queryOriginSliRefSettlement(otherChargeItems);

                for (SettlementLineItem__c oci : otherChargeItems) {
                    oci.OriginReconciliationNo__c = reconciliationId;
                    oci.ClosingType__c = REC_Consts.ClosingType.P_C;
                    oci.OriginCurrency__c = settlementCurrency;
                    oci.AccountingDate__c = settlementDate;
                    oci.BizRegion__c = baseSli_BizRegion;
                    oci.AccountName__c = REC_Utils.getAccountIdByRegion(baseSli_BizRegion);
                    oci.Status__c = REC_Consts.STCStatus.CONFIRM;
                    oci.OriginalFXRateDate__c = oci.AccountingDate__c;
                    oci.SendtoCloseDate__c = oci.AccountingDate__c;
                    if (
                        oci.OriginSettlementLineItem__c != null && originSliMap.containsKey(oci.OriginSettlementLineItem__c)
                    ) {
                        oci.RefSettlement__c = originSliMap.get(oci.OriginSettlementLineItem__c).RefSettlement__c;
                    }
                    sumOtherChargesPC += (oci.OriginAmount__c != null ? oci.OriginAmount__c : 0);
                }
                insert as system otherChargeItems;
            }

            // ── Step 3.5: P_C Other Charges RLIs ─────────────────────────────
            processPcRlis(reconciliationId, otherChargeRliItems);

            // ── Step 4: Base Settlement Line Item ────────────────────────────
            Id baseSliId = ctx.baseSliRli.RefSettlementLineItem__c;
            Decimal otherChargesVal = otherCharges != null ? otherCharges : 0;
            Decimal originAmount = ctx.baseSliRli.RefSettlementLineItem__r?.OriginAmount__c;

            SettlementLineItem__c baseSli = new SettlementLineItem__c(Id = baseSliId);
            baseSli.SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR;
            baseSli.SettlementCurrency__c = settlementCurrency;
            baseSli.SettlementDate__c = settlementDate;
            baseSli.SettlementType__c = REC_Consts.SettlementType.NORMAL;
            baseSli.SettlementAmountSLI__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                sumReconciledAmt,
                otherChargesVal,
                sumOtherChargesPC
            );

            // B. Validate: Base SLI OriginAmount must equal calculated SettlementAmountSLI (only when same currency)
            String originCurrency = ctx.baseSliRli.RefSettlementLineItem__r?.OriginCurrency__c;
            if (originCurrency == settlementCurrency && originAmount != baseSli.SettlementAmountSLI__c) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_UNMATCHED_RECONCILED_AMT);
            }

            baseSli.OtherCharges__c = otherChargesVal;
            baseSli.SettlementAmountTTL__c = REC_SettlementLineItemDomain.calculateSettlementAmountTTL(
                sumReconciledAmt,
                sumOtherChargesPC,
                settlementCurrency
            );

            // C. Validate: OriginAmount, SettlementAmountSLI, SettlementAmountTTL must have the same sign
            Decimal sliAmt = baseSli.SettlementAmountSLI__c ?? 0;
            Decimal ttlAmt = baseSli.SettlementAmountTTL__c ?? 0;

            if (originAmount != null && (originAmount * sliAmt < 0 || originAmount * ttlAmt < 0)) {
                throw new REC_ReconciliationDomainException(
                    'Origin Amount, Settlement Amount SLI, and Settlement Amount TTL must all have the same sign.'
                );
            }

            // FXRateSettlementAccounting__c
            baseSli.FXRateSettlementAccounting__c = FX.rate(settlementDate, baseSli_BizRegion, settlementCurrency);

            // A. FXRateOrigintoSettlement__c — if settlement ccy matches origin ccy → 1
            baseSli.FXRateOrigintoSettlement__c = REC_SettlementLineItemDomain.calculateFXRate(
                settlementCurrency,
                originCurrency,
                baseSli.SettlementAmountSLI__c,
                originAmount
            );

            // User-entered fields from baseSliInput
            if (baseSliInput != null) {
                baseSli.RemittanceOnHold__c = baseSliInput.RemittanceOnHold__c;
                baseSli.HoldReason__c = baseSliInput.HoldReason__c;
                baseSli.ExchangeDate__c = baseSliInput.ExchangeDate__c;
                baseSli.ExchangeCurrency__c = baseSliInput.ExchangeCurrency__c;
                baseSli.ExchangeAmount__c = baseSliInput.ExchangeAmount__c;
                baseSli.ExchangeRate__c = baseSliInput.ExchangeRate__c;
            }

            update as system baseSli;

            // Update Base SLI RLI with refreshed SLI values (clean SObject to avoid FLS issues)
            ReconciliationLineItem__c baseSliRliUpdate = new ReconciliationLineItem__c(Id = ctx.baseSliRli.Id);
            baseSliRliUpdate.SettlementCurrency__c = baseSli.SettlementCurrency__c;
            baseSliRliUpdate.SettlementDate__c = baseSli.SettlementDate__c;
            baseSliRliUpdate.SettlementAmountTTL__c = baseSli.SettlementAmountTTL__c;
            baseSliRliUpdate.OtherCharges__c = baseSli.OtherCharges__c;
            baseSliRliUpdate.SettlementAmountSLI__c = baseSli.SettlementAmountSLI__c;
            baseSliRliUpdate.FXRateOrigintoSettlement__c = baseSli.FXRateOrigintoSettlement__c;
            baseSliRliUpdate.FXRateSettlementAccounting__c = baseSli.FXRateSettlementAccounting__c;

            update as system baseSliRliUpdate;

            // ── Step 5: Counter Settlement Line Item ─────────────────────────
            // Fetch baseSli from DB for counterpart case determination
            REC_SettlementLineItemSelector sliSel = REC_SettlementLineItemSelector.getInstance();
            List<SObject> baseSliRows = sliSel.queryByIds(new Set<Id>{ baseSliId });
            SettlementLineItem__c baseSliDb = baseSliRows.isEmpty() ? null : (SettlementLineItem__c) baseSliRows[0];

            Map<Id, SettlementLineItem__c> counterMap = REC_SettlementLineItemDomain.searchCounterparts(
                new List<Id>{ baseSliId }
            );
            if (counterMap.containsKey(baseSliId) && baseSliDb != null) {
                SettlementLineItem__c counterSli = counterMap.get(baseSliId);

                // Use DB SettlementType for Case determination
                String settlementType = baseSliDb.SettlementType__c;
                Decimal originAmountVal = baseSliDb.OriginAmount__c;

                Boolean isCase1Or2 = REC_SettlementLineItemDomain.isCounterpartCase1Or2(
                    settlementType,
                    originAmountVal,
                    counterSli
                );

                SettlementLineItem__c counterUpdate = new SettlementLineItem__c(Id = counterSli.Id);

                if (isCase1Or2) {
                    // Case 1 OR Case 2: main field updates
                    counterUpdate.OtherCharges__c = -1 * otherChargesVal;
                    counterUpdate.SettlementStatus__c = REC_Consts.SettlementStatus.AVAILABLE;
                    counterUpdate.SettlementType__c = settlementType;
                    counterUpdate.SettlementCurrency__c = baseSli.SettlementCurrency__c;
                    counterUpdate.FXRateOrigintoSettlement__c = baseSli.FXRateOrigintoSettlement__c;

                    // (Case 1 OR Case 2) AND Case 4: DueDate update
                    // Use post-update state: SettlementStatus = Clear (set in Step 4)
                    SettlementLineItem__c originForDueDate = new SettlementLineItem__c();
                    originForDueDate.OriginAmount__c = baseSliDb.OriginAmount__c;
                    originForDueDate.Status__c = baseSliDb.Status__c;
                    originForDueDate.SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR;

                    if (REC_SettlementLineItemDomain.isDueDateUpdatable(originForDueDate, counterSli)) {
                        counterUpdate.DueDate__c = REC_Utils.getBusinessDay(
                            baseSliDb.BizRegion__c,
                            baseSliDb.SettlementDateCounterparty__c ?? Date.today(),
                            10
                        );
                    }
                } else {
                    // Case 3: NOT Case1 AND NOT Case2
                    counterUpdate.SettlementDateCounterparty__c = baseSli.SettlementDate__c;
                }

                update as system counterUpdate;
            }

            // ── Step 6: Set Reconciliation Status to Confirmed ───────────────
            confirm(reconciliationId, settlementCurrency);

            // ── Step 7: Enqueue NoteAmount Evaluation ────────────────────────
            Set<Id> evaluationSliIds = new Set<Id>();
            evaluationSliIds.add(baseSliId);
            if (counterMap.containsKey(baseSliId)) {
                SettlementLineItem__c ctrSli = counterMap.get(baseSliId);
                if (ctrSli.ClosingType__c != REC_Consts.ClosingType.P_C) {
                    evaluationSliIds.add(ctrSli.Id);
                }
            }
            if (!evaluationSliIds.isEmpty()) {
                System.enqueueJob(new REC_NoteAmountEvaluationQueueable(evaluationSliIds));
            }
        } catch (Exception e) {
            Database.rollback(sp);
            if (e instanceof REC_ReconciliationDomainException || e instanceof REC_ValidationException) {
                throw e;
            }
            throw new REC_ReconciliationDomainException('Error confirming settlement line items: ' + e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Statement-Based Draft
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Draft operation for Statement-based reconciliation.
     * Creates/updates/deletes SLI-referenced RLIs and updates the base Statement RLI.
     *
     * Draft only updates RLI records — does NOT update referenced SLI or Statement records.
     *
     * @param reconciliationId    Parent Reconciliation Id
     * @param details             SLI-referenced RLIs with user-entered fields
     * @param otherChargeRliItems P_C Other Charges RLI rows from the table (nullable)
     * @param baseStmtRliInput     User-entered fields for the base Statement RLI (nullable)
     */
    public static void draftStatementBased(
        String reconciliationId,
        List<ReconciliationLineItem__c> details,
        List<ReconciliationLineItem__c> foDetails,
        List<ReconciliationLineItem__c> otherChargeRliItems,
        ReconciliationLineItem__c baseStmtRliInput,
        List<ReconciliationLineItem__c> stmtLineItemDetails
    ) {
        SavePoint sp = Database.setSavepoint();

        try {
            if (String.isBlank(reconciliationId)) {
                throw new REC_ReconciliationDomainException('Reconciliation Id is required');
            }

            REC_ReconciliationLineItemSelector rliSel = REC_ReconciliationLineItemSelector.getInstance();
            REC_SettlementLineItemSelector sliSel = REC_SettlementLineItemSelector.getInstance();
            REC_FiduciaryOthersSelector foSel = REC_FiduciaryOthersSelector.getInstance();

            // ── 1. Fetch existing RLIs ───────────────────────────────────────
            List<ReconciliationLineItem__c> rliExisting = rliSel.queryForStmtBasedDraft(reconciliationId);

            if (rliExisting.isEmpty()) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_RLI_NOT_FOUND);
            }

            // ── 2. Categorise existing RLIs ──────────────────────────────────
            ReconciliationLineItem__c baseStmtRli;
            Map<Id, ReconciliationLineItem__c> existingSliRefs = new Map<Id, ReconciliationLineItem__c>();
            Map<Id, ReconciliationLineItem__c> existingFoRefs = new Map<Id, ReconciliationLineItem__c>();

            for (ReconciliationLineItem__c rli : rliExisting) {
                if (rli.RefStatement__c != null) {
                    baseStmtRli = rli;
                } else if (rli.RefStatementLineItem__c != null) {
                    // StmtLI RLIs — skip; handled separately via stmtLineItemDetails
                } else if (rli.RefSettlementLineItem__c != null) {
                    existingSliRefs.put(rli.RefSettlementLineItem__c, rli);
                } else if (rli.RefFiduciaryOthers__c != null) {
                    existingFoRefs.put(rli.RefFiduciaryOthers__c, rli);
                }
            }

            if (baseStmtRli == null) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_RLI_NOT_FOUND);
            }

            // ── 3. Build new SLI refs from details ───────────────────────────
            Map<Id, ReconciliationLineItem__c> newSliRefs = new Map<Id, ReconciliationLineItem__c>();
            if (details != null) {
                for (ReconciliationLineItem__c detail : details) {
                    if (detail.RefSettlementLineItem__c != null) {
                        newSliRefs.put(detail.RefSettlementLineItem__c, detail);
                    }
                }
            }

            // ── 3.5. Build new FO refs from foDetails ───────────────────────
            Map<Id, ReconciliationLineItem__c> newFoRefs = new Map<Id, ReconciliationLineItem__c>();
            if (foDetails != null) {
                for (ReconciliationLineItem__c detail : foDetails) {
                    if (detail.RefFiduciaryOthers__c != null) {
                        newFoRefs.put(detail.RefFiduciaryOthers__c, detail);
                    }
                }
            }

            // ── 4. DELETE: RLIs that exist but are no longer in new set ──────
            // (StmtLI RLIs are excluded — they are created at Upload and never orphaned)
            List<ReconciliationLineItem__c> orphans = new List<ReconciliationLineItem__c>();
            for (ReconciliationLineItem__c rli : rliExisting) {
                if (rli.RefStatementLineItem__c != null) {
                    continue; // StmtLI RLIs are never orphaned
                }
                if (rli.RefSettlementLineItem__c != null && !newSliRefs.containsKey(rli.RefSettlementLineItem__c)) {
                    orphans.add(rli);
                }
                if (rli.RefFiduciaryOthers__c != null && !newFoRefs.containsKey(rli.RefFiduciaryOthers__c)) {
                    orphans.add(rli);
                }
            }
            if (!orphans.isEmpty()) {
                delete as system orphans;
            }

            // ── 4.5. StmtLI RLI UPDATE + recalcTotalPremium ─────────────────
            Decimal recalcTotalPremium = null;
            if (stmtLineItemDetails != null && !stmtLineItemDetails.isEmpty()) {
                recalcTotalPremium = 0;
                List<ReconciliationLineItem__c> stmtLiRliToUpdate = new List<ReconciliationLineItem__c>();
                for (ReconciliationLineItem__c detail : stmtLineItemDetails) {
                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c(Id = detail.Id);
                    rli.FXAmountPremiumLocal__c = detail.FXAmountPremiumLocal__c;
                    rli.Remarks__c = detail.Remarks__c;
                    stmtLiRliToUpdate.add(rli);
                    recalcTotalPremium += (detail.FXAmountPremiumLocal__c != null ? detail.FXAmountPremiumLocal__c : 0);
                }
                update as system stmtLiRliToUpdate;
            }

            // ── 5. Handle empty details → clear base Statement RLI ──────────
            Boolean hasNoSliDetails = (details == null || details.isEmpty());
            Boolean hasNoFoDetails = (foDetails == null || foDetails.isEmpty());
            if (hasNoSliDetails && hasNoFoDetails) {
                ReconciliationLineItem__c clearRli = new ReconciliationLineItem__c(Id = baseStmtRli.Id);
                clearRli.ReconciledAMT__c = 0;
                clearRli.NotReconciledAMT__c = baseStmtRli.RefStatement__r?.TotalBrokerageAMT__c;
                clearRli.MatchedPremiumAMT__c = 0;
                clearRli.NotMatchedPremiumAMT__c = baseStmtRli.RefStatement__r?.TotalPremiumAMT__c;
                clearRli.MatchingStatus__c = 'Unmatched';
                update as system clearRli;
                processStmtBasedPcRlis(
                    reconciliationId,
                    otherChargeRliItems,
                    baseStmtRli.RefStatement__r?.BizRegion__c,
                    baseStmtRli.RefStatement__r?.Currency__c,
                    baseStmtRli.RefStatement__r?.TransactionDate__c
                );
                setDraft(reconciliationId);
                return;
            }

            // ── 6. Re-query referenced SLIs from DB ─────────────────────────
            // ── 7. UPSERT: SLI-referenced RLIs with calculated fields ───────
            List<ReconciliationLineItem__c> rliToUpsert = new List<ReconciliationLineItem__c>();
            Decimal sumSettlementAmtTTL = 0;
            Decimal sumSettlementAmtPremium = 0;
            String baseStmtCurrency = baseStmtRli.RefStatement__r?.Currency__c;

            if (!newSliRefs.isEmpty()) {
                String sliFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(newSliRefs.keySet())).toJson();
                Map<Id, SettlementLineItem__c> refSLIs = new Map<Id, SettlementLineItem__c>();
                for (SObject s : sliSel.queryByFilter(sliFilter)) {
                    SettlementLineItem__c sli = (SettlementLineItem__c) s;
                    refSLIs.put(sli.Id, sli);
                }

                for (Id sliId : newSliRefs.keySet()) {
                    ReconciliationLineItem__c detail = newSliRefs.get(sliId);
                    SettlementLineItem__c refSLI = refSLIs.get(sliId);
                    if (refSLI == null) {
                        continue;
                    }

                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();

                    // Resolve Id (update existing or insert new)
                    ReconciliationLineItem__c existing = existingSliRefs.get(sliId);
                    if (detail.Id != null && !String.valueOf(detail.Id).startsWith('_temp')) {
                        rli.Id = detail.Id;
                    } else if (existing != null) {
                        rli.Id = existing.Id;
                    } else {
                        rli.RefReconciliation__c = reconciliationId;
                    }

                    rli.RefSettlementLineItem__c = sliId;
                    rli.BizRegion__c = refSLI.BizRegion__c;

                    // User-entered fields
                    rli.SettlementCurrency__c = detail.SettlementCurrency__c;
                    rli.FXRateOrigintoSettlement__c = detail.FXRateOrigintoSettlement__c;
                    rli.SettlementDate__c = baseStmtRli.RefStatement__r?.TransactionDate__c;
                    Decimal otherCharges = detail.OtherCharges__c != null ? detail.OtherCharges__c : 0;
                    rli.OtherCharges__c = otherCharges;
                    rli.NeedsVerification__c = detail.NeedsVerification__c;
                    rli.Remarks__c = detail.Remarks__c;
                    rli.FXAmountPremiumLocal__c = detail.FXAmountPremiumLocal__c;

                    // SettlementAmountSLI__c = RefSLI.OriginAmount * FXRateOrigintoSettlement
                    rli.SettlementAmountSLI__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                        refSLI.OriginAmount__c,
                        rli.FXRateOrigintoSettlement__c,
                        rli.SettlementCurrency__c
                    );

                    // SettlementAmountTTL__c = SettlementAmountSLI - OtherCharges
                    rli.SettlementAmountTTL__c = REC_SettlementLineItemDomain.calculateDetailTTL(
                        rli.SettlementAmountSLI__c,
                        rli.OtherCharges__c,
                        rli.SettlementCurrency__c
                    );

                    // SettlementAmountPremium__c = RLI.FXAmountPremiumLocal * FXRateOrigintoSettlement
                    rli.SettlementAmountPremium__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                        detail.FXAmountPremiumLocal__c,
                        rli.FXRateOrigintoSettlement__c,
                        rli.SettlementCurrency__c
                    );

                    rliToUpsert.add(rli);

                    sumSettlementAmtTTL += (rli.SettlementAmountTTL__c != null ? rli.SettlementAmountTTL__c : 0);
                    sumSettlementAmtPremium += (rli.SettlementAmountPremium__c != null ? rli.SettlementAmountPremium__c : 0);
                }
            }

            if (!rliToUpsert.isEmpty()) {
                upsert as system rliToUpsert;
            }

            // ── 7.5. Validate & UPSERT: FO-referenced RLIs ─────────────────
            List<ReconciliationLineItem__c> foRliToUpsert = new List<ReconciliationLineItem__c>();
            if (!newFoRefs.isEmpty()) {
                String foFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(newFoRefs.keySet())).toJson();
                Map<Id, FiduciaryOthers__c> refFOs = new Map<Id, FiduciaryOthers__c>();
                for (SObject s : foSel.queryByFilter(foFilter)) {
                    FiduciaryOthers__c fo = (FiduciaryOthers__c) s;
                    refFOs.put(fo.Id, fo);
                }

                // Validate: 0 ≤ ABS(INPUT.ReconciledAMT) ≤ ABS((BeforeCalc) NotReconciledAMT)
                List<REC_TableHelper.CellError> cellErrors = new List<REC_TableHelper.CellError>();
                for (Id foId : newFoRefs.keySet()) {
                    ReconciliationLineItem__c detail = newFoRefs.get(foId);
                    FiduciaryOthers__c refFO = refFOs.get(foId);
                    if (refFO == null)
                        continue;

                    Decimal ramt = detail.ReconciledAMT__c != null ? detail.ReconciledAMT__c : 0;
                    Decimal notReconciled = refFO.NotReconciledAMT__c != null
                        ? refFO.NotReconciledAMT__c
                        : (refFO.OriginAmount__c != null ? refFO.OriginAmount__c : 0);

                    if (!REC_FiduciaryOthersDomain.isReconciledAmountValid(ramt, notReconciled)) {
                        cellErrors.add(
                            new REC_TableHelper.CellError(
                                String.valueOf(foId),
                                'ReconciledAMT__c',
                                Label.REC_MSG_INVALID_RECONCILED_AMT
                            )
                        );
                    }
                }
                if (!cellErrors.isEmpty()) {
                    throw new REC_ValidationException(cellErrors);
                }

                // Build & upsert FO RLIs
                for (Id foId : newFoRefs.keySet()) {
                    ReconciliationLineItem__c detail = newFoRefs.get(foId);
                    FiduciaryOthers__c refFO = refFOs.get(foId);
                    if (refFO == null)
                        continue;

                    Decimal ramt = detail.ReconciledAMT__c != null ? detail.ReconciledAMT__c : 0;

                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();

                    // Resolve Id (update existing or insert new)
                    ReconciliationLineItem__c existingFo = existingFoRefs.get(foId);
                    if (detail.Id != null && !String.valueOf(detail.Id).startsWith('_fo_temp')) {
                        rli.Id = detail.Id;
                    } else if (existingFo != null) {
                        rli.Id = existingFo.Id;
                    } else {
                        rli.RefReconciliation__c = reconciliationId;
                    }

                    rli.RefFiduciaryOthers__c = foId;
                    rli.BizRegion__c = refFO.BizRegion__c;
                    rli.BTAccountName__c = refFO.AccountName__c;
                    rli.ReconciledAMT__c = ramt;
                    rli.NotReconciledAMT__c = (refFO.OriginAmount__c != null ? refFO.OriginAmount__c : 0) - ramt;

                    foRliToUpsert.add(rli);
                }

                upsert as system foRliToUpsert;
            }

            // ── 8. Process P_C Other Charges RLIs ───────────────────────────
            Decimal sumOtherChargesPC = processStmtBasedPcRlis(
                reconciliationId,
                otherChargeRliItems,
                baseStmtRli.RefStatement__r?.BizRegion__c,
                baseStmtCurrency,
                baseStmtRli.RefStatement__r?.TransactionDate__c
            );

            // ── 9. Update Base Statement RLI ─────────────────────────────────
            Decimal totalBrokerageAmt = baseStmtRli.RefStatement__r?.TotalBrokerageAMT__c != null
                ? baseStmtRli.RefStatement__r.TotalBrokerageAMT__c
                : 0;
            Decimal totalPremiumAmt = recalcTotalPremium != null
                ? recalcTotalPremium
                : (baseStmtRli.TotalPremiumAMT__c != null &&
                      baseStmtRli.TotalPremiumAMT__c != 0
                      ? baseStmtRli.TotalPremiumAMT__c
                      : (baseStmtRli.RefStatement__r?.TotalPremiumAMT__c != null
                            ? baseStmtRli.RefStatement__r.TotalPremiumAMT__c
                            : 0));

            ReconciliationLineItem__c baseUpdate = new ReconciliationLineItem__c(Id = baseStmtRli.Id);
            if (baseStmtRliInput != null) {
                baseUpdate.Remarks__c = baseStmtRliInput.Remarks__c;
            }

            // ReconciledAMT = Σ(Selected.SettlementAmountTTL) - Σ(P_C.OriginAmount)
            baseUpdate.ReconciledAMT__c = sumSettlementAmtTTL - sumOtherChargesPC;

            // NotReconciledAMT = RefStatement.TotalBrokerageAMT - ReconciledAMT
            baseUpdate.NotReconciledAMT__c = totalBrokerageAmt - baseUpdate.ReconciledAMT__c;

            // MatchedPremiumAMT = Σ(Selected.SettlementAmountPremium)
            baseUpdate.MatchedPremiumAMT__c = sumSettlementAmtPremium;

            // NotMatchedPremiumAMT = TotalPremiumAMT - MatchedPremiumAMT
            baseUpdate.NotMatchedPremiumAMT__c = totalPremiumAmt - baseUpdate.MatchedPremiumAMT__c;

            // TotalPremiumAMT__c — store recalculated value on Base RLI
            baseUpdate.TotalPremiumAMT__c = totalPremiumAmt;

            // MatchingStatus
            baseUpdate.MatchingStatus__c = REC_StatementDomain.determineMatchingStatus(
                baseStmtCurrency,
                baseUpdate.NotReconciledAMT__c
            );

            update as system baseUpdate;

            // ── 10. Set Reconciliation status to Draft ──────────────────────
            setDraft(reconciliationId);

            // ── 11. NeedsVerification post-processing ────────────────────────
            Set<Id> needsVerifSliIds = new Set<Id>();
            for (Id sliId : newSliRefs.keySet()) {
                if (newSliRefs.get(sliId).NeedsVerification__c == true) {
                    needsVerifSliIds.add(sliId);
                }
            }
            if (!needsVerifSliIds.isEmpty()) {
                new REC_NeedsVerificationService(reconciliationId, baseStmtRli.RefStatement__c, needsVerifSliIds).process();
            }
        } catch (Exception e) {
            Database.rollback(sp);
            if (e instanceof REC_ReconciliationDomainException || e instanceof REC_ValidationException) {
                throw e;
            }
            throw new REC_ReconciliationDomainException(
                'Error drafting statement based reconciliation: ' + '[' + e.getTypeName() + '] ' + e.getMessage()
            );
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Stmt-Based Confirm
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Confirm operation for Statement-based reconciliation.
     * Includes Draft logic (RLI upsert/delete) AND actual updates to:
     *   - Detail Settlement Line Items (confirm fields)
     *   - Fiduciary Others (reconciled amount accumulation)
     *   - P_C Settlement Line Items (created at Confirm)
     *   - Base Statement RLI and Statement record
     *   - Reconciliation status
     */
    public static void confirmStatementBased(
        String reconciliationId,
        List<ReconciliationLineItem__c> details,
        List<ReconciliationLineItem__c> foDetails,
        List<ReconciliationLineItem__c> otherChargeRliItems,
        ReconciliationLineItem__c baseStmtRliInput,
        List<ReconciliationLineItem__c> stmtLineItemDetails
    ) {
        SavePoint sp = Database.setSavepoint();

        try {
            if (String.isBlank(reconciliationId)) {
                throw new REC_ReconciliationDomainException('Reconciliation Id is required');
            }

            REC_ReconciliationLineItemSelector rliSel = REC_ReconciliationLineItemSelector.getInstance();
            REC_SettlementLineItemSelector sliSel = REC_SettlementLineItemSelector.getInstance();
            REC_FiduciaryOthersSelector foSel = REC_FiduciaryOthersSelector.getInstance();

            // ── 1. Fetch existing RLIs ───────────────────────────────────────
            List<ReconciliationLineItem__c> rliExisting = rliSel.queryForStmtBasedDraft(reconciliationId);

            if (rliExisting.isEmpty()) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_RLI_NOT_FOUND);
            }

            // ── 2. Categorise existing RLIs ──────────────────────────────────
            ReconciliationLineItem__c baseStmtRli;
            Map<Id, ReconciliationLineItem__c> existingSliRefs = new Map<Id, ReconciliationLineItem__c>();
            Map<Id, ReconciliationLineItem__c> existingFoRefs = new Map<Id, ReconciliationLineItem__c>();

            for (ReconciliationLineItem__c rli : rliExisting) {
                if (rli.RefStatement__c != null) {
                    baseStmtRli = rli;
                } else if (rli.RefStatementLineItem__c != null) {
                    // StmtLI RLIs — skip; handled separately via stmtLineItemDetails
                } else if (rli.RefSettlementLineItem__c != null) {
                    existingSliRefs.put(rli.RefSettlementLineItem__c, rli);
                } else if (rli.RefFiduciaryOthers__c != null) {
                    existingFoRefs.put(rli.RefFiduciaryOthers__c, rli);
                }
            }

            if (baseStmtRli == null) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_RLI_NOT_FOUND);
            }

            // ── 3. Build new SLI refs from details ───────────────────────────
            Map<Id, ReconciliationLineItem__c> newSliRefs = new Map<Id, ReconciliationLineItem__c>();
            if (details != null) {
                for (ReconciliationLineItem__c detail : details) {
                    if (detail.RefSettlementLineItem__c != null) {
                        newSliRefs.put(detail.RefSettlementLineItem__c, detail);
                    }
                }
            }

            // ── 3.5. Build new FO refs from foDetails ───────────────────────
            Map<Id, ReconciliationLineItem__c> newFoRefs = new Map<Id, ReconciliationLineItem__c>();
            if (foDetails != null) {
                for (ReconciliationLineItem__c detail : foDetails) {
                    if (detail.RefFiduciaryOthers__c != null) {
                        newFoRefs.put(detail.RefFiduciaryOthers__c, detail);
                    }
                }
            }

            // ── 3.6. Pre-Action Amount Validation ────────────────────────────
            //   Statement.TotalBrokerageAMT__c
            //     == BankTransaction.NetBalanceAftCleared__c
            //        + Σ ( selected FiduciaryOthers.NotReconciledAMT__c )
            //   All comparison values are queried fresh from the DB (no UI input).
            Decimal totalBrokerageDb = baseStmtRli.RefStatement__r?.TotalBrokerageAMT__c != null
                ? baseStmtRli.RefStatement__r.TotalBrokerageAMT__c
                : 0;
            Decimal netBalanceDb = 0;
            Id baseBtIdForValidation = baseStmtRli.RefStatement__r?.RefBankTransaction__c;
            if (baseBtIdForValidation != null) {
                List<BankTransaction__c> btsForValidation = REC_BankTransactionSelector.getInstance()
                    .queryForReconciliation(new Set<Id>{ baseBtIdForValidation });
                if (!btsForValidation.isEmpty() && btsForValidation[0].NetBalanceAftCleared__c != null) {
                    netBalanceDb = btsForValidation[0].NetBalanceAftCleared__c;
                }
            }
            Decimal sumFoNotReconciledDb = 0;
            if (!newFoRefs.isEmpty()) {
                String foValidationFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(newFoRefs.keySet())).toJson();
                for (SObject s : foSel.queryByFilter(foValidationFilter)) {
                    FiduciaryOthers__c fo = (FiduciaryOthers__c) s;
                    if (fo.NotReconciledAMT__c != null) {
                        sumFoNotReconciledDb += fo.NotReconciledAMT__c;
                    }
                }
            }
            if (totalBrokerageDb != netBalanceDb + sumFoNotReconciledDb) {
                throw new REC_ReconciliationDomainException(
                    'Statement TotalBrokerageAMT must equal BankTransaction NetBalanceAftCleared plus the sum of selected FiduciaryOthers NotReconciledAMT.'
                );
            }

            // ── 4. DELETE: RLIs that exist but are no longer in new set ──────
            // (StmtLI RLIs are excluded — they are created at Upload and never orphaned)
            List<ReconciliationLineItem__c> orphans = new List<ReconciliationLineItem__c>();
            for (ReconciliationLineItem__c rli : rliExisting) {
                if (rli.RefStatementLineItem__c != null) {
                    continue; // StmtLI RLIs are never orphaned
                }
                if (rli.RefSettlementLineItem__c != null && !newSliRefs.containsKey(rli.RefSettlementLineItem__c)) {
                    orphans.add(rli);
                }
                if (rli.RefFiduciaryOthers__c != null && !newFoRefs.containsKey(rli.RefFiduciaryOthers__c)) {
                    orphans.add(rli);
                }
            }
            if (!orphans.isEmpty()) {
                delete as system orphans;
            }

            // ── 4.5. StmtLI RLI UPDATE + StatementLineItem UPDATE + recalcTotalPremium ─
            Decimal recalcTotalPremium = null;
            if (stmtLineItemDetails != null && !stmtLineItemDetails.isEmpty()) {
                recalcTotalPremium = 0;
                List<ReconciliationLineItem__c> stmtLiRliToUpdate = new List<ReconciliationLineItem__c>();
                List<StatementLineItem__c> stmtLIsToUpdate = new List<StatementLineItem__c>();
                for (ReconciliationLineItem__c detail : stmtLineItemDetails) {
                    // StmtLI RLI UPDATE
                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c(Id = detail.Id);
                    rli.FXAmountPremiumLocal__c = detail.FXAmountPremiumLocal__c;
                    rli.Remarks__c = detail.Remarks__c;
                    stmtLiRliToUpdate.add(rli);

                    // StatementLineItem UPDATE (Confirm only — write back to original)
                    StatementLineItem__c sliUpdate = new StatementLineItem__c(Id = detail.RefStatementLineItem__c);
                    sliUpdate.Premium__c = detail.FXAmountPremiumLocal__c;
                    sliUpdate.Remarks__c = detail.Remarks__c;
                    stmtLIsToUpdate.add(sliUpdate);

                    recalcTotalPremium += (detail.FXAmountPremiumLocal__c != null ? detail.FXAmountPremiumLocal__c : 0);
                }
                update as system stmtLiRliToUpdate;
                update as system stmtLIsToUpdate;
            }

            // ── 5. SLI-referenced RLI UPSERT + SLI UPDATE ───────────────────
            List<ReconciliationLineItem__c> rliToUpsert = new List<ReconciliationLineItem__c>();
            List<SettlementLineItem__c> slisToUpdate = new List<SettlementLineItem__c>();
            Decimal sumSettlementAmtTTL = 0;
            Decimal sumSettlementAmtPremium = 0;
            String baseStmtCurrency = baseStmtRli.RefStatement__r?.Currency__c;

            if (!newSliRefs.isEmpty()) {
                String sliFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(newSliRefs.keySet())).toJson();
                Map<Id, SettlementLineItem__c> refSLIs = new Map<Id, SettlementLineItem__c>();
                for (SObject s : sliSel.queryByFilter(sliFilter)) {
                    SettlementLineItem__c sli = (SettlementLineItem__c) s;
                    refSLIs.put(sli.Id, sli);
                }

                for (Id sliId : newSliRefs.keySet()) {
                    ReconciliationLineItem__c detail = newSliRefs.get(sliId);
                    SettlementLineItem__c refSLI = refSLIs.get(sliId);
                    if (refSLI == null) {
                        continue;
                    }

                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();

                    // Resolve Id (update existing or insert new)
                    ReconciliationLineItem__c existing = existingSliRefs.get(sliId);
                    if (detail.Id != null && !String.valueOf(detail.Id).startsWith('_temp')) {
                        rli.Id = detail.Id;
                    } else if (existing != null) {
                        rli.Id = existing.Id;
                    } else {
                        rli.RefReconciliation__c = reconciliationId;
                    }

                    rli.RefSettlementLineItem__c = sliId;
                    rli.BizRegion__c = refSLI.BizRegion__c;

                    // User-entered fields
                    rli.SettlementCurrency__c = detail.SettlementCurrency__c;
                    rli.FXRateOrigintoSettlement__c = detail.FXRateOrigintoSettlement__c;
                    rli.SettlementDate__c = baseStmtRli.RefStatement__r?.TransactionDate__c;
                    Decimal otherCharges = detail.OtherCharges__c != null ? detail.OtherCharges__c : 0;
                    rli.OtherCharges__c = otherCharges;
                    rli.NeedsVerification__c = detail.NeedsVerification__c;
                    rli.Remarks__c = detail.Remarks__c;
                    rli.FXAmountPremiumLocal__c = detail.FXAmountPremiumLocal__c;

                    // Calculated fields
                    rli.SettlementAmountSLI__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                        refSLI.OriginAmount__c,
                        rli.FXRateOrigintoSettlement__c,
                        rli.SettlementCurrency__c
                    );
                    rli.SettlementAmountTTL__c = REC_SettlementLineItemDomain.calculateDetailTTL(
                        rli.SettlementAmountSLI__c,
                        rli.OtherCharges__c,
                        rli.SettlementCurrency__c
                    );
                    rli.SettlementAmountPremium__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                        detail.FXAmountPremiumLocal__c,
                        rli.FXRateOrigintoSettlement__c,
                        rli.SettlementCurrency__c
                    );

                    rliToUpsert.add(rli);

                    sumSettlementAmtTTL += (rli.SettlementAmountTTL__c != null ? rli.SettlementAmountTTL__c : 0);
                    sumSettlementAmtPremium += (rli.SettlementAmountPremium__c != null ? rli.SettlementAmountPremium__c : 0);

                    // ── Confirm-specific: SLI UPDATE ─────────────────────────
                    SettlementLineItem__c sliUpdate = new SettlementLineItem__c(Id = sliId);
                    sliUpdate.ReconcileNo__c = reconciliationId;
                    sliUpdate.BizRegion__c = refSLI.BizRegion__c;
                    sliUpdate.SettlementCurrency__c = detail.SettlementCurrency__c;
                    sliUpdate.FXRateOrigintoSettlement__c = detail.FXRateOrigintoSettlement__c;
                    sliUpdate.OtherCharges__c = otherCharges;
                    sliUpdate.NeedsVerification__c = detail.NeedsVerification__c;
                    sliUpdate.Remark__c = detail.Remarks__c;
                    sliUpdate.SettlementAmountSLI__c = rli.SettlementAmountSLI__c;
                    sliUpdate.SettlementAmountTTL__c = rli.SettlementAmountTTL__c;
                    sliUpdate.SettlementAmountPremium__c = rli.SettlementAmountPremium__c;
                    sliUpdate.SettlementDate__c = baseStmtRli.RefStatement__r?.TransactionDate__c;
                    sliUpdate.SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR;
                    sliUpdate.SettlementType__c = REC_Consts.SettlementType.NORMAL;
                    sliUpdate.Status__c = REC_Consts.STCStatus.CONFIRM;

                    // FXRateSettlementAccounting__c
                    //   IF SettlementCurrency == RefSLI.AccountingCurrency_fm__c THEN 1
                    //   ELSE FX.rate(SettlementDate, BizRegion, SettlementCurrency)
                    if (
                        detail.SettlementCurrency__c != null &&
                        detail.SettlementCurrency__c == refSLI.AccountingCurrency_fm__c
                    ) {
                        sliUpdate.FXRateSettlementAccounting__c = 1;
                    } else {
                        sliUpdate.FXRateSettlementAccounting__c = FX.rate(
                            baseStmtRli.RefStatement__r?.TransactionDate__c,
                            refSLI.BizRegion__c,
                            detail.SettlementCurrency__c
                        );
                    }
                    rli.FXRateSettlementAccounting__c = sliUpdate.FXRateSettlementAccounting__c;

                    slisToUpdate.add(sliUpdate);
                }
            }

            if (!rliToUpsert.isEmpty()) {
                upsert as system rliToUpsert;
            }
            if (!slisToUpdate.isEmpty()) {
                update as system slisToUpdate;
            }

            // ── 6. Validate & UPSERT: FO-referenced RLIs + FO UPDATE ────────
            List<ReconciliationLineItem__c> foRliToUpsert = new List<ReconciliationLineItem__c>();
            List<FiduciaryOthers__c> fosToUpdate = new List<FiduciaryOthers__c>();
            Decimal sumFoReconciledAmt = 0;
            if (!newFoRefs.isEmpty()) {
                String foFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(newFoRefs.keySet())).toJson();
                Map<Id, FiduciaryOthers__c> refFOs = new Map<Id, FiduciaryOthers__c>();
                for (SObject s : foSel.queryByFilter(foFilter)) {
                    FiduciaryOthers__c fo = (FiduciaryOthers__c) s;
                    refFOs.put(fo.Id, fo);
                }

                // Validate: ABS(INPUT.ReconciledAMT) ≤ ABS(NotReconciledAMT)
                List<REC_TableHelper.CellError> cellErrors = new List<REC_TableHelper.CellError>();
                for (Id foId : newFoRefs.keySet()) {
                    ReconciliationLineItem__c detail = newFoRefs.get(foId);
                    FiduciaryOthers__c refFO = refFOs.get(foId);
                    if (refFO == null)
                        continue;

                    Decimal ramt = detail.ReconciledAMT__c != null ? detail.ReconciledAMT__c : 0;
                    Decimal notReconciled = refFO.NotReconciledAMT__c != null
                        ? refFO.NotReconciledAMT__c
                        : (refFO.OriginAmount__c != null ? refFO.OriginAmount__c : 0);

                    if (!REC_FiduciaryOthersDomain.isReconciledAmountValid(ramt, notReconciled)) {
                        cellErrors.add(
                            new REC_TableHelper.CellError(
                                String.valueOf(foId),
                                'ReconciledAMT__c',
                                Label.REC_MSG_INVALID_RECONCILED_AMT
                            )
                        );
                    }
                }
                if (!cellErrors.isEmpty()) {
                    throw new REC_ValidationException(cellErrors);
                }

                // Build & upsert FO RLIs + update FO records
                for (Id foId : newFoRefs.keySet()) {
                    ReconciliationLineItem__c detail = newFoRefs.get(foId);
                    FiduciaryOthers__c refFO = refFOs.get(foId);
                    if (refFO == null)
                        continue;

                    Decimal ramt = detail.ReconciledAMT__c != null ? detail.ReconciledAMT__c : 0;

                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();

                    // Resolve Id (update existing or insert new)
                    ReconciliationLineItem__c existingFo = existingFoRefs.get(foId);
                    if (detail.Id != null && !String.valueOf(detail.Id).startsWith('_fo_temp')) {
                        rli.Id = detail.Id;
                    } else if (existingFo != null) {
                        rli.Id = existingFo.Id;
                    } else {
                        rli.RefReconciliation__c = reconciliationId;
                    }

                    rli.RefFiduciaryOthers__c = foId;
                    rli.BizRegion__c = refFO.BizRegion__c;
                    rli.BTAccountName__c = refFO.AccountName__c;
                    rli.ReconciledAMT__c = ramt;
                    rli.NotReconciledAMT__c =
                        (refFO.OriginAmount__c != null ? refFO.OriginAmount__c : 0) -
                        ((refFO.ReconciledAMT__c != null ? refFO.ReconciledAMT__c : 0) + ramt);

                    foRliToUpsert.add(rli);
                    sumFoReconciledAmt += ramt;

                    // ── Confirm-specific: FO UPDATE ──────────────────────────
                    REC_FiduciaryOthersDomain.applyReconciledAmount(refFO, ramt);
                    fosToUpdate.add(refFO);
                }

                upsert as system foRliToUpsert;
                update as system fosToUpdate;
            }

            // ── 7. P_C Other Charges — SLI INSERT + RLI UPSERT ──────────────
            String baseStmt_BizRegion = baseStmtRli.RefStatement__r?.BizRegion__c;
            Date baseStmt_TransactionDate = baseStmtRli.RefStatement__r?.TransactionDate__c;
            Decimal sumOtherChargesPC = 0;

            // P_C SLI INSERT
            List<SettlementLineItem__c> otherChargeSlis = new List<SettlementLineItem__c>();
            if (otherChargeRliItems != null && !otherChargeRliItems.isEmpty()) {
                for (ReconciliationLineItem__c item : otherChargeRliItems) {
                    Decimal originAmt = item.OriginAmount__c != null ? item.OriginAmount__c : 0;
                    SettlementLineItem__c sli = new SettlementLineItem__c();
                    sli.ClosingType__c = REC_Consts.ClosingType.P_C;
                    sli.BizRegion__c = baseStmt_BizRegion;
                    sli.OriginReconciliationNo__c = reconciliationId;
                    sli.ReconcileNo__c = reconciliationId;
                    sli.OriginSettlementLineItem__c = item.OriginSettlementLineItem__c;
                    sli.OriginBankTransaction__c = item.OriginBankTransaction__c;
                    sli.COA_lk__c = item.COA_lk__c;
                    sli.OriginCurrency__c = item.OriginCurrency__c;
                    sli.OriginAmount__c = originAmt;
                    sli.SettlementCurrency__c = item.SettlementCurrency__c;
                    sli.FXRateOrigintoSettlement__c = item.FXRateOrigintoSettlement__c;
                    sli.Remark__c = item.Remarks__c;
                    sli.SettlementDate__c = baseStmt_TransactionDate;
                    sli.AccountName__c = REC_Utils.getAccountIdByRegion(baseStmt_BizRegion);
                    sli.AccountingDate__c = Date.today();
                    sli.SettlementAmountSLI__c =
                        originAmt * (item.FXRateOrigintoSettlement__c != null ? item.FXRateOrigintoSettlement__c : 1);
                    sli.SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR;
                    sli.SettlementType__c = REC_Consts.SettlementType.NORMAL;
                    sli.Status__c = REC_Consts.STCStatus.CONFIRM;

                    otherChargeSlis.add(sli);
                    sumOtherChargesPC += originAmt;
                }
                insert as system otherChargeSlis;
            }

            // P_C RLI UPSERT
            List<ReconciliationLineItem__c> existingPcRlis = rliSel.queryPcRlisByRecon(reconciliationId);
            Map<Id, ReconciliationLineItem__c> existingPcMap = new Map<Id, ReconciliationLineItem__c>(existingPcRlis);
            Set<Id> incomingPcIds = new Set<Id>();
            List<ReconciliationLineItem__c> pcRliToUpsert = new List<ReconciliationLineItem__c>();

            if (otherChargeRliItems != null && !otherChargeRliItems.isEmpty()) {
                for (Integer i = 0; i < otherChargeRliItems.size(); i++) {
                    ReconciliationLineItem__c item = otherChargeRliItems[i];
                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();

                    if (item.Id != null && existingPcMap.containsKey(item.Id)) {
                        incomingPcIds.add(item.Id);
                        rli.Id = item.Id;
                    } else {
                        rli.RefReconciliation__c = reconciliationId;
                    }

                    // Assign the newly inserted SLI Id
                    rli.RefSettlementLineItem__c = otherChargeSlis[i].Id;
                    rli.ClosingType__c = REC_Consts.ClosingType.P_C;
                    rli.IsOtherCharges__c = true;
                    rli.BizRegion__c = baseStmt_BizRegion;
                    rli.COA_lk__c = item.COA_lk__c;
                    rli.OriginCurrency__c = item.OriginCurrency__c;
                    rli.OriginAmount__c = item.OriginAmount__c;
                    rli.OriginSettlementLineItem__c = item.OriginSettlementLineItem__c;
                    rli.OriginBankTransaction__c = item.OriginBankTransaction__c;
                    rli.SettlementCurrency__c = item.SettlementCurrency__c;
                    rli.FXRateOrigintoSettlement__c = item.FXRateOrigintoSettlement__c;
                    rli.SettlementDate__c = baseStmt_TransactionDate;
                    rli.Remarks__c = item.Remarks__c;

                    pcRliToUpsert.add(rli);
                }
            }

            // DELETE orphan P_C RLIs
            List<ReconciliationLineItem__c> pcToDelete = new List<ReconciliationLineItem__c>();
            for (ReconciliationLineItem__c ex : existingPcRlis) {
                if (!incomingPcIds.contains(ex.Id)) {
                    pcToDelete.add(ex);
                }
            }
            if (!pcToDelete.isEmpty()) {
                delete as system pcToDelete;
            }
            if (!pcRliToUpsert.isEmpty()) {
                upsert as system pcRliToUpsert;
            }

            // ── 8. Base Statement RLI UPDATE + Statement UPDATE ──────────────
            Decimal totalBrokerageAmt = baseStmtRli.RefStatement__r?.TotalBrokerageAMT__c != null
                ? baseStmtRli.RefStatement__r.TotalBrokerageAMT__c
                : 0;
            Decimal totalPremiumAmt = recalcTotalPremium != null
                ? recalcTotalPremium
                : (baseStmtRli.TotalPremiumAMT__c != null &&
                      baseStmtRli.TotalPremiumAMT__c != 0
                      ? baseStmtRli.TotalPremiumAMT__c
                      : (baseStmtRli.RefStatement__r?.TotalPremiumAMT__c != null
                            ? baseStmtRli.RefStatement__r.TotalPremiumAMT__c
                            : 0));

            ReconciliationLineItem__c baseUpdate = new ReconciliationLineItem__c(Id = baseStmtRli.Id);
            baseUpdate.ReconciledAMT__c = sumSettlementAmtTTL - sumOtherChargesPC;
            baseUpdate.NotReconciledAMT__c = totalBrokerageAmt - baseUpdate.ReconciledAMT__c;
            baseUpdate.MatchedPremiumAMT__c = sumSettlementAmtPremium;
            baseUpdate.NotMatchedPremiumAMT__c = totalPremiumAmt - baseUpdate.MatchedPremiumAMT__c;
            baseUpdate.MatchingStatus__c = 'Matched';
            baseUpdate.TotalPremiumAMT__c = totalPremiumAmt;
            if (baseStmtRliInput != null) {
                baseUpdate.Remarks__c = baseStmtRliInput.Remarks__c;
            }

            update as system baseUpdate;

            // Statement UPDATE
            Statement__c stmtUpdate = new Statement__c(Id = baseStmtRli.RefStatement__c);
            stmtUpdate.ReconciledAMT__c = baseUpdate.ReconciledAMT__c;
            stmtUpdate.NotReconciledAMT__c = baseUpdate.NotReconciledAMT__c;
            stmtUpdate.MatchedPremiumAMT__c = baseUpdate.MatchedPremiumAMT__c;
            stmtUpdate.NotMatchedPremiumAMT__c = baseUpdate.NotMatchedPremiumAMT__c;
            stmtUpdate.MatchingStatus__c = 'Matched';
            stmtUpdate.ReconciledStatus__c = REC_Consts.ReconciliationStatus.CONFIRMED;
            if (recalcTotalPremium != null) {
                stmtUpdate.TotalPremiumAMT__c = recalcTotalPremium;
            }
            if (baseStmtRliInput != null) {
                stmtUpdate.Remarks__c = baseStmtRliInput.Remarks__c;
            }

            update as system stmtUpdate;

            // ── 8.5. Bank Transaction UPDATE ─────────────────────────────────
            Id baseBtId = baseStmtRli.RefStatement__r?.RefBankTransaction__c;
            if (baseBtId != null) {
                REC_BankTransactionSelector btSel = REC_BankTransactionSelector.getInstance();
                List<BankTransaction__c> bts = btSel.queryForReconciliation(new Set<Id>{ baseBtId });
                if (!bts.isEmpty()) {
                    BankTransaction__c baseBt = bts[0];
                    Decimal stmtReconciledAmt = baseUpdate.ReconciledAMT__c != null ? baseUpdate.ReconciledAMT__c : 0;
                    Decimal prevTotalCleared = baseBt.TotalClearedAmount__c != null ? baseBt.TotalClearedAmount__c : 0;
                    Decimal newTotalCleared = prevTotalCleared + stmtReconciledAmt - sumFoReconciledAmt;
                    Decimal btOriginAmt = baseBt.OriginAmount__c != null ? baseBt.OriginAmount__c : 0;
                    Decimal netBalance = btOriginAmt - newTotalCleared;
                    String btStatus = REC_BankTransactionDomain.decideStatus(netBalance);

                    BankTransaction__c btUpdate = new BankTransaction__c(
                        Id = baseBtId,
                        TotalClearedAmount__c = newTotalCleared,
                        NetBalanceAftCleared__c = netBalance,
                        Status__c = btStatus
                    );
                    update as system btUpdate;
                }
            }

            // ── 9. Reconciliation UPDATE ─────────────────────────────────────
            confirm(reconciliationId, baseStmtCurrency);

            // ── 10. Post-Action Validation ───────────────────────────────────
            if (baseUpdate.NotMatchedPremiumAMT__c != 0 || baseUpdate.NotReconciledAMT__c != 0) {
                Database.rollback(sp);
                throw new REC_ReconciliationDomainException('대사 금액이 일치하지 않아 Confirm할 수 없습니다.');
            }

            // ── 11. Enqueue NoteAmount Evaluation ────────────────────────────
            Set<Id> evaluationSliIds = new Set<Id>();
            for (SettlementLineItem__c s : slisToUpdate) {
                evaluationSliIds.add(s.Id);
            }
            if (!evaluationSliIds.isEmpty()) {
                System.enqueueJob(new REC_NoteAmountEvaluationQueueable(evaluationSliIds));
            }
        } catch (Exception e) {
            Database.rollback(sp);
            if (e instanceof REC_ReconciliationDomainException || e instanceof REC_ValidationException) {
                throw e;
            }
            throw new REC_ReconciliationDomainException(
                'Error confirming statement based reconciliation: ' + e.getMessage()
            );
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  BT-Based Draft
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Draft operation for BT-based reconciliation.
     * Creates/updates/deletes SLI-referenced RLIs and updates the base BT RLI.
     *
     * Draft only updates RLI records — does NOT update referenced SLI or BT records.
     *
     * BaseBt.TotalClearedAmount__c = sum of Selected SettlementAmountTTL - sum of P_C OtherCharges
     *
     * @param reconciliationId    Parent Reconciliation Id
     * @param details             SLI-referenced RLIs with user-entered FXRateOrigintoSettlement__c
     * @param otherChargeRliItems P_C Other Charges RLI rows from the table (nullable)
     * @return                    Upserted SLI-referenced RLIs
     */
    public static String draftBankTransactionBased(
        String reconciliationId,
        List<ReconciliationLineItem__c> details,
        List<ReconciliationLineItem__c> otherChargeRliItems
    ) {
        SavePoint sp = Database.setSavepoint();

        try {
            if (String.isBlank(reconciliationId)) {
                throw new REC_ReconciliationDomainException('Reconciliation Id is required');
            }

            REC_ReconciliationLineItemSelector rliSel = REC_ReconciliationLineItemSelector.getInstance();
            REC_SettlementLineItemSelector sliSel = REC_SettlementLineItemSelector.getInstance();

            // ── 1. Fetch existing RLIs ───────────────────────────────────────
            List<ReconciliationLineItem__c> rliExisting = rliSel.queryForBtBasedDraft(reconciliationId);

            if (rliExisting.isEmpty()) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_RLI_NOT_FOUND);
            }

            // ── 2. Categorise existing RLIs ──────────────────────────────────
            ReconciliationLineItem__c baseBtRli;
            Map<Id, ReconciliationLineItem__c> existingSliRefs = new Map<Id, ReconciliationLineItem__c>();

            for (ReconciliationLineItem__c rli : rliExisting) {
                if (rli.RefBankTransaction__c != null) {
                    baseBtRli = rli;
                } else if (rli.RefSettlementLineItem__c != null) {
                    existingSliRefs.put(rli.RefSettlementLineItem__c, rli);
                }
            }

            if (baseBtRli == null) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_BASE_BT_RLI_NOT_FOUND);
            }

            // ── 3. Build new SLI refs from details ───────────────────────────
            Map<Id, ReconciliationLineItem__c> newSliRefs = new Map<Id, ReconciliationLineItem__c>();
            if (details != null) {
                for (ReconciliationLineItem__c detail : details) {
                    if (detail.RefSettlementLineItem__c != null) {
                        newSliRefs.put(detail.RefSettlementLineItem__c, detail);
                    }
                }
            }

            // ── 4. DELETE: RLIs that exist but are no longer in new set ─────
            List<ReconciliationLineItem__c> orphans = new List<ReconciliationLineItem__c>();
            for (ReconciliationLineItem__c rli : rliExisting) {
                if (rli.RefSettlementLineItem__c != null && !newSliRefs.containsKey(rli.RefSettlementLineItem__c)) {
                    orphans.add(rli);
                }
            }
            if (!orphans.isEmpty()) {
                delete as system orphans;
            }

            // ── 5. Handle empty details → clear base BT RLI ─────────────────
            if (details == null || details.isEmpty()) {
                ReconciliationLineItem__c clearBtRli = new ReconciliationLineItem__c(Id = baseBtRli.Id);
                clearBtRli.TotalClearedAmount__c = 0;
                clearBtRli.NetAmountAfterClearing__c = baseBtRli.RefBankTransaction__r?.NetBalanceAftCleared__c;
                update as system clearBtRli;
                processPcRlis(reconciliationId, otherChargeRliItems);
                setDraft(reconciliationId);
                return null;
            }

            // ── 6. Re-query referenced SLIs from DB ─────────────────────────
            String sliFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(newSliRefs.keySet())).toJson();
            Map<Id, SettlementLineItem__c> refSLIs = new Map<Id, SettlementLineItem__c>();
            for (SObject s : sliSel.queryByFilter(sliFilter)) {
                SettlementLineItem__c sli = (SettlementLineItem__c) s;
                refSLIs.put(sli.Id, sli);
            }

            // ── 6.5. Validate Detail SLI Status__c ────────────────────────
            for (SettlementLineItem__c refSLI : refSLIs.values()) {
                if (refSLI.Status__c != REC_Consts.STCStatus.CONFIRM) {
                    throw new REC_ReconciliationDomainException(Label.REC_MSG_INVALID_SLI_STATUS);
                }
            }

            // ── 6.6. Validate SettlementType__c ─────────────────────────────
            List<REC_TableHelper.CellError> validationErrors = REC_SettlementLineItemDomain.validateSettlementType(
                newSliRefs,
                refSLIs
            );
            if (!validationErrors.isEmpty()) {
                Database.rollback(sp);
                throw new REC_ValidationException(validationErrors);
            }

            // ── 7. UPSERT: SLI-referenced RLIs with calculated fields ───────
            List<ReconciliationLineItem__c> rliToUpsert = new List<ReconciliationLineItem__c>();
            Decimal sumSettlementAmtTTL = 0;
            Date baseBtTransactionDate = baseBtRli.RefBankTransaction__r?.TransactionDate__c;

            for (Id sliId : newSliRefs.keySet()) {
                ReconciliationLineItem__c detail = newSliRefs.get(sliId);
                SettlementLineItem__c refSLI = refSLIs.get(sliId);
                if (refSLI == null) {
                    continue;
                }

                ReconciliationLineItem__c rli = new ReconciliationLineItem__c();

                // Resolve Id (update existing or insert new)
                ReconciliationLineItem__c existing = existingSliRefs.get(sliId);
                if (detail.Id != null && !String.valueOf(detail.Id).startsWith('_temp')) {
                    rli.Id = detail.Id;
                } else if (existing != null) {
                    rli.Id = existing.Id;
                } else {
                    rli.RefReconciliation__c = reconciliationId;
                }

                rli.RefSettlementLineItem__c = sliId;
                rli.BizRegion__c = refSLI.BizRegion__c;

                // 4-1-a. SettlementDate__c = Base BT's TransactionDate__c
                rli.SettlementDate__c = baseBtTransactionDate;

                // SettlementCurrency__c = from BT base currency
                rli.SettlementCurrency__c = baseBtRli.RefBankTransaction__r?.Currency__c;

                // FXRate: use user input directly
                rli.FXRateOrigintoSettlement__c = detail.FXRateOrigintoSettlement__c;

                // 4-1-b. SettlementAmountSLI__c = round(RefSLI.OriginAmount__c * RLI.FXRateOrigintoSettlement__c, ccy)
                rli.SettlementAmountSLI__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                    refSLI.OriginAmount__c,
                    rli.FXRateOrigintoSettlement__c,
                    rli.SettlementCurrency__c
                );

                // OtherCharges: use user input directly (null → 0 for calculation)
                Decimal otherCharges = detail.OtherCharges__c != null ? detail.OtherCharges__c : 0;
                rli.OtherCharges__c = otherCharges;

                // 4-1-c. SettlementAmountTTL__c = round(SettlementAmountSLI − OtherCharges, ccy)
                rli.SettlementAmountTTL__c = REC_SettlementLineItemDomain.calculateDetailTTL(
                    rli.SettlementAmountSLI__c,
                    rli.OtherCharges__c,
                    rli.SettlementCurrency__c
                );

                // ── User-entered fields: use detail values directly ──
                rli.SettlementType__c = detail.SettlementType__c;
                rli.RemittanceOnHold__c = detail.RemittanceOnHold__c;
                rli.HoldReason__c = detail.HoldReason__c;
                rli.ExchangeDate__c = detail.ExchangeDate__c;
                rli.ExchangeCurrency__c = detail.ExchangeCurrency__c;
                rli.ExchangeAmount__c = detail.ExchangeAmount__c;
                rli.ExchangeRate__c = detail.ExchangeRate__c;

                rliToUpsert.add(rli);
                sumSettlementAmtTTL += (rli.SettlementAmountTTL__c != null ? rli.SettlementAmountTTL__c : 0);
            }

            upsert as system rliToUpsert;

            // ── 7.5. Process P_C Other Charges RLIs ─────────────────────────
            Decimal sumOtherChargesPC = processPcRlis(reconciliationId, otherChargeRliItems);

            // ── 8. Update Base BT RLI ────────────────────────────────────────
            Decimal btOriginAmt = baseBtRli.RefBankTransaction__r?.OriginAmount__c != null
                ? baseBtRli.RefBankTransaction__r.OriginAmount__c
                : 0;
            Decimal btNetBalance = baseBtRli.RefBankTransaction__r?.NetBalanceAftCleared__c != null
                ? baseBtRli.RefBankTransaction__r.NetBalanceAftCleared__c
                : btOriginAmt;

            // Build a clean SObject to avoid FLS issues with non-updateable fields (e.g. RefReconciliation__c)
            ReconciliationLineItem__c baseBtRliUpdate = new ReconciliationLineItem__c(Id = baseBtRli.Id);
            // TotalClearedAmount__c = sum of Selected SettlementAmountTTL - sum of P_C OtherCharges
            baseBtRliUpdate.TotalClearedAmount__c = sumSettlementAmtTTL - sumOtherChargesPC;
            // NetAmountAfterClearing__c = BaseBT.NetBalanceAftCleared__c - TotalClearedAmount__c
            baseBtRliUpdate.NetAmountAfterClearing__c = btNetBalance - baseBtRliUpdate.TotalClearedAmount__c;
            // BTStatus__c
            baseBtRliUpdate.BTStatus__c = REC_BankTransactionDomain.decideStatus(baseBtRliUpdate.NetAmountAfterClearing__c);

            // ── 8.5. Validate Reconciled Amount ─────────────────────────────
            Boolean isValid = isReconciledAmountValid(btOriginAmt, baseBtRliUpdate.TotalClearedAmount__c, btNetBalance);

            update as system baseBtRliUpdate;

            // ── 9. Set Reconciliation status to Draft ───────────────────────
            setDraft(reconciliationId);

            return isValid ? null : Label.REC_MSG_INVALID_RECONCILED_AMT;
        } catch (Exception e) {
            Database.rollback(sp);
            if (e instanceof REC_ReconciliationDomainException || e instanceof REC_ValidationException) {
                throw e;
            }
            throw new REC_ReconciliationDomainException(
                'Error drafting bank transaction based reconciliation: ' + '[' + e.getTypeName() + '] ' + e.getMessage()
            );
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  BT-Based Confirm
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Confirm operation for BT-based reconciliation.
     * Includes Draft logic (RLI upsert/delete) AND actual updates to:
     *   - Detail Settlement Line Items (user-entered + calculated fields)
     *   - Counterpart SLIs (OtherCharges negation + Available status)
     *   - Base Bank Transaction (TotalClearedAmount, NetBalanceAftCleared, Status)
     *   - Other Charges (P_C SLIs) — created only at Confirm
     *
     * @param reconciliationId    Parent Reconciliation Id
     * @param details             SLI-referenced RLIs with user-entered fields
     * @param otherChargeItems    Other Charges table rows (P_C Settlement Line Items)
     * @param otherChargeRliItems P_C Other Charges RLI rows from the table (nullable)
     */
    public static String confirmBankTransactionBased(
        String reconciliationId,
        List<ReconciliationLineItem__c> details,
        List<SettlementLineItem__c> otherChargeItems,
        List<ReconciliationLineItem__c> otherChargeRliItems
    ) {
        SavePoint sp = Database.setSavepoint();

        try {
            if (String.isBlank(reconciliationId)) {
                throw new REC_ReconciliationDomainException('Reconciliation Id is required');
            }
            if (details == null || details.isEmpty()) {
                throw new REC_ReconciliationDomainException('Selected items are required for confirmation');
            }

            REC_ReconciliationLineItemSelector rliSel = REC_ReconciliationLineItemSelector.getInstance();
            REC_SettlementLineItemSelector sliSel = REC_SettlementLineItemSelector.getInstance();
            REC_BankTransactionSelector btSel = REC_BankTransactionSelector.getInstance();

            // ── 1. Fetch existing RLIs ───────────────────────────────────────
            List<ReconciliationLineItem__c> rliExisting = rliSel.queryForBtBasedDraft(reconciliationId);

            if (rliExisting.isEmpty()) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_RLI_NOT_FOUND);
            }

            // ── 2. Categorise existing RLIs ──────────────────────────────────
            ReconciliationLineItem__c baseBtRli;
            Map<Id, ReconciliationLineItem__c> existingSliRefs = new Map<Id, ReconciliationLineItem__c>();

            for (ReconciliationLineItem__c rli : rliExisting) {
                if (rli.RefBankTransaction__c != null) {
                    baseBtRli = rli;
                } else if (rli.RefSettlementLineItem__c != null) {
                    existingSliRefs.put(rli.RefSettlementLineItem__c, rli);
                }
            }

            if (baseBtRli == null) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_BASE_BT_RLI_NOT_FOUND);
            }

            // ── 3. Build new SLI refs from details ───────────────────────────
            Map<Id, ReconciliationLineItem__c> newSliRefs = new Map<Id, ReconciliationLineItem__c>();
            for (ReconciliationLineItem__c detail : details) {
                if (detail.RefSettlementLineItem__c != null) {
                    newSliRefs.put(detail.RefSettlementLineItem__c, detail);
                }
            }

            // ── 4. DELETE: orphaned RLIs ─────────────────────────────────────
            List<ReconciliationLineItem__c> orphans = new List<ReconciliationLineItem__c>();
            for (ReconciliationLineItem__c rli : rliExisting) {
                if (rli.RefSettlementLineItem__c != null && !newSliRefs.containsKey(rli.RefSettlementLineItem__c)) {
                    orphans.add(rli);
                }
            }
            if (!orphans.isEmpty()) {
                delete as system orphans;
            }

            // ── 5. Re-query referenced SLIs from DB ─────────────────────────
            String sliFilter = REC_TableHelper.filter().isIn('Id', new List<Id>(newSliRefs.keySet())).toJson();
            Map<Id, SettlementLineItem__c> refSLIs = new Map<Id, SettlementLineItem__c>();
            for (SObject s : sliSel.queryByFilter(sliFilter)) {
                SettlementLineItem__c sli = (SettlementLineItem__c) s;
                refSLIs.put(sli.Id, sli);
            }

            // ── 6. Re-query Base BT from DB ──────────────────────────────────
            Id baseBtId = baseBtRli.RefBankTransaction__c;
            String btFilter = REC_TableHelper.filter().isIn('Id', new List<Id>{ baseBtId }).toJson();
            BankTransaction__c baseBt;
            for (SObject s : btSel.queryByFilter(btFilter)) {
                baseBt = (BankTransaction__c) s;
            }
            if (baseBt == null) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_BASE_BT_NOT_FOUND);
            }

            Date baseBtTransactionDate = baseBt.TransactionDate__c;
            String baseBtCurrency = baseBt.Currency__c;
            String baseBtBizRegion = baseBt.BizRegion__c;

            // ── 6.5. Validate Detail SLI Status__c ────────────────────────
            for (SettlementLineItem__c refSLI : refSLIs.values()) {
                if (refSLI.Status__c != REC_Consts.STCStatus.CONFIRM) {
                    throw new REC_ReconciliationDomainException(Label.REC_MSG_INVALID_SLI_STATUS);
                }
            }

            // ── 6.6. Validate SettlementType__c ─────────────────────────────
            List<REC_TableHelper.CellError> validationErrors = REC_SettlementLineItemDomain.validateSettlementType(
                newSliRefs,
                refSLIs
            );
            if (!validationErrors.isEmpty()) {
                Database.rollback(sp);
                throw new REC_ValidationException(validationErrors);
            }

            // ── 7. UPSERT: SLI-referenced RLIs (same as Draft) ──────────────
            List<ReconciliationLineItem__c> rliToUpsert = new List<ReconciliationLineItem__c>();
            Decimal sumSettlementAmtTTL = 0;

            // Also collect SLIs to update
            List<SettlementLineItem__c> slisToUpdate = new List<SettlementLineItem__c>();

            for (Id sliId : newSliRefs.keySet()) {
                ReconciliationLineItem__c detail = newSliRefs.get(sliId);
                SettlementLineItem__c refSLI = refSLIs.get(sliId);
                if (refSLI == null) {
                    continue;
                }

                ReconciliationLineItem__c rli = new ReconciliationLineItem__c();

                // Resolve Id (update existing or insert new)
                ReconciliationLineItem__c existing = existingSliRefs.get(sliId);
                if (detail.Id != null && !String.valueOf(detail.Id).startsWith('_temp')) {
                    rli.Id = detail.Id;
                } else if (existing != null) {
                    rli.Id = existing.Id;
                } else {
                    rli.RefReconciliation__c = reconciliationId;
                }

                rli.RefSettlementLineItem__c = sliId;
                rli.BizRegion__c = refSLI.BizRegion__c;
                rli.SettlementDate__c = baseBtTransactionDate;
                rli.SettlementCurrency__c = baseBtCurrency;

                // FXRate: user input
                rli.FXRateOrigintoSettlement__c = detail.FXRateOrigintoSettlement__c;

                // SettlementAmountSLI__c = round(SLI.OriginAmount__c * RLI.FXRateOrigintoSettlement__c, ccy)
                rli.SettlementAmountSLI__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                    refSLI.OriginAmount__c,
                    rli.FXRateOrigintoSettlement__c,
                    rli.SettlementCurrency__c
                );

                // OtherCharges: user input
                Decimal otherChargesVal = detail.OtherCharges__c != null ? detail.OtherCharges__c : 0;
                rli.OtherCharges__c = otherChargesVal;

                // SettlementAmountTTL__c = round(SettlementAmountSLI − OtherCharges, ccy)
                rli.SettlementAmountTTL__c = REC_SettlementLineItemDomain.calculateDetailTTL(
                    rli.SettlementAmountSLI__c,
                    rli.OtherCharges__c,
                    rli.SettlementCurrency__c
                );

                // User-entered fields
                rli.SettlementType__c = detail.SettlementType__c;
                rli.RemittanceOnHold__c = detail.RemittanceOnHold__c;
                rli.HoldReason__c = detail.HoldReason__c;
                rli.ExchangeDate__c = detail.ExchangeDate__c;
                rli.ExchangeCurrency__c = detail.ExchangeCurrency__c;
                rli.ExchangeAmount__c = detail.ExchangeAmount__c;
                rli.ExchangeRate__c = detail.ExchangeRate__c;

                rliToUpsert.add(rli);
                sumSettlementAmtTTL += (rli.SettlementAmountTTL__c != null ? rli.SettlementAmountTTL__c : 0);

                // ── Detail SLI update ────────────────────────────────────────
                SettlementLineItem__c sliUpdate = new SettlementLineItem__c(Id = sliId);
                sliUpdate.ReconcileNo__c = reconciliationId;
                sliUpdate.SettlementDate__c = baseBtTransactionDate;
                sliUpdate.SettlementCurrency__c = baseBtCurrency;
                sliUpdate.OtherCharges__c = otherChargesVal;
                sliUpdate.SettlementAmountSLI__c = rli.SettlementAmountSLI__c;
                sliUpdate.SettlementAmountTTL__c = rli.SettlementAmountTTL__c;
                sliUpdate.SettlementType__c = detail.SettlementType__c;
                sliUpdate.RemittanceOnHold__c = detail.RemittanceOnHold__c;
                sliUpdate.HoldReason__c = detail.HoldReason__c;
                sliUpdate.ExchangeDate__c = detail.ExchangeDate__c;
                sliUpdate.ExchangeCurrency__c = detail.ExchangeCurrency__c;
                sliUpdate.ExchangeAmount__c = detail.ExchangeAmount__c;
                sliUpdate.ExchangeRate__c = detail.ExchangeRate__c;
                sliUpdate.SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR; // All SLIs from details are considered cleared at confirmation
                sliUpdate.FXRateOrigintoSettlement__c = rli.FXRateOrigintoSettlement__c;
                sliUpdate.FXRateSettlementAccounting__c = FX.rate(
                    baseBtTransactionDate,
                    refSLI.BizRegion__c,
                    baseBtCurrency
                );

                // Assign same FXRateSettlementAccounting to the RLI
                rli.FXRateSettlementAccounting__c = sliUpdate.FXRateSettlementAccounting__c;

                // Funded SLIs: triggers Funded P_C creation via trigger handler

                slisToUpdate.add(sliUpdate);
            }

            upsert as system rliToUpsert;

            // ── 7.5. Early reconciled amount validation ──────────────────────
            Decimal earlyOtherChargesPC = 0;
            if (otherChargeItems != null) {
                for (SettlementLineItem__c oci : otherChargeItems) {
                    earlyOtherChargesPC += (oci.OriginAmount__c != null ? oci.OriginAmount__c : 0);
                }
            }
            Decimal earlyReconCleared = sumSettlementAmtTTL - earlyOtherChargesPC;
            Decimal earlyBtOriginAmt = baseBt.OriginAmount__c != null ? baseBt.OriginAmount__c : 0;
            Decimal earlyBtNetBalance = baseBt.NetBalanceAftCleared__c != null
                ? baseBt.NetBalanceAftCleared__c
                : earlyBtOriginAmt;

            if (!isReconciledAmountValid(earlyBtOriginAmt, earlyReconCleared, earlyBtNetBalance)) {
                // Validation failed → fall back to Draft (skip Confirm-specific DML)
                Decimal pcSum = processPcRlis(reconciliationId, otherChargeRliItems);
                Decimal draftReconCleared = sumSettlementAmtTTL - pcSum;

                ReconciliationLineItem__c draftBtRliUpdate = new ReconciliationLineItem__c(Id = baseBtRli.Id);
                draftBtRliUpdate.TotalClearedAmount__c = draftReconCleared;
                draftBtRliUpdate.NetAmountAfterClearing__c = earlyBtNetBalance - draftReconCleared;
                draftBtRliUpdate.BTStatus__c = REC_BankTransactionDomain.decideStatus(
                    draftBtRliUpdate.NetAmountAfterClearing__c
                );
                update as system draftBtRliUpdate;

                setDraft(reconciliationId);
                return Label.REC_MSG_INVALID_RECONCILED_AMT;
            }

            // ── Proceed with full Confirm ─────────────────────────────────────
            update as system slisToUpdate;

            // Collect Funded SLI IDs for Step 8 exclusion
            Set<Id> fundedSliIds = new Set<Id>();
            for (Id sliId : newSliRefs.keySet()) {
                ReconciliationLineItem__c detail = newSliRefs.get(sliId);
                if (detail.SettlementType__c == REC_Consts.SettlementType.FUNDED) {
                    System.debug('Funded:: ' + sliId);
                    fundedSliIds.add(sliId);
                }
            }

            // ── 8. Counterpart SLIs ──────────────────────────────────────────
            // Only non-P_C, non-Funded SLIs have counterparts processed here.
            // Funded SLIs are handled by the SettlementLineItem trigger handler.
            List<Id> nonPcSliIds = new List<Id>();
            for (Id sliId : newSliRefs.keySet()) {
                SettlementLineItem__c refSLI = refSLIs.get(sliId);
                if (refSLI != null && refSLI.ClosingType__c != REC_Consts.ClosingType.P_C && !fundedSliIds.contains(sliId)) {
                    nonPcSliIds.add(sliId);
                }
            }

            if (!nonPcSliIds.isEmpty()) {
                try {
                    Map<Id, SettlementLineItem__c> counterMap = REC_SettlementLineItemDomain.searchCounterparts(nonPcSliIds);
                    List<SettlementLineItem__c> counterUpdates = new List<SettlementLineItem__c>();

                    for (Id sliId : nonPcSliIds) {
                        if (!counterMap.containsKey(sliId)) {
                            String sliName = refSLIs.get(sliId)?.Name ?? String.valueOf(sliId);

                            throw new REC_ReconciliationDomainException(
                                String.format(Label.REC_MSG_SLI_CPTY_NOT_FOUND, new List<String>{ sliName })
                            );
                        }

                        SettlementLineItem__c counterSli = counterMap.get(sliId);
                        ReconciliationLineItem__c detail = newSliRefs.get(sliId);
                        SettlementLineItem__c originSli = refSLIs.get(sliId);

                        // Use user-input SettlementType for Case determination
                        String settlementType = detail.SettlementType__c;
                        Decimal originAmount = originSli.OriginAmount__c;

                        Boolean isCase1Or2 = REC_SettlementLineItemDomain.isCounterpartCase1Or2(
                            settlementType,
                            originAmount,
                            counterSli
                        );

                        SettlementLineItem__c counterUpdate = new SettlementLineItem__c(Id = counterSli.Id);

                        if (isCase1Or2) {
                            // Case 1 OR Case 2: main field updates
                            Decimal sliOtherCharges = detail.OtherCharges__c != null ? detail.OtherCharges__c : 0;
                            counterUpdate.OtherCharges__c = (-1) * sliOtherCharges;
                            counterUpdate.SettlementStatus__c = REC_Consts.SettlementStatus.AVAILABLE;
                            counterUpdate.SettlementType__c = settlementType;
                            counterUpdate.SettlementCurrency__c = originSli.SettlementCurrency__c;
                            counterUpdate.FXRateOrigintoSettlement__c = originSli.FXRateOrigintoSettlement__c;

                            // (Case 1 OR Case 2) AND Case 4: DueDate update
                            // Use post-update state: SettlementStatus = Clear (set in Step 7)
                            SettlementLineItem__c originForDueDate = new SettlementLineItem__c();
                            originForDueDate.OriginAmount__c = originSli.OriginAmount__c;
                            originForDueDate.Status__c = originSli.Status__c;
                            originForDueDate.SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR;

                            if (REC_SettlementLineItemDomain.isDueDateUpdatable(originForDueDate, counterSli)) {
                                counterUpdate.DueDate__c = REC_Utils.getBusinessDay(
                                    originSli.BizRegion__c,
                                    originSli.SettlementDateCounterparty__c ?? Date.today(),
                                    10
                                );
                            }
                        } else {
                            // Case 3: NOT Case1 AND NOT Case2
                            counterUpdate.SettlementDateCounterparty__c = baseBtTransactionDate;
                        }

                        counterUpdates.add(counterUpdate);
                    }

                    if (!counterUpdates.isEmpty()) {
                        update as system counterUpdates;
                    }
                } catch (REC_SettlementLineItemDomain.REC_SettlementLineItemDomainException e) {
                    Logger.error('Counterpart search failed: ' + e.getMessage(), e);
                    Logger.saveLog();
                    throw new REC_ReconciliationDomainException(e.getMessage());
                }
            }

            // ── 9. Other Charges (P_C Settlement Line Items) ─────────────────
            // Confirmed Reconciliations have all actions disabled, so no existing
            // P_C SLIs can exist at this point — skip delete and insert fresh.
            Decimal sumOtherChargesPC = 0;

            if (otherChargeItems != null && !otherChargeItems.isEmpty()) {
                // Query RefSettlement__c from OriginSettlementLineItem for each P_C SLI
                Map<Id, SettlementLineItem__c> originSliMap = queryOriginSliRefSettlement(otherChargeItems);

                for (SettlementLineItem__c oci : otherChargeItems) {
                    oci.OriginReconciliationNo__c = reconciliationId;
                    oci.ClosingType__c = REC_Consts.ClosingType.P_C;
                    oci.OriginCurrency__c = baseBtCurrency;
                    oci.AccountingDate__c = baseBtTransactionDate;
                    oci.BizRegion__c = baseBtBizRegion;
                    oci.AccountName__c = REC_Utils.getAccountIdByRegion(baseBtBizRegion);
                    oci.Status__c = REC_Consts.STCStatus.CONFIRM;
                    oci.OriginalFXRateDate__c = oci.AccountingDate__c;
                    oci.SendtoCloseDate__c = oci.AccountingDate__c;
                    // User Input
                    oci.COA_lk__c = oci.COA_lk__c;
                    oci.OriginAmount__c = oci.OriginAmount__c;
                    oci.OriginSettlementLineItem__c = oci.OriginSettlementLineItem__c;
                    oci.OriginBankTransaction__c = oci.OriginBankTransaction__c;
                    oci.Remark__c = oci.Remark__c;
                    if (
                        oci.OriginSettlementLineItem__c != null && originSliMap.containsKey(oci.OriginSettlementLineItem__c)
                    ) {
                        oci.RefSettlement__c = originSliMap.get(oci.OriginSettlementLineItem__c).RefSettlement__c;
                    }

                    sumOtherChargesPC += (oci.OriginAmount__c != null ? oci.OriginAmount__c : 0);
                }
                insert as system otherChargeItems;
            }

            // ── 9.5. P_C Other Charges RLIs ─────────────────────────────────
            processPcRlis(reconciliationId, otherChargeRliItems);

            // ── 10. Update Base Bank Transaction ─────────────────────────────
            Decimal thisReconCleared = sumSettlementAmtTTL - sumOtherChargesPC;
            Decimal btOriginAmt = baseBt.OriginAmount__c != null ? baseBt.OriginAmount__c : 0;
            Decimal prevTotalCleared = baseBt.TotalClearedAmount__c != null ? baseBt.TotalClearedAmount__c : 0;
            // BaseBT.TotalClearedAmount = existing + this reconciliation's cleared amount
            Decimal newTotalCleared = prevTotalCleared + thisReconCleared;
            // BaseBT.NetBalanceAftCleared = OriginAmount - TotalClearedAmount (after accumulation)
            Decimal netBalance = btOriginAmt - newTotalCleared;
            // Status
            String btStatus = REC_BankTransactionDomain.decideStatus(netBalance);

            BankTransaction__c btUpdate = new BankTransaction__c(
                Id = baseBtId,
                TotalClearedAmount__c = newTotalCleared,
                NetBalanceAftCleared__c = netBalance,
                Status__c = btStatus
            );
            update as system btUpdate;

            // ── 11. Update Base BT RLI ───────────────────────────────────────
            ReconciliationLineItem__c baseBtRliUpdate = new ReconciliationLineItem__c(Id = baseBtRli.Id);
            // RLI stores this reconciliation's cleared amount (not cumulative)
            baseBtRliUpdate.TotalClearedAmount__c = thisReconCleared;
            // RLI.NetAmountAfterClearing = BaseBT.NetBalanceAftCleared (before) - this recon cleared
            baseBtRliUpdate.NetAmountAfterClearing__c = earlyBtNetBalance - thisReconCleared;
            baseBtRliUpdate.BTStatus__c = btStatus;
            update as system baseBtRliUpdate;

            // ── 12. Set Reconciliation Status to Confirmed ───────────────────
            confirm(reconciliationId, baseBtCurrency);

            // ── 13. Enqueue NoteAmount Evaluation ────────────────────────────
            Set<Id> evaluationSliIds = new Set<Id>();
            for (SettlementLineItem__c s : slisToUpdate) {
                evaluationSliIds.add(s.Id);
            }
            if (!evaluationSliIds.isEmpty()) {
                System.enqueueJob(new REC_NoteAmountEvaluationQueueable(evaluationSliIds));
            }

            Logger.saveLog();
            return null;
        } catch (Exception e) {
            Database.rollback(sp);
            if (e instanceof REC_ReconciliationDomainException || e instanceof REC_ValidationException) {
                throw e;
            }

            String errorMessage =
                'Error confirming bank transaction based reconciliation: ' +
                '[' +
                e.getTypeName() +
                '] ' +
                e.getMessage();

            Logger.error(errorMessage, e);
            Logger.saveLog();

            throw new REC_ReconciliationDomainException(errorMessage);
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Reverse Offset
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Processes Reverse Offset for the given Settlement Line Item IDs.
     * Called after Reversing is complete — expects both Reversed and Reversing SLI Ids.
     *
     * 1. Creates a new Reconciliation__c (Status = 'Confirm')
     * 2. Updates all SLIs with calculated settlement fields
     * 3. Creates junction ReconciliationLineItem__c records
     *
     * @param sliIds  List of Reversed and Reversing Settlement Line Item Ids
     * @return        Id of the newly created Reconciliation__c
     */
    public static Id processReverseOffset(List<Id> sliIds) {
        if (sliIds == null || sliIds.isEmpty()) {
            throw new REC_ReconciliationDomainException('Settlement Line Item IDs cannot be null or empty.');
        }

        Savepoint sp = Database.setSavepoint();
        try {
            ExceptionSimulator.throwIfActive();
            // ── 1. Query SLIs with all required fields ───────────────────
            List<SettlementLineItem__c> sliList = (List<SettlementLineItem__c>) REC_SettlementLineItemSelector.getInstance()
                .queryByIds(new Set<Id>(sliIds));

            if (sliList.isEmpty()) {
                throw new REC_ReconciliationDomainException(Label.REC_MSG_SLI_NOT_FOUND);
            }

            // ── 2. Create Reconciliation ─────────────────────────────────
            Reconciliation__c newRecon = new Reconciliation__c();
            newRecon.ReconciledDate__c = Date.today();
            newRecon.Status__c = REC_Consts.ReconciliationStatus.CONFIRMED;
            newRecon.BizRegion__c = sliList[0].BizRegion__c;

            Database.SaveResult reconSr = Database.insert(newRecon);
            if (!reconSr.isSuccess()) {
                throw new REC_ReconciliationDomainException(formatDmlErrors(reconSr));
            }
            Id reconId = reconSr.getId();

            // ── 3. Update Settlement Line Items ──────────────────────────
            Map<Id, SettlementLineItem__c> updatedSliMap = new Map<Id, SettlementLineItem__c>();
            List<SettlementLineItem__c> slisToUpdate = new List<SettlementLineItem__c>();

            for (SettlementLineItem__c sli : sliList) {
                SettlementLineItem__c sliUpdate = new SettlementLineItem__c(Id = sli.Id);
                sliUpdate.ReconcileNo__c = reconId;
                sliUpdate.SettlementDate__c = Date.today();
                sliUpdate.SettlementCurrency__c = sli.OriginCurrency__c;
                sliUpdate.FXRateOrigintoSettlement__c = 1;
                sliUpdate.FXRateSettlementAccounting__c = sli.AccountingFXRate__c;
                sliUpdate.SettlementDateCounterparty__c = Date.today();

                sliUpdate.SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR;
                sliUpdate.SettlementType__c = REC_Consts.SettlementType.OFFSET;

                sliUpdate.SettlementAmountSLI__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                    sli.OriginAmount__c,
                    sliUpdate.FXRateOrigintoSettlement__c,
                    sli.OriginCurrency__c
                );

                sliUpdate.OtherCharges__c = 0;
                sliUpdate.SettlementAmountTTL__c = REC_SettlementLineItemDomain.calculateSettlementAmountTTL(
                    sliUpdate.SettlementAmountSLI__c,
                    sliUpdate.OtherCharges__c,
                    sli.OriginCurrency__c
                );

                slisToUpdate.add(sliUpdate);
                updatedSliMap.put(sli.Id, sliUpdate);
            }

            update as system slisToUpdate;

            // ── 4. Create Reconciliation Line Items (junction) ───────────
            List<ReconciliationLineItem__c> rliToInsert = new List<ReconciliationLineItem__c>();

            for (SettlementLineItem__c sli : sliList) {
                SettlementLineItem__c updated = updatedSliMap.get(sli.Id);

                ReconciliationLineItem__c rli = new ReconciliationLineItem__c();
                // Mapped from updated SLI fields
                rli.RefReconciliation__c = reconId;
                rli.RefSettlementLineItem__c = sli.Id;
                rli.SettlementDate__c = updated.SettlementDate__c;
                rli.SettlementCurrency__c = updated.SettlementCurrency__c;
                rli.SettlementAmountSLI__c = updated.SettlementAmountSLI__c;
                rli.OtherCharges__c = updated.OtherCharges__c;
                rli.SettlementAmountTTL__c = updated.SettlementAmountTTL__c;
                rli.SettlementType__c = updated.SettlementType__c;
                // Mapped from original (queried) SLI fields
                rli.FXRateOrigintoSettlement__c = sli.FXRateOrigintoSettlement__c;
                rli.RemittanceOnHold__c = sli.RemittanceOnHold__c;
                rli.HoldReason__c = sli.HoldReason__c;
                rli.ExchangeDate__c = sli.ExchangeDate__c;
                rli.ExchangeCurrency__c = sli.ExchangeCurrency__c;
                rli.ExchangeAmount__c = sli.ExchangeAmount__c;
                rli.ExchangeRate__c = sli.ExchangeRate__c;

                rliToInsert.add(rli);
            }

            insert as system rliToInsert;

            return reconId;
        } catch (Exception e) {
            Database.rollback(sp);
            if (e instanceof REC_ReconciliationDomainException || e instanceof REC_ValidationException) {
                throw e;
            }
            String errMsg = 'Error processing reverse offset: ' + e.getMessage();
            Logger.error(errMsg, e);
            Logger.saveLog();
            throw new REC_ReconciliationDomainException(errMsg);
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Private Helpers
    // ═════════════════════════════════════════════════════════════════════════

    /** Creates a Reconciliation__c pre-populated with the correct base lookup. */
    private static Reconciliation__c buildReconciliation(Id recordId, SObjectType objType) {
        Reconciliation__c recon = new Reconciliation__c();
        if (objType == SETTLEMENT_LINE_ITEM_TYPE) {
            recon.BaseSettlementLineItem__c = recordId;
        } else if (objType == BANK_TRANSACTION_TYPE) {
            recon.BaseBankTransaction__c = recordId;
        } else {
            throw new REC_ReconciliationDomainException('Unsupported record type for Reconciliation: ' + objType);
        }
        return recon;
    }

    /** Creates a ReconciliationLineItem linked to its parent Reconciliation and base record. */
    private static ReconciliationLineItem__c buildLineItem(Id reconciliationId, Id recordId, SObjectType objType) {
        ReconciliationLineItem__c rli = new ReconciliationLineItem__c();
        rli.RefReconciliation__c = reconciliationId;

        if (objType == SETTLEMENT_LINE_ITEM_TYPE) {
            rli.RefSettlementLineItem__c = recordId;

            return rli;
        }

        if (objType == BANK_TRANSACTION_TYPE) {
            rli.RefBankTransaction__c = recordId;
        }

        return rli;
    }

    /** Formats DML errors into a single error string. */
    private static String formatDmlErrors(Database.SaveResult sr) {
        String msg = '';
        for (Database.Error err : sr.getErrors()) {
            msg += err.getMessage() + '; ';
        }
        return msg;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Fiduciary Others Validation (placeholder)
    // ═════════════════════════════════════════════════════════════════════════

    public static List<REC_TableHelper.CellError> validateFiduciaryOthers(List<FiduciaryOthers__c> records) {
        List<REC_TableHelper.CellError> errors = new List<REC_TableHelper.CellError>();
        for (FiduciaryOthers__c rec : records) {
            // ── Add business rules below ──────────────────────────────
        }
        return errors;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  SLI-Based Validation
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Validates reconciled amount for each SLI-based detail RLI (Draft & Confirm).
     * Condition 1 (positive): OriginAmount > 0 && ReconciledAMT >= 0 && ReconciledAMT <= NetAmountAfterClearing
     * Condition 2 (negative): OriginAmount < 0 && ReconciledAMT <= 0 && ReconciledAMT >= NetAmountAfterClearing
     * Fails if neither condition is met.
     */
    private static void validateSliDetailReconciledAmount(
        Decimal originAmount,
        Decimal reconciledAmt,
        Decimal netAmountAfterClearing
    ) {
        if (originAmount == null) {
            originAmount = 0;
        }
        if (reconciledAmt == null) {
            reconciledAmt = 0;
        }
        if (netAmountAfterClearing == null) {
            netAmountAfterClearing = 0;
        }

        Boolean condition1 = originAmount > 0 && reconciledAmt >= 0 && reconciledAmt <= netAmountAfterClearing;
        Boolean condition2 = originAmount < 0 && reconciledAmt <= 0 && reconciledAmt >= netAmountAfterClearing;

        if (!condition1 && !condition2) {
            throw new REC_ReconciliationDomainException(Label.REC_MSG_INVALID_RECONCILED_AMT);
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  BT-Based Validation
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Checks whether the reconciled amount is within the valid range for BT-based reconciliation.
     * Condition 1 (positive BT): OriginAmount > 0 && TotalClearedAmount >= 0 && TotalClearedAmount <= NetBalance
     * Condition 2 (negative BT): OriginAmount < 0 && TotalClearedAmount <= 0 && TotalClearedAmount >= NetBalance
     * @return true if valid, false otherwise
     */
    private static Boolean isReconciledAmountValid(Decimal originAmount, Decimal totalClearedAmount, Decimal netBalance) {
        if (originAmount == null) {
            originAmount = 0;
        }

        if (totalClearedAmount == null) {
            totalClearedAmount = 0;
        }

        if (netBalance == null) {
            netBalance = 0;
        }

        Boolean condition1 = originAmount > 0 && totalClearedAmount >= 0 && totalClearedAmount <= netBalance;
        Boolean condition2 = originAmount < 0 && totalClearedAmount <= 0 && totalClearedAmount >= netBalance;

        return condition1 || condition2;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  P_C Other Charges Helper
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Queries RefSettlement__c for each OriginSettlementLineItem referenced by
     * the given P_C SLI list. Returns a map keyed by the origin SLI Id.
     */
    private static Map<Id, SettlementLineItem__c> queryOriginSliRefSettlement(List<SettlementLineItem__c> otherChargeItems) {
        Set<Id> originSliIds = new Set<Id>();
        for (SettlementLineItem__c oci : otherChargeItems) {
            if (oci.OriginSettlementLineItem__c != null) {
                originSliIds.add(oci.OriginSettlementLineItem__c);
            }
        }
        if (originSliIds.isEmpty()) {
            return new Map<Id, SettlementLineItem__c>();
        }
        return REC_SettlementLineItemSelector.getInstance().queryCompactByIds(originSliIds);
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  P_C Other Charges RLI Processing
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Processes P_C Other Charges Reconciliation Line Items:
     *   - INSERT: items without Id (new rows)
     *   - UPDATE: items with existing Id
     *   - DELETE: existing P_C RLIs not present in the input
     *
     * @param reconciliationId  Parent Reconciliation Id
     * @param items             User-entered P_C RLI rows from the Other Charges table (nullable)
     * @return                  Sum of OriginAmount__c across all persisted P_C RLIs
     */
    private static Decimal processPcRlis(String reconciliationId, List<ReconciliationLineItem__c> items) {
        REC_ReconciliationLineItemSelector rliSel = REC_ReconciliationLineItemSelector.getInstance();
        List<ReconciliationLineItem__c> existing = rliSel.queryPcRlisByRecon(reconciliationId);
        Map<Id, ReconciliationLineItem__c> existingMap = new Map<Id, ReconciliationLineItem__c>(existing);

        Set<Id> incomingIds = new Set<Id>();
        List<ReconciliationLineItem__c> toInsert = new List<ReconciliationLineItem__c>();
        List<ReconciliationLineItem__c> toUpdate = new List<ReconciliationLineItem__c>();
        Decimal sumAmount = 0;

        if (items != null) {
            for (ReconciliationLineItem__c item : items) {
                if (item.Id != null && existingMap.containsKey(item.Id)) {
                    // UPDATE: existing P_C RLI
                    incomingIds.add(item.Id);
                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c(Id = item.Id);
                    rli.COA_lk__c = item.COA_lk__c;
                    rli.OriginAmount__c = item.OriginAmount__c;
                    rli.BTCurrency__c = item.BTCurrency__c;
                    rli.RefSettlementLineItem__c = item.RefSettlementLineItem__c;
                    rli.RefBankTransaction__c = item.RefBankTransaction__c;
                    rli.Remarks__c = item.Remarks__c;
                    toUpdate.add(rli);
                } else {
                    // INSERT: new P_C RLI
                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();
                    rli.RefReconciliation__c = reconciliationId;
                    rli.ClosingType__c = REC_Consts.ClosingType.P_C;
                    rli.IsOtherCharges__c = true;
                    rli.COA_lk__c = item.COA_lk__c;
                    rli.OriginAmount__c = item.OriginAmount__c;
                    rli.BTCurrency__c = item.BTCurrency__c;
                    rli.RefSettlementLineItem__c = item.RefSettlementLineItem__c;
                    rli.RefBankTransaction__c = item.RefBankTransaction__c;
                    rli.Remarks__c = item.Remarks__c;
                    toInsert.add(rli);
                }
                sumAmount += (item.OriginAmount__c != null ? item.OriginAmount__c : 0);
            }
        }

        // DELETE: existing P_C RLIs not in the incoming set
        List<ReconciliationLineItem__c> toDelete = new List<ReconciliationLineItem__c>();
        for (ReconciliationLineItem__c ex : existing) {
            if (!incomingIds.contains(ex.Id)) {
                toDelete.add(ex);
            }
        }

        if (!toDelete.isEmpty()) {
            delete as system toDelete;
        }
        if (!toUpdate.isEmpty()) {
            update as system toUpdate;
        }
        if (!toInsert.isEmpty()) {
            insert as system toInsert;
        }

        return sumAmount;
    }

    /**
     * Processes P_C Other Charges RLIs for Statement-based reconciliation.
     * Uses Statement-based fields: OriginSettlementLineItem__c, OriginBankTransaction__c,
     * OriginCurrency__c, SettlementCurrency__c, FXRateOrigintoSettlement__c.
     *
     * @param reconciliationId  Parent Reconciliation Id
     * @param items             User-entered P_C RLI rows from the Other Charges table (nullable)
     * @param bizRegion         BizRegion from the base Statement
     * @param stmtTransactionDate TransactionDate from the base Statement
     * @return                  Sum of OriginAmount__c across all persisted P_C RLIs
     */
    private static Decimal processStmtBasedPcRlis(
        String reconciliationId,
        List<ReconciliationLineItem__c> items,
        String bizRegion,
        String stmtCurrency,
        Date stmtTransactionDate
    ) {
        REC_ReconciliationLineItemSelector rliSel = REC_ReconciliationLineItemSelector.getInstance();
        List<ReconciliationLineItem__c> existing = rliSel.queryPcRlisByRecon(reconciliationId);
        Map<Id, ReconciliationLineItem__c> existingMap = new Map<Id, ReconciliationLineItem__c>(existing);

        Set<Id> incomingIds = new Set<Id>();
        List<ReconciliationLineItem__c> toInsert = new List<ReconciliationLineItem__c>();
        List<ReconciliationLineItem__c> toUpdate = new List<ReconciliationLineItem__c>();
        Decimal sumAmount = 0;

        if (items != null) {
            for (ReconciliationLineItem__c item : items) {
                if (item.Id != null && existingMap.containsKey(item.Id)) {
                    // UPDATE: existing P_C RLI
                    incomingIds.add(item.Id);
                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c(Id = item.Id);
                    rli.COA_lk__c = item.COA_lk__c;
                    rli.OriginCurrency__c = item.OriginCurrency__c;
                    rli.OriginAmount__c = item.OriginAmount__c;
                    rli.OriginSettlementLineItem__c = item.OriginSettlementLineItem__c;
                    rli.OriginBankTransaction__c = item.OriginBankTransaction__c;
                    rli.SettlementCurrency__c = item.SettlementCurrency__c;
                    rli.FXRateOrigintoSettlement__c = item.FXRateOrigintoSettlement__c;
                    rli.SettlementDate__c = stmtTransactionDate;
                    rli.Remarks__c = item.Remarks__c;
                    toUpdate.add(rli);
                } else {
                    // INSERT: new P_C RLI
                    ReconciliationLineItem__c rli = new ReconciliationLineItem__c();
                    rli.RefReconciliation__c = reconciliationId;
                    rli.ClosingType__c = REC_Consts.ClosingType.P_C;
                    rli.IsOtherCharges__c = true;
                    rli.BizRegion__c = bizRegion;
                    rli.COA_lk__c = item.COA_lk__c;
                    rli.OriginCurrency__c = item.OriginCurrency__c;
                    rli.OriginAmount__c = item.OriginAmount__c;
                    rli.OriginSettlementLineItem__c = item.OriginSettlementLineItem__c;
                    rli.OriginBankTransaction__c = item.OriginBankTransaction__c;
                    rli.SettlementCurrency__c = item.SettlementCurrency__c;
                    rli.FXRateOrigintoSettlement__c = item.FXRateOrigintoSettlement__c;
                    rli.SettlementDate__c = stmtTransactionDate;
                    rli.Remarks__c = item.Remarks__c;
                    toInsert.add(rli);
                }
                sumAmount += (item.OriginAmount__c != null ? item.OriginAmount__c : 0);
            }
        }

        // DELETE: existing P_C RLIs not in the incoming set
        List<ReconciliationLineItem__c> toDelete = new List<ReconciliationLineItem__c>();
        for (ReconciliationLineItem__c ex : existing) {
            if (!incomingIds.contains(ex.Id)) {
                toDelete.add(ex);
            }
        }

        if (!toDelete.isEmpty()) {
            delete as system toDelete;
        }
        if (!toUpdate.isEmpty()) {
            update as system toUpdate;
        }
        if (!toInsert.isEmpty()) {
            insert as system toInsert;
        }

        return sumAmount;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Exception
    // ═════════════════════════════════════════════════════════════════════════

    public class REC_ReconciliationDomainException extends Exception {
    }

    /**
     * Validation exception that carries per-cell errors.
     * Thrown when pre-DML validation fails so the controller can return
     * a structured REC_Response instead of a generic AuraHandledException.
     */
    public class REC_ValidationException extends Exception {
        public List<REC_TableHelper.CellError> cellErrors;

        public REC_ValidationException(List<REC_TableHelper.CellError> cellErrors) {
            this('Validation failed');
            this.cellErrors = cellErrors;
        }
    }
}