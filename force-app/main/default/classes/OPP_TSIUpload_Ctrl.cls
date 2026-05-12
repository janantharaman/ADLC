/**********************************************************************************
 * @filename       : OPP_TSIUpload_Ctrl.cls
 * @projectname   : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-16 (금)
 * @group         :
 * @group-content :
 * @description   : OPP_TSIByLocation__c 데이터를 엑셀 업로드 형태로 처리하는 Controller
 *                  - 필드 메타데이터 조회, 업로드 데이터 파싱/저장, Google Geo 기반 주소 보완
 *                  - Slip TSI__c 와 TSI By Location 합계의 통화별 정합성 검증 기능
 * @test-class    : OppTSIUpload_Ctrl_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-16      i2max            Create
**********************************************************************************/

public with sharing class OPP_TSIUpload_Ctrl implements Database.AllowsCallouts  {

    /**
     * @description 업로드 템플릿 구성에 필요한 OPP_TSIByLocation__c 필드 메타데이터를 반환
     *              (필드 순서, 라벨, 타입, 필수 여부, Picklist/Boolean 옵션 포함)
     * @return Map<String, Object> fieldOrder 및 fields 정보를 담은 메타데이터 맵
     */
    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> getTSIFieldMetadata() {

        Map<String, Object> response = new Map<String, Object>();
        Map<String, Object> fieldResultMap = new Map<String, Object>();

        Schema.SObjectType objectType =
                Schema.getGlobalDescribe().get('OPP_TSIByLocation__c');

        if (objectType == null) {
            throw new AuraHandledException('Object OPP_TSIByLocation__c not found');
        }

        Map<String, Schema.SObjectField> fieldMap =
                objectType.getDescribe().fields.getMap();

        List<String> fieldOrder = new List<String>{
                'LocationName__c','UnamedLocation__c','Address__Street__s',
           /*     'GPSCoordinates__Latitude__s','GPSCoordinates__Longitude__s',*/
                'Address__PostalCode__s','CoveredSection__c','Asset__c',
                'TSICurrency__c','InsuredAmount__c','GrossRatePct__c',
                'DPPct__c','PremiumCurrency__c','FxRatePremCurrency__c'
        };

        for (String fieldName : fieldOrder) {

            if (!fieldMap.containsKey(fieldName)) continue;

            Schema.DescribeFieldResult d =
                    fieldMap.get(fieldName).getDescribe();

            Map<String, Object> fieldInfo = new Map<String, Object>{
                    'apiName' => fieldName,
                    'label' => d.getLabel(),
                    'type' => String.valueOf(d.getType()),
                    'required' => !d.isNillable()
            };

            if (d.getType() == Schema.DisplayType.PICKLIST ||
                    d.getType() == Schema.DisplayType.MULTIPICKLIST) {

                List<Map<String, String>> picklistValues =
                        new List<Map<String, String>>();

                for (Schema.PicklistEntry pe : d.getPicklistValues()) {
                    if (pe.isActive()) {
                        picklistValues.add(new Map<String, String>{
                                'label' => pe.getLabel(),
                                'value' => pe.getValue()
                        });
                    }
                }

                fieldInfo.put('picklistValues', picklistValues);
            }

            if (d.getType() == Schema.DisplayType.BOOLEAN) {
                fieldInfo.put('booleanValues', new List<String>{'true','false'});
            }

            fieldResultMap.put(fieldName, fieldInfo);
        }

        response.put('fieldOrder', fieldOrder);
        response.put('fields', fieldResultMap);

        return response;
    }

    /**
     * @description 다양한 입력값(Y/YES/TRUE/1 등)을 Boolean 값으로 변환하는 유틸리티 메서드
     * @param value 변환할 원본 값
     * @return Boolean true/false 변환 결과
     */
    private static Boolean toBoolean(Object value) {
        if (value == null) return false;

        String s = String.valueOf(value).trim().toUpperCase();
        return s == 'Y' || s == 'YES' || s == 'TRUE' || s == '1';
    }

    /**
     * @description 업로드된 TSI By Location 행 데이터를 SlipInfo 에 저장하고 TSI 정합성 여부를 반환
     *              주소/좌표/우편번호 기반 Geo 보완 후 레코드를 생성하며, 저장 후 Slip TSI 와 합계를 비교한다.
     * @param slipInfoId 저장 대상 OPP_SlipInfo__c Id
     * @param tsiList 업로드된 행 데이터 목록
     * @return Boolean 저장 후 Slip TSI 와 TSI By Location 합계의 통화별 일치 여부
     */
    @AuraEnabled
    public static Boolean saveTSIByLocation(Id slipInfoId, List<Map<String, Object>> tsiList) {
        if (slipInfoId == null) {
            throw new AuraHandledException('SlipInfo Id is required.');
        }

        List<OPP_TSIByLocation__c> tsiRecords = new List<OPP_TSIByLocation__c>();

        for (Map<String, Object> row : tsiList) {

            OPP_TSIByLocation__c tsi = new OPP_TSIByLocation__c();
            tsi.SlipInfo_md__c = slipInfoId;
            tsi.Type__c = 'TSIByLocation';

            tsi.LocationName__c = (String) row.get('LocationName__c');
            tsi.UnamedLocation__c = toBoolean(row.get('UnamedLocation__c'));
            tsi.CoveredSection__c = (String) row.get('CoveredSection__c');
            tsi.Asset__c = (String) row.get('Asset__c');
            tsi.TSICurrency__c = (String) row.get('TSICurrency__c');
            tsi.PremiumCurrency__c = (String) row.get('PremiumCurrency__c');


            tsi.InsuredAmount__c = row.get('InsuredAmount__c') != null ? Decimal.valueOf(String.valueOf(row.get('InsuredAmount__c'))) : null;
            tsi.GrossRatePct__c = row.get('GrossRatePct__c') != null ? Decimal.valueOf(String.valueOf(row.get('GrossRatePct__c'))) : null;
            tsi.DPPct__c = row.get('DPPct__c') != null ? Decimal.valueOf(String.valueOf(row.get('DPPct__c'))) : null;
            tsi.FxRatePremCurrency__c = row.get('FxRatePremCurrency__c') != null ? Decimal.valueOf(String.valueOf(row.get('FxRatePremCurrency__c'))) : null;

            String street = (String) row.get('Address__Street__s');
            String postal = (String) row.get('Address__PostalCode__s');
            String latStr = row.get('GPSCoordinates__Latitude__s') != null ? String.valueOf(row.get('GPSCoordinates__Latitude__s')) : null;
            String lngStr = row.get('GPSCoordinates__Longitude__s') != null ? String.valueOf(row.get('GPSCoordinates__Longitude__s')) : null;

            Boolean geoResolved = false;

            try {
                if (String.isNotBlank(street)) {
                    geoResolved = resolveGeo(tsi, street);
                }

                if (!geoResolved && String.isNotBlank(latStr) && String.isNotBlank(lngStr)) {
                    geoResolved = resolveGeo(tsi, latStr + ',' + lngStr);
                }

                if (!geoResolved && String.isNotBlank(postal)) {
                    geoResolved = resolveGeo(tsi, postal);
                }

            }  catch (Exception e) {
                throw new AuraHandledException('Google Geo failed: ' + e.getMessage());
            }

            tsiRecords.add(tsi.clone(false, true, false, false));

        }

        try {
            insert tsiRecords;
        } catch (Exception e) {
            throw new AuraHandledException('Insert failed: ' + e.getMessage());
        }

        return validateTSIMatch(slipInfoId);
    }

    /**
     * @description Google Map Service 로 주소 정보를 조회해 TSI 레코드의 주소/좌표 필드를 보완
     * @param tsi 주소 정보를 채울 OPP_TSIByLocation__c 레코드
     * @param addressParam 조회할 주소 또는 좌표 문자열
     * @return Boolean Geo 조회 성공 여부
     */
    private static Boolean resolveGeo(OPP_TSIByLocation__c tsi, String addressParam) {

        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();
        req.address = addressParam;
        req.mode = 'ADDRESS';

        List<COM_GoogleMapService.GeoResult> res =
                COM_GoogleMapService.findGeoInfo(JSON.serialize(req));

        if (!res.isEmpty() && res[0].status == 'OK') {

            COM_GoogleMapService.GeoResult geo = res[0];

            tsi.Address__Street__s = addressParam;
            tsi.GPSCoordinates__Latitude__s = geo.lat;
            tsi.GPSCoordinates__Longitude__s = geo.lng;
            tsi.Address__PostalCode__s = geo.postalCode;
            tsi.Address__City__s = geo.city;
            tsi.Address__StateCode__s = geo.stateCode;
            tsi.Address__CountryCode__s = geo.countryCode;

            return true;
        }

        return false;
    }

    /**
     * @description SlipInfo.TSI__c 텍스트를 파싱하여 통화별 금액 맵으로 변환
     *              구분자(줄바꿈, '/')를 기준으로 분리 후 앞 3자 통화코드와 금액을 추출한다.
     * @param tsiText SlipInfo 의 TSI__c 원본 문자열
     * @return Map<String, Decimal> 통화코드별 금액 맵
     */
    private static Map<String, Decimal> parseSlipTSI(String tsiText) {

        Map<String, Decimal> result = new Map<String, Decimal>();

        if (String.isBlank(tsiText)) {
            return result;
        }

        // 줄바꿈,  "/" 구분
        List<String> parts = tsiText.split('[\\n/]');

        for (String part : parts) {

            part = part.trim();
            if (part.length() < 4) continue;

            String currencyStr = part.substring(0, 3).toUpperCase();
            String amountStr = part.substring(3)
                    .replace(',', '')
                    .trim();

            try {
                Decimal amount = Decimal.valueOf(amountStr);
                result.put(currencyStr, amount);
            } catch (Exception e) {

            }
        }

        return result;
    }

    /**
     * @description Slip TSI 합계 맵과 TSI By Location 합계 맵의 통화/금액 일치 여부를 비교
     * @param slipMap Slip TSI 파싱 결과 맵
     * @param locationMap TSI By Location 집계 결과 맵
     * @return Boolean 두 맵이 완전히 일치하면 true, 아니면 false
     */
    private static Boolean isTSIMatch(Map<String, Decimal> slipMap, Map<String, Decimal> locationMap) {

        if (slipMap.size() != locationMap.size()) {
            return false;
        }

        for (String curr : slipMap.keySet()) {
            if (!locationMap.containsKey(curr)) {
                return false;
            }
            if (slipMap.get(curr) != locationMap.get(curr)) {
                return false;
            }
        }

        return true;
    }

    /**
     * @description SlipInfo 기준으로 저장된 TSI By Location 합계를 계산해 Slip TSI__c 와 정합성 검증
     * @param slipInfoId 검증 대상 OPP_SlipInfo__c Id
     * @return Boolean 통화별 합계가 일치하면 true, 불일치하면 false
     */
    private static Boolean validateTSIMatch(Id slipInfoId) {

        List<OPP_TSIByLocation__c> locations = [
                SELECT TSICurrency__c, InsuredAmount__c
                FROM OPP_TSIByLocation__c
                WHERE SlipInfo_md__c = :slipInfoId
        ];

        if (locations.isEmpty()) {
            return true;
        }

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

        return isTSIMatch(slipMap, locationMap);
    }

}