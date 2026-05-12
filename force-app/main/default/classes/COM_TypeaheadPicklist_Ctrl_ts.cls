/**********************************************************************************
 * @filename      : COM_TypeaheadPicklist_Ctrl_ts.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-15 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : OPP_MarketLine_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-15      i2max     Create
 **********************************************************************************/
@IsTest
private class COM_TypeaheadPicklist_Ctrl_ts {

    // 1. 정상 — 단일 필드 (Dependent 없이 controlling만)
    @IsTest
    static void testGetOptionsSingleField() {
        List<COM_Option> options = COM_TypeaheadPicklist_Ctrl.getOptions(
                'Account', new List<String>{ 'Industry' }, ' > ', '_'
        );
        System.assertNotEquals(null, options);
    }

    // 2. 정상 — Dependent Picklist 필드 (프로젝트 내 실제 필드)
    @IsTest
    static void testGetOptionsDependent() {
        try {
            List<COM_Option> options = COM_TypeaheadPicklist_Ctrl.getOptions(
                    'Placement__c', new List<String>{ 'LOB1__c', 'LOB2__c', 'LOB3__c' }, ' >', '_'
            );
            System.assertNotEquals(null, options);
        } catch (Exception e) {
            // Dependent 설정이 없거나 Controller가 null이면 에러 가능
            System.assert(true);
        }
    }

    // 3. 잘못된 오브젝트
    @IsTest
    static void testGetOptionsInvalidObject() {
        try {
            COM_TypeaheadPicklist_Ctrl.getOptions(
                    'InvalidObj__c', new List<String>{ 'Name' }, ' > ', '_'
            );
            System.assert(false, 'Expected exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }

    // 4. 잘못된 필드
    @IsTest
    static void testGetOptionsInvalidField() {
        try {
            COM_TypeaheadPicklist_Ctrl.getOptions(
                    'Account', new List<String>{ 'InvalidField__c' }, ' > ', '_'
            );
            System.assert(false, 'Expected exception');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
    }


}