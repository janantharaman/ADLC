/**********************************************************************************
 * @filename      : oppRQDocgenWrapper.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-04-22 (수)
 * @group         :
 * @group-content :
 * @description   : Opportunity RQ Docgen Wrapper LWC 컴포넌트
 *                  - Quick Action 닫기 처리 후,
 *                  - 현재 페이지 참조 정보를 기준으로 화면 이동을 수행한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-04-22       i2max             Create
 **********************************************************************************/

// LWC
import { LightningElement, api, wire } from "lwc";

// Lightning Actions
import { CloseActionScreenEvent } from "lightning/actions";

// Navigation
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";

export default class OppRQDocgenWrapper extends NavigationMixin(LightningElement) {
    // Public Properties
    @api recordId;
    @api objectApiName;

    // Wire Properties
    @wire(CurrentPageReference)
    pageRef;

    // Event Handlers

    /**
     * @description Quick Action 창을 닫고 현재 페이지 참조 정보가 있으면 해당 페이지로 이동한다.
     * @return {void}
     */
    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());

        if (this.pageRef) {
            this[NavigationMixin.Navigate](this.pageRef);
        }
    }
}