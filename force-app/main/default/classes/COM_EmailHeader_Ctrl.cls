/**********************************************************************************
 * @filename      : COM_EmailHeader_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-02 (월)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : COM_EmailHeader_Ctrl_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-02      i2max     Create
**********************************************************************************/
public with sharing class COM_EmailHeader_Ctrl {

    public Id recipientId { get; set; }

    // User 정보를 담을 변수
    public User recipientUser {
        get {
            if (recipientUser == null && recipientId != null) {

                List<User> users = [SELECT Id, Name, Region__c FROM User WHERE Id = :recipientId LIMIT 1];
                if (!users.isEmpty()) {
                    recipientUser = users[0];
                }
            }
            return recipientUser;
        }
        private set;
    }


}