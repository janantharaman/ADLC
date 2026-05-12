/**********************************************************************************
 * @filename      : COM_EmailHeader_Ctrl_ts.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-17 (화)
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
 * 1.0   2026-03-17      i2max     Create
**********************************************************************************/
@IsTest
private class COM_EmailHeader_Ctrl_ts {

    // 1. recipientId 설정 → User 조회
    @IsTest
    static void testWithRecipientId() {
        COM_EmailHeader_Ctrl ctrl = new COM_EmailHeader_Ctrl();
        ctrl.recipientId = UserInfo.getUserId();
        System.assertNotEquals(null, ctrl.recipientUser);
        System.assertEquals(UserInfo.getUserId(), ctrl.recipientUser.Id);
    }

    // 2. recipientId 미설정 → null
    @IsTest
    static void testWithoutRecipientId() {
        COM_EmailHeader_Ctrl ctrl = new COM_EmailHeader_Ctrl();
        System.assertEquals(null, ctrl.recipientUser);
    }


}