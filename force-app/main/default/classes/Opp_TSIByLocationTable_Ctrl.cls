/**********************************************************************************
 * @filename       : Opp_TSIByLocationTable_Ctrl.cls
 * @projectname   : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-12 (월)
 * @group         :
 * @group-content :
 * @description   : OPP_TSIByLocation__c(TSI By Location) 레코드의 조회 · 등록 · 수정 · 삭제 및 다운로드 기능을 제공하는 Controller
 *                  1. Placement / Opportunity / SlipInfo 컨텍스트에 따른 TSIByLocation 목록 조회
 *                     및 Slip TSI__c 와 TSIByLocation 합계의 Currency별 정합성 여부(isMatch) 반환
 *                  2. 신규 TSIByLocation 등록 시 Currency 유효성 검증, 주소 유효성 검증,
 *                     Google Maps API 를 통한 주소 자동 보완(enrichAddress) 수행
 *                  3. TSIByLocation 수정 시 수정 대상 제외 기존 데이터와 합산하여 정합성 재계산
 *                  4. TSIByLocation 삭제 시 연관 Panel / PremiumSchedule 존재 여부 확인 후 삭제 처리
 *                  5. NeedRecalculate 플래그 업데이트 및 Platform Event 발행
 *                  6. TSIByLocation 데이터를 헤더/행 구조로 변환하여 엑셀 다운로드 지원
 * @test-class    : Opp_TSIByLocationTable_Ctrl_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-12      i2max            Create
**********************************************************************************/

public with sharing class Opp_TSIByLocationTable_Ctrl {

    /**
     * @description TSIByLocation 목록과 Slip TSI 정합성 여부를 함께 반환하는 응답 클래스
     * locations : TSIByLocation 레코드 목록
     * isMatch : Slip TSI 합계와 TSIByLocation 합계의 통화별 일치 여부
     */
    public class TSIByLocationResponse {
        @AuraEnabled public List<OPP_TSIByLocation__c> locations;
        @AuraEnabled public Boolean isMatch;

        public TSIByLocationResponse(
                List<OPP_TSIByLocation__c> locations,
                Boolean isMatch
        ) {
            this.locations = locations;
            this.isMatch = isMatch;
        }
    }

    // Placement_r.TransactionType_c = END 배서 Slip 조회
    /**
     * @description
     * 현재 페이지 Context (Placement / Opportunity / SlipInfo)에 따라 TransactionType 을 반환
     * recordId 가 Placement 인 경우 : Placement.TransactionType__c 직접 조회
     * recordId 가 Opportunity 또는 SlipInfo 인 경우 : SlipInfo 의 Placement 를 경유하여 조회
     * @param recordId 현재 페이지의 레코드 Id (Placement, Opportunity, SlipInfo 중 하나)
     * @param slipInfoId SlipInfo 페이지에서 전달되는 SlipInfo 레코드 Id (없으면 null)
     * @return String Placement 의 TransactionType__c 값, 조회 불가 시 null
     */
    @AuraEnabled(Cacheable=true)
    public static String getTransactionType(Id recordId, Id slipInfoId) {

        System.debug('### getTransactionType START recordId=' + recordId + ' slipInfoId=' + slipInfoId);

        // Placement 페이지
        if (recordId != null && String.valueOf(recordId).startsWith(
                Placement__c.SObjectType.getDescribe().getKeyPrefix()
        )) {
            System.debug('### Branch: Placement');
            Placement__c p = [
                    SELECT TransactionType__c
                    FROM Placement__c
                    WHERE Id = :recordId
                    LIMIT 1
            ];
            return p.TransactionType__c;
        }

        // Opportunity / SlipInfo 페이지 → SlipInfo의 Placement 경유
        Id resolvedSlipInfoId = slipInfoId != null ? slipInfoId : recordId;
        System.debug('### resolvedSlipInfoId=' + resolvedSlipInfoId);

        if (resolvedSlipInfoId == null) return null;

        OPP_SlipInfo__c slip = [
                SELECT Placement_lk__r.TransactionType__c
                FROM OPP_SlipInfo__c
                WHERE Id = :resolvedSlipInfoId
                LIMIT 1
        ];

        System.debug('### Slip Placement TransactionType=' + slip.Placement_lk__r?.TransactionType__c);

        if (slip.Placement_lk__r == null) return null;

        return slip.Placement_lk__r.TransactionType__c;
    }

    /**
     * @description
     * SlipInfo 또는 Placement 기준으로 TSIByLocation 목록과 Slip TSI 정합성 여부를 반환
     * slipInfoId 가 없고 placementId 가 있는 경우 : Latest_is__c = true 인 SlipInfo 를 기준으로 조회
     * 현재 SlipInfo 에 데이터가 없으면 동일 Placement 내 가장 최근 TSIByLocation 데이터로 fallback
     * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id (없으면 null)
     * @param placementId 조회 기준 Placement 레코드 Id (없으면 null)
     * @return TSIByLocationResponse TSIByLocation 목록 및 Slip TSI 정합성 여부
     */
    @AuraEnabled
    public static TSIByLocationResponse getTSIByLocation(Id slipInfoId, Id placementId) {

        if (slipInfoId == null && placementId != null) {
            List<OPP_SlipInfo__c> slips = [
                    SELECT Id
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :placementId
                    AND Latest_is__c = TRUE
                    LIMIT 1
            ];

            if (!slips.isEmpty()) {
                slipInfoId = slips[0].Id;
            }
        }

        if (slipInfoId == null) {
            return new TSIByLocationResponse(
                    new List<OPP_TSIByLocation__c>(),
                    false
            );
        }

        List<OPP_TSIByLocation__c> locations = [
                SELECT Id, LocationName__c, UnamedLocation__c, Address__c,
                        GPSCoordinates__Latitude__s, GPSCoordinates__Longitude__s,
                        CoveredSection__c, Asset__c,
                        TSICurrency__c, InsuredAmount__c,
                        GrossRatePct__c, DPPct__c,
                        PremiumCurrency__c, FxRatePremCurrency__c,
                        GrossPremBfDP_fm__c, GrossPrem_fm__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipInfoId
                AND Type__c = 'TSIByLocation'
                ORDER BY CreatedDate ASC
        ];

        // Placement 화면에서 현재 slipInfoId에 데이터가 없는 경우,
        // 해당 Placement 내에서 TSIByLocation 데이터가 존재하는 Slip으로 fallback
        if (locations.isEmpty() && placementId != null) {
            List<OPP_TSIByLocation__c> fallbackRows = [
                    SELECT SlipInfo_md__c
                    FROM OPP_TSIByLocation__c
                    WHERE SlipInfo_md__r.Placement_lk__c = :placementId
                    AND Type__c = 'TSIByLocation'
                    ORDER BY SlipInfo_md__r.Latest_is__c DESC,
                             SlipInfo_md__r.CreatedDate DESC,
                             CreatedDate DESC
                    LIMIT 1
            ];

            if (!fallbackRows.isEmpty()) {
                slipInfoId = fallbackRows[0].SlipInfo_md__c;

                locations = [
                        SELECT Id, LocationName__c, UnamedLocation__c, Address__c,
                                GPSCoordinates__Latitude__s, GPSCoordinates__Longitude__s,
                                CoveredSection__c, Asset__c,
                                TSICurrency__c, InsuredAmount__c,
                                GrossRatePct__c, DPPct__c,
                                PremiumCurrency__c, FxRatePremCurrency__c,
                                GrossPremBfDP_fm__c, GrossPrem_fm__c
                        FROM OPP_TSIByLocation__c
                        WHERE SlipInfo_md__c = :slipInfoId
                        AND Type__c = 'TSIByLocation'
                        ORDER BY CreatedDate ASC
                ];
            }
        }

        if (locations.isEmpty()) {
            return new TSIByLocationResponse(locations, false);
        }

        // slip TSI parsing
        OPP_SlipInfo__c slip = [
                SELECT TSI__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipInfoId
                LIMIT 1
        ];

        Map<String, Decimal> slipMap = parseSlipTSI(slip.TSI__c);

        Map<String, Decimal> locationMap = new Map<String, Decimal>();
        for (OPP_TSIByLocation__c loc : locations) {
            if (loc.TSICurrency__c != null && loc.InsuredAmount__c != null) {
                locationMap.put(loc.TSICurrency__c, loc.InsuredAmount__c);
            }
        }

        Boolean isMatch = isTSIMatch(slipMap, locationMap);

        return new TSIByLocationResponse(locations, isMatch);
    }

    /**
         * @description
         * SlipInfo 또는 Placement 기준으로 현재 Slip 의 Type__c 를 반환
         * slipInfoId 미전달 시 Placement 기준 Latest_is__c = true 인 SlipInfo 의 Type__c 반환
         * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id (없으면 null)
         * @param placementId 조회 기준 Placement 레코드 Id (없으면 null)
         * @return String SlipInfo 의 Type__c 값, 조회 불가 시 null
         */
    @AuraEnabled
    public static String getSlipType (Id slipInfoId, Id placementId) {
        System.debug('Get Slip Type ==> ' + placementId);

        if (slipInfoId == null && placementId != null) {
            List<OPP_SlipInfo__c> slips = [
                    SELECT Type__c
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c =: placementId
                    AND Latest_is__c = TRUE
                    LIMIT 1
            ];

            if (!slips.isEmpty()) {
                return slips[0].Type__c;
            }

            return null;
        }

        if (slipInfoId == null) {
            return null;
        }

        return [
                SELECT Type__c
                FROM OPP_SlipInfo__c
                WHERE Id = :slipInfoId
                LIMIT 1
        ].Type__c;
    }

    /**
    * @description
    * TSICurrency__c 필드의 활성 Picklist 옵션 목록을 반환
    * @return List<Map<String, String>> label / value 쌍으로 구성된 옵션 목록
    */
    @AuraEnabled(Cacheable=true)
    public static List<Map<String, String>> getTSICurrencyOptions() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        // 기본 옵션 추가
        options.add(new Map<String, String>{
                'label' => '--None--',
                'value' => ''
        });

        // Picklist 값 조회
        Schema.DescribeFieldResult fieldResult = OPP_TSIByLocation__c.TSICurrency__c.getDescribe();
        List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

        for (Schema.PicklistEntry entry : picklistEntries) {
            if (entry.isActive()) {
                options.add(new Map<String, String>{
                        'label' => entry.getLabel(),
                        'value' => entry.getValue()
                });
            }
        }

        return options;

    }

    /**
    * @description
    * 신규 TSIByLocation 레코드를 등록하고 Slip TSI 정합성 여부를 반환
    * slipInfoId 미전달 시 Placement 기준 최신 SlipInfo 로 자동 설정
    * 등록 전 Currency 유효성 검증(validateCurrencyExistsInSlip) 및 주소 유효성 검증(validateAddress) 수행
    * Google Maps API 를 통해 GPS 또는 우편번호 기반 주소 자동 보완(enrichAddress)
    * 기존 데이터와 신규 데이터의 Currency별 합계를 합산하여 Slip TSI 와 비교
    * @param slipInfoId 등록 대상 OPP_SlipInfo__c 레코드 Id (없으면 null)
    * @param placementId 등록 대상 Placement 레코드 Id (없으면 null)
    * @param records 등록할 OPP_TSIByLocation__c 레코드 목록
    * @return Boolean 등록 후 Slip TSI 와 TSIByLocation 합계의 Currency별 일치 여부
    */
    @AuraEnabled
    public static Boolean insertTSIByLocation(Id slipInfoId, Id placementId, List<OPP_TSIByLocation__c> records) {

        if (records == null || records.isEmpty()) {
            return true;
        }

        if (slipInfoId == null && placementId != null) {
            List<OPP_SlipInfo__c> slips = [
                    SELECT Id
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :placementId
                    AND Latest_is__c = TRUE
                    LIMIT 1
            ];

            if (!slips.isEmpty()) {
                slipInfoId = slips[0].Id;
            }
        }

        OPP_SlipInfo__c slip = [ SELECT Id, TSI__c FROM OPP_SlipInfo__c WHERE Id =: slipInfoId];
        validateCurrencyExistsInSlip(slipInfoId, records);

        // Slip TSI__c 파싱
        Map<String, Decimal> slipCurrencyMap = parseSlipTSI(slip.TSI__c);
        // 신규 행 합계 계산
        Map<String, Decimal> locationCurrencyMap = new Map<String, Decimal>();

        // 기존 데이터 조회
        List<OPP_TSIByLocation__c> existing = [
                SELECT TSICurrency__c, InsuredAmount__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c =: slipInfoId
        ];

        // 기존 데이터 합계
        for (OPP_TSIByLocation__c rec : existing) {
            if (rec.TSICurrency__c == null || rec.InsuredAmount__c == null) continue;

            locationCurrencyMap.put(rec.TSICurrency__c,
                    (locationCurrencyMap.get(rec.TSICurrency__c) == null ? 0 : locationCurrencyMap.get(rec.TSICurrency__c)) + rec.InsuredAmount__c);
        }

        for(OPP_TSIByLocation__c rec : records) {

            rec.SlipInfo_md__c = slipInfoId;
            rec.Type__c = 'TSIByLocation';

            validateAddress(rec);
            enrichAddress(rec);

            if (rec.TSICurrency__c == null || rec.InsuredAmount__c == null || rec.InsuredAmount__c == 0) continue;

            locationCurrencyMap.put(rec.TSICurrency__c,
                    (locationCurrencyMap.get(rec.TSICurrency__c) == null ? 0 : locationCurrencyMap.get(rec.TSICurrency__c)) + rec.InsuredAmount__c);
        }

        System.debug('Slip Map: ' + slipCurrencyMap);
        System.debug('Final Location Map: ' + locationCurrencyMap);

        Boolean isMatch = isTSIMatch(slipCurrencyMap, locationCurrencyMap);
        System.debug('isMatch: ' + isMatch);

        insert records;
        OPP_SlipInfo_Ctrl.updateRecalculateRequired(slipInfoId);

        return isMatch;
    }

    /**
     * @description
     * 기존 TSIByLocation 레코드를 수정하고 Slip TSI 정합성 여부를 반환
     * 수정 전 Currency 유효성 검증 및 주소 처리 수행
     * 수정 대상을 제외한 기존 데이터와 수정 데이터의 Currency별 합계를 합산하여 Slip TSI 와 비교
     * @param slipInfoId 수정 대상 OPP_SlipInfo__c 레코드 Id
     * @param records 수정할 OPP_TSIByLocation__c 레코드 목록
     * @return Boolean 수정 후 Slip TSI 와 TSIByLocation 합계의 Currency별 일치 여부
     */
    @AuraEnabled
    public static Boolean updateTSIByLocation(Id slipInfoId, List<OPP_TSIByLocation__c> records) {

        if (records == null || records.isEmpty()) {
            return true;
        }

        OPP_SlipInfo__c slip = [SELECT Id, TSI__c FROM OPP_SlipInfo__c WHERE Id =: slipInfoId];

        validateCurrencyExistsInSlip(slipInfoId, records);

        Map<String, Decimal> slipCurrencyMap = parseSlipTSI(slip.TSI__c);
        Map<String, Decimal> locationCurrencyMap = new Map<String, Decimal>();

        Set<Id> updatingIds = new Set<Id>();
        for(OPP_TSIByLocation__c r : records) {
            if(r.Id != null) updatingIds.add(r.Id);
        }

        List<OPP_TSIByLocation__c> existing = [
                SELECT Id, TSICurrency__c, InsuredAmount__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c =: slipInfoId
                AND Id NOT IN :updatingIds
        ];

        for (OPP_TSIByLocation__c rec : existing) {
            if(rec.TSICurrency__c == null || rec.InsuredAmount__c == null) continue;

            locationCurrencyMap.put(rec.TSICurrency__c, (locationCurrencyMap.get(rec.TSICurrency__c) == null ? 0 : locationCurrencyMap.get(rec.TSICurrency__c))
                            + rec.InsuredAmount__c);
        }

        for (OPP_TSIByLocation__c rec : records) {

            //rec.SlipInfo_md__c = slipInfoId;

            validateAddress(rec);
            enrichAddress(rec);

            if(rec.TSICurrency__c == null || rec.InsuredAmount__c == null || rec.InsuredAmount__c == 0) continue;

            locationCurrencyMap.put(rec.TSICurrency__c, (locationCurrencyMap.get(rec.TSICurrency__c) == null ? 0 : locationCurrencyMap.get(rec.TSICurrency__c))
                            + rec.InsuredAmount__c);
        }

        Boolean isMatch = isTSIMatch(slipCurrencyMap, locationCurrencyMap);

        update records;
        OPP_SlipInfo_Ctrl.updateRecalculateRequired(slipInfoId);

        return isMatch;
    }

    /**
     * @description
     * GPS 좌표 또는 우편번호를 기반으로 Google Maps API 를 호출하여 주소 정보를 자동 보완
     * GPS 좌표(위경도) 우선, 없으면 우편번호로 조회
     * API 응답이 OK 인 경우 Street, City, PostalCode, CountryCode, StateCode 를 레코드에 반영
     * @param rec 주소를 보완할 OPP_TSIByLocation__c 레코드
     */
    private static void enrichAddress(OPP_TSIByLocation__c rec) {
        Boolean hasLatLng = rec.GPSCoordinates__Latitude__s != null && rec.GPSCoordinates__Longitude__s != null;

        Boolean hasPostal = String.isNotBlank(rec.Address__PostalCode__s);

        if(!hasLatLng && !hasPostal) {
            return;
        }

        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();

        // 위경도
        if(hasLatLng) {
            req.lat  = (Double) rec.GPSCoordinates__Latitude__s;
            req.lng  = (Double) rec.GPSCoordinates__Longitude__s;
            req.mode = 'COORDINATES';
        }

        // Postal Code
        else if(hasPostal) {
            req.address = rec.Address__PostalCode__s;
            req.mode    = 'ADDRESS';
        }

        String jsonReq = JSON.serialize(req);

        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.findGeoInfo(jsonReq);

        if (results != null && !results.isEmpty() && results[0].status == 'OK') {
            COM_GoogleMapService.GeoResult geo = results[0];
            rec.Address__Street__s      = geo.address;
            rec.Address__City__s        = geo.city;
            rec.Address__PostalCode__s  = geo.postalCode;
            rec.Address__CountryCode__s = geo.countryCode;
            rec.Address__StateCode__s   = geo.stateCode;

            rec.Address__Latitude__s  = geo.lat;
            rec.Address__Longitude__s = geo.lng;
        }
    }

    /**
     * @description
     * TSIByLocation 레코드의 주소 입력 유효성을 검증
     * UnamedLocation__c = true 인 경우 검증 생략
     * Street, 우편번호, GPS 좌표 중 하나도 없는 경우 AuraHandledException 발생
     * @param rec 검증할 OPP_TSIByLocation__c 레코드
     */
    private static void validateAddress(OPP_TSIByLocation__c rec) {

        if(rec.UnamedLocation__c != null && rec.UnamedLocation__c) {
            return;
        }

        System.debug('UnnamedLocation__c: ' + rec.UnamedLocation__c);

        Boolean hasStreet  = String.isNotBlank(rec.Address__Street__s);
        Boolean hasPostal  = String.isNotBlank(rec.Address__PostalCode__s);
        Boolean hasLatLng  = rec.GPSCoordinates__Latitude__s  != null && rec.GPSCoordinates__Longitude__s != null;

        if(!hasStreet && !hasPostal && !hasLatLng) {
            throw new AuraHandledException(
                    'Message Test'
                   // 'When Unnamed Location is No, please enter Address or Postal Code, or Latitude/Longitude.'
            );
        }
    }

    /**
     * @description
     * Slip TSI__c 텍스트(줄바꿈 또는 '/' 구분)를 파싱하여 Currency별 금액 Map 으로 반환
     * 각 항목의 앞 3자리를 Currency 코드, 나머지를 금액으로 파싱
     * @param tsiText Slip TSI__c 필드의 텍스트 값
     * @return Map<String, Decimal> Currency 코드 → 금액 매핑
     */
    private static Map<String, Decimal> parseSlipTSI(String tsiText) {

        Map<String, Decimal> result = new Map<String, Decimal>();

        if (String.isBlank(tsiText)) return result;

        // 엔터 또는 /
        List<String> parts = tsiText.split('[\\n/]');

        for (String part : parts) {
            part = part.trim();
            if (part.length() < 4) continue;
            String currencyStr = part.substring(0, 3);
            String amountStr = part.substring(3).replace(',', '').trim();
            Decimal amount;

            try {
                amount = Decimal.valueOf(amountStr);
            } catch (Exception e) {
                continue;
            }

            result.put(currencyStr, amount);
        }

        return result;
    }

    /**
     * @description
     * Slip TSI Currency별 합계와 TSIByLocation Currency별 합계의 일치 여부를 반환
     * Currency 종류 수 불일치, 특정 Currency 미존재, 금액 불일치 중 하나라도 해당하면 false 반환
     * @param slipMap Slip TSI__c 에서 파싱된 Currency별 금액 Map
     * @param locationMap TSIByLocation 의 Currency별 금액 합계 Map
     * @return Boolean Currency 및 금액이 완전히 일치하면 true, 하나라도 다르면 false
     */
    private static Boolean isTSIMatch(Map<String, Decimal> slipMap, Map<String, Decimal> locationMap) {
        if (slipMap.size() != locationMap.size()) return false;

        for (String curr : slipMap.keySet()) {
            if (!locationMap.containsKey(curr)) {
                return false;
            }

            if (slipMap.get(curr) != locationMap.get(curr)) {
                return false;
            }
        }

        for (String curr : locationMap.keySet()) {
            if (!slipMap.containsKey(curr)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @description
     * 전달된 Id 목록의 TSIByLocation 레코드를 삭제
     * @param recordIds 삭제할 OPP_TSIByLocation__c 레코드 Id 목록
     */
    @AuraEnabled
    public static void deleteTSIByLocation(List<Id> recordIds) {
        if (recordIds == null || recordIds.isEmpty()) return;

        delete [
                SELECT Id
                FROM OPP_TSIByLocation__c
                WHERE Id IN :recordIds
        ];
    }

    /**
     * @description
     * 등록할 TSIByLocation 레코드의 Currency가 SlipInfo 가 연결된 Slip(Type__c = 'Slip') 에 존재하는지 검증
     * Slip 에 없는 Currency가 하나라도 있으면 AuraHandledException 발생
     * @param slipInfoId 검증 기준 OPP_SlipInfo__c 레코드 Id
     * @param records 검증할 OPP_TSIByLocation__c 레코드 목록
     */
    private static void validateCurrencyExistsInSlip(Id slipInfoId, List<OPP_TSIByLocation__c> records) {

        Set<String> currencies = new Set<String>();

        for (OPP_TSIByLocation__c r : records) {
            if (r.TSICurrency__c != null) {
                currencies.add(r.TSICurrency__c);
            }
        }

        if (currencies.isEmpty()) return;

        Set<String> existingSlipCurrencies = new Set<String>();

        for (OPP_TSIByLocation__c rec : [
                SELECT TSICurrency__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipInfoId
                AND Type__c = 'Slip'
                AND TSICurrency__c IN :currencies
        ]) {
            existingSlipCurrencies.add(rec.TSICurrency__c);
        }

        // 없는 Currency 찾기
        List<String> missing = new List<String>();

        for (String c : currencies) {
            if (!existingSlipCurrencies.contains(c)) {
                missing.add(c);
            }
        }

        if (!missing.isEmpty()) {
            throw new AuraHandledException(
                    'TSI by Location cannot be saved. No matching Slip record found for currency: '
                            + String.join(missing, ', ')
            );
        }
    }

    /**
    * @description
    * Placement 또는 Opportunity 에 연결된 Layer → Panel 목록을 통화 목록 기준으로 조회
    * placementId 또는 opportunityId 중 하나라도 있으면 조건에 포함하여 Layer 조회
    * @param placementId 조회 기준 Placement 레코드 Id (없으면 null)
    * @param opportunityId 조회 기준 Opportunity 레코드 Id (없으면 null)
    * @param premCurrencies 조회할 통화 코드 목록
    * @return List<OPP_Panel__c> 조건에 해당하는 Panel 레코드 목록
    */
    private static List<OPP_Panel__c> getPanels (Id placementId, Id opportunityId, List<String> premCurrencies) {
        System.debug('### [START] getPanels');
        System.debug('### placementId: ' + placementId);
        System.debug('### opportunityId: ' + opportunityId);
        System.debug('### premCurrencies: ' + premCurrencies);

        if (premCurrencies == null || premCurrencies.isEmpty()) {
            return new List<OPP_Panel__c>();
        }

        List<String> conditions = new List<String>();

        if (placementId != null) {
            conditions.add('Placement_lk__c = :placementId');
        }

        if (opportunityId != null) {
            conditions.add('Opportunity_md__c = :opportunityId');
        }

        if (conditions.isEmpty()) {
            return new List<OPP_Panel__c>();
        }

        String layerQuery = 'SELECT Id FROM OPP_Layer__c WHERE ' + String.join(conditions, ' OR ');

        System.debug('### FINAL LAYER SOQL: ' + layerQuery);

        List<OPP_Layer__c> layers = Database.query(layerQuery);

        if (layers.isEmpty()) {
            System.debug('### No Layers');
            return new List<OPP_Panel__c>();
        }

        Set<Id> layerIds = new Set<Id>();
        for (OPP_Layer__c l : layers) {
            layerIds.add(l.Id);
        }

        List<OPP_Panel__c> panels = [
                SELECT Id, Currency__c, Layer_md__c, Layer_md__r.Placement_lk__c, Layer_md__r.Opportunity_md__c
                FROM OPP_Panel__c
                WHERE Layer_md__c IN :layerIds
                AND Currency__c IN :premCurrencies
        ];

        System.debug('### Panels found: ' + panels.size());
        System.debug('### Panels detail: ' + panels);

        return panels;

    }

    /**
     * @description
     * TSIByLocation 삭제 처리와 연관 Panel 삭제를 함께 수행하며, Panel 존재 여부를 반환
     * 삭제 후 완전히 사라지에 Currency(잔여 레코드 없는 통화)에 연결된 Panel 조회
     * @param placementId 대상 Placement 레코드 Id
     * @param opportunityId 대상 Opportunity 레코드 Id
     * @param slipInfoId 대상 OPP_SlipInfo__c 레코드 Id
     * @param deleteIds 삭제할 OPP_TSIByLocation__c 레코드 Id 목록
     * @param doDelete true: 실제 삭제 수행, false: Panel 존재 여부만 반환
     * @return Boolean 삭제 대상 Currency 연결된 Panel 이 존재하면 true, 없으면 false
     */
    @AuraEnabled
    public static Boolean deleteTSIByLocationAndPanel(Id placementId, Id opportunityId, Id slipInfoId, List<Id> deleteIds, Boolean doDelete) {
        System.debug('### [START] deleteTSIByLocationAndPanel');

        if (deleteIds == null || deleteIds.isEmpty()) {
            return false;
        }

        // 현재 SlipInfo 에 연결된 TSIByLocation(Type=TSIByLocation) 전체 조회
        List<OPP_TSIByLocation__c> existing = [
                SELECT Id, PremiumCurrency__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipInfoId
                AND Type__c = 'TSIByLocation'
        ];

        // 삭제 전 Currency 별 카운트
        Map<String, Integer> originalMap = new Map<String, Integer>();
        for (OPP_TSIByLocation__c rec : existing) {
            if (rec.PremiumCurrency__c == null) continue;
            Integer cnt = originalMap.get(rec.PremiumCurrency__c);
            originalMap.put(rec.PremiumCurrency__c, cnt == null ? 1 : cnt + 1);
        }

        // 삭제 대상 제외 후 Currency 별 카운트
        Set<Id> deleteSet = new Set<Id>(deleteIds);
        Map<String, Integer> remainMap = new Map<String, Integer>();

        for (OPP_TSIByLocation__c rec : existing) {
            if (deleteSet.contains(rec.Id)) continue;
            if (rec.PremiumCurrency__c == null) continue;
            Integer cnt = remainMap.get(rec.PremiumCurrency__c);
            remainMap.put(rec.PremiumCurrency__c, cnt == null ? 1 : cnt + 1);
        }

        // 삭제 후 완전히 사라지는 Currency 추출, (삭제 전엔 있었으나 삭제 후 남은 레코드가 없는 Currency)
        List<String> fullyDeletedCurrencies = new List<String>();
        for (String currencyStr : originalMap.keySet()) {
            if (!remainMap.containsKey(currencyStr)) {
                fullyDeletedCurrencies.add(currencyStr);
            }
        }

        System.debug('### fullyDeletedCurrencies: ' + fullyDeletedCurrencies);

        // 완전히 삭제되는 Currency 가 없으면 Panel 삭제 불필요
        if (fullyDeletedCurrencies.isEmpty()) {
            return false;
        }

        // 해당 Currency 의 Panel 조회
        List<OPP_Panel__c> panels = getPanels(placementId, opportunityId, fullyDeletedCurrencies);
        Boolean hasPanel = !panels.isEmpty();

        System.debug('### hasPanel: ' + hasPanel);

        // doDelete = false
        if (!doDelete) {
            return hasPanel;
        }

        // doDelete = true → 삭제 실행
        // Panel 삭제
        if (hasPanel) {
            System.debug('### Deleting Panels: ' + panels.size());
            delete panels;
        }

        // TSIByLocation 삭제
        List<OPP_TSIByLocation__c> tsiDeleteList = new List<OPP_TSIByLocation__c>();
        for (OPP_TSIByLocation__c rec : existing) {
            if (deleteSet.contains(rec.Id)) {
                tsiDeleteList.add(rec);
            }
        }

        if (!tsiDeleteList.isEmpty()) {
            System.debug('### Deleting TSIByLocation: ' + tsiDeleteList.size());
            delete tsiDeleteList;
        }
        if(opportunityId <> null) OPP_SlipInfo_Ctrl.publishRecordChangedEvent(opportunityId, 'Opportunity', 'NEED_RECALCULATE');
        if(placementId <> null) OPP_SlipInfo_Ctrl.publishRecordChangedEvent(placementId, 'Placement', 'NEED_RECALCULATE');

        return hasPanel;
    }

  /*  // Panel 있는지 체크
    @AuraEnabled
    public static Boolean checkPanels(Id placementId, Id opportunityId, List<String> premCurrencies) {
        List<OPP_Panel__c> panels = getPanels(placementId, opportunityId, premCurrencies);

        return !panels.isEmpty();
    }

    // Panel 삭제
    @AuraEnabled
    public static void deletePanels(Id placementId, Id opportunityId, List<String> premCurrencies) {
        List<OPP_Panel__c> panels = getPanels(placementId, opportunityId, premCurrencies);

        if (!panels.isEmpty()) {
            System.debug('### Deleting panels...');
            delete panels;
            System.debug('### Panels deleted');
        }
    }*/

    /**
     * @description
     * SlipInfo 의 TSIByLocation 에 연결된 Panel 을 기준으로 NeedRecalculate 플래그를 업데이트하고 이벤트 발행
     * SlipInfo 의 TSIByLocation PremiumCurrency 기준으로 Panel 조회
     * Panel 이 Placement 에 연결된 경우 → Placement.NeedRecalculate_is__c = true
     * Panel 이 Opportunity 에 연결된 경우 → Opportunity.NeedRecalculate_is__c = true
     * @param placementId 대상 Placement 레코드 Id
     * @param opportunityId 대상 Opportunity 레코드 Id
     * @param slipInfoId 대상 OPP_SlipInfo__c 레코드 Id
     */
    @AuraEnabled
    public static void updateNeedRecalculateFlag( Id placementId, Id opportunityId, Id slipInfoId) {
        Set<String> premCurrencies = new Set<String>();

        for (OPP_TSIByLocation__c rec : [
                SELECT PremiumCurrency__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipInfoId
                AND Type__c = 'TSIByLocation'
        ]) {
            if (rec.PremiumCurrency__c != null) {
                premCurrencies.add(rec.PremiumCurrency__c);
            }
        }

        System.debug('### tsiCurrencies: ' + premCurrencies);

        if (premCurrencies.isEmpty()) {
            System.debug('### No currencies → EXIT');
            return;
        }

        List<OPP_Panel__c> panels = getPanels(
                placementId,
                opportunityId,
                new List<String>(premCurrencies)
        );

        System.debug('### panels found: ' + panels.size());

        if (panels.isEmpty()) {
            System.debug('### No matching Panels → EXIT');
            return;
        }

        Boolean hasPlacementPanel = false;
        Boolean hasOpportunityPanel = false;

        for (OPP_Panel__c p : panels) {

            if (p.Layer_md__r.Placement_lk__c != null) {
                hasPlacementPanel = true;
            }

            if (p.Layer_md__r.Opportunity_md__c != null) {
                hasOpportunityPanel = true;
            }
        }

        List<SObject> updates = new List<SObject>();

        if (hasPlacementPanel && placementId != null) {
            updates.add(new Placement__c(
                    Id = placementId,
                    NeedRecalculate_is__c = true
            ));
        }

        if (hasOpportunityPanel && opportunityId != null) {
            updates.add(new Opportunity(
                    Id = opportunityId,
                    NeedRecalculate_is__c = true
            ));
        }

        if (!updates.isEmpty()) {
            update updates;
            System.debug('### Updated NeedRecalculate');
            if(opportunityId <> null) OPP_SlipInfo_Ctrl.publishRecordChangedEvent(opportunityId, 'Opportunity', 'NEED_RECALCULATE');
            if(placementId <> null) OPP_SlipInfo_Ctrl.publishRecordChangedEvent(placementId, 'Placement', 'NEED_RECALCULATE');
        } else {
            System.debug('### Nothing to update');
        }

        System.debug('### [END]');
    }

    /**
     * @description TSI 다운로드용 헤더와 행 데이터를 함께 반환하는 응답 클래스
     * headers : 컬럼 헤더 목록
     * rows : 각 TSIByLocation 레코드를 문자열 목록으로 변환한 행 데이터
     */
    public class TSIDownloadResponse {
        @AuraEnabled public List<String> headers;
        @AuraEnabled public List<List<String>> rows;

        public TSIDownloadResponse(List<String> headers, List<List<String>> rows) {
            this.headers = headers;
            this.rows    = rows;
        }
    }

    /**
     * @description
     * TSIByLocation 레코드의 주소 구성 요소를 쉼표로 연결하여 단일 문자열로 반환
     * Street, City, StateCode, PostalCode, CountryCode 순서로 값이 있는 항목만 포함
     * @param loc 주소를 추출할 OPP_TSIByLocation__c 레코드
     * @return String 쉼표로 연결된 주소 문자열
     */
    private static String buildAddressCell(OPP_TSIByLocation__c loc) {
        List<String> addressParts = new List<String>();

        if (String.isNotBlank(loc.Address__Street__s)) {
            addressParts.add(loc.Address__Street__s);
        }
        if (String.isNotBlank(loc.Address__City__s)) {
            addressParts.add(loc.Address__City__s);
        }
        if (String.isNotBlank(loc.Address__StateCode__s)) {
            addressParts.add(loc.Address__StateCode__s);
        }
        if (String.isNotBlank(loc.Address__PostalCode__s)) {
            addressParts.add(loc.Address__PostalCode__s);
        }
        if (String.isNotBlank(loc.Address__CountryCode__s)) {
            addressParts.add(loc.Address__CountryCode__s);
        }

        return String.join(addressParts, ', ');
    }

    /**
     * @description
     * TSIByLocation 데이터를 다운로드용 헤더/행 구조로 변환하여 반환
     * slipInfoId 미전달 시 Placement 기준 최신 SlipInfo 로 자동 설정
     * @param slipInfoId 조회 기준 OPP_SlipInfo__c 레코드 Id (없으면 null)
     * @param placementId 조회 기준 Placement 레코드 Id (없으면 null)
     * @return TSIDownloadResponse 헤더 목록 및 행 데이터 목록
     */
    @AuraEnabled
    public static TSIDownloadResponse downloadTSIByLocation(Id slipInfoId, Id placementId) {

        if (slipInfoId == null && placementId != null) {
            List<OPP_SlipInfo__c> slips = [
                    SELECT Id
                    FROM OPP_SlipInfo__c
                    WHERE Placement_lk__c = :placementId
                    AND Latest_is__c = TRUE
                    LIMIT 1
            ];
            if (!slips.isEmpty()) {
                slipInfoId = slips[0].Id;
            }
        }

        List<String> headers = new List<String>{
                'No',
                'Location Name',
                'Unnamed Location',
                'Address',
                'Latitude',
                'Longitude',
                'Covered Section',
                'Asset',
                'TSI Currency',
                'Insured Amount',
                'Gross Rate (%)',
                'DP (%)',
                'Premium Currency',
                'Fx Rate to Prem Currency',
                'Gross Prem (Before DP)',
                'Gross Prem'
        };

        if (slipInfoId == null) {
            return new TSIDownloadResponse(headers, new List<List<String>>());
        }

        List<OPP_TSIByLocation__c> locations = [
                SELECT Id, LocationName__c, UnamedLocation__c, Address__c,
                        Address__Street__s, Address__City__s, Address__StateCode__s,
                        Address__PostalCode__s, Address__CountryCode__s,
                        GPSCoordinates__Latitude__s, GPSCoordinates__Longitude__s,
                        CoveredSection__c, Asset__c,
                        TSICurrency__c, InsuredAmount__c,
                        GrossRatePct__c, DPPct__c,
                        PremiumCurrency__c, FxRatePremCurrency__c,
                        GrossPremBfDP_fm__c, GrossPrem_fm__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipInfoId
                AND Type__c = 'TSIByLocation'
                ORDER BY CreatedDate ASC
        ];

        List<List<String>> rows = new List<List<String>>();
        Integer seq = 1;

        for (OPP_TSIByLocation__c loc : locations) {
            String addressCell = buildAddressCell(loc);

            List<String> row = new List<String>{
                    String.valueOf(seq++),
                    loc.LocationName__c ?? '',
                    loc.UnamedLocation__c == true ? 'Yes' : 'No',
                    addressCell,
                    loc.GPSCoordinates__Latitude__s != null ? String.valueOf(loc.GPSCoordinates__Latitude__s) : '',
                    loc.GPSCoordinates__Longitude__s != null ? String.valueOf(loc.GPSCoordinates__Longitude__s) : '',
                    loc.CoveredSection__c ?? '',
                    loc.Asset__c ?? '',
                    loc.TSICurrency__c ?? '',
                    loc.InsuredAmount__c != null ? formatDecimal(loc.InsuredAmount__c) : '',
                    loc.GrossRatePct__c != null ? String.valueOf(loc.GrossRatePct__c) : '',
                    loc.DPPct__c != null ? String.valueOf(loc.DPPct__c) : '',
                    loc.PremiumCurrency__c ?? '',
                    loc.FxRatePremCurrency__c != null ? String.valueOf(loc.FxRatePremCurrency__c) : '',
                    loc.GrossPremBfDP_fm__c != null ? formatDecimal(loc.GrossPremBfDP_fm__c) : '',
                    loc.GrossPrem_fm__c != null ? formatDecimal(loc.GrossPrem_fm__c) : ''
            };
            rows.add(row);
        }

        return new TSIDownloadResponse(headers, rows);
    }

    /**
    * @description
    * Decimal 값을 문자열로 변환
    * 정수로 떨어지는 경우 소수점 없이 반환
    * 소수점이 있는 경우 후행 0 제거 후 반환
    * @param val 변환할 Decimal 값
    * @return String 변환된 문자열, null 이면 빈 문자열 반환
    */
    private static String formatDecimal(Decimal val) {
        if (val == null) return '';
        if (val == val.setScale(0)) {
            return String.valueOf(val.setScale(0).longValue());
        }
        return String.valueOf(val.stripTrailingZeros());
    }

}