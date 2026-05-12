/**********************************************************************************
 * @filename      : ACC_AccountContactDigestCtrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-30 (금)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : ACC_AccountContactDigestCtrl_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-30      i2max     Create
**********************************************************************************/
public with sharing class ACC_AccountContactDigestCtrl {
//    public Id acctId { get; set; }

    public Id acctId {
        get;
        set {
            acctId = value;
            init();
        }
    }

    public String recipientName { get; private set; }
    public String accountName { get; private set; }
    public String logoUrl { get; private set; }
    public List<Contact> contacts { get; private set; }
    public Integer contactsSize { get { return contacts == null ? 0 : contacts.size(); } }

    public ACC_AccountContactDigestCtrl() {
        // Visualforce Email Template 컨텍스트에서 recipient / relatedTo를 직접 받기 어렵기 때문에
        // accountId로 필요한 정보를 로딩합니다.
//        init();
        contacts = new List<Contact>();

    }

    private void init() {
        if (acctId == null) {
            contacts = new List<Contact>();
            recipientName = '';
            accountName = '';
            logoUrl = '';
            return;
        }

        Account a = [
                SELECT Id, Name, Owner.Name,
                (SELECT Id, Name, Title, Email, Phone FROM Contacts ORDER BY LastName, FirstName LIMIT 200)
                FROM Account
                WHERE Id = :acctId
                LIMIT 1
        ];

        accountName = a.Name;
        recipientName = a.Owner != null ? a.Owner.Name : '';

        contacts = new List<Contact>();
        if (a.Contacts != null) {
            contacts.addAll(a.Contacts);
        }

        // 법인/사용자별 로고 분기: 여기에서 결정 (예시는 임시 고정)
        // 가장 안전한 방식은 Document(Externally Available Image) 기반 ImageServer URL 사용
        logoUrl = buildDocumentImageUrl('YOUR_DOCUMENT_ID');
    }

    private static String buildDocumentImageUrl(String documentId) {
        if (String.isBlank(documentId)) {
            return '';
        }

        return Url.getOrgDomainUrl().toExternalForm()
                + '/servlet/servlet.ImageServer?id=' + EncodingUtil.urlEncode(documentId, 'UTF-8')
                + '&oid=' + UserInfo.getOrganizationId();
    }

}