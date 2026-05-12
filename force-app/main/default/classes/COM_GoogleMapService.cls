/**********************************************************************************
 * @filename      : COM_GoogleMapService.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-30 (금)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : COM_GoogleMapService_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-30      i2max     Create
**********************************************************************************/
public with sharing class COM_GoogleMapService {

    private static final APIConfig__mdt CONFIG = APIConfig__mdt.getInstance('GoogleMaps');
    private static final String API_KEY = CONFIG.APIKey__c;

    // State Name Mapping (Korean -> English Code)
    private static final Map<String, String> KOREA_STATE_MAP = new Map<String, String>{
            '서울특별시' => 'Seoul',
            '부산광역시' => 'Busan',
            '대구광역시' => 'Daegu',
            '인천광역시' => 'Incheon',
            '광주광역시' => 'Gwangju',
            '대전광역시' => 'Daejeon',
            '울산광역시' => 'Ulsan',
            '세종특별자치시' => 'Sejong',
            '경기도' => 'Gyeonggi-do',
            '강원도' => 'Gangwon-do',
            '충청북도' => 'Chungcheongbuk-do',
            '충청남도' => 'Chungcheongnam-do',
            '전라북도' => 'Jeollabuk-do',
            '전라남도' => 'Jeollanam-do',
            '경상북도' => 'Gyeongsangbuk-do',
            '경상남도' => 'Gyeongsangnam-do',
            '제주특별자치도' => 'Jeju-do'
    };

    // ===========================================================================
    // Wrapper Classes (Flow & LWC Compatible)
    // ===========================================================================
    public class GeoRequest {
        @InvocableVariable(Label='Address' Description='Address to search (Geocoding)')
        @AuraEnabled public String address;

        @InvocableVariable(Label='Latitude' Description='Latitude (Reverse Geocoding)')
        @AuraEnabled public Double lat;

        @InvocableVariable(Label='Longitude' Description='Longitude (Reverse Geocoding)')
        @AuraEnabled public Double lng;
        @InvocableVariable(
                Label='Search Mode'
                Description='검색 모드를 지정합니다. 주소로 검색하려면 "ADDRESS", 좌표로 주소를 찾으려면 "COORDINATES"를 입력하세요. (대소문자 구분 없음)'
        )
        @AuraEnabled public String mode;
        @InvocableVariable(
                Label='language'
                Description='검색결과 언어를 설정합니다. 기본값은 영어(en)입니다. 미지정 시 영어로 검색결과가 리턴됩니다.'
        )
        @AuraEnabled public String language;  // 'en'(default), 'ko'

    }

    public class GeoResult {
        @InvocableVariable @AuraEnabled public String address;      // Formatted Address
        @InvocableVariable @AuraEnabled public Double lat;          // Latitude
        @InvocableVariable @AuraEnabled public Double lng;          // Longitude
        @InvocableVariable @AuraEnabled public String status;       // OK, ZERO_RESULTS, ERROR
        @InvocableVariable @AuraEnabled public String errorMessage; // Error details

        // Additional Info (Optional)
        @InvocableVariable @AuraEnabled public String placeId;
        @InvocableVariable @AuraEnabled public String country;
        @InvocableVariable @AuraEnabled public String city;
        @InvocableVariable @AuraEnabled public String state;
        @InvocableVariable @AuraEnabled public String countryCode;
        @InvocableVariable @AuraEnabled public String stateCode;
        @InvocableVariable @AuraEnabled public String postalCode;

        public GeoResult withError(String errStatus, String errMsg) {
            this.status = errStatus;
            this.errorMessage = errMsg;
            return this;
        }
        public GeoResult withError() {
            return withError('ZERO_RESULTS', Label.COM_MSG_NO_SEARCH_RESULT);
        }
    }


    // ===========================================================================
    // Flow Method (@InvocableMethod)
    // ===========================================================================
    @InvocableMethod(
            Callout=true
            Label='Get Geo Info'
            Description='Google Maps API를 사용하여 주소 및 좌표 검색을 수행합니다. 주소 검색 시 Mode="ADDRESS", 좌표 검색 시 Mode="COORDINATES"를 입력하세요. 검색 결과 중 첫 번째 행만 반환됩니다.'
            Category='Google Maps')
    public static List<GeoResult> getGeoInfo(List<GeoRequest> requests) {
        List<GeoResult> results = new List<GeoResult>();
        for(GeoRequest req : requests) {
            List<GeoResult> geoResults = executeGeocoding(req);
            if(geoResults.isEmpty()) {
                results.add(new GeoResult().withError());
            } else {
                results.add(geoResults[0]);
            }
        }
        return results;
    }

    // ===========================================================================
    // LWC Method (@AuraEnabled)
    // ===========================================================================
    @AuraEnabled
    public static List<GeoResult> findGeoInfo(String geoRequest) {
        if(String.isBlank(geoRequest)) return new List<GeoResult>();
        GeoRequest req = (GeoRequest) JSON.deserialize(geoRequest, GeoRequest.class);
        return executeGeocoding(req);
    }

    // ===========================================================================
    // Core Logic (Private)
    // ===========================================================================
    private static List<GeoResult> executeGeocoding(GeoRequest req) {

//        System.debug('<< ⭐️⭐⭐  executeGeocoding >> req=['+ req +']');

        List<GeoResult> resultList = new List<GeoResult>();

        // Validation
//        Boolean hasAddress = String.isNotBlank(req.address);
        Boolean hasAddress = String.isNotBlank(req.address) && req.address != 'null';
        Boolean hasCoordinates = (req.lat != null && req.lng != null);

        // Determine Mode if not provided
        String searchMode = req.mode;
        if (String.isBlank(searchMode)) {
            searchMode = (hasAddress ? 'ADDRESS' : 'COORDINATES');
        }

        if ('ADDRESS'.equalsIgnoreCase(searchMode) && !hasAddress) {
             resultList.add(new GeoResult().withError('ERROR', 'Address is required for ADDRESS mode.'));
             return resultList;
        }
        if ('COORDINATES'.equalsIgnoreCase(searchMode) && !hasCoordinates) {
            resultList.add(new GeoResult().withError('ERROR', 'Coordinates are required for COORDINATES mode.'));
            return resultList;
        }

        try {
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            String lang = String.isNotBlank(req.language) ? req.language : 'en';
            String requestUrl = 'callout:GoogleMapsAPI/maps/api/geocode/json?key=' + API_KEY + '&language=' + lang + '&region=kr';

            if ('ADDRESS'.equalsIgnoreCase(searchMode)) {
                requestUrl += '&address=' + EncodingUtil.urlEncode(req.address, 'UTF-8');// Geocoding: Address -> Lat/Lng
            } else {
                // Reverse Geocoding: Lat/Lng -> Address
                requestUrl += '&latlng=' + req.lat + ',' + req.lng;
                requestUrl += '&result_type=street_address';
                //street_address (도로명 주소 / 지번 주소): 가장 일반적인 "정확한 주소
                //premise (구내 / 부지 / 건물 자체): 도로명 주소 체계로 딱 떨어지지 않는 특정 건물, 단지, 시설물
            }

            request.setEndpoint(requestUrl);
            request.setMethod('GET');
            request.setTimeout(10000); // 10초 timeout

            HttpResponse response = http.send(request);

            if (response.getStatusCode() == 200) {
                Map<String, Object> resultsMap = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                String status = (String) resultsMap.get('status');

//                System.debug('[COM_GoogleMapService > executeGeocoding] status=['+ status +']');

                if ('OK'.equalsIgnoreCase(status)) {
                    List<Object> results = (List<Object>) resultsMap.get('results');
//                    System.debug('[COM_GoogleMapService > executeGeocoding] results.size()=[' + results.size() +']');

                    if (results != null && !results.isEmpty()) {

                        Map<String, String> stateCodes = COM_MetaUtil.getPicklistL2V('Account','Address__StateCode__s');

                        for(Object r : results) {
                            Map<String, Object> rMap = (Map<String, Object>) r;
                            List<Object> types = (List<Object>) rMap.get('types');

                            if (types != null && types.contains('plus_code')) {
                                continue;
                            }

                            GeoResult res = new GeoResult();
                            parseResult(res, rMap, stateCodes);
                            res.status = 'OK';
                            resultList.add(res);
                        }

                    } else {
                        resultList.add(new GeoResult().withError());
                    }
                } else {
                    String errMsg = (String) resultsMap.get('error_message');
                    if (String.isBlank(errMsg)) errMsg = 'Google API Status: ' + status;
                    resultList.add(new GeoResult().withError(status, errMsg));
                }
            } else {
                resultList.add(new GeoResult().withError('HTTP_ERROR', 'HTTP Status Code: ' + response.getStatusCode()));
            }

        } catch (Exception e) {
            resultList.add(new GeoResult().withError('EXCEPTION', e.getMessage()));
            System.debug('Google Map API Error: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }

        return resultList;
    }

    private static void parseResult(GeoResult result, Map<String, Object> data, Map<String, String> stateCodes) {

        // 1. Formatted Address
        result.address = (String) data.get('formatted_address');
        result.placeId = (String) data.get('place_id');

        // 2. Geometry (Lat/Lng)
        Map<String, Object> geometry = (Map<String, Object>) data.get('geometry');
        if (geometry != null) {
            Map<String, Object> location = (Map<String, Object>) geometry.get('location');
            if (location != null) {
                result.lat = (Double) location.get('lat');
                result.lng = (Double) location.get('lng');
            }
        }

        // 3. Address Components (Country, City, State)
        List<Object> components = (List<Object>) data.get('address_components');
        if (components != null) {
            for (Object compObj : components) {
                Map<String, Object> comp = (Map<String, Object>) compObj;
                List<Object> types = (List<Object>) comp.get('types');
                String longName = (String) comp.get('long_name');
                String shortName = (String) comp.get('short_name');

                if (types.contains('country')) {
                    result.country = longName;
                    result.countryCode = shortName;
                }
                if (types.contains('administrative_area_level_1')) {
                    result.state = longName;
                    result.stateCode = shortName;
                }
                if (types.contains('locality') || types.contains('administrative_area_level_2')) {
                    if (String.isBlank(result.city) || types.contains('locality')) {
                        result.city = longName;
                    }
                }
                //우편번호
                if(types.contains('postal_code')) {
                    result.postalCode = longName;
                }
            }
        }

        if(stateCodes.containsKey(result.state)) {
            result.stateCode = stateCodes.get(result.state);
        } else {
            String stateCode = result.stateCode;
            result.stateCode = '';
            if ('KR'.equalsIgnoreCase(result.countryCode)) {
                if((KOREA_STATE_MAP.containsKey(stateCode) && stateCodes.containsKey(KOREA_STATE_MAP.get(stateCode)))) {
                    result.stateCode = stateCodes.get(KOREA_STATE_MAP.get(stateCode));
                }
            }
        }
    }

    /**
     * @description 레코드 ID와 필드명을 받아 주소 정보를 동적으로 조회
     * @param recordId 대상 레코드 ID
     * @param addressField 주소 필드 API Name (Address__c Custom Field로 지정)
     * @return Map<String, Object> (street, city, latitude, longitude 등)
     */
    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> getAddressInfo(Id recordId, String addressField) {
        Map<String, Object> result = new Map<String, Object>();

        if (recordId == null || String.isBlank(addressField)) return result;

        try {
            String sObjName = COM_MetaUtil.getObjectNameById(recordId);

            if (!COM_MetaUtil.existsField(sObjName, addressField)) {
                result.put('error', 'TARGET_FIELD_NOT_FOUND');
                return result;
            }

            Map<String, SObjectField> fieldMap = Schema.getGlobalDescribe().get(sObjName).getDescribe().fields.getMap();
            // Address 타입 체크
            Schema.DisplayType fieldType = fieldMap.get(addressField).getDescribe().getType();
            if (fieldType != Schema.DisplayType.ADDRESS) {
                result.put('error', 'INVALID_FIELD_TYPE');
                return result;
            }

            Boolean isActiveKr = false;
            if('Account'.equalsIgnoreCase(sObjName)) {
                isActiveKr = [SELECT COUNT() FROM Account WHERE Id = :recordId AND Country__c = 'KR' LIMIT 1] > 0;
            }

            Boolean hasAddressKOField = (COM_MetaUtil.existsField(sObjName, 'AddressKO__c') && fieldMap.get('AddressKO__c').getDescribe().getType()==Schema.DisplayType.ADDRESS);

            List<COM_Option> searchOption = new List<COM_Option>();
            searchOption.add(new COM_Option(Label.COM_LBL_ADDRESS_SEARCH,'ADDRESS'));
            searchOption.add(new COM_Option(Label.COM_LBL_COORDINATE_SEARCH,'COORDINATES'));

            //GPSCoordinates__c 필드 존재 여부 체크
            result.put('hasGPSField', COM_MetaUtil.existsField(sObjName, 'GPSCoordinates__c'));
            result.put('hasStateField', COM_MetaUtil.existsField(sObjName, 'State__c'));
            result.put('hasAddressKOField', hasAddressKOField);
            result.put('isKrSearchDefault', (isActiveKr && hasAddressKOField));

            // Custom Address Field의 구성요소 필드명 생성
            String streetField = addressField.replace('__c', '__Street__s');
            String cityField = addressField.replace('__c', '__City__s');
            String postalField = addressField.replace('__c', '__PostalCode__s');
            String countryField = addressField.replace('__c', '__CountryCode__s');
            String stateField = addressField.replace('__c', '__StateCode__s');
            String latField = addressField.replace('__c', '__Latitude__s');
            String lngField = addressField.replace('__c', '__Longitude__s');

            List<String> selectFields = new List<String>{
                    streetField,
                    cityField,
                    postalField,
                    countryField,
                    stateField,
                    latField,
                    lngField
            };

            String query = String.format(
                    'SELECT {0} FROM {1} WHERE Id = :recordId WITH SECURITY_ENFORCED',
                    new List<String>{
                            String.join(selectFields, ','),
                            String.escapeSingleQuotes(sObjName)
                    }
            );
            SObject obj = Database.query(query);

            result.put('street', obj.get(streetField));
            result.put('city', obj.get(cityField));
            result.put('postalCode', obj.get(postalField));
            result.put('countryCode', obj.get(countryField));
            result.put('stateCode', obj.get(stateField));
            result.put('latitude', obj.get(latField));
            result.put('longitude', obj.get(lngField));
            result.put('searchModeOptions', searchOption);

        } catch (Exception e) {
            System.debug('Error querying address info: ' + e.getMessage());
            result.put('error', 'EXCEPTION');
        }

        return result;
    }


}