/**********************************************************************************
 * @filename      : comNoRecords.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-26 (목)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-26      i2max      Create
 **********************************************************************************/
import { LightningElement, api } from 'lwc';
import COM_MSG_NORECORDS from '@salesforce/label/c.COM_MSG_NORECORDS';

export default class ComNoRecords extends LightningElement {
    @api colspan = 99;
    @api message = COM_MSG_NORECORDS;
}