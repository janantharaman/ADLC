/**********************************************************************************
 * @filename      : oppMarketLineManage.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-07 (수)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-07      i2max      Create
 **********************************************************************************/
import { LightningElement, wire, api, track } from "lwc";
import { callApex, confirm, toast, toggleFullscreen, getCurrencyScale } from "c/com";
import labels from "./oppMarketLineLabels";

import { subscribe, MessageContext, APPLICATION_SCOPE } from "lightning/messageService";
import OPP_DATA_CHANGED from "@salesforce/messageChannel/OPP_OpportunityDataChanged__c";

import { subscribe as empSubscribe, unsubscribe as empUnsubscribe } from "lightning/empApi";

import initMeta from "@salesforce/apex/OPP_MarketLine_Ctrl.initMeta";
import queryRows from "@salesforce/apex/OPP_MarketLine_Ctrl.queryRows";
import saveRows from "@salesforce/apex/OPP_MarketLine_Ctrl.saveRows";
import checkNeedRecalculate from "@salesforce/apex/OPP_MarketLine_Ctrl.checkNeedRecalculate";
// import refreshCtx from '@salesforce/apex/OPP_MarketLine_Ctrl.refreshCtx';

import { applyAllCalcRules, applyCalcRulesForChange, initCalcRules, validateCalcRulesOnLoad, recalcBrkgAdjRows } from "./oppMarketLineCalc";

export default class oppMarketLineManage extends LightningElement {
    @api recordId;

    @api
    get selectedCurrency() {
        return this._selectedCurrency;
    }
    set selectedCurrency(value) {
        this._selectedCurrency = value;
        if (value) {
            void this.loadData();
        }
    }
    _selectedCurrency;

    // 외부에서 선택된 행 목록 조회 (Allocation 등에서 사용)
    @api
    getSelectedRows() {
        const grid = this.template.querySelector("c-opp-market-line-table");
        return grid ? grid.getSelectedRows() : [];
    }
    // 외부에서 선택된 행 해제 (Allocation 등에서 사용)
    @api
    clearSelection() {
        const grid = this.template.querySelector("c-opp-market-line-table");
        if (grid) {
            grid.clearSelection();
        }
    }

    labels = labels;

    @track columns = [];
    @track rows = [];
    isLoading = false;

    isFullscreen = false;

    isInit = false;
    isSaveDisabled = true;
    isReadOnly = false;
    isOpp = true;
    isClaim = false;
    isCICase = false;
    isPlacement = false;
    @track _bizRegion = "";
    get bizRegion() {
        // console.log("[KYC] manage template bizRegion=", this._bizRegion);
        return this._bizRegion;
    }
    set bizRegion(v) {
        this._bizRegion = v;
    }
    claimCurrency = "";

    // 서버에서 내려주는 참조값(ctx_*)
    ctx = {};

    _marketRuleByType = {}; // { 'Facility': rule, 'MGA': rule, ... }

    @track collapsedByGroup = {}; // { [groupName]: true|false }
    groupIndex = {}; // { [groupName]: { primaryKey, collapsible } }

    @track isAllCollapsed = false;
    @track isGroupToggleDisabled = false;

    // KYC 에러 상태 관리 (Set<rowId>)
    kycErrors = new Set();

    // 계산식 관련 변수
    _calcRules = [];
    _calcRulesByDependencyKey = {};

    // 원본 데이터 보관용 (Dirty Check)
    _originalRowsMap = new Map();

    // 포커스 제어용
    pendingFocus = null;

    get hasFinalizeModified() {
        return this._hasFinalizeModified;
    }
    _hasFinalizeModified = false;
    get hasNeedRecalculate() {
        return this._hasNeedRecalculate;
    }
    _hasNeedRecalculate = false;

    /*
    1. 등록된 레코드가 없으면 true
    2. CI Case이면 true
    3. 수정 중이면 true
     */
    get isSimulDisabled() {
        // 1. 등록된 레코드가 없으면 true
        if (!this.rows || this.rows.length === 0) return true;

        // // 2. 기회가 아니면 true
        // if (!this.isOpp) return true;

        // CI Case이면 true
        if (this.isCICase || this.isClaim) return true;

        // 3. 수정 중이면 true
        return !this.isSaveDisabled;
    }

    get cntFinalizedLine() {
        return (this.rows || []).filter((r) => !r.isDeleted && r.Finalize_is__c === true).length;
    }

    get skeletonRows() {
        return [1, 2, 3, 4, 5]; // 5개 행
    }

    get skeletonCols() {
        return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]; // 10개 열
    }

    @wire(MessageContext)
    messageContext;
    subscription = null;

    async loadMeta() {
        if (!this.recordId) return;

        this.isLoading = true;
        try {
            const meta = await callApex(this, initMeta, { recordId: this.recordId, selectedCurrency: this.selectedCurrency }, { toastOnError: true });
            if (!meta) return;

            this.isReadOnly = meta?.isReadOnly || false;
            this.isOpp = meta?.isOpp === true;
            this.isClaim = meta?.isClaim || false;
            this.isCICase = meta?.isCICase || false;
            this.isPlacement = meta?.isPlacement || false;
            this.bizRegion = meta?.ctx?.ctx_bizRegion || "None";
            this.claimCurrency = meta?.claimCurrency || "";

            this._applyMeta(meta);

            const calcRuleErrors = validateCalcRulesOnLoad(this._calcRules);
            if (calcRuleErrors.length) {
                const snapshot = Array.from(calcRuleErrors || []).map((e) => ({ ...e }));
                console.error("CalcRule validation errors length:", snapshot.length);
                console.error("CalcRule validation errors JSON:\n" + JSON.stringify(snapshot, null, 2));
                console.table(snapshot);
                const msg = this.labels.OPP_MSG_CALC_RULE_CONFIG_ERROR.replace("{0}", calcRuleErrors.length);
                toast(this, this.labels.COM_LBL_ERROR, msg, "error");
            }

            this.collapsedByGroup = this.initCollapsed(false);

            const layerItems = meta?.rows || [];
            this._hasFinalizeModified = false;
            this._setRowsFromLayerItems(layerItems, false);
            this.kycErrors.clear();

            if (this.ctx?.ctx_NeedRecalculate && !this.isReadOnly && !this.isClaim && this.rows.length > 0) {
                this._hasNeedRecalculate = true;
                toast(this, "Warning", this.labels.OPP_MSG_NEED_RECALCULATE, "warning");
            }
        } catch (error) {
            console.error("⛔ loadMeta error", error);
            console.error("message", error?.message, "body", error?.body);
        } finally {
            this.isLoading = false;
        }
    }

    async loadData() {
        if (!this.recordId) {
            this.rows = [];
            this._originalRowsMap.clear();
            return;
        }

        this.isLoading = true;
        try {
            const layerItems = await callApex(this, queryRows, { recordId: this.recordId, selectedCurrency: this.selectedCurrency }, { toastOnError: true });

            if (!layerItems) {
                this.rows = [];
                this._originalRowsMap.clear();
                return;
            }
            this._setRowsFromLayerItems(layerItems, false); //재계산 X
            this.kycErrors.clear(); // 로드 시 에러 초기화
        } catch (error) {
            // toast(this, this.labels.COM_LBL_DATA_RETRIEVAL_FAILED, this.labels.COM_MSG_DATA_LOAD_FAIL, 'error');
            console.error(error);
            this.rows = [];
            this._originalRowsMap.clear();
        } finally {
            this.isLoading = false;
        }
    }

    handleCellChange(event) {
        const { rowId, key, value } = event.detail || {};
        if (!rowId || !key) return;

        const index = this.rows.findIndex((r) => r.Id === rowId);
        if (index < 0) return;

        const rows = [...this.rows];
        const baseRow = rows[index];
        const layerId = baseRow?.layerId || baseRow?.Id;
        // const colMeta = (this.columns || []).find(c => c?.key === key);
        const colMeta = this.columns?.find((c) => c.key === key);
        const isLayerField = colMeta?.groupName === "Layer" || key === "LayerAction";

        // console.log("[CellChange] rowId=", rowId, "key=", key, "layerId=", layerId, "isLayerField=", isLayerField);

        // Layer 필드 변경이면 동일 layerId 전체 row에 반영(계산식 연쇄 포함)
        if (isLayerField) {
            // 1. 먼저 현재 변경된 값을 반영하여 updatedRows를 만듭니다.
            let updatedRows = rows.map((r) => {
                if ((r?.layerId || r?.Id) !== layerId) return r;
                //if (r.CO_is__c || r.BrkgAdj_is__c) return r; // CO나 BrkgAdj인 행은 계산 대상 제외 (기존 값 유지) ???
                // return { ...r, [key]: value };
                const updates = {[key]: value};
                if (key === "Type__c" || key === "LOL__c" || key === "Excess__c") {
                    updates.Layer_fm__c = "";
                }
                // LayerCurrency__c 변경 시 Panel의 Currency__c도 동기화
                if (key === "LayerCurrency__c") {
                    updates.Currency__c = value;
                }
                return {...r, ...updates};
            });
            // 2. Type__c 변경 시 Excess__c 및 LOL__c 자동 계산 로직 수행
            if (key === "Type__c") {
                const currentType = value;
                const newExcessValue = (currentType === "QS" || currentType === "Primary") ? 0 : null;

                updatedRows = updatedRows.map((r) => {
                    if ((r?.layerId || r?.Id) !== layerId) return r;
                    return {...r, Excess__c: newExcessValue, LOL__c: null, Layer_fm__c: ""};
                });
            }

            // 2-2. Type__c 또는 LOL__c 변경 시 QS Row LOL 일괄 재계산
            if (key === "Type__c" || key === "LOL__c") {
                const changedRow = updatedRows.find(r => (r.layerId || r.Id) === layerId);
                if (value === "QS" || changedRow?.Finalize_is__c) {
                    updatedRows = this._recalcQsLOL(updatedRows);
                }
            }

            // 4. 최종적으로 계산식 적용 및 Dirty 상태 업데이트
            // (여기서는 이미 값이 반영된 updatedRows를 사용해야 함)
            this.rows = updatedRows.map((r) => {
                if ((r?.layerId || r?.Id) !== layerId) return r;

                // 이미 Excess__c, LOL__c가 반영된 r을 사용
                let nextRow = r;

                // 계산식 적용 (Type__c 변경에 따른 연쇄 계산)
                nextRow = applyCalcRulesForChange(nextRow, key, this._calcRules, this._calcRulesByDependencyKey, this.ctx);

                return this._updateDirtyState(nextRow);
            });

            this.checkSaveDisabled();
            return;
        } //if (isLayerField) end

        // Panel 필드 변경
        let cellValue = value;

        if (key === "Signed__c") {
            const writtenVal = Number(baseRow.Written__c || 0);
            const signedVal = Number(cellValue || 0);
            if (signedVal > writtenVal) {
                //Signed 값은 Written 값을 초과할 수 없습니다.
                toast(this, this.labels.COM_LBL_WARNING, this.labels.OPP_MSG_SIGNED_EXCEEDS_WRITTEN, "warning");
                cellValue = null;
            }
        }

        let row = { ...baseRow, [key]: cellValue };

        // 값 변경 시 해당 필드의 에러 제거
        if (row._errors && row._errors[key]) {
            const nextErrors = { ...row._errors };
            delete nextErrors[key];
            row._errors = nextErrors;
        }

        if (row.Finalize_is__c === true) {
            row.Finalize_is__c = false;
            this._hasFinalizeModified = true; // 경고 메시지 표시용 플래그

            // BrkgAdj Row 초기화
            const brkgIdx = rows.findIndex((r) => r.BrkgAdj_is__c === true);
            if (brkgIdx >= 0) {
                rows[brkgIdx] = {
                    ...rows[brkgIdx],
                    TotalBrkg__c: 0,
                    NetProducingCobrker__c: 0,
                    NetToLKPrem__c: 0
                };
            }
        }

        if (key === "MarketType__c") {
            const rules = this._marketRuleByType?.[value] || [];

            let fieldsToClear = [];
            if (rules.length > 0) {
                rules.forEach((r) => {
                    if (r.clearFields) fieldsToClear.push(...r.clearFields);
                });
            } else {
                fieldsToClear = ["Facility_lk__c", "MGAName_lk__c"];
            }
            fieldsToClear = [...new Set(fieldsToClear)];

            for (const f of fieldsToClear) row[f] = null;

            row._marketLookup = this._deriveMarketLookupFromRow(row);

            for (const f of fieldsToClear) {
                row = applyCalcRulesForChange(row, f, this._calcRules, this._calcRulesByDependencyKey, this.ctx);
            }
        }
        // 부모 필드 변경 시 dependsOn 걸린 필드 초기화
        // - columns의 col.depends가 ['Reinsurer_lk__c'] 형태
        // - key가 변경되면, 해당 key를 depends에 포함한 컬럼들을 clear
        const depCols = (this.columns || []).filter((c) => Array.isArray(c.depends) && c.depends.includes(key));
        if (depCols.length > 0) {
            // 중복 제거
            const clearKeys = [...new Set(depCols.map((c) => c.key).filter(Boolean))];

            for (const ck of clearKeys) {
                // 값 초기화
                row[ck] = null;

                // 해당 필드 에러도 제거
                if (row._errors && row._errors[ck]) {
                    const nextErrors = {...row._errors};
                    delete nextErrors[ck];
                    row._errors = nextErrors;
                }

                // 계산식 연쇄가 필요하면(lookup 변경으로 수식/합계 영향) 여기서도 태움
                row = applyCalcRulesForChange(row, ck, this._calcRules, this._calcRulesByDependencyKey, this.ctx);
            }
        }

        row = applyCalcRulesForChange(row, key, this._calcRules, this._calcRulesByDependencyKey, this.ctx);
        row = this._updateDirtyState(row);

        rows[index] = row;
        this.rows = rows;

        this.checkSaveDisabled();
    }

    _updateDirtyState(row) {
        if (row._isNew) return row; // 신규 행은 항상 Dirty

        const original = this._originalRowsMap.get(row.Id);
        if (!original) {
            console.warn(`[DirtyCheck] Original row not found for ${row.Id}`);
            return row;
        }

        const changes = { ...(row._changes || {}) };
        let isEdited = false;

        // 현재 행의 모든 키를 순회하며 비교 (또는 컬럼 기준)
        // 성능을 위해 columns에 정의된 키만 비교
        for (const col of this.columns) {
            const key = col.key;
            if (!key || col.type === "button") continue;

            const currVal = row[key];
            const origVal = original[key];

            if (!this._isSameValue(currVal, origVal)) {
                // console.log(`[DirtyCheck] 🪔🪔🪔🪔🪔 Diff: key=${key}, curr=${currVal}, orig=${origVal}`);
                changes[key] = true;
            } else {
                delete changes[key];
            }
        }

        // _changes 객체가 비어있는지 확인
        isEdited = changes && Object.keys(changes).length > 0;

        return { ...row, _changes: changes, isEdited };
    }

    // 값 비교 유틸 (null, undefined, '' 처리)
    _isSameValue(v1, v2) {
        const isEmpty = (v) => v === null || v === undefined || v === "";
        if (isEmpty(v1) && isEmpty(v2)) return true;
        if (isEmpty(v1) && (v2 === 0 || v2 === false)) return true;
        if (isEmpty(v2) && (v1 === 0 || v1 === false)) return true;
        return String(v1) === String(v2);
    }

    // 저장 버튼 활성화 여부 체크
    checkSaveDisabled() {
        // 1. 신규 행이 있는가?
        const hasNew = this.rows.some((r) => r._isNew && !r.isDeleted);

        // 2. 삭제된 행이 있는가?
        const hasDeleted = this.rows.some((r) => r.isDeleted && !r._isNew); // 신규 행 삭제는 제외

        // 3. 수정된 행이 있는가?
        const hasEdited = this.rows.some((r) => r.isEdited && !r.isDeleted);

        // console.log(`[checkSaveDisabled] hasNew=${hasNew}, hasDeleted=${hasDeleted}, hasEdited=${hasEdited}`);
        this.isSaveDisabled = !(hasNew || hasDeleted || hasEdited);
    }

    handleKycStatusChange(event) {
        const { rowId, isKycIncomplete } = event.detail;
        //console.log(`[KYC Status] rowId=${rowId}, incomplete=${isKycIncomplete}`);
        if (isKycIncomplete) {
            this.kycErrors.add(rowId);
        } else {
            this.kycErrors.delete(rowId);
        }
        //console.log('[KYC Errors]', Array.from(this.kycErrors));
    }

    async handleAction(event) {
        const action = event.detail?.value || event.currentTarget?.dataset?.action;
        const grid = this.template.querySelector("c-opp-market-line-table");

        switch (action) {
            case "refresh":
                void this.onReset();
                break;
            case "refreshCtx":
                void this.onRefreshCtx();
                break;
            case "addRow":
                void this.onAddRow(false);
                break;
            case "delRow":
                void this.onDeleteRow();
                break;
            case "toggleGroup": {
                if (grid) {
                    if (this.isAllCollapsed) {
                        grid.expandAll();
                    } else {
                        grid.collapseAll();
                    }
                    this._syncToolbarFromGrid();
                }
                break;
            }
            case "expand_alt": {
                const target = this.template.querySelector(".fsRoot") ?? this.template.host;
                this.isFullscreen = await toggleFullscreen(target, { className: "pseudo-fs", lockScroll: true });
                break;
            }
            case "save":
                await this.onSave();
                break;
            case "simulation": {
                // 선택된 Panel ID 목록 추출
                const selectedRows = grid ? grid.getSelectedRows() : [];

                // 1. 시뮬레이션할 대상을 선택
                if (selectedRows.length === 0 && !this.isReadOnly) {
                    //'시뮬레이션할 대상을 선택해주세요.'
                    toast(this, this.labels.COM_LBL_WARNING, this.labels.OPP_MSG_SELECT_TARGET_FOR_SIMULATION, "warning");
                    return;
                }

                // 전부 QS이면 시뮬레이션 불가
                const validRows = selectedRows.filter((r) => !r.isDeleted && !r.BrkgAdj_is__c);
                // const validRows = selectedRows.filter(r => !r.isDeleted && !r.BrkgAdj_is__c && !r.CO_is__c);
                const isAllQS = validRows.length > 0 && validRows.every((r) => r.Type__c === "QS");
                // if (isAllQS) {
                //     toast(this, this.labels.COM_LBL_WARNING, '선택된 항목이 모두 QS인 경우 시뮬레이션을 진행할 수 없습니다.', 'warning');
                //     return;
                // }
                // const panelIds = selectedRows.map(r => r.Id);
                const panelIds = this.isReadOnly
                      ? this.rows.filter((r) => r.Finalize_is__c || r.BrkgAdj_is__c).map((r) => r.Id)
                      : selectedRows.map((r) => r.Id);

                console.log("🛢️🛢️🛢️ this.isPlacement=[" + this.isPlacement + "], panelIds=", JSON.stringify(panelIds));

                this.template.querySelector("c-opp-modal-container").openPopup("SIMULATION", {
                    recordId: this.recordId,
                    selectedCurrency: this.selectedCurrency,
                    panelIds: panelIds,
                    isReadOnly: this.isReadOnly,
                    isPlacement: this.isPlacement,
                    isAllQS: isAllQS
                });
                break;
            }
            case "createCO": {
                void this.onAddRow(true);
                break;
            }
            default:
                toast(this, this.labels.COM_LBL_NOTICE, action + " 기능은 준비 중입니다.", "info");
                console.warn("Unknown action:", action);
        }
    }

    handleAddPanel(event) {
        console.log("[Manage > handleAddPanel Start ⭐️");
        const rowNo = event.detail && event.detail.rowNo;
        if (!rowNo || !Array.isArray(this.rows) || this.rows.length === 0) return;

        // 클릭한 Layer 블록의 "첫 행" index (rowNo는 1-base)
        const headerIndex = rowNo - 1;
        if (headerIndex < 0 || headerIndex >= this.rows.length) return;

        const rows = [...this.rows];
        const headerRow = rows[headerIndex];
        if (!headerRow) return;

        const layerId = headerRow.layerId || headerRow.Id;

        // 기존 layerRowSpan
        const spanBefore = headerRow.layerRowSpan || 1;
        headerRow.layerRowSpan = spanBefore + 1;

        // 신규 Panel 한 줄 생성
        const newRow = this.createBlankRow(layerId);
        // Layer 필드 값 복사
        const layerCols = (this.columns || []).filter(c => c.groupName === 'Layer');
        for (const col of layerCols) {
            if (col.key && headerRow[col.key] !== undefined) {
                newRow[col.key] = headerRow[col.key];
            }
        }

        const ranStr = Math.random().toString(36).substring(2, 5); // a-z0-9 3글자
        newRow.Id = newRow.panelId = `${layerId}@${ranStr}`;
        newRow.layerId = layerId;
        newRow.layerRowSpan = 0; // 첫 행만 rowspan
        newRow.Currency__c =  this.selectedCurrency;
        // 기존 Layer 블록의 마지막 Panel 바로 뒤에 끼워 넣기
        const insertIndex = headerIndex + spanBefore;
        // CalcRule 일괄 적용
        const calculatedRow = applyAllCalcRules(newRow, this._calcRules, this.ctx);
        rows.splice(insertIndex, 0, calculatedRow);
        //rows.splice(insertIndex, 0, newRow);

        // rowNo 재부여
        this._reindexRows(rows);

        this.rows = rows;
        this.checkSaveDisabled();
    }

    async handleDelPanel(event) {
        const { layerId, panelId } = event.detail || {};
        if (!layerId || !panelId || !Array.isArray(this.rows) || !this.rows.length) return;

        let rows = [...this.rows];

        // 삭제 대상 Panel 행 찾기
        const idx = rows.findIndex((r) => (r.panelId ?? r.Id) === panelId);
        if (idx === -1) return;

        const target = rows[idx];

        // 이 Layer에 속한 "보이는 Panel" 목록 (isDeleted = false 기준)
        const activeIdxList = [];
        rows.forEach((r, i) => {
            if (r.layerId === layerId && !r.isDeleted) activeIdxList.push(i);
        });

        const panelCount = activeIdxList.length;
        if (panelCount === 0) return;

        const isTempLayer = typeof layerId === "string" && layerId.startsWith("tmp_");
        const isTempPanel = typeof target.Id === "string" && target.Id.startsWith("tmp_");
        const isLastPanel = panelCount === 1;

        // 마지막 Panel인 경우 → Layer 삭제 여부 확인
        if (isLastPanel) {
            const ok = await confirm(this.labels.OPP_MSG_CONFIRM_LAYER_DELETE);
            if (!ok) return;

            if (isTempLayer) {
                // 신규 Layer: rows 에서 완전히 제거
                rows = rows.filter((r) => r.layerId !== layerId);
            } else {
                // 기존 Layer: isDeleted = true 만 세팅 (나중에 Save 시 삭제)
                rows = rows.map((r) => (r.layerId === layerId ? { ...r, isDeleted: true } : r));
            }
        } else {
            // Panel만 삭제
            if (isTempPanel) {
                rows.splice(idx, 1);
            } else {
                rows[idx] = { ...rows[idx], isDeleted: true };
            }

            // 남은 Panel 개수 다시 계산
            const remainIdxList = [];
            rows.forEach((r, i) => {
                if (r.layerId === layerId && !r.isDeleted) remainIdxList.push(i);
            });

            // 이 Layer 전체의 layerRowSpan 초기화
            rows = rows.map((r) => (r.layerId === layerId ? { ...r, layerRowSpan: 0 } : r));

            // 남은 Panel 중 첫 번째 행에만 layerRowSpan 세팅
            if (remainIdxList.length > 0) {
                const firstIdx = remainIdxList[0];
                rows[firstIdx] = { ...rows[firstIdx], layerRowSpan: remainIdxList.length };
            }
        }

        // rowNo 재부여
        this._reindexRows(rows);

        this.rows = rows;
        this.checkSaveDisabled();
    }

    async handleDelLayer(event) {
        console.log("[Manage > handleDelLayer Start ⭐️");
        const { layerId } = event.detail || {};
        if (!layerId) return;

        if (!(await confirm(this.labels.OPP_MSG_CONFIRM_LAYER_DELETE))) return;

        this._deleteLayers([layerId]);
    }

    // ===== 팝업 핸들러 =====
    handleOpenSubjectivity(event) {
        // console.log('[Manage > handleOpenSubjectivity Start ⭐️')
        const { panelId, reinsurerId } = event.detail;
        if (!panelId) return;

        this.template.querySelector("c-opp-modal-container").openPopup("SUBJECTIVITY", {
            panelId: panelId,
            reinsurerId: reinsurerId,
            isReadOnly: this.isReadOnly,
            recordId: this.recordId
        });
    }

    handleOpenMarketSearch(event) {
        // console.log('[Manage > handleOpenMarketSearch Start ⭐️')
        const { rowId, key, type, parentId } = event.detail;

        this.template.querySelector("c-opp-modal-container").openPopup("MARKET_SEARCH", {
            rowId,
            key,
            type,
            parentId
        });
    }

    handleMarketSelect(event) {
        const { id, name, rowId, key, facilityParticipantId } = event.detail;

        const index = this.rows.findIndex((r) => r.Id === rowId);
        if (index >= 0) {
            const newRows = [...this.rows];
            const newRow = { ...newRows[index] };

            const relationKey = key.replace("__c", "__r");
            newRow[relationKey] = { Name: name }; // 이름 업데이트
            newRow[key] = id;

            // Facility Participant 업데이트
            if (facilityParticipantId) {
                newRow.FacilityParticipant_lk__c = facilityParticipantId;
            }

            newRows[index] = newRow;
            this.rows = newRows; // 배열 레퍼런스 교체 -> 리렌더링 트리거
        }

        // handleCellChange 호출 (계산식 적용 등을 위해)
        this.handleCellChange({
            detail: {
                rowId: rowId,
                key: key,
                value: id
            }
        });
    }

    // Text Editor 오픈
    handleOpenTextEditor(event) {
        const { rowId, key, value, mode, title } = event.detail;
        this.template.querySelector("c-opp-modal-container").openPopup("TEXT_EDITOR", {
            rowId,
            key,
            value,
            mode,
            title,
            isReadOnly: this.isReadOnly
        });
    }

    // [추가] Text Editor 값 적용
    handleTextEditorApply(event) {
        const { rowId, key, value } = event.detail;
        this.handleCellChange({
            detail: {
                rowId,
                key,
                value
            }
        });
    }

    // 자식 그리드가 그룹 상태를 변경할 때 올라오는 이벤트로 동기화
    onGroupStateChange(event) {
        const s = event.detail;
        this.isAllCollapsed = s.allCollapsed;
        this.isGroupToggleDisabled = s.collapsibleCount === 0;
    }

    async onReset() {
        this.init();
        await this.loadMeta();
        this._syncToolbarFromGrid();
        // this.clearSelection();
        toast(this, this.labels.COM_LBL_COMPLETE, this.labels.COM_MSG_GRID_RESET, "success");
    }

    async onReload() {
        await this.loadData();
        this.clearSelection();
        toast(this, this.labels.COM_LBL_COMPLETE, this.labels.COM_MSG_DATA_RELOADED, "success");
    }

    async onRefreshCtx() {

        if (!this.recordId) return;
        this.isLoading = true;
        try {
            const meta = await callApex(this, initMeta, { recordId: this.recordId, selectedCurrency: this.selectedCurrency }, { toastOnError: true });
            if (!meta) return;

            this._applyMeta(meta);

            // const hiddenKeys = new Set( (this.columns || []).filter(c => c.mode === 'hidden').map(c => c.key) );
            const hiddenFields = new Set(this.ctx?.ctx_hiddenFields || []);
            
            this.rows = this.rows.map((r) => {
                const updated = { ...r };
                hiddenFields.forEach(k => { updated[k] = null; });
                // hiddenKeys.forEach(k => { updated[k] = null; });
                // const preserveKeys = new Set([
                //     'CO_is__c', 'BrkgAdj_is__c', 'Finalize_is__c', 'LayerCurrency__c'
                //     'Currency__c', 'MGAName_lk__c', 'FacilityParticipant_lk__c'
                // ]);
                // hiddenKeys.forEach(k => {
                //     if (!preserveKeys.has(k)) updated[k] = null;
                // });
                // Panel Currency가 비어있으면 Layer Currency로 채움
                if (!updated.Currency__c && updated.LayerCurrency__c) {
                    updated.Currency__c = updated.LayerCurrency__c;
                }
                if (this.ctx?.ctx_hasLKPlacingCoBroker && !updated.BrkgAdj_is__c) {
                    updated.CoBroker_lk__c = null;
                }
                const recalced = applyAllCalcRules(updated, this._calcRules, this.ctx);
                return this._updateDirtyState(recalced);
            });

            if (this.rows.some((r) => r?.BrkgAdj_is__c)) this.rows = recalcBrkgAdjRows(this.rows, this.ctx);

            this.checkSaveDisabled();
            const newNeedRecalc = this.ctx?.ctx_NeedRecalculate || false;
            if (newNeedRecalc && !this._hasNeedRecalculate) {
                toast(this, "Warning", this.labels.OPP_MSG_NEED_RECALCULATE, "warning");
            }
            this._hasNeedRecalculate = newNeedRecalc;
            toast(this, this.labels.COM_LBL_COMPLETE, this.labels.OPP_MSG_CONTEXT_REFRESHED, "success");
        } catch (error) {
            console.error("onRefreshCtx error", error);
        } finally {
            this.clearSelection();
            this.isLoading = false;
        }
    }

    async _checkRecalculateRequired() {
        if (this.isReadOnly || this.isClaim) return false;

        const needRecalc = await callApex(this, checkNeedRecalculate, { recordId: this.recordId }, { toastOnError: true });

        if (needRecalc && !this._hasNeedRecalculate) {
            toast(this, "Warning", labels.OPP_MSG_NEED_RECALCULATE, "warning");
        }
        this._hasNeedRecalculate = needRecalc;
        return needRecalc;
    }

    async onAddRow(isCO = false) {
        // if (await this._checkRecalculateRequired()) return;
        await this._checkRecalculateRequired();

        const layerId = `tmp_${Date.now()}`;
        const ranStr = Math.random().toString(36).substring(2, 5);
        const panelId = `${layerId}@${ranStr}`;

        // 1. Layer/Panel 기본값 생성
        let row = this.createBlankRow(layerId);
        row.layerId = layerId;
        row.Id = panelId;
        row.panelId = panelId;
        row.layerRowSpan = 1;
        row.LayerCurrency__c = this.selectedCurrency;
        row.Currency__c = this.selectedCurrency;
        // 2. CO일 때 추가 세팅
        if (isCO) {
            row.CO_is__c = true;
            row.PlacingSettlementType__c = "Separate"; // CO기본값
            row.TotalBrkg__c = 0;
            row.CobrokingType__c = "CO";
            row.NetProducingCobrker__c = 0;
            row.NetToLKPrem__c = 0;
            row.NetToUW__c = 0;
        }
        // 3. 계산식 적용
        row = applyAllCalcRules(row, this._calcRules, this.ctx);

        const rows = [...this.rows, row];
        this._reindexRows(rows);
        this.rows = rows;

        // const firstKey = (this.columns || []).find(c => c.mode === 'edit')?.key;
        // if (firstKey) this.pendingFocus = { rowId: row.Id, key: firstKey };

        // 포커스 (CO일 때는 Remarks__c에 포커스)
        const focusKey = isCO ? "Remarks__c" : (this.columns || []).find((c) => c.mode === "edit")?.key;
        if (focusKey) this.pendingFocus = { rowId: row.Id, key: focusKey };

        this.checkSaveDisabled(); // 상태 체크
    }

    async onDeleteRow() {
        const grid = this.template.querySelector("c-opp-market-line-table");
        if (!grid) return;

        const selectedRows = grid.getSelectedRows();
        if (!selectedRows || selectedRows.length === 0) {
            toast(this, this.labels.OPP_MSG_SELECT_LAYER_TO_DELETE, "error");
            return;
        }

        // Brkg Adj 삭제 방지 => 그리드내 체크박스 비활성화가 더 좋을 것 같음.
        const hasBrkgAdj = selectedRows.some((r) => r.BrkgAdj_is__c);
        if (hasBrkgAdj) {
            toast(this, this.labels.COM_LBL_WARNING, "Brkg Adj 레코드는 삭제할 수 없습니다.", "warning");
            return;
        }

        if (!(await confirm(this.labels.OPP_MSG_CONFIRM_LAYER_DELETE))) return;

        const layerIds = selectedRows.map((r) => r.layerId || r.Id);
        const uniqueLayerIds = [...new Set(layerIds)];

        this._deleteLayers(uniqueLayerIds);
    }

    _deleteLayers(targetLayerIds) {
        if (!targetLayerIds || targetLayerIds.length === 0) return;

        const targets = new Set(targetLayerIds);
        let rows = [...this.rows];
        const nextRows = [];

        for (const r of rows) {
            const lid = r.layerId || r.Id;

            if (targets.has(lid)) {
                const isTempLayer = typeof lid === "string" && lid.startsWith("tmp_");

                if (!isTempLayer) {
                    // 기존 Layer: isDeleted = true 처리
                    nextRows.push({ ...r, isDeleted: true });
                }
            } else {
                nextRows.push(r);
            }
        }

        // rowNo 재부여
        this._reindexRows(nextRows);

        this.rows = nextRows;
        this.checkSaveDisabled(); // [수정] 상태 체크
    }

    async onSave() {
        console.log("[save] start recordId=", this.recordId);

        // 1. 화면 유효성 검사 (Grid 내 필수값 체크 및 표시)
        // if (await this._checkRecalculateRequired()) return;

        const grid = this.template.querySelector("c-opp-market-line-table");
        if (grid && !grid.validate()) {
            toast(this, this.labels.COM_MSG_CHECK_REQUIRED, "error");
            return;
        }

        // LK Placing Co-broker 삭제 확인
        let deleteLKPlacing = false;
        if (this.ctx?.ctx_hasLKPlacingCoBroker) {
            const hasCoBrokerSelected = this.rows.some((r) => !r.isDeleted && r.CoBroker_lk__c);
            if (hasCoBrokerSelected) {
                const ok = await confirm(this.labels.OPP_MSG_DELETE_COBROKING);
                if (!ok) return;
                deleteLKPlacing = true;
            }
        }

        // 비즈니스 로직 유효성 검사 (Signed <= Written)
        for (const row of this.rows) {
            if (row.isDeleted) continue;

            const written = Number(row.Written__c || 0);
            const signed = Number(row.Signed__c || 0);

            if (signed > written) {
                //OPP_MSG_SIGNED_EXCEEDS_WRITTEN_VAL
                const msg = this.labels.OPP_MSG_SIGNED_EXCEEDS_WRITTEN_VAL.replace("{0}", signed).replace("{1}", written);

                // 1. Toast 표시
                toast(this, this.labels.COM_LBL_WARNING, msg, "warning");

                // 2. 해당 행에 에러 마킹 (화면 표시용)
                const newRows = [...this.rows];
                const targetRowIndex = newRows.findIndex((r) => r.Id === row.Id);

                if (targetRowIndex >= 0) {
                    const targetRow = { ...newRows[targetRowIndex] };
                    targetRow._errors = { ...(targetRow._errors || {}), Signed__c: msg };
                    newRows[targetRowIndex] = targetRow;
                    this.rows = newRows; // 화면 갱신 트리거
                }

                return; // 저장 중단
            }
        }

        // CoBroker 선택 시 PlacingSettlementType 필수 체크
        for (const row of this.rows) {
            if (row.isDeleted) continue;
            if (row.CoBroker_lk__c && !row.PlacingSettlementType__c) {
                const msg = this.labels.OPP_MSG_REQUIRE_SETTLEMENT_TYPE;
                toast(this, this.labels.COM_LBL_WARNING, msg, "warning");

                const newRows = [...this.rows];
                const targetRowIndex = newRows.findIndex((r) => r.Id === row.Id);
                if (targetRowIndex >= 0) {
                    const targetRow = { ...newRows[targetRowIndex] };
                    targetRow._errors = { ...(targetRow._errors || {}), PlacingSettlementType__c: msg };
                    newRows[targetRowIndex] = targetRow;
                    this.rows = newRows;
                }
                return;
            }
        }

        // 2. KYC 체크: KYC 완료되지 않았을때 바인딩 불가 레코드 저장은 가능
        // console.log('[save] kycErrors size=', this.kycErrors.size);
        // if (this.kycErrors.size > 0) {
        //     toast(this, '저장 불가', 'KYC가 완료되지 않은 재보험사가 포함되어 있습니다.', 'error');
        //     return;
        // }

        this.isLoading = true;
        try {
            console.log("[save] rows count=", this.rows.length);
            console.log("[save] deleted rows=", this.rows.filter((r) => r.isDeleted).length);

            // const cleanRows = this.rows.map((row) => {
            //     const { _rowNo, _marketLookup, layerRowSpan, _errors, _changes, isEdited, ...rest } = row;
            //     return rest;
            // });
            const cleanRows = this.rows.map((row) => {
                const { _marketLookup, layerRowSpan, _errors, _changes, isEdited, ...rest } = row;
                return rest;
            });

            const layerItems = await callApex(
                this,
                saveRows,
                {
                    recordId: this.recordId,
                    isCICase: this.isCICase,
                    jsonString: JSON.stringify(cleanRows),
                    selectedCurrency: this.selectedCurrency,
                    deleteLKPlacing: deleteLKPlacing
                },
                { toastOnError: true }
            );
            if (!layerItems) return;
            console.log("[save] apex returned len=", layerItems?.length);
            this._setRowsFromLayerItems(layerItems, false); //재계산 X

            this.isSaveDisabled = true;
            this._hasFinalizeModified = false;
            this._hasNeedRecalculate = false;
            toast(this, this.labels.COM_LBL_COMPLETE, this.labels.COM_MSG_SAVE_SUCCESS, "success");
            // void this.onRefreshCtx();
        } catch (error) {
            const raw = JSON.parse(JSON.stringify(error));
            console.error("[save] apex error raw=", raw);
            // toast(this, this.labels.COM_LBL_ERROR, error?.body?.message || error?.message || this.labels.COM_MSG_SAVE_FAIL, 'error' );
        } finally {
            this.isLoading = false;
        }
    }

    handleMessage(message) {
        console.log("[handleMessage] 📣📣📣📣📣 action=", message.action, "isLoading=", this.isLoading);

        if (message.opportunityId !== this.recordId) return;
        if (this.isLoading) return;

        switch (message.action) {
            case "REFRESH":
                void this.onReset();
                break;
            case "NEED_RECALCULATE":
                console.log("[handleMessage] 📣📣📣📣📣 action=", message.action, "111 this._hasNeedRecalculate=", this._hasNeedRecalculate);
                this._hasNeedRecalculate = true;
                toast(this, "Warning", this.labels.OPP_MSG_NEED_RECALCULATE, "warning");
                void this.onRefreshCtx();

                console.log("[handleMessage] 📣📣📣📣📣 action=", message.action, "222 this._hasNeedRecalculate=", this._hasNeedRecalculate);
                break;
        }
    }

    // ===== Group index =====
    buildGroupIndex(cols) {
        const idx = {};
        for (const c of cols || []) {
            const g = c.groupName || "";
            if (!g) continue;
            if (!idx[g]) idx[g] = { primaryKey: null, collapsible: true };
            if (c.groupPrimary) idx[g].primaryKey = c.key;
            if (c.groupCollapsible === false) idx[g].collapsible = false;
        }
        return idx;
    }

    initCollapsed(v) {
        const next = {};
        for (const [name, meta] of Object.entries(this.groupIndex)) {
            next[name] = meta.collapsible ? v : false;
        }
        return next;
    }

    // ===== 6) 유틸 =====
    createBlankRow(layerId = null) {
        const r = { _isNew: true };
        for (const c of this.columns) {
            switch (c.type) {
                case "num":
                case "percent":
                case "picklist":
                case "lookup":
                case "d":
                case "dt":
                    r[c.key] = null;
                    break;
                case "checkbox":
                    r[c.key] = false;
                    break;
                case "multipicklist":
                    r[c.key] = [];
                    break;
                default:
                    r[c.key] = "";
            }
        }
        // Default Value Setting
        if ("Finalize_is__c" in r) r.Finalize_is__c = false;
        if ("LKCoBrokingSharing_is__c" in r) r.LKCoBrokingSharing_is__c = false;
        if ("DPPct__c" in r) r.DPPct__c = 100;
        if (layerId) r.layerId = layerId;
        return r;
    }

    init() {
        this.columns = [];
        this.rows = [];
        this.ctx = {};

        this._marketRuleByType = {};
        this._calcRules = [];
        this._calcRulesByDependencyKey = {};

        this.groupIndex = {};
        this.collapsedByGroup = {};
        this.isSaveDisabled = true;
        this.isAllCollapsed = false;
        this.isGroupToggleDisabled = true;
        this.kycErrors.clear();
        this._originalRowsMap.clear();
    }

    _decorateMarketLookup(row) {
        const next = { ...row };
        next._marketLookup = this._deriveMarketLookupFromRow(next);
        return next;
    }

    _deriveMarketLookupFromRow(row) {
        const mt = row?.MarketType__c;
        const rules = mt && this._marketRuleByType[mt] ? this._marketRuleByType[mt] : [];

        const configMap = {};
        if (rules.length === 0) {
            // Default fallback
            configMap["Facility_lk__c"] = { uiKey: "Facility_lk__c", activeField: "Facility_lk__c", disabled: false };
        } else {
            for (const rule of rules) {
                if (rule.uiKey) {
                    configMap[rule.uiKey] = {
                        uiKey: rule.uiKey,
                        activeField: rule.activeField,
                        lookupObject: rule.lookupObject,
                        disabled: !!rule.disabled,
                        filterField: rule.filterField || null,
                        filterValue: rule.filterValue || null
                    };
                }
            }
        }
        return configMap;
    }

    _setRowsFromLayerItems(layerItems, shouldRecalculate = false) {
        const flat = [];

        for (const layer of layerItems || []) {
            const layerId = layer?.Id;
            const layerValues = layer?.layerValues || {};
            const panels = (layer?.marketLineItems || []).filter((p) => !p?.isDeleted);

            if (!panels.length) {
                flat.push({
                    Id: layerId,
                    layerId,
                    panelId: layerId,
                    layerRowSpan: 1,
                    ...layerValues
                });
                continue;
            }

            panels.forEach((p, idx) => {
                flat.push({
                    Id: p.Id,
                    layerId: p.layerId || layerId,
                    panelId: p.Id,
                    layerRowSpan: idx === 0 ? panels.length : 0,
                    ...layerValues,
                    ...(p.values || {})
                });
            });
        }

        const decoratedRows = flat.map((r) => this._decorateMarketLookup(r));
        // const calculatedRows = decoratedRows.map(r => applyAllCalcRules(r, this._calcRules, this.ctx));
        const calculatedRows = shouldRecalculate ? decoratedRows.map((r) => applyAllCalcRules(r, this._calcRules, this.ctx)) : decoratedRows;
        this._reindexRows(calculatedRows);

        this._originalRowsMap.clear();
        calculatedRows.forEach((r) => {
            this._originalRowsMap.set(r.Id, JSON.parse(JSON.stringify(r)));
        });
        //console.log('[DEBUG] Original Map Size:', this._originalRowsMap.size);

        this.rows = calculatedRows;
        this.checkSaveDisabled(); // [추가] 초기 상태 체크
    }

    _reindexRows(rows) {
        let count = 0;
        (rows || []).forEach((r) => {
            if (!r.isDeleted) {
                count++;
                r._rowNo = count;
            }
        });
    }

    // 툴바 상태 강제 동기화용
    _syncToolbarFromGrid() {
        const grid = this.template.querySelector("c-opp-market-line-table");
        if (!grid?.getCollapseSummary) return;
        const s = grid.getCollapseSummary();
        this.isAllCollapsed = s.allCollapsed;
        this.isGroupToggleDisabled = s.collapsibleCount === 0;
    }

    subscribeToMessageChannel() {
        if (!this.subscription) {
            this.subscription = subscribe(this.messageContext, OPP_DATA_CHANGED, (message) => this.handleMessage(message), { scope: APPLICATION_SCOPE });
        }
        // console.log("[MessageChannel] Subscribed to OPP_DATA_CHANGED");
    }

    _applyMeta(meta) {
        this.ctx = meta?.ctx || {};
        this.ctx.currencyScale = getCurrencyScale(this.selectedCurrency);
        this.columns = meta?.columns || [];

        const rules = meta?.rules || {};
        const marketTypeRules = rules?.marketTypeRules || [];
        const calcRules = rules?.calcRules || [];

        // market rule index
        const indexByMarketType = {};
        for (const rule of marketTypeRules) {
            if (rule?.marketType) {
                if (!indexByMarketType[rule.marketType]) indexByMarketType[rule.marketType] = [];
                indexByMarketType[rule.marketType].push(rule);
            }
        }
        this._marketRuleByType = indexByMarketType;

        // calc rules
        const calcInitResult = initCalcRules(this.columns, calcRules, this.ctx);
        this._calcRules = calcInitResult.calcRules;
        this._calcRulesByDependencyKey = calcInitResult.calcRulesByDependencyKey;

        this.groupIndex = this.buildGroupIndex(this.columns);
    }

    _subscribePlatformEvent() {
        const channel = "/event/OPP_RecordChanged__e";
        empSubscribe(channel, -1, (event) => {
            const data = event?.data?.payload;
            if (!data) return;
            if (data.RecordId__c !== this.recordId) return;
            if (this.isLoading) return;
            console.log("[empApi] OPP_RecordChanged__e received", data.Action__c);
            if (data.Action__c === "NEED_RECALCULATE" || data.Action__c === "TSI_CHANGED") {
                this._hasNeedRecalculate = true;
                toast(this, "Warning", this.labels.OPP_MSG_NEED_RECALCULATE, "warning");
                void this.onRefreshCtx();
            }
        }).then((sub) => {
            this._empSubscription = sub;
            // console.log("[empApi] Subscribed to OPP_RecordChanged__e");
        });
    }

    _recalcQsLOL(rows) {
        const qsLayerIds = [...new Set(
            rows.filter(r => r.Type__c === "QS" && !r.BrkgAdj_is__c && !r.CO_is__c)
                .map(r => r.layerId || r.Id)
        )];
        if (!qsLayerIds.length) return rows;

        const maxLOL = Math.max(0, ...rows
            .filter(r => r.Finalize_is__c && r.Type__c !== "QS")
            .map(r => Number(r.LOL__c || 0))
        );
        const newQsLOL = maxLOL > 0 ? maxLOL : null;

        return rows.map(r => {
            if (!qsLayerIds.includes(r.layerId || r.Id)) return r;
            return this._updateDirtyState({ ...r, LOL__c: newQsLOL, Layer_fm__c: "" });
        });
    }

    // ===== 2) 라이프사이클 =====
    _empSubscription = null;

    async connectedCallback() {
        this.subscribeToMessageChannel();
        this._subscribePlatformEvent();

        if (this.recordId && !this.isInit) {
            await this.loadMeta();
            this._syncToolbarFromGrid();
            this.isInit = true;
        }
    }

    disconnectedCallback() {
        if (this._empSubscription) {
            void empUnsubscribe(this._empSubscription);
            this._empSubscription = null;
        }
    }

    renderedCallback() {
        if (!this.pendingFocus) return;
        const { rowId, key } = this.pendingFocus;

        const el = this.template.querySelector(
            `c-opp-market-line-cell[data-row-id="${rowId}"][data-key="${key}"] lightning-input, 
             c-opp-market-line-cell[data-row-id="${rowId}"][data-key="${key}"] lightning-combobox,
             c-com-lookup[data-row-id="${rowId}"][data-key="${key}"]`
        );
        el?.focus?.();
        this.pendingFocus = null;
    }
}