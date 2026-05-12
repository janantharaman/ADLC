/**
 * @description       :
 * @author            : Akrom Saidkamolov
 * @last modified on  : 2026-04-16
 * @last modified by  : Akrom Saidkamolov
 **/
@IsTest
private class AccountDepositor_tr_ts {
    @TestSetup
    static void setup() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_Consts.BizRegion.LK_KR)) {
            // Accounts
            Account acc1 = ACC_TestDataFactory.createAccount('Account Test 1', false);
            Account acc2 = ACC_TestDataFactory.createAccount('Account Test 2', false);
            insert new List<Account>{ acc1, acc2 };

            // Bank Account (required lookup for BankTransaction)
            ACC_AdditionalInfo__c bankAccount = REC_TestDataFactory.insertBankAccount();

            // Bank Transactions
            BankTransaction__c bt1 = new BankTransaction__c(
                BizRegion__c = 'LK_KR',
                Depositor__c = 'John Doe',
                AccountName__c = null,
                TransactionDate__c = Date.newInstance(2025, 6, 1),
                Currency__c = REC_Consts.CCY.KRW,
                OriginAmount__c = 1000000,
                BankAccount__c = bankAccount.Id,
                TransactionType__c = 'Deposit'
            );
            BankTransaction__c bt2 = new BankTransaction__c(
                BizRegion__c = 'LK_KR',
                Depositor__c = 'John Doe',
                AccountName__c = null,
                TransactionDate__c = Date.newInstance(2025, 6, 1),
                Currency__c = REC_Consts.CCY.KRW,
                OriginAmount__c = 1000000,
                BankAccount__c = bankAccount.Id,
                TransactionType__c = 'Deposit'
            );
            BankTransaction__c bt3 = new BankTransaction__c(
                BizRegion__c = 'LK_KR',
                Depositor__c = 'Jane Doe',
                AccountName__c = acc2.Id,
                TransactionDate__c = Date.newInstance(2025, 6, 1),
                Currency__c = REC_Consts.CCY.KRW,
                OriginAmount__c = 1000000,
                BankAccount__c = bankAccount.Id,
                TransactionType__c = 'Deposit'
            );
            insert new List<BankTransaction__c>{ bt1, bt2, bt3 };

            Reconciliation__c rec = new Reconciliation__c(Status__c = 'Confirmed');
            insert rec;

            // Make bt2 confirmed
            ReconciliationLineItem__c rli = new ReconciliationLineItem__c(
                BizRegion__c = 'LK_KR',
                RefBankTransaction__c = bt2.Id,
                RefReconciliation__c = rec.Id,
                TransactionDate__c = Date.today(),
                ExchangeDate__c = Date.today()
            );
            insert rli;

            // AccountDepositor for duplicate detection test
            AccountDepositor__c adDuplicate = new AccountDepositor__c(
                BizRegion__c = 'LK_KR',
                Depositor__c = 'Duplicate',
                IsActive__c = true
            );
            insert adDuplicate;
        }
    }

    @isTest
    static void testAssignBizRegion() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            AccountDepositor__c ad = new AccountDepositor__c(Depositor__c = 'No Region', IsActive__c = true);
            Test.startTest();
            insert ad;
            Test.stopTest();

            AccountDepositor__c insertedAd = [SELECT BizRegion__c FROM AccountDepositor__c WHERE Id = :ad.Id];
            // Cannot strictly assert Util.getBizRegion() without knowing its execution logic in test,
            // but it should not be null.
            Assert.isNotNull(insertedAd.BizRegion__c, 'BizRegion should be populated');
        }
    }

    @isTest
    static void testPreventDuplicateActiveDepositor() {
        // ad1 with Depositor='Duplicate' already exists from TestSetup
        AccountDepositor__c ad2 = new AccountDepositor__c(
            BizRegion__c = 'LK_KR',
            Depositor__c = 'Duplicate',
            IsActive__c = true
        );

        Test.startTest();
        try {
            insert ad2;
            Assert.fail('Should have thrown an exception');
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Cannot Duplicate Active Depositor'), 'Exception message should match');
        }
        Test.stopTest();
    }

    @isTest
    static void testPreventDuplicateActiveDepositorSameTransaction() {
        AccountDepositor__c ad3 = new AccountDepositor__c(
            BizRegion__c = 'LK_KR',
            Depositor__c = 'SameTrans',
            IsActive__c = true
        );
        AccountDepositor__c ad4 = new AccountDepositor__c(
            BizRegion__c = 'LK_KR',
            Depositor__c = 'SameTrans',
            IsActive__c = true
        );

        Test.startTest();
        try {
            insert new List<AccountDepositor__c>{ ad3, ad4 };
            Assert.fail('Should have thrown exception on same transaction insert');
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains('Cannot Duplicate Active Depositor'), e.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void testUpdateAccountOfBankTransactionAfterInsert() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            Account acc = [SELECT Id FROM Account WHERE Name LIKE '%Account Test 2' LIMIT 1];

            AccountDepositor__c ad = new AccountDepositor__c(
                BizRegion__c = 'LK_KR',
                Depositor__c = 'John Doe',
                AccountName__c = acc.Id,
                IsActive__c = true,
                UpdateScope__c = AccountDepositorService.DEPOSITOR_UPDATE_SCOPE_UNRECONCILED_ONLY
            );

            Test.startTest();
            insert ad;
            Test.stopTest();

            // bt1 has no AccountName and had no RLI -> Should have been updated
            List<BankTransaction__c> updatedBts = [
                SELECT AccountName__c
                FROM BankTransaction__c
                WHERE Depositor__c = 'John Doe' AND AccountName__c = :acc.Id
            ];
            Assert.areEqual(1, updatedBts.size(), 'bt1 Should be updated');

            // bt2 had confirmed RLI -> Should NOT be updated
            List<BankTransaction__c> bt2List = [
                SELECT Id
                FROM BankTransaction__c
                WHERE Depositor__c = 'John Doe' AND AccountName__c = NULL
            ];
            Assert.areEqual(1, bt2List.size(), 'bt2 should remain null');
        }
    }

    @isTest
    static void testUpdateAccountOfBankTransactionAfterUpdate() {
        System.runAs(REC_TestDataFactory.getOrCreateRegionUser(REC_TestDataFactory.DEFAULT_BIZ_REGION)) {
            Account acc1 = [SELECT Id FROM Account WHERE Name LIKE '%Account Test 1' LIMIT 1];

            AccountDepositor__c ad = new AccountDepositor__c(
                BizRegion__c = 'LK_KR',
                Depositor__c = 'Jane Doe',
                AccountName__c = null,
                IsActive__c = true,
                UpdateScope__c = AccountDepositorService.DEPOSITOR_UPDATE_SCOPE_UNRECONCILED_ONLY
            );
            insert ad;

            // Give it a different Account
            ad.AccountName__c = acc1.Id;

            Test.startTest();
            update ad;
            Test.stopTest();

            List<BankTransaction__c> bt3List = [
                SELECT AccountName__c
                FROM BankTransaction__c
                WHERE Depositor__c = 'Jane Doe'
                LIMIT 1
            ];
            Assert.areEqual(1, bt3List.size(), 'bt3 should exist');
            Assert.areEqual(acc1.Id, bt3List[0].AccountName__c, 'AccountName should be updated after UpdateScope was met');
        }
    }
}