/**********************************************************************************
 * @filename      : oppBrokerageSummary.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-02 (목)
 * @group         :
 * @group-content :
 * @description   : Opportunity Brokerage Summary LWC 컴포넌트
 *                  - Brokerage Summary 데이터를 조회하여 카드 형태로 표시하고,
 *                  - BrkgAdj 가상 패널 계산값을 병합하여 화면 표시 데이터를 재계산하며,
 *                  - Total Order 모달 열기, 데이터 새로고침, 통화/퍼센트/Layer 포맷팅을 처리한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-02       i2max             Create
 **********************************************************************************/

import { LightningElement, api, track, wire } from "lwc";
import { getCurrencyScale, toast } from "c/com";
import { refreshApex } from "@salesforce/apex";

// Apex Methods
import getBrokerageSummary from "@salesforce/apex/Opp_BrokerageSummary_Ctrl.getBrokerageSummary";

// Constants
// 모듈 레벨 카운터: 컴포넌트 remount 시에도 리셋되지 않아 wire 캐시 키 충돌 방지
let _modalRefreshCounter = 0;

export default class OppBrokerageSummary extends LightningElement {
    // Public Properties
    @api recordId;
    @api selectedCurrency;
    @api selectedPanelIds = [];
    @api hideDataWhenNoSelection = false;
    @api hideSection = false;
    @api hasCIDetail = false;

    // Reactive Properties
    @track summaryData = {};
    @track showTotalOrderModal = false;
    @track modalRefreshKey = 0;

    // Private Properties
    wiredSummaryResult;
    _baseData = null;
    _adjustmentData = null;

    // Getter / Setter
    @api
    set adjustmentData(value) {
        this._adjustmentData = value;
        this._mergeSummaryData();
    }

    get adjustmentData() {
        return this._adjustmentData;
    }

    get formattedGrossPremium() {
        return this.formatCurrency(this.summaryData.grossPremium);
    }

    get formattedTotalOrderPct() {
        return this.formatPercentage(this.summaryData.totalOrderPct);
    }

    get formattedNetToProducingCoBroker() {
        return this.formatCurrency(this.summaryData.netToProducingCoBroker);
    }

    get formattedNetToLKPrem() {
        return this.formatCurrency(this.summaryData.netToLKPrem);
    }

    get formattedNetToUW() {
        return this.formatCurrency(this.summaryData.netToUW);
    }

    get formattedAdminFeeToProducing() {
        return this.formatCurrency(this.summaryData.adminFeeToProducing);
    }

    get formattedAdminFeeToLK() {
        return this.formatCurrency(this.summaryData.adminFeeToLK);
    }

    get formattedTotalBrkg() {
        return this.formatCurrency(this.summaryData.totalBrkg);
    }

    get formattedLKBrokerage() {
        return this.formatCurrency(this.summaryData.lkBrokerage);
    }

    get formattedLkReBrkge() {
        return this.formatCurrency(this.summaryData.lkReBrkge);
    }

    get formattedLKTPPBrokerage() {
        return this.formatCurrency(this.summaryData.lkTPPBrokerage);
    }

    get formattedTPPBrokerage() {
        return this.formatCurrency(this.summaryData.tppBrokerage);
    }

    get formattedLKReBrokerage() {
        return this.formatCurrency(this.summaryData.lkReBrkge);
    }

    get formattedLKReBrokeragePercent() {
        return this.formatPercentage(this.summaryData.lkReBrokeragePercent);
    }

    get formattedProportional() {
        return this.formatCurrency(this.summaryData.proportional);
    }

    get formattedProportionalPercent() {
        return this.formatPercentage(this.summaryData.proportionalPercent);
    }

    get formattedNonProportional() {
        return this.formatCurrency(this.summaryData.nonProportional);
    }

    get formattedNonProportionalPercent() {
        return this.formatPercentage(this.summaryData.nonProportionalPercent);
    }

    get formattedBrkgAdj() {
        return this.formatCurrency(this.summaryData.brkgAdj);
    }

    get formattedLKReBrokerageAfterAdmin() {
        return this.formatCurrency(this.summaryData.lkReBrokerageAfterAdmin);
    }

    get formattedTPPBrokerageAfterAdmin() {
        return this.formatCurrency(this.summaryData.tppBrokerageAfterAdmin);
    }

    get hasMismatchedLayers() {
        return this.summaryData.mismatchedLayers && this.summaryData.mismatchedLayers.length > 0;
    }

    get shouldShowPlacementStatus() {
        return this.summaryData.hasPanels && !this.hasMismatchedLayers;
    }

    get mismatchedLayersList() {
        if (!this.hasMismatchedLayers) {
            return [];
        }

        return this.summaryData.mismatchedLayers.map((layer, index) => ({
            rowNumber: index + 1,
            layerName: this.formatLayerWithUnits(layer.layerName),
            totalOrderPct: this.formatPercentage(layer.totalOrderPct),
            signedPct: this.formatPercentage(layer.signedPct),
            status: layer.status,
            statusClass: this.getStatusClass(layer.status)
        }));
    }

    // Wire Methods
    @wire(getBrokerageSummary, {
        recordId: "$recordId",
        curr: "$selectedCurrency",
        panelIds: "$selectedPanelIds",
        hasCIDetail: "$hasCIDetail"
    })
    wiredBrokerageSummary(result) {
        this.wiredSummaryResult = result;

        if (result.data) {
            console.log("Brokerage summary data received:", result.data);

            if (this.hideDataWhenNoSelection && (!this.selectedPanelIds || this.selectedPanelIds.length === 0)) {
                this._baseData = {
                    grossPremium: 0,
                    totalOrderPct: 0,
                    signedPct: 0,
                    netToProducingCoBroker: 0,
                    netToLKPrem: 0,
                    netToUW: 0,
                    adminFeeToProducing: 0,
                    adminFeeToLK: 0,
                    totalBrkg: 0,
                    lkBrokerage: 0,
                    lkReBrkge: 0,
                    lkTPPBrokerage: 0,
                    tppBrokerage: 0,
                    lkReBrokeragePercent: 0,
                    proportional: 0,
                    proportionalPercent: 0,
                    nonProportional: 0,
                    nonProportionalPercent: 0,
                    brkgAdj: 0,
                    lkReBrokerageAfterAdmin: 0,
                    tppBrokerageAfterAdmin: 0,
                    mismatchedLayers: [],
                    hasPanels: false
                };
            } else {
                this._baseData = { ...result.data };
            }

            console.log("param", this.showSection);
            this._mergeSummaryData();
        } else if (result.error) {
            console.error("Error loading brokerage summary:", result.error);
            toast("Error", "Error loading brokerage summary", "error");
        }
    }

    // Event Handlers

    /**
     * @description 상태값에 따라 CSS 클래스명을 반환한다.
     * @param {String} status 상태 문자열
     * @return {String} 상태별 CSS 클래스명
     */
    getStatusClass(status) {
        if (status === "Shortfall") {
            return "status-label status-shortfall";
        } else if (status === "Placement Done") {
            return "status-label status-done";
        } else if (status === "Over Placed") {
            return "status-label status-overplaced";
        }
        return "status-label";
    }

    /**
     * @description 외부에서 호출 가능한 새로고침 메서드이다.
     *              modalRefreshKey를 증가시키고 wire 데이터를 refreshApex로 재조회한다.
     * @return {Promise} refreshApex Promise
     */
    @api
    handleRefresh() {
        console.log("OppBrokerageSummary - handleRefresh called");
        this.modalRefreshKey++;
        return refreshApex(this.wiredSummaryResult);
    }

    /**
     * @description Total Order 모달을 열기 전에 refresh key를 증가시키고 summary 데이터를 새로고침한다.
     * @return {void}
     */
    handleOpenTotalOrderModal() {
        this.modalRefreshKey = ++_modalRefreshCounter;
        refreshApex(this.wiredSummaryResult);
        this.showTotalOrderModal = true;
    }

    /**
     * @description Total Order 모달을 닫는다.
     * @return {void}
     */
    handleCloseTotalOrderModal() {
        this.showTotalOrderModal = false;
    }

    // Private Methods

    /**
     * @description _baseData와 _adjustmentData를 병합하여 summaryData를 재계산한다.
     *              adjustmentData가 없으면 base data를 그대로 사용한다.
     * @return {void}
     */
    _mergeSummaryData() {
        if (!this._baseData) return;

        if (!this._adjustmentData) {
            this.summaryData = { ...this._baseData };
            return;
        }

        const b = this._baseData;
        const adj = this._adjustmentData;
        const n = (v) => Number(v) || 0;

        const netToLKPrem = n(b.netToLKPrem) + n(adj.netToLKPrem);
        const totalBrkg = n(b.totalBrkg) + n(adj.totalBrkg);
        const lkReBrkge = n(b.lkReBrkge) + n(adj.lkReBrkge);
        const netToUW = n(b.netToUW) + n(adj.netToUW);
        const netToProducingCoBroker = n(b.netToProducingCoBroker) + n(adj.netToProducingCoBroker);
        const adminFeeToProducing = n(b.adminFeeToProducing) + n(adj.adminFeeToProducing);
        const adminFeeToLK = n(b.adminFeeToLK) + n(adj.adminFeeToLK);
        const lkTPPBrokerage = n(b.lkTPPBrokerage) + n(adj.lkProducingTPPBrkg) + n(adj.lkPlacingTPPBrkg);
        const tppBrokerage = n(b.tppBrokerage) + n(adj.producingTPPBrkg) + n(adj.placingTPPBrkge);
        const brkgAdj = n(b.brkgAdj) + n(adj.lkReBrkge);

        const lkBrokerage = lkReBrkge + lkTPPBrokerage;
        const lkReBrokeragePercent = netToLKPrem !== 0 ? (lkReBrkge / netToLKPrem) * 100 : 0;
        const nonProportional = lkReBrkge - n(b.proportional) - brkgAdj;
        const lkReBrokerageAfterAdmin = adminFeeToProducing + adminFeeToLK + lkBrokerage;
        const tppBrokerageAfterAdmin = tppBrokerage - adminFeeToProducing - adminFeeToLK;

        this.summaryData = {
            ...b,
            netToLKPrem,
            totalBrkg,
            lkReBrkge,
            netToUW,
            netToProducingCoBroker,
            adminFeeToProducing,
            adminFeeToLK,
            lkTPPBrokerage,
            tppBrokerage,
            brkgAdj,
            lkBrokerage,
            lkReBrokeragePercent,
            nonProportional,
            lkReBrokerageAfterAdmin,
            tppBrokerageAfterAdmin
        };
    }

    /**
     * @description 금액 값을 현재 선택 통화 기준으로 포맷된 문자열로 반환한다.
     * @param {Number} value 포맷할 금액 값
     * @return {String} 포맷된 통화 문자열
     */
    formatCurrency(value) {
        const scale = getCurrencyScale(this.selectedCurrency, 2);
        const zero = (0).toFixed(scale);

        if (!value || isNaN(value)) {
            return `${zero} ${this.selectedCurrency}`;
        }

        return `${this.formatNumber(value, scale)} ${this.selectedCurrency}`;
    }

    /**
     * @description 퍼센트 값을 소수점 2자리 문자열로 포맷하여 반환한다.
     * @param {Number} value 포맷할 퍼센트 값
     * @return {String} 포맷된 퍼센트 문자열
     */
    formatPercentage(value) {
        if (!value || isNaN(value)) {
            return "0.00%";
        }

        return `${this.formatNumber(value, 2)}%`;
    }

    /**
     * @description 숫자 값을 지정 소수 자릿수 기준으로 locale 문자열로 반환한다.
     * @param {Number} value 포맷할 숫자 값
     * @param {Number} scale 소수 자릿수
     * @return {String} 포맷된 숫자 문자열
     */
    formatNumber(value, scale) {
        const s = scale ?? getCurrencyScale(this.selectedCurrency, 2);
        return Number(value).toLocaleString("en-US", { minimumFractionDigits: s, maximumFractionDigits: s });
    }

    /**
     * @description Layer 문자열을 금액 단위 축약 형식으로 변환하여 반환한다.
     * @param {String} layerString 원본 Layer 문자열
     * @return {String} 단위 변환된 Layer 문자열
     */
    formatLayerWithUnits(layerString) {
        if (!layerString) {
            return layerString;
        }

        const parts = layerString.split(" xs ");
        if (parts.length < 2) {
            return layerString;
        }

        const firstAmount = this.convertAmountToUnit(parts[0]);
        const secondAmount = this.convertAmountToUnit(parts[1]);
        const remaining = parts.slice(2).join(" xs ");

        return `${firstAmount} xs ${secondAmount}${remaining ? " xs " + remaining : ""}`;
    }

    /**
     * @description 숫자 문자열을 tr / bn / m 단위 축약 문자열로 변환한다.
     * @param {String} amountStr 원본 금액 문자열
     * @return {String} 단위 변환된 금액 문자열
     */
    convertAmountToUnit(amountStr) {
        if (!amountStr) {
            return amountStr;
        }

        const numStr = amountStr.replace(/,/g, "");
        const num = parseFloat(numStr);

        if (isNaN(num)) {
            return amountStr;
        }

        if (num >= 1000000000000) {
            const value = num / 1000000000000;
            return `${this.formatUnitValue(value)} tr`;
        } else if (num >= 1000000000) {
            const value = num / 1000000000;
            return `${this.formatUnitValue(value)} bn`;
        } else if (num >= 1000000) {
            const value = num / 1000000;
            return `${this.formatUnitValue(value)} m`;
        }

        return amountStr;
    }

    /**
     * @description 단위 변환용 숫자 값을 불필요한 0 없이 문자열로 반환한다.
     * @param {Number} value 포맷할 숫자 값
     * @return {String} 포맷된 단위 값 문자열
     */
    formatUnitValue(value) {
        if (value === Math.floor(value)) {
            return value.toString();
        }
        return value.toFixed(2).replace(/\.?0+$/, "");
    }
}