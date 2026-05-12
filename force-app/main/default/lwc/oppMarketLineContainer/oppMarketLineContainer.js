/**********************************************************************************
 * @filename      : oppMarketLineContainer.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-02
 * @group         :
 * @group-content :
 * @description   : Opportunity Market Line Container LWC 컴포넌트
 *                  - Container 초기 데이터를 조회하여 통화 옵션, 섹션 타이틀, Co-broking 상태를 관리하고,
 *                  - Currency 변경, Finalize 후 Brokerage Summary 새로고침,
 *                  - cobrokingrefresh / updatemarkettitle 이벤트 및 Platform Event 구독을 처리한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-02       i2max             Create
 * 1.1   2026-01-29       i2max             Add handleFinalize to refresh BrokerageSummary
 * 1.2   2026-03-23       i2max             getContainerData 단일 wire로 통합
 **********************************************************************************/

import { LightningElement, api, track, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { subscribe as empSubscribe, unsubscribe as empUnsubscribe } from "lightning/empApi";

// Apex Methods
import getContainerData from "@salesforce/apex/Opp_MarketLineContainer_Ctrl.getContainerData";

// Custom Labels
import OPP_LBL_TSI_NULL from "@salesforce/label/c.OPP_LBL_TSI_NULL";

export default class OppMarketLineContainer extends LightningElement {
    // Public Properties
    @api recordId;

    // Reactive Properties
    @track selectedCurrency = null;
    @track currencyOptions = [];
    @track sectiontitle = "Market Line";
    @track hasCIDetail = false;
    @track hasProducing = false;
    @track isPlacementMode = false;

    // Private Properties
    wiredContainerDataResult;

    labels = {
        COM_MSG_INPUT_TSI_BY_LOCATION: OPP_LBL_TSI_NULL
    };

    // Getters
    get sectionTitle() {
        return this.sectiontitle;
    }

    get hasCurrencyOptions() {
        return this.currencyOptions && this.currencyOptions.length > 0;
    }

    // Wire Methods

    /**
     * @description Container 초기 데이터를 조회하여 화면 상태를 초기화한다.
     * @return {void}
     */
    @wire(getContainerData, { recordId: "$recordId" })
    wiredContainerData(result) {
        this.wiredContainerDataResult = result;
        const { data, error } = result;

        if (data) {
            this.isPlacementMode = data.isPlacement || false;

            this.currencyOptions = data.currencyOptions || [];
            if (this.currencyOptions.length > 0) {
                this.selectedCurrency = this.currencyOptions[0].value;
            }

            this.hasCIDetail = data.satisfiesCIDetailCondition || false;
            this.hasProducing = data.hasProducingCobroker || false;
            this.updateSectionTitle();
        } else if (error) {
            this.isPlacementMode = false;
            console.error("Error loading container data:", error);
        }
    }

    // Event Handlers

    /**
     * @description Currency 선택값 변경 시 selectedCurrency를 갱신한다.
     * @param {Event} event 변경 이벤트
     * @return {void}
     */
    handleCurrencyChange(event) {
        this.selectedCurrency = event.detail.value;
        console.log("OppMarketLineContainer - Currency changed to:", this.selectedCurrency);
    }

    /**
     * @description oppSimulation에서 finalize 버튼 클릭 시 Brokerage Summary를 새로고침한다.
     * @return {void}
     */
    handleFinalize() {
        console.log("OppMarketLineContainer - handleFinalize called");

        const brokerageSummary = this.template.querySelector("c-opp-brokerage-summary");

        if (brokerageSummary) {
            console.log("OppMarketLineContainer - Refreshing BrokerageSummary");
            brokerageSummary.handleRefresh();
        } else {
            console.warn("OppMarketLineContainer - BrokerageSummary component not found");
        }
    }

    /**
     * @description cobrokingrefresh 이벤트 수신 시 같은 recordId이면 Container 데이터를 다시 조회한다.
     * @param {CustomEvent} event 커스텀 이벤트
     * @return {Promise<void>}
     */
    async handleCobrokingRefreshEvent(event) {
        if (event.detail && event.detail.recordId === this.recordId) {
            console.log("OppMarketLineContainer - cobrokingrefresh event received");
            await refreshApex(this.wiredContainerDataResult);
        }
    }

    /**
     * @description updatemarkettitle 이벤트 수신 시 같은 recordId이면 섹션 타이틀을 변경한다.
     * @param {CustomEvent} event 커스텀 이벤트
     * @return {void}
     */
    handleUpdateMarketTitleEvent(event) {
        if (event.detail && event.detail.recordId === this.recordId) {
            console.log("OppMarketLineContainer - updatemarkettitle event received:", event.detail.title);
            this.sectiontitle = event.detail.title;
        }
    }

    // Private Methods

    /**
     * @description 현재 CIDetail 존재 여부에 따라 섹션 타이틀을 갱신한다.
     * @return {void}
     */
    updateSectionTitle() {
        if (this.hasCIDetail) {
            this.sectiontitle = "CI Detail";
        } else {
            this.sectiontitle = "Market Line";
        }
    }

    /**
     * @description OPP_RecordChanged__e Platform Event를 구독하여 TSI 변경 시 Container 데이터를 새로고침한다.
     * @return {void}
     */
    _subscribePlatformEvent() {
        if (this._empSubscription) return;

        empSubscribe("/event/OPP_RecordChanged__e", -1, (event) => {
            const data = event?.data?.payload;
            if (!data || data.RecordId__c !== this.recordId) return;

            if (data.Action__c === "TSI_CHANGED") {
                refreshApex(this.wiredContainerDataResult);
            }
        }).then((sub) => {
            this._empSubscription = sub;
        });
    }

    // Lifecycle Methods

    /**
     * @description 컴포넌트 초기화 시 window 이벤트와 Platform Event 구독을 등록한다.
     * @return {void}
     */
    connectedCallback() {
        this._boundHandleCobrokingRefreshEvent = this.handleCobrokingRefreshEvent.bind(this);
        window.addEventListener("cobrokingrefresh", this._boundHandleCobrokingRefreshEvent);

        this._boundHandleUpdateMarketTitleEvent = this.handleUpdateMarketTitleEvent.bind(this);
        window.addEventListener("updatemarkettitle", this._boundHandleUpdateMarketTitleEvent);

        this._subscribePlatformEvent();
    }

    /**
     * @description 컴포넌트 종료 시 등록한 이벤트 리스너와 Platform Event 구독을 해제한다.
     * @return {void}
     */
    disconnectedCallback() {
        if (this._boundHandleCobrokingRefreshEvent) {
            window.removeEventListener("cobrokingrefresh", this._boundHandleCobrokingRefreshEvent);
        }
        if (this._boundHandleUpdateMarketTitleEvent) {
            window.removeEventListener("updatemarkettitle", this._boundHandleUpdateMarketTitleEvent);
        }
        if (this._empSubscription) {
            void empUnsubscribe(this._empSubscription);
            this._empSubscription = null;
        }
    }
}