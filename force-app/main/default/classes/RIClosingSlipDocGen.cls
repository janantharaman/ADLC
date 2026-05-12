/**********************************************************************************
 * @filename       : RIClosingSlipDocGen.cls
 * @projectname   : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-15 (일)
 * @group         :
 * @group-content :
 * @description   : RI Closing Slip / RI Offer Slip 문서 생성을 위한 Remote Action 용 Controller
 *                  OmniScript => RIOffer_DocGen, RISlipEND_DocGen, RIClosing_DocGen 에서 사용
 * @test-class    : RIClosingSlipDocGen_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-15      i2max            Create
 **********************************************************************************/

public with sharing class RIClosingSlipDocGen implements Callable {
    
    /**
     * @description Subjectivity 데이터를 Addition / Amendment / Cancellation 유형별로 분류하는 Response Wrapper
     */
    public class ResponseWrapper {
        public List<Object> Addition = new List<Object>();
        public List<Object> Amendment = new List<Object>();
        public List<Object> Cancellation = new List<Object>();
    }
    
    /**
     * @description Callable 인터페이스 구현 메서드 - action 값에 따라 각 데이터 빌드 로직을 분기하여 output/input 맵에 결과를 적재한다.
     * @param action 실행할 액션 명칭 (예: getSubjectivities, buildLayerData 등)
     * @param args output, input, options 키를 포함하는 인자 맵
     * @return 처리 성공 여부를 나타내는 Boolean (항상 true)
     */
    public Object call(String action, Map<String, Object> args) {
        
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        
        if (action == 'getSubjectivities') {
            // Slip에 연결된 Subjectivity 레코드를 유형별로 분류하여 output에 적재
            Id slipId = (Id) options.get('slipId');
            
            System.debug('Slip Id ==> ' + slipId);
            
            if (slipId != null) {
                
                ResponseWrapper res = getSubjectivities(slipId);
                
                Map<String, Object> subjectMap = new Map<String, Object>();
                subjectMap.put('Addition', res.Addition);
                subjectMap.put('Amendment', res.Amendment);
                subjectMap.put('Cancellation', res.Cancellation);
                
                output.put('Subjectivities', subjectMap);
                
                if (input != null) {
                    input.put('Subjectivities', subjectMap);
                }
            }
            
        }  else if (action == 'buildLayerData') {
            // Layer별 Panel 데이터를 Header + Panels 구조로 빌드하여 output에 적재
            Id slipId = (Id) options.get('slipId');
            
            System.debug('Layer Action !!');
            List<Object> layers = buildLayerData(slipId);
            output.put('Layers', layers);
            if (input != null) input.put('Layers', layers);
            
        } else if (action == 'getDeductionData') {
            // Panel의 공제율(Brokerage, RI Comm, Other) 합산 데이터를 Layer별로 빌드
            Id slipId = (Id) options.get('slipId');
            
            List<Object> result = getDeductionData(slipId);
            
            output.put('Deductions', result);
            if (input != null) input.put('Deductions', result);
            
        } else if (action == 'getOrderHereonData') {
            // Currency 개수에 따라 Order Hereon 표기 방식을 결정하여 Layer별로 빌드
            Id slipId = (Id) options.get('slipId');
            
            List<Object> result = getOrderHereonData(slipId);
            
            output.put('OrderHereon', result);
            if (input != null) input.put('OrderHereon', result);
            
        } else if (action == 'getDepositPremiumData') {
            // Deposit Premium 데이터를 Currency 단일/복수 여부에 따라 구조화하여 빌드
            Id slipId = (Id) options.get('slipId');
            
            List<Object> result = getDepositPremiumData(slipId);
            
            output.put('DepositPremiums', result);
            if (input != null) input.put('DepositPremiums', result);
            
        } else if (action == 'cleanPremPaymentClause') {
            // PremPaymentClause 필드의 <br> 태그를 제거하여 DMTResult에 저장
            System.debug('### ENTER cleanPremPaymentClause');
            
            Id slipId = (Id) options.get('slipId');
            System.debug('### slipId => ' + slipId);
            
            if (slipId == null) return true;
            
            OPP_SlipInfo__c slip = [
                    SELECT PremPaymentClause_fm__c
                    FROM OPP_SlipInfo__c
                    WHERE Id = :slipId
                    LIMIT 1
            ];
            
            //RTB로 옮겨야할듯
            String cleanValue = removeBrTag(slip.PremPaymentClause_fm__c);
            Map<String, Object> dmt = (Map<String, Object>) input.get('DMTResult');
            
            if (dmt == null) {
                dmt = new Map<String, Object>();
                input.put('DMTResult', dmt);
            }
            
            dmt.put('PremPaymentClause', cleanValue);
            // 디버깅용
            output.put('PremPaymentClause', cleanValue);
        } else if (action == 'getCountryLabelData') {
            // TerritoryScope, GoverningLaw, CountryOrigin 코드 값을 레이블로 변환하여 output에 적재
            Id slipId = (Id) options.get('slipId');
            
            Map<String, Object> countryData = getCountryLabelData(slipId);
            
            output.putAll(countryData);
            if (input != null) input.putAll(countryData);
            
            if (output.containsKey('DMTResult')) {
                Map<String, Object> dmt = (Map<String, Object>) output.get('DMTResult');
                dmt.putAll(countryData);
            }
            
        } else if (action == 'getTodayDate') {
            // 오늘 날짜를 영문 형식(예: 17th April 2026)으로 변환하여 output에 적재
            String todayDate = getTodayDate();
            
            output.put('TodayDate', todayDate);
            if (input != null) input.put('TodayDate', todayDate);
            
            if (output.containsKey('OPP_SlipInfo')) {
                Map<String, Object> slipInfo = (Map<String, Object>) output.get('OPP_SlipInfo');
                slipInfo.put('TodayDate', todayDate);
            }
            
            if (output.containsKey('DMTResult')) {
                Map<String, Object> dmt = (Map<String, Object>) output.get('DMTResult');
                dmt.put('TodayDate', todayDate);
            }
        } else if (action == 'applyNewLines') {
            // SlipInfo의 텍스트 필드(Insured, TermsConds 등)를 줄 단위 List로 변환하여 DMTResult에 적재
            if (output != null) {
                output.remove('InsuredLines');
                output.remove('TermsCondsLines');
                output.remove('DeductibleLines');
                output.remove('LOL_Lines');
                output.remove('CoveredLines');
            }
            
            Id slipId = (Id) options.get('slipId');
            if (slipId == null) return true;
            
            OPP_SlipInfo__c slip = [
                    SELECT Insured__c, LimitofLiability__c, Deductible__c, TermsConds__c, CoveredRisk__c
                    FROM OPP_SlipInfo__c
                    WHERE Id = :slipId
                    LIMIT 1
            ];
            
            //이거 다 RTB로 옮겨야할듯
            Map<String, Object> slipData = new Map<String, Object>();
            slipData.put('TermsCondsLines', toLineList(slip.TermsConds__c));
            slipData.put('InsuredLines',    toLineList(slip.Insured__c));
            slipData.put('DeductibleLines', toLineList(slip.Deductible__c));
            slipData.put('LOL_Lines',       toLineList(slip.LimitofLiability__c));
            slipData.put('CoveredLines',    toLineList(slip.CoveredRisk__c));
            
            if (output != null) {
                output.putAll(slipData);
            }
            
            if (input != null) {
                Map<String, Object> dmt;
                if (input.get('DMTResult') instanceof Map<String, Object>) {
                    dmt = (Map<String, Object>) input.get('DMTResult');
                } else {
                    dmt = new Map<String, Object>();
                }
                
                dmt.remove('InsuredLines');
                dmt.remove('TermsCondsLines');
                dmt.remove('DeductibleLines');
                dmt.remove('LOL_Lines');
                dmt.remove('CoveredLines');
                
                dmt.putAll(slipData);
                input.put('DMTResult', dmt);
            }
        } else if (action == 'getSlipInfo') {
            // SlipInfo 기본 정보(ENDNo, LKRefNo, Amendments, ENDEffectivedDate)를 output에 적재
            Id slipId = (Id) options.get('slipId');
            System.debug('Get Slip Info Id ==> ' + slipId);
            if (slipId != null) {
                Map<String, Object> slipData = getSlipInfoData(slipId);
                output.putAll(slipData);
            }
        } else if (action == 'getCustomLabels') {
            
            Map<String, Object> dmt;
            if (output.get('DMTResult') instanceof Map<String, Object>) {
                dmt = (Map<String, Object>) output.get('DMTResult');
            } else {
                dmt = new Map<String, Object>();
            }
            dmt.putAll(getCustomLabelData());
            output.put('DMTResult', dmt);
            
        }
        
        System.debug('### FINAL OUTPUT JSON => ' + JSON.serializePretty(output));
        
        // OPP_SlipInfo 노드가 있으면 공통 데이터 복사
        if (output.containsKey('OPP_SlipInfo')) {
            Map<String, Object> slipInfo = (Map<String, Object>) output.get('OPP_SlipInfo');
            
            if (output.containsKey('TodayDate')) slipInfo.put('TodayDate', output.get('TodayDate'));
            if (output.containsKey('CountryOrigin')) slipInfo.put('CountryOrigin', output.get('CountryOrigin'));
            if (output.containsKey('TerritoryScope')) slipInfo.put('TerritoryScope', output.get('TerritoryScope'));
            if (output.containsKey('GoverningLaw')) slipInfo.put('GoverningLaw', output.get('GoverningLaw'));
        }
        
        // 만약 DMTResult 노드도 사용 중이라면 거기에도 복사
        if (output.containsKey('DMTResult')) {
            Map<String, Object> dmt = (Map<String, Object>) output.get('DMTResult');
            if (output.containsKey('TodayDate')) dmt.put('TodayDate', output.get('TodayDate'));
            if (output.containsKey('CountryOrigin')) dmt.put('CountryOrigin', output.get('CountryOrigin'));
        }
        
        return true;
    }
    
    /**
     * @description 지정된 Slip에 연결된 Subjectivity 레코드를 유형(Addition/Amendment/Cancellation)별로 분류하여 반환한다.
     * @param slipId 대상 OPP_SlipInfo__c 레코드 Id
     * @return 유형별로 분류된 Subjectivity 데이터가 담긴 ResponseWrapper
     */
    private static ResponseWrapper getSubjectivities(Id slipId) {
        ResponseWrapper res = new ResponseWrapper();
        
        List<OPP_SlipInfo__c> slipList = [SELECT Reinsurer_lk__c FROM OPP_SlipInfo__c WHERE Id = :slipId LIMIT 1];
        if (slipList.isEmpty()) return res;
        OPP_SlipInfo__c slip = slipList[0];
        
        List<OPP_Subjectivity__c> subs = [
                SELECT Detail__c, Type__c
                FROM OPP_Subjectivity__c
                WHERE Clear_is__c = FALSE
                AND Panel_lk__r.Reinsurer_lk__c = :slip.Reinsurer_lk__c
                AND Panel_lk__c IN (SELECT Panel_lk__c FROM SLP_PanelJunction__c WHERE Slip_lk__c = :slipId)
        ];
        
        for (OPP_Subjectivity__c s : subs) {
            if (String.isBlank(s.Detail__c) || s.Type__c == null) continue;
            
            Map<String, String> item = new Map<String, String>();
            item.put('Detail', s.Detail__c);
            
            if (s.Type__c.contains('Addition')) {
                res.Addition.add(item);
            }
            else if (s.Type__c.contains('Amendment')) {
                res.Amendment.add(item);
            }
            else if (s.Type__c.contains('Cancellation')) {
                res.Cancellation.add(item);
            }
        }
        return res;
    }
    
    /**
     * @description Slip에 연결된 Panel 목록을 Layer Header 기준으로 그룹화하여 Layer + Panel 데이터 구조를 반환한다.
     * @param slipId 대상 OPP_SlipInfo__c 레코드 Id
     * @return Header와 Panels 키를 가진 Map의 List
     */
    public static List<Object> buildLayerData(Id slipId) {
        
        List<OPP_Panel__c> panels = [
                SELECT Id,
                        Currency__c,
                        GrossPremDP__c,
                        ActualAdjRatePct__c,
                        Layer_md__r.Type__c,
                        Layer_md__r.LOL__c,
                        Layer_md__r.Excess__c,
                        Layer_md__r.LayerCurrency__c
                FROM OPP_Panel__c
                WHERE Id IN (
                        SELECT Panel_lk__c
                        FROM SLP_PanelJunction__c
                        WHERE Slip_lk__c = :slipId
                )
        ];
        
        Map<String, Map<String, Object>> layerMap = new Map<String, Map<String, Object>>();
        
        for (OPP_Panel__c p : panels) {
            
            String header = buildHeader(p);
            
            if (p.Layer_md__r == null) continue;
            
            if (header == null) continue;
            
            if (!layerMap.containsKey(header)) {
                
                layerMap.put(header, new Map<String, Object>{
                    'Header' => header,
                    'Panels' => new List<Object>()
                });
            }
            
            List<Object> panelList = (List<Object>) layerMap.get(header).get('Panels');
            
            panelList.add(new Map<String, Object>{
                'Currency' => p.Currency__c,
                'GrossPremDP' => fmtAmt(p.GrossPremDP__c),
                'Rate' => p.ActualAdjRatePct__c
            });
        }
        
        List<Object> result = new List<Object>();
        
        for (Map<String, Object> val : layerMap.values()) {
            result.add(val);
        }
        
        return result;
    }
    
    /**
     * @description Decimal 값을 소수점 2자리 문자열로 변환한다. null이면 빈 문자열을 반환한다.
     * @param val 변환할 Decimal 값
     * @return 소수점 2자리로 포맷된 문자열 또는 빈 문자열
     */
    public static String format(Decimal val) {
        if (val == null) return '';
        return String.valueOf(val.setScale(2));
    }
    
    /**
     * @description Decimal 값을 천단위 쉼표 포맷 문자열로 반환한다. null이면 빈 문자열을 반환한다.
     * @param  val  포맷할 Decimal 값
     * @return      천단위 쉼표가 포함된 문자열
     */
    private static String fmtAmt(Decimal val) {
        if (val == null) {
            return '';
        }
        return val.setScale(2).format();
    }
    
    /**
     * @description Slip에 연결된 Panel의 데이터를 Layer Header 기준으로 그룹화하여 반환한다.
     * @param slipId 대상 OPP_SlipInfo__c 레코드 Id
     * @return Header와 Deductions 키를 가진 Map의 List
     */
    public static List<Object> getDeductionData(Id slipId) {
        
        List<OPP_Panel__c> panels = [
                SELECT Id,
                        Currency__c,
                        BrkgBase__c,
                        RICommPct__c,
                        OtherDeductionPct__c,
                        TotalBrkgPct__c,
                        Layer_md__r.Type__c,
                        Layer_md__r.LOL__c,
                        Layer_md__r.Excess__c,
                        Layer_md__r.LayerCurrency__c
                FROM OPP_Panel__c
                WHERE Id IN (
                        SELECT Panel_lk__c
                        FROM SLP_PanelJunction__c
                        WHERE Slip_lk__c = :slipId
                )
        ];
        
        Map<String, Map<String, Object>> layerMap = new Map<String, Map<String, Object>>();
        
        for (OPP_Panel__c p : panels) {
            String header = buildHeader(p);
            if (header == null) continue;
            
            if (!layerMap.containsKey(header)) {
                layerMap.put(header, new Map<String, Object>{
                    'Header' => header,
                    'Items' => new List<Object>()
                });
            }
            
            List<Object> dedList = (List<Object>) layerMap.get(header).get('Items');
            dedList.add(new Map<String, Object>{
                'Currency' => p.Currency__c,
                'Value' => calculateDeduction(p)
            });
        }
        
        List<Object> result = new List<Object>();
        for (Map<String, Object> val : layerMap.values()) {
            result.add(val);
        }
        
        // Layer가 1건이면 Header를 null로 처리(문서 템플릿에서 헤더 미출력)
        if (result.size() == 1) {
            Map<String, Object> firstRow = (Map<String, Object>)result[0];
            firstRow.put('Header', null);
        }
        
        return result;
    }
    
    /**
     * @description Panel과 연결된 Layer 정보를 기반으로 문서 출력용 Layer 헤더 문자열을 생성한다.
     * @param p 헤더를 생성할 OPP_Panel__c 레코드
     * @return 'Currency LOL - per any one occurance Excess of Excess' 형식의 헤더 문자열, 해당 없으면 null
     */
    public static String buildHeader(OPP_Panel__c p) {
        
        if (p.Layer_md__r == null) return null;
        
        String type = p.Layer_md__r.Type__c;
        // Brkg Adj 타입은 헤더 생성 대상 제외
        if (type == 'Brkg Adj') return null;
        
        String currencyStr = String.valueOf(p.Layer_md__r.LayerCurrency__c);
        String lol = fmtAmt(p.Layer_md__r.LOL__c);
        String excess = fmtAmt(p.Layer_md__r.Excess__c);
        
        if (type == 'QS' || type == 'Primary') {
            return currencyStr + ' ' + lol +  ' - per any one occurance Excess of Original Policy Deductible';
        }
        else if (type == 'Excess') {
            return  currencyStr + ' ' + lol + ' - per any one occurance Excess of ' + excess;
        }
        
        return null;
    }
    
    /**
     * @description BrkgBase 값에 따라 Panel의 공제율 합계를 계산하여 포맷된 문자열로 반환한다.
     * @param p 공제율을 계산할 OPP_Panel__c 레코드
     * @return 소수점 2자리로 포맷된 공제율 합계 문자열
     */
    public static String calculateDeduction(OPP_Panel__c p) {
        
        Decimal total;
        
        if (p.BrkgBase__c == 'Gross') {
            // Gross 기준: RI Comm + Other Deduction + Total Brokerage 합산
            total =  (p.RICommPct__c == null ? 0 : p.RICommPct__c) +
                (p.OtherDeductionPct__c == null ? 0 : p.OtherDeductionPct__c) +
                (p.TotalBrkgPct__c == null ? 0 : p.TotalBrkgPct__c);
        } else {
            // Net 기준: Total Brokerage만 적용
            total = (p.TotalBrkgPct__c == null ? 0 : p.TotalBrkgPct__c);
        }
        
        return format(total);
    }
    
    /**
     * @description Slip에 연결된 Panel의 Order Hereon 데이터를 Currency 수에 따라 다르게 포맷하여 Layer별로 반환한다.
     * @param slipId 대상 OPP_SlipInfo__c 레코드 Id
     * @return Header와 Items 키를 가진 Map의 List
     */
    public static List<Object> getOrderHereonData(Id slipId) {
        
        List<OPP_Panel__c> panels = [
                SELECT Id,
                        Currency__c,
                        LOL__c,
                        Signed__c,
                        Layer_md__r.Type__c,
                        Layer_md__r.LOL__c,
                        Layer_md__r.Excess__c,
                        Layer_md__r.LayerCurrency__c
                FROM OPP_Panel__c
                WHERE Id IN (
                        SELECT Panel_lk__c
                        FROM SLP_PanelJunction__c
                        WHERE Slip_lk__c = :slipId
                )
        ];
        
        // Currency별 Panel 건수 집계 (단일 Currency 여부 판단용)
        Map<String, Integer> currencyCountMap = new Map<String, Integer>();
        
        for (OPP_Panel__c p : panels) {
            if (!currencyCountMap.containsKey(p.Currency__c)) {
                currencyCountMap.put(p.Currency__c, 0);
            }
            currencyCountMap.put(p.Currency__c, currencyCountMap.get(p.Currency__c) + 1);
        }
        
        Map<String, Map<String, Object>> layerMap = new Map<String, Map<String, Object>>();
        
        for (OPP_Panel__c p : panels) {
            
            String header = buildHeader(p);
            if (header == null) continue;
            
            if (!layerMap.containsKey(header)) {
                layerMap.put(header, new Map<String, Object>{
                    'Header' => header,
                    'Items' => new List<Object>()
                });
            }
            
            List<Object> itemList = (List<Object>) layerMap.get(header).get('Items');
            
            // Currency 별 개수 체크
            Integer count = currencyCountMap.get(p.Currency__c);
            
            String orderValue;
            
            if (count == 1) {
                // Currency 단일: Signed% of 100% 형식
                orderValue =  format(p.Signed__c);
            } else {
                // Currency 복수: LOL 금액 형식
                orderValue = format(p.LOL__c);
            }
            
            itemList.add(new Map<String, Object>{
                'Currency' => p.Currency__c,
                'OrderValue' => orderValue
            });
        }
        
        List<Object> result = new List<Object>();
        for (Map<String, Object> val : layerMap.values()) {
            result.add(val);
        }
        
        // Layer가 1건이면 Header 미출력
        if (result.size() == 1) {
            Map<String, Object> firstRow = (Map<String, Object>)result[0];
            firstRow.put('Header', null);
        }
        
        return result;
    }
    
    /**
     * @description Slip에 연결된 Panel의 Deposit Premium 데이터를 Currency 단일/복수 여부에 따라 구조화하여 반환한다.
     * @param slipId 대상 OPP_SlipInfo__c 레코드 Id
     * @return IsSingle, Header, Items 키를 가진 Map의 List
     */
    public static List<Object> getDepositPremiumData(Id slipId) {
        
        List<OPP_Panel__c> panels = [
                SELECT Id,
                        Currency__c,
                        GrossPrem__c,
                        DPPct__c,
                        Layer_md__r.Type__c,
                        Layer_md__r.LOL__c,
                        Layer_md__r.Excess__c,
                        Layer_md__r.LayerCurrency__c
                FROM OPP_Panel__c
                WHERE Id IN (
                        SELECT Panel_lk__c
                        FROM SLP_PanelJunction__c
                        WHERE Slip_lk__c = :slipId
                )
        ];
        
        // DPPct가 100이 아닌 TSI 레코드에서 Asset 목록 수집
        List<OPP_TSIByLocation__c> tsiList = [
                SELECT Asset__c, DPPct__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipId
                AND DPPct__c != 100
        ];
        
        String assetStr = '';
        for (OPP_TSIByLocation__c tsi : tsiList) {
            if (tsi.Asset__c != null) {
                assetStr += tsi.Asset__c + ', ';
            }
        }
        if (assetStr.endsWith(', ')) {
            assetStr = assetStr.substring(0, assetStr.length() - 2);
        }
        
        // Currency 기준 단일/다중 판단
        Set<String> currencySet = new Set<String>();
        for (OPP_Panel__c p : panels) {
            if (p.Currency__c != null) {
                currencySet.add(p.Currency__c);
            }
        }
        
        List<Object> result = new List<Object>();
        
        // Currency가 1종류인 경우: 단일 구조로 반환
        if (currencySet.size() == 1 && !panels.isEmpty()) {
            OPP_Panel__c p = panels[0];
            
            Map<String, Object> singleData = new Map<String, Object>();
            singleData.put('IsSingle', true);
            singleData.put('Header', '');
            
            List<Object> items = new List<Object>();
            items.add(new Map<String, Object>{
                'Currency' => p.Currency__c,
                'GrossPrem' => fmtAmt(p.GrossPrem__c),
                'DPPct' => format(p.DPPct__c),
                'Asset' => assetStr
            });
            singleData.put('Items', items);
            
            result.add(singleData);
            return result;
        }
        
        // Currency가 2종류 이상인 경우: Layer별 구조로 반환
        Map<String, Map<String, Object>> layerMap = new Map<String, Map<String, Object>>();
        
        for (OPP_Panel__c p : panels) {
            
            String header = buildHeader(p);
            if (header == null) continue;
            
            if (!layerMap.containsKey(header)) {
                layerMap.put(header, new Map<String, Object>{
                    'Header' => header,
                    'Items' => new List<Object>()
                });
            }
            
            List<Object> itemList = (List<Object>) layerMap.get(header).get('Items');
            
            itemList.add(new Map<String, Object>{
                'Currency' => p.Currency__c,
                'GrossPrem' => fmtAmt(p.GrossPrem__c),
                'DPPct' => format(p.DPPct__c),
                'Asset' => assetStr
            });
        }
        
        for (Map<String, Object> val : layerMap.values()) {
            result.add(val);
        }
        
        return result;
    }
    
    /**
     * @description HTML <br> 태그(및 변형)를 공백으로 치환하여 순수 텍스트로 반환한다.
     * @param input 원본 HTML 문자열
     * @return <br> 태그가 제거된 텍스트 문자열
     */
    private static String removeBrTag(String input) {
        if (String.isBlank(input)) return '';
        
        String output = input;
        
        // <br> 케이스들 제거
        output = output.replace('<br><br>', ' ');
        output = output.replace('<br/>', ' ');
        output = output.replace('<br>', ' ');
        
        return output;
    }
    
    /**
     * @description SlipInfo의 TerritoryScope, GoverningLaw, CountryOrigin 필드 코드 값을 CountryMapping 메타데이터 레이블로 변환하여 반환한다.
     * @param slipId 대상 OPP_SlipInfo__c 레코드 Id
     * @return TerritoryScope, GoverningLaw, CountryOrigin 키와 레이블 값으로 구성된 Map
     */
    public static Map<String, Object> getCountryLabelData(Id slipId) {
        Map<String, Object> result = new Map<String, Object>();
        
        // 대상 레코드 쿼리
        List<OPP_SlipInfo__c> slips = [
                SELECT TerritoryScope__c, GoverningLaw__c, CountryOrigin_fm__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipId
                LIMIT 1
        ];
        
        if (slips.isEmpty()) return result;
        OPP_SlipInfo__c slip = slips[0];
        
        // 메타 가져오기
        Map<String, CountryMapping__mdt> metaMap = CountryMapping__mdt.getAll();
        
        // 각 필드 매핑 처리
        result.put('TerritoryScope', getLabel(slip.TerritoryScope__c, metaMap));
        result.put('GoverningLaw', getLabel(slip.GoverningLaw__c, metaMap));
        result.put('CountryOrigin', getLabel(slip.CountryOrigin_fm__c, metaMap));
        
        return result;
    }
    
    /**
     * @description 국가 코드 값을 CountryMapping 메타데이터에서 조회하여 레이블로 변환한다. 코드가 없거나 매핑이 없으면 원본 값을 반환한다.
     * @param codeValue 변환할 국가 코드 문자열 (세미콜론 또는 언더스코어 구분자 포함 가능)
     * @param metaMap CountryMapping 메타데이터 전체 맵
     * @return 매핑된 레이블 문자열 또는 원본 코드 값
     */
    private static String getLabel(String codeValue, Map<String, CountryMapping__mdt> metaMap) {
        if (String.isBlank(codeValue) || codeValue == 'No data.') return codeValue;
        
        // 분리자(;, _) 처리: 첫 번째 코드 추출
        String cleanCode = codeValue.contains(';') ? codeValue.split(';')[0] :
            (codeValue.contains('_') ? codeValue.split('_')[0] : codeValue);
        cleanCode = cleanCode.trim();
        
        CountryMapping__mdt rec = metaMap.get(cleanCode);
        return (rec != null && String.isNotBlank(rec.LabelName__c)) ? rec.LabelName__c : codeValue;
    }
    
    /**
     * @description 오늘 날짜를 영문 서수 형식(예: 17th April 2026)으로 변환하여 반환한다.
     * @return 영문 서수 날짜 형식 문자열
     */
    private static String getTodayDate() {
        Date today = Date.today();
        Integer day = today.day();
        
        // 영어 날짜 접미사 (st, nd, rd, th)
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
        
        // 월/년도 포맷
        String monthYear = Datetime.newInstance(today.year(), today.month(), today.day()).format('MMMM yyyy');
        return String.valueOf(day) + suffix + ' ' + monthYear;
    }
    
    
    /**
     * @description 텍스트 필드 값을 줄 바꿈 기준으로 분리하여 각 줄을 'Line' 키를 가진 Map의 List로 변환한다.
     * @param value 변환할 텍스트 문자열
     * @return 각 줄이 {'Line': '...'} 형태의 Map으로 구성된 List
     */
    private static List<Object> toLineList(String value) {
        List<Object> result = new List<Object>();
        if (String.isBlank(value)) return result;
        
        String cleaned = value.unescapeHtml4().replace('\r\n', '\n');
        
        // 줄 단위로 분리
        for (String line : cleaned.split('\n')) {
            String trimmedLine = line.trim();
            
            if (String.isNotBlank(trimmedLine)) {
                Map<String, String> lineMap = new Map<String, String>();
                lineMap.put('Line', trimmedLine);
                result.add(lineMap);
            }
        }
        return result;
    }
    
    /**
     * @description 문서 출력에 사용되는 Custom Label 값을 Map으로 반환한다.
     *              BasisWritten: SLIP_DOC_BASIS_OF_WRITTEN_LINES
     *              BasisSigned: SLIP_DOC_BASIS_OF_SIGNED_LINES
     * @return BasisWritten, BasisSigned 키를 포함한 Map
     */
    private static Map<String, Object> getCustomLabelData() {
        return new Map<String, Object>{
            'BasisWritten' => Label.SLIP_DOC_BASIS_OF_WRITTEN_LINES,
            'BasisSigned'  => Label.SLIP_DOC_BASIS_OF_SIGNED_LINES
        };
    }
    
    /**
     * @description 지정된 SlipInfo 레코드의 기본 문서 정보(ENDNo, LKRefNo, Amendments, ENDEffectivedDate)를 조회하여 반환한다.
     * @param slipId 대상 OPP_SlipInfo__c 레코드 Id
     * @return ENDNo, LKRefNo, Amendments, ENDEffectivedDate 키를 포함한 Map
     */
    private static Map<String, Object> getSlipInfoData(Id slipId) {
        Map<String, Object> resultMap = new Map<String, Object>();
        
        OPP_SlipInfo__c slip = [
                SELECT Id, Placement_lk__r.LKRefNoh__c, ENDEffectivedDate__c,
                        Placement_lk__r.ENDNo__c, Amendments__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipId
                LIMIT 1
        ];
        
        // 날짜 포맷팅 (DD Month YYYY)
        String formattedDate = '';
        if (slip.ENDEffectivedDate__c != null) {
            Datetime dt = Datetime.newInstance(slip.ENDEffectivedDate__c, Time.newInstance(0, 0, 0, 0));
            formattedDate = dt.format('d MMMM yyyy', 'en_US');
        }
        
        resultMap.put('ENDNo', slip.Placement_lk__r != null ? String.valueOf(slip.Placement_lk__r.ENDNo__c) : '');
        resultMap.put('LKRefNo', slip.Placement_lk__r.LKRefNoh__c);
        resultMap.put('Amendments', slip.Amendments__c);
        resultMap.put('ENDEffectivedDate', formattedDate);
        
        return resultMap;
    }
    
}