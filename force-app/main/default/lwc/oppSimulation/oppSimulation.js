/**********************************************************************************
 * @filename      : oppSimulation.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-12
 * @description   : Opportunity Simulation Panel LWC Component with Chart.js
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-12      i2max              Create
 **********************************************************************************/
import { LightningElement, api, track, wire } from "lwc";
import { getCurrencyScale, toast } from "c/com";
import { loadScript } from "lightning/platformResourceLoader";
import { refreshApex } from "@salesforce/apex";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import PANEL_OBJ from "@salesforce/schema/OPP_Panel__c";
import LAYER_OBJ from "@salesforce/schema/OPP_Layer__c";

//APEX Methods
import getSelectedPanelData from "@salesforce/apex/Opp_SimulationPanel_Ctrl.getSelectedPanelData";
import getIsTreaty from "@salesforce/apex/Opp_SimulationPanel_Ctrl.getIsTreaty";
import updatePanelFinalize from "@salesforce/apex/Opp_SimulationPanel_Ctrl.updatePanelFinalize";
import calculateSpecialRow from "@salesforce/apex/OPP_MarketLineService.calculateSpecialRow";

/// Resource URLs
import CHARTJS from "@salesforce/resourceUrl/chartjs";
import CHARTJS_ANNOTATION from "@salesforce/resourceUrl/chartjsAnnotation";

//Custom Labels
import COM_BTN_FINALIZE from "@salesforce/label/c.COM_BTN_FINALIZE";
import COM_BTN_CALCULATE from "@salesforce/label/c.COM_BTN_CALCULATE";
import OPP_MSG_FINALIZE_SUCCESS from "@salesforce/label/c.OPP_MSG_FINALIZE_SUCCESS";
import OPP_MSG_CALCULATE_SUCCESS from "@salesforce/label/c.OPP_MSG_CALCULATE_SUCCESS";
import OPP_MSG_SELECT_PANEL from "@salesforce/label/c.OPP_MSG_SELECT_PANEL";

// 색상 팔레트
const COLOR_PALETTE = [
    { border: "rgba(242, 118, 73, 1)", bg: "rgba(242, 118, 73, 0.08)" }, // Primary 1 - Orange
    { border: "rgba(143, 63, 191, 1)", bg: "rgba(143, 63, 191, 0.08)" }, // XOL 1 - Purple
    { border: "rgba(90, 90, 90, 1)", bg: "rgba(90, 90, 90, 0.06)" }, // Primary 2 - Dark Gray
    { border: "rgba(46, 125, 50, 1)", bg: "rgba(46, 125, 50, 0.08)" }, // XOL 2 - Green
    { border: "rgba(33, 150, 243, 1)", bg: "rgba(33, 150, 243, 0.08)" }, // Blue
    { border: "rgba(255, 152, 0, 1)", bg: "rgba(255, 152, 0, 0.08)" }, // Amber
    { border: "rgba(156, 39, 176, 1)", bg: "rgba(156, 39, 176, 0.08)" }, // Deep Purple
    { border: "rgba(0, 150, 136, 1)", bg: "rgba(0, 150, 136, 0.08)" } // Teal
];

// Excess Layer용 특별 색상
const EXCESS_LAYER_COLOR = {
    border: "rgba(165, 42, 42, 1)", // 팥색ㅛㅛㅛ
    bg: "rgba(165, 42, 42, 0.08)"
};

// verification 영역 텍스트 색(우측 리스트용)
const VERI_COLORS = [
    "rgba(46, 125, 50, 1)", // green
    "rgba(143, 63, 191, 1)", // purple
    "rgba(242, 118, 73, 1)", // orange
    "rgba(33, 150, 243, 1)" // blue
];

export default class OppSimulation extends LightningElement {
    // API 속성
    @api recordId;
    @api selectedPanelIds = [];
    @api isOpen = false;
    @api selectedCurrency;
    @api isReadOnly = false;
    @api isPlacement = false;
    @api isAllQS = false;

    // 추적 속성 (반응형)
    @track panelData = [];
    @track selectedRows = [];
    @track chartInitialized = false;
    @track verificationData = [];

    // Private 속성
    chart = null;
    chartJsLoaded = false;
    wiredPanelDataResult;
    _isTreaty = false;
    panelObjectFields;
    layerObjectFields;

    labels = {
        finalize: COM_BTN_FINALIZE,
        calculate: COM_BTN_CALCULATE,
        finalizeSuccess: OPP_MSG_FINALIZE_SUCCESS,
        calculateSuccess: OPP_MSG_CALCULATE_SUCCESS,
        selectPanelWarning: OPP_MSG_SELECT_PANEL
    };

    // ✅ 안정화용 private state
    _chartLibPromise = null; // Chart.js + plugin 로드 단일 Promise
    _chartInitPromise = null; // initializeChart 중복 실행 방지
    _boundKeyDown = null; // keydown 핸들러 참조
    _isDisposed = false; // disconnected 이후 async 작업 방지용
    _initialMaxY = null; // 최초 차트 생성 시 계산된 maxY (row 선택 시 변경 안 함)
    _brkgAdjRow = null; // calculateSpecialRow 결과 (가상 BrkgAdj row, DB 미저장) — grid 표시 전용
    _summaryPanelIds = []; // BrokerageSummary에 전달할 panel ID 목록 (Calculate 버튼 눌렀을 때만 갱신)
    _brkgAdjForSummary = null; // BrokerageSummary에 전달할 BrkgAdj 조정 데이터 (Calculate 버튼 눌렀을 때만 갱신)
    _isFinalizing = false; // Finalize 중복 실행 방지 (double-click guard)
    _mountRefreshDone = false; // 마운트 시 cacheable=true 캐시 무효화용 (팝업 재생성 시 자동 초기화)

    // --------------------
    // Getter/Setter
    // --------------------
    get isTreaty() {
        return this._isTreaty;
    }

    get showCheckbox() {
        return !this.isReadOnly;
    }
    get panelClass() {
        return this.isOpen ? "side-panel side-panel-open" : "side-panel";
    }

    get hasPanelData() {
        return Array.isArray(this.panelData) && this.panelData.length > 0;
    }

    get tableRows() {
        return this.panelData.map((row) => {
            // const isBrkgAdj = row.id === "VIRTUAL_BRKG_ADJ";
            const isBrkgAdj = row.id === "VIRTUAL_BRKG_ADJ" || row.layerType === "Brkg Adj";
            const isSelected = this.selectedRows.includes(row.id);
            return {
                ...row,
                isSelected,
                isDisabled: isBrkgAdj,
                ariaLabel: isBrkgAdj ? "Brkg Adj (not selectable)" : `Select row ${row.no}`,
                rowClass: isBrkgAdj ? "slds-color__background_gray-7" : isSelected ? "slds-is-selected" : "",
                finalizeDisplay: row.finalize ? "✓" : "—",
                lolDisplay: this._formatNumber(row.lol, getCurrencyScale(this.selectedCurrency, 2)),
                excessDisplay: this._formatNumber(row.excess, getCurrencyScale(this.selectedCurrency, 2)),
                signedDisplay: this._formatPercent(row.signed),
                grossPremiumDisplay: this._formatCurrency(row.grossPremium, row.curr),
                totalBrkgDisplay: this._formatCurrency(row.totalBrkg, row.curr),
                netToLKPremDisplay: this._formatCurrency(row.netToLKPrem, row.curr),
                lkReBrkgeDisplay: this._formatCurrency(row.lkReBrkge, row.curr),
                netRIDisplay: this._formatCurrency(row.netRI, row.curr)
            };
        });
    }

    _formatCurrency(value, curr) {
        if (value == null) return "—";
        const scale = getCurrencyScale(curr, 2);
        return Number(value).toLocaleString("en-US", {
            style: "currency",
            currency: curr,
            minimumFractionDigits: scale,
            maximumFractionDigits: scale
        });
    }

    _formatPercent(value) {
        if (value == null) return "—";
        return (value * 100).toFixed(2) + "%";
    }

    _formatNumber(value, scale) {
        if (value == null) return "—";
        const s = scale ?? 0;
        return Number(value).toLocaleString("en-US", {
            minimumFractionDigits: s,
            maximumFractionDigits: s
        });
    }

    get hasSelectedRows() {
        return Array.isArray(this.selectedRows) && this.selectedRows.length > 0;
    }

    get isAllSelected() {
        const selectableIds = this.panelData.filter((p) => p.id !== "VIRTUAL_BRKG_ADJ").map((p) => p.id);
        if (selectableIds.length === 0) return false;
        return selectableIds.every((id) => this.selectedRows.includes(id));
    }

    get selectedPanels() {
        if (!this.hasSelectedRows) return [];
        return this.panelData.filter((p) => this.selectedRows.includes(p.id));
    }

    get selectionInfo() {
        if (!this.hasSelectedRows) return "No panels selected";
        return `${this.selectedRows.length} of ${this.panelData.length} panels selected`;
    }

    get hasVerificationData() {
        return Array.isArray(this.verificationData) && this.verificationData.length > 0;
    }

    get verificationView() {
        const totalOrderPct = this.panelData[0]?.totalOrderPct || 100;
        const reinsurerPct = totalOrderPct; // 재보험사 목표 비율

        return (this.verificationData || []).map((r, idx) => {
            const pct = Number(r.signedLine || 0) * 100;
            let signedColor = "#3e3e3c"; // 기본 색상 (검은색)

            if (pct > reinsurerPct) {
                signedColor = "#0176d3"; // Over Placed (파란색)
            } else if (pct < reinsurerPct) {
                signedColor = "#c23934"; // Shortfall (빨간색)
            }

            return {
                layerId: r.layerId,
                layerLimit: r.layerLimit,
                signedText: `${pct.toFixed(1)}%`,
                signedStyle: `color:${signedColor}; font-weight:700;`
            };
        });
    }

    get isFinalizeBtnDisabled() {
        if (this.isTreaty) return !this.hasSelectedRows || this._isFinalizing;
        return !this.hasSelectedRows || !this._brkgAdjRow?.Panel || this._isFinalizing;
    }

    get isCalculateBtnDisabled() {
        return this.isReadOnly || !this.hasSelectedRows;
    }

    /**
     * BrokerageSummary에 전달할 real panel ID 목록
     * Calculate 버튼을 눌렀을 때만 갱신되며, row 선택/해제 시에는 변경되지 않음
     */
    get summaryPanelIds() {
        return this._summaryPanelIds;
    }

    /**
     * BrokerageSummary에 전달할 BrkgAdj 조정 데이터
     * Calculate 버튼을 눌렀을 때만 갱신되며, row 선택/해제 시에는 변경되지 않음
     */
    get brkgAdjForSummary() {
        if (!this._brkgAdjForSummary) return null;
        const p = this._brkgAdjForSummary.Panel;
        return {
            netToLKPrem: p?.NetToLKPrem__c,
            totalBrkg: p?.TotalBrkg__c,
            lkReBrkge: p?.LKReBrkge__c,
            netToUW: p?.NetToUW__c,
            netToProducingCoBroker: p?.NetProducingCobrker__c,
            adminFeeToProducing: p?.ToProducingAdminFee__c,
            adminFeeToLK: p?.ToLKAdminFee__c,
            lkProducingTPPBrkg: p?.LKProducingTPPBrkg__c,
            lkPlacingTPPBrkg: p?.LKPlacingTPPBrkg__c,
            producingTPPBrkg: p?.ProducingTPPBrkg__c,
            placingTPPBrkge: p?.PlacingTPPBrkge__c
        };
    }

    // Column header label getters (OPP_Panel__c fields)
    get finalizeLabel() {
        return this.panelObjectFields?.Finalize_is__c?.label ?? "Finalize";
    }

    get signedLabel() {
        return this.panelObjectFields?.Signed__c?.label ?? "Signed (%)";
    }

    get grossPremLabel() {
        return this.panelObjectFields?.GrossPrem__c?.label ?? "Gross Prem";
    }

    get totalBrkgLabel() {
        return this.panelObjectFields?.TotalBrkg__c?.label ?? "Total Brokerage";
    }

    get netToLKPremLabel() {
        return this.panelObjectFields?.NetToLKPrem__c?.label ?? "Net to LK Prem";
    }

    get lkReBrkgeLabel() {
        return this.panelObjectFields?.LKReBrkge__c?.label ?? "LK Re Brkge";
    }

    get netRILabel() {
        return this.panelObjectFields?.NetRI__c?.label ?? "Net to RI";
    }

    // Column header label getters (OPP_Layer__c fields)
    get layerTypeLabel() {
        return this.layerObjectFields?.Type__c?.label ?? "Layer Type";
    }

    get lolLabel() {
        return this.layerObjectFields?.LOL__c?.label ?? "LOL";
    }

    get excessLabel() {
        return this.layerObjectFields?.Excess__c?.label ?? "Excess";
    }

    // --------------------
    // Wire
    // --------------------

    @wire(getIsTreaty, { recordId: "$recordId" })
    wiredIsTreaty({ data }) {
        this._isTreaty = data === true;
    }

    @wire(getObjectInfo, { objectApiName: PANEL_OBJ })
    wiredPanelObjectInfo({ data, error }) {
        if (data) {
            this.panelObjectFields = data.fields;
        } else if (error) {
            this.panelObjectFields = null;
        }
    }

    @wire(getObjectInfo, { objectApiName: LAYER_OBJ })
    wiredLayerObjectInfo({ data, error }) {
        if (data) {
            this.layerObjectFields = data.fields;
        } else if (error) {
            this.layerObjectFields = null;
        }
    }

    @wire(getSelectedPanelData, { panelIds: "$selectedPanelIds" })
    wiredSelectedPanelData(result) {
        this.wiredPanelDataResult = result;
        const { data, error } = result;
        if (data) {
            // Treaty인 경우 BrkgAdj 패널은 표시 제외
            const filtered = this.isTreaty ? data.filter((p) => p.layerType !== "Brkg Adj") : data;
            // BrkgAdj 패널은 항상 맨 아래로 정렬
            const sorted = [...filtered].sort((a, b) => {
                const aAdj = a.layerType === "Brkg Adj" ? 1 : 0;
                const bAdj = b.layerType === "Brkg Adj" ? 1 : 0;
                return aAdj - bAdj;
            });
            this.panelData = sorted.map((panel, idx) => ({
                id: panel.id,
                no: idx + 1,
                finalize: panel.finalize,
                layerType: panel.layerType,
                marketType: panel.marketType,
                signed: panel.signed != null ? Number(panel.signed) / 100 : 0,
                grossPremium: panel.grossPremium,
                totalBrkg: panel.totalBrkg,
                netToLKPrem: panel.netToLKPrem,
                lkReBrkge: panel.lkReBrkge,
                netRI: panel.netRI,
                totalBrokeragePercent: panel.totalBrokeragePercent / 100,
                reinsurer: panel.reinsurer,
                facilityMGAName: panel.facilityMGAName,
                leader: panel.leader,
                security: panel.security,
                curr: panel.curr,
                lol: panel.lol,
                excess: panel.excess,
                layerId: panel.layerId,
                totalOrderPct: panel.totalOrderPct,
                rowCss: panel.layerType === "Brkg Adj" ? "slds-color__background_gray-7" : ""
            }));

            console.log(">>>>>>>>> this.isPlacement", this.isPlacement);

            // 초기 선택 처리: isReadOnly/isPlacement이거나 selectedPanelIds가 있으면 해당 패널 선택
            const preSelectIds = new Set(Array.isArray(this.selectedPanelIds) ? this.selectedPanelIds : []);
            this.selectedRows =
                this.isReadOnly || this.isPlacement
                    ? this.panelData.filter((p) => p.id !== "VIRTUAL_BRKG_ADJ" && p.layerType !== "Brkg Adj").map((p) => p.id)
                    : preSelectIds.size > 0
                      ? this.panelData.filter((p) => p.id !== "VIRTUAL_BRKG_ADJ" && p.layerType !== "Brkg Adj" && preSelectIds.has(p.id)).map((p) => p.id)
                      : [];
            // this.verificationData = [];
            if (this.selectedRows.length > 0) {
                this.generateVerificationTableFromSelectedRows();
            } else {
                this.verificationData = [];
            }
            this._brkgAdjRow = null;
            this._summaryPanelIds = [];
            this._brkgAdjForSummary = null;

            // 패널이 열려있는 상태에서 데이터가 갱신되면 차트도(원수사만이라도) 갱신되게
            this.chartInitialized = false;
            this._initialMaxY = null; // 데이터 변경 시 maxY 재계산

            // cacheable=true 캐시 무효화: 팝업 열릴 때마다 최신 DB 재조회 (팝업 닫히면 컴포넌트 destroy → _mountRefreshDone 자동 초기화)
            if (!this._mountRefreshDone) {
                this._mountRefreshDone = true;
                refreshApex(this.wiredPanelDataResult);
            }
        } else if (error) {
            console.error("Error loading selected panel data:", error);
            toast("Error", "Error loading selected panel data", "error");
        }
    }

    // --------------------
    // 이벤트 핸들러
    // --------------------
    handleClose() {
        this.destroyChart();
        this.chartInitialized = false;

        console.log("OppSimulation - handleClose: Chart destroyed and flags reset");
        this.dispatchEvent(new CustomEvent("close"));
    }

    handleOverlayClick() {
        this.handleClose();
    }

    async handleSelectAll(event) {
        if (event.target.checked) {
            this.selectedRows = this.panelData.filter((p) => p.id !== "VIRTUAL_BRKG_ADJ").map((p) => p.id);
        } else {
            this.selectedRows = [];
        }

        this._brkgAdjRow = null;

        if (this.selectedRows.length > 0) {
            this.generateVerificationTableFromSelectedRows();
        } else {
            this.verificationData = [];
        }

        this.chartInitialized = false;
        await this.initializeChart();
    }

    async handleCheckboxChange(event) {
        const rowId = event.target.dataset.rowId;
        if (!rowId) return;

        if (event.target.checked) {
            this.selectedRows = [...this.selectedRows, rowId];
        } else {
            this.selectedRows = this.selectedRows.filter((id) => id !== rowId);
        }

        this._brkgAdjRow = null;

        if (this.selectedRows.length > 0) {
            this.generateVerificationTableFromSelectedRows();
        } else {
            this.verificationData = [];
        }

        this.chartInitialized = false;
        await this.initializeChart();
    }

    async handleCalculate() {
        try {
            const result = await this._runCalculate();
            if (result === null) {
                toast("Warning", this.labels.selectPanelWarning, "warning");
                return;
            }
            console.log("[handleCalculate] result:", JSON.stringify(result));
            toast("Success", this.labels.calculateSuccess, "success");

            // _summaryPanelIds 변경 후 LWC re-render 1틱 대기 → child의 wiredSummaryResult가 새 panelIds로 갱신된 뒤 refresh
            await Promise.resolve();
            this.template.querySelector("c-opp-brokerage-summary")?.handleRefresh();
        } catch (error) {
            console.error("[handleCalculate] error:", error);
            toast("Error", error.body?.message || error.message || "Unknown error", "error");
        }
    }

    async _runCalculate() {
        // BrkgAdj 타입 패널 제외한 ID만 calculateSpecialRow에 전달
        const inputIds = this.selectedRows.filter((id) => {
            if (id === "VIRTUAL_BRKG_ADJ") return false;
            const panel = this.panelData.find((p) => p.id === id);
            return panel && panel.layerType !== "Brkg Adj";
        });

        if (inputIds.length === 0) {
            this._brkgAdjRow = null;
            this._summaryPanelIds = [];
            this._brkgAdjForSummary = null;
            return null;
        }

        // Treaty인 경우 Brkg Adj row 계산 및 생성 생략
        if (this.isTreaty) {
            this._brkgAdjRow = null;
            this._brkgAdjForSummary = null;
            this._summaryPanelIds = inputIds;
            return {};
        }

        const result = await calculateSpecialRow({ panelIds: inputIds, type: "Brkg Adj" });

        console.log("[calculateSpecialRow] result:", JSON.stringify(result));

        const panel = result?.Panel;
        const layer = result?.Layer;

        // 기존 BrkgAdj row 제거 (virtual이든 DB에서 로드된 실제 row든 모두 교체)
        const base = this.panelData.filter((p) => p.id !== "VIRTUAL_BRKG_ADJ" && p.layerType !== "Brkg Adj");
        const maxNo = base.reduce((m, p) => Math.max(m, p.no || 0), 0);
        const virtualRow = {
            id: "VIRTUAL_BRKG_ADJ",
            no: maxNo + 1,
            finalize: false,
            layerType: "Brkg Adj",
            marketType: panel?.MarketType__c ?? "",
            totalBrkg: panel?.TotalBrkg__c ?? 0,
            netToLKPrem: panel?.NetToLKPrem__c ?? 0,
            lkReBrkge: panel?.LKReBrkge__c ?? 0,
            netRI: panel?.NetRI__c ?? 0,
            totalBrokeragePercent: 0,
            reinsurer: null,
            facilityMGAName: null,
            leader: "",
            security: null,
            curr: panel?.Currency__c ?? this.selectedCurrency,
            lol: null,
            excess: null,
            layerId: layer?.Id ?? null,
            totalOrderPct: 0,
            rowCss: "slds-color__background_gray-7"
        };

        // grid 가상 row 상태 업데이트
        this._brkgAdjRow = result;
        this.panelData = [...base, virtualRow];

        // Brokerage Summary 갱신
        this._summaryPanelIds = inputIds;
        this._brkgAdjForSummary = result;

        return result;
    }

    async handleFinalize() {
        if (this._isFinalizing) return; // double-click 방지
        this._isFinalizing = true;
        try {
            // VIRTUAL_BRKG_ADJ는 실제 Salesforce ID가 아니므로 제거
            const realPanelIds = this.selectedRows.filter((id) => id !== "VIRTUAL_BRKG_ADJ");

            // QS 패널이 포함된 경우 해당 레이어의 LOL을 현재 시뮬레이션 보상한도(maxY)로 업데이트
            const hasQSPanel = this.selectedPanels.some((p) => p.layerType === "QS");

            // calculateSpecialRow 계산값 → BrkgAdj panel에 저장
            const brkgAdjPanel = this._brkgAdjRow?.Panel;
            const brkgAdjData = brkgAdjPanel
                ? {
                      totalBrkg: brkgAdjPanel.TotalBrkg__c,
                      netToLKPrem: brkgAdjPanel.NetToLKPrem__c,
                      lkReBrkge: brkgAdjPanel.LKReBrkge__c,
                      producingTPPBrkg: brkgAdjPanel.ProducingTPPBrkg__c,
                      placingTPPBrkge: brkgAdjPanel.PlacingTPPBrkge__c,
                      lkProducingTPPBrkg: brkgAdjPanel.LKProducingTPPBrkg__c,
                      lkPlacingTPPBrkg: brkgAdjPanel.LKPlacingTPPBrkg__c,
                      netToUW: brkgAdjPanel.NetToUW__c,
                      netToProducingCoBroker: brkgAdjPanel.NetProducingCobrker__c,
                      adminFeeToProducing: brkgAdjPanel.ToProducingAdminFee__c,
                      adminFeeToLK: brkgAdjPanel.ToLKAdminFee__c,
                      netRI: brkgAdjPanel.NetRI__c,
                      facilityId: brkgAdjPanel.Facility_lk__c,
                      facilityParticipantId: brkgAdjPanel.FacilityParticipant_lk__c
                  }
                : null;

            await updatePanelFinalize({
                panelIds: realPanelIds,
                recordId: this.recordId,
                selectedCurrency: this.selectedCurrency,
                qsLol: hasQSPanel ? this._initialMaxY : null,
                brkgAdjData
            });

            // 상위 컴포넌트에 완료 알림 (데이터 새로고침 전에 먼저 dispatch)
            console.log("[OppSimulation] Dispatching finalize event");
            this.dispatchEvent(new CustomEvent("finalize", { bubbles: true, composed: true }));

            // 데이터 새로고침
            await refreshApex(this.wiredPanelDataResult);

            // Success toast는 패널 외부(플랫폼 레이어)에 렌더링되므로 패널 닫힌 후에도 표시됨
            toast("Success", this.labels.finalizeSuccess, "success");
            this.handleClose();
        } catch (error) {
            console.error("Error finalizing panels:", error);
            const errorMessage = error.body?.message || error.message || "Unknown error occurred";
            toast("Error", `Failed to finalize panels: ${errorMessage}`, "error");
        } finally {
            this._isFinalizing = false;
        }
    }

    handleKeyDown(event) {
        if ((event.key === "Escape" || event.keyCode === 27) && this.isOpen) {
            event.preventDefault();
            event.stopPropagation();
            this.handleClose();
        }
    }

    // --------------------
    // Chart 로딩/초기화
    // --------------------
    async loadChartJs() {
        if (this.chartJsLoaded) return true;
        if (this._chartLibPromise) return this._chartLibPromise;

        const chartUrl = CHARTJS + "/dist/chart.umd.min.js";
        const annoUrl = CHARTJS_ANNOTATION + "/chartjs-plugin-annotation.min.js";

        this._chartLibPromise = (async () => {
            try {
                // 1) Chart.js 먼저 로드
                await loadScript(this, chartUrl);

                // 2) Chart 객체 존재 확인
                if (!window.Chart) throw new Error("window.Chart not found after loading Chart.js");

                // 3) Annotation Plugin 로드
                await loadScript(this, annoUrl);

                const Chart = window.Chart;
                const anno = window["chartjs-plugin-annotation"] || window.ChartAnnotation;

                if (anno?.default) Chart.register(anno.default);
                else if (anno) Chart.register(anno);

                this.chartJsLoaded = true;
                return true;
            } catch (e) {
                this._chartLibPromise = null; // 다음 시도 가능
                console.error("[loadScript FAIL]", {
                    message: e?.message,
                    name: e?.name,
                    stack: e?.stack,
                    chartUrl,
                    annoUrl
                });
                return false;
            }
        })();

        return this._chartLibPromise;
    }

    async initializeChart() {
        // ✅ 중복 실행 방지
        if (this._chartInitPromise) return this._chartInitPromise;

        this._chartInitPromise = (async () => {
            if (this._isDisposed) return;

            const chartContainer = this.template.querySelector(".chart-container");
            if (!chartContainer || !this.hasPanelData) return;

            const loaded = await this.loadChartJs();
            if (!loaded || this._isDisposed) return;

            // y축 범위: 항상 전체 panelData 기준, 최초 1회 계산 후 고정 (row 선택 시 변경 안 함)
            const layerGroupsForYAxis = this.groupPanelsByLayer(this.panelData);
            if (!this._initialMaxY) {
                this._initialMaxY = this.calculateMaxY(layerGroupsForYAxis) || 100;
            }
            const maxY = this._initialMaxY;
            const yAxisTicks = this.calculateYAxisTicks(layerGroupsForYAxis, maxY);

            const totalOrderPct = this.panelData[0]?.totalOrderPct || 100;
            const cedentPct = 100 - totalOrderPct;

            const activePanels = this.selectedPanels; // 선택 없으면 [] → 원수사만 표시
            const annotations = this.createAnnotations(activePanels, maxY, cedentPct, totalOrderPct);

            // ✅ 차트가 이미 있으면 업데이트
            if (this.chart) {
                this.chart.options.scales.y.max = maxY;
                this.chart.options.plugins.annotation.annotations = annotations;

                // y축 ticks도 업데이트(segments 기반)
                this.chart.options.scales.y.ticks.callback = function (value) {
                    return yAxisTicks.includes(value) ? value : "";
                };
                this.chart.options.scales.y.afterBuildTicks = function (axis) {
                    axis.ticks = yAxisTicks.map((value) => ({ value }));
                };

                this.chart.update("none");
                this.chartInitialized = true;
                return;
            }

            // ✅ 새로 생성
            while (chartContainer.firstChild) {
                chartContainer.removeChild(chartContainer.firstChild);
            }

            const canvas = document.createElement("canvas");
            canvas.width = 800;
            canvas.height = 400;
            chartContainer.appendChild(canvas);

            const ctx = canvas.getContext("2d");
            const Chart = window.Chart;

            this.chart = new Chart(ctx, {
                type: "scatter",
                data: { datasets: [] },
                options: {
                    animation: false,
                    responsive: false,
                    maintainAspectRatio: false,
                    devicePixelRatio: 2,
                    plugins: {
                        legend: { display: false },
                        tooltip: { enabled: false },
                        annotation: { annotations }
                    },
                    scales: {
                        x: {
                            type: "linear",
                            min: 0,
                            max: 100,
                            afterBuildTicks: function (axis) {
                                // 화면 고정 위치(0, 25, 50, 75, 100)에 눈금 배치
                                axis.ticks = [0, 25, 50, 75, 100].map((v) => ({ value: v }));
                            },
                            ticks: {
                                autoSkip: false,
                                callback: function (value) {
                                    // 화면 좌표 → 실제 % 역변환
                                    let real;
                                    if (value <= 25) {
                                        real = (value / 25) * cedentPct;
                                    } else {
                                        real = cedentPct + ((value - 25) / 75) * (100 - cedentPct);
                                    }
                                    return Math.round(real) + "%";
                                }
                            },
                            title: {
                                display: true,
                                text: "재보험사 (%)",
                                font: { size: 14, weight: "bold" }
                            }
                        },
                        y: {
                            type: "linear",
                            min: 0,
                            max: maxY,
                            ticks: {
                                callback: function (value) {
                                    return yAxisTicks.includes(value) ? value : "";
                                },
                                autoSkip: false,
                                maxTicksLimit: 50
                            },
                            afterBuildTicks: function (axis) {
                                axis.ticks = yAxisTicks.map((value) => ({ value }));
                            },
                            title: {
                                display: true,
                                text: "Layer Limit",
                                font: { size: 14, weight: "bold" }
                            }
                        }
                    }
                }
            });

            this.chartInitialized = true;
        })().finally(() => {
            this._chartInitPromise = null;
        });

        return this._chartInitPromise;
    }

    destroyChart() {
        if (this.chart) {
            try {
                this.chart.destroy();
            } catch (e) {
                console.warn("Chart destroy error:", e);
            }
            this.chart = null;
        }
    }

    // --------------------
    // 데이터 처리 유틸
    // --------------------
    /**
     * QS 타입 레이어: excess=0, lol=maxY로 조정 (Quota Share는 전체 구간 커버)
     */
    applyQSLayerAdjustment(layerGroups, maxY) {
        return layerGroups.map((layer) => {
            if (layer.layerType === "QS") {
                return { ...layer, excess: 0, lol: maxY };
            }
            return layer;
        });
    }

    groupPanelsByLayer(panels) {
        const layerMap = new Map();
        (panels || []).forEach((panel) => {
            const layerId = panel.layerId;
            if (!layerMap.has(layerId)) {
                layerMap.set(layerId, {
                    layerId,
                    layerType: panel.layerType,
                    lol: panel.lol,
                    excess: panel.excess,
                    panels: []
                });
            }
            layerMap.get(layerId).panels.push(panel);
        });
        return Array.from(layerMap.values());
    }

    calculateMaxY(layerGroups) {
        let maxY = 0;
        (layerGroups || []).forEach((layer) => {
            const layerLimit = Number(layer.excess || 0) + Number(layer.lol || 0);
            if (layerLimit > maxY) maxY = layerLimit;
        });
        return maxY;
    }

    /**
     * ✅ Segment 기반 Y축 Tick: breakpoints(0, excess들, excess+lol들, maxY)
     */
    calculateYAxisTicks(layerGroups, maxY) {
        const bps = this.buildYBreakpoints(layerGroups, maxY);
        return bps;
    }

    buildYBreakpoints(layerGroups, maxY) {
        const set = new Set([0, maxY]);

        (layerGroups || []).forEach((layer) => {
            const y0 = Number(layer.excess || 0);
            const y1 = y0 + Number(layer.lol || 0);
            set.add(y0);
            set.add(y1);
        });

        return Array.from(set)
            .filter((v) => Number.isFinite(v))
            .sort((a, b) => a - b);
    }

    buildYSegments(breakpoints) {
        const segs = [];
        for (let i = 0; i < breakpoints.length - 1; i++) {
            const a = breakpoints[i];
            const b = breakpoints[i + 1];
            if (b > a) segs.push({ yMin: a, yMax: b });
        }
        return segs;
    }

    getSegmentLabel(seg) {
        const start = seg.yMin;
        const end = seg.yMax;
        if (start === 0) return `${this.formatNumber(end)} xs OPDs`;
        return `${this.formatNumber(end - start)} xs ${this.formatNumber(start)} xs OPDs`;
    }

    getLayerLimitLabel(layer) {
        if (layer.layerType === "Primary") {
            return `${this.formatNumber(layer.lol)} xs OPDs`;
        }
        const start = layer.excess;
        const end = Number(layer.excess || 0) + Number(layer.lol || 0);
        return `${this.formatNumber(end - start)} xs ${this.formatNumber(start)} xs OPDs`;
    }

    formatNumber(num) {
        return Math.round(Number(num || 0)).toLocaleString();
    }

    /**
     * 실제 X 좌표(0~100)를 화면 표시 좌표로 변환
     * - 원수사 영역(0~cedentPct)을 항상 화면 0~25%로 고정
     * - 재보험사 영역(cedentPct~100)을 항상 화면 25~100%로 고정
     */
    _toDisplayX(realX, cedentPct) {
        const CEDENT_W = 25;
        if (cedentPct < 0) return realX;
        if (realX < cedentPct) {
            return (realX / cedentPct) * CEDENT_W;
        }
        return CEDENT_W + ((realX - cedentPct) / (100 - cedentPct)) * (100 - CEDENT_W);
    }

    /**
     * ✅ Excess 기반 Annotation 생성
     * - Excess 값이 같은 레이어들은 x축을 공유
     * - 각 Excess 그룹별로 독립적인 x축 배치
     * - 레이어는 전체 y 범위(excess ~ excess+lol)로 표시
     */
    createAnnotations(activePanels, maxY, cedentPct, totalOrderPct) {
        const annotations = {};
        const safeTotalOrderPct = Number(totalOrderPct || 0) > 0 ? Number(totalOrderPct) : 100;

        // 원수사 split 라인 (화면상 항상 25% 위치)
        annotations.insurerSplit = {
            type: "line",
            xMin: 25,
            xMax: 25,
            yMin: 0,
            yMax: maxY,
            borderWidth: 3,
            borderColor: "rgba(0, 0, 0, 0.8)"
        };

        // 원수사 라벨 박스 (화면상 항상 0~25%)
        annotations.cedentLabel = {
            type: "box",
            xMin: 0,
            xMax: 25,
            yMin: 0,
            yMax: maxY,
            borderWidth: 0,
            backgroundColor: "rgba(255, 191, 0, 0.9)",
            label: {
                display: true,
                content: `원수사 ${cedentPct.toFixed(0)}%`,
                position: "center",
                color: "#111",
                font: { size: 16, weight: "600" }
            }
        };

        if (!activePanels || activePanels.length === 0) return annotations;

        // 1) 레이어 그룹 생성 → QS 조정(excess=0, lol=maxY) → 정렬
        const layerGroups = this.applyQSLayerAdjustment(this.groupPanelsByLayer(activePanels), maxY);
        layerGroups.sort((a, b) => (a.excess || 0) - (b.excess || 0));

        // 2) Excess 값별로 레이어들을 그룹화
        const excessGroups = new Map();
        for (const layer of layerGroups) {
            const excessKey = Number(layer.excess || 0);
            if (!excessGroups.has(excessKey)) excessGroups.set(excessKey, []);
            excessGroups.get(excessKey).push(layer);
        }

        // QS 패널들의 총 signed(%) 및 X 너비 사전 계산
        const qsTotalSignedPct = layerGroups.filter((l) => l.layerType === "QS").reduce((sum, layer) => sum + layer.panels.reduce((ps, p) => ps + p.signed * 100, 0), 0);
        const qsEndX = cedentPct + (qsTotalSignedPct / safeTotalOrderPct) * (100 - cedentPct);
        // 비QS 그룹의 오른쪽 정렬 기준: totalOrderPct 중 QS가 소비한 부분 제외
        const nonQSAvailablePct = safeTotalOrderPct - qsTotalSignedPct;

        // 3) Excess 그룹별로 "패널 단위"로 배치
        // - QS 그룹  : cedentPct(= 100 - totalOrderPct)부터 오른쪽으로
        // - 비QS 그룹: QS 끝나는 지점(qsEndX)부터 시작
        let colorIndex = 0;

        for (const [excessValue, layers] of excessGroups.entries()) {
            // QS/비QS 패널을 각각 독립적인 X 위치로 추적 (같은 excess 그룹 내 혼재 대응)
            let qsCurrentX = cedentPct;
            let nonQsCurrentX = qsEndX;
            let groupCumSigned = 0; // 비QS 오른쪽 정렬 판단용 누적

            // 3-1) 레이어들을 panel 리스트로 펼치기 (하지만 layer 메타는 유지)
            const panelItems = [];
            for (const layer of layers) {
                const y0 = Number(layer.excess || 0);
                const y1 = y0 + Number(layer.lol || 0);

                const layerTotalSigned = layer.panels.reduce((sum, p) => sum + p.signed * 100, 0);
                const isExcessLayerLowSigned = layer.layerType === "Excess" && layerTotalSigned < 20;
                const isEmptyLayer = !layer.excess && !layer.lol;
                const isOverPlaced = this.checkOverPlaced(layer, layerGroups);

                let baseColor;
                if (isEmptyLayer) {
                    baseColor = {
                        border: "rgba(200, 200, 200, 0.5)",
                        bg: "rgba(255, 255, 255, 0)"
                    };
                } else if (isOverPlaced) {
                    baseColor = { border: "rgba(255, 0, 0, 1)", bg: "rgba(255, 0, 0, 0.1)" };
                } else if (isExcessLayerLowSigned) {
                    baseColor = EXCESS_LAYER_COLOR;
                } else {
                    baseColor = COLOR_PALETTE[colorIndex % COLOR_PALETTE.length];
                }
                colorIndex++;

                const labelText = isOverPlaced ? "Over Placed" : isEmptyLayer ? "" : this.getLayerLimitLabel(layer);

                for (let i = 0; i < layer.panels.length; i++) {
                    panelItems.push({
                        layer,
                        layerId: layer.layerId,
                        panelIndex: i,
                        panel: layer.panels[i],
                        y0,
                        y1,
                        baseColor,
                        labelText
                    });
                }
            }

            // 3-2) panel-wise 배치 (QS여부를 패널 단위로 판단)
            for (const item of panelItems) {
                const { layerId, panelIndex, panel, y0, y1, baseColor, labelText } = item;
                const isQSPanel = item.layer.layerType === "QS";

                const signedPct = panel.signed * 100;
                const width = (signedPct / safeTotalOrderPct) * (100 - cedentPct);

                // 비QS 패널: 가용 범위 초과 시 오른쪽 정렬
                if (!isQSPanel) {
                    if (groupCumSigned + signedPct > nonQSAvailablePct) {
                        nonQsCurrentX = 100 - width;
                    }
                    groupCumSigned += signedPct;
                }

                const currentX = isQSPanel ? qsCurrentX : nonQsCurrentX;
                let xEnd = currentX + width;

                // 100%를 넘으면: 두 개의 박스 (현재~100 + cedentPct~overflow)
                if (xEnd > 100) {
                    const overflow = xEnd - 100;

                    // 박스 1: currentX ~ 100%
                    const key1 = `excess_${excessValue}_layer_${layerId}_p_${panelIndex}_main`;
                    annotations[key1] = {
                        type: "box",
                        xMin: this._toDisplayX(currentX, cedentPct),
                        xMax: 100,
                        yMin: y0,
                        yMax: y1,
                        borderWidth: 2,
                        borderDash: [6, 4],
                        borderColor: baseColor.border,
                        backgroundColor: baseColor.bg,
                        label: { display: false }
                    };

                    // 박스 2: cedentPct ~ cedentPct + overflow
                    const key2 = `excess_${excessValue}_layer_${layerId}_p_${panelIndex}_overflow`;
                    annotations[key2] = {
                        type: "box",
                        xMin: 25,
                        xMax: this._toDisplayX(cedentPct + overflow, cedentPct),
                        yMin: y0,
                        yMax: y1,
                        borderWidth: 2,
                        borderDash: [6, 4],
                        borderColor: baseColor.border,
                        backgroundColor: baseColor.bg,
                        label: {
                            display: labelText ? true : false,
                            content: labelText ? [labelText, `${signedPct.toFixed(1)}%`] : [],
                            position: "center",
                            color: baseColor.border,
                            font: { size: 12, weight: "600" }
                        }
                    };

                    if (isQSPanel) qsCurrentX = cedentPct + overflow;
                    else nonQsCurrentX = cedentPct + overflow;
                } else {
                    // 정상: 한 개의 박스
                    const key = `excess_${excessValue}_layer_${layerId}_p_${panelIndex}`;
                    annotations[key] = {
                        type: "box",
                        xMin: this._toDisplayX(currentX, cedentPct),
                        xMax: this._toDisplayX(xEnd, cedentPct),
                        yMin: y0,
                        yMax: y1,
                        borderWidth: 2,
                        borderDash: [6, 4],
                        borderColor: baseColor.border,
                        backgroundColor: baseColor.bg,
                        label: {
                            display: labelText ? true : false,
                            content: labelText ? [labelText, `${signedPct.toFixed(1)}%`] : [],
                            position: "center",
                            color: baseColor.border,
                            font: { size: 12, weight: "600" }
                        }
                    };

                    if (isQSPanel) qsCurrentX = xEnd;
                    else nonQsCurrentX = xEnd;
                }
            }
        }

        return annotations;
    }
    /**
     * Over Placed 체크 로직
     * 예: XoL1의 Excess가 60이고, 그 아래 레이어가 있는지 확인
     */
    checkOverPlaced(currentLayer, allLayerGroups) {
        if (!currentLayer.layerType || !currentLayer.layerType.includes("XoL")) {
            return false;
        }

        const currentExcess = currentLayer.excess || 0;

        for (const layer of allLayerGroups) {
            if (layer.layerId === currentLayer.layerId) continue;

            const layerExcess = layer.excess || 0;
            const layerTop = Number(layerExcess) + Number(layer.lol || 0);

            if (currentExcess >= layerExcess && currentExcess < layerTop) {
                return true;
            }
        }

        return false;
    }

    // --------------------
    // Verification Table (✅ segment 기준 합산)
    // --------------------
    generateVerificationTableFromSelectedRows() {
        if (!this.hasSelectedRows) {
            this.verificationData = [];
            return;
        }

        const selectedPanels = this.selectedPanels;
        if (!selectedPanels.length) {
            this.verificationData = [];
            return;
        }

        // ✅ maxY는 초기 차트 기준값 사용 (없으면 전체 panelData 기준으로 계산)
        const allLayerGroups = this.groupPanelsByLayer(this.panelData);
        const maxY = this._initialMaxY || this.calculateMaxY(allLayerGroups) || 100;

        // QS 조정(excess=0, lol=maxY) 적용
        const layerGroups = this.applyQSLayerAdjustment(this.groupPanelsByLayer(selectedPanels), maxY);

        const breakpoints = this.buildYBreakpoints(layerGroups, maxY);
        const segments = this.buildYSegments(breakpoints);

        // 레이어별 total signed(%) + y0/y1
        const layerSigned = (layerGroups || []).map((layer) => {
            const y0 = Number(layer.excess || 0);
            const y1 = y0 + Number(layer.lol || 0);
            const totalSignedPct = layer.panels.reduce((sum, panel) => sum + panel.signed * 100, 0); // %
            return { layerId: layer.layerId, y0, y1, totalSignedPct };
        });

        // segment별 합산: segment를 덮는 레이어들의 totalSignedPct를 모두 더함
        this.verificationData = segments.map((seg) => {
            let sumPct = 0;

            for (const lw of layerSigned) {
                const covers = lw.y0 <= seg.yMin && lw.y1 >= seg.yMax;
                if (covers) sumPct += lw.totalSignedPct;
            }

            return {
                layerId: `${seg.yMin}-${seg.yMax}`,
                layerLimit: this.getSegmentLabel(seg),
                signedLine: sumPct / 100 // UI가 0~1 형태로 쓰는 것 유지
            };
        });
    }

    // --------------------
    // Lifecycle
    // --------------------
    connectedCallback() {
        this._isDisposed = false;

        this._boundKeyDown = this.handleKeyDown.bind(this);
        document.addEventListener("keydown", this._boundKeyDown);
    }

    renderedCallback() {
        if (this.isOpen && !this.chartInitialized && this.hasPanelData) {
            this.initializeChart().catch((e) => {
                console.error("initializeChart failed in renderedCallback", e);
            });
        }
    }

    disconnectedCallback() {
        this._isDisposed = true;

        if (this._boundKeyDown) {
            document.removeEventListener("keydown", this._boundKeyDown);
            this._boundKeyDown = null;
        }

        this.destroyChart();
        this.chartInitialized = false;
    }
}