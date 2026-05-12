/**********************************************************************************
 * @filename      : SOA_NoteManager_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-18 (수)
 * @group         :
 * @group-content :
 * @description   : SOA Note 관리 컨트롤러 — Note 조회, 파일 다운로드, ZIP 생성 기능 제공
 * @test-class    : SOA_NoteManager_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-18      i2max     Create
 **********************************************************************************/
public with sharing class SOA_NoteManager_Ctrl {

    // [Debit/Credit/SOC Note] OR [Cover Note]
    private static final String CLAIM_DEBIT_CATEGORY = 'SOC';
    private static final String CLAIM_CREDIT_CATEGORY = 'Cedant SOC';
    private static final String CATEGORY_COVER_NOTE = '';

    @AuraEnabled(Cacheable=true)
    public static Map<String, Object> initData() {
        return new Map<String, Object>{
                'noteTypeOptions' => COM_Util.makePickListOptions('COM_Note__c', 'NoteType__c', true)
        };
    }

    @AuraEnabled
    public static List<COM_Note__c> getNotes(String recordId, String filterCondition) {

        System.debug('getNotes 🐶🐶🐶 recordId=['+ recordId +'] filterCondition=['+ filterCondition +']');

        List<String> fields = new List<String>{
                'Id', 'Name', 'SettlementLineItem__r.ClosingOrign__c', 'NoteType__c',
                'Facility_lk__c', 'Facility_lk__r.Name', 'FacilityUY_fm__c',
                'LKRefNReins__c', 'CedantFacility_lk__c', 'CedantFacility_lk__r.Name',
                'Insured_lk__c', 'Insured_lk__r.Name',
                'PeriodFrom_fm__c', 'PeriodTo_fm__c',
                'LOB_fm__c', 'Type_fm__c',
                'ParentClaimNo_fm__c', 'CedantClaimNo_fm__c',
                'DateOfLoss_fm__c', 'LocationOfLoss_fm__c',
                'ChildClaim_lk__c', 'ChildClaim_lk__r.Name',
                'PolicyNo__c', 'Placement_lk__c',
                'Reinsured_lk__c', 'Reinsured_lk__r.Name',
                'PPWType__c', 'PPWDays_fm__c', 'PPWDate__c',
                'InstallmentNo__c', 'InstallmentSeq__c', 'InstallPct__c',
                'NoteStatus__c', 'OriginCurrency__c',
                'Slip_lk__c', 'Slip_lk__r.Name',
                'Account_lk__c', 'Account_lk__r.Name',
                'NoteContact_lk__c', 'NoteContact_lk__r.Name',
                'NoteParticular__c', 'NoteAmtSettled__c', 'NoteAmtBalance__c',
                'NoteAmount__c', 'IssueDate__c'
        };

        List<String> clauses = new List<String>{
                'NoteType__c <> \'\'',
                'OriginCurrency__c <> \'\''
        };

        // 레코드 모드: recordId 기반 조회
        if (String.isNotBlank(recordId)) {
            clauses.add('Id IN (SELECT Note_md__c FROM SOA_NoteJunction__c WHERE SOA_md__c = :recordId)');
        }

        // 탭 모드: 필터 조건 기반 조회
        if (String.isNotBlank(filterCondition)) {
            Map<String, Object> filters = (Map<String, Object>) JSON.deserializeUntyped(filterCondition);
            clauses.addAll(buildFilterClauses(filters));
        }

        String query = 'SELECT ' + String.join(fields, ', ')
                + ' FROM COM_Note__c'
                + ' WHERE ' + String.join(clauses, ' AND ')
                + ' WITH SECURITY_ENFORCED'
                + ' ORDER BY Name DESC'
                + ' LIMIT 2000';

        System.debug('query=[' + query + ']');

        return Database.query(query);
    }

    private static List<String> buildFilterClauses(Map<String, Object> filters) {
        List<String> clauses = new List<String>();

        // Note Status (고정값)
//        if (filters.containsKey('noteStatus') && filters.get('noteStatus') != null) {
//            String val = String.escapeSingleQuotes((String) filters.get('noteStatus'));
//            clauses.add('NoteStatus__c = \'' + val + '\'');
//        }

        // Account (필수)
        if (filters.containsKey('accountId') && filters.get('accountId') != null) {
            String val = String.escapeSingleQuotes((String) filters.get('accountId'));
            clauses.add('Account_lk__c = \'' + val + '\'');
        }

        // Note Type
        if (filters.containsKey('noteType') && filters.get('noteType') != null) {
            Object noteType = filters.get('noteType');
            if (noteType instanceof List<Object>) {
                List<String> vals = new List<String>();
                for (Object v : (List<Object>) noteType) {
                    vals.add('\'' + String.escapeSingleQuotes((String) v) + '\'');
                }
                if (!vals.isEmpty()) {
                    clauses.add('NoteType__c IN (' + String.join(vals, ', ') + ')');
                }
            } else {
                String val = String.escapeSingleQuotes((String) noteType);
                clauses.add('NoteType__c = \'' + val + '\'');
            }
        }

        // Debit/Credit No. (LIKE)
        if (filters.containsKey('creditNoteSeq') && String.isNotBlank((String) filters.get('creditNoteSeq'))) {
            String val = String.escapeSingleQuotes((String) filters.get('creditNoteSeq'));
            clauses.add('CreditNoteSeq_fm__c LIKE \'%' + val + '%\'');
        }

        // Facility
        if (filters.containsKey('facilityId') && filters.get('facilityId') != null) {
            String val = String.escapeSingleQuotes((String) filters.get('facilityId'));
            clauses.add('Facility_lk__c = \'' + val + '\'');
        }

        // Facility BDX Period From ~ To
        if (filters.containsKey('facilityBDXPeriodFrom') && filters.get('facilityBDXPeriodFrom') != null) {
            String val = String.escapeSingleQuotes((String) filters.get('facilityBDXPeriodFrom'));
            clauses.add('FacilityBDXPeriodFrom__c >= ' + val);
        }
        if (filters.containsKey('facilityBDXPeriodTo') && filters.get('facilityBDXPeriodTo') != null) {
            String val = String.escapeSingleQuotes((String) filters.get('facilityBDXPeriodTo'));
            clauses.add('FacilityBDXPeriodTo__c <= ' + val);
        }

        // LK Ref No.
        if (filters.containsKey('lkRefNo') && String.isNotBlank((String) filters.get('lkRefNo'))) {
            String val = String.escapeSingleQuotes((String) filters.get('lkRefNo'));
            clauses.add('LKRefNReins__c LIKE \'%' + val + '%\'');
        }

        // Placement
        if (filters.containsKey('placementId') && filters.get('placementId') != null) {
            String val = String.escapeSingleQuotes((String) filters.get('placementId'));
            clauses.add('Placement_lk__c = \'' + val + '\'');
        }

        // Insured
        if (filters.containsKey('insuredId') && filters.get('insuredId') != null) {
            String val = String.escapeSingleQuotes((String) filters.get('insuredId'));
            clauses.add('Insured_lk__c = \'' + val + '\'');
        }

        // Inception Date
        if (filters.containsKey('inceptionDate') && filters.get('inceptionDate') != null) {
            String val = String.escapeSingleQuotes((String) filters.get('inceptionDate'));
            clauses.add('InceptionDate__c = ' + val);
        }

        // No of Installment
        if (filters.containsKey('installmentNo') && filters.get('installmentNo') != null) {
            clauses.add('InstallmentNo__c = ' + String.valueOf(filters.get('installmentNo')));
        }

        // PPW Date
        if (filters.containsKey('ppwDate') && filters.get('ppwDate') != null) {
            String val = String.escapeSingleQuotes((String) filters.get('ppwDate'));
            clauses.add('PPWDate__c = ' + val);
        }

        // Date of Loss
        if (filters.containsKey('dateOfLoss') && filters.get('dateOfLoss') != null) {
            String val = String.escapeSingleQuotes((String) filters.get('dateOfLoss'));
            clauses.add('DateOfLoss_fm__c = ' + val);
        }

        // SOC Seq.
        if (filters.containsKey('socSeq') && String.isNotBlank((String) filters.get('socSeq'))) {
            String val = String.escapeSingleQuotes((String) filters.get('socSeq'));
            clauses.add('SOCSeq__c = \'' + val + '\'');
        }

        return clauses;
    }

    @AuraEnabled
    public static Id saveAsFile(
            Id recordId,
            String fileName,
            String base64Data,
            String netAmount
    ) {
        ContentVersion cv = new ContentVersion();
        cv.Title = fileName;
        cv.PathOnClient = fileName + '.xlsx';
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        cv.FirstPublishLocationId = recordId;
        insert cv;

        update new SOA_Statement__c(
                Id = recordId,
                NetAmount__c = netAmount
        );

        return cv.Id;
    }

    @AuraEnabled
    public static Id createSOA(String selectedRowsStr) {
        try {
            List<Object> rows = (List<Object>) JSON.deserializeUntyped(selectedRowsStr);
            if (rows.isEmpty()) throw new AuraHandledException('No rows selected.');

            Id accountId;
            Map<String, Decimal> netAmountByCcy = new Map<String, Decimal>();
//            Map<String, Decimal> creditByCcy = new Map<String, Decimal>();
//            Map<String, Decimal> debitByCcy = new Map<String, Decimal>();
            List<Id> noteIds = new List<Id>();
            String prefix = Datetime.now().format('yyMM');
            List<AggregateResult> aggList = [
                    SELECT MAX(Name) maxName
                    FROM SOA_Statement__c
                    WHERE Name LIKE :prefix + '-%'
            ];

            Integer seq = 1;
            String maxName = (String) aggList[0].get('maxName');
            if (maxName != null) {
                // 'YYMM-01' → '01' 추출 후 +1
                seq = Integer.valueOf(maxName.substringAfterLast('-')) + 1;
            }

            for (Object obj : rows) {
                Map<String, Object> row = (Map<String, Object>) obj;

                noteIds.add((Id) row.get('Id'));

                // Account (동일 값)
                if (accountId == null && row.get('Account_lk__c') != null) {
                    accountId = (Id) row.get('Account_lk__c');
                }

                // 통화별 합계
                String ccy = (String) row.get('OriginCurrency__c');
                if (String.isNotBlank(ccy)) {
                    Decimal noteAmt = COM_Util.toDec(row.get('NoteAmount__c'));
//                    Decimal creditAmt = COM_Util.toDec(row.get('CreditAmount__c'));
//                    Decimal debitAmt = COM_Util.toDec(row.get('DebitAmount__c'));

                    netAmountByCcy.put(ccy, (netAmountByCcy.containsKey(ccy) ? netAmountByCcy.get(ccy) : 0) + noteAmt);
                }
            }

            // SOA_Statement__c 생성
            SOA_Statement__c soa = new SOA_Statement__c(
                    Name = prefix + '-' + String.valueOf(seq).leftPad(2, '0'),
                    Account_lk__c = accountId,
                    IssueDate__c = Date.today(),
                    NetAmount__c = formatCurrencyTotals(netAmountByCcy)
            );
            insert soa;

            // SOA_NoteJunction__c 생성
            List<SOA_NoteJunction__c> junctions = new List<SOA_NoteJunction__c>();
            for (Id noteId : noteIds) {
                junctions.add(new SOA_NoteJunction__c(
                        SOA_md__c = soa.Id,
                        Note_md__c = noteId
                ));
            }
            insert junctions;

            return soa.Id;

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    /*
    [Debit/Credit/SOC Note]
    ClosingOrign: COM_Note__c.SettlementLineItem__r.ClosingOrign__c
    NoteType: COM_Note__c.NoteType__c
    1~4 모든 조건에서 File명이 COM_Note__c.Name을 포함 하는 것만 대상으로 함.
    1. ClosingOrign=='Placement' && NoteType =='Debit' ==> Placement_lk__c 하위 ContentDocument 전체
    2. ClosingOrign=='Placement' && NoteType =='Credit' ==> Placement_lk__c 하위 ContentDocument 전체
    3. ClosingOrign=='Claim' && NoteType =='Debit' ==> ChildClaim_lk__c 하위 ContentDocument 중에서 RelFiles__Category__c=='SOC'
    4. ClosingOrign=='Claim' && NoteType =='Credit' ==> ChildClaim_lk__c 하위 ContentDocument 중에서 RelFiles__Category__c=='Cedant SOC'
    [Cover Note]
    1. ClosingOrign=='Placement' && NoteType =='Debit' ==> Placement_lk__c 하위 ContentDocument 전체
    2. ClosingOrign=='Placement' && NoteType =='Credit' ==> Placement_lk__c 하위 ContentDocument 전체
    3. ClosingOrign=='Claim' && NoteType =='Debit' ==> ChildClaim_lk__c 하위 ContentDocument
    4. ClosingOrign=='Claim' && NoteType =='Credit' ==> ChildClaim_lk__c 하위 ContentDocument
     */


    /**
     * @description Note별 첨부 파일 조회
     *              - Debit/Credit Note 파일과 Cover Note 파일을 한 번에 반환
     *              - 내부에서 Placement/Claim 그룹별로 bulk 조회하여 SOQL 최소화
     *
     *              ClosingOrign: COM_Note__c.SettlementLineItem__r.ClosingOrign__c
     *              NoteType: COM_Note__c.NoteType__c
     *              모든 조건에서 File명이 COM_Note__c.Name을 포함 하는 것만 대상으로 함.
     *
     *              [Debit/Credit/SOC Note]
     *              1. ClosingOrign=='Placement' && NoteType=='Debit'  ==> Placement_lk__c 하위 ContentDocument 전체
     *              2. ClosingOrign=='Placement' && NoteType=='Credit' ==> Placement_lk__c 하위 ContentDocument 전체
     *              3. ClosingOrign=='Claim'     && NoteType=='Debit'  ==> ChildClaim_lk__c 하위 ContentDocument 중에서 RelFiles__Category__c=='SOC'
     *              4. ClosingOrign=='Claim'     && NoteType=='Credit' ==> ChildClaim_lk__c 하위 ContentDocument 중에서 RelFiles__Category__c=='Cedant SOC'
     *
     *              [Cover Note]
     *              1. ClosingOrign=='Placement' && NoteType=='Debit'  ==> Placement_lk__c 하위 ContentDocument 전체
     *              2. ClosingOrign=='Placement' && NoteType=='Credit' ==> Placement_lk__c 하위 ContentDocument 전체
     *              3. ClosingOrign=='Claim'     && NoteType=='Debit'  ==> ChildClaim_lk__c 하위 ContentDocument 전체
     *              4. ClosingOrign=='Claim'     && NoteType=='Credit' ==> ChildClaim_lk__c 하위 ContentDocument 전체
     *
     * @param noteIds COM_Note__c Id List
     * @return Map<Id, NoteFileBundle> Note Id 기준 파일 번들 (Debit/Credit + Cover)
     */
    @AuraEnabled
    public static Map<Id, NoteFileInfo> getNoteFileMap(List<Id> noteIds) {
        Map<Id, NoteFileInfo> result = new Map<Id, NoteFileInfo>();
        if (noteIds == null || noteIds.isEmpty()) return result;

        // 1. Note 재조회 — 분기 기준 필드 확보
        List<COM_Note__c> notes = [
                SELECT Id, Name, NoteType__c,
                        SettlementLineItem__r.ClosingOrign__c,
                        Placement_lk__c, ChildClaim_lk__c
                FROM COM_Note__c
                WHERE Id IN :noteIds
        ];

        // 2. Parent Id 수집 (Placement / Claim)
        Set<Id> parentIds = new Set<Id>();
        for (COM_Note__c n : notes) {
            String origin = n.SettlementLineItem__r?.ClosingOrign__c;
            if (origin == 'Placement' && n.Placement_lk__c != null) {
                parentIds.add(n.Placement_lk__c);
            } else if (origin == 'Claim' && n.ChildClaim_lk__c != null) {
                parentIds.add(n.ChildClaim_lk__c);
            }
        }

        // 3. Parent별 파일 pool 구성
        Map<Id, List<ContentVersion>> filesByParent = new Map<Id, List<ContentVersion>>();
        if (!parentIds.isEmpty()) {
            // ContentDocumentLink → ContentDocumentId 매핑
            Map<Id, Set<Id>> docIdsByParent = new Map<Id, Set<Id>>();
            Set<Id> allDocIds = new Set<Id>();
            for (ContentDocumentLink cdl : [
                    SELECT LinkedEntityId, ContentDocumentId
                    FROM ContentDocumentLink
                    WHERE LinkedEntityId IN :parentIds
            ]) {
                if (!docIdsByParent.containsKey(cdl.LinkedEntityId)) {
                    docIdsByParent.put(cdl.LinkedEntityId, new Set<Id>());
                }
                docIdsByParent.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
                allDocIds.add(cdl.ContentDocumentId);
            }

            // ContentVersion bulk 조회 (IsLatest=true)
            Map<Id, ContentVersion> cvByDocId = new Map<Id, ContentVersion>();
            if (!allDocIds.isEmpty()) {
                for (ContentVersion cv : [
                        SELECT Id, ContentDocumentId, Title, FileExtension, ContentSize, RelFiles__Category__c
                        FROM ContentVersion
                        WHERE ContentDocumentId IN :allDocIds AND IsLatest = TRUE
                ]) {
                    cvByDocId.put(cv.ContentDocumentId, cv);
                }
            }

            // Parent별 CV 리스트 구성
            for (Id parentId : docIdsByParent.keySet()) {
                List<ContentVersion> contentVersions = new List<ContentVersion>();
                for (Id docId : docIdsByParent.get(parentId)) {
                    ContentVersion cv = cvByDocId.get(docId);
                    if (cv != null) contentVersions.add(cv);
                }
                filesByParent.put(parentId, contentVersions);
            }
        }

        // 4. Note별 Debit/Credit + Cover 집계
        for (COM_Note__c n : notes) {
            NoteFileInfo info = new NoteFileInfo();

            String origin = n.SettlementLineItem__r?.ClosingOrign__c;
            String type = n.NoteType__c;
            Id parentId = (origin == 'Placement') ? n.Placement_lk__c
                    : (origin == 'Claim')     ? n.ChildClaim_lk__c : null;

            List<ContentVersion> pool = (parentId != null) ? filesByParent.get(parentId) : null;

            if (pool != null && !pool.isEmpty()) {
                String noteNameLower = (n.Name != null) ? n.Name.toLowerCase() : '';

                // Debit/Credit Note 집계용
                List<String> dcNames = new List<String>();
                List<String> dcDocIds = new List<String>();
                Long dcTotalSize = 0;

                // Cover Note 집계용 (필터 없음 — 해당 parent 하위 전체)
                List<String> cvNames = new List<String>();
                List<String> cvDocIds = new List<String>();
                Long cvTotalSize = 0;

                // Claim Debit/Credit 용 카테고리 타겟
                String targetCategory = (origin == 'Claim')
                        ? ((type == 'Debit') ? CLAIM_DEBIT_CATEGORY
                                : (type == 'Credit') ? CLAIM_CREDIT_CATEGORY : null)
                        : null;

                for (ContentVersion cv : pool) {
                    String fileName = (cv.FileExtension != null) ? cv.Title + '.' + cv.FileExtension : cv.Title;
                    String titleLower = (cv.Title != null) ? cv.Title.toLowerCase() : '';
                    Boolean titleContainsName = String.isNotBlank(noteNameLower) && titleLower.contains(noteNameLower);
                    Long size = (cv.ContentSize != null) ? cv.ContentSize : 0;

                    // ── Cover Note: 필터 없음, parent 하위 전체 ──
                    cvNames.add(fileName);
                    cvDocIds.add(cv.ContentDocumentId);
                    cvTotalSize += size;

                    // ── Debit/Credit Note: 조건별 필터링 ──
                    Boolean matchDC = false;
                    if (origin == 'Placement' && (type == 'Debit' || type == 'Credit')) {
                        matchDC = titleContainsName;
                    } else if (origin == 'Claim' && targetCategory != null) {
                        matchDC = titleContainsName && targetCategory.equalsIgnoreCase(cv.RelFiles__Category__c);
                    }

                    if (matchDC) {
                        dcNames.add(fileName);
                        dcDocIds.add(cv.ContentDocumentId);
                        dcTotalSize += size;
                    }
                }

                info.debitNoteFileName           = dcNames.isEmpty() ? null : String.join(dcNames, ', ');
                info.debitNoteContentDocumentIds = dcDocIds.isEmpty() ? null : String.join(dcDocIds, ',');
                info.debitNoteTotalSize          = dcTotalSize;

                info.coverNoteFileName           = cvNames.isEmpty() ? null : String.join(cvNames, ', ');
                info.coverNoteContentDocumentIds = cvDocIds.isEmpty() ? null : String.join(cvDocIds, ',');
                info.coverNoteTotalSize          = cvTotalSize;
            }

            result.put(n.Id, info);
        }

        return result;
    }

    /**
     * @description 선택된 ContentDocumentId 들로 ZIP 생성 → 레코드에 첨부 (호출 측에서 8MB 이하로 청크 분할하여 N회 호출)
     * @param recordId SOA RecordId
     * @param contentDocumentIds 선택된 ContentDocumentId
     * @param fileName fileName
     *
     * @return ContentVersionId
     */
    @AuraEnabled
    public static Id downloadNotesAsZip(Id recordId, List<String> contentDocumentIds, String fileName) {
        if (contentDocumentIds == null || contentDocumentIds.isEmpty()) {
            throw new AuraHandledException('No files to download.');
        }

        // dedupe
        Set<Id> docIdSet = new Set<Id>();
        for (String contentDocumentId : contentDocumentIds) {
            if (String.isNotBlank(contentDocumentId)) docIdSet.add((Id) contentDocumentId);
        }
        if (docIdSet.isEmpty()) throw new AuraHandledException('No files to download.');

        // 최신 ContentVersion 조회
        List<ContentVersion> versions = [
                SELECT Id, ContentDocumentId, Title, FileExtension, VersionData
                FROM ContentVersion
                WHERE ContentDocumentId IN :docIdSet
                AND IsLatest = TRUE
        ];
        if (versions.isEmpty()) throw new AuraHandledException('Files not found.');

        // ZIP 생성
        Compression.ZipWriter writer = new Compression.ZipWriter();
        Set<String> usedNames = new Set<String>();
        for (ContentVersion cv : versions) {
            String ext   = String.isNotBlank(cv.FileExtension) ? ('.' + cv.FileExtension) : '';
            String entry = cv.Title + ext;
            Integer dup  = 1;
            while (usedNames.contains(entry)) {
                entry = cv.Title + '_' + dup + ext;
                dup++;
            }
            usedNames.add(entry);
            writer.addEntry(entry, cv.VersionData);
        }
        Blob zipBlob = writer.getArchive();

        // ContentVersion 생성 + SOA 레코드에 첨부
        ContentVersion zipCv = new ContentVersion();
        zipCv.Title                  = fileName;
        zipCv.PathOnClient           = fileName + '.zip';
        zipCv.VersionData            = zipBlob;
        zipCv.FirstPublishLocationId = recordId;
        insert zipCv;

        return zipCv.Id;
    }

    private static String formatCurrencyTotals(Map<String, Decimal> totals) {
        List<String> parts = new List<String>();
        for (String ccy : totals.keySet()) {
            parts.add(ccy + ' ' + totals.get(ccy).setScale(2).format());
        }
        return String.join(parts, ' ');
    }

    public class NoteFileInfo {
        @AuraEnabled public String debitNoteFileName;
        @AuraEnabled public String debitNoteContentDocumentIds;
        @AuraEnabled public Long   debitNoteTotalSize;
        @AuraEnabled public String coverNoteFileName;
        @AuraEnabled public String coverNoteContentDocumentIds;
        @AuraEnabled public Long   coverNoteTotalSize;
    }



}