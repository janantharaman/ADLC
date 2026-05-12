global with sharing class RQCountryMappingRemoteAction implements Callable {
    public Object call(String action, Map<String, Object> args) {
        Map<String, Object> input = (Map<String, Object>) args.get('input');
        Map<String, Object> output = (Map<String, Object>) args.get('output');
        Map<String, Object> options = (Map<String, Object>) args.get('options');

        return invokeMethod(action, input, output, options);
    }

    global Boolean invokeMethod(String methodName, Map<String, Object> input, Map<String, Object> output, Map<String, Object> options) {
        try {
            if (methodName == 'mapCountryCodes') {
                output.put('result', mapCountryCodes(input));
                return true;
            }

            output.put('error', 'Unsupported method: ' + methodName);
            return false;
        } catch (Exception e) {
            output.put('error', e.getMessage());
            return false;
        }
    }

    private Map<String, Object> mapCountryCodes(Map<String, Object> inputData) {
        Map<String, Object> result = new Map<String, Object>();
        result.putAll(inputData);

        Map<String, Country_Mapping__mdt> metaMap = Country_Mapping__mdt.getAll();

        replaceField(result, 'Terrutorial', metaMap);
        replaceField(result, 'COL1', metaMap);
        replaceField(result, 'COL2', metaMap);

        return result;
    }

    private void replaceField(Map<String, Object> target, String fieldName, Map<String, Country_Mapping__mdt> metaMap) {
        if (target == null || !target.containsKey(fieldName)) {
            return;
        }

        Object rawValue = target.get(fieldName);
        if (rawValue == null) {
            return;
        }

        String codeValue = String.valueOf(rawValue).trim();

        if (String.isBlank(codeValue) || codeValue == 'No data.') {
            return;
        }

        // KR_US 같이 오면 앞에 것만 변환
        if (codeValue.contains('_')) {
            List<String> parts = codeValue.split('_');
            if (!parts.isEmpty()) {
                String firstCode = parts[0] != null ? parts[0].trim() : '';
                Country_Mapping__mdt rec = metaMap.get(firstCode);

                if (rec != null && String.isNotBlank(rec.LabelName__c)) {
                    parts[0] = rec.LabelName__c;
                    target.put(fieldName, String.join(parts, '_'));
                }
            }
            return;
        }

        // 단일 코드 처리
        Country_Mapping__mdt rec = metaMap.get(codeValue);

        if (rec != null && String.isNotBlank(rec.LabelName__c)) {
            target.put(fieldName, rec.LabelName__c);
        }
    }
}