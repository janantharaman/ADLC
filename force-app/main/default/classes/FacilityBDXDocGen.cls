/**********************************************************************************
 * @filename       : FacilityBDXDocGen.cls
 * @projectname   : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-24 (화)
 * @group         :
 * @group-content :
 * @description   : Facility BDX 문서 생성을 위한 Remote Action 용 Class
 *                  OmniScript => FacilityBDX_SOA_DocGen / FacilityBDX_DebitNote_DocGen 에서 사용
 * @test-class    : FacilityBDXDocGen_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-24      i2max            Create
**********************************************************************************/

public with sharing class FacilityBDXDocGen implements Callable {

    @TestVisible
    private static List<Map<String, Object>> testRefItems;
    @TestVisible
    private static List<Map<String, Object>> testShareItems;
    @TestVisible
    private static List<Map<String, Object>> testCurrencyItems;
    @TestVisible
    private static List<Map<String, Object>> testLossRows;
    @TestVisible
    private static List<Map<String, Object>> testAllocationAggRows;

    // Type 구분
    /**
     * @description BDX 타입 조회
     * @param recordId COM_FacilityBDX__c Id
     * @return BDXType__c 값 (없으면 빈 문자열)
     */
    @AuraEnabled(Cacheable=true)
    public static String getBDXType(Id recordId) {
        try {
            COM_FacilityBDX__c bdx = [
                    SELECT BDXType__c
                    FROM COM_FacilityBDX__c
                    WHERE Id = :recordId
                    LIMIT 1
            ];

            return (bdx.BDXType__c != null) ? bdx.BDXType__c : '';
        } catch (Exception e) {
            throw new AuraHandledException('BDX 타입을 가져오는 중 오류 발생: ' + e.getMessage());
        }
    }

    /**
     * @description 해당 Facility BDX 에 연결된 Line Item 존재 여부 확인
     * @param recordId COM_FacilityBDX__c Id
     * @return Line Item 이 1건 이상 존재하면 true, 없으면 false
     */
    @AuraEnabled(Cacheable=true)
    public static Boolean checkLineItemsExist(Id recordId) {
        try {
            // 해당 Facility BDX에 연결된 Line Item 있는지 Count
            Integer count = [
                    SELECT COUNT()
                    FROM COM_FacilityBDXLineItem__c
                    WHERE FacilityBDX_md__c = :recordId
                    LIMIT 1
            ];
            return count > 0;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /**
     * @description Callable 인터페이스 구현 메서드.
     *              action = 'getPeriodData' 인 경우 기간 정보, 참조번호, 공유율, Cedant 명,
     *              문서 생성일, Currency 별 테이블 데이터를 output/input 에 세팅한다.
     * @param action 실행할 액션 명 (현재 'getPeriodData' 지원)
     * @param args   input / output / options 맵을 포함하는 인자 맵
     * @return 처리 완료 여부 (true)
     */
    public Object call (String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>)args.get('input');
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        Map<String, Object> options = (Map<String, Object>)args.get('options');

        Id facilityId = (Id) options.get('facilityId');
        if (facilityId == null) {
            facilityId = (Id) input.get('ContextId');
        }

        if (action == 'getPeriodData') {
            if (facilityId != null) {
                // 날짜 데이터 포맷
                Map<String, String> periodData = getPeriodData(facilityId);
                output.putAll(periodData);

                // LK Ref
                String refDisplay = getReferenceDisplay(facilityId);
                output.put('ReferenceDisplay', refDisplay);

                // LK Share
                String shareDisplay = getShareDisplay(facilityId);
                output.put('ShareDisplay', shareDisplay);

                // To Cedant 명
                String cedantName = getCedantName(facilityId);
                output.put('CedantCompanyName', cedantName);

                // 문서 생성일자
                String todayDate = getTodayDate();
                output.put('TodayDate', todayDate);

                // Currency 별 테이블 생성
                List<Map<String, Object>> currencyTables = getCurrencyTableData(facilityId);
                //output.put('CurrencyTables', currencyTables);
                // Outstanding Losses
                List<Map<String, Object>> lossData = getOutstandingLossData(facilityId);
                //output.put('OutstandingLosses', outstandingLosses);

                // Currency + OutstandingLoss
                for (Map<String, Object> tableRow : currencyTables) {
                    String tableCurr = (String)tableRow.get('Currency');
                    tableRow.put('OutstandingLoss', '0'); // 기본값 설정

                    for (Map<String, Object> lossRow : lossData) {
                        // 통화가 일치하면 금액을 꽂아줌
                        if (tableCurr != null && tableCurr.equals(lossRow.get('Currency'))) {
                            tableRow.put('OutstandingLoss', lossRow.get('Amount'));
                            break;
                        }
                    }
                }

                output.put('CurrencyTables', currencyTables);

                if (input != null) {
                    input.putAll(periodData);
                    input.put('ReferenceDisplay', refDisplay);
                    input.put('ShareDisplay', shareDisplay);
                    input.put('CurrencyTables', currencyTables);
                    input.put('CedantCompanyName', cedantName);
                    input.put('TodayDate', todayDate);
                }
            }
        }

        System.debug('### FINAL OUTPUT => ' + JSON.serializePretty(output));
        return true;
    }

    /**
     * @description Facility BDX 에 연결된 Cedant 회사명 조회
     * @param facilityId COM_FacilityBDX__c Id
     * @return Cedant Account 의 CompanyNameEng__c 값 (없으면 빈 문자열)
     */
    private static String getCedantName(Id facilityId) {
        List<COM_FacilityBDX__c> bdxList = [
                SELECT FacilityParticipant_lk__r.CedantAccount_lk__r.CompanyNameEng__c
                FROM COM_FacilityBDX__c
                WHERE Id = :facilityId
                LIMIT 1
        ];

        if (bdxList.isEmpty()) return '';

        String name = bdxList[0].FacilityParticipant_lk__r.CedantAccount_lk__r.CompanyNameEng__c;
        return (name != null) ? name : '';
    }

    /**
     * @description 오늘 날짜를 '1st January 2026' 형식의 영문 날짜 문자열로 반환
     * @return 포맷된 오늘 날짜 문자열
     */
    private static String getTodayDate() {
        Date today = Date.today();
        Integer day = today.day();

        String suffix = getDaySuffix(day);

        // 월/년도 포맷
        String monthYear = Datetime.newInstance(today.year(), today.month(), today.day()).format('MMMM yyyy');
        return String.valueOf(day) + suffix + ' ' + monthYear;
    }

    /**
     * @description 날짜의 일(day) 값에 해당하는 영어 서수 접미사 반환 (st / nd / rd / th)
     * @param day 일(day) 숫자
     * @return 서수 접미사 문자열
     */
    @TestVisible
    private static String getDaySuffix(Integer day) {
        String suffix = 'th';

        if (day < 11 || day > 13) {
            Integer lastDigit = Math.mod(day, 10);
            if (lastDigit == 1) {
                suffix = 'st';
            } else if (lastDigit == 2) {
                suffix = 'nd';
            } else if (lastDigit == 3) {
                suffix = 'rd';
            }
        }

        return suffix;
    }


    /**
     * @description Facility BDX 의 Issue Period 및 연결된 Participant 의 Period From/To 날짜를
     *              영문 포맷으로 변환하여 맵으로 반환
     * @param facilityId COM_FacilityBDX__c Id
     * @return FormattedIssuePeriod / FormattedFromDate / FormattedToDate 키를 포함한 맵
     */
    private static Map<String, String> getPeriodData(Id facilityId) {
        Map<String, String> resultMap = new Map<String, String>();

        List<COM_FacilityBDX__c> bdxList = [
                SELECT FacilityParticipant_lk__c, IssueFrom__c, IssueTo__c
                FROM COM_FacilityBDX__c
                WHERE Id = :facilityId
                LIMIT 1
        ];

        if (bdxList.isEmpty()) {
            return resultMap;
        }

        COM_FacilityBDX__c bdx = bdxList[0];

        // Issue Period 포맷
        if (bdx.IssueFrom__c != null && bdx.IssueTo__c != null) {
            String issueFromStr = Datetime.newInstance(bdx.IssueFrom__c, Time.newInstance(0,0,0,0)).format('dd MMMM yyyy');
            String issueToStr = Datetime.newInstance(bdx.IssueTo__c, Time.newInstance(0,0,0,0)).format('dd MMMM yyyy');

            String combinedIssuePeriod = '(' + issueFromStr + ' - ' + issueToStr + ')';
            resultMap.put('FormattedIssuePeriod', combinedIssuePeriod);
        }

        if (bdx.FacilityParticipant_lk__c != null) {
            List<COM_FacilityParticipant__c> pList = [
                    SELECT PeriodFrom__c, PeriodTo__c
                    FROM COM_FacilityParticipant__c
                    WHERE Id = :bdx.FacilityParticipant_lk__c
                    LIMIT 1
            ];

            if (!pList.isEmpty()) {
                COM_FacilityParticipant__c p = pList[0];

                String formattedFrom = (p.PeriodFrom__c != null) ?
                        Datetime.newInstance(p.PeriodFrom__c, Time.newInstance(0,0,0,0)).format('dd MMMM yyyy') : '';

                String formattedTo = (p.PeriodTo__c != null) ?
                        Datetime.newInstance(p.PeriodTo__c, Time.newInstance(0,0,0,0)).format('dd MMMM yyyy') : '';

                resultMap.put('FormattedFromDate', formattedFrom);
                resultMap.put('FormattedToDate', formattedTo);
            }
        }

        return resultMap;
    }

    /**
     * @description LK Ref No. 표시 문자열 조회.
     *              단일 값이면 그대로, 복수 값이면 '{값} and others' 형식으로 반환
     * @param facilityId COM_FacilityBDX__c Id
     * @return LK Ref No. 표시 문자열
     */
    private static String getReferenceDisplay(Id facilityId) {
        if (Test.isRunningTest() && testRefItems != null) {
            return buildReferenceDisplay(testRefItems);
        }

        List<COM_FacilityBDXLineItem__c> items = [
                SELECT LKRefNo_fm__c
                FROM COM_FacilityBDXLineItem__c
                WHERE FacilityBDX_md__c = :facilityId
                ORDER BY NetShare_fm__c DESC, CreatedDate ASC
        ];

        List<Map<String, Object>> mapItems = new List<Map<String, Object>>();
        for (COM_FacilityBDXLineItem__c item : items) {
            mapItems.add(new Map<String, Object>{ 'LKRefNo_fm__c' => item.LKRefNo_fm__c });
        }
        return buildReferenceDisplay(mapItems);
    }

    /**
     * @description Line Item 목록으로 LK Ref No. 표시 문자열 생성
     * @param items LKRefNo_fm__c 키를 포함한 맵 리스트
     * @return LK Ref No. 표시 문자열
     */
    private static String buildReferenceDisplay(List<Map<String, Object>> items) {
        if (items == null || items.isEmpty()) return '';

        Set<String> uniqueRefs = new Set<String>();
        for (Map<String, Object> item : items) {
            String ref = (String) item.get('LKRefNo_fm__c');
            if (ref != null) uniqueRefs.add(ref);
        }

        String topValue = (String) items[0].get('LKRefNo_fm__c');
        return uniqueRefs.size() <= 1 ? topValue : topValue + ' and others';
    }

    /**
     * @description LK Share(%) 표시 문자열 조회.
     *              단일 값이면 '{값}%', 복수 값이면 '{값}% and others' 형식으로 반환
     * @param facilityId COM_FacilityBDX__c Id
     * @return Share 표시 문자열
     */
    private static String getShareDisplay(Id facilityId) {
        if (Test.isRunningTest() && testShareItems != null) {
            return buildShareDisplay(testShareItems);
        }

        List<COM_FacilityBDXLineItem__c> items = [
                SELECT TotalOrderPct_fm__c
                FROM COM_FacilityBDXLineItem__c
                WHERE FacilityBDX_md__c = :facilityId
                ORDER BY TotalOrderPct_fm__c DESC, CreatedDate ASC
        ];

        List<Map<String, Object>> mapItems = new List<Map<String, Object>>();
        for (COM_FacilityBDXLineItem__c item : items) {
            mapItems.add(new Map<String, Object>{ 'TotalOrderPct_fm__c' => item.TotalOrderPct_fm__c });
        }
        return buildShareDisplay(mapItems);
    }

    /**
     * @description Line Item 목록으로 Share 표시 문자열 생성
     * @param items TotalOrderPct_fm__c 키를 포함한 맵 리스트
     * @return Share 표시 문자열
     */
    private static String buildShareDisplay(List<Map<String, Object>> items) {
        if (items == null || items.isEmpty()) return '';

        Set<Decimal> uniqueShares = new Set<Decimal>();
        for (Map<String, Object> item : items) {
            Decimal share = toDecimal(item.get('TotalOrderPct_fm__c'));
            if (share != null) uniqueShares.add(share);
        }

        String topValue = String.valueOf(toDecimal(items[0].get('TotalOrderPct_fm__c')));
        return uniqueShares.size() <= 1 ? topValue + '%' : topValue + '% and others';
    }

    /**
     * @description Currency 별 Premium/Claim 집계 테이블 데이터 생성.
     *              A(PremOnLKShare), B(TotalDeduction), C(A-B), D(OriginAmount of Claim), E(C-D) 컬럼을 포함한다.
     * @param facilityId COM_FacilityBDX__c Id
     * @return Currency 별 집계 맵 리스트 (Currency / SumA~SumE / OutstandingLoss 키 포함)
     */
    private static List<Map<String, Object>> getCurrencyTableData(Id facilityId) {
        List<Map<String, Object>> tableList = new List<Map<String, Object>>();

        Map<String, Map<String, Decimal>> currencyMap = new Map<String, Map<String, Decimal>>();
        Set<String> premiumCurrencies = new Set<String>();

        List<Map<String, Object>> sourceItems = new List<Map<String, Object>>();
        if (Test.isRunningTest() && testCurrencyItems != null) {
            sourceItems = testCurrencyItems;
        } else {
            List<COM_FacilityBDXLineItem__c> items = [
                    SELECT OriginCurrency_fm__c, PremOnLKShare_fm__c, TotalDeduction_fm__c, OriginAmount_fm__c, Claim_lk__c
                    FROM COM_FacilityBDXLineItem__c
                    WHERE FacilityBDX_md__c = :facilityId
            ];
            for (COM_FacilityBDXLineItem__c item : items) {
                sourceItems.add(new Map<String, Object>{
                        'OriginCurrency_fm__c' => item.OriginCurrency_fm__c,
                        'PremOnLKShare_fm__c' => item.PremOnLKShare_fm__c,
                        'TotalDeduction_fm__c' => item.TotalDeduction_fm__c,
                        'OriginAmount_fm__c' => item.OriginAmount_fm__c,
                        'Claim_lk__c' => item.Claim_lk__c
                });
            }
        }

        for (Map<String, Object> item : sourceItems) {
            String curr = (String) item.get('OriginCurrency_fm__c');
            if (String.isBlank(curr)) curr = 'N/A';

            if (!currencyMap.containsKey(curr)) {
                currencyMap.put(curr, new Map<String, Decimal>{ 'A' => 0, 'B' => 0, 'D' => 0, 'OL' => 0 });
            }

            Map<String, Decimal> sums = currencyMap.get(curr);
            Id claimId = (Id) item.get('Claim_lk__c');

            if (claimId == null) {
                premiumCurrencies.add(curr);
                Decimal a = toDecimal(item.get('PremOnLKShare_fm__c'));
                Decimal b = toDecimal(item.get('TotalDeduction_fm__c'));
                sums.put('A', sums.get('A') + (a != null ? a : 0));
                sums.put('B', sums.get('B') + (b != null ? b : 0));
            } else {
                Decimal d = toDecimal(item.get('OriginAmount_fm__c'));
                sums.put('D', sums.get('D') + (d != null ? d : 0));
            }
        }

        // premiumCurrencies 기준으로 테이블 Row
        for (String curr : premiumCurrencies) {
            Map<String, Decimal> v = currencyMap.get(curr);

            Decimal aVal = v.get('A');
            Decimal bVal = v.get('B');
            Decimal cVal = aVal - bVal;         // C = A - B
            Decimal dVal = v.get('D');          // D = Claim != null 레코드의 OriginAmount_fm__c 합계
            Decimal eVal = cVal - dVal;         // E = C - D

            Map<String, Object> row = new Map<String, Object>();
            row.put('Currency', curr);
            row.put('SumA', formatNumber(aVal));
            row.put('SumB', formatNumber(bVal));
            row.put('SumC', formatNumber(cVal));
            row.put('SumD', formatNumber(dVal));
            row.put('SumE', formatNumber(eVal));

            tableList.add(row);
        }

        return tableList;
    }

    /**
     * @description Decimal 값을 천 단위 구분 기호가 포함된 정수 문자열로 포맷
     * @param d 포맷할 Decimal 값
     * @return 포맷된 숫자 문자열
     */
    private static String formatNumber(Decimal d) {
        return d.setScale(0).format();
    }

    /**
     * @description Outstanding Loss 데이터 조회.
     *              BDX Line Item 에 연결된 Claim 의 Parent Claim 을 기준으로
     *              CLM_Allocation__c 의 TotalAmtForRISettled__c 를 Currency 별로 집계하여 반환
     * @param facilityId COM_FacilityBDX__c Id
     * @return Currency / Amount 키를 포함한 집계 맵 리스트
     */
    private static List<Map<String, Object>> getOutstandingLossData(Id facilityId) {

        if (Test.isRunningTest() && testLossRows != null) {
            return testLossRows;
        }

        if (Test.isRunningTest() && testAllocationAggRows != null) {
            List<Map<String, Object>> mockedResult = new List<Map<String, Object>>();
            for (Map<String, Object> ar : testAllocationAggRows) {
                Map<String, Object> row = new Map<String, Object>();
                row.put('Currency', ar.get('curr') != null ? (String) ar.get('curr') : 'N/A');
                row.put('Amount', formatNumber(toDecimal(ar.get('total'))));
                mockedResult.add(row);
            }
            return mockedResult;
        }

        List<Map<String, Object>> resultList = new List<Map<String, Object>>();
        Set<Id> parentClaimIds = new Set<Id>();

        // BDX에 연결된 Line Item들의 Parent Claim ID
        for (COM_FacilityBDXLineItem__c item : [
                SELECT Claim_lk__r.ParentClaim_lk__c
                FROM COM_FacilityBDXLineItem__c
                WHERE FacilityBDX_md__c = :facilityId
                AND Claim_lk__c != NULL
        ]) {
            parentClaimIds.add(item.Claim_lk__r.ParentClaim_lk__c);
        }

        if (parentClaimIds.isEmpty()) return resultList;

        // Parent를 공유하는 자식들의 Allocation 합산
        for (AggregateResult ar : [
                SELECT SettlementCurrency__c curr, SUM(TotalAmtForRISettled__c) total
                FROM CLM_Allocation__c
                WHERE Claim_md__c IN (
                        SELECT Id FROM Claim
                        WHERE ParentClaim_lk__c IN :parentClaimIds
                        AND LastPLA_is__c = TRUE
                )
                GROUP BY SettlementCurrency__c
        ]) {
            Map<String, Object> row = new Map<String, Object>();
            row.put('Currency', ar.get('curr') != null ? (String)ar.get('curr') : 'N/A');
            row.put('Amount', formatNumber((Decimal)ar.get('total')));
            resultList.add(row);
        }

        return resultList;
    }

    /**
     * @description Object 타입 값을 Decimal 로 변환 (null 이면 null 반환)
     * @param raw 변환할 Object 값 (Decimal / Integer / Long / Double / String 지원)
     * @return 변환된 Decimal 값
     */
    private static Decimal toDecimal(Object raw) {
        if (raw == null) return null;
        if (raw instanceof Decimal) return (Decimal) raw;
        if (raw instanceof Integer) return Decimal.valueOf((Integer) raw);
        if (raw instanceof Long) return Decimal.valueOf((Long) raw);
        if (raw instanceof Double) return Decimal.valueOf((Double) raw);
        return Decimal.valueOf(String.valueOf(raw));
    }

}