/**********************************************************************************
 * @filename      : AccNewsItem.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-08 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-08       i2max             Create
 **********************************************************************************/
import {LightningElement, api} from 'lwc';

export default class AccNewsItem extends LightningElement {

    @api news;

    handleOpenLink(event) {
        event.preventDefault();
        const url = event.currentTarget.dataset.url;
        if (url) window.open(url, '_blank');
    }

}