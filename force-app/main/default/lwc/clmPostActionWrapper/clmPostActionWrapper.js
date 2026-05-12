/**********************************************************************************
 * @filename      : clmPostActionWrapper.js
 * @project-name  : LK Insurance Services
 * @author        : i2max
 * @date          : 2026-03-25
 * @description   : CLM Post Quick Action 등록용 Wrapper 컴포넌트
 *                  Quick Action 'Post'에 등록되며, mode="POST"로 ClmQuickAction에 위임
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-25      i2max              Create
 **********************************************************************************/
import { LightningElement, api } from "lwc";
import { CloseActionScreenEvent } from "lightning/actions";
import { RefreshEvent } from "lightning/refresh";

export default class ClmPostActionWrapper extends LightningElement {
    // ========== API 속성 ==========
    @api recordId;

    // ========== 이벤트 핸들러 ==========
    handleActionComplete() {
        this.dispatchEvent(new RefreshEvent());
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}