/**********************************************************************************
 * @filename      : AdditionalAccountInfoTrigger.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2026-01-02 (금)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : AdditionalAccountInfoTrigger_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-12-23      i2max            Create
**********************************************************************************/

trigger AdditionalAccountInfoTrigger on ACC_AdditionalInfo__c (before insert) {
    new ACC_AdditionalAccountInfo_tr().run();
}