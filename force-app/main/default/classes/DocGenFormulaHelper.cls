/**********************************************************************************
 * @filename      : DocGenFormulaHelper.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-23 (월)
 * @group         :
 * @group-content :
 * @description   : OmniStudio 문서 생성용 커스텀 포뮬라 헬퍼 (Callable)
 *                  sumField·sanitize·sanitizeAndEncode·groupLayerPanelSubjectivity
 *                  action 지원
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-23      i2max            Create
 **********************************************************************************/
global class DocGenFormulaHelper implements Callable {
    private static final String LOG_PREFIX = '[DocGenFormulaHelper]';
    
    /**
     * @description Callable 인터페이스 진입점
     *              OmniStudio에서 action 이름과 함께 input/output/options 맵을 전달받아
     *              invokeMethod로 위임
     * @param action    호출할 메서드명
     * @param args      'input', 'output', 'options' 키를 포함하는 인자 맵
     * @return          invokeMethod 실행 결과
     */
    public Object call(String action, Map<String, Object> args) {
        System.debug(LOG_PREFIX + ' call() - action: ' + action);
        System.debug(LOG_PREFIX + ' call() - args: ' + args);
        
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        
        return invokeMethod(action, input, output, options);
    }
    
    /**
     * @description 메서드명에 따라 실제 로직을 분기 실행
     *              지원 메서드:
     *              - sumField
     *              - sanitize
     *              - sanitizeAndEncode
     *              - groupLayerPanelSubjectivity
     * @param methodName    실행할 메서드명
     * @param inputs        메서드 입력값 맵 (arguments 키로 파라미터 전달)
     * @param output        메서드 출력값 맵 (result 키로 결과 저장)
     * @param options       추가 옵션 맵 (현재 미사용)
     * @return              항상 true 반환
     */
    global Boolean invokeMethod(String methodName, Map<String, Object> inputs, Map<String, Object> output, Map<String, Object> options) {
        System.debug(LOG_PREFIX + ' invokeMethod() - methodName: ' + methodName);
        System.debug(LOG_PREFIX + ' invokeMethod() - inputs: ' + inputs);
        
        if (methodName == 'sumField') {
            List<Object> arguments = (List<Object>) inputs.get('arguments');
            Decimal result = sumField(arguments);
            output.put('result', result);
            System.debug(LOG_PREFIX + ' invokeMethod() - sumField result: ' + result);
            
        } else if (methodName == 'sanitize') {
            String raw = extractFirstArgument(inputs);
            String cleaned = sanitizeForDocGen(raw);
            output.put('result', cleaned);
            System.debug(LOG_PREFIX + ' invokeMethod() - sanitize result: ' + cleaned);
            
        } else if (methodName == 'sanitizeAndEncode') {
            String raw = extractFirstArgument(inputs);
            String encoded = encodeBase64Unicode(sanitizeForDocGen(raw));
            output.put('result', encoded);
            System.debug(LOG_PREFIX + ' invokeMethod() - sanitizeAndEncode completed');
            
        } else if (methodName == 'groupLayerPanelSubjectivity') {
            List<Object> arguments = (List<Object>) inputs.get('arguments');
            List<Object> result = groupLayerPanelSubjectivity(arguments);
            output.put('result', result);
            System.debug(LOG_PREFIX + ' invokeMethod() - groupLayerPanelSubjectivity result: ' + JSON.serialize(result));
            
        } else {
            System.debug(LOG_PREFIX + ' invokeMethod() - 지원하지 않는 methodName: ' + methodName);
        }
        
        return true;
    }
    
    /**
     * @description inputs 맵의 arguments[0]을 String으로 추출
     * @param inputs    메서드 입력값 맵
     * @return          첫 번째 인자의 String 값, 없으면 null
     */
    private static String extractFirstArgument(Map<String, Object> inputs) {
        if (inputs == null)
            return null;
        List<Object> arguments = (List<Object>) inputs.get('arguments');
        if (arguments == null || arguments.isEmpty() || arguments[0] == null)
            return null;
        return String.valueOf(arguments[0]);
    }
    
    /**
     * @description 리스트 항목의 특정 필드 값을 합산
     *              arguments[0]: 합산 대상 리스트 (또는 단일 맵)
     *              arguments[1]: 합산할 필드명 (String)
     * @param arguments OmniStudio에서 전달받은 인자 목록
     * @return          합산된 Decimal 값 (유효하지 않을 경우 0)
     */
    private Decimal sumField(List<Object> arguments) {
        System.debug(LOG_PREFIX + ' sumField() - arguments: ' + arguments);
        
        Decimal total = 0;
        
        if (arguments == null || arguments.size() < 2) {
            System.debug(LOG_PREFIX + ' sumField() - 인자 부족 또는 null, 0 반환');
            return total;
        }
        
        Object rawItems = arguments[0];
        String fieldName = String.valueOf(arguments[1]);
        System.debug(LOG_PREFIX + ' sumField() - fieldName: ' + fieldName + ', rawItems type: ' + (rawItems == null ? 'null' : String.valueOf(rawItems).left(200)));
        
        List<Object> items = normalizeToList(rawItems);
        System.debug(LOG_PREFIX + ' sumField() - 정규화된 items 수: ' + items.size());
        
        for (Object itemObj : items) {
            if (itemObj == null) {
                continue;
            }
            
            if (itemObj instanceof Map<String, Object>) {
                Map<String, Object> row = (Map<String, Object>) itemObj;
                Decimal fieldValue = toDecimalSafe(row.get(fieldName));
                System.debug(LOG_PREFIX + ' sumField() - row[' + fieldName + ']: ' + row.get(fieldName) + ' → ' + fieldValue);
                total += fieldValue;
            }
        }
        
        System.debug(LOG_PREFIX + ' sumField() - 최종 합산 결과: ' + total);
        return total;
    }
    
    /**
     * @description 다양한 타입의 입력값을 List<Object>로 정규화
     *              - null            → 빈 리스트
     *              - List<Object>    → 그대로 반환
     *              - Map with 'VLOCITY-FORMULA-LIST' 키 → 해당 리스트 추출
     *              - 단순 Map        → 단일 항목 리스트로 래핑
     * @param rawItems  정규화할 원본 데이터
     * @return          List<Object> 형태로 변환된 결과
     */
    private List<Object> normalizeToList(Object rawItems) {
        List<Object> result = new List<Object>();
        
        if (rawItems == null) {
            System.debug(LOG_PREFIX + ' normalizeToList() - rawItems is null, 빈 리스트 반환');
            return result;
        }
        
        if (rawItems instanceof List<Object>) {
            List<Object> asList = (List<Object>) rawItems;
            System.debug(LOG_PREFIX + ' normalizeToList() - List 타입 감지, size: ' + asList.size());
            return asList;
        }
        
        if (rawItems instanceof Map<String, Object>) {
            Map<String, Object> wrappedMap = (Map<String, Object>) rawItems;
            
            if (wrappedMap.containsKey('VLOCITY-FORMULA-LIST')) {
                Object listObj = wrappedMap.get('VLOCITY-FORMULA-LIST');
                System.debug(LOG_PREFIX + ' normalizeToList() - VLOCITY-FORMULA-LIST 키 감지');
                if (listObj instanceof List<Object>) {
                    List<Object> extracted = (List<Object>) listObj;
                    System.debug(LOG_PREFIX + ' normalizeToList() - VLOCITY-FORMULA-LIST 추출, size: ' + extracted.size());
                    return extracted;
                }
            }
            
            System.debug(LOG_PREFIX + ' normalizeToList() - 단순 Map을 리스트로 래핑');
            result.add(wrappedMap);
            return result;
        }
        
        System.debug(LOG_PREFIX + ' normalizeToList() - 지원하지 않는 타입, 빈 리스트 반환: ' + rawItems);
        return result;
    }
    
    /**
     * @description 임의의 Object를 Decimal로 안전하게 변환
     *              - null 또는 빈 문자열 → 0
     *              - Decimal 타입       → 캐스팅 반환
     *              - 문자열             → 콤마 제거 후 파싱 (실패 시 0)
     * @param rawValue  변환할 원본 값
     * @return          변환된 Decimal 값
     */
    private Decimal toDecimalSafe(Object rawValue) {
        if (rawValue == null) {
            System.debug(LOG_PREFIX + ' toDecimalSafe() - rawValue is null, 0 반환');
            return 0;
        }
        
        if (rawValue instanceof Decimal) {
            return (Decimal) rawValue;
        }
        
        String s = String.valueOf(rawValue);
        
        if (String.isBlank(s)) {
            System.debug(LOG_PREFIX + ' toDecimalSafe() - 빈 문자열, 0 반환');
            return 0;
        }
        
        s = s.replace(',', '').trim();
        
        try {
            return Decimal.valueOf(s);
        } catch (Exception e) {
            System.debug(LOG_PREFIX + ' toDecimalSafe() - 파싱 실패 [' + s + '], 0 반환. 에러: ' + e.getMessage());
            return 0;
        }
    }
    
    private static List<Object> groupLayerPanelSubjectivity(List<Object> rawLayers) {
        System.debug(LOG_PREFIX + ' groupLayerPanelSubjectivity() - rawLayers JSON: ' + JSON.serialize(rawLayers));
        
        List<Object> demoNode = new List<Object>();
        
        if (rawLayers == null || rawLayers.isEmpty()) {
            System.debug(LOG_PREFIX + ' groupLayerPanelSubjectivity() - rawLayers is empty');
            return demoNode;
        }
        
        for (Object layerObj : rawLayers) {
            if (!(layerObj instanceof Map<String, Object>)) {
                continue;
            }
            
            Map<String, Object> layerMap = (Map<String, Object>) layerObj;
            Object panelObj = layerMap.get('OPP_Panel');
            
            if (!(panelObj instanceof Map<String, Object>)) {
                continue;
            }
            
            Map<String, Object> panelMap = (Map<String, Object>) panelObj;
            Object rawSubjectivity = panelMap.get('OPP_Subjectivity');
            
            if (rawSubjectivity == null) {
                continue;
            }
            
            List<Object> subjectivityList = normalizeStaticToList(rawSubjectivity);
            if (subjectivityList.isEmpty()) {
                continue;
            }
            
            // Security 우선, 없으면 Reinsurer
            String reinsurerValue = null;
            if (panelMap.get('Security') != null && String.isNotBlank(String.valueOf(panelMap.get('Security')))) {
                reinsurerValue = String.valueOf(panelMap.get('Security'));
            } else if (panelMap.get('Reinsurer') != null) {
                reinsurerValue = String.valueOf(panelMap.get('Reinsurer'));
            }
            
            List<Object> additionList = new List<Object>();
            List<Object> amendmentList = new List<Object>();
            List<Object> cancellationList = new List<Object>();
            
            for (Object subObj : subjectivityList) {
                if (!(subObj instanceof Map<String, Object>)) {
                    continue;
                }
                
                Map<String, Object> subMap = (Map<String, Object>) subObj;
                String typeVal = subMap.get('Type') == null ? null : String.valueOf(subMap.get('Type'));
                
                if (typeVal == 'Addition') {
                    additionList.add(new Map<String, Object>{
                        'RTB_ADDDetail' => subMap.get('Detail')
                    });
                } else if (typeVal == 'Amendment') {
                    amendmentList.add(new Map<String, Object>{
                        'RTB_AMDDetail' => subMap.get('Detail')
                    });
                } else if (typeVal == 'Cancellation') {
                    cancellationList.add(new Map<String, Object>{
                        'RTB_CANDetail' => subMap.get('Detail')
                    });
                }
            }
            
            Map<String, Object> node = new Map<String, Object>{
                'Reinsurer' => reinsurerValue,
                'AdditionList' => additionList,
                'AmendmentList' => amendmentList,
                'CancellationList' => cancellationList,
                'IF_Add' => additionList.isEmpty() ? '' : 'true',
                'IF_Amend' => amendmentList.isEmpty() ? '' : 'true',
                'IF_Cancel' => cancellationList.isEmpty() ? '' : 'true'
            };
            
            demoNode.add(node);
        }
        
        System.debug(LOG_PREFIX + ' groupLayerPanelSubjectivity() - final demoNode size: ' + demoNode.size());
        return demoNode;
    }
    
    /**
     * @description static 컨텍스트에서 Object 값을 List<Object>로 정규화한다.
     *              - null                 → 빈 리스트
     *              - List<Object>         → 그대로 반환
     *              - Map<String,Object>   → 단일 항목 리스트로 래핑
     *              - VLOCITY-FORMULA-LIST → 내부 리스트 추출
     * @param  rawItems  정규화 대상
     * @return           정규화된 리스트
     */
    private static List<Object> normalizeStaticToList(Object rawItems) {
        List<Object> result = new List<Object>();
        
        if (rawItems == null) {
            return result;
        }
        
        if (rawItems instanceof List<Object>) {
            return (List<Object>) rawItems;
        }
        
        if (rawItems instanceof Map<String, Object>) {
            Map<String, Object> wrappedMap = (Map<String, Object>) rawItems;
            
            if (wrappedMap.containsKey('VLOCITY-FORMULA-LIST')) {
                Object listObj = wrappedMap.get('VLOCITY-FORMULA-LIST');
                if (listObj instanceof List<Object>) {
                    return (List<Object>) listObj;
                }
            }
            
            result.add(wrappedMap);
            return result;
        }
        
        return result;
    }
    
    /**
     * @description 문서 생성용 텍스트 정제
     *              - 제어문자 제거 (탭, 개행, 캐리지리턴 포함)
     *              - BOM 제거
     *              - Surrogate 영역 제거 (깨진 이모지/유니코드 방지)
     *              - 동그라미 숫자/괄호 숫자류 제거 (① 등)
     * @param s     정제할 원본 문자열
     * @return      정제된 문자열 (null 입력 시 null 반환)
     */
    private static String sanitizeForDocGen(String s) {
        if (s == null)
            return null;
        s = s.replaceAll('[\\u0000-\\u001F\\u007F]', '');
        s = s.replaceAll('\\uFEFF', '');
        s = s.replaceAll('[\\uD800-\\uDFFF]', '');
        s = s.replaceAll('[\\u2460-\\u24FF\\u2776-\\u2793]', '');
        return s;
    }
    
    /**
     * @description UTF-8 기반 Base64 인코딩 (한글 지원)
     *              JavaScript의 btoa() 에러 방지용
     * @param s     인코딩할 문자열
     * @return      Base64 인코딩된 문자열 (null 입력 시 null 반환)
     */
    private static String encodeBase64Unicode(String s) {
        if (s == null)
            return null;
        return EncodingUtil.base64Encode(Blob.valueOf(s));
    }
}