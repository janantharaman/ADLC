/**********************************************************************************
 * @filename      : ACC_TestDataFactory.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-14 (수)
 * @group         :
 * @group-content :
 * @description   : Account Domain Test Data Factory
 * @test-class    : ACC_TestDataFactory_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-14      i2max     Create
**********************************************************************************/
@IsTest
public class ACC_TestDataFactory {

    /**
     * @description Create Account (Default)
     * @param name (String): Account Name (If null, random name generated)
     * @param isInsert (Boolean): Insert flag
     * @return Account
     */
    public static Account createAccount(String name, Boolean isInsert) {
        return createAccount(name, null, isInsert);
    }

    /**
     * @description Create Account with InsuredType
     * @param name (String): Account Name (If null, random name generated)
     * @param insuredTypes (String): InsuredType__c value (Multi-Select Picklist, e.g., 'Reinsurer;MGA')
     * @param isInsert (Boolean): Insert flag
     * @return Account
     */
    public static Account createAccount(String name, String insuredTypes, Boolean isInsert) {
        String accName = String.isNotBlank(name) ? name : 'TestAcc_' + COM_TestDataFactory.generateRandomString(5);

        Id bizAccRtId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('BusinessAccount').getRecordTypeId();

        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
            Account.Name => accName,
            Account.CompanyNameEng__c => accName,
            Account.Country__c => 'KR',
            Account.RecordTypeId => bizAccRtId,
            Account.InsuredType__c => insuredTypes
        };

        // InsuredType에 따른 체크박스 자동 설정
        if (String.isNotBlank(insuredTypes)) {
            List<String> types = insuredTypes.split(';');
            if (types.contains('General')) fields.put(Account.isGeneralAcc__c, true);
            if (types.contains('Insurer')) fields.put(Account.isInsurerAcc__c, true);
            if (types.contains('Reinsurer')) fields.put(Account.isReinsurerAcc__c, true);
            if (types.contains('Broker')) fields.put(Account.isBrokerAcc__c, true);
            if (types.contains('MGA')) fields.put(Account.isMGAAcc__c, true);
        }
        return (Account) COM_TestDataFactory.createSObject('Account', fields, isInsert);
    }

    /**
     * @description Create Contact
     * @param accountId (Id): Parent Account Id
     * @param lastName (String): Contact Last Name (If null, random name generated)
     * @param isInsert (Boolean): Insert flag
     * @return Contact
     */
    public static Contact createContact(Id accountId, String lastName, Boolean isInsert) {
        String cName = String.isNotBlank(lastName) ? lastName : 'TestContact_' + COM_TestDataFactory.generateRandomString(5);

        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
            Contact.AccountId => accountId,
            Contact.LastName => cName
        };
        return (Contact) COM_TestDataFactory.createSObject('Contact', fields, isInsert);
    }

    /**
     * @description Create ACC_AdditionalInfo__c (Base Method)
     * @param accountId (Id): Parent Account Id
     * @param rtDevName (String): RecordType DeveloperName ('BankInformation' or 'Security')
     * @param name (String): Name (If null, random name generated)
     * @param isInsert (Boolean): Insert flag
     * @return ACC_AdditionalInfo__c
     */
    public static ACC_AdditionalInfo__c createAdditionalInfo(Id accountId, String rtDevName, String name, Boolean isInsert) {
        String infoName = String.isNotBlank(name) ? name : 'Info_' + COM_TestDataFactory.generateRandomString(5);
        Id rtId = Schema.SObjectType.ACC_AdditionalInfo__c.getRecordTypeInfosByDeveloperName().get(rtDevName).getRecordTypeId();

        Map<Schema.SObjectField, Object> fields = new Map<Schema.SObjectField, Object>{
            ACC_AdditionalInfo__c.Account_lk__c => accountId,
            ACC_AdditionalInfo__c.RecordTypeId => rtId,
            ACC_AdditionalInfo__c.Name => infoName
        };
        return (ACC_AdditionalInfo__c) COM_TestDataFactory.createSObject('ACC_AdditionalInfo__c', fields, isInsert);
    }

    /**
     * @description Create Bank Information (ACC_AdditionalInfo__c)
     * @param accountId (Id): Parent Account Id
     * @param isInsert (Boolean): Insert flag
     * @return ACC_AdditionalInfo__c
     */
    public static ACC_AdditionalInfo__c createBankInfo(Id accountId, Boolean isInsert) {
        return createAdditionalInfo(accountId, 'BankInformation', null, isInsert);
    }

    /**
     * @description Create Security Information (ACC_AdditionalInfo__c)
     * @param accountId (Id): Parent Account Id
     * @param isInsert (Boolean): Insert flag
     * @return ACC_AdditionalInfo__c
     */
    public static ACC_AdditionalInfo__c createSecurityInfo(Id accountId, Boolean isInsert) {
        return createAdditionalInfo(accountId, 'Security', null, isInsert);
    }
}