/**
 * @description       : Controller for Outward Fund record page
 * @author            : Akrom Saidkamolov
 * @last modified on  : 2026-04-23
 * @last modified by  : Akrom Saidkamolov
 **/
public with sharing class REC_OutwardFundCtrl {
    private static final Integer DEFAULT_LIMIT = 2000;
    private static final REC_NoteSelector NOTE_SEL = REC_NoteSelector.getInstance();

    // ═════════════════════════════════════════════════════════════════════════
    //  Settlement Line Items
    // ═════════════════════════════════════════════════════════════════════════

    @AuraEnabled
    public static List<SettlementLineItem__c> inquirySettlementLineItems(String filters) {
        try {
            ExceptionSimulator.throwIfActive();
            String relFields = JSON.serialize(
                new List<String>{
                    'COA_lk__r.Name',
                    'AccountName__r.Name',
                    'CedantFacilityName__r.Name',
                    'Insured__r.Name',
                    'Layer__r.Name',
                    'Reinsurer__r.Name',
                    'MarketFacilityName__r.Name',
                    'ParentClaimNo__r.Name',
                    'FacilityName__r.Name'
                }
            );
            List<SettlementLineItem__c> allItems = REC_SLIInquiryCtrl.inquirySettlementLineItems(filters, relFields);

            // Additional filtering to exclude SLIs already linked to an Outward Fund
            Set<Id> sliIds = new Set<Id>();
            for (SettlementLineItem__c sli : allItems) {
                sliIds.add(sli.Id);
            }

            List<OutwardFundLineItem__c> linkedItems = [
                SELECT ClosingInfo__c
                FROM OutwardFundLineItem__c
                WHERE ClosingInfo__c IN :sliIds
                WITH SYSTEM_MODE
            ];

            Set<Id> linkedSliIds = new Set<Id>();
            for (OutwardFundLineItem__c ofli : linkedItems) {
                linkedSliIds.add(ofli.ClosingInfo__c);
            }

            List<SettlementLineItem__c> result = new List<SettlementLineItem__c>();
            for (SettlementLineItem__c sli : allItems) {
                if (!linkedSliIds.contains(sli.Id)) {
                    result.add(sli);
                }
            }
            return result;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Outward Fund
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Returns a single OutwardFund__c record for the given record Id.
     *
     * @param recordId  Id of the OutwardFund__c record
     * @return          OutwardFund__c with display fields
     */
    @AuraEnabled(cacheable=true)
    public static OutwardFund__c getOutwardFund(Id recordId) {
        try {
            ExceptionSimulator.throwIfActive();
            return [
                SELECT Id, Name, ReportDate__c, ApprovedDate__c, ApprovalStatus__c
                FROM OutwardFund__c
                WHERE Id = :recordId
                WITH USER_MODE
                LIMIT 1
            ] ?? null;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Note Inquiry
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Queries COM_Note__c records based on the provided filter JSON.
     * The special filter key 'Note_lk__c' is remapped to an Id equality
     * condition (searches for a specific Note by record).
     *
     * @param filters    JSON filter string from c-rec-filter-bar
     * @param relFields  JSON array of additional relationship field paths (optional)
     * @return           Up to 2000 COM_Note__c records ordered by Name DESC
     */
    @AuraEnabled
    public static List<COM_Note__c> inquiryNotes(String filters, String relFields) {
        try {
            ExceptionSimulator.throwIfActive();
            return NOTE_SEL.queryByFilter(filters, relFields);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Related SLI Lookup
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Returns SettlementLineItem__c records linked to the given Note IDs
     * via the Note_lk__c lookup field.
     *
     * @param noteIds  List of COM_Note__c record IDs
     * @return         Matching SettlementLineItem__c records
     */
    @AuraEnabled
    public static List<SettlementLineItem__c> getRelatedSlis(List<Id> noteIds) {
        try {
            ExceptionSimulator.throwIfActive();
            return NOTE_SEL.queryRelatedSlis(
                noteIds,
                false,
                new List<String>{
                    'COA_lk__r.Name',
                    'AccountName__r.Name',
                    'CedantFacilityName__r.Name',
                    'Insured__r.Name',
                    'Layer__r.Name',
                    'Reinsurer__r.Name',
                    'MarketFacilityName__r.Name',
                    'ParentClaimNo__r.Name',
                    'FacilityName__r.Name'
                }
            );
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Outward Fund Line Items
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Returns SLI records linked to this OutwardFund via OutwardFundLineItem__c.
     * Used on page load to populate the selected-items table.
     *
     * @param outwardFundId  Id of the OutwardFund__c record
     * @return               SettlementLineItem__c records already confirmed for this fund
     */
    @AuraEnabled
    public static OutwardFund__c getOutwardFundWithLineItems(Id outwardFundId) {
        try {
            ExceptionSimulator.throwIfActive();
            return [
                SELECT
                    Id,
                    Name,
                    ReportDate__c,
                    ApprovedDate__c,
                    ApprovalStatus__c,
                    TotalRecords__c,
                    IsConfirmed__c,
                    (
                        SELECT
                            AdditionalAccountInfo__c,
                            ClosingInfo__c,
                            ClosingInfo__r.Id,
                            ClosingInfo__r.Name,
                            ClosingInfo__r.ClosingType__c,
                            ClosingInfo__r.COA_lk__c,
                            ClosingInfo__r.COA_lk__r.Name,
                            ClosingInfo__r.COAName_fm__c,
                            ClosingInfo__r.AccountName__c,
                            ClosingInfo__r.AccountName__r.Name,
                            ClosingInfo__r.OriginCurrency__c,
                            ClosingInfo__r.OriginAmount__c,
                            ClosingInfo__r.SettlementStatus__c,
                            ClosingInfo__r.SettlementCurrency__c,
                            ClosingInfo__r.SettlementDate__c,
                            ClosingInfo__r.FXRateOrigintoSettlement__c,
                            ClosingInfo__r.SettlementAmountSLI__c,
                            ClosingInfo__r.OtherCharges__c,
                            ClosingInfo__r.SettlementAmountTTL__c,
                            ClosingInfo__r.SettlementType__c,
                            ClosingInfo__r.SettlementDateCounterparty__c,
                            ClosingInfo__r.RemittanceOnHold__c,
                            ClosingInfo__r.HoldReason__c,
                            ClosingInfo__r.ExchangeDate__c,
                            ClosingInfo__r.ExchangeCurrency__c,
                            ClosingInfo__r.ExchangeAmount__c,
                            ClosingInfo__r.ExchangeRate__c,
                            ClosingInfo__r.PPWType_fm__c,
                            ClosingInfo__r.InstallmentNo__c,
                            ClosingInfo__r.PPWDate_fm__c,
                            ClosingInfo__r.PPWDate__c,
                            ClosingInfo__r.LKRefNoPolicy_fm__c,
                            ClosingInfo__r.CedantRefNo__c,
                            ClosingInfo__r.CedantFacilityName__c,
                            ClosingInfo__r.Insured__c,
                            ClosingInfo__r.InceptionDate__c,
                            ClosingInfo__r.ExpirationDate__c,
                            ClosingInfo__r.LOB3__c,
                            ClosingInfo__r.Note_lk__c
                        FROM OutwardFundLineItems__r
                        WHERE ClosingInfo__c != NULL
                        LIMIT :DEFAULT_LIMIT
                    )
                FROM OutwardFund__c
                WHERE Id = :outwardFundId
                WITH SYSTEM_MODE
                LIMIT 1
            ] ?? null;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Validates a candidate list of SLI IDs against existing OutwardFundLineItem__c
     * records and returns those already claimed by a *different* OutwardFund__c.
     *
     * @param outwardFundId  Id of the current OutwardFund__c (excluded from check)
     * @param sliIds         Ids of SettlementLineItem__c candidates
     * @return               Conflicting SettlementLineItem__c records (Id + Name)
     */
    @AuraEnabled
    public static List<SettlementLineItem__c> checkSliConflicts(Id outwardFundId, List<Id> sliIds) {
        try {
            ExceptionSimulator.throwIfActive();
            if (sliIds == null || sliIds.isEmpty()) {
                return new List<SettlementLineItem__c>();
            }

            List<OutwardFundLineItem__c> conflicts = [
                SELECT ClosingInfo__c, ClosingInfo__r.Id, ClosingInfo__r.Name
                FROM OutwardFundLineItem__c
                WHERE ClosingInfo__c IN :sliIds AND OutwardFund__c != :outwardFundId AND ClosingInfo__c != NULL
                WITH SYSTEM_MODE
            ];

            Set<Id> seen = new Set<Id>();
            List<SettlementLineItem__c> result = new List<SettlementLineItem__c>();
            for (OutwardFundLineItem__c ofli : conflicts) {
                if (seen.add(ofli.ClosingInfo__c)) {
                    result.add(ofli.ClosingInfo__r);
                }
            }
            return result;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Creates OutwardFundLineItem__c records for the given SLI IDs.
     * SLIs that already have an OFLI for this OutwardFund are skipped (idempotent).
     *
     * @param outwardFundId  Id of the parent OutwardFund__c
     * @param sliIds         Ids of SettlementLineItem__c records to link
     */
    @AuraEnabled
    public static void saveOutwardFundLineItems(
        List<OutwardFundLineItem__c> outwardFundLineItems,
        List<SettlementLineItem__c> sliRecords
    ) {
        try {
            if (sliRecords == null || sliRecords.isEmpty()) {
                return;
            }

            if (outwardFundLineItems == null || outwardFundLineItems.isEmpty()) {
                throw new AuraHandledException('Outward Fund Line Items list cannot be empty.');
            }

            Id outwardFundId = outwardFundLineItems[0].OutwardFund__c;
            Set<Id> sliIds = new Map<Id, SettlementLineItem__c>(sliRecords).keySet();

            Map<Id, OutwardFundLineItem__c> existingOfliMap = new Map<Id, OutwardFundLineItem__c>();
            List<OutwardFundLineItem__c> existingOFLIs = [
                SELECT ClosingInfo__c, AdditionalAccountInfo__c
                FROM OutwardFundLineItem__c
                WHERE OutwardFund__c = :outwardFundId AND ClosingInfo__c IN :sliIds
                WITH SYSTEM_MODE
            ];
            for (OutwardFundLineItem__c existing : existingOFLIs) {
                existingOfliMap.put(existing.ClosingInfo__c, existing);
            }

            List<OutwardFundLineItem__c> toInsert = new List<OutwardFundLineItem__c>();
            List<OutwardFundLineItem__c> toUpdate = new List<OutwardFundLineItem__c>();

            for (OutwardFundLineItem__c ofli : outwardFundLineItems) {
                if (existingOfliMap.containsKey(ofli.ClosingInfo__c)) {
                    OutwardFundLineItem__c existing = existingOfliMap.get(ofli.ClosingInfo__c);

                    if (existing.AdditionalAccountInfo__c != ofli.AdditionalAccountInfo__c) {
                        existing.AdditionalAccountInfo__c = ofli.AdditionalAccountInfo__c;
                        toUpdate.add(existing);
                    }
                } else {
                    toInsert.add(ofli);
                }
            }

            if (!toUpdate.isEmpty()) {
                Database.update(toUpdate, AccessLevel.SYSTEM_MODE);
            }
            if (!toInsert.isEmpty()) {
                Database.insert(toInsert, AccessLevel.SYSTEM_MODE);
            }

            for (SettlementLineItem__c sli : sliRecords) {
                sli.SettlementAmountSLI__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                    sli.OriginAmount__c ?? 0,
                    sli.FXRateOrigintoSettlement__c ?? 1,
                    sli.SettlementCurrency__c
                );
                sli.SettlementAmountTTL__c = REC_SettlementLineItemDomain.calculateSettlementAmountTTL(
                    sli.SettlementAmountSLI__c,
                    sli.OtherCharges__c ?? 0,
                    sli.SettlementCurrency__c
                );
            }

            Database.update(sliRecords, AccessLevel.SYSTEM_MODE);
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Deletes OutwardFundLineItem__c records linked to the given SLI IDs for this
     * Outward Fund.  SLIs that are not linked are silently ignored (idempotent).
     *
     * @param outwardFundId  Id of the parent OutwardFund__c
     * @param sliIds         Ids of SettlementLineItem__c records to unlink
     */
    @AuraEnabled
    public static void deleteOutwardFundLineItems(Id outwardFundId, List<Id> sliIds) {
        try {
            ExceptionSimulator.throwIfActive();
            if (sliIds == null || sliIds.isEmpty())
                return;

            List<OutwardFundLineItem__c> toDelete = [
                SELECT Id
                FROM OutwardFundLineItem__c
                WHERE OutwardFund__c = :outwardFundId AND ClosingInfo__c IN :sliIds
                WITH SYSTEM_MODE
            ];
            if (!toDelete.isEmpty()) {
                Database.delete(toDelete, AccessLevel.SYSTEM_MODE);
            }
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Creates a new OutwardFund__c record and, optionally, one OutwardFundLineItem__c
     * per provided SettlementLineItem__c ID.  Passing null or an empty list creates
     * the fund with no line items.
     *
     * @param sliIds  (Optional) Ids of SettlementLineItem__c records to attach
     * @return        Id of the newly created OutwardFund__c
     */
    @AuraEnabled
    public static Id createOutwardFundWithLineItems(List<Id> sliIds) {
        try {
            ExceptionSimulator.throwIfActive();
            OutwardFund__c newFund = new OutwardFund__c(BizRegion__c = Util.getBizRegion());
            Database.insert(newFund, AccessLevel.SYSTEM_MODE);

            if (sliIds != null && !sliIds.isEmpty()) {
                List<OutwardFundLineItem__c> lineItems = new List<OutwardFundLineItem__c>();
                for (Id sliId : sliIds) {
                    lineItems.add(
                        new OutwardFundLineItem__c(
                            OutwardFund__c = newFund.Id,
                            ClosingInfo__c = sliId,
                            BizRegion__c = Util.getBizRegion()
                        )
                    );
                }
                Database.insert(lineItems, AccessLevel.SYSTEM_MODE);
            }

            return newFund.Id;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void confirmOutwardFund(Id outwardFundId) {
        try {
            ExceptionSimulator.throwIfActive();
            update as system new OutwardFund__c(Id = outwardFundId, ReportDate__c = Date.today(), IsConfirmed__c = true);

            List<SettlementLineItem__c> slis = [
                SELECT
                    Id,
                    SettlementAmountSLI__c,
                    SettlementAmountTTL__c,
                    OriginAmount__c,
                    FXRateOriginToSettlement__c,
                    OtherCharges__c,
                    SettlementCurrency__c
                FROM SettlementLineItem__c
                WHERE
                    Id IN (
                        SELECT ClosingInfo__c
                        FROM OutwardFundLineItem__c
                        WHERE OutwardFund__c = :outwardFundId
                    )
                WITH SYSTEM_MODE
            ];

            for (SettlementLineItem__c sli : slis) {
                sli.SettlementAmountSLI__c = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
                    sli.OriginAmount__c ?? 0,
                    sli.FXRateOrigintoSettlement__c ?? 1,
                    sli.SettlementCurrency__c
                );
                sli.SettlementAmountTTL__c = REC_SettlementLineItemDomain.calculateSettlementAmountTTL(
                    sli.SettlementAmountSLI__c,
                    sli.OtherCharges__c ?? 0,
                    sli.SettlementCurrency__c
                );
            }

            if (!slis.isEmpty()) {
                Database.update(slis, AccessLevel.SYSTEM_MODE);
            }
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Outward Fund Files
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Returns Note records whose linked SLI belongs to this Outward Fund.
     * Settlement data is aggregated from the Note's child SLIs (SettlementLineItem__c.Note_lk__c):
     * number fields are summed and date fields use the earliest value.
     *
     * @param outwardFundId  Id of the OutwardFund__c record
     * @param accountId      Optional Account filter (Account_lk__c on Note)
     * @return               Row maps with Note + aggregated child-SLI fields
     */
    @AuraEnabled
    public static List<Map<String, Object>> getNotesByOutwardFund(Id outwardFundId, Id accountId) {
        try {
            ExceptionSimulator.throwIfActive();

            Set<Id> sliIds = new Set<Id>();
            for (OutwardFundLineItem__c ofli : [
                SELECT ClosingInfo__c
                FROM OutwardFundLineItem__c
                WHERE OutwardFund__c = :outwardFundId AND ClosingInfo__c != NULL
                WITH SYSTEM_MODE
            ]) {
                sliIds.add(ofli.ClosingInfo__c);
            }

            if (sliIds.isEmpty()) {
                return new List<Map<String, Object>>();
            }

            // 1. Query notes without parent-SLI relationship fields
            List<COM_Note__c> notes;
            if (accountId != null) {
                notes = [
                    SELECT
                        Id,
                        Name,
                        Account_lk__c,
                        Account_lk__r.Name,
                        NoteType__c,
                        OriginCurrency__c,
                        NoteAmount__c,
                        Closing_Origin_fm__c,
                        Reinsured_lk__c,
                        Reinsured_lk__r.Name,
                        DateOfLoss_fm__c,
                        LocationOfLoss_fm__c,
                        PeriodFrom_fm__c,
                        SOCSeq_fm__c
                    FROM COM_Note__c
                    WHERE SettlementLineItem__c IN :sliIds AND Account_lk__c = :accountId
                    ORDER BY Name
                    LIMIT :DEFAULT_LIMIT
                ];
            } else {
                notes = [
                    SELECT
                        Id,
                        Name,
                        Account_lk__c,
                        Account_lk__r.Name,
                        NoteType__c,
                        OriginCurrency__c,
                        NoteAmount__c,
                        Closing_Origin_fm__c,
                        Reinsured_lk__c,
                        Reinsured_lk__r.Name,
                        DateOfLoss_fm__c,
                        LocationOfLoss_fm__c,
                        PeriodFrom_fm__c,
                        SOCSeq_fm__c
                    FROM COM_Note__c
                    WHERE SettlementLineItem__c IN :sliIds
                    ORDER BY Name
                    LIMIT :DEFAULT_LIMIT
                ];
            }

            if (notes.isEmpty()) {
                return new List<Map<String, Object>>();
            }

            // 2. Aggregate child SLIs by Note_lk__c — numbers summed, dates earliest
            Set<Id> noteIds = new Map<Id, COM_Note__c>(notes).keySet();
            Map<Id, Map<String, Object>> sliSummaryMap = new Map<Id, Map<String, Object>>();
            for (AggregateResult ar : [
                SELECT
                    Note_lk__c noteId,
                    MIN(SettlementDate__c) settlementDate,
                    SUM(OriginAmount__c) originAmount,
                    MIN(SettlementCurrency__c) settlementCurrency,
                    SUM(SettlementAmountSLI__c) settlementAmountSLI,
                    SUM(FXRateOrigintoSettlement__c) fxRate,
                    SUM(OtherCharges__c) otherCharges,
                    SUM(SettlementAmountTTL__c) settlementAmountTTL,
                    MIN(LKRefNoPolicy_fm__c) lkRefNo,
                    MIN(CedantRefNo__c) cedantRefNo,
                    MIN(Insured_fm__c) insured,
                    MIN(ExpirationDate__c) expirationDate
                FROM SettlementLineItem__c
                WHERE Note_lk__c IN :noteIds
                GROUP BY Note_lk__c
            ]) {
                sliSummaryMap.put(
                    (Id) ar.get('noteId'),
                    new Map<String, Object>{
                        'SettlementDate__c' => ar.get('settlementDate'),
                        'OriginAmount__c' => ar.get('originAmount'),
                        'SettlementCurrency__c' => ar.get('settlementCurrency'),
                        'SettlementAmountSLI__c' => ar.get('settlementAmountSLI'),
                        'FXRateOrigintoSettlement__c' => ar.get('fxRate'),
                        'OtherCharges__c' => ar.get('otherCharges'),
                        'SettlementAmountTTL__c' => ar.get('settlementAmountTTL'),
                        'LKRefNoPolicy_fm__c' => ar.get('lkRefNo'),
                        'CedantRefNo__c' => ar.get('cedantRefNo'),
                        'Insured_fm__c' => ar.get('insured'),
                        'ExpirationDate__c' => ar.get('expirationDate')
                    }
                );
            }

            // 3. Build row maps
            List<Map<String, Object>> rows = new List<Map<String, Object>>();
            for (COM_Note__c n : notes) {
                rows.add(
                    new Map<String, Object>{
                        'Id' => n.Id,
                        'Name' => n.Name,
                        'Account_lk__c' => n.Account_lk__c,
                        'Account_lk__r' => n.Account_lk__r != null
                            ? new Map<String, Object>{ 'Name' => n.Account_lk__r.Name }
                            : null,
                        'NoteType__c' => n.NoteType__c,
                        'OriginCurrency__c' => n.OriginCurrency__c,
                        'NoteAmount__c' => n.NoteAmount__c,
                        'Closing_Origin_fm__c' => n.Closing_Origin_fm__c,
                        'Reinsured_lk__c' => n.Reinsured_lk__c,
                        'Reinsured_lk__r' => n.Reinsured_lk__r != null
                            ? new Map<String, Object>{ 'Name' => n.Reinsured_lk__r.Name }
                            : null,
                        'DateOfLoss_fm__c' => n.DateOfLoss_fm__c,
                        'LocationOfLoss_fm__c' => n.LocationOfLoss_fm__c,
                        'PeriodFrom_fm__c' => n.PeriodFrom_fm__c,
                        'SOCSeq_fm__c' => n.SOCSeq_fm__c,
                        'SettlementLineItem__r' => sliSummaryMap.get(n.Id)
                    }
                );
            }
            return rows;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException('Failed to load notes: ' + e.getMessage());
        }
    }

    /**
     * Attaches an Excel file (base64-encoded) to the given OutwardFund__c record.
     *
     * @param recordId   OutwardFund__c Id
     * @param fileName   File name (without extension)
     * @param base64Data Base64-encoded .xlsx content
     * @return           ContentVersion Id
     */
    @AuraEnabled
    public static Id saveAsFile(Id recordId, String fileName, String base64Data) {
        try {
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = fileName + '.xlsx';
            cv.VersionData = EncodingUtil.base64Decode(base64Data);
            cv.FirstPublishLocationId = recordId;
            insert cv;
            return cv.Id;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * Returns file name info for the 4 file types per Note record:
     *   - Debit/Credit/SOC Note
     *   - Cover Note
     *   - Closing Slip
     *   - SOC from Cedant
     *
     * @param noteIds  COM_Note__c Id list
     * @return         Map<NoteId, OutwardFundFileInfo>
     */
    @AuraEnabled
    public static Map<Id, OutwardFundFileInfo> getOutwardFundFileMap(List<Id> noteIds) {
        Map<Id, OutwardFundFileInfo> result = new Map<Id, OutwardFundFileInfo>();
        if (noteIds == null || noteIds.isEmpty()) {
            return result;
        }

        // 1. Re-query notes with fields needed for file routing
        List<COM_Note__c> notes = [
            SELECT
                Id,
                Name,
                NoteType__c,
                Closing_Origin_fm__c,
                Placement_lk__c,
                ChildClaim_lk__c,
                SettlementLineItem__r.RefReinsurance__c,
                SettlementLineItem__r.RefClaim__c
            FROM COM_Note__c
            WHERE Id IN :noteIds
        ];

        // 2. Collect parent IDs by usage
        Set<Id> placementParentIds = new Set<Id>(); // Placement_lk__c  (debitCreditSoc + coverNote)
        Set<Id> claimDebitParentIds = new Set<Id>(); // ChildClaim_lk__c (debitCreditSoc, Claim+Debit)
        Set<Id> refClaimParentIds = new Set<Id>(); // SLI.RefClaim__c  (socFromCedant, Claim+Credit)
        Set<Id> riPlacementIds = new Set<Id>(); // SLI.RefReinsurance__c (closingSlip)

        for (COM_Note__c n : notes) {
            Boolean isPlacement = 'Placement' == n.Closing_Origin_fm__c;
            Boolean isClaim = 'Claim' == n.Closing_Origin_fm__c;
            Boolean isCredit = 'Credit' == n.NoteType__c;
            Boolean isDebit = 'Debit' == n.NoteType__c;

            if (isPlacement) {
                if (n.Placement_lk__c != null)
                    placementParentIds.add(n.Placement_lk__c);
                if (isCredit && n.SettlementLineItem__r?.RefReinsurance__c != null)
                    riPlacementIds.add(n.SettlementLineItem__r.RefReinsurance__c);
            } else if (isClaim) {
                if (isDebit && n.ChildClaim_lk__c != null)
                    claimDebitParentIds.add(n.ChildClaim_lk__c);
                if (isCredit && n.SettlementLineItem__r?.RefClaim__c != null)
                    refClaimParentIds.add(n.SettlementLineItem__r.RefClaim__c);
            }
        }

        // 3. Bulk-fetch ContentVersions for CDL parents (Placement, Claim, RefClaim)
        Set<Id> cdlParentIds = new Set<Id>();
        cdlParentIds.addAll(placementParentIds);
        cdlParentIds.addAll(claimDebitParentIds);
        cdlParentIds.addAll(refClaimParentIds);

        Map<Id, List<ContentVersion>> filesByParent = buildFilesByParent(cdlParentIds, true);

        // 4. Closing Slip: OPP_SlipInfo__c (RI Closing + FinalRISlip) attached files, keyed by Placement Id
        Map<Id, List<ContentVersion>> closingSlipFilesByPlacement = new Map<Id, List<ContentVersion>>();
        if (!riPlacementIds.isEmpty()) {
            Set<Id> slipIds = new Set<Id>();
            Map<Id, Id> slipToPlacement = new Map<Id, Id>();
            for (OPP_SlipInfo__c slip : [
                SELECT Id, Placement_lk__c
                FROM OPP_SlipInfo__c
                WHERE Placement_lk__c IN :riPlacementIds AND Type__c = 'RI Closing' AND FinalRISlip_is__c = TRUE
                WITH SYSTEM_MODE
            ]) {
                slipIds.add(slip.Id);
                slipToPlacement.put(slip.Id, slip.Placement_lk__c);
            }

            if (!slipIds.isEmpty()) {
                Map<Id, List<ContentVersion>> filesBySlip = buildFilesByParent(slipIds, false);
                for (Id slipId : slipToPlacement.keySet()) {
                    Id placementId = slipToPlacement.get(slipId);
                    List<ContentVersion> cvs = filesBySlip.get(slipId);
                    if (cvs == null)
                        continue;
                    if (!closingSlipFilesByPlacement.containsKey(placementId))
                        closingSlipFilesByPlacement.put(placementId, new List<ContentVersion>());
                    closingSlipFilesByPlacement.get(placementId).addAll(cvs);
                }
            }
        }

        // 5. Build result per note
        for (COM_Note__c n : notes) {
            OutwardFundFileInfo info = new OutwardFundFileInfo();
            Boolean isPlacement = 'Placement' == n.Closing_Origin_fm__c;
            Boolean isClaim = 'Claim' == n.Closing_Origin_fm__c;
            Boolean isDebit = 'Debit' == n.NoteType__c;
            Boolean isCredit = 'Credit' == n.NoteType__c;
            String noteNameLower = n.Name != null ? n.Name.toLowerCase() : '';

            if (isPlacement && n.Placement_lk__c != null) {
                List<ContentVersion> pool = filesByParent.get(n.Placement_lk__c);
                if (pool != null && !pool.isEmpty()) {
                    List<String> dcNames = new List<String>();
                    List<String> dcDocIds = new List<String>();
                    Long dcSize = 0;
                    List<String> cnNames = new List<String>();
                    List<String> cnDocIds = new List<String>();
                    Long cnSize = 0;
                    for (ContentVersion cv : pool) {
                        String fileName = cv.FileExtension != null ? cv.Title + '.' + cv.FileExtension : cv.Title;
                        String titleLower = cv.Title != null ? cv.Title.toLowerCase() : '';
                        Long size = cv.ContentSize != null ? cv.ContentSize : 0;
                        if (titleLower.contains(noteNameLower)) {
                            dcNames.add(fileName);
                            dcDocIds.add(cv.ContentDocumentId);
                            dcSize += size;
                        }
                        if (isDebit) {
                            cnNames.add(fileName);
                            cnDocIds.add(cv.ContentDocumentId);
                            cnSize += size;
                        }
                    }
                    if (!dcNames.isEmpty()) {
                        info.debitCreditSocNoteFileName = String.join(dcNames, ', ');
                        info.debitCreditSocNoteContentDocumentIds = String.join(dcDocIds, ',');
                        info.debitCreditSocNoteTotalSize = dcSize;
                    }
                    if (!cnNames.isEmpty()) {
                        info.coverNoteFileName = String.join(cnNames, ', ');
                        info.coverNoteContentDocumentIds = String.join(cnDocIds, ',');
                        info.coverNoteTotalSize = cnSize;
                    }
                }

                // Closing Slip (Placement + Credit)
                if (isCredit && n.SettlementLineItem__r?.RefReinsurance__c != null) {
                    List<ContentVersion> slipCvs = closingSlipFilesByPlacement.get(
                        n.SettlementLineItem__r.RefReinsurance__c
                    );
                    if (slipCvs != null && !slipCvs.isEmpty()) {
                        List<String> slipNames = new List<String>();
                        List<String> slipDocIds = new List<String>();
                        Long slipSize = 0;
                        for (ContentVersion cv : slipCvs) {
                            slipNames.add(cv.FileExtension != null ? cv.Title + '.' + cv.FileExtension : cv.Title);
                            slipDocIds.add(cv.ContentDocumentId);
                            slipSize += cv.ContentSize != null ? cv.ContentSize : 0;
                        }
                        info.closingSlipFileName = String.join(slipNames, ', ');
                        info.closingSlipContentDocumentIds = String.join(slipDocIds, ',');
                        info.closingSlipTotalSize = slipSize;
                    }
                }
            } else if (isClaim) {
                // Debit/Credit/SOC Note (Claim + Debit): ChildClaim files, category SOC, title contains note name
                if (isDebit && n.ChildClaim_lk__c != null) {
                    List<ContentVersion> pool = filesByParent.get(n.ChildClaim_lk__c);
                    if (pool != null && !pool.isEmpty()) {
                        List<String> names = new List<String>();
                        List<String> docIds = new List<String>();
                        Long totalSize = 0;
                        for (ContentVersion cv : pool) {
                            String titleLower = cv.Title != null ? cv.Title.toLowerCase() : '';
                            if (titleLower.contains(noteNameLower) && 'SOC'.equalsIgnoreCase(cv.RelFiles__Category__c)) {
                                names.add(cv.FileExtension != null ? cv.Title + '.' + cv.FileExtension : cv.Title);
                                docIds.add(cv.ContentDocumentId);
                                totalSize += cv.ContentSize != null ? cv.ContentSize : 0;
                            }
                        }
                        if (!names.isEmpty()) {
                            info.debitCreditSocNoteFileName = String.join(names, ', ');
                            info.debitCreditSocNoteContentDocumentIds = String.join(docIds, ',');
                            info.debitCreditSocNoteTotalSize = totalSize;
                        }
                    }
                }

                // SOC from Cedant (Claim + Credit): SLI.RefClaim files, category Cedant SOC
                if (isCredit && n.SettlementLineItem__r?.RefClaim__c != null) {
                    List<ContentVersion> pool = filesByParent.get(n.SettlementLineItem__r.RefClaim__c);
                    if (pool != null && !pool.isEmpty()) {
                        List<String> names = new List<String>();
                        List<String> docIds = new List<String>();
                        Long totalSize = 0;
                        for (ContentVersion cv : pool) {
                            if ('Cedant SOC'.equalsIgnoreCase(cv.RelFiles__Category__c)) {
                                names.add(cv.FileExtension != null ? cv.Title + '.' + cv.FileExtension : cv.Title);
                                docIds.add(cv.ContentDocumentId);
                                totalSize += cv.ContentSize != null ? cv.ContentSize : 0;
                            }
                        }
                        if (!names.isEmpty()) {
                            info.socFromCedantFileName = String.join(names, ', ');
                            info.socFromCedantContentDocumentIds = String.join(docIds, ',');
                            info.socFromCedantTotalSize = totalSize;
                        }
                    }
                }
            }

            result.put(n.Id, info);
        }

        return result;
    }

    /**
     * Bulk-fetches ContentVersions (IsLatest) for a set of parent record IDs via ContentDocumentLink.
     *
     * @param parentIds      Parent record IDs to query CDLs for
     * @param withCategory   Whether to include RelFiles__Category__c in the select
     * @return               Map<parentId, List<ContentVersion>>
     */
    private static Map<Id, List<ContentVersion>> buildFilesByParent(Set<Id> parentIds, Boolean withCategory) {
        Map<Id, List<ContentVersion>> result = new Map<Id, List<ContentVersion>>();
        if (parentIds == null || parentIds.isEmpty())
            return result;

        Map<Id, Set<Id>> docIdsByParent = new Map<Id, Set<Id>>();
        Set<Id> allDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT LinkedEntityId, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :parentIds
            WITH SYSTEM_MODE
        ]) {
            if (!docIdsByParent.containsKey(cdl.LinkedEntityId))
                docIdsByParent.put(cdl.LinkedEntityId, new Set<Id>());
            docIdsByParent.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
            allDocIds.add(cdl.ContentDocumentId);
        }

        if (allDocIds.isEmpty())
            return result;

        Map<Id, ContentVersion> cvByDocId = new Map<Id, ContentVersion>();
        String cvQuery =
            'SELECT Id, ContentDocumentId, Title, FileExtension, ContentSize' +
            (withCategory ? ', RelFiles__Category__c' : '') +
            ' FROM ContentVersion WHERE ContentDocumentId IN :allDocIds AND IsLatest = TRUE';
        for (ContentVersion cv : Database.query(cvQuery)) {
            cvByDocId.put(cv.ContentDocumentId, cv);
        }

        for (Id parentId : docIdsByParent.keySet()) {
            List<ContentVersion> cvs = new List<ContentVersion>();
            for (Id docId : docIdsByParent.get(parentId)) {
                ContentVersion cv = cvByDocId.get(docId);
                if (cv != null)
                    cvs.add(cv);
            }
            result.put(parentId, cvs);
        }

        return result;
    }

    public class OutwardFundFileInfo {
        @AuraEnabled
        public String debitCreditSocNoteFileName;
        @AuraEnabled
        public String debitCreditSocNoteContentDocumentIds;
        @AuraEnabled
        public Long debitCreditSocNoteTotalSize;
        @AuraEnabled
        public String coverNoteFileName;
        @AuraEnabled
        public String coverNoteContentDocumentIds;
        @AuraEnabled
        public Long coverNoteTotalSize;
        @AuraEnabled
        public String closingSlipFileName;
        @AuraEnabled
        public String closingSlipContentDocumentIds;
        @AuraEnabled
        public Long closingSlipTotalSize;
        @AuraEnabled
        public String socFromCedantFileName;
        @AuraEnabled
        public String socFromCedantContentDocumentIds;
        @AuraEnabled
        public Long socFromCedantTotalSize;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Additional Account Info Defaults
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * For each given Account ID, returns the sole ACC_AdditionalInfo__c record
     * if exactly one exists.  Accounts with zero or multiple child records are
     * omitted from the result map.
     *
     * @param accountIds  Set of Account IDs to check
     * @return            Map<AccountId, ACC_AdditionalInfo__c Id> for single-child accounts
     */
    @AuraEnabled
    public static Map<Id, Id> getDefaultAdditionalAccountInfo(List<Id> accountIds) {
        try {
            ExceptionSimulator.throwIfActive();
            if (accountIds == null || accountIds.isEmpty()) {
                return new Map<Id, Id>();
            }

            Map<Id, Id> result = new Map<Id, Id>();
            for (AggregateResult ar : [
                SELECT MIN(Id) infoId, Account_lk__c
                FROM ACC_AdditionalInfo__c
                WHERE Account_lk__c IN :accountIds
                GROUP BY Account_lk__c
                HAVING COUNT(Id) = 1
            ]) {
                result.put((Id) ar.get('Account_lk__c'), (Id) ar.get('infoId'));
            }
            return result;
        } catch (Exception e) {
            Logger.error(e.getMessage(), e);
            Logger.saveLog();
            throw new AuraHandledException(e.getMessage());
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Private Helpers
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Builds a REC_FilterBuilder from the given filter map.
     * 'Note_lk__c' filter is remapped to an Id equality condition so that the
     * LWC Record-Picker's returned ID is matched against the COM_Note__c.Id.
     */
    private static REC_FilterBuilder buildNoteFilter(Map<String, Object> filterMap) {
        Object noteIdValue = filterMap.remove('Note_lk__c');

        REC_FilterBuilder fb = new REC_FilterBuilder(
            filterMap.isEmpty() ? null : JSON.serialize(filterMap),
            COM_Note__c.SObjectType
        );

        if (noteIdValue != null && String.isNotBlank(String.valueOf(noteIdValue))) {
            fb.addCondition('Id = :noteId').addBind('noteId', (Id) String.valueOf(noteIdValue));
        }

        return fb;
    }
}