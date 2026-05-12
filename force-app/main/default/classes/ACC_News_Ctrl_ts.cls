/**********************************************************************************
 * @filename      : OPP_MarketLineConverter_ts.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-08 (일)
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
 * 1.0   2026-03-08      i2max     Create
**********************************************************************************/
@IsTest
private class ACC_News_Ctrl_ts {
    @IsTest
    static void testBehavior() {
        Account acc = (Account) COM_TestDataFactory.createSObject('Account', new Map<String, Object>{
                'Name' => 'Test Account'
        }, true);
        ACC_News_Ctrl.getNewsByAccountId(acc.Id, 100);
    }
}