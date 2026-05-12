/**
 * ExceptionSimulator — Zero-cost exception injection for catch-block coverage.
 *
 * Production methods call throwIfActive() at the start of try blocks.
 * In normal (non-test) execution this is a no-op.
 * In test context, when active == true, it throws a SimulatedException
 * so the surrounding catch block executes and gets covered.
 *
 * Usage (production controller):
 *   try {
 *       ExceptionSimulator.throwIfActive();
 *       // ...normal logic...
 *   } catch (Exception e) {
 *       throw new AuraHandledException(e.getMessage());
 *   }
 *
 * Usage (test class):
 *   ExceptionSimulator.active = true;
 *   try {
 *       MyController.someMethod(validArgs);
 *       Assert.fail('Expected AuraHandledException');
 *   } catch (AuraHandledException e) { }
 */
public class ExceptionSimulator {
    @TestVisible
    static Boolean active = false;

    public static void throwIfActive() {
        if (Test.isRunningTest() && active) {
            active = false;
            throw new SimulatedException('Simulated exception for catch-block coverage');
        }
    }

    public class SimulatedException extends Exception {
    }
}