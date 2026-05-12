/**********************************************************************************
 * @filename      : comModal.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-12-09 (화)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2025-12-09      i2max      Create
 * 1.1   2025-12-19      i2max      Add hideFooter option
 * 1.2   2026-01-05      i2max      Add size control
 **********************************************************************************/
import { LightningElement, api } from "lwc";
import COM_BTN_CLOSE from '@salesforce/label/c.COM_BTN_CLOSE';
import COM_BTN_SAVE from '@salesforce/label/c.COM_BTN_SAVE';
import COM_BTN_CANCEL from '@salesforce/label/c.COM_BTN_CANCEL';

const SIZE_CLASS_MAP = {
    small: "slds-modal_small",
    medium: "slds-modal_medium",
    large: "slds-modal_large",
    full: "slds-modal_full",
};

export default class ComModal extends LightningElement {
    label = {
        COM_BTN_CLOSE,
        COM_BTN_CANCEL,
        COM_BTN_SAVE
    };
    // 📍 1. API 속성 (외부에서 설정 가능)
    @api title;
    @api cancelLabel = COM_BTN_CANCEL;
    @api saveLabel = COM_BTN_SAVE;
    @api hideSave = false;
    @api hideFooter = false;
    @api hideHeader = false;

    // ✅ 추가: 'small' | 'medium' | 'large'
    @api size = "medium";

    // 📍 2. 추적 속성 (반응형)

    // 📍 3. Private 속성

    // 📍 4. Getter/Setter

    get modalClass() {
      const key = (this.size || "medium").toLowerCase();
      const sizeClass = SIZE_CLASS_MAP[key] || SIZE_CLASS_MAP.medium;
      return `slds-modal slds-fade-in-open ${sizeClass}`;
    }

    // 📍 5. Wire 메서드

    // 📍 6. 이벤트 핸들러
    handleCancel() {
      this.dispatchEvent(new CustomEvent("cancel"));
    }

    handleSave() {
      this.dispatchEvent(new CustomEvent("confirm"));
    }

    // 📍 7. Private 메서드

    // 📍 8. 라이프사이클 메서드
    connectedCallback() {}

    disconnectedCallback() {}
}