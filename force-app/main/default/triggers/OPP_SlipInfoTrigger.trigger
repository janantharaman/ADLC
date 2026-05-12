/**********************************************************************************
 * @filename      : OPP_SlipInfoTrigger.cls
 * @projectname   :
 * @author        : i2max
 * @date          : 2026-02-02 (월)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : OPP_SlipInfoTrigger_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-02      i2max            Create
**********************************************************************************/

trigger OPP_SlipInfoTrigger on OPP_SlipInfo__c (before insert, after insert, before update) {
   new OPP_SlipInfo_tr().run();
}