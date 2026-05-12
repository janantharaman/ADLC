/**********************************************************************************
 * @filename      : ContentDocument.trigger
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-15 (목)
 * @sobjects      : ContentDocument
 * @events        : before delete
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : ContentDocument_tr_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-15      i2max     Create
**********************************************************************************/
trigger ContentDocument on ContentDocument (before delete) {
    new COM_ContentDocument_tr().run();
}