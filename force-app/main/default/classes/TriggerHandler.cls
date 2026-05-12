/**********************************************************************************
 * @filename      : TriggerHandler.cls
 * @projectname   : 
 * @author        : i2max
 * @date          : 2025-10-30 (목)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : TriggerHandler_ts.cls
 * @reference     : 
 * @copyright     : 
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-10-30      i2max     Create
**********************************************************************************/
public virtual inherited sharing class TriggerHandler {

    @TestVisible private static Map<String, LoopCount> loopCountMap = new Map<String, LoopCount>();
    @TestVisible private static Set<String> bypassedHandlers = new Set<String>();
    @TestVisible private static Set<Id> processedIds = new Set<Id>();

    @TestVisible private System.TriggerOperation op;
    @TestVisible private Boolean isTriggerExecuting;

    public TriggerHandler() { setTriggerContext(); }

    public void run() {
        if (!validateRun()) return;
        addToLoopCount();
        switch on op {
            when BEFORE_INSERT   { beforeInsert(); }
            when BEFORE_UPDATE   { beforeUpdate(); }
            when BEFORE_DELETE   { beforeDelete(); }
            when AFTER_INSERT    { afterInsert(); }
            when AFTER_UPDATE    { afterUpdate(); }
            when AFTER_DELETE    { afterDelete(); }
            when AFTER_UNDELETE  { afterUndelete(); }
            when else            { }
        }
    }

    // 타입 기준 루프 한도 (인스턴스 한도 제거)
    public void setMaxLoopCount(Integer max) {
        String tk = getHandlerTypeKey();
        loopCountMap.put(tk, new LoopCount(max));
        loopCountMap.put(simpleName(tk), new LoopCount(max));
    }
    public void clearMaxLoopCount() {
        String tk = getHandlerTypeKey();
        loopCountMap.remove(tk);
        loopCountMap.remove(simpleName(tk));
    }

    // ===== static helpers =====
    public static void bypass(String handlerTypeKey) {
        String k = norm(handlerTypeKey);
        bypassedHandlers.add(k);
        bypassedHandlers.add(simpleName(k));
    }
    public static void clearBypass(String handlerTypeKey) {
        String k = norm(handlerTypeKey);
        bypassedHandlers.remove(k);
        bypassedHandlers.remove(simpleName(k));
    }
    public static Boolean isBypassed(String handlerTypeKey) {
        String k = norm(handlerTypeKey);
        return bypassedHandlers.contains(k) || bypassedHandlers.contains(simpleName(k));
    }

    public static void bypass(Type handlerType) {
        String k = typeKeyFromType(handlerType);
        bypassedHandlers.add(k);
        bypassedHandlers.add(simpleName(k));
    }
    public static void clearBypass(Type handlerType) {
        String k = typeKeyFromType(handlerType);
        bypassedHandlers.remove(k);
        bypassedHandlers.remove(simpleName(k));
    }
    public static Boolean isBypassed(Type handlerType) {
        String k = typeKeyFromType(handlerType);
        return bypassedHandlers.contains(k) || bypassedHandlers.contains(simpleName(k));
    }

    public static void clearAllBypasses() { bypassedHandlers.clear(); }

    public static void setMaxLoopCount(Type t, Integer max) {
        String k = typeKeyFromType(t);
        loopCountMap.put(k, new LoopCount(max));
        loopCountMap.put(simpleName(k), new LoopCount(max));
    }

    // ===== test support =====
    @TestVisible private static void reset() {
        loopCountMap.clear(); bypassedHandlers.clear(); processedIds.clear();
    }
    @TestVisible private void setContextForTest(System.TriggerOperation injectedOp) {
        this.isTriggerExecuting = true; this.op = injectedOp;
    }

    // ===== extension hooks =====
    @TestVisible protected virtual void beforeInsert()   {}
    @TestVisible protected virtual void beforeUpdate()   {}
    @TestVisible protected virtual void beforeDelete()   {}
    @TestVisible protected virtual void afterInsert()    {}
    @TestVisible protected virtual void afterUpdate()    {}
    @TestVisible protected virtual void afterDelete()    {}
    @TestVisible protected virtual void afterUndelete()  {}


    // ===== helpers =====
    protected Boolean changedAny(final SObject n, final SObject o, final List<SObjectField> fs) {
        if (o == null || fs == null) return false;
        for (SObjectField f : fs) if (n.get(f) != o.get(f)) return true;
        return false;
    }
    protected Boolean changedAll(final SObject n, final SObject o, final List<SObjectField> fs) {
        if (o == null || fs == null || fs.isEmpty()) return false;
        for (SObjectField f : fs) if (n.get(f) == o.get(f)) return false;
        return true;
    }
    protected Boolean markProcessed(final Id recordId) {
        if (recordId == null) return false;
        if (processedIds.contains(recordId)) return false;
        processedIds.add(recordId); return true;
    }

    // ===== private =====
    @TestVisible private void setTriggerContext() {
        if (!Trigger.isExecuting) { this.isTriggerExecuting = false; return; }
        this.isTriggerExecuting = true; this.op = Trigger.operationType;
    }

    @TestVisible private void addToLoopCount() {
        String tk = getHandlerTypeKey();
        // 정확 매칭 또는 심플 네임 매칭
        LoopCount lc = loopCountMap.get(tk);
        if (lc == null) lc = loopCountMap.get(simpleName(tk));
        if (lc != null && lc.increment()) {
            Integer max = lc.max;
            throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + tk);
        }
    }

    @TestVisible private Boolean validateRun() {
        if (!this.isTriggerExecuting || this.op == null) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        String tk = getHandlerTypeKey();
        if (bypassedHandlers.contains(tk) || bypassedHandlers.contains(simpleName(tk))) return false;
        return true;
    }

    // 인스턴스 → 타입 키
    @TestVisible private String getHandlerTypeKey() {
        String s = String.valueOf(this);
        Integer idx = s.indexOf(':');
        s = (idx > 0) ? s.substring(0, idx) : s;
        return norm(s);
    }

    // Type → 타입 키
    @TestVisible private static String typeKeyFromType(Type t){
        return norm(String.valueOf(t));
    }

    // 키 정규화: 'Class.' 제거, 내부클래스 구분자 '$' → '.'
    @TestVisible private static String norm(String s){
        if (s == null) return null;
        if (s.startsWith('Class.')) s = s.substring(6);
        s = s.replace('$','.');
        return s;
    }
    @TestVisible private static String simpleName(String s){
        if (s == null) return null;
        Integer dot = s.lastIndexOf('.');
        return dot >= 0 ? s.substring(dot+1) : s;
    }

    @TestVisible private class LoopCount {
        private Integer max; private Integer count;
        public LoopCount()          { this.max = 1; this.count = 0; }
        public LoopCount(Integer m) { this.max = (m == null ? 1 : m); this.count = 0; }
        public Boolean increment()  { this.count++; return (max > 0 && count > max); }
        public LoopCount withMax(Integer m){ this.max = (m == null ? this.max : m); return this; }
    }

    public class TriggerHandlerException extends Exception {}
}