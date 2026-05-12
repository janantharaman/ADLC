/**
 * REC_FiduciaryOthersDomain — Business logic for FiduciaryOthers__c.
 */
public inherited sharing class REC_FiduciaryOthersDomain {
    // ═════════════════════════════════════════════════════════════════════════
    //  Status
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Determines FiduciaryOthers status based on the remaining not-reconciled amount.
     */
    public static String decideStatus(FiduciaryOthers__c fo) {
        if (fo.NotReconciledAMT__c == 0) {
            return REC_Consts.FiduciaryOthersStatus.CLEAR;
        }
        if (fo.NotReconciledAMT__c > 0) {
            return REC_Consts.FiduciaryOthersStatus.PARTIAL;
        }
        return null;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Reconciled Amount — Apply / Rollback
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Applies a reconciled amount to a FiduciaryOthers record, updating
     * reconciled totals and deriving status.
     */
    public static void applyReconciledAmount(FiduciaryOthers__c fo, Decimal reconAmount) {
        fo.ReconciledAMT__c = (fo.ReconciledAMT__c ?? 0) + reconAmount;
        fo.NotReconciledAMT__c = fo.OriginAmount__c - fo.ReconciledAMT__c;
        fo.Status__c = decideStatus(fo);
    }

    /**
     * Rolls back a reconciled amount from a FiduciaryOthers record (used when
     * deleting an RLI reference).
     */
    public static void rollbackReconciledAmount(FiduciaryOthers__c fo, Decimal reconAmount) {
        fo.ReconciledAMT__c -= reconAmount;
        fo.NotReconciledAMT__c = fo.OriginAmount__c - fo.ReconciledAMT__c;
        fo.Status__c = decideStatus(fo);
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Validation
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Validates that the reconciled amount does not exceed the remaining not-reconciled amount.
     * Rule: ABS(inputReconciledAmt) ≤ ABS(currentNotReconciledAmt)
     *
     * @param inputReconciledAmt        User-entered reconciled amount for this draft
     * @param currentNotReconciledAmt   NotReconciledAMT before this calculation (= remaining balance)
     */
    public static Boolean isReconciledAmountValid(Decimal inputReconciledAmt, Decimal currentNotReconciledAmt) {
        Decimal absInput = Math.abs(inputReconciledAmt ?? 0);
        Decimal absRemaining = Math.abs(currentNotReconciledAmt ?? 0);
        return absInput <= absRemaining;
    }

    /**
     * Server-side validation before DML.
     */
    public static List<REC_TableHelper.CellError> validate(List<FiduciaryOthers__c> records) {
        List<REC_TableHelper.CellError> errors = new List<REC_TableHelper.CellError>();

        for (FiduciaryOthers__c rec : records) {
            // ── Add business rules below ──────────────────────────────
        }

        return errors;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Custom Exception
    // ═════════════════════════════════════════════════════════════════════════

    public class REC_FiduciaryOthersDomainException extends Exception {
    }
}