/**********************************************************************************
 * @filename      : oppCobrokerConfirmModal.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-03
 * @group         :
 * @group-content :
 * @description   : Co-broking 충돌 확인 모달 컨텐츠 LWC 컴포넌트
 *                  - Co-broking 관련 충돌 데이터와 기존 레코드 목록을 화면에 표시하고,
 *                  - Object Info를 조회하여 동적 라벨을 구성하며,
 *                  - 모달 타입 및 체크 상태에 따라 표시할 섹션/테이블을 제어한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-03       i2max             Create
 **********************************************************************************/

import { LightningElement, api, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

// Schema
import COBROKER_OBJ from "@salesforce/schema/OPP_Cobroker__c";

export default class OppCobrokerConfirmModal extends LightningElement {
    // Public Properties
    @api producingConflicts = [];
    @api placingPanelConflicts = [];
    @api placingCobrokingConflicts = [];
    @api existingRecords = [];
    @api modalType = "placing"; // 'placing' | 'producing'
    @api producingChecked = false;
    @api placingChecked = false;

    // Private Properties
    objectFields;

    // Wire Methods

    /**
     * @description OPP_Cobroker__c Object Info를 조회하여 필드 라벨 정보를 저장한다.
     * @return {void}
     */
    @wire(getObjectInfo, { objectApiName: COBROKER_OBJ })
    wiredObjectInfo({ data, error }) {
        if (data?.fields) {
            this.objectFields = data.fields;
        } else if (error) {
            this.objectFields = null;
            console.error("Error loading object info:", error);
        }
    }

    // Label Getters
    get cobrokerNameLabel() {
        return this.objectFields?.CobrokerName_lk__c?.label ?? "Co-broker Name";
    }

    get cobrokerContactLabel() {
        return this.objectFields?.CobrokerContact_lk__c?.label ?? "Co-broker Contact";
    }

    get cobrokerUserLabel() {
        return this.objectFields?.CobrokerUser_lk__c?.label ?? "Co-broker Name";
    }

    get settlementTypeLabel() {
        return this.objectFields?.SettlementType__c?.label ?? "Settlement Type";
    }

    get sharingPctLabel() {
        return this.objectFields?.SharingPct__c?.label ?? "Sharing (%)";
    }

    get lkAdminFeePctLabel() {
        return this.objectFields?.LKAdminFeePct__c?.label ?? "Admin Fee (%)";
    }

    get tppAdminFeePctLabel() {
        return this.objectFields?.TPPAdminFeePct__c?.label ?? "TPP Admin Fee (%)";
    }

    // State Getters
    get hasProducingConflicts() {
        return this.producingConflicts && this.producingConflicts.length > 0;
    }

    get hasPlacingPanelConflicts() {
        return this.placingPanelConflicts && this.placingPanelConflicts.length > 0;
    }

    get hasPlacingCobrokingConflicts() {
        return this.placingCobrokingConflicts && this.placingCobrokingConflicts.length > 0;
    }

    get hasPlacingConflicts() {
        return this.hasPlacingPanelConflicts || this.hasPlacingCobrokingConflicts;
    }

    get hasExistingRecords() {
        return this.existingRecords && this.existingRecords.length > 0;
    }

    get isPlacingType() {
        return this.modalType === "placing";
    }

    get isProducingType() {
        return this.modalType === "producing";
    }

    get showProducingConflicts() {
        return this.hasProducingConflicts && this.producingChecked;
    }

    get showPlacingConflicts() {
        return this.hasPlacingConflicts && this.placingChecked;
    }

    get showPlacingCobrokingTable() {
        return this.isPlacingType && this.hasPlacingCobrokingConflicts;
    }

    get showExistingRecordsTable() {
        return this.isProducingType && this.hasExistingRecords;
    }

    get fourColumnTableRecords() {
        if (this.showPlacingCobrokingTable) {
            return this.placingCobrokingConflicts;
        } else if (this.showExistingRecordsTable) {
            return this.existingRecords;
        }
        return [];
    }
}