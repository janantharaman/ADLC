/**********************************************************************************
 * @filename      : Opportunity.trigger
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-10 (화)
 * @sobjects      : Opportunity
 * @events        : before insert, before update
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : OPP_Opportunity_tr_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-10      i2max     Create
 **********************************************************************************/
trigger Opportunity on Opportunity(before update) {
    new OPP_Opportunity_tr().run();
}