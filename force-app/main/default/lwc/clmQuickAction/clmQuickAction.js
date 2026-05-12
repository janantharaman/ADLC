/**********************************************************************************
 * @filename      : clmQuickAction.js
 * @project-name  : LK Insurance Services
 * @author        : i2max
 * @date          : 2026-03-25
 * @description   : CLM Quick Action 공통 컴포넌트
 *                  mode 파라미터에 따라 분기하여 Quick Action 로직을 처리한다.
 *                  - mode="PLA_SOC_ISSUE" : SOC/PLA 문서 생성 (ClmDocGenModal 로직 동일)
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-25      i2max              Create (PLA_SOC_ISSUE 모드: ClmDocGenModal 로직 이전)
 **********************************************************************************/
import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { notifyRecordUpdateAvailable } from "lightning/uiRecordApi";
import getClaimDocInfo from "@salesforce/apex/CLM_QuickAction_Ctrl.getClaimDocInfo";
import generateClaimDocument from "@salesforce/apex/CLM_QuickAction_Ctrl.generateClaimDocument";

import COM_BTN_CANCEL from "@salesforce/label/c.COM_BTN_CANCEL";
import COM_BTN_DOC_GEN from "@salesforce/label/c.COM_BTN_DOC_GEN";
import COM_LBL_DOC_GEN from "@salesforce/label/c.COM_LBL_DOC_GEN";
import COM_MSG_DOC_GEN_PERMISSION from "@salesforce/label/c.COM_MSG_DOC_GEN_PERMISSION";
import COM_MSG_DOC_GEN_EMAIL_CONFIRM from "@salesforce/label/c.COM_MSG_DOC_GEN_EMAIL_CONFIRM";
import CLM_MSG_AMOUNT from "@salesforce/label/c.CLM_MSG_AMOUNT";
import CLM_MSG_ALLOCATED from "@salesforce/label/c.CLM_MSG_ALLOCATED";

// ===== Mode 상수 =====
const MODE_PLA_SOC_ISSUE = "PLA_SOC_ISSUE";

export default class ClmQuickAction extends LightningElement {
    // ========== API 속성 ==========
    @api recordId;
    @api mode;

    // ========== Reactive 속성 ==========
    isLoading = false;
    isInfoLoading = true;
    canGenerate = false;
    hasEditPermission = false;
    isAllocated = false;
    isTotalAmtMismatch = false;

    labels = {
        cancel: COM_BTN_CANCEL,
        generate: COM_BTN_DOC_GEN,
        header: COM_LBL_DOC_GEN,
        permissionError: COM_MSG_DOC_GEN_PERMISSION,
        confirmSubMessage: COM_MSG_DOC_GEN_EMAIL_CONFIRM,
        totalAmtMismatch: CLM_MSG_AMOUNT,
        allocationIncomplete: CLM_MSG_ALLOCATED
    };

    // ========== Getter: 모드 분기 ==========
    get isPLASOCMode() {
        return this.mode === MODE_PLA_SOC_ISSUE;
    }

    // ========== Getter: PLA_SOC_ISSUE 모드 UI 상태 ==========
    get showSpinner() {
        return this.isLoading || this.isInfoLoading;
    }

    get isGenerateHidden() {
        return this.isInfoLoading || !this.hasEditPermission || !this.isAllocated || !this.canGenerate;
    }

    get showPermissionError() {
        return !this.hasEditPermission;
    }

    get showAllocationError() {
        return this.hasEditPermission && !this.isAllocated;
    }

    get showBusinessError() {
        return this.hasEditPermission && this.isAllocated && !this.canGenerate && this.isTotalAmtMismatch;
    }

    get showConfirmMessage() {
        return this.hasEditPermission && this.isAllocated && this.canGenerate;
    }

    // ========== Wire 메서드 ==========
    @wire(getClaimDocInfo, { claimId: "$recordId" })
    wiredClaimDocInfo({ data, error }) {
        if (!this.isPLASOCMode) return;
        this.isInfoLoading = false;
        if (data) {
            this.canGenerate = data.canGenerate || false;
            this.hasEditPermission = data.hasEditPermission || false;
            this.isAllocated = data.isAllocated || false;
            this.isTotalAmtMismatch = data.isTotalAmtMismatch || false;
        } else if (error) {
            console.error("Error loading claim doc info:", error);
        }
    }

    // ========== Private 메서드 ==========
    _closeAction() {
        notifyRecordUpdateAvailable([{ recordId: this.recordId }]);
        this.dispatchEvent(new CustomEvent("actioncomplete"));
    }

    // ========== 이벤트 핸들러 ==========
    handleClose() {
        this._closeAction();
    }

    async handleGenerate() {
        this.isLoading = true;
        try {
            await generateClaimDocument({ claimId: this.recordId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: this.labels.confirmSubMessage,
                    variant: "success"
                })
            );
            this._closeAction();
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: error.body?.message || "문서 생성 중 오류가 발생했습니다.",
                    variant: "error"
                })
            );
            this.isLoading = false;
        }
    }
}