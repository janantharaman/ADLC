/**********************************************************************************
 * @filename      : COM_FileList_Ctrl_ts.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-18 (수)
 * @group         :
 * @group-content :
 * @description   : 
 * @target-class  : 
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-18      i2max     Create
**********************************************************************************/
@IsTest
private class COM_FileList_Ctrl_ts {

    @TestSetup
    static void setup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        ContentVersion cv = new ContentVersion(
                Title = 'TestFile',
                PathOnClient = 'TestFile.pdf',
                VersionData = Blob.valueOf('Test'),
                RelFiles__Category__c = 'SOA'
        );
        insert cv;

        Id docId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
        insert new ContentDocumentLink(
                ContentDocumentId = docId,
                LinkedEntityId = acc.Id,
                ShareType = 'V'
        );
    }

    @IsTest
    static void testGetFiles() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> result = COM_FileList_Ctrl.getFiles(acc.Id, 'SOA');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'Should return files');
        System.assertEquals('TestFile.pdf', result[0].get('Title'));
    }

    @IsTest
    static void testGetFilesAll() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> result = COM_FileList_Ctrl.getFiles(acc.Id, 'ALL');
        Test.stopTest();

        System.assert(!result.isEmpty(), 'ALL should return all files');
    }

    @IsTest
    static void testGetFilesNoCategory() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        List<Map<String, Object>> result = COM_FileList_Ctrl.getFiles(acc.Id, '');
        Test.stopTest();

        System.assert(result.isEmpty(), 'Empty category should return only uncategorized files');
    }

    @IsTest
    static void testGetFilesNullRecordId() {
        try {
            COM_FileList_Ctrl.getFiles(null, 'SOA');
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    @IsTest
    static void testDeleteFiles() {
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        Test.startTest();
        COM_FileList_Ctrl.deleteFiles(new List<Id>{ cv.ContentDocumentId });
        Test.stopTest();

        System.assertEquals(0, [SELECT COUNT() FROM ContentDocument WHERE Id = :cv.ContentDocumentId]);
    }

    @IsTest
    static void testDeleteFilesFails() {
        ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion LIMIT 1];

        User u = COM_TestDataFactory.createMinAccessUser(true);

        Boolean thrown = false;
        System.runAs(u) {
            try {
                COM_FileList_Ctrl.deleteFiles(new List<Id>{ cv.ContentDocumentId });
            } catch (AuraHandledException e) {
                thrown = true;
            }
        }
        Assert.isTrue(thrown, 'SECURITY_ENFORCED must throw');
    }

    @IsTest
    static void testDeleteFilesEmpty() {
        try {
            COM_FileList_Ctrl.deleteFiles(new List<Id>());
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    @IsTest
    static void testUpdateCategory() {
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        Test.startTest();
        COM_FileList_Ctrl.updateCategory(new List<Id>{ cv.Id }, 'Slip');
        Test.stopTest();

        ContentVersion updated = [SELECT RelFiles__Category__c FROM ContentVersion WHERE Id = :cv.Id];
        System.assertEquals('Slip', updated.RelFiles__Category__c);
    }

    @IsTest
    static void testUpdateCategoryAll() {
        ContentVersion cv = [SELECT Id FROM ContentVersion LIMIT 1];

        Test.startTest();
        COM_FileList_Ctrl.updateCategory(new List<Id>{ cv.Id }, 'ALL');
        Test.stopTest();

        ContentVersion updated = [SELECT RelFiles__Category__c FROM ContentVersion WHERE Id = :cv.Id];
        Assert.isNull(updated.RelFiles__Category__c);
    }
}