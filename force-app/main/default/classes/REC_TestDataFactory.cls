/**
 * REC_TestDataFactory — Test data factory for the REC module.
 *
 * Design goals:
 *  - `create*` methods return unsaved SObjects (for bulk insert flexibility)
 *  - `insert*` methods insert and return the persisted record
 *  - Inner `BtBasedReconContext` holds the full object graph for BT-based tests
 *  - Field defaults are defined in one place — update constants here when the
 *    schema or picklist values change, minimising diff surface across all tests
 *
 * Object graph for BT-based reconciliation:
 *
 *   Settlement__c
 *     ├── SettlementLineItem__c  (detailSli,      +amount, Not-Available)
 *     └── SettlementLineItem__c  (counterpartSli, -amount, Not-Available)
 *   BankTransaction__c  (baseBt)
 *   Reconciliation__c   (linked to baseBt via BaseBankTransaction__c)
 *     └── ReconciliationLineItem__c (base BT RLI, RefBankTransaction__c = baseBt)
 */
@IsTest
public class REC_TestDataFactory {
    // ═════════════════════════════════════════════════════════════════════════
    //  Defaults — change here when schema or picklist values change
    // ═════════════════════════════════════════════════════════════════════════

    public static final String DEFAULT_BIZ_REGION = REC_Consts.BizRegion.LK_KR;
    public static final String DEFAULT_CURRENCY = REC_Consts.CCY.KRW;
    public static final String DEFAULT_CLOSING_TYPE = REC_Consts.ClosingType.P_R;
    public static final Decimal DEFAULT_ORIGIN_AMOUNT = 1000000;
    public static final Decimal DEFAULT_FX_RATE = 1.0;
    public static final Date DEFAULT_TX_DATE = Date.newInstance(2025, 6, 1);
    public static final String DEFAULT_DEPOSITOR = 'TestDepositor';
    public static final String DEFAULT_TX_TYPE = 'Deposit';
    public static final String DEFAULT_USER_REGION = 'KR';

    // ═════════════════════════════════════════════════════════════════════════
    //  Context — full object graph for a BT-based reconciliation scenario
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Holds every record that belongs to one BT-based reconciliation test scenario.
     * Use `setupBtBasedRecon()` to obtain a fully populated instance.
     */
    public class BtBasedReconContext {
        /** Bank Transaction the Reconciliation is initiated from. */
        public BankTransaction__c baseBt;
        /** Reconciliation header (Status is set by the first draft/confirm call). */
        public Reconciliation__c reconciliation;
        /** RLI linking the Reconciliation to the base BT. */
        public ReconciliationLineItem__c baseBtRli;
        /** Settlement that owns the SLI counterpart pair. */
        public Settlement__c settlement;
        /** Detail SLI — positive OriginAmount, Not-Available, used as reconciliation target. */
        public SettlementLineItem__c detailSli;
        /** Counterpart of detailSli — negative OriginAmount, Not-Available. */
        public SettlementLineItem__c counterpartSli;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Context — full object graph for an SLI-based reconciliation scenario
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Holds every record that belongs to one SLI-based reconciliation test scenario.
     * Use `setupSliBasedRecon()` to obtain a fully populated instance.
     *
     * Object graph:
     *   Settlement__c
     *     ├── SettlementLineItem__c  (baseSli,       +amount, Not-Available)
     *     └── SettlementLineItem__c  (counterpartSli, -amount, Not-Available)
     *   BankTransaction__c   (bt, available for reconciliation)
     *   FiduciaryOthers__c   (fo, available for reconciliation)
     *   Reconciliation__c    (linked to baseSli via BaseSettlementLineItem__c)
     *     └── ReconciliationLineItem__c (base SLI RLI, RefSettlementLineItem__c = baseSli)
     */
    public class SliBasedReconContext {
        /** Settlement that owns the SLI counterpart pair. */
        public Settlement__c settlement;
        /** Base SLI — positive OriginAmount, Not-Available, the Reconciliation origin. */
        public SettlementLineItem__c baseSli;
        /** Counterpart of baseSli — negative OriginAmount, Not-Available. */
        public SettlementLineItem__c counterpartSli;
        /** BankTransaction available for reconciliation (detail selection). */
        public BankTransaction__c bt;
        /** FiduciaryOthers available for reconciliation (detail selection). */
        public FiduciaryOthers__c fo;
        /** Reconciliation header (Status is set by the first draft/confirm call). */
        public Reconciliation__c reconciliation;
        /** RLI linking the Reconciliation to the base SLI. */
        public ReconciliationLineItem__c baseSliRli;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Settlement
    // ═════════════════════════════════════════════════════════════════════════

    /** Returns an unsaved Settlement__c with no mandatory fields. */
    public static Settlement__c createSettlement() {
        return new Settlement__c();
    }

    public static Settlement__c insertSettlement() {
        Settlement__c s = createSettlement();
        insert s;
        return s;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Settlement Line Item
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Returns an unsaved SettlementLineItem__c.
     *
     * @param settlementId  Parent Settlement lookup
     * @param closingType   e.g. REC_Consts.ClosingType.P_R
     * @param originAmount  Positive for the main side; negative for counterpart
     * @param currencyCode  OriginCurrency__c value
     * @param bizRegion     BizRegion__c value
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static SettlementLineItem__c createSettlementLineItem(
        Id settlementId,
        String closingType,
        Decimal originAmount,
        String ccy,
        String bizRegion
    ) {
        return new SettlementLineItem__c(
            RefSettlement__c = settlementId,
            ClosingType__c = closingType,
            OriginAmount__c = originAmount,
            OriginCurrency__c = ccy,
            BizRegion__c = bizRegion,
            SettlementStatus__c = REC_Consts.SettlementStatus.NOT_AVAILABLE
        );
    }

    /**
     * Inserts a counterpart pair (positive main + negative counterpart) into the
     * same Settlement and returns them as [main, counterpart].
     *
     * Per basic.md: SLIs are always created in pairs sharing the same Settlement.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static List<SettlementLineItem__c> insertSettlementLineItemPair(
        Id settlementId,
        String closingType,
        Decimal positiveAmount,
        String ccy,
        String bizRegion
    ) {
        SettlementLineItem__c main = createSettlementLineItem(settlementId, closingType, positiveAmount, ccy, bizRegion);
        SettlementLineItem__c cp = createSettlementLineItem(settlementId, closingType, -positiveAmount, ccy, bizRegion);
        insert new List<SettlementLineItem__c>{ main, cp };
        return new List<SettlementLineItem__c>{ main, cp };
    }

    /**
     * Returns an unsaved P_C SLI (Other Charge) linked to the given Reconciliation.
     * P_C SLIs have no counterpart (per basic.md) and are created only at Confirm time.
     */
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static SettlementLineItem__c createOtherChargeSli(Id reconId, Decimal amount, String ccy, String bizRegion) {
        return new SettlementLineItem__c(
            ClosingType__c = REC_Consts.ClosingType.P_C,
            OriginAmount__c = amount,
            OriginCurrency__c = ccy,
            BizRegion__c = bizRegion,
            OriginReconciliationNo__c = reconId
        );
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Bank Account (ACC_AdditionalInfo__c) — required lookup for BankTransaction
    // ═════════════════════════════════════════════════════════════════════════

    public static String getUserRegionForBizRegion(String bizRegion) {
        if (bizRegion == REC_Consts.BizRegion.LK_RE) {
            return 'SG';
        }
        if (bizRegion == REC_Consts.BizRegion.LK_VN) {
            return 'VN';
        }
        return DEFAULT_USER_REGION;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Region-scoped test user (avoids UNABLE_TO_LOCK_ROW on shared User row)
    // ═════════════════════════════════════════════════════════════════════════

    /** Cache keyed by bizRegion so repeat calls in the same transaction reuse the user. */
    private static Map<String, User> regionUserCache = new Map<String, User>();

    /**
     * Returns a test User whose `Region__c` matches the region required by `bizRegion`.
     * On cache miss, the running user is cloned (inheriting ProfileId and all
     * createable required fields), unique fields are regenerated, and the new
     * User is inserted inside a `System.runAs(runningUser)` block to avoid the
     * Mixed DML error when the same transaction has already inserted setup data.
     */
    public static User getOrCreateRegionUser(String bizRegion) {
        String region = getUserRegionForBizRegion(bizRegion);
        if (regionUserCache.containsKey(region)) {
            return regionUserCache.get(region);
        }
        User cloned = cloneRunningUser(region);
        System.runAs(new User(Id = UserInfo.getUserId())) {
            insert cloned;
        }
        regionUserCache.put(region, cloned);
        return cloned;
    }

    /**
     * Executes the given `Callable` as a region-scoped user and refreshes the
     * region caches that depend on `User.Region__c`.
     */
    public static void runAsRegionUser(String bizRegion, System.Callable work) {
        User u = getOrCreateRegionUser(bizRegion);
        System.runAs(u) {
            UserService.resetUserRegion();
            Util.resetForTest();
            work.call(null, null);
        }
    }

    /** Builds a dynamic SELECT listing every createable, non-calculated User field. */
    private static String buildUserSelectAllSoql() {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.User.fields.getMap();
        List<String> names = new List<String>();
        for (String name : fieldMap.keySet()) {
            Schema.DescribeFieldResult d = fieldMap.get(name).getDescribe();
            if (d.isCreateable() && !d.isCalculated()) {
                names.add(d.getName());
            }
        }
        return 'SELECT ' + String.join(names, ', ') + ' FROM User WHERE Id = :runningUserId LIMIT 1';
    }

    /**
     * Clones the running user, regenerates unique fields, nulls the federation
     * identifier, and injects the target `Region__c`. The resulting User is
     * unsaved — the caller is responsible for insertion.
     */
    private static User cloneRunningUser(String region) {
        Id runningUserId = UserInfo.getUserId();
        User source = Database.query(buildUserSelectAllSoql());
        User clone = source.clone(false, true, false, false);
        clone.Id = null;

        String suffix = String.valueOf(System.currentTimeMillis()) + String.valueOf(Math.abs(Crypto.getRandomInteger()));
        clone.Username = 'rec.test.' + suffix + '@example.invalid.test';
        clone.Email = 'rec.test.' + suffix + '@example.invalid.test';
        clone.Alias = ('t' + suffix).left(8);
        clone.CommunityNickname = ('recU' + suffix).left(40);
        clone.FederationIdentifier = null;
        clone.IsActive = true;
        clone.put('Region__c', region);
        return clone;
    }

    public static ACC_AdditionalInfo__c insertBankAccount() {
        ACC_AdditionalInfo__c ba = new ACC_AdditionalInfo__c(
            ActiveKr_is__c = true,
            ActiveRe_is__c = true,
            ActiveVn_is__c = true
        );
        insert ba;
        return ba;
    }

    public static Account createAccount(String name) {
        return ACC_TestDataFactory.createAccount(name, false);
    }

    public static Account insertAccount(String name) {
        return ACC_TestDataFactory.createAccount(name, true);
    }

    public static AccountDepositor__c createAccountDepositor(
        String depositor,
        String bizRegion,
        Id accountId,
        Boolean isActive
    ) {
        return new AccountDepositor__c(
            Depositor__c = depositor,
            BizRegion__c = bizRegion,
            AccountName__c = accountId,
            IsActive__c = isActive
        );
    }

    public static AccountDepositor__c insertAccountDepositor(
        String depositor,
        String bizRegion,
        Id accountId,
        Boolean isActive
    ) {
        AccountDepositor__c accountDepositor = createAccountDepositor(depositor, bizRegion, accountId, isActive);
        insert accountDepositor;
        return accountDepositor;
    }

    public static ACC_AdditionalInfo__c createAdditionalAccountInfo(Id accountId, String name) {
        return new ACC_AdditionalInfo__c(Account_lk__c = accountId, Name = name);
    }

    public static ACC_AdditionalInfo__c insertAdditionalAccountInfo(Id accountId, String name) {
        ACC_AdditionalInfo__c additionalInfo = createAdditionalAccountInfo(accountId, name);
        insert additionalInfo;
        return additionalInfo;
    }

    public static Placement__c createPlacement() {
        return new Placement__c();
    }

    public static Placement__c insertPlacement() {
        Placement__c placement = createPlacement();
        insert placement;
        return placement;
    }

    public static Claim createClaim(String name) {
        return new Claim(Name = name);
    }

    public static Claim insertClaim(String name) {
        Claim claimRecord = createClaim(name);
        insert claimRecord;
        return claimRecord;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Bank Transaction
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Returns an unsaved BankTransaction__c with reconciliation-relevant fields pre-filled.
     *
     * @param currencyCode  Currency__c value
     * @param originAmount  OriginAmount__c (also seeds NetBalanceAftCleared__c)
     * @param bizRegion     BizRegion__c value
     */
    public static BankTransaction__c createBankTransaction(String ccy, Decimal originAmount, String bizRegion) {
        return new BankTransaction__c(
            TransactionDate__c = DEFAULT_TX_DATE,
            Currency__c = ccy,
            OriginAmount__c = originAmount,
            TotalClearedAmount__c = 0,
            NetBalanceAftCleared__c = originAmount,
            BizRegion__c = bizRegion,
            Depositor__c = DEFAULT_DEPOSITOR,
            TransactionType__c = DEFAULT_TX_TYPE
        );
    }

    public static BankTransaction__c createBankTransaction(
        String ccy,
        Decimal originAmount,
        String bizRegion,
        Id bankAccountId
    ) {
        BankTransaction__c bt = createBankTransaction(ccy, originAmount, bizRegion);
        bt.BankAccount__c = bankAccountId;
        return bt;
    }

    /**
     * Inserts a BankTransaction__c using default Account info.
     *
     * Self-wraps the insert in `System.runAs(getOrCreateRegionUser(bizRegion))`
     * so the Lookup Filter on `BankAccount__c` (driven by `User.Region__c`) is
     * satisfied without the caller needing its own runAs wrapper.
     */
    public static BankTransaction__c insertBankTransaction(String ccy, Decimal originAmount, String bizRegion) {
        BankTransaction__c bt;
        System.runAs(getOrCreateRegionUser(bizRegion)) {
            UserService.resetUserRegion();
            Util.resetForTest();
            ACC_AdditionalInfo__c ba = insertBankAccount();
            bt = createBankTransaction(ccy, originAmount, bizRegion, ba.Id);
            insert bt;
        }
        return bt;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Fiduciary Others
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Returns an unsaved FiduciaryOthers__c with reconciliation-relevant fields pre-filled.
     *
     * @param ccy           SettlementCurrency__c value
     * @param originAmount  OriginAmount__c (also seeds NotReconciledAMT__c)
     * @param bizRegion     BizRegion__c value
     */
    public static FiduciaryOthers__c createFiduciaryOthers(String ccy, Decimal originAmount, String bizRegion) {
        return new FiduciaryOthers__c(
            TransactionDate__c = DEFAULT_TX_DATE,
            SettlementCurrency__c = ccy,
            OriginAmount__c = originAmount,
            ReconciledAMT__c = 0,
            NotReconciledAMT__c = originAmount,
            BizRegion__c = bizRegion
        );
    }

    public static FiduciaryOthers__c insertFiduciaryOthers(String ccy, Decimal originAmount, String bizRegion) {
        FiduciaryOthers__c fo = createFiduciaryOthers(ccy, originAmount, bizRegion);
        insert fo;
        return fo;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Reconciliation Line Item
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Returns an unsaved RLI that represents the base BT link
     * (created by createNewReconciliation — exposed here for direct-insert tests).
     */
    public static ReconciliationLineItem__c createBtRli(Id reconId, Id btId) {
        return new ReconciliationLineItem__c(RefReconciliation__c = reconId, RefBankTransaction__c = btId);
    }

    /**
     * Returns an unsaved RLI detail record suitable for passing as the `details`
     * parameter of draftBankTransactionBased / confirmBankTransactionBased.
     *
     * SettlementType defaulted to Normal (valid for positive-amount Not-Available SLIs).
     *
     * @param sliId    RefSettlementLineItem__c
     * @param fxRate   FXRateOrigintoSettlement__c (user-entered value)
     */
    public static ReconciliationLineItem__c createSliDetailRli(Id sliId, Decimal fxRate) {
        return new ReconciliationLineItem__c(
            RefSettlementLineItem__c = sliId,
            FXRateOrigintoSettlement__c = fxRate,
            SettlementType__c = REC_Consts.SettlementType.NORMAL
        );
    }

    /**
     * Returns an unsaved RLI detail record for SLI-based reconciliation,
     * referencing a BankTransaction with a user-entered ReconciledAMT.
     *
     * @param btId            RefBankTransaction__c
     * @param reconciledAmt   ReconciledAMT__c (user-entered value)
     */
    public static ReconciliationLineItem__c createBtReconDetailRli(Id btId, Decimal reconciledAmt) {
        return new ReconciliationLineItem__c(RefBankTransaction__c = btId, ReconciledAMT__c = reconciledAmt);
    }

    /**
     * Returns an unsaved RLI detail record for SLI-based reconciliation,
     * referencing a FiduciaryOthers with a user-entered ReconciledAMT.
     *
     * @param foId            RefFiduciaryOthers__c
     * @param reconciledAmt   ReconciledAMT__c (user-entered value)
     */
    public static ReconciliationLineItem__c createFoReconDetailRli(Id foId, Decimal reconciledAmt) {
        return new ReconciliationLineItem__c(RefFiduciaryOthers__c = foId, ReconciledAMT__c = reconciledAmt);
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Full BT-Based Reconciliation Context
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Creates and inserts the complete object graph required for BT-based
     * reconciliation tests:
     *
     *  1. Settlement
     *  2. Counterpart SLI pair  (P_R, +DEFAULT_ORIGIN_AMOUNT / -DEFAULT_ORIGIN_AMOUNT)
     *  3. BankTransaction       (DEFAULT_CURRENCY, DEFAULT_ORIGIN_AMOUNT)
     *  4. Reconciliation + base BT RLI  (via REC_ReconciliationDomain.createNewReconciliation)
     *
     * @return Fully populated BtBasedReconContext
     */
    public static BtBasedReconContext setupBtBasedRecon() {
        BtBasedReconContext ctx = new BtBasedReconContext();
        User regionUser = getOrCreateRegionUser(DEFAULT_BIZ_REGION);
        System.runAs(regionUser) {
            UserService.resetUserRegion();
            Util.resetForTest();

            // 1. Settlement (parent of the SLI pair)
            ctx.settlement = insertSettlement();

            // 2. SLI counterpart pair — positive for the detail side, negative for the counterpart
            List<SettlementLineItem__c> sliPair = insertSettlementLineItemPair(
                ctx.settlement.Id,
                DEFAULT_CLOSING_TYPE,
                DEFAULT_ORIGIN_AMOUNT,
                DEFAULT_CURRENCY,
                DEFAULT_BIZ_REGION
            );
            ctx.detailSli = sliPair[0]; // positive
            ctx.counterpartSli = sliPair[1]; // negative

            // 3. Base Bank Transaction
            ctx.baseBt = insertBankTransaction(DEFAULT_CURRENCY, DEFAULT_ORIGIN_AMOUNT, DEFAULT_BIZ_REGION);

            // 4. Reconciliation + base BT RLI  (domain handles insert)
            Id reconId = REC_ReconciliationDomain.createNewReconciliation(ctx.baseBt.Id);
            ctx.reconciliation = [
                SELECT Id, Status__c, BaseBankTransaction__c
                FROM Reconciliation__c
                WHERE Id = :reconId
                LIMIT 1
            ];
            ctx.baseBtRli = [
                SELECT Id, RefReconciliation__c, RefBankTransaction__c
                FROM ReconciliationLineItem__c
                WHERE RefReconciliation__c = :reconId AND RefBankTransaction__c != NULL
                LIMIT 1
            ];
        }

        return ctx;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Full SLI-Based Reconciliation Context
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Creates and inserts the complete object graph required for SLI-based
     * reconciliation tests:
     *
     *  1. Settlement
     *  2. Counterpart SLI pair  (P_R, +DEFAULT_ORIGIN_AMOUNT / -DEFAULT_ORIGIN_AMOUNT)
     *  3. BankTransaction       (DEFAULT_CURRENCY, DEFAULT_ORIGIN_AMOUNT)
     *  4. FiduciaryOthers       (DEFAULT_CURRENCY, DEFAULT_ORIGIN_AMOUNT)
     *  5. Reconciliation + base SLI RLI  (via REC_ReconciliationDomain.createNewReconciliation)
     *
     * @return Fully populated SliBasedReconContext
     */
    public static SliBasedReconContext setupSliBasedRecon() {
        SliBasedReconContext ctx = new SliBasedReconContext();
        User regionUser = getOrCreateRegionUser(DEFAULT_BIZ_REGION);
        System.runAs(regionUser) {
            UserService.resetUserRegion();
            Util.resetForTest();

            // 1. Settlement (parent of the SLI pair)
            ctx.settlement = insertSettlement();

            // 2. SLI counterpart pair — positive is used as the base record for reconciliation
            List<SettlementLineItem__c> sliPair = insertSettlementLineItemPair(
                ctx.settlement.Id,
                DEFAULT_CLOSING_TYPE,
                DEFAULT_ORIGIN_AMOUNT,
                DEFAULT_CURRENCY,
                DEFAULT_BIZ_REGION
            );
            ctx.baseSli = sliPair[0]; // positive
            ctx.counterpartSli = sliPair[1]; // negative

            // 3. Bank Transaction (available for selection in the BT panel)
            ctx.bt = insertBankTransaction(DEFAULT_CURRENCY, DEFAULT_ORIGIN_AMOUNT, DEFAULT_BIZ_REGION);

            // 4. Fiduciary Others (available for selection in the FO panel)
            ctx.fo = insertFiduciaryOthers(DEFAULT_CURRENCY, DEFAULT_ORIGIN_AMOUNT, DEFAULT_BIZ_REGION);

            // 5. Reconciliation + base SLI RLI  (domain handles insert)
            Id reconId = REC_ReconciliationDomain.createNewReconciliation(ctx.baseSli.Id);
            ctx.reconciliation = [
                SELECT Id, Status__c, BaseSettlementLineItem__c
                FROM Reconciliation__c
                WHERE Id = :reconId
                LIMIT 1
            ];
            ctx.baseSliRli = [
                SELECT Id, RefReconciliation__c, RefSettlementLineItem__c
                FROM ReconciliationLineItem__c
                WHERE RefReconciliation__c = :reconId AND RefSettlementLineItem__c != NULL
                LIMIT 1
            ];
        }

        return ctx;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Selector Test Context
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Creates the object graph required for Selector-layer tests.
     *
     * Builds on SLI-based reconciliation context, then adds detail RLIs
     * so that queryByReconWithBankTransaction / queryByBaseRecord / etc. have data.
     *
     * Object graph:
     *   Settlement__c
     *     ├── SettlementLineItem__c  (baseSli, +amount)
     *     └── SettlementLineItem__c  (counterpartSli, -amount)
     *   BankTransaction__c
     *   FiduciaryOthers__c
     *   Reconciliation__c  (SLI-based, Draft)
     *     ├── ReconciliationLineItem__c  (base SLI RLI)
     *     ├── ReconciliationLineItem__c  (BT detail RLI)
     *     └── ReconciliationLineItem__c  (FO detail RLI)
     */
    public static void setupSelectorTestData() {
        SliBasedReconContext ctx = setupSliBasedRecon();

        // Insert BT and FO detail RLIs linked to the Reconciliation
        insert new List<ReconciliationLineItem__c>{
            new ReconciliationLineItem__c(
                RefReconciliation__c = ctx.reconciliation.Id,
                RefBankTransaction__c = ctx.bt.Id,
                ReconciledAMT__c = DEFAULT_ORIGIN_AMOUNT
            ),
            new ReconciliationLineItem__c(
                RefReconciliation__c = ctx.reconciliation.Id,
                RefFiduciaryOthers__c = ctx.fo.Id,
                ReconciledAMT__c = DEFAULT_ORIGIN_AMOUNT
            )
        };
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Reverse Offset Context
    // ═════════════════════════════════════════════════════════════════════════

    /**
     * Holds the records for a reverse-offset reconciliation test scenario.
     *
     * Object graph:
     *   Settlement__c
     *     ├── SettlementLineItem__c  (detailSli,      +amount, Not-Available, P_R)
     *     └── SettlementLineItem__c  (counterpartSli, -amount, Not-Available, P_R)
     */
    public class ReverseOffsetContext {
        public Settlement__c settlement;
        public SettlementLineItem__c detailSli;
        public SettlementLineItem__c counterpartSli;
    }

    /**
     * Creates and inserts the object graph required for reverse-offset tests:
     *
     *  1. Settlement
     *  2. Counterpart SLI pair  (P_R, +DEFAULT_ORIGIN_AMOUNT / -DEFAULT_ORIGIN_AMOUNT)
     *
     * The Reconciliation is created by REC_ReconciliationDomain.processReverseOffset
     * during the test itself, so it is not included here.
     *
     * @return Fully populated ReverseOffsetContext
     */
    public static ReverseOffsetContext setupReverseOffset() {
        ReverseOffsetContext ctx = new ReverseOffsetContext();

        ctx.settlement = insertSettlement();

        List<SettlementLineItem__c> sliPair = insertSettlementLineItemPair(
            ctx.settlement.Id,
            DEFAULT_CLOSING_TYPE,
            DEFAULT_ORIGIN_AMOUNT,
            DEFAULT_CURRENCY,
            DEFAULT_BIZ_REGION
        );
        ctx.detailSli = sliPair[0];
        ctx.counterpartSli = sliPair[1];

        return ctx;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Statement
    // ═════════════════════════════════════════════════════════════════════════

    /** Returns an unsaved Statement__c linked to the given BankTransaction. */
    public static Statement__c createStatement(Id bankTransactionId) {
        return new Statement__c(
            RefBankTransaction__c = bankTransactionId,
            BizRegion__c = DEFAULT_BIZ_REGION,
            Currency__c = DEFAULT_CURRENCY,
            TransactionDate__c = DEFAULT_TX_DATE,
            ReconciledStatus__c = REC_Consts.ReconciliationStatus.DRAFT
        );
    }

    public static Statement__c insertStatement(Id bankTransactionId) {
        Statement__c s = createStatement(bankTransactionId);
        insert s;
        return s;
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  Statement Line Item
    // ═════════════════════════════════════════════════════════════════════════

    /** Returns an unsaved StatementLineItem__c linked to the given Statement. */
    public static StatementLineItem__c createStatementLineItem(Id statementId, String bizRegion) {
        return new StatementLineItem__c(RefStatement_lk__c = statementId, BizRegion__c = bizRegion);
    }

    public static StatementLineItem__c insertStatementLineItem(Id statementId, String bizRegion) {
        StatementLineItem__c sli = createStatementLineItem(statementId, bizRegion);
        insert sli;
        return sli;
    }
}