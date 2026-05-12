@SuppressWarnings('PMD.PropertyNamingConventions,PMD.FieldNamingConventions')
public with sharing class REC_Consts {
    /* ═════════════════════════════════════════════════════════════════════════
     *  Currency
     * ═════════════════════════════════════════════════════════════════════════ */

    // ── Currency Code

    public static CCY CCY {
        get {
            return new CCY();
        }
    }

    public class CCY {
        public String KRW = 'KRW';
        public String USD = 'USD';
        public String VND = 'VND';
        public String EUR = 'EUR';
        public String JPY = 'JPY';
        public String CNY = 'CNY';
    }

    /* ═════════════════════════════════════════════════════════════════════════
     *  Biz Region
     * ═════════════════════════════════════════════════════════════════════════ */

    // ── Biz Region

    public static BizRegion BizRegion {
        get {
            return new BizRegion();
        }
    }

    public class BizRegion {
        public String LK_KR = 'LK_KR';
        public String LK_RE = 'LK_Re';
        public String LK_VN = 'LK_VN';
    }

    // ── COA by Biz Region
    public static Map<String, String> BizRegion_COA {
        get {
            return new Map<String, String>{ BizRegion.LK_RE => COA.CLOSING, BizRegion.LK_KR => COA.DEPOSIT_REINS };
        }
    }

    /* ═════════════════════════════════════════════════════════════════════════
     *  Reconciliation
     * ═════════════════════════════════════════════════════════════════════════ */

    // ── Reconciliation Status

    public static ReconciliationStatus ReconciliationStatus {
        get {
            return new ReconciliationStatus();
        }
    }

    public class ReconciliationStatus {
        public String DRAFT = 'Draft';
        public String CONFIRMED = 'Confirmed';
        public String CANCELED = 'Canceled';
    }

    // ── Reconciliation Base Type

    public static ReconciliationBaseType ReconciliationBaseType {
        get {
            return new ReconciliationBaseType();
        }
    }

    public class ReconciliationBaseType {
        public String STATEMENT = 'Statement';
        public String BANK_TRANSACTION = 'Bank Transaction';
        public String SETTLEMENT_LINE_ITEM = 'Settlement Line Item';
    }

    /* ═════════════════════════════════════════════════════════════════════════
     *  Settlement
     * ═════════════════════════════════════════════════════════════════════════ */

    // ── Settlement Status

    public static SettlementStatus SettlementStatus {
        get {
            return new SettlementStatus();
        }
    }

    public class SettlementStatus {
        public String NOT_AVAILABLE = 'Not-Available';
        public String AVAILABLE = 'Available';
        public String CLEAR = 'Clear';
    }

    // ── STC Status

    public static STCStatus STCStatus {
        get {
            return new STCStatus();
        }
    }

    public class STCStatus {
        public String PROVISIONAL = 'Provisional';
        public String CONFIRM = 'Confirm';
        public String REVERSED = 'Reversed';
        public String REVERSING = 'Reversing';
        public String CANCEL = 'Cancel';
    }

    // ── Closing Type

    public static ClosingType ClosingType {
        get {
            return new ClosingType();
        }
    }

    public class ClosingType {
        public String P_A = 'P_A';
        public String P_R = 'P_R';
        public String P_B = 'P_B';
        public String P_FA = 'P_FA';
        public String P_FL = 'P_FL';
        public String C_FA = 'C_FA';
        public String C_FL = 'C_FL';
        public String P_C = 'P_C';
        public String ADJ = 'ADJ';
    }

    // ── Closing Origin

    public static ClosingOrigin ClosingOrigin {
        get {
            return new ClosingOrigin();
        }
    }

    public class ClosingOrigin {
        public String INSURANCE_POLICY = 'Insurance Policy';
        public String PLACEMENT = 'Placement';
        public String CLAIM = 'Claim';
    }

    // ── Settlement Type

    public static SettlementType SettlementType {
        get {
            return new SettlementType();
        }
    }

    public class SettlementType {
        public String NORMAL = 'Normal';
        public String OFFSET = 'Off-set';
        public String FUNDED = 'Funded';
    }

    /* ═════════════════════════════════════════════════════════════════════════
     *  Bank Transaction
     * ═════════════════════════════════════════════════════════════════════════ */

    // ── Bank Transaction Status

    public static BankTransactionStatus BankTransactionStatus {
        get {
            return new BankTransactionStatus();
        }
    }

    public class BankTransactionStatus {
        public String NONE = 'None';
        public String CLEAR = 'Clear';
        public String PARTIAL = 'Partial';
    }

    // ── Transaction Type

    public static TransactionType TransactionType {
        get {
            return new TransactionType();
        }
    }

    public class TransactionType {
        public String DEPOSIT = 'Deposit';
        public String WITHDRAWAL = 'Withdrawal';
    }

    /* ═════════════════════════════════════════════════════════════════════════
     *  Fiduciary Others
     * ═════════════════════════════════════════════════════════════════════════ */

    // ── Fiduciary Others Status

    public static FiduciaryOthersStatus FiduciaryOthersStatus {
        get {
            return new FiduciaryOthersStatus();
        }
    }

    public class FiduciaryOthersStatus {
        public String NONE = 'None';
        public String CLEAR = 'Clear';
        public String PARTIAL = 'Partial';
    }

    /* ═════════════════════════════════════════════════════════════════════════
     *  COA
     * ═════════════════════════════════════════════════════════════════════════ */

    // ── COA
    public static COA COA {
        get {
            return new COA();
        }
    }

    public class COA {
        public String CLOSING = '99999999';
        public String DEPOSIT_REINS = '21401002';
    }

    /* ═════════════════════════════════════════════════════════════════════════
     *  Note
     * ═════════════════════════════════════════════════════════════════════════ */

    // --- Note Status

    public static NoteStatus NoteStatus {
        get {
            return new NoteStatus();
        }
    }

    public class NoteStatus {
        public String CLEAR = 'Clear';
        public String AVAILABLE = 'Available';
        public String NON_AVAILABLE = 'Non-Available';
    }

    /* ═════════════════════════════════════════════════════════════════════════
     *  Role
     * ═════════════════════════════════════════════════════════════════════════ */

    // --- Role

    public static Role Role {
        get {
            return new Role();
        }
    }

    public class Role {
        public String CEO = 'CEO';
        public String SETTLEMENT_TEAM = 'UserRole5'; // 경영관리팀 - 정청산 담당
    }

    public static BizRole BizRole {
        get {
            return new BizRole();
        }
    }

    public class BizRole {
        public String OPERATION = 'Operation';
        public String FINANCE = 'Finance';
    }

    /* ═════════════════════════════════════════════════════════════════════════
     *  Statement
     * ═════════════════════════════════════════════════════════════════════════ */

    // --- Statement Reconciled Status

    public static StatementReconciledStatus StatementReconciledStatus {
        get {
            return new StatementReconciledStatus();
        }
    }

    public class StatementReconciledStatus {
        public String NONE = 'None';
        public String CLEAR = 'Clear';
        public String PARTIAL = 'Partial';
    }

    // --- Statement Matching Status

    public static StatementMatchingStatus StatementMatchingStatus {
        get {
            return new StatementMatchingStatus();
        }
    }

    public class StatementMatchingStatus {
        public String UNMATCHED = 'Unmatched';
        public String MATCHED = 'Matched';
        public String READY_TO_MATCH = 'Ready to Match';
        public String PENDING_CONFIRMATION = 'Pending Confirmation';
    }

    /* ═════════════════════════════════════════════════════════════════════════
     *  Exchange Rate
     * ═════════════════════════════════════════════════════════════════════════ */

    // --- Exchange Rate Status

    public static ExchangeRateStatus ExchangeRateStatus {
        get {
            return new ExchangeRateStatus();
        }
    }

    public class ExchangeRateStatus {
        public String ACTIVE = 'Active';
        public String INACTIVE = 'inActive';
    }
}