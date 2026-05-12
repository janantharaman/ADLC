/**********************************************************************************
 * @filename      : oppMarketLineLabels.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-15 (목)
 * @group         :
 * @group-content :
 * @description   : oppMarketLineManage에서 사용하는 Custom Label 모음
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-15      i2max      Create
 **********************************************************************************/
// 공통 라벨 (Common)
import COM_LBL_ERROR from '@salesforce/label/c.COM_LBL_ERROR';
import COM_LBL_WARNING from '@salesforce/label/c.COM_LBL_WARNING';
import COM_LBL_NOTICE from '@salesforce/label/c.COM_LBL_NOTICE';
import COM_LBL_COMPLETE from '@salesforce/label/c.COM_LBL_COMPLETE';

// 공통 메시지 (Common Message)
import COM_MSG_CHECK_REQUIRED from '@salesforce/label/c.COM_MSG_CHECK_REQUIRED_FIELDS';
import COM_MSG_DATA_LOAD_FAIL from '@salesforce/label/c.COM_MSG_DATA_LOAD_FAIL';
import COM_MSG_SAVE_SUCCESS from '@salesforce/label/c.COM_MSG_SAVE_SUCCESS';
import COM_MSG_SAVE_FAIL from '@salesforce/label/c.COM_MSG_SAVE_FAIL';
import COM_MSG_DATA_RELOADED from '@salesforce/label/c.COM_MSG_DATA_RELOADED';
import COM_LBL_DATA_RETRIEVAL_FAILED from '@salesforce/label/c.COM_LBL_DATA_RETRIEVAL_FAILED';

// 버튼 라벨
import COM_BTN_SIMULATION from '@salesforce/label/c.COM_BTN_SIMULATION';

// 모듈 전용 메시지 (Opportunity Market Line)
import OPP_MSG_CONFIRM_LAYER_DELETE from '@salesforce/label/c.OPP_MSG_CONFIRM_LAYER_DELETE';
import OPP_MSG_SELECT_LAYER_TO_DELETE from '@salesforce/label/c.OPP_MSG_SELECT_LAYER_TO_DELETE';
import OPP_MSG_GRID_CONFIG_LOAD_FAIL from '@salesforce/label/c.OPP_MSG_GRID_CONFIG_LOAD_FAIL';
import OPP_MSG_CALC_RULE_CONFIG_ERROR from '@salesforce/label/c.OPP_MSG_CALC_RULE_CONFIG_ERROR';
import OPP_MSG_SIGNED_EXCEEDS_WRITTEN from '@salesforce/label/c.OPP_MSG_SIGNED_EXCEEDS_WRITTEN';
import OPP_MSG_SELECT_TARGET_FOR_SIMULATION from '@salesforce/label/c.OPP_MSG_SELECT_TARGET_FOR_SIMULATION';
import COM_MSG_GRID_RESET from '@salesforce/label/c.COM_MSG_GRID_RESET';
import OPP_MSG_CONTEXT_REFRESHED from '@salesforce/label/c.OPP_MSG_CONTEXT_REFRESHED';
import OPP_MSG_SIGNED_EXCEEDS_WRITTEN_VAL from '@salesforce/label/c.OPP_MSG_SIGNED_EXCEEDS_WRITTEN_VAL';
import OPP_MSG_NEED_RECALCULATE from '@salesforce/label/c.OPP_MSG_NEED_RECALCULATE';
import OPP_MSG_REQUIRE_SETTLEMENT_TYPE from '@salesforce/label/c.OPP_MSG_COBROKER_REQUIRE_SETTLEMENT_TYPE';
import OPP_MSG_DELETE_COBROKING from '@salesforce/label/c.OPP_MSG_CONFIRM_DELETE_COBROKING';


const labels = {
    // Common
    COM_LBL_ERROR,
    COM_LBL_WARNING,
    COM_LBL_NOTICE,
    COM_LBL_COMPLETE,

    // Messages
    COM_MSG_CHECK_REQUIRED,
    COM_MSG_DATA_LOAD_FAIL,
    COM_MSG_SAVE_SUCCESS,
    COM_MSG_SAVE_FAIL,
    COM_MSG_DATA_RELOADED,
    COM_LBL_DATA_RETRIEVAL_FAILED,

    // Buttons
    COM_BTN_SIMULATION,

    // Module Specific
    OPP_MSG_CONFIRM_LAYER_DELETE,
    OPP_MSG_SELECT_LAYER_TO_DELETE,
    OPP_MSG_GRID_CONFIG_LOAD_FAIL,
    OPP_MSG_CALC_RULE_CONFIG_ERROR,
    OPP_MSG_SIGNED_EXCEEDS_WRITTEN,
    OPP_MSG_SELECT_TARGET_FOR_SIMULATION,
    COM_MSG_GRID_RESET,
    OPP_MSG_CONTEXT_REFRESHED,
    OPP_MSG_SIGNED_EXCEEDS_WRITTEN_VAL,
    OPP_MSG_NEED_RECALCULATE,
    OPP_MSG_REQUIRE_SETTLEMENT_TYPE,
    OPP_MSG_DELETE_COBROKING
};

export default labels;