/**
 * @group        : Trestle
 * @description  : Excel Upload Controller with enhanced stability and timezone safety
 * @author       : Yugon Hwang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   02-23-2026   Yugon Hwang   Initial Version
 **/
public with sharing class ExcelFileUploadController {
    private static final String STATUS_ACTIVE = 'Active';

    private static final String TRANSACTION_TYPE_DEPOSIT = 'Deposit';
    private static final String TRANSACTION_TYPE_WITHDRAWAL = 'Withdrawal';

    /**
     * Exchange Rate
     */
    @AuraEnabled
    public static DuplicateCheckResult checkDuplicateExchangeRates(List<ExcelRow> rows) {
        Logger.setScenario('ExcelFileUploadController.checkDuplicateExchangeRates');
        Logger.info('rows :: ' + rows);
        try {
            Set<String> setCurrency = new Set<String>();
            Set<Date> setBaseDate = new Set<Date>();

            for (ExcelRow row : rows) {
                String currencyCode = rowValToString(row, new List<String>{ '통화', 'Currency' }) ??
                    Util.getRegionCurrency();
                Date baseDate = rowValToDate(row, new List<String>{ '일자', 'Date' });
                setCurrency.add(currencyCode);
                setBaseDate.add(baseDate);
            }

            Map<String, ExchangeRate__c> existingRatesMap = ExchangeRateService.getExistingRatesMap(
                new List<String>(setCurrency),
                new List<Date>(setBaseDate)
            );
            Logger.info('existingRatesMap :: ' + existingRatesMap);
            List<DuplicateRow> duplicateRows = new List<DuplicateRow>();

            for (ExcelRow row : rows) {
                ExchangeRate__c rate = populateExchangeRate(row);
                if (rate.BaseDate__c == null) {
                    continue;
                }

                if (existingRatesMap.containsKey(ExchangeRateService.getExchangeRateKey(rate))) {
                    duplicateRows.add(new DuplicateRow(row.rowNumber, rate.Currency__c, rate.BaseDate__c));
                }
            }

            DuplicateCheckResult result = new DuplicateCheckResult(duplicateRows);
            Logger.info('result :: ' + result);
            return result;
        } catch (Exception e) {
            Logger.error(e.getMessage() + ' :: ' + e.getStackTraceString());
            throw new AuraHandledException('중복 확인 중 서버 오류가 발생했습니다: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }

    @AuraEnabled
    public static UploadResult uploadExchangeRate(List<ExcelRow> rows) {
        Logger.setScenario('ExcelFileUploadController.uploadExchangeRate');
        Logger.info('rows :: ' + rows);
        try {
            Set<String> setCurrency = new Set<String>();
            Set<Date> setBaseDate = new Set<Date>();

            for (ExcelRow row : rows) {
                String currencyCode = rowValToString(row, new List<String>{ '통화', 'Currency' }) ??
                    Util.getRegionCurrency();
                Date baseDate = rowValToDate(row, new List<String>{ '일자', 'Date' });
                if (baseDate != null) {
                    setCurrency.add(currencyCode);
                    setBaseDate.add(baseDate);
                }
            }

            Map<String, ExchangeRate__c> existingRatesMap = ExchangeRateService.getExistingRatesMap(
                new List<String>(setCurrency),
                new List<Date>(setBaseDate)
            );

            Map<Integer, Integer> recordIndexToRow = new Map<Integer, Integer>();
            List<RowError> errors = new List<RowError>();
            List<ExchangeRate__c> exchangeRatesToInsert = new List<ExchangeRate__c>();
            Set<String> processedInBatch = new Set<String>();
            Integer duplicateCount = 0;

            for (ExcelRow row : rows) {
                try {
                    ExchangeRate__c rate = populateExchangeRate(row);
                    if (rate.BaseDate__c == null) {
                        errors.add(new RowError(row.rowNumber, 'Mapping', '일자 필드가 비어있습니다.'));
                        continue;
                    }

                    String rateKey = ExchangeRateService.getExchangeRateKey(rate);
                    if (existingRatesMap.containsKey(rateKey)) {
                        duplicateCount++;
                    } else if (!processedInBatch.contains(rateKey)) {
                        exchangeRatesToInsert.add(rate);
                        recordIndexToRow.put(exchangeRatesToInsert.size() - 1, row.rowNumber);
                        processedInBatch.add(rateKey);
                    }
                } catch (Exception e) {
                    errors.add(new RowError(row.rowNumber, 'Mapping', e.getMessage()));
                }
            }

            Logger.info('exchangeRatesToInsert :: ' + exchangeRatesToInsert);
            if (!exchangeRatesToInsert.isEmpty()) {
                insertAndReportErrors(exchangeRatesToInsert, recordIndexToRow, errors);
            }

            UploadResult result = new UploadResult(errors);
            result.totalCount = rows.size();
            result.duplicateCount = duplicateCount;
            result.errorCount = errors.size();
            result.createdCount = errors.isEmpty() ? exchangeRatesToInsert.size() : 0;

            Logger.info('result :: ' + result);
            return result;
        } catch (Exception e) {
            Logger.error(e.getMessage() + ' :: ' + e.getStackTraceString());
            throw new AuraHandledException('서버 오류: ' + e.getMessage());
        } finally {
            Logger.saveLog();
        }
    }

    private static ExchangeRate__c populateExchangeRate(ExcelRow row) {
        ExchangeRate__c rate = new ExchangeRate__c();
        rate.BizRegion__c = Util.getBizRegion();

        rate.Currency__c = rowValToString(row, new List<String>{ '통화', 'Currency' }) ?? Util.getRegionCurrency();
        rate.BaseDate__c = rowValToDate(row, new List<String>{ '일자', 'Date' });

        List<String> rateKeys = new List<String>{
            '매매기준율',
            '매매기준율(고객)',
            '매매기준율(전신환)',
            'Selling/BuyingRate',
            'WhenSending',
            'WhenReceiving',
            'AtTimeofPurchase',
            'AtTimeofSelling'
        };
        rate.ExchangeRate__c = rowValToCurrency(row, rateKeys);

        List<String> usdRateKeys = new List<String>{ '미화환산율', 'USDConversionRate' };
        rate.USDRate__c = rowValToDecimal(row, usdRateKeys);

        rate.Status__c = STATUS_ACTIVE;

        if (rate.BaseDate__c != null) {
            String dateStr = String.valueOf(rate.BaseDate__c).left(10);
            rate.Name = dateStr + '_' + rate.Currency__c;
        }

        return rate;
    }

    @TestVisible
    private static Map<String, Map<Date, Decimal>> getExchangeRateMap(List<ExcelRow> rows) {
        Map<String, Map<Date, Decimal>> resultMap = new Map<String, Map<Date, Decimal>>();
        Set<String> setCurrency = new Set<String>();
        Date oldestDate;
        Date newestDate;

        for (ExcelRow row : rows) {
            Date kDate = rowValToDate(row, new List<String>{ '거래일', '거래일시' });
            if (kDate != null && (oldestDate == null || kDate < oldestDate)) {
                oldestDate = kDate;
            }
            if (kDate != null && (newestDate == null || kDate > newestDate)) {
                newestDate = kDate;
            }

            String kCurrency = rowValToString(row, '통화');
            if (String.isNotBlank(kCurrency)) {
                setCurrency.add(kCurrency);
            }
        }

        if (setCurrency.isEmpty()) {
            return resultMap;
        }

        // Fallback 로직 제거: 정확한 날짜의 환율만 조회
        Date queryMinDate = (oldestDate != null) ? oldestDate : Date.today();
        Date queryMaxDate = (newestDate != null) ? newestDate : Date.today();

        // Query optimization
        for (ExchangeRate__c er : [
            SELECT BaseDate__c, Currency__c, ExchangeRate__c
            FROM ExchangeRate__c
            WHERE
                Currency__c IN :setCurrency
                AND BaseDate__c >= :queryMinDate
                AND BaseDate__c <= :queryMaxDate
                AND Status__c = :STATUS_ACTIVE
            ORDER BY BaseDate__c DESC
        ]) {
            if (!resultMap.containsKey(er.Currency__c)) {
                resultMap.put(er.Currency__c, new Map<Date, Decimal>());
            }
            resultMap.get(er.Currency__c).put(er.BaseDate__c, er.ExchangeRate__c);
        }
        return resultMap;
    }

    /********************************************************
     * BankTransaction
     ********************************************************/
    @AuraEnabled
    public static UploadResult uploadBankTransaction(List<ExcelRow> rows, Id bankAccountId) {
        try {
            Map<Integer, Integer> recordIndexToRow = new Map<Integer, Integer>();
            List<RowError> errors = new List<RowError>();
            List<BankTransaction__c> transactionsToInsert = new List<BankTransaction__c>();

            for (ExcelRow row : rows) {
                try {
                    BankTransaction__c bt = populateBankTransaction(row);
                    bt.BankAccount__c = bankAccountId;
                    transactionsToInsert.add(bt);
                    recordIndexToRow.put(transactionsToInsert.size() - 1, row.rowNumber);
                } catch (Exception e) {
                    errors.add(new RowError(row.rowNumber, 'Mapping', e.getMessage()));
                }
            }

            if (!transactionsToInsert.isEmpty()) {
                insertAndReportErrors(transactionsToInsert, recordIndexToRow, errors);
            }

            UploadResult result = new UploadResult(errors);
            result.totalCount = rows.size();
            result.errorCount = errors.size();
            result.createdCount = errors.isEmpty() ? transactionsToInsert.size() : 0;
            result.duplicateCount = 0;
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('서버 오류: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static BankDuplicateCheckResult checkDuplicateBankTransactions(List<ExcelRow> rows, Id bankAccountId) {
        Set<DateTime> transactionDates = new Set<DateTime>();
        Set<Decimal> originAmounts = new Set<Decimal>();

        for (ExcelRow row : rows) {
            DateTime transDate = rowValToDateTime(
                row,
                new List<String>{ '거래일시', 'TransactionDate&Type', 'TransactionDate' }
            );
            if (transDate != null)
                transactionDates.add(transDate);

            Decimal originAmount = isZeroOrNull(rowValToCurrency(row, new List<String>{ '입금', 'DepositAmount' }))
                ? rowValToCurrency(row, new List<String>{ '출금', 'WithdrawalAmount' })
                : rowValToCurrency(row, new List<String>{ '입금', 'DepositAmount' });

            if (originAmount != null)
                originAmounts.add(originAmount);
        }

        Set<String> existingTransactionKeys = new Set<String>();
        if (!transactionDates.isEmpty() && !originAmounts.isEmpty()) {
            for (BankTransaction__c bt : [
                SELECT BankAccount__c, Depositor__c, OriginAmount__c, Currency__c, TransactionDateTime__c, Balance__c
                FROM BankTransaction__c
                WHERE
                    BizRegion__c != NULL
                    AND BizRegion__c = :Util.getBizRegion()
                    AND BankAccount__c = :bankAccountId
                    AND TransactionDateTime__c IN :transactionDates
                    AND OriginAmount__c IN :originAmounts
            ]) {
                existingTransactionKeys.add(getBankTransactionKey(bt));
            }
        }

        List<ExcelRow> duplicateRows = new List<ExcelRow>();
        Set<String> processedKeysInFile = new Set<String>();

        for (ExcelRow row : rows) {
            DateTime transDate = rowValToDateTime(
                row,
                new List<String>{ '거래일시', 'TransactionDate&Type', 'TransactionDate' }
            );
            Decimal originAmount = isZeroOrNull(rowValToCurrency(row, new List<String>{ '입금', 'DepositAmount' }))
                ? rowValToCurrency(row, new List<String>{ '출금', 'WithdrawalAmount' })
                : rowValToCurrency(row, new List<String>{ '입금', 'DepositAmount' });

            String depositor = rowValToString(row, new List<String>{ '의뢰인', '의뢰인/수취인', 'Depositor' });
            Decimal balance = rowValToCurrency(row, new List<String>{ '거래후잔액', 'Balance' });
            String currencyCode = rowValToString(row, new List<String>{ '통화', 'Currency' }) ?? Util.getRegionCurrency();

            BankTransaction__c tempBt = new BankTransaction__c(
                BankAccount__c = bankAccountId,
                Depositor__c = depositor,
                OriginAmount__c = originAmount,
                Currency__c = currencyCode,
                TransactionDateTime__c = transDate,
                Balance__c = balance
            );
            String key = getBankTransactionKey(tempBt);

            if (existingTransactionKeys.contains(key) || processedKeysInFile.contains(key)) {
                duplicateRows.add(row);
            }
            processedKeysInFile.add(key);
        }

        return new BankDuplicateCheckResult(duplicateRows);
    }

    private static BankTransaction__c populateBankTransaction(ExcelRow row) {
        BankTransaction__c bt = new BankTransaction__c();

        bt.BizRegion__c = Util.getBizRegion();

        // 날짜 및 통화 설정 (Timezone Safety 적용)
        bt.TransactionDateTime__c = rowValToDateTime(
            row,
            new List<String>{ '거래일시', 'TransactionDate&Type', 'TransactionDate' }
        );
        bt.TransactionDate__c = bt.TransactionDateTime__c?.date();
        bt.Currency__c = rowValToString(row, new List<String>{ '통화', 'Currency' }) ?? Util.getRegionCurrency();

        // 금액 설정 (입금/출금 통합 처리)
        bt.OriginAmount__c = isZeroOrNull(rowValToCurrency(row, new List<String>{ '입금', 'DepositAmount' }))
            ? rowValToCurrency(row, new List<String>{ '출금', 'WithdrawalAmount' })
            : rowValToCurrency(row, new List<String>{ '입금', 'DepositAmount' });
        bt.Balance__c = rowValToCurrency(row, new List<String>{ '거래후잔액', 'Balance' });
        bt.TransactionType__c = bt.OriginAmount__c > 0 ? TRANSACTION_TYPE_DEPOSIT : TRANSACTION_TYPE_WITHDRAWAL;

        // 기타 정보
        bt.No__c = rowValToDecimal(row, 'No');
        bt.Remarks__c = rowValToString(row, new List<String>{ '적요', 'Remarks' });
        bt.TransactionDetailType__c = rowValToString(row, new List<String>{ '구분', 'Type' });
        bt.Depositor__c = rowValToString(row, new List<String>{ '의뢰인', '의뢰인/수취인', 'Depositor' });
        bt.Branch__c = rowValToString(row, new List<String>{ '은행', '거래점', 'Branch' });
        bt.TransactionNotes__c = rowValToString(row, new List<String>{ '거래특이사항', 'TransactionNote' });

        return bt;
    }

    @AuraEnabled(cacheable=true)
    public static Id getDefaultBankAccountId() {
        try {
            String bizRegion = Util.getBizRegion();
            Account regionAccount = [SELECT Id FROM Account WHERE LKInternalRegion__c = :bizRegion LIMIT 1] ?? null;

            if (regionAccount == null) {
                return null;
            }

            List<ACC_AdditionalInfo__c> listBankAccounts = new List<ACC_AdditionalInfo__c>(
                [
                    SELECT Id
                    FROM ACC_AdditionalInfo__c
                    WHERE Account_lk__c = :regionAccount.Id
                ]
            );

            if (listBankAccounts.size() == 1) {
                return listBankAccounts.get(0).Id;
            }

            return null;
        } catch (Exception e) {
            throw e;
        }
    }

    /**
     * Utils
     */

    private static void insertAndReportErrors(
        List<SObject> records,
        Map<Integer, Integer> indexToRow,
        List<RowError> errors
    ) {
        Savepoint sp = Database.setSavepoint();
        List<Database.SaveResult> results = Database.insert(records, false);

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                Integer actualRow = indexToRow.get(i);
                for (Database.Error err : results[i].getErrors()) {
                    errors.add(new RowError(actualRow, 'Database', err.getMessage()));
                }
            }
        }

        if (!errors.isEmpty()) {
            Database.rollback(sp);
        }
    }

    // ===== UTILS =====
    private static Date rowValToDate(ExcelRow row, List<String> keys) {
        for (String key : keys) {
            String val = rowValToString(row, key);
            if (String.isNotBlank(val)) {
                try {
                    return (val.length() > 10) ? DateTime.valueOf(val).date() : Date.valueOf(val);
                } catch (Exception e) {
                    continue;
                }
            }
        }
        return null;
    }

    private static DateTime rowValToDateTime(ExcelRow row, List<String> keys) {
        for (String key : keys) {
            String val = rowValToString(row, key);
            if (String.isNotBlank(val)) {
                try {
                    return DateTime.valueOf(val);
                } catch (Exception e) {
                    continue;
                }
            }
        }
        return null;
    }

    /**
     * @param row The row to get value from
     * @param key The key of data to import from row
     * @return  `String` The trimmed string value, or null if the value is empty
     */
    private static String rowValToString(ExcelRow row, String key) {
        Object val = row.values.get(key)?.value;
        return val == null ? null : String.valueOf(val).trim();
    }

    private static String rowValToString(ExcelRow row, List<String> keys) {
        for (String key : keys) {
            String val = rowValToString(row, key);
            if (String.isNotBlank(val)) {
                return val;
            }
        }
        return null;
    }

    /**
     * @param row The row to get value from
     * @param key The key of data to import from row
     * @return  `Decimal` The parsed Decimal value scaled to 2 places. Returns a negative value for '출금'. Returns null if blank or parsing fails
     */
    private static Decimal rowValToCurrency(ExcelRow row, String key) {
        String val = rowValToString(row, key);
        if (String.isBlank(val)) {
            return null;
        }

        try {
            String cleanVal = val.replaceAll(',', '').replaceAll('\\.{2,}', '.');
            Decimal num = Decimal.valueOf(cleanVal).setScale(2, RoundingMode.HALF_UP);
            return (key == '출금' || key == 'WithdrawalAmount') ? num * -1 : num;
        } catch (Exception e) {
            return null;
        }
    }

    private static Decimal rowValToCurrency(ExcelRow row, List<String> keys) {
        for (String key : keys) {
            Decimal val = rowValToCurrency(row, key);
            if (val != null) {
                return val;
            }
        }
        return null;
    }

    private static Decimal rowValToDecimal(ExcelRow row, String key) {
        String val = rowValToString(row, key);
        if (String.isBlank(val)) {
            return null;
        }

        try {
            String cleanVal = val.replaceAll(',', '').replaceAll('\\.{2,}', '.');
            return Decimal.valueOf(cleanVal);
        } catch (Exception e) {
            return null;
        }
    }

    private static Decimal rowValToDecimal(ExcelRow row, List<String> keys) {
        for (String key : keys) {
            Decimal val = rowValToDecimal(row, key);
            if (val != null) {
                return val;
            }
        }
        return null;
    }

    private static String getBankTransactionKey(BankTransaction__c bt) {
        return String.join(
            new List<String>{
                String.valueOf(bt.BankAccount__c),
                (bt.Depositor__c == null ? 'null' : bt.Depositor__c),
                String.valueOf(bt.OriginAmount__c),
                (bt.Currency__c == null ? 'null' : bt.Currency__c),
                String.valueOf(bt.TransactionDateTime__c),
                String.valueOf(bt.Balance__c)
            },
            '_'
        );
    }

    public class DuplicateRow {
        @AuraEnabled
        public Integer rowNumber { get; set; }
        @AuraEnabled
        public String currencyCode { get; set; }
        @AuraEnabled
        public Date baseDate { get; set; }
        public DuplicateRow(Integer rowNumber, String currencyCode, Date baseDate) {
            this.rowNumber = rowNumber;
            this.currencyCode = currencyCode;
            this.baseDate = baseDate;
        }
    }

    public class BankDuplicateCheckResult {
        @AuraEnabled
        public List<ExcelRow> duplicateExcelRows { get; set; }
        public BankDuplicateCheckResult(List<ExcelRow> rows) {
            this.duplicateExcelRows = rows;
        }
    }

    public class DuplicateCheckResult {
        @AuraEnabled
        public Integer duplicateCount { get; set; }
        @AuraEnabled
        public List<DuplicateRow> duplicateRows { get; set; }
        public DuplicateCheckResult(List<DuplicateRow> duplicateRows) {
            this.duplicateCount = duplicateRows.size();
            this.duplicateRows = duplicateRows;
        }
    }

    public class ExcelRow {
        @AuraEnabled
        public Integer rowNumber { get; set; }
        @AuraEnabled
        public Map<String, ExcelCell> values { get; set; }
    }

    public class ExcelCell {
        @AuraEnabled
        public Object value { get; set; }
    }

    public class RowError {
        @AuraEnabled
        public Integer rowNumber;
        @AuraEnabled
        public String columnName;
        @AuraEnabled
        public String message;
        public RowError(Integer row, String col, String msg) {
            this.rowNumber = row;
            this.columnName = col;
            this.message = msg;
        }
    }

    public class UploadResult {
        @AuraEnabled
        public List<RowError> errors;
        @AuraEnabled
        public String message { get; set; }
        @AuraEnabled
        public Integer totalCount { get; set; }
        @AuraEnabled
        public Integer createdCount { get; set; }
        @AuraEnabled
        public Integer duplicateCount { get; set; }
        @AuraEnabled
        public Integer errorCount { get; set; }

        public UploadResult(List<RowError> errs) {
            this.errors = errs;
            this.message = '';
            this.totalCount = 0;
            this.createdCount = 0;
            this.duplicateCount = 0;
            this.errorCount = (errs != null) ? errs.size() : 0;
        }
    }

    // **************** Utils
    private static Boolean isZeroOrNull(Decimal val) {
        return val == null || val == 0;
    }
}