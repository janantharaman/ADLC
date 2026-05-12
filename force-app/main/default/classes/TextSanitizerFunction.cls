global class TextSanitizerFunction implements Callable {
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');
        return invokeMethod(action, input, output, options);
    }

    global Boolean invokeMethod(
        String methodName,
        Map<String, Object> inputs,
        Map<String, Object> output,
        Map<String, Object> options
    ) {
        List<Object> arguments = (inputs == null) ? null : (List<Object>) inputs.get('arguments');
        String raw = (arguments != null &&
            !arguments.isEmpty() &&
            arguments[0] != null)
            ? String.valueOf(arguments[0])
            : null;

        if (methodName == 'sanitize') {
            String cleaned = sanitizeForDocGen(raw);
            output.put('result', cleaned);
            System.debug(LoggingLevel.WARN, '[TextSanitizerFunction] output.result=' + cleaned);
            return true;
        }

        if (methodName == 'sanitizeAndEncode') {
            String cleaned = sanitizeForDocGen(raw);
            String encoded = encodeBase64Unicode(cleaned);
            output.put('result', encoded);
            System.debug(LoggingLevel.WARN, '[TextSanitizerFunction] sanitizeAndEncode completed');
            return true;
        }

        output.put('result', null);
        System.debug(LoggingLevel.WARN, '[TextSanitizerFunction] output.result=null (unsupported method)');
        return true;
    }

    /**
     * "이상한 문자" 제거(한글 유지)
     * - 제어문자 제거(탭/개행/CR 포함)
     * - BOM 제거
     * - Surrogate(깨진 이모지/깨진 유니코드 조각) 제거
     * - 동그라미 숫자(① 등) 제거
     */
    private static String sanitizeForDocGen(String s) {
        if (s == null)
            return null;

        // 제어문자 제거 (탭, 개행, 캐리지리턴 포함)
        s = s.replaceAll('[\\u0000-\\u001F\\u007F]', '');

        // BOM 제거
        s = s.replaceAll('\\uFEFF', '');

        // Surrogate 영역 제거 (깨진 이모지/깨진 유니코드 방지)
        s = s.replaceAll('[\\uD800-\\uDFFF]', '');

        // 동그라미 숫자/괄호숫자류 제거 (① 같은 것)
        s = s.replaceAll('[\\u2460-\\u24FF\\u2776-\\u2793]', '');

        return s;
    }

    /**
     * UTF-8 기반 Base64 인코딩 (한글 지원)
     * JavaScript의 btoa() 에러 방지용
     */
    private static String encodeBase64Unicode(String s) {
        if (s == null)
            return null;

        Blob blobData = Blob.valueOf(s);
        return EncodingUtil.base64Encode(blobData);
    }
}