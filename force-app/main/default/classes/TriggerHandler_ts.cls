/**********************************************************************************
 * @filename      : TriggerHandler_ts.cls
 * @project-name   :
 * @author        : i2max
 * @date          : 2025-10-30 (목)
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
 * 1.0   2025-10-30      i2max     Create
**********************************************************************************/
@IsTest
private class TriggerHandler_ts {

    private class TestHandler extends TriggerHandler {
        public Boolean isBi = false, isBu = false, isBd = false, isAi = false, isAu = false, isAd = false, isAuu = false;

        public Boolean changedAnyProxy(SObject n, SObject o, List<SObjectField> fs) {
            return changedAny(n, o, fs);
        }
        public Boolean changedAllProxy(SObject n, SObject o, List<SObjectField> fs) {
            return changedAll(n, o, fs);
        }
        public Boolean markProcessedProxy(Id rid) {
            return markProcessed(rid);
        }

        protected override void beforeInsert() {
            isBi = true;
        }
        protected override void beforeUpdate() {
            isBu = true;
        }
        protected override void beforeDelete() {
            isBd = true;
        }
        protected override void afterInsert() {
            isAi = true;
        }
        protected override void afterUpdate() {
            isAu = true;
        }
        protected override void afterDelete() {
            isAd = true;
        }
        protected override void afterUndelete() {
            isAuu = true;
        }
    }

    @IsTest
    static void run_switch_invokes_correct_hook() {
        TriggerHandler.reset();

        for (System.TriggerOperation op : new List<System.TriggerOperation>{
                System.TriggerOperation.BEFORE_INSERT,
                System.TriggerOperation.BEFORE_UPDATE,
                System.TriggerOperation.BEFORE_DELETE,
                System.TriggerOperation.AFTER_INSERT,
                System.TriggerOperation.AFTER_UPDATE,
                System.TriggerOperation.AFTER_DELETE,
                System.TriggerOperation.AFTER_UNDELETE
        }) {
            TriggerHandler triggerHandler = new TriggerHandler();
            triggerHandler.setContextForTest(op);
            triggerHandler.run();
        }
    }

    @IsTest
    static void bypass_by_type_and_clear() {
        TriggerHandler.reset();

        TriggerHandler.bypass(TestHandler.class);
        TestHandler testHandler = new TestHandler();
        testHandler.setContextForTest(System.TriggerOperation.AFTER_UPDATE);
        testHandler.run();
        System.assertEquals(false, testHandler.isAu);

        TriggerHandler.clearBypass(TestHandler.class);
        TestHandler testHandler2 = new TestHandler();
        testHandler2.setContextForTest(System.TriggerOperation.AFTER_UPDATE);
        testHandler2.run();
        System.assertEquals(true, testHandler2.isAu);
    }

    @IsTest
    static void loop_count_limits_and_reset() {
        TriggerHandler.reset();

        TestHandler testHandler = new TestHandler();
        testHandler.setMaxLoopCount(1);
        testHandler.setContextForTest(System.TriggerOperation.BEFORE_INSERT);
        testHandler.run();

        Boolean threw = false;
        try {
            testHandler.run();
        } catch (TriggerHandler.TriggerHandlerException e) {
            threw = true;
        }
        System.assertEquals(true, threw);

        TriggerHandler.reset();
        System.assertEquals(0, TriggerHandler.loopCountMap.size());
        System.assertEquals(0, TriggerHandler.bypassedHandlers.size());
        System.assertEquals(0, TriggerHandler.processedIds.size());
    }

    @IsTest
    static void static_setMaxLoopCount_by_type() {
        TriggerHandler.reset();

        TriggerHandler.setMaxLoopCount(TestHandler.class, 1);

        TestHandler testHandler = new TestHandler();
        testHandler.setContextForTest(System.TriggerOperation.AFTER_INSERT);
        testHandler.run();

        Boolean threw = false;
        try {
            TestHandler testHandler2 = new TestHandler();
            testHandler2.setContextForTest(System.TriggerOperation.AFTER_INSERT);
            testHandler2.run();
        } catch (TriggerHandler.TriggerHandlerException e) {
            threw = true;
        }
        System.assertEquals(true, threw);
    }

    @IsTest
    static void changed_helpers_work() {
        TriggerHandler.reset();
        TestHandler testHandler = new TestHandler();

        Account oldA = new Account(Name = 'Old');
        Account newA = new Account(Name = 'New');

        Boolean any1 = testHandler.changedAnyProxy(newA, oldA, new List<SObjectField>{
                Account.Name
        });
        Boolean all1 = testHandler.changedAllProxy(newA, oldA, new List<SObjectField>{
                Account.Name
        });
        System.assertEquals(true, any1);
        System.assertEquals(true, all1);

        Account oldB = new Account(Name = 'X', Phone = '1');
        Account newB = new Account(Name = 'X', Phone = '2');

        Boolean any2 = testHandler.changedAnyProxy(newB, oldB, new List<SObjectField>{
                Account.Name, Account.Phone
        });
        Boolean all2 = testHandler.changedAllProxy(newB, oldB, new List<SObjectField>{
                Account.Name, Account.Phone
        });
        System.assertEquals(true, any2);
        System.assertEquals(false, all2);
    }

    @IsTest
    static void markProcessed_prevents_duplicate_work() {
        TriggerHandler.reset();
        TestHandler testHandler = new TestHandler();

        Account a = new Account(Name = 'Proc');
        insert a;

        Boolean first = testHandler.markProcessedProxy(a.Id);
        Boolean second = testHandler.markProcessedProxy(a.Id);

        System.assertEquals(true, first);
        System.assertEquals(false, second);
    }

    @IsTest
    static void validateRun_outside_trigger_then_injected_context() {
        TriggerHandler.reset();

        Boolean threw = false;
        try {
            TestHandler testHandler = new TestHandler();
            testHandler.run();
        } catch (TriggerHandler.TriggerHandlerException e) {
            threw = true;
        }
        System.assertEquals(true, threw);

        TestHandler testHandler2 = new TestHandler();
        testHandler2.setContextForTest(System.TriggerOperation.AFTER_UNDELETE);
        testHandler2.run();
        System.assertEquals(true, testHandler2.isAuu);
    }

    @IsTest
    static void bypass_and_clear_with_simple_name() {
        TriggerHandler.reset();

        TriggerHandler.bypass('TestHandler'); // simpleName만 전달

        TriggerHandler_ts.TestHandler testHandler = new TriggerHandler_ts.TestHandler();
        testHandler.setContextForTest(System.TriggerOperation.AFTER_UPDATE);
        testHandler.run();
        System.assertEquals(false, testHandler.isAu, 'simpleName bypass가 적용되어야 함');

        TriggerHandler.clearBypass('TestHandler');
        TriggerHandler_ts.TestHandler testHandler2 = new TriggerHandler_ts.TestHandler();
        testHandler2.setContextForTest(System.TriggerOperation.AFTER_UPDATE);
        testHandler2.run();
        System.assertEquals(true, testHandler2.isAu, 'simpleName clearBypass 이후 실행되어야 함');
    }

    @IsTest
    static void clearMaxLoopCount_removes_both_keys() {
        TriggerHandler.reset();

        TriggerHandler_ts.TestHandler testHandler = new TriggerHandler_ts.TestHandler();
        testHandler.setContextForTest(System.TriggerOperation.BEFORE_INSERT);

        testHandler.setMaxLoopCount(1);
        testHandler.run(); // count=1

        // 한도 제거
        testHandler.clearMaxLoopCount();

        Boolean threw = false;
        try {
            testHandler.run();
        } catch (Exception e) {
            threw = true;
        }
        System.assertEquals(false, threw, 'clearMaxLoopCount 후에는 자유 실행');
    }

    @IsTest
    static void isBypassed_string_false_path() {
        TriggerHandler.reset();
        System.assertEquals(false, TriggerHandler.isBypassed('NotExistHandler'));
        System.assertEquals(false, TriggerHandler.isBypassed('TriggerHandler_ts.NotExistHandler'));
    }

    @IsTest
    static void clearAllBypasses_path() {
        TriggerHandler.reset();
        TriggerHandler.bypass(TriggerHandler_ts.TestHandler.class);
        System.assertEquals(true, TriggerHandler.isBypassed(TriggerHandler_ts.TestHandler.class));
        TriggerHandler.clearAllBypasses();
        System.assertEquals(false, TriggerHandler.isBypassed(TriggerHandler_ts.TestHandler.class));
    }

    @IsTest
    static void clearBypass_string_path(){
        TriggerHandler.reset();
        TriggerHandler.bypass('TestHandler');              // simpleName 저장
        System.assertEquals(true, TriggerHandler.isBypassed('TestHandler'));
        TriggerHandler.clearBypass('TestHandler');         // String 해제 경로
        System.assertEquals(false, TriggerHandler.isBypassed('TestHandler'));
    }

    @IsTest
    static void isBypassed_type_false_path(){
        TriggerHandler.reset();
        System.assertEquals(false, TriggerHandler.isBypassed(TriggerHandler_ts.TestHandler.class));
    }

    @IsTest
    static void class_prefix_and_dollar_norm_path(){
        TriggerHandler.reset();
        // 내부클래스 표기 케이스 강제
        TriggerHandler.bypass('Class.TriggerHandler_ts$TestHandler');
        // 풀네임/심플네임 양쪽 모두 인식되어야 함
        System.assertEquals(true, TriggerHandler.isBypassed(TriggerHandler_ts.TestHandler.class));
        System.assertEquals(true, TriggerHandler.isBypassed('TestHandler'));
        // 실행 차단 확인
        TriggerHandler_ts.TestHandler h = new TriggerHandler_ts.TestHandler();
        h.setContextForTest(System.TriggerOperation.AFTER_UPDATE);
        h.run();
        System.assertEquals(false, h.isAu);

    }




}