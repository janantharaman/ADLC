/**********************************************************************************
 * @filename      : Account.trigger
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-30 (금)
 * @sobjects      : Account
 * @events        : before insert, before update
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : AccountHandler_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-30      i2max     Create
**********************************************************************************/
trigger Account on Account (before update, after insert, after update) {
    new Account_tr().run();
}