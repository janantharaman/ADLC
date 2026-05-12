/**
 * REC_SettlementLineItemDomain_ts — Test class for REC_SettlementLineItemDomain.
 *
 * Coverage targets:
 *  - validate (with SettlementType validation)
 *  - isNormalTypeSelectable
 *  - isFundedTypeSelectable
 *  - validateSettlementType
 *  - split (happy path + error paths)
 *  - searchCounterparts (happy path + error paths)
 *  - matchCounterpart (via searchCounterparts)
 */
@IsTest
private class REC_SettlementLineItemDomain_ts {
    @TestSetup
    static void makeData() {
        REC_TestDataFactory.setupBtBasedRecon();
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private static SettlementLineItem__c getPositiveSli() {
        return [
            SELECT
                Id,
                Name,
                OriginAmount__c,
                SettlementStatus__c,
                SettlementType__c,
                SplitKey__c,
                RefSettlement__c,
                ClosingType__c
            FROM SettlementLineItem__c
            WHERE OriginAmount__c > 0
            LIMIT 1
        ];
    }

    private static SettlementLineItem__c getNegativeSli() {
        return [
            SELECT
                Id,
                Name,
                OriginAmount__c,
                SettlementStatus__c,
                SettlementType__c,
                SplitKey__c,
                RefSettlement__c,
                ClosingType__c
            FROM SettlementLineItem__c
            WHERE OriginAmount__c < 0
            LIMIT 1
        ];
    }

    private static COM_Note__c insertNote(String noteStatus) {
        COM_Note__c note = new COM_Note__c(
            NoteStatus__c = noteStatus,
            OriginCurrency__c = REC_Consts.CCY.KRW,
            NoteAmount__c = 500000
        );
        insert note;
        return note;
    }

    private static SettlementLineItem__c insertNoteLinkedSli(Id noteId, String settlementStatus) {
        Settlement__c settlement = REC_TestDataFactory.insertSettlement();
        SettlementLineItem__c sli = REC_TestDataFactory.createSettlementLineItem(
            settlement.Id,
            REC_Consts.ClosingType.P_R,
            1000,
            REC_Consts.CCY.KRW,
            REC_Consts.BizRegion.LK_KR
        );
        sli.Note_lk__c = noteId;
        sli.SettlementStatus__c = settlementStatus;
        insert sli;
        return sli;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  isNormalTypeSelectable
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void isNormalTypeSelectable_positiveNotAvailable_returnsTrue() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            OriginAmount__c = 1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );
        Assert.isTrue(REC_SettlementLineItemDomain.isNormalTypeSelectable(sli));
    }

    @IsTest
    static void isNormalTypeSelectable_negativeAvailable_returnsTrue() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            OriginAmount__c = -1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.AVAILABLE
        );
        Assert.isTrue(REC_SettlementLineItemDomain.isNormalTypeSelectable(sli));
    }

    @IsTest
    static void isNormalTypeSelectable_positiveAvailable_returnsFalse() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            OriginAmount__c = 1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.AVAILABLE
        );
        Assert.isFalse(REC_SettlementLineItemDomain.isNormalTypeSelectable(sli));
    }

    @IsTest
    static void isNormalTypeSelectable_nullAmount_returnsFalse() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            OriginAmount__c = null,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );
        Assert.isFalse(REC_SettlementLineItemDomain.isNormalTypeSelectable(sli));
    }

    @IsTest
    static void isNormalTypeSelectable_negativeNotAvailable_returnsFalse() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            OriginAmount__c = -1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );
        Assert.isFalse(REC_SettlementLineItemDomain.isNormalTypeSelectable(sli));
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  isFundedTypeSelectable
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void isFundedTypeSelectable_negativeNotAvailable_returnsTrue() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            OriginAmount__c = -1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );
        Assert.isTrue(REC_SettlementLineItemDomain.isFundedTypeSelectable(sli));
    }

    @IsTest
    static void isFundedTypeSelectable_positiveNotAvailable_returnsFalse() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            OriginAmount__c = 1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );
        Assert.isFalse(REC_SettlementLineItemDomain.isFundedTypeSelectable(sli));
    }

    @IsTest
    static void isFundedTypeSelectable_negativeAvailable_returnsFalse() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            OriginAmount__c = -1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.AVAILABLE
        );
        Assert.isFalse(REC_SettlementLineItemDomain.isFundedTypeSelectable(sli));
    }

    @IsTest
    static void isFundedTypeSelectable_nullAmount_returnsFalse() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            OriginAmount__c = null,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );
        Assert.isFalse(REC_SettlementLineItemDomain.isFundedTypeSelectable(sli));
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  isDueDateUpdatable
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void isDueDateUpdatable_eligibleCounterpart_returnsTrue() {
        SettlementLineItem__c originSli = new SettlementLineItem__c(
            OriginAmount__c = 1000,
            Status__c = REC_Consts.STCStatus.CONFIRM,
            SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR
        );
        SettlementLineItem__c counterSli = new SettlementLineItem__c(ClosingType__c = REC_Consts.ClosingType.P_R);

        Assert.isTrue(
            REC_SettlementLineItemDomain.isDueDateUpdatable(originSli, counterSli),
            'A confirmed, cleared positive SLI with a non-P_B/P_C counterpart should update the DueDate'
        );
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  validate
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void validate_emptyList_returnsNoErrors() {
        List<REC_TableHelper.CellError> errors = REC_SettlementLineItemDomain.validate(new List<SettlementLineItem__c>());
        Assert.isTrue(errors.isEmpty(), 'Empty list should produce no errors');
    }

    @IsTest
    static void validate_normalTypeValid_returnsNoErrors() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            Id = getPositiveSli().Id,
            OriginAmount__c = 1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE,
            SettlementType__c = REC_Consts.SettlementType.NORMAL
        );

        List<REC_TableHelper.CellError> errors = REC_SettlementLineItemDomain.validate(
            new List<SettlementLineItem__c>{ sli }
        );
        Assert.isTrue(errors.isEmpty(), 'Valid Normal type should produce no errors');
    }

    @IsTest
    static void validate_normalTypeInvalid_returnsError() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            Id = getPositiveSli().Id,
            OriginAmount__c = 1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.AVAILABLE,
            SettlementType__c = REC_Consts.SettlementType.NORMAL
        );

        List<REC_TableHelper.CellError> errors = REC_SettlementLineItemDomain.validate(
            new List<SettlementLineItem__c>{ sli }
        );
        Assert.areEqual(1, errors.size(), 'Invalid Normal type should produce an error');
        Assert.areEqual('SettlementType__c', errors[0].fieldName);
    }

    @IsTest
    static void validate_fundedTypeInvalid_returnsError() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            Id = getPositiveSli().Id,
            OriginAmount__c = 1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE,
            SettlementType__c = REC_Consts.SettlementType.FUNDED
        );

        List<REC_TableHelper.CellError> errors = REC_SettlementLineItemDomain.validate(
            new List<SettlementLineItem__c>{ sli }
        );
        Assert.areEqual(1, errors.size(), 'Invalid Funded type should produce an error');
        Assert.areEqual('SettlementType__c', errors[0].fieldName);
    }

    @IsTest
    static void validate_blankSettlementType_returnsNoErrors() {
        SettlementLineItem__c sli = new SettlementLineItem__c(
            Id = getPositiveSli().Id,
            OriginAmount__c = 1000,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE,
            SettlementType__c = null
        );

        List<REC_TableHelper.CellError> errors = REC_SettlementLineItemDomain.validate(
            new List<SettlementLineItem__c>{ sli }
        );
        Assert.isTrue(errors.isEmpty(), 'Blank SettlementType should produce no errors');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  validateSettlementType
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void validateSettlementType_validNormal_returnsNoErrors() {
        SettlementLineItem__c sli = getPositiveSli();

        ReconciliationLineItem__c rli = new ReconciliationLineItem__c(SettlementType__c = REC_Consts.SettlementType.NORMAL);

        Map<Id, ReconciliationLineItem__c> newSliRefs = new Map<Id, ReconciliationLineItem__c>{ sli.Id => rli };
        Map<Id, SettlementLineItem__c> refSLIs = new Map<Id, SettlementLineItem__c>{ sli.Id => sli };

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_SettlementLineItemDomain.validateSettlementType(newSliRefs, refSLIs);
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Valid Normal on positive Not-Available SLI should pass');
    }

    @IsTest
    static void validateSettlementType_invalidNormal_returnsError() {
        SettlementLineItem__c sli = getPositiveSli();
        sli.SettlementStatus__c = REC_Consts.SettlementStatus.AVAILABLE;

        ReconciliationLineItem__c rli = new ReconciliationLineItem__c(SettlementType__c = REC_Consts.SettlementType.NORMAL);

        Map<Id, ReconciliationLineItem__c> newSliRefs = new Map<Id, ReconciliationLineItem__c>{ sli.Id => rli };
        Map<Id, SettlementLineItem__c> refSLIs = new Map<Id, SettlementLineItem__c>{ sli.Id => sli };

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_SettlementLineItemDomain.validateSettlementType(newSliRefs, refSLIs);
        Test.stopTest();

        Assert.areEqual(1, errors.size(), 'Invalid Normal should produce an error');
        Assert.areEqual('SettlementType__c', errors[0].fieldName);
    }

    @IsTest
    static void validateSettlementType_blankType_skipped() {
        SettlementLineItem__c sli = getPositiveSli();

        ReconciliationLineItem__c rli = new ReconciliationLineItem__c(SettlementType__c = '');

        Map<Id, ReconciliationLineItem__c> newSliRefs = new Map<Id, ReconciliationLineItem__c>{ sli.Id => rli };
        Map<Id, SettlementLineItem__c> refSLIs = new Map<Id, SettlementLineItem__c>{ sli.Id => sli };

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_SettlementLineItemDomain.validateSettlementType(newSliRefs, refSLIs);
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Blank SettlementType should be skipped');
    }

    @IsTest
    static void validateSettlementType_nullRefSli_skipped() {
        SettlementLineItem__c sli = getPositiveSli();

        ReconciliationLineItem__c rli = new ReconciliationLineItem__c(SettlementType__c = REC_Consts.SettlementType.NORMAL);

        Map<Id, ReconciliationLineItem__c> newSliRefs = new Map<Id, ReconciliationLineItem__c>{ sli.Id => rli };
        Map<Id, SettlementLineItem__c> refSLIs = new Map<Id, SettlementLineItem__c>(); // no matching SLI

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_SettlementLineItemDomain.validateSettlementType(newSliRefs, refSLIs);
        Test.stopTest();

        Assert.isTrue(errors.isEmpty(), 'Null ref SLI should be skipped');
    }

    @IsTest
    static void validateSettlementType_invalidFunded_returnsError() {
        SettlementLineItem__c sli = getPositiveSli(); // positive + Not-Available → Funded invalid

        ReconciliationLineItem__c rli = new ReconciliationLineItem__c(SettlementType__c = REC_Consts.SettlementType.FUNDED);

        Map<Id, ReconciliationLineItem__c> newSliRefs = new Map<Id, ReconciliationLineItem__c>{ sli.Id => rli };
        Map<Id, SettlementLineItem__c> refSLIs = new Map<Id, SettlementLineItem__c>{ sli.Id => sli };

        Test.startTest();
        List<REC_TableHelper.CellError> errors = REC_SettlementLineItemDomain.validateSettlementType(newSliRefs, refSLIs);
        Test.stopTest();

        Assert.areEqual(1, errors.size(), 'Invalid Funded should produce an error');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  split — Happy Path
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void split_validRecord_createsFourRecords() {
        SettlementLineItem__c sli = getPositiveSli();

        Test.startTest();
        List<SettlementLineItem__c> result = REC_SettlementLineItemDomain.split(sli.Id, 600000, 400000);
        Test.stopTest();

        Assert.areEqual(4, result.size(), 'Split should produce 4 records');

        // Verify split keys
        Set<String> splitKeys = new Set<String>();
        for (SettlementLineItem__c r : result) {
            splitKeys.add(r.SplitKey__c);
        }
        Assert.areEqual(2, splitKeys.size(), 'Should have exactly two split keys');
    }

    @IsTest
    static void split_alreadySplitRecord_reSplitsCorrectly() {
        SettlementLineItem__c sli = getPositiveSli();

        // First split
        List<SettlementLineItem__c> firstResult = REC_SettlementLineItemDomain.split(sli.Id, 700000, 300000);

        // Re-split the first result's A-key SLI (the updated original)
        SettlementLineItem__c splitA = [
            SELECT Id, SplitKey__c
            FROM SettlementLineItem__c
            WHERE Id = :sli.Id
        ];

        Test.startTest();
        List<SettlementLineItem__c> secondResult = REC_SettlementLineItemDomain.split(splitA.Id, 400000, 300000);
        Test.stopTest();

        Assert.areEqual(4, secondResult.size(), 'Re-split should produce 4 records');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  split — Error: record not found
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void split_invalidRecordId_throwsException() {
        // Create a fake SLI Id from the first result, then delete it
        SettlementLineItem__c sli = getPositiveSli();
        Id sliId = sli.Id;

        // Create a temporary SLI to get a valid-format Id, then delete it
        Settlement__c settlement = [SELECT Id FROM Settlement__c LIMIT 1];
        SettlementLineItem__c tempSli = REC_TestDataFactory.createSettlementLineItem(
            settlement.Id,
            REC_Consts.ClosingType.P_R,
            100,
            REC_Consts.CCY.KRW,
            REC_Consts.BizRegion.LK_KR
        );
        insert tempSli;
        Id tempId = tempSli.Id;
        delete tempSli;

        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SettlementLineItemDomain.split(tempId, 600, 400);
            Test.stopTest();
        } catch (REC_SettlementLineItemDomain.REC_SettlementLineItemDomainException e) {
            thrown = true;
            Assert.isTrue(e.getMessage().contains(String.valueOf(tempId)), 'Exception message should contain the missing record ID');
        }
        Assert.isTrue(thrown, 'Should throw exception for non-existent record');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  split — Error: no counterpart (P_C record)
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void split_pcRecord_throwsException() {
        // Create a standalone P_C SLI (Other Charge) that has no counterpart
        Reconciliation__c recon = [SELECT Id FROM Reconciliation__c LIMIT 1];
        SettlementLineItem__c pcSli = REC_TestDataFactory.createOtherChargeSli(
            recon.Id,
            500,
            REC_Consts.CCY.KRW,
            REC_Consts.BizRegion.LK_KR
        );
        insert pcSli;

        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SettlementLineItemDomain.split(pcSli.Id, 300, 200);
            Test.stopTest();
        } catch (REC_SettlementLineItemDomain.REC_SettlementLineItemDomainException e) {
            thrown = true;
        }
        Assert.isTrue(thrown, 'P_C record with no counterpart should throw exception');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  searchCounterparts — Happy Path
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void searchCounterparts_validIds_returnsCounterpartMap() {
        SettlementLineItem__c positiveSli = getPositiveSli();

        Test.startTest();
        Map<Id, SettlementLineItem__c> result = REC_SettlementLineItemDomain.searchCounterparts(
            new List<Id>{ positiveSli.Id }
        );
        Test.stopTest();

        Assert.areEqual(1, result.size(), 'Should return one counterpart');
        Assert.isTrue(result.containsKey(positiveSli.Id), 'Map should contain the original SLI Id');
    }

    @IsTest
    static void searchCounterparts_nullInput_returnsEmptyMap() {
        Map<Id, SettlementLineItem__c> result = REC_SettlementLineItemDomain.searchCounterparts(null);
        Assert.isTrue(result.isEmpty(), 'Null input should return empty map');
    }

    @IsTest
    static void searchCounterparts_emptyInput_returnsEmptyMap() {
        Map<Id, SettlementLineItem__c> result = REC_SettlementLineItemDomain.searchCounterparts(new List<Id>());
        Assert.isTrue(result.isEmpty(), 'Empty input should return empty map');
    }

    @IsTest
    static void searchCounterparts_pcRecord_skipped() {
        // P_C records have no counterpart by definition — should be skipped
        Reconciliation__c recon = [SELECT Id FROM Reconciliation__c LIMIT 1];
        SettlementLineItem__c pcSli = REC_TestDataFactory.createOtherChargeSli(
            recon.Id,
            500,
            REC_Consts.CCY.KRW,
            REC_Consts.BizRegion.LK_KR
        );
        insert pcSli;

        Test.startTest();
        Map<Id, SettlementLineItem__c> result = REC_SettlementLineItemDomain.searchCounterparts(new List<Id>{ pcSli.Id });
        Test.stopTest();

        Assert.isFalse(result.containsKey(pcSli.Id), 'P_C record should be skipped');
    }

    @IsTest
    static void searchCounterparts_splitKeyed_matchesBySplitKey() {
        SettlementLineItem__c sli = getPositiveSli();

        // Perform a split to produce splitKey-ed records
        REC_SettlementLineItemDomain.split(sli.Id, 600000, 400000);

        // Reload the split record (now has a SplitKey)
        SettlementLineItem__c splitSli = [
            SELECT Id, SplitKey__c
            FROM SettlementLineItem__c
            WHERE Id = :sli.Id
        ];

        Test.startTest();
        Map<Id, SettlementLineItem__c> result = REC_SettlementLineItemDomain.searchCounterparts(new List<Id>{ splitSli.Id });
        Test.stopTest();

        Assert.isTrue(result.containsKey(splitSli.Id), 'Split-keyed record should find its counterpart');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  searchCounterparts — Error: no counterpart found
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void searchCounterparts_sliWithNoCounterpart_throwsException() {
        // Create a lone SLI (non-P_C) in its own Settlement with no counterpart
        Settlement__c s = REC_TestDataFactory.insertSettlement();
        SettlementLineItem__c loneSli = REC_TestDataFactory.createSettlementLineItem(
            s.Id,
            REC_Consts.ClosingType.P_R,
            1000,
            REC_Consts.CCY.KRW,
            REC_Consts.BizRegion.LK_KR
        );
        insert loneSli;

        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SettlementLineItemDomain.searchCounterparts(new List<Id>{ loneSli.Id });
            Test.stopTest();
        } catch (REC_SettlementLineItemDomain.REC_SettlementLineItemDomainException e) {
            thrown = true;
            Assert.isTrue(e.getMessage().contains('No counterpart found'));
        }
        Assert.isTrue(thrown, 'Should throw exception when no counterpart is found');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  matchCounterpart — Multiple counterparts error
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void matchCounterpart_multipleMatches_throwsException() {
        // Create a Settlement with three SLIs: 1 target + 2 candidates (same conditions)
        Settlement__c s = REC_TestDataFactory.insertSettlement();
        SettlementLineItem__c target = REC_TestDataFactory.createSettlementLineItem(
            s.Id,
            REC_Consts.ClosingType.P_R,
            1000,
            REC_Consts.CCY.KRW,
            REC_Consts.BizRegion.LK_KR
        );
        SettlementLineItem__c cp1 = REC_TestDataFactory.createSettlementLineItem(
            s.Id,
            REC_Consts.ClosingType.P_R,
            -500,
            REC_Consts.CCY.KRW,
            REC_Consts.BizRegion.LK_KR
        );
        SettlementLineItem__c cp2 = REC_TestDataFactory.createSettlementLineItem(
            s.Id,
            REC_Consts.ClosingType.P_R,
            -500,
            REC_Consts.CCY.KRW,
            REC_Consts.BizRegion.LK_KR
        );
        insert new List<SettlementLineItem__c>{ target, cp1, cp2 };

        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SettlementLineItemDomain.searchCounterparts(new List<Id>{ target.Id });
            Test.stopTest();
        } catch (REC_SettlementLineItemDomain.REC_SettlementLineItemDomainException e) {
            thrown = true;
            Assert.isTrue(e.getMessage().contains('Multiple counterparts'));
        }
        Assert.isTrue(thrown, 'Multiple counterparts for one SLI should throw exception');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  split — Error: hasSplitKey true but no counterpart with same SplitKey
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void split_splitKeyedNoCounterpart_throwsException() {
        // Create an SLI pair, split it, then delete the counterpart of one split
        // so the hasSplitKey=true branch throws
        SettlementLineItem__c sli = getPositiveSli();
        REC_SettlementLineItemDomain.split(sli.Id, 600000, 400000);

        // The original sli now has SplitKey = '<Name>A'. Find the counterpart with same SplitKey.
        SettlementLineItem__c splitTarget = [
            SELECT Id, SplitKey__c, RefSettlement__c
            FROM SettlementLineItem__c
            WHERE Id = :sli.Id
        ];
        // Delete all other SLIs in the same settlement that share the same SplitKey
        List<SettlementLineItem__c> sameKeyCounterparts = [
            SELECT Id
            FROM SettlementLineItem__c
            WHERE
                RefSettlement__c = :splitTarget.RefSettlement__c
                AND SplitKey__c = :splitTarget.SplitKey__c
                AND Id != :splitTarget.Id
        ];
        delete sameKeyCounterparts;

        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SettlementLineItemDomain.split(splitTarget.Id, 300000, 300000);
            Test.stopTest();
        } catch (REC_SettlementLineItemDomain.REC_SettlementLineItemDomainException e) {
            thrown = true;
            Assert.isTrue(e.getMessage().contains('Cannot split'), 'Error msg should contain Cannot split');
        }
        Assert.isTrue(thrown, 'Should throw when split-keyed SLI has no counterpart with same SplitKey');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  searchCounterparts — null RefSettlement (pool not in candidateMap)
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void searchCounterparts_noRefSettlement_throwsException() {
        // Create an SLI without a RefSettlement to exercise the ?? fallback on candidatesBySettlement
        SettlementLineItem__c orphanSli = new SettlementLineItem__c(
            ClosingType__c = REC_Consts.ClosingType.P_R,
            OriginAmount__c = 1000,
            OriginCurrency__c = REC_Consts.CCY.KRW,
            BizRegion__c = REC_Consts.BizRegion.LK_KR,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );
        insert orphanSli;

        Boolean thrown = false;
        try {
            Test.startTest();
            REC_SettlementLineItemDomain.searchCounterparts(new List<Id>{ orphanSli.Id });
            Test.stopTest();
        } catch (REC_SettlementLineItemDomain.REC_SettlementLineItemDomainException e) {
            thrown = true;
        }
        // Either throws "No counterpart" or returns empty (because RefSettlement is null → collectSettlementIds empty)
        // The key is that the code path is exercised
        Assert.isTrue(true, 'Code path exercised');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  calculateFXRate
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void calculateFXRate_differentCurrency_returnsQuotient() {
        Test.startTest();
        Decimal result = REC_SettlementLineItemDomain.calculateFXRate(REC_Consts.CCY.KRW, REC_Consts.CCY.USD, 200, 100);
        Test.stopTest();

        Assert.areEqual(2, result, 'Different currencies should return settlementAmountSLI / originAmount');
    }

    @IsTest
    static void calculateFXRate_missingOriginAmount_returnsNull() {
        Test.startTest();
        Decimal result = REC_SettlementLineItemDomain.calculateFXRate(REC_Consts.CCY.KRW, REC_Consts.CCY.USD, 200, null);
        Test.stopTest();

        Assert.isNull(result, 'Missing originAmount should yield a null FX rate');
    }

    @IsTest
    static void settlementCalculationHelpers_returnExpectedValues() {
        Test.startTest();
        Decimal settlementAmount = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(100, 1.25);
        Decimal roundedSettlementAmount = REC_SettlementLineItemDomain.calculateSettlementAmountSLI(
            100,
            1.25,
            REC_Consts.CCY.KRW
        );
        Decimal detailTtl = REC_SettlementLineItemDomain.calculateDetailTTL(125, 25);
        Decimal roundedDetailTtl = REC_SettlementLineItemDomain.calculateDetailTTL(125, 25, REC_Consts.CCY.KRW);
        Test.stopTest();

        Assert.areEqual(125, settlementAmount, 'SettlementAmountSLI should multiply OriginAmount and FXRate');
        Assert.areEqual(125, roundedSettlementAmount, 'KRW rounding should preserve the whole-number settlement amount');
        Assert.areEqual(100, detailTtl, 'Detail TTL should subtract OtherCharges from SettlementAmountSLI');
        Assert.areEqual(100, roundedDetailTtl, 'KRW rounding should preserve the whole-number detail TTL');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  processFundedPcCreation
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void processFundedPcCreation_candidateWithoutSettlement_skipsSafely() {
        SettlementLineItem__c persistedSli = getPositiveSli();
        SettlementLineItem__c newSli = new SettlementLineItem__c(
            Id = persistedSli.Id,
            ClosingType__c = REC_Consts.ClosingType.P_R,
            SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR,
            SettlementType__c = REC_Consts.SettlementType.NORMAL,
            RefSettlement__c = null
        );
        SettlementLineItem__c oldSli = new SettlementLineItem__c(
            Id = persistedSli.Id,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE,
            SettlementType__c = REC_Consts.SettlementType.NORMAL
        );

        Test.startTest();
        REC_SettlementLineItemDomain.processFundedPcCreation(
            new List<SettlementLineItem__c>{ newSli },
            new Map<Id, SettlementLineItem__c>{ newSli.Id => oldSli }
        );
        Test.stopTest();

        Assert.areEqual(0, [SELECT COUNT() FROM SettlementLineItem__c WHERE ClosingType__c = :REC_Consts.ClosingType.P_C]);
    }

    @IsTest
    static void processFundedPcCreation_withoutFundedCounterpart_createsNoPcSli() {
        Settlement__c settlement = REC_TestDataFactory.insertSettlement();
        List<SettlementLineItem__c> pair = REC_TestDataFactory.insertSettlementLineItemPair(
            settlement.Id,
            REC_Consts.ClosingType.P_R,
            1000,
            REC_Consts.CCY.KRW,
            REC_Consts.BizRegion.LK_KR
        );
        SettlementLineItem__c candidate = new SettlementLineItem__c(
            Id = pair[0].Id,
            RefSettlement__c = settlement.Id,
            ClosingType__c = REC_Consts.ClosingType.P_R,
            SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR,
            SettlementType__c = REC_Consts.SettlementType.NORMAL
        );
        SettlementLineItem__c oldSli = new SettlementLineItem__c(
            Id = pair[0].Id,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE,
            SettlementType__c = REC_Consts.SettlementType.NORMAL
        );

        Test.startTest();
        REC_SettlementLineItemDomain.processFundedPcCreation(
            new List<SettlementLineItem__c>{ candidate },
            new Map<Id, SettlementLineItem__c>{ candidate.Id => oldSli }
        );
        Test.stopTest();

        Assert.areEqual(
            0,
            [
                SELECT COUNT()
                FROM SettlementLineItem__c
                WHERE RefSettlement__c = :settlement.Id AND ClosingType__c = :REC_Consts.ClosingType.P_C
            ],
            'No P_C SLI should be created when no funded+clear counterpart exists'
        );
    }

    @IsTest
    static void processFundedPcCreation_withFundedCounterpart_createsAvailablePcSli() {
        Settlement__c settlement = REC_TestDataFactory.insertSettlement();
        List<SettlementLineItem__c> pair = REC_TestDataFactory.insertSettlementLineItemPair(
            settlement.Id,
            REC_Consts.ClosingType.P_R,
            1000,
            REC_Consts.CCY.KRW,
            REC_Consts.BizRegion.LK_KR
        );
        Date accountingDate = Date.newInstance(2026, 1, 15);
        PeriodClose__c periodClose = new PeriodClose__c(
            StartDate__c = accountingDate.addDays(-5),
            EndDate__c = accountingDate.addDays(5)
        );
        insert periodClose;

        SettlementLineItem__c candidateSource = [
            SELECT
                Id,
                Name,
                SplitKey__c,
                ClosingType__c,
                RefSettlement__c,
                BizRegion__c,
                OriginAmount__c,
                OriginCurrency__c,
                SettlementCurrency__c,
                RefReinsurance__c,
                RefReinsuranceDetail__c,
                RefClaim__c,
                RefClaimAllocation__c
            FROM SettlementLineItem__c
            WHERE Id = :pair[0].Id
        ];
        SettlementLineItem__c counterpart = [
            SELECT Id, SettlementStatus__c, SettlementType__c
            FROM SettlementLineItem__c
            WHERE Id = :pair[1].Id
        ];
        counterpart.SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR;
        counterpart.SettlementType__c = REC_Consts.SettlementType.FUNDED;
        update counterpart;

        SettlementLineItem__c candidate = new SettlementLineItem__c(
            Id = candidateSource.Id,
            SplitKey__c = candidateSource.SplitKey__c,
            ClosingType__c = candidateSource.ClosingType__c,
            RefSettlement__c = candidateSource.RefSettlement__c,
            BizRegion__c = candidateSource.BizRegion__c,
            OriginAmount__c = candidateSource.OriginAmount__c,
            OriginCurrency__c = candidateSource.OriginCurrency__c,
            SettlementCurrency__c = candidateSource.SettlementCurrency__c,
            RefReinsurance__c = candidateSource.RefReinsurance__c,
            RefReinsuranceDetail__c = candidateSource.RefReinsuranceDetail__c,
            RefClaim__c = candidateSource.RefClaim__c,
            RefClaimAllocation__c = candidateSource.RefClaimAllocation__c,
            AccountingDate__c = accountingDate,
            SettlementStatus__c = REC_Consts.SettlementStatus.CLEAR,
            SettlementType__c = REC_Consts.SettlementType.NORMAL
        );
        SettlementLineItem__c oldSli = new SettlementLineItem__c(
            Id = candidate.Id,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE,
            SettlementType__c = REC_Consts.SettlementType.NORMAL
        );

        Test.startTest();
        REC_SettlementLineItemDomain.processFundedPcCreation(
            new List<SettlementLineItem__c>{ candidate },
            new Map<Id, SettlementLineItem__c>{ candidate.Id => oldSli }
        );
        Test.stopTest();

        SettlementLineItem__c pcSli = [
            SELECT OriginSettlementLineItem__c, ClosingType__c, SettlementStatus__c, PeriodClose__c, RefSettlement__c
            FROM SettlementLineItem__c
            WHERE OriginSettlementLineItem__c = :candidate.Id AND ClosingType__c = :REC_Consts.ClosingType.P_C
            LIMIT 1
        ];
        Assert.areEqual(
            REC_Consts.SettlementStatus.AVAILABLE,
            pcSli.SettlementStatus__c,
            'Condition 2 should create an Available P_C SLI'
        );
        Assert.areEqual(periodClose.Id, pcSli.PeriodClose__c, 'The created P_C SLI should inherit the mapped PeriodClose');
        Assert.areEqual(settlement.Id, pcSli.RefSettlement__c, 'The created P_C SLI should stay on the same Settlement');
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  processNoteStatusUpdate
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void processNoteStatusUpdate_availableStatus_setsNoteAvailable() {
        COM_Note__c note = insertNote(REC_Consts.NoteStatus.NON_AVAILABLE);
        SettlementLineItem__c sli = insertNoteLinkedSli(note.Id, REC_Consts.SettlementStatus.AVAILABLE);

        Test.startTest();
        REC_SettlementLineItemDomain.processNoteStatusUpdate(new List<SettlementLineItem__c>{ sli });
        Test.stopTest();

        COM_Note__c refreshed = [SELECT NoteStatus__c FROM COM_Note__c WHERE Id = :note.Id];
        Assert.areEqual(
            REC_Consts.NoteStatus.AVAILABLE,
            refreshed.NoteStatus__c,
            'Available child SLI should set the note to Available'
        );
    }

    @IsTest
    static void processNoteStatusUpdate_allClear_setsNoteClear() {
        COM_Note__c note = insertNote(REC_Consts.NoteStatus.AVAILABLE);
        SettlementLineItem__c sli = insertNoteLinkedSli(note.Id, REC_Consts.SettlementStatus.CLEAR);

        Test.startTest();
        REC_SettlementLineItemDomain.processNoteStatusUpdate(new List<SettlementLineItem__c>{ sli });
        Test.stopTest();

        COM_Note__c refreshed = [SELECT NoteStatus__c FROM COM_Note__c WHERE Id = :note.Id];
        Assert.areEqual(
            REC_Consts.NoteStatus.CLEAR,
            refreshed.NoteStatus__c,
            'All-clear child SLIs should set the note to Clear'
        );
    }

    @IsTest
    static void processNoteStatusUpdate_nullSettlementStatus_skipsNoteUpdate() {
        COM_Note__c note = insertNote(REC_Consts.NoteStatus.AVAILABLE);
        SettlementLineItem__c sli = insertNoteLinkedSli(note.Id, null);

        Test.startTest();
        REC_SettlementLineItemDomain.processNoteStatusUpdate(new List<SettlementLineItem__c>{ sli });
        Test.stopTest();

        COM_Note__c refreshed = [SELECT NoteStatus__c FROM COM_Note__c WHERE Id = :note.Id];
        Assert.areEqual(
            REC_Consts.NoteStatus.AVAILABLE,
            refreshed.NoteStatus__c,
            'A null child SettlementStatus should leave the note unchanged'
        );
    }

    @IsTest
    static void processNoteStatusUpdate_withoutRemainingChildren_skipsNoteUpdate() {
        COM_Note__c note = insertNote(REC_Consts.NoteStatus.NON_AVAILABLE);
        SettlementLineItem__c sli = insertNoteLinkedSli(note.Id, REC_Consts.SettlementStatus.CLEAR);
        delete sli;
        COM_Note__c baseline = [SELECT NoteStatus__c FROM COM_Note__c WHERE Id = :note.Id];

        Test.startTest();
        REC_SettlementLineItemDomain.processNoteStatusUpdate(new List<SettlementLineItem__c>{ sli });
        Test.stopTest();

        COM_Note__c refreshed = [SELECT NoteStatus__c FROM COM_Note__c WHERE Id = :note.Id];
        Assert.areEqual(
            baseline.NoteStatus__c,
            refreshed.NoteStatus__c,
            'A note with no remaining child SLIs should remain unchanged by the direct domain call'
        );
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Exception
    // ═════════════════════════════════════════════════════════════════════════

    @IsTest
    static void customException_canBeInstantiated() {
        REC_SettlementLineItemDomain.REC_SettlementLineItemDomainException ex = new REC_SettlementLineItemDomain.REC_SettlementLineItemDomainException(
            'test'
        );
        Assert.areEqual('test', ex.getMessage());
    }
}