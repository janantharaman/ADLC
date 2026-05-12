/**********************************************************************************
 * @filename      : comDocGenQuickAction.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-10 (화)
 * @group         :
 * @group-content :
 * @description   : 공통 문서 생성 Quick Action LWC 컴포넌트
 *                  - mode(OmniProcess.Type) 기준으로 Apex에서 OmniScript 설정 정보를 조회하고,
 *                  - 조회된 설정값으로 OmniScript를 동적으로 렌더링하며,
 *                  - OmniScript 완료 시 성공 메시지 표시 및 화면 갱신 처리를 수행한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-10       i2max             Create
 **********************************************************************************/
import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { RefreshEvent } from "lightning/refresh";
// Apex Methods
import getOmniScriptConfig from "@salesforce/apex/COM_DocGen_Ctrl.getOmniScriptConfig";

// Custom Labels
import COM_LBL_DOC_GEN from "@salesforce/label/c.COM_LBL_DOC_GEN";
import COM_MSG_DOC_GEN_SUCCESS from "@salesforce/label/c.COM_MSG_DOC_GEN_SUCCESS";

export default class ComDocGenQuickAction extends LightningElement {
    // ============================================================
    // Public Properties
    // ============================================================

    @api recordId;
    @api objectApiName;
    @api mode;
    @api noteType;

    // ============================================================
    // Reactive Properties
    // ============================================================

    isLoading = true;
    hasError = false;
    errorMessage = "";
    scriptType;
    scriptSubType;
    scriptLanguage;

    // ============================================================
    // Private Properties
    // ============================================================

    labels = {
        title: COM_LBL_DOC_GEN,
        success: COM_MSG_DOC_GEN_SUCCESS
    };

    _onMsg = (e) => this.handleWindowMessage(e);

    _onKeyDown = (e) => {
        if (e.key === "Escape") {
            e.stopPropagation();
            e.preventDefault();
        }
    };

    _closeButtonStyle = null;

    // ============================================================
    // Getters
    // ============================================================

    /**
     * @description OmniScript에 전달할 seed data를 JSON 문자열로 반환한다.
     *              recordId가 없으면 빈 객체 문자열을 반환하고,
     *              noteType이 존재하면 NoteType 속성을 추가한다.
     * @return {String} OmniScript 전달용 seed data JSON 문자열
     */
    get seedDataJson() {
        if (!this.recordId) return JSON.stringify({});

        const seed = {
            ContextId: this.recordId,
            ObjectType: this.objectApiName || "Unknown",
            DocGenType: this.mode || "Unknown"
        };

        if (this.noteType) seed.NoteType = this.noteType;

        return JSON.stringify(seed);
    }

    /**
     * @description OmniScript 렌더링 가능 여부를 반환한다.
     *              로딩이 끝났고, 오류가 없고, scriptType 값이 존재할 때 true를 반환한다.
     * @return {Boolean} OmniScript 표시 여부
     */
    get showOmniScript() {
        return !this.isLoading && !this.hasError && !!this.scriptType;
    }

    // ============================================================
    // Wire Methods
    // ============================================================

    /**
     * @description mode 값을 기준으로 Apex에서 OmniScript 설정 정보를 조회한다.
     *              조회 성공 시 scriptType, scriptSubType, scriptLanguage를 세팅하고,
     *              실패 시 오류 상태와 오류 메시지를 세팅한다.
     * @param {Object} param0 wire 응답 객체
     * @param {Object} param0.data Apex 반환 데이터
     * @param {Object} param0.error Apex 오류 객체
     * @return {void}
     */
    @wire(getOmniScriptConfig, { mode: "$mode" })
    wiredConfig({ data, error }) {
        this.isLoading = false;

        if (data) {
            this.scriptType = data.scriptType;
            this.scriptSubType = data.scriptSubType;
            this.scriptLanguage = data.scriptLanguage;
        } else if (error) {
            this.hasError = true;
            this.errorMessage = error.body?.message || "OmniScript configuration could not be loaded.";
            console.error("ComDocGenQuickAction config error:", error);
        }
    }

    // ============================================================
    // Event Handlers
    // ============================================================

    /**
     * @description window message 이벤트를 수신하여 OmniScript 완료 메시지를 처리한다.
     *              OmniScript가 Complete 상태이고 IsSaved=true이면 성공 Toast를 표시하고,
     *              이후 상위 컴포넌트로 완료 이벤트를 전달한다.
     * @param {MessageEvent} event window message 이벤트 객체
     * @return {void}
     */
    handleWindowMessage(event) {
        const msg = event.data?.["OmniScript-Messaging"];
        if (!msg) return;

        if (msg.OmniScript === "Complete") {
            if (msg.IsSaved === true) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Document Generation Completed",
                        message: this.labels.success,
                        variant: "success"
                    })
                );
            }

            this.dispatchEvent(new CustomEvent("omniscriptcomplete", { bubbles: true }));
        }
    }

    // ============================================================
    // Lifecycle Methods
    // ============================================================

    /**
     * @description 컴포넌트 초기화 시 message 리스너와 ESC 키 차단 리스너를 등록한다.
     *              또한 Quick Action 모달의 닫기(X) 버튼을 숨기기 위한 스타일을 동적으로 추가한다.
     * @return {void}
     */
    connectedCallback() {
        window.addEventListener("message", this._onMsg);

        // ESC 키 차단 (캡처 단계에서 플랫폼보다 먼저 처리)
        document.addEventListener("keydown", this._onKeyDown, true);

        // X 버튼 숨김
        this._closeButtonStyle = document.createElement("style");
        this._closeButtonStyle.textContent = "button.slds-modal__close { display: none !important; }";
        document.head.appendChild(this._closeButtonStyle);
    }

    /**
     * @description 컴포넌트 종료 시 등록한 리스너를 제거하고,
     *              동적으로 추가한 닫기 버튼 숨김 스타일을 제거한다.
     *              이후 로그를 남기고 RefreshEvent를 발생시켜 화면 갱신을 요청한다.
     * @return {void}
     */
    disconnectedCallback() {
        window.removeEventListener("message", this._onMsg);
        document.removeEventListener("keydown", this._onKeyDown, true);

        // X 버튼 숨김 스타일 제거
        if (this._closeButtonStyle) {
            this._closeButtonStyle.remove();
            this._closeButtonStyle = null;
        }

        console.log("[ComDocGenQuickAction] 창 닫힘 - recordId:", this.recordId, "| objectApiName:", this.objectApiName, "| mode:", this.mode);
        this.dispatchEvent(new RefreshEvent());
    }
}