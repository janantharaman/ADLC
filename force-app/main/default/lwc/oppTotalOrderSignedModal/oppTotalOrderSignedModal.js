/**********************************************************************************
 * @filename      : oppTotalOrderSignedModal.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-02 (목)
 * @group         :
 * @group-content :
 * @description   : Total Order (%) / Signed (%) Modal 컴포넌트
 *                  - Layer별 Total Order / Signed 데이터를 조회하여 표시하고,
 *                  - Layer Limit 문자열에 금액 단위를 적용하며,
 *                  - 외부 refresh 및 모달 닫기 이벤트를 처리한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-02       i2max             Create
 **********************************************************************************/

// LWC
import { LightningElement, api, track, wire } from "lwc";

// Apex
import { refreshApex } from "@salesforce/apex";
import getTotalOrderSignedData from "@salesforce/apex/Opp_TotalOrderSignedModal_Ctrl.getTotalOrderSignedData";

// Custom Labels
import COM_BTN_CLOSE from "@salesforce/label/c.COM_BTN_CLOSE";
import LABEL_NORECORDS from "@salesforce/label/c.COM_MSG_NORECORDS";

export default class OppTotalOrderSignedModal extends LightningElement {
    // Public Properties
    @api recordId;
    @api curr;
    @api refreshKey;
    @api panelIds = [];

    // Reactive Properties
    @track layerPanelData = [];

    // Private Properties
    wiredDataResult;

    // Custom Labels
    labels = {
        close: COM_BTN_CLOSE,
        noRecords: LABEL_NORECORDS
    };

    // Getter / Setter
    get hasData() {
        return this.layerPanelData && this.layerPanelData.length > 0;
    }

    // Wire Methods
    @wire(getTotalOrderSignedData, {
        recordId: "$recordId",
        curr: "$curr",
        refreshKey: "$refreshKey",
        panelIds: "$panelIds"
    })
    wiredData(result) {
        this.wiredDataResult = result;
        const { data, error } = result;

        if (data) {
            this.layerPanelData = data.map((row) => ({
                ...row,
                layerLimit: this.formatLayerWithUnits(row.layerLimit)
            }));
        } else if (error) {
            console.error("Error loading Total Order/Signed data:", error);
        }
    }

    // Event Handlers

    /**
     * @description 외부에서 호출 가능한 refresh 메서드
     * @return {Promise} refreshApex 실행 결과
     */
    @api
    handleRefresh() {
        console.log("OppTotalOrderSignedModal - handleRefresh called");
        return refreshApex(this.wiredDataResult);
    }

    /**
     * @description 모달 닫기 이벤트를 상위 컴포넌트로 전달한다.
     * @return {void}
     */
    handleClose() {
        this.dispatchEvent(new CustomEvent("close"));
    }

    // Private Methods

    /**
     * @description Layer 문자열의 금액 부분을 단위 변환하여 반환한다.
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
     * @description 금액 문자열을 tr / bn / m 단위 문자열로 변환한다.
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
     * @description 단위 변환된 숫자 값을 불필요한 0 없이 문자열로 반환한다.
     * @param {Number} value 포맷할 숫자 값
     * @return {String} 포맷된 숫자 문자열
     */
    formatUnitValue(value) {
        if (value === Math.floor(value)) {
            return value.toString();
        }
        return value.toFixed(2).replace(/\.?0+$/, "");
    }
}