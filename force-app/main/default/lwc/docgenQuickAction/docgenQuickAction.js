import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { CloseActionScreenEvent } from "lightning/actions";

export default class DocgenQuickAction extends LightningElement {
    // Quick Action에서 자동으로 주입되는 recordId
    @api recordId;

    // Object API Name (자동 주입)
    @api objectApiName;

    // OmniScript 설정
    omniScriptType = "RQ";
    omniScriptSubType = "Docgen";
    omniScriptLang = "Multi-Language";

    /**
     * OmniScript에 전달할 Context ID와 Object Type을 포함한 Seed Data
     */
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