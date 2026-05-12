/**********************************************************************************
 * @filename      : COM_Util.cls
 * @projectname   : 
 * @author        : i2max
 * @date          : 2025-10-27 (월)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : COM_Util_ts.cls
 * @reference     : 
 * @copyright     : 
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-10-27      i2max            Create
**********************************************************************************/
public with sharing class COM_Util {

    /**
     * 숫자 문자열을 Decimal로 변환
     * - 공백·쉼표 제거 후 정규식으로 유효성 검사
     * - allowDecimal=false이면 정수만 허용
     * - 유효하지 않으면 null 반환
     *
     * @param s 입력 문자열 (예: "1,234.50", " -42 ")
     * @param allowDecimal 소수 허용 여부
     * @return Decimal 값 또는 null
     */
    public static Decimal toDec(String s, Boolean allowDecimal) {
        if (String.isBlank(s)) return null;
        String t = s.trim().replace(',', '').replace(' ', '');
        String re = allowDecimal ? '^[+-]?[0-9]+(\\.[0-9]+)?$' : '^[+-]?[0-9]+$';
        Matcher m = Pattern.compile(re).matcher(t);
        return m.matches() ? Decimal.valueOf(t) : null;
    }

    public static Integer toIntOrZero(String s) {
        if (String.isBlank(s)) return 0;
        if (String.isBlank(s)) return 0;
        String t = s.trim().replace(',', '').replace(' ', '');
        Matcher m = Pattern.compile('^[+-]?[0-9]+$').matcher(t);
        return m.matches() ? Integer.valueOf(t) : 0;
    }

    // ========== NVL: expr1이 null이면 expr2 반환 ==========
    public static String  nvl(String v, String defv)        { return v == null ? defv : v; }
    public static Integer nvl(Integer v, Integer defv)      { return v == null ? defv : v; }
    public static Long    nvl(Long v, Long defv)            { return v == null ? defv : v; }
    public static Decimal nvl(Decimal v, Decimal defv)      { return v == null ? defv : v; }
    public static Double  nvl(Double v, Double defv)        { return v == null ? defv : v; }
    public static Boolean nvl(Boolean v, Boolean defv)      { return v == null ? defv : v; }
    public static Date    nvl(Date v, Date defv)            { return v == null ? defv : v; }
    public static Datetime nvl(Datetime v, Datetime defv)   { return v == null ? defv : v; }
    public static Id      nvl(Id v, Id defv)                { return v == null ? defv : v; }
    public static Object  nvl(Object v, Object defv)        { return v == null ? defv : v; } // 범용

    public static Decimal NVL(Decimal val) {
        return val == null ? 0 : val;
    }

    // 빈 문자열도 기본값으로 치환하고 싶을 때
    public static String nvlBlank(String v, String defv)     { return String.isBlank(v) ? defv : v; }

    // ========== NVL2: expr1이 null이 아니면 expr2, 아니면 expr3 ==========
    public static String  nvl2(String v, String whenNotNull, String whenNull) {
        return v == null ? whenNull : whenNotNull;
    }
    public static Decimal nvl2(Decimal v, Decimal whenNotNull, Decimal whenNull) {
        return v == null ? whenNull : whenNotNull;
    }
    public static Integer nvl2(Integer v, Integer whenNotNull, Integer whenNull) {
        return v == null ? whenNull : whenNotNull;
    }
    public static Boolean nvl2(Boolean v, Boolean whenNotNull, Boolean whenNull) {
        return v == null ? whenNull : whenNotNull;
    }
    public static Date    nvl2(Date v, Date whenNotNull, Date whenNull) {
        return v == null ? whenNull : whenNotNull;
    }
    public static Datetime nvl2(Datetime v, Datetime whenNotNull, Datetime whenNull) {
        return v == null ? whenNull : whenNotNull;
    }
    public static Object  nvl2(Object v, Object whenNotNull, Object whenNull) {
        return v == null ? whenNull : whenNotNull;
    }

    // ========== COALESCE: 인자들 중 첫 번째 null이 아닌 값 반환 ==========
    public static String coalesce(String a, String b, String c) {
        if (a != null) return a; if (b != null) return b; return c;
    }
    public static Decimal coalesce(Decimal a, Decimal b, Decimal c) {
        if (a != null) return a; if (b != null) return b; return c;
    }
    public static Integer coalesce(Integer a, Integer b, Integer c) {
        if (a != null) return a; if (b != null) return b; return c;
    }
    // 가변 개수 처리가 필요하면 Object 리스트 버전 사용
    public static Object coalesce(List<Object> vals) {
        if (vals == null) return null;
        for (Object o : vals) if (o != null) return o;
        return null;
    }

    /**
     * @description Sandbox Name
     * @return String
     */
    public static String getOrgName() {
        return System.DomainParser.parse(Url.getOrgDomainUrl()).getSandboxName();
    }

    /**
     * @description Sandbox 여부 체크
     * @return Boolean
     */
    public static Boolean isSandbox() {
        return String.isNotBlank(System.DomainParser.parse(Url.getOrgDomainUrl()).getSandboxName());
    }

    /**
     * @description 선택목록 반환
     * @param obj   : String
     * @param field : String
     * @return  List<Schema.PicklistEntry>
     */
    public static List<Schema.PicklistEntry> getPickList(final String obj, final String field) {
        if(String.isBlank(obj) || String.isBlank(field)) return new List<Schema.PicklistEntry>();
        return (((SObject) (Type.forName('Schema.' + obj).newInstance())).getSObjectType())
                .getDescribe().fields.getMap().get(field).getDescribe().getPicklistValues();
    }

    /**
     * @description Sobject의 Field 를 이용한 Select Options 생성
     * @param obj       : String
     * @param field     : String
     * @param notBlank  : Boolean
     * @return  List<COM_Option>
     */
    public static List<COM_Option> makePickListOptions(final String obj, final String field, final Boolean notBlank) {
        return makePickListOptions(obj, field, notBlank, false);
    }

    /**
     * @description Sobject의 Field 를 이용한 Select Options 생성
     * @param obj           : String
     * @param field         : String
     * @param notBlank      : Boolean
     * @param isSelectAll   : Boolean
     * @return  List<COM_Option>
     */
    public static List<COM_Option> makePickListOptions(final String obj, final String field, final Boolean notBlank, final Boolean isSelectAll) {
        return makePickListOptions(obj, field, notBlank, isSelectAll, null);
    }

    /**
     * @description Sobject의 Field 를 이용한 Select Options 생성
     * @param obj           : String
     * @param field         : String
     * @param notBlank      : Boolean
     * @param isSelectAll   : Boolean
     * @param excludes      : Set<String>
     * @return  List<Option>
     */
    public static List<COM_Option> makePickListOptions(final String obj, final String field, final Boolean notBlank, final Boolean isSelectAll, final Set<String> excludes) {
        List<COM_Option> tmpList = makeInitOptions((isSelectAll ? '--All--' : null), notBlank);
        for (Schema.PicklistEntry pick : getPickList(obj, field)) {
            if (excludes == null) {
                tmpList.add(new COM_Option(pick.getLabel(), pick.getValue()));
            } else {
                if (excludes.contains(pick.getValue()) == false && pick.isActive()) {
                    tmpList.add(new COM_Option(pick.getLabel(), pick.getValue()));
                }
            }

        }
        return tmpList;
    }

    /**
     * @description Select Option의 기본값을 세팅하여 리턴
     * @param selectAllComment : String
     * @return  List<Option>
     */
    public static List<COM_Option> makeInitOptions(final String selectAllComment) {
        return makeInitOptions(selectAllComment, false);
    }

    /**
     * @description Select Option의 기본값을 세팅하여 리턴
     * @param selectAllComment  : String
     * @param notBlank          : Boolean
     * @return  List<Option>
     */
    public static List<COM_Option> makeInitOptions(final String selectAllComment, final Boolean notBlank) {
        List<COM_Option> tmpOptions = new List<COM_Option>();
        if (notBlank == false) {
            tmpOptions.add(new COM_Option(String.isNotBlank(selectAllComment) ? selectAllComment : '--None--', ''));
        }
        return tmpOptions;
    }

    public static Decimal divide(Decimal val, Decimal divisor, Integer scale, RoundingMode roundingMode) {
        scale = (scale == null ? 0 : scale);
        if ((val == null && divisor == null) || (divisor==null || divisor == 0)) return 0;
        return val.divide(divisor, scale, roundingMode);
    }

    public static String getDateYYMMDD(Date val) {
        String result = '';
        if (val <> null) {
            String year = String.valueOf(val.year()).substring(2, 4);
            String month = String.valueOf(val.month()).leftPad(2, '0');
            String day = String.valueOf(val.day()).leftPad(2, '0');
            result = (year + month + day);
        }
        return result;
    }

    /**
     * @description Rich Text 필드를 Plain Text로 변환할 때 사용 -> <p>, <br>, <ul>, <ol>, <a>, <li> 등의 태그를 처리하여 텍스트로 변환
     * @param input HTML 태그를 포함한 문자열
     * @return HTML 태그가 제거된 텍스트 문자열
     */
    public static String removeHtmlTagsExceptBr(String input) {
        if (String.isBlank(input)) return '';
        // 1. <a> 태그를 텍스트로 변환 (링크는 제거하고 텍스트만 출력)
        input = input.replaceAll('<a[^>]*>(.*?)</a>', '$1');

        // 2. <p> 태그를 \n으로 변환 (단락 간에 빈 줄을 추가)
        input = input.replaceAll('<p><br></p>', '\n');
        input = input.replaceAll('<p>', '\n').replaceAll('</p>', '\n');

        // 3. <br> 태그를 \n으로 변환 (줄바꿈)
        input = input.replaceAll('<br>', '\n');
        input = input.replaceAll('</br>', '\n');

        // 4. <ol> 태그 처리: 번호 매기기 리스트로 변환
        input = processOrderedList(input);

        // 5. <ul>과 <li> 태그를 불릿 리스트로 변환
        input = input.replaceAll('<ul>', '')  // <ul>은 제거
                .replaceAll('</ul>', '') // </ul>도 제거
                .replaceAll('<li>', '• ')  // <li> 항목을 불릿 기호로 시작
                .replaceAll('</li>', '\n'); // <li> 항목마다 줄바꿈 추가

        // 6. 나머지 HTML 태그는 제거
        String pattern = '<[^>]*>';
        String cleanedString = input.replaceAll(pattern, '');

        return cleanedString;
    }

    /**
     * @description <ol> 태그 안의 <li> 항목을 순차적으로 번호 매기기
     * @param input <ol> 태그가 포함된 HTML 문자열
     * @return <ol> 태그 내의 <li> 항목들이 번호 매기기 리스트로 변환된 문자열
     */
    private static String processOrderedList(String input) {
        String olPattern = '<ol>([\\s\\S]*?)</ol>';
        String result = input;

        // <ol> 태그에서 내용을 추출하기 위한 정규 표현식 패턴
        Matcher olMatcher = Pattern.compile(olPattern).matcher(result);

        Integer olCount;

        // <ol>이 있으면 그 안의 <li>를 처리
        while (olMatcher.find()) {
            String olContent = olMatcher.group(1);  // <ol> 안의 내용만 가져옴
            olCount = 1;  // 번호 매기기 초기화

            // <li> 태그를 찾아서 각 항목에 번호를 추가
            String[] liItems = olContent.split('<li>');
            String resultString = '';

            for (Integer i = 1; i < liItems.size(); i++) {  // 첫 번째 항목은 빈 값이므로 무시
                String liItem = liItems[i].replaceAll('</li>', '');
                resultString += olCount + '. ' + liItem + '\n';
                olCount++;
            }

            // <ol> 부분을 순차적으로 번호 매긴 내용으로 교체
            result = result.replace(olMatcher.group(0), resultString);
        }

        return result;
    }

    public static String randomStr(Integer len) {
        System.debug('■■■ randomStr ■■■');
        if (len == null || len <= 0 ) return '';
        final String charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String result = '';
        while (result.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), charset.length());
            result += charset.substring(idx, idx + 1);
        }
        return result;
    }

    public static Long randomNum(Integer len) {
        if (len == null || len <= 0) return null;
        String result = '';
        for (Integer i = 0; i < len; i++) {
            Integer randomDigit = Math.mod(Math.abs(Crypto.getRandomInteger()), 10); // 0~9 사이의 숫자 생성
            result += String.valueOf(randomDigit);
        }
        return Long.valueOf(result);
    }

    /**
     * @description 공백이 아닌 경우 원래 문자열, 그렇지 않으면 빈 문자열("")
     * @param val String
     *
     * @return String
     */
    public static String toStr(String val) {
        return (String.isBlank(val) ? '' : val);
    }

    /**
     * @description String 값을 Decimal 로 변환, Null 일때 0으로 반환
     * @param val 변환 대상 Value
     * @return Decimal
     */
    public static Decimal toDec2(String val) {
        val = val != null ? val.trim() : '';
        if (!String.isBlank(val) && (val.endsWith('-') || val.endsWith('_') || val.endsWith(','))) {
            val = val.substring(0, val.length() - 1);
        }
        return (String.isBlank(val) ? 0 : Decimal.valueOf(val));
    }

    public static Decimal toDec(Object val) {
        if (val == null) return 0;
        if (val instanceof Decimal) return (Decimal) val;
        if (val instanceof Long || val instanceof Integer || val instanceof Double) {
            return Decimal.valueOf(String.valueOf(val));
        }
        return toDec2((String) val);
    }

    /**
    * @description String -> Integer
    * @param numStr numberStr
    * @return Date
    */
    public static Integer toInteger(String numStr) {
        Integer result = 0;
        if ((String.isNotBlank(numStr)) && (numStr.length() > 0)) {
            result = Integer.valueOf(numStr);
        }
        return result;
    }

    /**
    * @description String -> Boolean
    * @param flagStr flagStr
    * @return Date
    */
    public static Boolean toBoolean(String flagStr) {
        Boolean result = false;
        if (String.isNotBlank(flagStr) && (flagStr.equals('Y') || flagStr.equals('y') || flagStr.containsAny('true') || flagStr.containsAny('TRUE'))) {
            result = true;
        }
        return result;
    }

    public static String boolConStr(Boolean flag) {
        return flag ? 'Y' : 'N';
    }

    /**
    * @description String -> Date
    * @param dateStr yyyyMMdd ex) 20250101
    * @return Date
    */
    public static Date toDate(String dateStr) {
        Date result = null;
        try {
            if (String.isNotBlank(dateStr)) {
                String cleanDate = dateStr.replace('-', '');
                if (cleanDate.length() >= 8 && !cleanDate.startsWith('0000')) {
                    Integer year = Integer.valueOf(cleanDate.substring(0, 4));
                    Integer month = Integer.valueOf(cleanDate.substring(4, 6));
                    Integer day = Integer.valueOf(cleanDate.substring(6, 8));

                    year = (year > 2999 || year <= 1900) ? 1900 : year;

                    result = Date.newInstance(year, month, day);
                }
            }

        } catch (Exception ex) {
            System.debug('COM_Util conDate error - dateStr: ' + dateStr + ', error: ' + ex.getMessage());
        }
        return result;
    }

    /**
    * @description String -> DateTime
    * @param dtStr yyyyMMddHHmmSS ex)20250101120000
    * @return Date
    */
    public static Datetime toDateTime(String dtStr) {
        Datetime result = null;
        if ((String.isNotBlank(dtStr)) && (dtStr.length() >= 8) && (dtStr != '00000000000000')) {
            result = Datetime.newInstance(
                    Integer.valueOf(dtStr.substring(0, 4)),
                    Integer.valueOf(dtStr.substring(4, 6)),
                    Integer.valueOf(dtStr.substring(6, 8)),
                    Integer.valueOf(dtStr.length() >= 10 ? dtStr.substring(8, 10) : '0'),
                    Integer.valueOf(dtStr.length() >= 12 ? dtStr.substring(10, 12) : '0'),
                    Integer.valueOf(dtStr.length() >= 14 ? dtStr.substring(12, 14) : '0')
            );
        }
        return result;
    }

    /**
    * @description String -> DateTime
    * @param dateStr yyyyMMdd ex)20250101
    * @param timeStr HHmmSS   ex)120000
    * @return Date
    */
    public static Datetime toDateTime(String dateStr, String timeStr) {
        Datetime result = null;
        if (((String.isNotBlank(dateStr)) && (dateStr.length() >= 8) && (dateStr != '00000000')) &&
                (String.isNotBlank(timeStr))) {
            result = Datetime.newInstance(
                    Integer.valueOf(dateStr.substring(0, 4)),
                    Integer.valueOf(dateStr.substring(4, 6)),
                    Integer.valueOf(dateStr.substring(6, 8)),
                    Integer.valueOf(timeStr.length() >= 2 ? timeStr.substring(0, 2) : '0'),
                    Integer.valueOf(timeStr.length() >= 4 ? timeStr.substring(2, 4) : '0'),
                    Integer.valueOf(timeStr.length() >= 6 ? timeStr.substring(4, 6) : '0')
            );
        }
        return result;
    }

    /**
     * @description Map<String, Object>에서 키에 해당하는 값을 String으로 안전하게 반환
     * - 키가 없거나 값이 null이면 null 반환
     * - JSON.deserializeUntyped 결과에서 null-safe하게 값을 추출할 때 사용
     * @param m 대상 Map
     * @param key 조회 Key
     *
     * @return String 값 또는 null
     */
    public static String getMapStr(Map<String, Object> m, String key) {
        Object val = m?.get(key);
        return (val != null) ? String.valueOf(val) : null;
    }

    public static Id toId(String val) {
        return String.isNotBlank(val) ? Id.valueOf(val) : null;
    }




}