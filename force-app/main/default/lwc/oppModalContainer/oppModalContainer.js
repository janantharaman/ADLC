/**********************************************************************************
 * @filename      : oppModalContainer.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-16 (금)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-16      i2max      Create
 * 1.1   2026-01-29      i2max      Update handleSimulationFinalize to propagate finalize event
 **********************************************************************************/
import { LightningElement, api, track } from "lwc";
import { toast } from "c/com";
import COM_BTN_CLOSE from "@salesforce/label/c.COM_BTN_CLOSE";
import COM_BTN_CANCEL from "@salesforce/label/c.COM_BTN_CANCEL";
import COM_BTN_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import COM_BTN_APPLY from "@salesforce/label/c.COM_BTN_APPLY";
import COM_MSG_SAVE_SUCCESS from "@salesforce/label/c.COM_MSG_SAVE_SUCCESS";
import COM_MSG_SAVE_FAILED from "@salesforce/label/c.COM_MSG_SAVE_FAILED";
import COM_LBL_COMPLETE from "@salesforce/label/c.COM_LBL_COMPLETE";
import COM_LBL_ERROR from "@salesforce/label/c.COM_LBL_ERROR";

export default class oppModalContainer extends LightningElement {
    // ========== API 속성 ==========
    @api recordId;

    // ========== 추적 속성 (반응형) ==========
    @track isPopupOpen = false;
    @track popupType;
    @track popupParams = {};
    @track isSaving = false;

    // ========== Custom Labels ==========
    labels = {
        COM_BTN_CLOSE,
        COM_BTN_CANCEL,
        COM_BTN_SAVE,
        COM_BTN_APPLY,
        COM_MSG_SAVE_SUCCESS,
        COM_MSG_SAVE_FAILED,
        COM_LBL_COMPLETE,
        COM_LBL_ERROR
    };

    // ========== Getter/Setter ==========
    get isMarketSearchPopup() {
        return this.popupType === "MARKET_SEARCH";
    }

    get isSubjectivityPopup() {
        return this.popupType === "SUBJECTIVITY";
    }

    get isSimulationPopup() {
        return this.popupType === "SIMULATION";
    }

    get isTextEditorPopup() {
        return this.popupType === "TEXT_EDITOR";
    }

    get modalTitle() {
        if (this.isSubjectivityPopup) return "Subjectivity Manage";
        if (this.isMarketSearchPopup) return `${this.popupParams.type || "Market"} Search`;
        if (this.isSimulationPopup) return "Simulation";
        if (this.isTextEditorPopup) return this.popupParams.title || "Text Editor";
        return "Popup";
    }

    get hideSaveButton() {
        // Market Search는 선택 시 자동 닫힘이므로 저장 버튼 숨김
        // Simulation 팝업도 자체 저장 버튼이 있다면 숨김 (여기서는 숨김 처리)
        return this.isMarketSearchPopup || this.isSimulationPopup || this.isReadOnly;
    }

    get saveLabel() {
        return this.isTextEditorPopup ? this.labels.COM_BTN_APPLY : this.labels.COM_BTN_SAVE;
    }

    get closeLabel() {
        return this.isTextEditorPopup && !this.isReadOnly ? this.labels.COM_BTN_CANCEL : this.labels.COM_BTN_CLOSE;
    }

    get isReadOnly() {
        return this.popupParams.isReadOnly || false;
    }

    get sizePopup() {
        return (this.isTextEditorPopup ? "small" : "medium");
    }

    // ========== API 메서드 ==========
    /**
     * @description 외부에서 팝업 오픈 요청
     */
    @api
    openPopup(type, params) {
        this.popupType = type;
        this.popupParams = params || {};
        this.isPopupOpen = true;
    }

    // ========== 이벤트 핸들러 ==========
    handleModalCancel() {
        this.isPopupOpen = false;
        this.popupType = null;
        this.popupParams = {};
    }

    async handleModalConfirm() {
        const child = this.template.querySelector('[data-id="popupChild"]');

        // 1. Text Editor 처리 (값 전달)
        if (this.isTextEditorPopup) {
            if (child && typeof child.getValue === "function") {
                const value = child.getValue();
                // 부모(Manage)에게 값 전달
                this.dispatchEvent(
                    new CustomEvent("texteditorapply", {
                        detail: {
                            value: value,
                            rowId: this.popupParams.rowId,
                            key: this.popupParams.key
                        }
                    })
                );
                this.handleModalCancel();
            }
            return;
        }

        // 2. 일반 팝업 처리 (DB 저장)
        // save 메서드가 없으면 그냥 닫기 (저장 기능 없는 팝업일 수 있음)
        if (!child || typeof child.save !== "function") {
            this.handleModalCancel();
            return;
        }

        this.isSaving = true;
        let result;

        try {
            result = await child.save();
        } catch (e) {
            result = {
                success: false,
                message: e && e.message ? e.message : "Unknown error"
            };
        }

        this.isSaving = false;

        if (result && result.success) {
            toast(this, this.labels.COM_LBL_COMPLETE, this.labels.COM_MSG_SAVE_SUCCESS, "success");
            this.handleModalCancel();

            // 저장 완료 이벤트 발송 (부모인 Manage가 받아서 리로드 등 처리) && Subjectivity 팝업이 아닐 때만 리로드 요청
            if (this.isSubjectivityPopup) {
                this.dispatchEvent(new CustomEvent("savecomplete"));
            }
        } else {
            toast(this, this.labels.COM_LBL_ERROR, result?.message || this.labels.COM_MSG_SAVE_FAILED, "error");
        }
    }

    handleRecordSelect(event) {
        // Market Search 팝업에서 선택 시
        const { id, name, facilityParticipantId } = event.detail;

        // 선택 결과 이벤트 발송
        this.dispatchEvent(
            new CustomEvent("recordselect", {
                detail: {
                    id,
                    name,
                    facilityParticipantId,
                    rowId: this.popupParams.rowId,
                    key: this.popupParams.key
                }
            })
        );

        this.handleModalCancel();
    }

    /**
     * @description oppSimulation에서 finalize 버튼 클릭 시 호출됨
     * finalize 이벤트를 상위 컴포넌트로 전파 (bubbles, composed)
     */
    handleSimulationFinalize() {
        console.log("[OppModalContainer] handleSimulationFinalize called");

        // finalize 이벤트를 상위로 전파 (oppMarketLineContainer까지 도달)
        this.dispatchEvent(
            new CustomEvent("finalize", {
                bubbles: true,
                composed: true
            })
        );
    }
}