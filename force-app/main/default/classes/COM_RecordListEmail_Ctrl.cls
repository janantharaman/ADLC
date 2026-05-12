/**********************************************************************************
 * @filename      : COM_RecordListEmail_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-09 (월)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : COM_RecordListEmail_Ctrl_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-09      i2max     Create
**********************************************************************************/
public with sharing class COM_RecordListEmail_Ctrl {

    public String recipientName { get; set; }
    public String recipientId { get; set; }
    public String recordUrl { get; set; }

    public COM_RecordListEmail_Ctrl() {
        recipientName = ApexPages.currentPage().getParameters().get('recipientName');
        recipientId = ApexPages.currentPage().getParameters().get('recipientId');
        String recordId = ApexPages.currentPage().getParameters().get('recordId');
        recordUrl = Url.getOrgDomainUrl().toExternalForm() + '/' + recordId;
    }

}