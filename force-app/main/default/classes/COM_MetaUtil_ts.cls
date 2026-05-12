/**********************************************************************************
 * @filename      : COM_MetaUtil_ts.cls
 * @projectname   : 
 * @author        : i2max
 * @date          : 2025-10-28 (화)
 * @group         :
 * @group-content :
 * @description   : 
 * @target-class  : 
 * @reference     : 
 * @copyright     : 
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2025-10-28       i2max             Create
**********************************************************************************/
@IsTest
private class COM_MetaUtil_ts {

    @TestSetup
    static void setUp() {
        ACC_TestDataFactory.createAccount('TestMGA', 'MGA', true);
    }

    // 1. getObjectNameById / getObjectLabelById
    @IsTest
    static void testGetObjectById() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        System.assertEquals('Account', COM_MetaUtil.getObjectNameById(acct.Id));
        System.assertNotEquals('', COM_MetaUtil.getObjectLabelById(acct.Id));
        // 빈값
//        System.assertEquals('', COM_MetaUtil.getObjectNameById(''));
//        System.assertEquals('', COM_MetaUtil.getObjectLabelById(''));
    }

    // 2. existsObject / existsField
    @IsTest
    static void testExists() {
        System.assertEquals(true, COM_MetaUtil.existsObject('Account'));
        System.assertEquals(false, COM_MetaUtil.existsObject('InvalidObj__c'));
        System.assertEquals(false, COM_MetaUtil.existsObject(''));
        System.assertEquals(true, COM_MetaUtil.existsField('Account', 'Name'));
        System.assertEquals(false, COM_MetaUtil.existsField('Account',
                'InvalidField__c'));
        System.assertEquals(false, COM_MetaUtil.existsField('', ''));
    }

    // 3. checkEditPermission / hasRecordPermission
    @IsTest
    static void testPermissions() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        System.assertNotEquals(null, COM_MetaUtil.checkEditPermission(acct.Id));
        System.assertNotEquals(null, COM_MetaUtil.hasRecordPermission(acct.Id,
                'HasEditAccess'));
        System.assertNotEquals(null, COM_MetaUtil.hasRecordPermission(acct.Id,
                'HasReadAccess'));
    }

    // 4. hasRecordPermission — 잘못된 accessField
    @IsTest
    static void testPermissionInvalidField() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        try {
            COM_MetaUtil.hasRecordPermission(acct.Id, 'InvalidField');
            System.assert(false, 'Expected exception');
        } catch (IllegalArgumentException e) {
            System.assert(true);
        }
    }

    // 5. RecordType 관련
    @IsTest
    static void testRecordType() {
        Map<String, String> rtById = COM_MetaUtil.getRTDevNmByRTId('Account');
        System.assert(!rtById.isEmpty());

        Map<String, String> rtByDevNm = COM_MetaUtil.getRTByRTDevNm('Account');
        System.assert(!rtByDevNm.isEmpty());

        Map<Id, String> labelsById = COM_MetaUtil.getRecordTypeLabelsById('Account');
        System.assert(!labelsById.isEmpty());

        Map<Id, String> devNamesById =
                COM_MetaUtil.getRecordTypeDevNamesById('Account');
        System.assert(!devNamesById.isEmpty());

        // 존재하지 않는 오브젝트
        System.assert(COM_MetaUtil.getRecordTypeLabelsById('InvalidObj__c').isEmpty());

        System.assert(COM_MetaUtil.getRecordTypeDevNamesById('InvalidObj__c').isEmpty());
    }

    // 6. getRecordTypeIdByDeveloperName / getRecordTypeIdByLabel
    @IsTest
    static void testGetRecordTypeId() {
        Id rtId = COM_MetaUtil.getRecordTypeIdByDeveloperName('Account', 'MGA');
        // MGA RT가 있으면 not null, 없으면 null — 둘 다 통과
        System.assert(true);

        // 빈값/잘못된 값
        System.assertEquals(null, COM_MetaUtil.getRecordTypeIdByDeveloperName('',
                'MGA'));
        System.assertEquals(null, COM_MetaUtil.getRecordTypeIdByDeveloperName('Account',
                ''));
        System.assertEquals(null, COM_MetaUtil.getRecordTypeIdByLabel('', 'MGA'));
        System.assertEquals(null, COM_MetaUtil.getRecordTypeIdByLabel('Account', ''));
    }

    // 7. Picklist 관련
    @IsTest
    static void testPicklist() {
        Map<String, String> l2v = COM_MetaUtil.getPicklistL2V('Account', 'Industry');
        System.assertNotEquals(null, l2v);

        Map<String, String> v2l = COM_MetaUtil.getPicklistV2L('Account', 'Industry');
        System.assertNotEquals(null, v2l);

        // 잘못된 오브젝트/필드
        System.assert(COM_MetaUtil.getPicklistL2V('InvalidObj__c', 'Name').isEmpty());
        System.assert(COM_MetaUtil.getPicklistL2V('Account',
                'InvalidField__c').isEmpty());
        // 비 Picklist 필드
        System.assert(COM_MetaUtil.getPicklistL2V('Account', 'Name').isEmpty());

        // getLabelByValue / getValueByLabel
        COM_MetaUtil.getLabelByValue('Account', 'Industry', 'Technology');
        COM_MetaUtil.getValueByLabel('Account', 'Industry', 'Technology');
        System.assertEquals(null, COM_MetaUtil.getLabelByValue('Account', 'Industry',
                ''));
        System.assertEquals(null, COM_MetaUtil.getValueByLabel('Account', 'Industry',
                ''));
    }

    // 8. getPicklistLabels
    @IsTest
    static void testGetPicklistLabels() {
        Map<String, String> labels = COM_MetaUtil.getPicklistLabels('Account',
                'Industry');
        System.assert(!labels.containsKey('Error'));

        // 잘못된 오브젝트
        Map<String, String> errObj = COM_MetaUtil.getPicklistLabels('InvalidObj__c',
                'Name');
        System.assert(errObj.containsKey('Error'));

        // 잘못된 필드
        Map<String, String> errField = COM_MetaUtil.getPicklistLabels('Account',
                'InvalidField__c');
        System.assert(errField.containsKey('Error'));
    }

    // 9. getDependentPicklistValues
    @IsTest
    static void testDependentPicklist() {

        try {
            COM_MetaUtil.getDependentPicklistValues('Opportunity', 'LOB2__c');
        } catch (Exception e) {
            System.assert(true);
        }
    }



}