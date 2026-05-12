/**********************************************************************************
 * @filename      : COM_Util_ts.cls
 * @projectname   : 
 * @author        : i2max-wonjulee
 * @date          : 2025-10-27 (월)
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
 * 1.0   2025-10-27      i2max-wonjulee     Create
**********************************************************************************/
@IsTest
private class COM_Util_ts {

    @TestSetup
    static void setUp() {
        Account acc = (Account) COM_TestDataFactory.createSObject('Account', new Map<String, Object>{
                'Name' => 'Test Account'
        }, true);
    }

    @IsTest
    static void testBehavior() {
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Datetime now = Datetime.newInstance(Date.today().year(), 1, 1);
        Date toDay = now.date();
        String defaultVal = 'default';

        String objectName = 'Account';
        String fieldName = 'Type';

        System.assertEquals(1234.50, COM_Util.toDec('1,234.50', true));
        System.assertEquals(-42,     COM_Util.toDec('-42', false));
        System.assertEquals(null,    COM_Util.toDec('1.2', false));
        System.assertEquals(null,    COM_Util.toDec('abc', true));

        // null → 0
        Assert.areEqual(0, COM_Util.toDec((Object) null));

        // Decimal 인스턴스 → 그대로 캐스팅
        Assert.areEqual(123.45, COM_Util.toDec((Object) 123.45));

        // Integer → Decimal 변환
        Assert.areEqual(100, COM_Util.toDec((Object) 100));

        // String → 기존 toDec(String) 재사용
        Assert.areEqual(50, COM_Util.toDec((Object) '50'));

        // suffix 포함 문자열 → suffix 제거 후 변환
        Assert.areEqual(100, COM_Util.toDec((Object) '100-'));


        System.assertEquals(123,    COM_Util.toIntOrZero('123'));
        System.assertEquals(0,    COM_Util.toIntOrZero(''));

        System.assertEquals('',    COM_Util.nvl('', '1'));
        System.assertEquals(0,    COM_Util.nvl(0, 1));
        System.assertEquals(0,    COM_Util.nvl((Long) 0, (Long)1));
        System.assertEquals(0,    COM_Util.nvl((Decimal) 0, (Decimal)1));
        System.assertEquals(0,    COM_Util.nvl((Double) 0, (Double)1));
        System.assertEquals(false,    COM_Util.nvl(null, false));
        System.assertEquals(toDay,    COM_Util.nvl(toDay, null));
        System.assertEquals(now,    COM_Util.nvl(now, null));
        System.assertEquals(acct.Id,    COM_Util.nvl(null, acct.Id));
        System.assertEquals(null,    COM_Util.nvl((Object) null, null));
        System.assertEquals(1.23, COM_Util.NVL((Decimal) 1.23));
        System.assertEquals('default',    COM_Util.nvlBlank(null, defaultVal));
        Assert.areEqual('default', COM_Util.nvl(null, defaultVal));
        Assert.areEqual('value', COM_Util.nvl('value', defaultVal));
        System.assertEquals(null,    COM_Util.nvl2(null, defaultVal, null));
        System.assertEquals((Decimal) null,    COM_Util.nvl2((Decimal) null, (Decimal) null, (Decimal) null));
        System.assertEquals((Integer) null,    COM_Util.nvl2((Integer) null, (Integer) null, (Integer) null));
        System.assertEquals((Boolean) null,    COM_Util.nvl2((Boolean) null, (Boolean) null, (Boolean) null));
        System.assertEquals((Date) null,    COM_Util.nvl2((Date) null, (Date) null, (Date) null));
        System.assertEquals((Datetime) null,    COM_Util.nvl2((Datetime) null, (Datetime) null, (Datetime) null));
        System.assertEquals((Object) null,    COM_Util.nvl2((Object) null, (Object) null, (Object) null));

        Assert.isNotNull(COM_Util.coalesce('3', '3', '3'));
        System.assertEquals((Decimal) null,    COM_Util.coalesce((Decimal) null, (Decimal) null, (Decimal) null));
        System.assertEquals((Integer) null,    COM_Util.coalesce((Integer) null, (Integer) null, (Integer) null));

        Assert.isNotNull(COM_Util.getOrgName());
        Assert.isNotNull(COM_Util.isSandbox());

        Assert.isNotNull(COM_Util.getPickList(objectName, fieldName));
        Assert.isNotNull(COM_Util.makePickListOptions(objectName, fieldName, false));
        Assert.isNotNull(COM_Util.makePickListOptions(objectName, fieldName, false, true, new Set<String>{'A'}));
        Assert.areEqual(1, COM_Util.makeInitOptions('전체').size());

        Assert.isNotNull(COM_Util.divide(10, 2, 2, RoundingMode.HALF_UP));
        Assert.isNotNull(COM_Util.getDateYYMMDD(toDay));
        Assert.isNotNull(COM_Util.removeHtmlTagsExceptBr('Test<ol><li>temp</li></ol>'));

        Assert.isNotNull(COM_Util.randomStr(3));
        Assert.isNotNull(COM_Util.randomNum(3));
        Assert.isNotNull(COM_Util.toStr('3'));
        Assert.isNotNull(COM_Util.toDec('3000-'));
        Assert.isNotNull(COM_Util.toInteger('3'));
        Assert.isTrue(COM_Util.toBoolean('Y'));
        Assert.isNotNull(COM_Util.boolConStr(true));
        Assert.isNotNull(COM_Util.toDate(toDay.toString()));
        Assert.isNotNull(COM_Util.toDateTime('20250101120000'));
        Assert.isNotNull(COM_Util.toDateTime('20250101', '000000'));
        Assert.isNull(COM_Util.toDate('2025ABCD'));
        
        // toDec2
        Assert.areEqual(3000, COM_Util.toDec2('3000-'));
        Assert.areEqual(0, COM_Util.toDec2(null));
        Assert.areEqual(100, COM_Util.toDec2('100_'));
        Assert.areEqual(200, COM_Util.toDec2('200,'));

        // coalesce(List<Object>)
        Assert.areEqual('a', COM_Util.coalesce(new List<Object>{ null, 'a', 'b' }));
        Assert.areEqual(null, COM_Util.coalesce((List<Object>) null));
        Assert.areEqual(null, COM_Util.coalesce(new List<Object>{ null, null }));

        // getMapStr
        Map<String, Object> m = new Map<String, Object>{ 'key1' => 'value1', 'key2' => null };
        Assert.areEqual('value1', COM_Util.getMapStr(m, 'key1'));
        Assert.areEqual(null, COM_Util.getMapStr(m, 'key2'));
        Assert.areEqual(null, COM_Util.getMapStr(m, 'nokey'));

        // toId
        Assert.areEqual(acct.Id, COM_Util.toId(acct.Id));
        Assert.areEqual(null, COM_Util.toId(''));
        Assert.areEqual(null, COM_Util.toId(null));

        // makePickListOptions 4파라미터 (isSelectAll=true)
        List<COM_Option> opts = COM_Util.makePickListOptions('Account', 'Type', false, true);
        Assert.isNotNull(opts);

        // toDec(Object) — Long, Double 분기
        Assert.areEqual(100, COM_Util.toDec((Object) 100L));
        Assert.areEqual(3.14, COM_Util.toDec((Object) 3.14));

    }

}