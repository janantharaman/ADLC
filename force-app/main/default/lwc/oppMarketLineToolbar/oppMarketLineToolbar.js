/**********************************************************************************
 * @filename      : oppMarketLineToolbar.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-15 (목)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-15      i2max      Create
 **********************************************************************************/
import {api, LightningElement} from 'lwc';

import COM_BTN_RefreshRef from '@salesforce/label/c.COM_BTN_RefreshRef';
import COM_LBL_RefreshRef from '@salesforce/label/c.COM_LBL_RefreshRef';
import COM_BTN_SAVE from '@salesforce/label/c.COM_BTN_SAVE';
import COM_BTN_REFRESH from '@salesforce/label/c.COM_BTN_REFRESH';
import COM_LBL_REFRESH from '@salesforce/label/c.COM_LBL_REFRESH';
import COM_BTN_SIMULATION from '@salesforce/label/c.COM_BTN_SIMULATION';
import COM_BTN_EXPAND from '@salesforce/label/c.COM_BTN_EXPAND';
import COM_BTN_COLLAPSE from '@salesforce/label/c.COM_BTN_COLLAPSE';
import COM_BTN_FULLSCREEN_OFF from '@salesforce/label/c.COM_BTN_FULLSCREEN_OFF';
import COM_BTN_FULLSCREEN_ON from '@salesforce/label/c.COM_BTN_FULLSCREEN_ON';
import COM_BTN_CREATECO from '@salesforce/label/c.COM_BTN_CREATECO';
import OPP_MSG_FINALIZE_MODIFIED from '@salesforce/label/c.OPP_MSG_FINALIZE_MODIFIED';
import OPP_MSG_NEED_RECALCULATE from '@salesforce/label/c.OPP_MSG_NEED_RECALCULATE';

export default class oppMarketLineToolbar extends LightningElement {

    labels = {
        COM_BTN_RefreshRef,
        COM_LBL_RefreshRef,
        COM_BTN_SAVE,
        COM_BTN_REFRESH,
        COM_LBL_REFRESH,
        COM_BTN_SIMULATION,
        COM_BTN_EXPAND,
        COM_BTN_COLLAPSE,
        COM_BTN_FULLSCREEN_OFF,
        COM_BTN_FULLSCREEN_ON,
        COM_BTN_CREATECO,
        OPP_MSG_FINALIZE_MODIFIED,
        OPP_MSG_NEED_RECALCULATE
    };

    // 📍 1. API 속성 (외부에서 설정 가능)
    @api selectedCurrency;
    @api cntFinalizedLine;
    @api isFullscreen;
    @api isGroupToggleDisabled;
    @api isAllCollapsed;
    @api isReadOnly;
    @api isSaveDisabled;
    @api isSimulDisabled;
    @api isOpp;
    @api isClaim;
    @api isCiCase;
    @api isPlacement;
    @api hasFinalizeModified;
    @api hasNeedRecalculate;

    // 📍 4. Getter/Setter
    get displaySelectedCurrency() {
        return this.selectedCurrency ? this.selectedCurrency :'';
    }
    get iconName() {
        return this.isFullscreen ? 'utility:contract' : 'utility:expand';
    }

    get buttonLabel() {
        return this.isFullscreen ? this.labels.COM_BTN_FULLSCREEN_OFF : this.labels.COM_BTN_FULLSCREEN_ON;
    }

    get groupToggleIcon() {
        return this.isAllCollapsed ? 'utility:chevronright' : 'utility:chevrondown';
    }

    get groupToggleLabel() {
        return this.isAllCollapsed ? this.labels.COM_BTN_EXPAND : this.labels.COM_BTN_COLLAPSE;
    }

    get isSaveVisible() { // 저장 관련 버튼 노출 여부 (Claim이 아닐 때만)
        // console.log('[oppMarketLineToolbar] 🐸 isSaveVisible isClaim=', this.isClaim);
        return !this.isClaim;
    }

    // 일반 기회 여부 (Add Layer 버튼 조회 여부) //Simulation
    get isStandardOpp() {
        return ((this.isOpp && !this.isCiCase) || this.isPlacement);
    }

    get isSimulationVisible() {
        return ((this.isOpp && !this.isCiCase) || this.isPlacement);
    }

    // 📍 6. 이벤트 핸들러
    handleAction(event) {
        const action = event.currentTarget.dataset.action;
        this.dispatchEvent(new CustomEvent('toolbaraction', {
            detail: { value: action }
        }));
    }
}