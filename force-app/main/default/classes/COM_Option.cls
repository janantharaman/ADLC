/**********************************************************************************
 * @filename      : COM_Option.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-11-18 (화)
 * @group         :
 * @group-content :
 * @description   : Select Option 공통 클래스
 * @test-class    : COM_Option_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-11-18      i2max     Create
**********************************************************************************/
public with sharing class COM_Option {

    @AuraEnabled public String label  { get; set; }
    @AuraEnabled public String value  { get; set; }
    @AuraEnabled public Boolean selected { get; set; }
    @AuraEnabled public String subLabel { get; set; }

    public COM_Option(String label, String value) {
        this.label    = label;
        this.value    = value;
        this.selected = false;
    }
    public COM_Option(String label, String value, String subLabel) {
        this(label, value);
        this.subLabel = subLabel;
    }

}