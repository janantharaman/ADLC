/**********************************************************************************
 * @filename      : ACC_NaverNewsFetch_ba.cls
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
public with sharing class ACC_NaverNewsFetch_ba implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private Integer newsSuccess = 0;
    private Integer newsFail = 0;
    private Integer acctSuccess = 0;
    private Integer acctFail = 0;


    // =========================================================================
    // start: 뉴스 수집 대상 Account 조회
    // =========================================================================
    public Database.QueryLocator start(Database.BatchableContext bc) {

        Logger.setScenario('ACC_NaverNewsFetch_ba');
        Logger.info('Batch 시작');
        Logger.saveLog();

        List<String> query = new List<String>();
        query.add('SELECT Id, Name, CompanyNameEng__c, CompanyNameKor__c, LastNewsFetchedAT__c');
        query.add('FROM Account');
        query.add('WHERE CompanyNameKor__c != NULL');
        query.add('AND (NOT Name LIKE \'%Test%\')');
        query.add('AND (NOT CompanyNameKor__c LIKE \'%Test%\')');

        return Database.getQueryLocator(String.join(query, ' '));
    }

    // =========================================================================
    // execute: Account별 뉴스 수집 → upsert
    // =========================================================================
    public void execute(Database.BatchableContext bc, List<Account> scope) {

        Logger.setScenario('ACC_NaverNewsFetch_ba');
        Logger.info('execute 시작 - scope size: ' + scope.size());

        // 1) Active Config 전체 조회
        List<NewsConfig__mdt> newsConfigs = [
                SELECT Keyword__c, FetchCount__c, ExcludeTerms__c
                FROM NewsConfig__mdt
                WHERE Active_is__c = TRUE
                AND Keyword__c != NULL
        ];
        if (newsConfigs.isEmpty()) return;

        List<String> keywords = new List<String>();
        List<String> excludeTerms = new List<String>();

        for (NewsConfig__mdt newsConfig : newsConfigs) {
            if (String.isNotBlank(newsConfig.Keyword__c)) {
                keywords.addAll(newsConfig.Keyword__c.deleteWhitespace().split(','));
            }
            if (String.isNotBlank(newsConfig.ExcludeTerms__c)) {
                excludeTerms.addAll(newsConfig.ExcludeTerms__c.deleteWhitespace().split(','));
            }
        }

        List<ACC_News__c> newsToUpsert = new List<ACC_News__c>();
        Set<Id> successAccountIds = new Set<Id>();

        for (Account acc : scope) {
            Boolean hasRateLimit = false;
            try {
                for (String keyword : keywords) {
                    keyword = acc.CompanyNameKor__c + ' ' + keyword;
                    Integer fetchCount = 10;

                    List<ACC_NaverNewsFetch_sv.NewsItem> items;
                    try {
                        items = ACC_NaverNewsFetch_sv.fetchNews(keyword, fetchCount);
                    } catch (Exception e) {
                        Logger.warn('keyword=[' + keyword + '] API 실패(skip): ' + e.getMessage());
                        if (e.getMessage().contains('429')) {
                            hasRateLimit = true;
                            break;
                        }
                        continue;
                    }
//                    System.debug('🤖 items=['+ items +']');
                    Logger.info('keyword=[' + keyword + '], result.size()=[' + items.size() + ']');

                    // ExcludeTerms 필터링
                    if (!excludeTerms.isEmpty()) {
                        List<ACC_NaverNewsFetch_sv.NewsItem> filtered = new List<ACC_NaverNewsFetch_sv.NewsItem>();
                        for (ACC_NaverNewsFetch_sv.NewsItem item : items) {
                            Boolean excluded = false;
                            for (String term : excludeTerms) {
                                String t = term.trim().toLowerCase();
                                if (item.title.toLowerCase().contains(t) || item.description.toLowerCase().contains(t)) {
                                    excluded = true;
                                    break;
                                }
                            }
                            if (!excluded) filtered.add(item);
                        }
                        items = filtered;
                    }

                    // pubDate 필터링
                    for (ACC_NaverNewsFetch_sv.NewsItem item : items) {
                        Date lastFetchedAt = (acc.LastNewsFetchedAT__c == null ? Date.today().addDays(-3) : acc.LastNewsFetchedAT__c.dateGmt());
                        if (item.pubDate == null || item.pubDate.dateGmt() <= lastFetchedAt) {
                            continue;
                        }
                        newsToUpsert.add(ACC_NaverNewsFetch_sv.toSObject(item, acc.Id));
                    }
                }
            } catch (Exception e) {
                Logger.error('Account [' + acc.CompanyNameKor__c + '] 뉴스 수집 실패: ' + e.getMessage(), e);
                hasRateLimit = true;
            }
            if (!hasRateLimit) {
                successAccountIds.add(acc.Id);
            }
        }

        Map<String, ACC_News__c> deduped = new Map<String, ACC_News__c>();
        for (ACC_News__c n : newsToUpsert) {
            deduped.put(n.NewsKey__c, n);
        }
        newsToUpsert = deduped.values();

        // 6) Upsert
        if (!newsToUpsert.isEmpty()) {
//            System.debug('🤖 newsToUpsert.size()=' + newsToUpsert.size());
//            System.debug('🤖 newsToUpsert=' + JSON.serializePretty(newsToUpsert));
            List<Database.UpsertResult> upsertResults = Database.upsert(newsToUpsert, ACC_News__c.NewsKey__c, false);
            for (Database.UpsertResult upsertResult : upsertResults) {
                if (upsertResult.isSuccess()) newsSuccess++;
                if (!upsertResult.isSuccess()) newsFail++;
            }
        }
//        System.debug('🤖 newsSuccess=' + newsSuccess);
//        System.debug('🤖 newsFail=' + newsFail);

        // 7) Account LastNewsFetchedAT__c 업데이트
        if (!successAccountIds.isEmpty()) {
            List<Account> accounts = new List<Account>();
            for (Id accId : successAccountIds) {
                accounts.add(new Account(Id = accId, LastNewsFetchedAT__c = Datetime.now()));
            }
            List<Database.SaveResult> saveResults = Database.update(accounts, false);
            for (Database.SaveResult saveResult : saveResults) {
                if (saveResult.isSuccess()) acctSuccess++;
                if (!saveResult.isSuccess()) acctFail++;
            }
        }
        Logger.info('upsert 건수: ' + newsToUpsert.size() + ', Account - Last News Fetched At 업데이트 건수: ' + successAccountIds.size());
        Logger.saveLog();
    }

    // =========================================================================
    // finish: 결과 로그
    // =========================================================================
    public void finish(Database.BatchableContext bc) {
        Logger.setScenario('ACC_NaverNewsFetch_ba');
        Logger.info('Batch 완료 ---------------------------------------------------');
        Logger.info('ACC_News__c 완료 - 성공: ' + newsSuccess + ', 실패: ' + newsFail);
        Logger.info('Account LastNewsFetchedAT__c 업데이트 - 성공: ' + acctSuccess + ', 실패: ' + acctFail);
        Logger.saveLog();

        // Delete Batch 체이닝
        Database.executeBatch(new ACC_NaverNewsDelete_ba(), 200);

    }

}