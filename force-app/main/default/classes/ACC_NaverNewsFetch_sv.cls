/**********************************************************************************
 * @filename      : ACC_NaverNewsFetch_sv.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2026-03-08 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : ACC_NaverNewsFetch_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-08      i2max            Create
**********************************************************************************/
public with sharing class ACC_NaverNewsFetch_sv {

    private static final APIConfig__mdt CONFIG = APIConfig__mdt.getInstance('NaverSearch');

    // =========================================================================
    // 뉴스 검색 결과 Wrapper
    // =========================================================================
    public class NewsItem {
        public String title;           // HTML 태그 제거된 제목
        public String titleOriginal;   // 원본 (HTML 포함)
        public String description;     // HTML 태그 제거된 요약
        public String descriptionOriginal;
        public String link;            // 네이버 링크
        public String originalLink;    // 원본 기사 링크
        public Datetime pubDate;
    }

    // =========================================================================
    // API 호출 → NewsItem 리스트 반환
    // =========================================================================
    public static List<NewsItem> fetchNews(String keyword, Integer displayCount) {

        if (!CONFIG.Active_is__c)  throw new NaverApiException('NaverSearch API is inactive.');
        /*
        검색 결과 정렬 방법
        - sim: 정확도순으로 내림차순 정렬(기본값)
        - date: 날짜순으로 내림차순 정렬
         */

        HttpRequest req = new HttpRequest();
        req.setEndpoint(CONFIG.BaseURL__c
                + '/v1/search/news.json'
                + '?query=' + EncodingUtil.urlEncode(keyword, 'UTF-8')
                + '&display=' + (displayCount != null ? displayCount : 10)
                + '&sort=date'
        );
        req.setMethod('GET');
        req.setHeader('X-Naver-Client-Id', CONFIG.APIKey__c);
        req.setHeader('X-Naver-Client-Secret', CONFIG.APISecret__c);
        req.setTimeout(10000);

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() != 200) {
            throw new NaverApiException(
                    'HTTP ' + res.getStatusCode() + ': ' + res.getBody()
            );
        }

        return parseResponse(res.getBody());
    }

    // =========================================================================
    // JSON 파싱
    // =========================================================================
    private static List<NewsItem> parseResponse(String jsonBody) {
        List<NewsItem> items = new List<NewsItem>();
        Map<String, Object> root = (Map<String, Object>) JSON.deserializeUntyped(jsonBody);
        List<Object> rawItems = (List<Object>) root.get('items');

        if (rawItems == null) return items;

        for (Object obj : rawItems) {
            Map<String, Object> m = (Map<String, Object>) obj;
            NewsItem item = new NewsItem();
            item.titleOriginal       = (String) m.get('title');
            item.title               = stripHtmlTags((String) m.get('title'));
            item.descriptionOriginal = (String) m.get('description');
            item.description         = stripHtmlTags((String) m.get('description'));
            item.link                = (String) m.get('link');
            item.originalLink        = (String) m.get('originallink');
            item.pubDate             = parseRfc1123(((String) m.get('pubDate')));
            items.add(item);
        }
        return items;
    }

    // =========================================================================
    // NewsItem → ACC_News__c 변환 (Batch에서 호출)
    // =========================================================================
    public static ACC_News__c toSObject(NewsItem item, Id accountId) {
        return new ACC_News__c(
                Account_lk__c          = accountId,
                Title__c               = item.title,
                TitleOriginal__c       = item.titleOriginal,
                Description__c         = item.description,
                DescriptionOriginal__c = item.descriptionOriginal,
                Link__c                = item.link,
                OriginalLink__c        = item.originalLink,
                PubDate__c             = item.pubDate,
                NewsKey__c             = generateNewsKey(accountId, item.originalLink)
        );
    }

    // =========================================================================
    // Utility
    // =========================================================================
    // 고유키 생성: AccountId_해시
    public static String generateNewsKey(Id accountId, String originalLink) {
        String raw = accountId + '_' + originalLink;
        Blob digest = Crypto.generateDigest('SHA-256', Blob.valueOf(raw));
        return EncodingUtil.convertToHex(digest).substring(0, 40);
    }

    // HTML 태그 제거
    private static String stripHtmlTags(String html) {
        return String.isBlank(html) ? html : html.stripHtmlTags();
    }

    // RFC 1123 날짜 파싱 ("Mon, 08 Mar 2026 09:00:00 +0900")
    private static Datetime parseRfc1123(String dateStr) {
        if (String.isBlank(dateStr)) return null;
        try {
            // Apex에서 직접 파싱이 어려우므로 정규식으로 분해
            // 형식: "Day, DD Mon YYYY HH:MM:SS +HHMM"
            Pattern p = Pattern.compile(
                    '\\w+,\\s+(\\d{1,2})\\s+(\\w+)\\s+(\\d{4})\\s+(\\d{2}):(\\d{2}):(\\d{2})\\s+([+-]\\d{4})'
            );
            Matcher m = p.matcher(dateStr);
            if (!m.matches()) return null;

            Map<String, Integer> monthMap = new Map<String, Integer>{
                    'Jan'=>1,'Feb'=>2,'Mar'=>3,'Apr'=>4,'May'=>5,'Jun'=>6,
                    'Jul'=>7,'Aug'=>8,'Sep'=>9,'Oct'=>10,'Nov'=>11,'Dec'=>12
            };

            Integer day   = Integer.valueOf(m.group(1));
            Integer month = monthMap.get(m.group(2));
            Integer year  = Integer.valueOf(m.group(3));
            Integer hour  = Integer.valueOf(m.group(4));
            Integer min   = Integer.valueOf(m.group(5));
            Integer sec   = Integer.valueOf(m.group(6));

            // UTC 기준 Datetime 생성 후 offset 적용
            String offset = m.group(7);
            Integer offsetHour = Integer.valueOf(offset.substring(0, 3));
            Integer offsetMin  = Integer.valueOf(offset.substring(0, 1) + offset.substring(3, 5));

            Datetime dt = Datetime.newInstanceGmt(year, month, day, hour, min, sec);
            dt = dt.addHours(-offsetHour);
            dt = dt.addMinutes(-offsetMin);

            return dt;
        } catch (Exception e) {
            System.debug('[ACC_NaverNewsFetch_sv] parseRfc1123 failed: ' + dateStr + ' / ' + e.getMessage());
            return null;
        }
    }

    // =========================================================================
    // Custom Exception
    // =========================================================================
    public class NaverApiException extends Exception {}

}