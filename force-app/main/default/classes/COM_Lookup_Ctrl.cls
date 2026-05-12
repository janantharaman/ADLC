/**********************************************************************************
 * @filename      : COM_Lookup_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-05 (월)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : COM_Lookup_Ctrl_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-05      i2max     Create
**********************************************************************************/
public with sharing class COM_Lookup_Ctrl {

    private static final Integer DEFAULT_LIMIT = 50;
    private static final Integer MAX_LIMIT     = 200;
    private static final String  DEFAULT_GROUP_KEY = 'base';

    public class Filter {
        @AuraEnabled public String field    { get; set; }
        @AuraEnabled public String op       { get; set; }
        @AuraEnabled public Object value    { get; set; }
        @AuraEnabled public List<Object> values { get; set; }
        @AuraEnabled public String type     { get; set; }
        @AuraEnabled public String groupKey { get; set; }
    }

    @AuraEnabled(Cacheable=true)
    public static List<COM_Option> getOptionsByIds(String objectApiName, String labelField, List<Id> ids) {
        if (ids == null || ids.isEmpty()) return new List<COM_Option>();
        if (String.isBlank(objectApiName)) throw new AuraHandledException('objectApiName is required.');
        if (String.isBlank(labelField))    throw new AuraHandledException('labelField is required.');

        Map<String, Schema.SObjectType> objectTypeMap = Schema.getGlobalDescribe();
        if (!objectTypeMap.containsKey(objectApiName)) throw new AuraHandledException('Invalid object: ' + objectApiName);

        Schema.DescribeSObjectResult dso = objectTypeMap.get(objectApiName).getDescribe();
        if (!dso.isAccessible()) throw new AuraHandledException('No access to object: ' + objectApiName);

        Map<String, Schema.SObjectField> fieldMap = dso.fields.getMap();
        if (!fieldMap.containsKey(labelField)) throw new AuraHandledException('Invalid labelField: ' + labelField);
        if (!fieldMap.get(labelField).getDescribe().isAccessible()) {
            throw new AuraHandledException('No access to field: ' + labelField);
        }

        Map<Id, String> labels = new Map<Id, String>();

        Integer i = 0;
        while (i < ids.size()) {
            Integer endCnt = Math.min(i + 1000, ids.size());
            List<Id> chunk = new List<Id>();
            for (Integer k = i; k < endCnt; k++) chunk.add(ids[k]);
            i = endCnt;

            String soql = 'SELECT Id,' + labelField + ' FROM ' + objectApiName + ' WHERE Id IN :chunk';
            List<SObject> rows = Database.queryWithBinds(
                    soql,
                    new Map<String, Object>{ 'chunk' => chunk },
                    AccessLevel.USER_MODE
            );

            for (SObject s : rows) {
                labels.put((Id)s.get('Id'), String.valueOf(s.get(labelField)));
            }
        }

        List<COM_Option> options = new List<COM_Option>();
        for (Id idv : ids) {
            if (labels.containsKey(idv)) options.add(new COM_Option(labels.get(idv), String.valueOf(idv)));
        }
        return options;
    }

    public static List<COM_Option> search(
            String objectApiName,
            String labelField,
            String keyword,
            Integer limitSize,
            List<Filter> filters,
            Integer minKeywordLen,
            String orderByField,
            String orderDir,
            String afterLabel,
            Id afterId,
            List<String> recordTypeDeveloperNames
    ) {
        return search(objectApiName, labelField, '', keyword, limitSize, filters, minKeywordLen, orderByField, orderDir, afterLabel, afterId, recordTypeDeveloperNames);
    }
    /**
     * @description 검색
     * @param objectApiName
     * @param labelField
     * @param subLabelField
     * @param keyword
     * @param limitSize
     * @param filters
     * @param minKeywordLen
     * @param orderByField
     * @param orderDir
     * @param afterLabel
     * @param afterId
     * @param recordTypeDeveloperNames
     *
     * @return List<COM_Option>
     */
    @AuraEnabled(Cacheable=true)
    public static List<COM_Option> search(
            String objectApiName,
            String labelField,
            String subLabelField,
            String keyword,
            Integer limitSize,
            List<Filter> filters,
            Integer minKeywordLen,
            String orderByField,
            String orderDir,
            String afterLabel,
            Id afterId,
            List<String> recordTypeDeveloperNames
    ) {
        System.debug(LoggingLevel.DEBUG, 'search ### objectApiName=' + objectApiName);
        System.debug(LoggingLevel.DEBUG, 'search ### labelField=' + labelField);
        System.debug(LoggingLevel.DEBUG, 'search ### keyword=' + keyword);
        System.debug(LoggingLevel.DEBUG, 'search ### filters=' + filters);

        if (String.isBlank(objectApiName)) throw new AuraHandledException('objectApiName is required.');
        if (String.isBlank(labelField))    throw new AuraHandledException('labelField is required.');

        Map<String, Schema.SObjectType> sObjectTypes = Schema.getGlobalDescribe();
        if (!sObjectTypes.containsKey(objectApiName)) throw new AuraHandledException('Invalid object: ' + objectApiName);

        Schema.DescribeSObjectResult dso = sObjectTypes.get(objectApiName).getDescribe();
        if (!dso.isAccessible()) throw new AuraHandledException('No access to object: ' + objectApiName);

        Map<String, Schema.SObjectField> fieldMap = dso.fields.getMap();
        if (!fieldMap.containsKey(labelField)) throw new AuraHandledException('Invalid labelField: ' + labelField);
        if (!fieldMap.get(labelField).getDescribe().isAccessible()) {
            throw new AuraHandledException('No access to field: ' + labelField);
        }

        Integer rowLimit = (limitSize == null || limitSize <= 0) ? DEFAULT_LIMIT : Math.min(limitSize, MAX_LIMIT);
        Integer minLen   = (minKeywordLen == null || minKeywordLen < 1) ? 2 : minKeywordLen;

        keyword = (keyword == null) ? '' : keyword.trim();
        if (keyword.length() < minLen) return new List<COM_Option>(); // UI와 일관되게: 최소 길이 미만이면 검색 안함

        String obField = String.isBlank(orderByField) ? labelField : orderByField;
        if (!fieldMap.containsKey(obField)) throw new AuraHandledException('Invalid orderByField: ' + obField);
        if (!fieldMap.get(obField).getDescribe().isAccessible()) {
            throw new AuraHandledException('No access to orderByField: ' + obField);
        }

        String dir = (orderDir == 'DESC') ? 'DESC' : 'ASC';
        String cmp = (dir == 'ASC') ? '>' : '<';

        List<String> whereClauses = new List<String>();
        Map<String, Object> bindMap = new Map<String, Object>();

        // 키워드 LIKE (ESCAPE 적용)
        String escaped = escapeLike(keyword.trim());
        whereClauses.add(labelField + ' LIKE :kw');
        bindMap.put('kw', '%' + escaped + '%');

        // RecordType 편의 필터
        if (recordTypeDeveloperNames != null && !recordTypeDeveloperNames.isEmpty() && fieldMap.containsKey('RecordTypeId')) {
            whereClauses.add('RecordType.DeveloperName IN :rtNames');
            bindMap.put('rtNames', recordTypeDeveloperNames);
        }

        // 필터 그룹: (AND...) OR (AND...)
        if (filters != null && !filters.isEmpty()) {
            Map<String, List<Filter>> groups = new Map<String, List<Filter>>();
            for (Filter filter : filters) {
                String gkey = String.isBlank(filter.groupKey) ? DEFAULT_GROUP_KEY : filter.groupKey;
                if (!groups.containsKey(gkey)) groups.put(gkey, new List<Filter>());
                groups.get(gkey).add(filter);
            }

            List<String> ors = new List<String>();
            for (String gkey : groups.keySet()) {
                List<String> ands = new List<String>();
                for (Filter filter : groups.get(gkey)) {
                    if (String.isBlank(filter.field) || !fieldMap.containsKey(filter.field)) {
                        System.debug(LoggingLevel.DEBUG, 'search ### fieldMap.containsKey('+filter.field+')=[' + fieldMap.containsKey(filter.field) +']');
                        throw new AuraHandledException('Invalid field in filter: ' + filter.field);
                    }
                    Schema.DescribeFieldResult fdr = fieldMap.get(filter.field).getDescribe();
                    if (!fdr.isAccessible()) {
                        throw new AuraHandledException('No access to filter field: ' + filter.field);
                    }
                    buildCondition(ands, bindMap, filter, fdr.getType());
                }
                if (!ands.isEmpty()) ors.add('(' + String.join(ands, ' AND ') + ')');
            }
            if (!ors.isEmpty()) whereClauses.add('(' + String.join(ors, ' OR ') + ')');
        }

        if (!String.isBlank(afterLabel) && afterId != null) {
            whereClauses.add(
                    '((' + obField + ' ' + cmp + ' :afterLabel) OR (' + obField + ' = :afterLabel AND Id ' + cmp + ' :afterId))'
            );
            bindMap.put('afterLabel', afterLabel);
            bindMap.put('afterId', afterId);
        }

        List<String> parts = new List<String>();

        String subSelect = '';
        if (String.isNotBlank(subLabelField)) {
            if (!fieldMap.containsKey(subLabelField)) throw new AuraHandledException('Invalid subLabelField: ' + subLabelField);
            if (!fieldMap.get(subLabelField).getDescribe().isAccessible()) {
                throw new AuraHandledException('No access to field: ' + subLabelField);
            }
//            Schema.DisplayType ft = fieldMap.get(subLabelField).getDescribe().getType();
//            Boolean isPicklist = (ft == Schema.DisplayType.PICKLIST || ft == Schema.DisplayType.MULTIPICKLIST);
//            subSelect = isPicklist ? 'toLabel(' + subLabelField + ')' : subLabelField;
            subSelect = subLabelField;
        }

        parts.add('SELECT Id, ' + labelField + (String.isNotBlank(subSelect) ? ', ' + subSelect : ''));
        parts.add('FROM ' + objectApiName);
        parts.add('WHERE ' + String.join(whereClauses, ' AND '));
        parts.add('ORDER BY ' + obField + ' ' + dir + ', Id ' + dir);
        parts.add('LIMIT :rowLimit');
        bindMap.put('rowLimit', rowLimit);

        System.debug(LoggingLevel.ERROR, 'SOQL=' + String.join(parts, ' '));
        System.debug(LoggingLevel.ERROR, 'BINDS=' + JSON.serialize(bindMap));

        List<SObject> rows = Database.queryWithBinds(String.join(parts, ' '), bindMap, AccessLevel.USER_MODE);

        List<COM_Option> options = new List<COM_Option>();
        for (SObject s : rows) {
            String sub = String.isNotBlank(subLabelField) ? String.valueOf(s.get(subLabelField)) : null;
            options.add(new COM_Option(String.valueOf(s.get(labelField)), (String)s.get('Id'), sub));
        }
        System.debug(LoggingLevel.DEBUG, 'options=' + options);
        return options;
    }

    /**
     * @description 조건빌더
     * @param ands
     * @param bindMap
     * @param filter
     * @param fieldType
     */
    private static void buildCondition(
            List<String> ands,
            Map<String, Object> bindMap,
            Filter filter,
            Schema.DisplayType fieldType
    ) {
        String op = (filter.op == null) ? 'EQ' : filter.op.trim().toUpperCase();

        if ((op == 'EQ' || op == 'NE')
                && filter.value == null
                && (filter.values == null || filter.values.isEmpty())) {
            return;
        }

        if (op == 'IS_NULL' || op == 'IS_NOT_NULL') {
            ands.add(filter.field + (op == 'IS_NULL' ? ' = null' : ' != null'));
            return;
        }

        if (op == 'IN' || op == 'NOT_IN') {
            List<Object> rawValues = (filter.values == null) ? new List<Object>() : new List<Object>(filter.values);
            if (rawValues.isEmpty()) return;

            if (rawValues.size() > 1000) {
                List<Object> trimmed = new List<Object>();
                for (Integer i = 0; i < 1000; i++) trimmed.add(rawValues[i]);
                rawValues = trimmed;
            }

            String bindKey = 'in' + bindMap.size();
            ands.add(filter.field + (op == 'IN' ? ' IN ' : ' NOT IN ') + ':' + bindKey);
            bindMap.put(bindKey, convertListToFieldType(rawValues, filter.type, fieldType));
            return;
        }

        if (op == 'BETWEEN') {
            if (filter.values == null || filter.values.size() != 2) return;

            String k1 = 'b' + bindMap.size();
            String k2 = 'b' + (bindMap.size() + 1);

            ands.add(filter.field + ' >= :' + k1);
            ands.add(filter.field + ' <= :' + k2);

            bindMap.put(k1, convertToFieldType(filter.values[0], filter.type, fieldType));
            bindMap.put(k2, convertToFieldType(filter.values[1], filter.type, fieldType));
            return;
        }

        if (op == 'LIKE' || op == 'STARTS_WITH' || op == 'ENDS_WITH' || op == 'CONTAINS') {
            String pat = String.valueOf(filter.value == null ? '' : filter.value).trim();
            if (String.isBlank(pat)) return;

            String key = 'lk' + bindMap.size();
            pat = escapeLike(pat);

            if (op == 'STARTS_WITH')      pat = pat + '%';
            else if (op == 'ENDS_WITH')   pat = '%' + pat;
            else                          pat = '%' + pat + '%'; // LIKE / CONTAINS

            ands.add(filter.field + ' LIKE :' + key);
            bindMap.put(key, pat);
            return;
        }

        // Multi-Select Picklist: INCLUDES / EXCLUDES
        if (op == 'INCLUDES' || op == 'EXCLUDES') {
            List<Object> rawValues = new List<Object>();

            if (filter.values != null && !filter.values.isEmpty()) {
                rawValues.addAll(filter.values);
            } else if (filter.value != null) {
                rawValues.add(filter.value);
            } else {
                return;
            }

            List<String> strVals = new List<String>();
            for (Object rv : rawValues) {
                if (rv == null) continue;
                strVals.add(String.valueOf(rv));
            }
            if (strVals.isEmpty()) return;

            List<String> quoted = new List<String>();
            for (String s : strVals) quoted.add('\'' + String.escapeSingleQuotes(s) + '\'');

            ands.add(filter.field + ' ' + op + ' (' + String.join(quoted, ',') + ')');
            return;
        }

        String so;
        switch on op {
            when 'EQ' { so = '=';  }
            when 'NE' { so = '!='; }
            when 'GT' { so = '>';  }
            when 'GE' { so = '>='; }
            when 'LT' { so = '<';  }
            when 'LE' { so = '<='; }
            when else { so = '=';  }
        }

        String vk = 'v' + bindMap.size();
        ands.add(filter.field + ' ' + so + ' :' + vk);
        bindMap.put(vk, convertToFieldType(filter.value, filter.type, fieldType));
    }

    /**
     * @description 타입변환
     * @param raw
     * @param dataType
     * @param fieldType
     *
     * @return
     */
    private static Object convertToFieldType(Object raw, String dataType, Schema.DisplayType fieldType) {
        if (raw == null) return null;
        dataType = (dataType == null) ? '' : dataType.toUpperCase();

        if (dataType == 'STRING' || dataType == 'PICKLIST' || dataType == 'ID') return String.valueOf(raw);
        if (dataType == 'NUMBER')   return (raw instanceof Decimal)  ? (Decimal)raw  : Decimal.valueOf(String.valueOf(raw));
        if (dataType == 'BOOLEAN')  return (raw instanceof Boolean)  ? (Boolean)raw  : Boolean.valueOf(String.valueOf(raw));
        if (dataType == 'DATE')     return (raw instanceof Date)     ? (Date)raw     : Date.valueOf(String.valueOf(raw));
        if (dataType == 'DATETIME') return (raw instanceof Datetime) ? (Datetime)raw : Datetime.valueOf(String.valueOf(raw));

        switch on fieldType {
            when DATE      { return (raw instanceof Date)     ? (Date)raw     : Date.valueOf(String.valueOf(raw)); }
            when DATETIME  { return (raw instanceof Datetime) ? (Datetime)raw : Datetime.valueOf(String.valueOf(raw)); }
            when BOOLEAN   { return (raw instanceof Boolean)  ? (Boolean)raw  : Boolean.valueOf(String.valueOf(raw)); }
            when CURRENCY, DOUBLE, INTEGER, LONG {
                return (raw instanceof Decimal) ? (Decimal)raw : Decimal.valueOf(String.valueOf(raw));
            }
            when else      { return String.valueOf(raw); }
        }
    }

    private static List<Object> convertListToFieldType(List<Object> raws, String typeHint, Schema.DisplayType fieldType) {
        if (raws == null || raws.isEmpty()) return new List<Object>();
        Object first = convertToFieldType(raws[0], typeHint, fieldType);
        if (first instanceof String) {
            List<String> out = new List<String>();
            out.add((String) first);
            for (Integer i = 1; i < raws.size(); i++) out.add(String.valueOf(convertToFieldType(raws[i], typeHint, fieldType)));
            return out;
        } else if (first instanceof Decimal) {
            List<Decimal> out = new List<Decimal>();
            out.add((Decimal) first);
            for (Integer i = 1; i < raws.size(); i++) out.add((Decimal) convertToFieldType(raws[i], typeHint, fieldType));
            return out;
        } else if (first instanceof Date) {
            List<Date> out = new List<Date>();
            out.add((Date) first);
            for (Integer i = 1; i < raws.size(); i++) out.add((Date) convertToFieldType(raws[i], typeHint, fieldType));
            return out;
        } else if (first instanceof Datetime) {
            List<Datetime> out = new List<Datetime>();
            out.add((Datetime) first);
            for (Integer i = 1; i < raws.size(); i++) out.add((Datetime) convertToFieldType(raws[i], typeHint, fieldType));
            return out;
        } else if (first instanceof Boolean) {
            List<Boolean> out = new List<Boolean>();
            out.add((Boolean) first);
            for (Integer i = 1; i < raws.size(); i++) out.add((Boolean) convertToFieldType(raws[i], typeHint, fieldType));
            return out;
        }
        List<String> out = new List<String>();
        for (Object r : raws) out.add(String.valueOf(convertToFieldType(r, typeHint, fieldType)));
        return out;
    }

    private static String escapeLike(String input) {
        if (String.isBlank(input)) return input;
        String s = input.trim();
        s = s.replace('\\', '\\\\'); // \ 자체 이스케이프
        s = s.replace('%',  '\\%');  // % 리터럴
        s = s.replace('_',  '\\_');  // _ 리터럴
        return s;
    }



}