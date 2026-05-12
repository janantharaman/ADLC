/**********************************************************************************
 * @filename      : COM_Option_ts.cls
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
private class COM_Option_ts {

    @IsTest
    static void testBehavior() {
        COM_Option option = new COM_Option('테스트라벨', 'testValue');
        COM_Option option2 = new COM_Option('테스트라벨', 'testValue', 'sub');

        Assert.areEqual('테스트라벨', option.label);
        Assert.areEqual('testValue', option.value);
        Assert.areEqual('sub', option2.subLabel);
        Assert.areEqual(false, option.selected);
    }


}