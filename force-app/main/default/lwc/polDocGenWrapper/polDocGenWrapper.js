/**********************************************************************************
 * @filename      : polDocGenWrapper.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-04-22 (수)
 * @group         :
 * @group-content :
 * @description   : Policy 문서 생성 Quick Action Wrapper 컴포넌트
 *                  - Quick Action 종료 시 모달을 닫고,
 *                  - 현재 페이지로 다시 Navigate 처리한다.
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

export default class PolDocGenWrapper extends NavigationMixin(LightningElement) {
    // Public Properties
    @api recordId;
    @api objectApiName;

    // Wire Methods
    @wire(CurrentPageReference)
    pageRef;

    // Event Handlers

    /**
     * @description Quick Action 모달을 닫고 현재 페이지로 다시 Navigate 한다.
     * @return {void}
     */
    handleClose() {
        this.dispatchEvent(new CloseActionScreenEvent());

        if (this.pageRef) {
            this[NavigationMixin.Navigate](this.pageRef);
        }
    }
}