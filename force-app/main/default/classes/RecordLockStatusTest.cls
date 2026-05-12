@isTest
public class RecordLockStatusTest {

    @isTest
    static void testRecordLockStatus() {
        Account acc1 = new Account(Name='Test1');
        insert acc1;
        
        Account acc2 = new Account(Name='Test2');
        insert acc2;

        // Lock one of the records
        Approval.LockResult lockResult = Approval.lock(acc1.Id);

        // Verify lock status after locking
        List<Boolean> lockStatusAfter = RecordLockStatus.checkRecordLockStatus(new List<String>{acc1.Id, acc2.Id});
        System.assertEquals(true, lockStatusAfter[0]);
        System.assertEquals(false, lockStatusAfter[1]);

    }
}