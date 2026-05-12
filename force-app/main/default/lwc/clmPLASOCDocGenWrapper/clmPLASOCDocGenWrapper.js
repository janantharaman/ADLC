/**********************************************************************************
 * @filename      : clmPLASOCDocGenWrapper.js
 * @project-name  : LK Insurance Services
 * @author        : i2max
 * @date          : 2026-03-25
 * @description   : CLM SOC/PLA Issue Quick Action 등록용 Wrapper 컴포넌트
 *                  Quick Action 'SOC/PLA Issue'에 등록되며, mode="PLA_SOC_ISSUE"로 ClmQuickAction에 위임
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-25      i2max              Create
 **********************************************************************************/
import { LightningElement, api, wire } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { NavigationMixin, CurrentPageReference } from "lightning/navigation";

export default class ClmPLASOCDocGenWrapper extends NavigationMixin(LightningElement) {
    // ========== API 속성 ==========
    @api recordId;

    // ========== Wire 메서드 ==========
    @wire(CurrentPageReference) pageRef;

    // ========== 이벤트 핸들러 ==========
    handleActionComplete() {
        this.dispatchEvent(new CloseActionScreenEvent());
        if (this.pageRef) {
            this[NavigationMixin.Navigate](this.pageRef);
        }
    }
}