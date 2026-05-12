/**********************************************************************************
 * @filename       : oppRIOfferDocGen.js
 * @project-name  : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-13 (금)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-13     i2max      Create
 **********************************************************************************/

import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";

export default class OppRiOfferDocGen extends LightningElement {
    @api recordId;
    @api objectApiName;

    // OmniScript 설정
    omniScriptType = "RIDocument";
    omniScriptSubType = "SlipInfo";
    omniScriptLang = "English";

    get seedDataJson() {
        if (!this.recordId) {
            return JSON.stringify({});
        }

        return JSON.stringify({
            ContextId: this.recordId,
            ObjectType: this.objectApiName || "Unknown"
        });
    }

    /**
     * OmniScript 완료 핸들러
     */
    handleOmniScriptComplete(event) {
        console.log("OmniScript completed:", event.detail);

        this.showToast("Success", "Document generated successfully", "success");

        // Quick Action 창 닫기
        this.closeQuickAction();
    }

    /**
     * Quick Action 닫기
     */
    closeQuickAction() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /**
     * Toast 메시지 표시
     */
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(event);
    }

    /**
     * 컴포넌트 초기화
     */
    connectedCallback() {
        console.log("TearSheetQuickAction initialized");
        console.log("RecordId:", this.recordId);
        console.log("ObjectApiName:", this.objectApiName);
    }
}