/**
 * REC_BankTransactionDomain — Business logic for BankTransaction__c.
 */
public inherited sharing class REC_BankTransactionDomain {
    // ═════════════════════════════════════════════════════════════════════════
    //  Status
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Determines status based on the remaining net balance.
     */
    public static String decideStatus(Decimal netBalance) {
        if (netBalance == 0) {
            return REC_Consts.BankTransactionStatus.CLEAR;
        }
        if (netBalance > 0) {
            return REC_Consts.BankTransactionStatus.PARTIAL;
        }
        return null;
    }

    public static String decideStatus(BankTransaction__c bt) {
        return decideStatus(bt.NetBalanceAftCleared__c);
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Reconciled Amount — Apply / Rollback
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Applies a reconciled amount to a BankTransaction, updating cleared totals
     * and deriving status.
     */
    public static void applyReconciledAmount(BankTransaction__c bt, Decimal reconAmount) {
        bt.TotalClearedAmount__c = (bt.TotalClearedAmount__c ?? 0) + reconAmount;
        bt.NetBalanceAftCleared__c = bt.OriginAmount__c - bt.TotalClearedAmount__c;
        bt.Status__c = decideStatus(bt);
    }

    /**
     * Rolls back a reconciled amount from a BankTransaction (used when
     * deleting an RLI reference).
     */
    public static void rollbackReconciledAmount(BankTransaction__c bt, Decimal reconAmount) {
        bt.TotalClearedAmount__c -= reconAmount;
        bt.NetBalanceAftCleared__c = bt.OriginAmount__c - bt.TotalClearedAmount__c;
        bt.Status__c = decideStatus(bt);
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Upload Statement
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Checks if the "Upload Statement" button should be disabled for given BankTransaction IDs.
     */
    public static Map<Id, Boolean> checkStatementUploadDisabled(Set<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) {
            return new Map<Id, Boolean>();
        }

        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for (Id recId : recordIds) {
            result.put(recId, false);
        }

        for (Reconciliation__c rec : [
            SELECT Id, BaseStatement__r.RefBankTransaction__c
            FROM Reconciliation__c
            WHERE BaseStatement__r.RefBankTransaction__c IN :recordIds
            WITH SYSTEM_MODE
            LIMIT 1000
        ]) {
            Id btId = rec.BaseStatement__r.RefBankTransaction__c;
            if (btId != null) {
                result.put(btId, true);
            }
        }

        return result;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Validation
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Server-side validation before DML.
     * Each violation produces a CellError the UI renders on the exact cell.
     */
    @TestVisible
    private static List<REC_TableHelper.CellError> testValidationErrors;

    public static List<REC_TableHelper.CellError> validate(List<BankTransaction__c> records) {
        List<REC_TableHelper.CellError> errors = new List<REC_TableHelper.CellError>();

        // Test hook — allows injection of validation errors for path coverage
        if (testValidationErrors != null) {
            errors.addAll(testValidationErrors);
            testValidationErrors = null;
            return errors;
        }

        for (BankTransaction__c rec : records) {
            // ── Add business rules below ──────────────────────────────
            // Example:
            // if (rec.Status__c == 'Clear' && String.isBlank(rec.Remarks__c)) {
            //     errors.add(new REC_TableHelper.CellError(rec.Id, 'Remarks__c', 'Remarks is required when status is Clear.'));
            // }
        }

        return errors;
    }

    /**
     * Validates AccountName changes: checks that matching AccountDepositor records exist.
     * Only rows whose Id is in accountNameChangedIds are validated.
     *
     * @param records               Parsed BankTransaction records (Id + updatable fields only)
     * @param accountNameChangedIds Set of BT Ids where AccountName__c was changed by the user
     * @return CellErrors for rows that fail validation (excluded from save)
     */
    public static List<REC_TableHelper.CellError> validateAccountMapping(
        List<BankTransaction__c> records,
        Set<Id> accountNameChangedIds
    ) {
        List<REC_TableHelper.CellError> errors = new List<REC_TableHelper.CellError>();
        if (accountNameChangedIds == null || accountNameChangedIds.isEmpty()) {
            return errors;
        }

        // Collect BT Ids that need validation
        Set<Id> btIdsToCheck = new Set<Id>();
        Map<Id, BankTransaction__c> parsedMap = new Map<Id, BankTransaction__c>();
        for (BankTransaction__c rec : records) {
            if (accountNameChangedIds.contains(rec.Id)) {
                btIdsToCheck.add(rec.Id);
                parsedMap.put(rec.Id, rec);
            }
        }
        if (btIdsToCheck.isEmpty())
            return errors;

        // Re-query original BT to get BizRegion__c and Depositor__c (not in updatable fields)
        Map<Id, BankTransaction__c> originalMap = new Map<Id, BankTransaction__c>(
            [
                SELECT Id, BizRegion__c, Depositor__c
                FROM BankTransaction__c
                WHERE Id IN :btIdsToCheck
            ]
        );

        // Collect lookup keys for bulk query
        Set<String> setBizRegion = new Set<String>();
        Set<String> setDepositor = new Set<String>();
        Set<Id> setAccountNameId = new Set<Id>();

        for (Id btId : btIdsToCheck) {
            BankTransaction__c orig = originalMap.get(btId);
            BankTransaction__c parsed = parsedMap.get(btId);
            if (orig == null)
                continue;

            // Check Depositor is present
            if (String.isBlank(orig.Depositor__c)) {
                errors.add(
                    new REC_TableHelper.CellError(btId, 'Depositor__c', 'Depositor is required when changing Account Name.')
                );
                continue;
            }

            if (parsed.AccountName__c != null) {
                setBizRegion.add(orig.BizRegion__c);
                setDepositor.add(orig.Depositor__c);
                setAccountNameId.add(parsed.AccountName__c);
            }
        }

        // Bulk query existing AccountDepositor keys
        Set<String> existingKeys = AccountDepositorService.findActiveAccountDepositorKeys(
            setBizRegion,
            setDepositor,
            setAccountNameId
        );

        // Validate each changed row
        for (Id btId : btIdsToCheck) {
            BankTransaction__c orig = originalMap.get(btId);
            BankTransaction__c parsed = parsedMap.get(btId);
            if (orig == null || String.isBlank(orig.Depositor__c))
                continue; // already reported

            if (parsed.AccountName__c == null) {
                // AccountName cleared — skip validation (allow null)
                continue;
            }

            String key = orig.BizRegion__c + '_' + orig.Depositor__c + '_' + parsed.AccountName__c;
            if (!existingKeys.contains(key)) {
                errors.add(
                    new REC_TableHelper.CellError(
                        btId,
                        'AccountName__c',
                        'No active Account-Depositor mapping found for this combination.'
                    )
                );
            }
        }

        return errors;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Exception
    // ═════════════════════════════════════════════════════════════════════════

    public class REC_BankTransactionDomainException extends Exception {
    }
}