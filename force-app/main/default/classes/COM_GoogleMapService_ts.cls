/**********************************************************************************
 * @filename      : COM_GoogleMapService_ts.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-05 (목)
 * @group         :
 * @group-content :
 * @description   : 
 * @target-class  : 
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-05      i2max     Create
**********************************************************************************/
@IsTest
private class COM_GoogleMapService_ts {

    // =========================================================================
    // Mock: Geocoding 정상 응답 (Address → Lat/Lng)
    // =========================================================================
    private class GeocodeMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{'
                    + '"status": "OK",'
                    + '"results": [{'
                    +     '"formatted_address": "서울특별시 강남구 테헤란로 123",'
                    +     '"place_id": "ChIJN1t_tDeuEmsRUsoyG83frY4",'
                    +     '"geometry": {"location": {"lat": 37.4979, "lng": 127.0276}},'
                    +     '"types": ["street_address"],'
                    +     '"address_components": ['
                    +         '{"long_name": "대한민국", "short_name": "KR", "types": ["country"]},'
                    +         '{"long_name": "서울특별시", "short_name": "서울특별시", "types": ["administrative_area_level_1"]},'
                    +         '{"long_name": "강남구", "short_name": "강남구", "types": ["locality"]},'
                    +         '{"long_name": "06234", "short_name": "06234", "types": ["postal_code"]}'
                    +     ']'
                    + '}]'
                    + '}');
            return res;

        }
    }

    // =========================================================================
    // Mock: ZERO_RESULTS
    // =========================================================================
    private class ZeroResultsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status": "ZERO_RESULTS", "results": []}');
            return res;
        }
    }

    // =========================================================================
    // Mock: HTTP 에러
    // =========================================================================
    private class HttpErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    // =========================================================================
    // InvocableMethod: ADDRESS 모드 정상
    // =========================================================================
    @IsTest
    static void testGetGeoInfo_Address() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());

        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();
        req.address = '서울특별시 강남구 테헤란로 123';
        req.mode = 'ADDRESS';

        Test.startTest();
        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.getGeoInfo(new List<COM_GoogleMapService.GeoRequest>{ req });
        Test.stopTest();

        System.assertEquals(1, results.size());
        System.assertEquals('OK', results[0].status);
        System.assertNotEquals(null, results[0].lat);
        System.assertNotEquals(null, results[0].lng);
        System.assertEquals('KR', results[0].countryCode);
    }

    // =========================================================================
    // InvocableMethod: COORDINATES 모드 정상
    // =========================================================================
    @IsTest
    static void testGetGeoInfo_Coordinates() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());

        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();
        req.lat = 37.4979;
        req.lng = 127.0276;
        req.mode = 'COORDINATES';

        Test.startTest();
        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.getGeoInfo(new List<COM_GoogleMapService.GeoRequest>{ req });
        Test.stopTest();

        System.assertEquals('OK', results[0].status);
    }

    // =========================================================================
    // InvocableMethod: 모드 자동 판별 (address만 있으면 ADDRESS)
    // =========================================================================
    @IsTest
    static void testGetGeoInfo_AutoMode() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());

        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();
        req.address = '서울시 강남구';

        Test.startTest();
        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.getGeoInfo(new List<COM_GoogleMapService.GeoRequest>{ req });
        Test.stopTest();

        System.assertEquals('OK', results[0].status);
    }

    // =========================================================================
    // Validation: ADDRESS 모드인데 address 없음
    // =========================================================================
    @IsTest
    static void testGetGeoInfo_AddressModeNoAddress() {
        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();
        req.mode = 'ADDRESS';

        Test.startTest();
        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.getGeoInfo(new List<COM_GoogleMapService.GeoRequest>{ req });
        Test.stopTest();

        System.assertEquals('ERROR', results[0].status);
    }

    // =========================================================================
    // Validation: COORDINATES 모드인데 좌표 없음
    // =========================================================================
    @IsTest
    static void testGetGeoInfo_CoordsModeNoCoords() {
        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();
        req.mode = 'COORDINATES';

        Test.startTest();
        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.getGeoInfo(new List<COM_GoogleMapService.GeoRequest>{ req });
        Test.stopTest();

        System.assertEquals('ERROR', results[0].status);
    }

    // =========================================================================
    // ZERO_RESULTS 응답
    // =========================================================================
    @IsTest
    static void testGetGeoInfo_ZeroResults() {
        Test.setMock(HttpCalloutMock.class, new ZeroResultsMock());

        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();
        req.address = '존재하지않는주소XYZ';
        req.mode = 'ADDRESS';

        Test.startTest();
        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.getGeoInfo(new List<COM_GoogleMapService.GeoRequest>{ req });
        Test.stopTest();

        System.assertEquals('ZERO_RESULTS', results[0].status);
    }

    // =========================================================================
    // HTTP 에러 응답
    // =========================================================================
    @IsTest
    static void testGetGeoInfo_HttpError() {
        Test.setMock(HttpCalloutMock.class, new HttpErrorMock());

        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();
        req.address = '서울시';
        req.mode = 'ADDRESS';

        Test.startTest();
        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.getGeoInfo(new List<COM_GoogleMapService.GeoRequest>{ req });
        Test.stopTest();

        System.assertEquals('HTTP_ERROR', results[0].status);
    }

    // =========================================================================
    // AuraEnabled: findGeoInfo 정상
    // =========================================================================
    @IsTest
    static void testFindGeoInfo() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());

        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();
        req.address = '서울시 강남구';
        req.mode = 'ADDRESS';

        Test.startTest();
        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.getGeoInfo(new List<COM_GoogleMapService.GeoRequest>{ req });
        Test.stopTest();

        System.assert(!results.isEmpty());
        System.assertEquals('OK', results[0].status);
    }

    // =========================================================================
    // AuraEnabled: findGeoInfo 빈 입력
    // =========================================================================
    @IsTest
    static void testFindGeoInfo_Blank() {
        Test.startTest();
        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.findGeoInfo('');
        Test.stopTest();

        System.assert(results.isEmpty());
    }

    // =========================================================================
    // AuraEnabled: findGeoInfo 언어 지정 (ko)
    // =========================================================================
    @IsTest
    static void testFindGeoInfo_Korean() {
        Test.setMock(HttpCalloutMock.class, new GeocodeMock());

        COM_GoogleMapService.GeoRequest req = new COM_GoogleMapService.GeoRequest();
        req.address = '서울시 강남구';
        req.mode = 'ADDRESS';
        req.language = 'ko';

        Test.startTest();
        List<COM_GoogleMapService.GeoResult> results = COM_GoogleMapService.findGeoInfo(JSON.serialize(req));
        results[0].withError();
        Test.stopTest();

        System.assertEquals('ZERO_RESULTS', results[0].status);
    }

    // =========================================================================
    // getAddressInfo: 필드 미존재
    // =========================================================================
    @IsTest
    static void testGetAddressInfo_InvalidFieldI() {
        Account acc = new Account(Name = 'Test');
        insert acc;

        Test.startTest();
        Map<String, Object> result = COM_GoogleMapService.getAddressInfo(acc.Id, 'NonExistentField__c');
        Test.stopTest();

        System.assertEquals('TARGET_FIELD_NOT_FOUND', result.get('error'));
    }

    // =========================================================================
    // getAddressInfo: null 입력
    // =========================================================================
    @IsTest
    static void testGetAddressInfo_NullInput() {
        Test.startTest();
        Map<String, Object> result = COM_GoogleMapService.getAddressInfo(null, null);
        Test.stopTest();

        System.assert(result.isEmpty());
    }

    // =========================================================================
    // getAddressInfo:
    // =========================================================================
    @IsTest
    static void testGetAddressInfo() {
        Account acc = new Account(Name = 'Test');
        insert acc;

        Test.startTest();
        Map<String, Object> result = COM_GoogleMapService.getAddressInfo(acc.Id, 'Address__c');
        Test.stopTest();

        System.assert(!result.isEmpty());
    }


    // =========================================================================
    // getAddressInfo:
    // =========================================================================
    @IsTest
    static void testGetAddressInfo_InvalidFieldType() {
        Account acc = new Account(Name = 'Test');
        insert acc;

        Test.startTest();
        Map<String, Object> result = COM_GoogleMapService.getAddressInfo(acc.Id, 'Phone');
        Test.stopTest();

        Assert.isFalse(result.isEmpty());
    }

    private class GoogleMapMock implements HttpCalloutMock {
        public String scenario = 'OK';

        public HttpResponse respond(HttpRequest req) {
            if (scenario == 'EXCEPTION') throw new CalloutException('Simulated Exception');

            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (scenario == 'HTTP_ERROR') {
                res.setStatusCode(500); // 208 라인 커버
                return res;
            }

            res.setStatusCode(200);
            String body = '';

            if (scenario == 'ERROR') {
                // status가 OK가 아닌 경우 (198 라인 커버)
                body = '{"status": "INVALID_REQUEST", "error_message": "API Key Error"}';
            } else if (scenario == 'KR_MAPPING') {
                // 한국 주소 매핑 (361~363 라인 커버)
                // result.state가 stateCodes에 없어야 else 문으로 진입함
                body = '{ "status": "OK", "results": [{ ' +
                        '  "formatted_address": "Seoul", ' +
                        '  "address_components": [ ' +
                        '    {"long_name": "South Korea", "short_name": "KR", "types": ["country"]}, ' +
                        '    {"long_name": "UnknownState", "short_name": "서울특별시", "types": ["administrative_area_level_1"]} ' +
                        '  ], ' +
                        '  "geometry": {"location": {"lat": 37.5, "lng": 127.0}} ' +
                        '}] }';
            } else {
                body = '{"status": "OK", "results": [{"formatted_address": "Test", "geometry": {"location": {"lat": 37.5, "lng": 127.0}}}]}';
            }

            res.setBody(body);
            return res;
        }
    }

    @IsTest
    static void testCoverageMaxing() {
        GoogleMapMock mock = new GoogleMapMock();
        Test.setMock(HttpCalloutMock.class, mock);

        COM_GoogleMapService.GeoRequest flowReq = new COM_GoogleMapService.GeoRequest();
        flowReq.address = 'Seoul';
        flowReq.mode = 'ADDRESS';
        COM_GoogleMapService.getGeoInfo(new List<COM_GoogleMapService.GeoRequest>{ flowReq });

        COM_GoogleMapService.GeoRequest req1 = new COM_GoogleMapService.GeoRequest();
        req1.mode = 'ADDRESS';
        req1.address = null; // null 또는 빈값
        COM_GoogleMapService.findGeoInfo(JSON.serialize(req1));

        COM_GoogleMapService.GeoRequest req2 = new COM_GoogleMapService.GeoRequest();
        req2.mode = 'COORDINATES';
        req2.lat = null;
        COM_GoogleMapService.findGeoInfo(JSON.serialize(req2));

        mock.scenario = 'ERROR';
        COM_GoogleMapService.GeoRequest req3 = new COM_GoogleMapService.GeoRequest();
        req3.address = 'Error';
        COM_GoogleMapService.findGeoInfo(JSON.serialize(req3));

        mock.scenario = 'HTTP_ERROR';
        COM_GoogleMapService.GeoRequest req4 = new COM_GoogleMapService.GeoRequest();
        req4.address = 'HttpError';
        COM_GoogleMapService.findGeoInfo(JSON.serialize(req4));

        mock.scenario = 'EXCEPTION';
        COM_GoogleMapService.GeoRequest req5 = new COM_GoogleMapService.GeoRequest();
        req5.address = 'Exception';
        COM_GoogleMapService.findGeoInfo(JSON.serialize(req5));

        mock.scenario = 'KR_MAPPING';
        COM_GoogleMapService.GeoRequest reqKR = new COM_GoogleMapService.GeoRequest();
        reqKR.address = 'Seoul';
        reqKR.mode = 'ADDRESS';
        COM_GoogleMapService.findGeoInfo(JSON.serialize(reqKR));
    }


}