/**********************************************************************************
 * @filename      : oppMarketLineTable.js
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
import {api, LightningElement} from 'lwc';

const DEBOUNCE_DELAY = 0; // 디바운싱을 위한 변수, 0ms 지연으로 다음 렌더링 사이클까지 기다림

// BRKG ADJ Row 일 때 빈값으로 보여줄 필드들 (이 필드만 빈값, 나머지는 표시)
const BRKG_ADJ_BLANK_FIELDS = new Set([
    'LayerAction', 'Finalize_is__c', 'Leader_is__c', 'Signed__c', 'DPPct__c',
    'RICommPct__c','Reinsurer_lk__c', 'CoBroker_lk__c','Others__c', 'BrkgBase__c',
    'RIContact_lk__c', 'CoBrokerContact_lk__c', 'CobrokingType__c', 'PlacingSettlementType__c', 'Security_lk__c'
]);//'LKPlacingSharingPct__c', 'LKProducingSharingPct__c',
// CO Row 일 때 빈값으로 보여줄 필드들 (이 필드만 빈값, 나머지는 표시)
const CO_BLANK_FIELDS = new Set([
    'LayerCurrency__c', 'Excess__c', 'DPPct__c', 'GrossPrem__c'
]);
/**
 * 셀 빈값 표시 규칙 목록
 *
 * 조건 a: [ALL] BrkgAdj Row (BrkgAdj_is__c=true)
 *     'LayerAction', 'Finalize_is__c', 'Leader_is__c', 'Signed__c', 'DPPct__c',
 *     'RICommPct__c','Reinsurer_lk__c', 'CoBroker_lk__c','Others__c', 'BrkgBase__c',
 *     'RIContact_lk__c', 'CoBrokerContact_lk__c', 'CobrokingType__c', 'PlacingSettlementType__c', 'Security_lk__c'
 *
 * 조건 b: [Placement only] 1 AND 2 AND 3
 *        1. Placement__c.TransactionType__c == 'END'
 *        2. OPP_Layer__c.Type__c === 'QS'
 *        3. OPP_PremiumSchedule__c.PaymentType__c <> SOA 레코드가 있을때
 *
 * 조건 c: [Placement only] 1 AND 2 AND 3
 *        1. Placement__c.TransactionType__c == 'END'
 *        2. OPP_Layer__c.Type__c <> 'QS'
 *        3. OPP_PremiumSchedule__c.PaymentType__c <> SOA 레코드가 있을때
 *
 * 조건 d: [Placement only] Declaration Placement 일 때: Placement__c.TransactionType__c == 'Declaration'
 *
 * 조건 e: [Opportunity OR Placement] 1 AND 2 AND 3
 *        1. Opportunity.TransactionType__c contains 'New' OR Placement__c.TransactionType__c Contains 'New'
 *        2. OPP_Layer__c.Type__c === 'QS'
 *        3. OPP_PremiumSchedule__c.PaymentType__c <> SOA 레코드가 있을때
 *
 * 조건 f: [Opportunity OR Placement] 1 AND 2
 *        1. Opportunity.TransactionType__c contains 'New' OR Placement__c.TransactionType__c contains 'New'
 *        2. OPP_PremiumSchedule__c.PaymentType__c === SOA 레코드가 있을때
 *
 * 조건 g: [Placement only] ( ( 1 OR (2 AND 3) ) AND 4)
 *        1. Placement__c.TransactionType__c === 'END'
 *        2. Placement__c.TransactionType__c contains 'New'
 *        3. OPP_PremiumSchedule__c.PaymentType__c !== SOA 레코드가 있을때
 *        4. OPP_Layer__r.Type__c = QS
 *        ==> DPPct__c, ActualAdjRatePct__c
 *
 * 조건 h: [Placement only] Placement__c.TransactionType__c === 'END' && OPP_Layer__r.Type__c !== 'QS'
 *        ==> GrossPremDP__c
 */
const BLANK_RULES = [
    { // a. BrkgAdj (기존)
        condition: (row) => row.BrkgAdj_is__c,
        blankFields: BRKG_ADJ_BLANK_FIELDS
    },
    { // b. END + QS + non-SOA (Placement only)
        condition: (row, ctx, currency) => ctx.ctx_isPlacementEND && !ctx.ctx_isSOAByCurrency?.[currency] && row.Type__c === 'QS',
        blankFields: new Set(['DPPct__c', 'ActualAdjRatePct__c'])
    },
    // { // c. END + non-QS + non-SOA (Placement only)
    //     condition: (row, ctx, currency) => ctx.ctx_isPlacementEND && !ctx.ctx_isSOAByCurrency?.[currency] && row.Type__c !== 'QS',
    //     blankFields: new Set(['GrossPremDP__c'])
    // },
    { // d. Declaration (Placement only)
        condition: (row, ctx) => ctx.ctx_isPlacementDeclaration,
        blankFields: new Set(['ActualAdjRatePct__c'])
    },
    { // e. New + non-SOA + QS (Opp + Placement)
        condition: (row, ctx, currency) => ctx.ctx_isNew && !ctx.ctx_isSOAByCurrency?.[currency] && row.Type__c === 'QS',
        blankFields: new Set(['DPPct__c', 'ActualAdjRatePct__c'])
    },
    { // f. New + SOA (Opp + Placement)
        condition: (row, ctx, currency) => ctx.ctx_isNew && !!ctx.ctx_isSOAByCurrency?.[currency],
        blankFields: new Set(['GrossPremDP__c'])
    },
    { // g. (END OR (New AND non-SOA)) AND Type = QS
        condition: (row, ctx, currency) => (ctx.ctx_isPlacementEND || (ctx.ctx_isNew && !ctx.ctx_isSOAByCurrency?.[currency])) &&
            row.Type__c === 'QS',
        blankFields: new Set(['DPPct__c', 'ActualAdjRatePct__c'])
    },
//     { // h. END Placement
//         condition: (row, ctx) => ctx.ctx_isPlacementEND && row.Type__c !== 'QS',
//         blankFields: new Set(['GrossPremDP__c'])
//     },
    { // CO Row
        condition: (row) => row.CO_is__c,
        blankFields: CO_BLANK_FIELDS
    },

];

/**
 * @description 셀 빈값 여부 판단 — BLANK_RULES를 순회하며 매칭되는 규칙의 blankFields를 누적 체크
 * @param {Object} row 행 데이터 (panel values)
 * @param {Object} col 컬럼 메타 (key, type 등)
 * @param {Object} ctx buildCtx에서 내려온 컨텍스트 맵
 * @param {String} currency 현재 선택된 통화
 * @returns {Boolean} true면 해당 셀을 빈값으로 표시
 */
function isBlankCell(row, col, ctx, currency) {
    if (!ctx || Object.keys(ctx).length === 0) return false;
    // if (ctx?.ctx_isTreaty) return false;
    for (const rule of BLANK_RULES) {
        if (rule.condition(row, ctx, currency) && rule.blankFields?.has(col.key)) {
            return true;
        }
    }
    return false;
}

const READONLY_RULES = [
    { // Declaration + SOA → DPPct__c readOnly
        condition: (row, ctx, currency) => ctx.ctx_isPlacementDeclaration && !!ctx.ctx_isSOAByCurrency?.[currency],
        readOnlyFields: new Set(['DPPct__c'])
    },
];

function isReadOnlyCell(row, col, ctx, currency) {
    if (!ctx || Object.keys(ctx).length === 0) return false;
    // if (ctx?.ctx_isTreaty) return false;
    for (const rule of READONLY_RULES) {
        if (rule.condition(row, ctx, currency) && rule.readOnlyFields?.has(col.key)) {
            return true;
        }
    }
    return false;
}

export default class oppMarketLineTable extends LightningElement {

    @api isReadOnly = false;
    @api isCiCase = false; // CI Case 여부
    @api isPlacement = false; // CI Case 여부
    @api isOpp = false;
    @api bizRegion = '';
    @api selectedCurrency = '';
    _ctx = {};
    @api
    get ctx() { return this._ctx; }
    set ctx(v) {
        this._ctx = v || {};
        this.scheduleRebuild();
    }
    _columns = [];
    _rows = [];

    leafColumns = [];
    headerRow1 = [];
    headerRow2 = [];
    displayRows = [];

    isAllSelected = false;
    _collapsed = {};

    _debounceTimer;

    _isClaim = false;
    @api
    get isClaim() {
        return this._isClaim;
    }
    set isClaim(value) {
        this._isClaim = value;
        this.scheduleRebuild(); // 직접 호출 대신 스케줄링
    }
    _claimCurrency = '';
    @api
    get claimCurrency() {
        return this._claimCurrency;
    }
    set claimCurrency(value) {
        this._claimCurrency = value;
        // if(this.isClaim) this._rebuildDisplayRows();
        this.scheduleRebuild(); // 직접 호출 대신 스케줄링
    }

    /**
     * _rebuildDisplayRows() 호출을 스케줄링
     * 짧은 시간 내에 여러 번 호출되어도 마지막 호출만 실행
     */
    scheduleRebuild() {
        // 기존에 예약된 타이머가 있다면 취소
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
        this._debounceTimer = setTimeout(() => { this._rebuildDisplayRows(); }, DEBOUNCE_DELAY);
    }

    // 요약 정보
    @api getCollapseSummary() {
        const groups = this._extractGroups(this._columns);
        // const names = Object.keys(groups).filter(g => (groups[g] || []).length > 1);
        const names = Object.keys(groups).filter(g => {
            const cols = groups[g] || [];
            return cols.length > 1 && !cols.some(c => c.groupCollapsible === false);
        });
        const collapsedCount = names.filter(g => !!this._collapsed[g]).length;
        return {
            collapsibleCount: names.length,
            collapsedCount,
            allCollapsed: names.length > 0 && collapsedCount === names.length,
            allExpanded: collapsedCount === 0,
            collapsedMap: { ...this._collapsed }
        };
    }
    _emitGroupState() {
        const s = this.getCollapseSummary();
        this.dispatchEvent(new CustomEvent('groupstatechange', { detail: s, bubbles: true, composed: true }));
    }

    // 토글 API
    @api collapseAll() {
        const groups = this._extractGroups(this._columns);
        const next = {};
        Object.keys(groups).forEach(g => {
            const colsInGroup = groups[g] || [];
            next[g] = colsInGroup.length > 1 && !colsInGroup.some(c => c.groupCollapsible === false);
        });
        this._collapsed = next;
        this._buildHeaders();
        this._rebuildDisplayRows();
        this._emitGroupState();
    }
    @api expandAll() {
        const groups = this._extractGroups(this._columns);
        const next = {};
        Object.keys(groups).forEach(g => (next[g] = false));
        this._collapsed = next;
        this._buildHeaders();
        this._rebuildDisplayRows();
        this._emitGroupState();
    }

    // Setters
    @api
    set columns(v) {

        this._columns = JSON.parse(JSON.stringify(Array.isArray(v) ? v : []));

        for (const c of this._columns) {
            let colStyle = c.width
                ? `width:${c.width}px;min-width:${c.width}px;`
                : (c.style || '');

            if (c.key === 'MLAction') colStyle += 'border-left: 1px solid rgb(221, 219, 218);';
            c.style = colStyle;
            c.isLayer = (c.groupName === 'Layer');
            const mode = (c.mode || '').toLowerCase().trim();
            c.isHidden = mode === 'hidden';
        }

        // 렌더링에서만 hidden 컬럼 제거
        this._renderColumns = this._columns.filter(c => !c.isHidden);

        const groups = this._extractGroups(this._renderColumns);
        const next = { ...(this._collapsed || {}) };
        for (const g of Object.keys(groups)) {
            // if (!(g in next)) next[g] = false;
            if (!(g in next)) next[g] = !!groups[g][0]?.collapsed;
            if (groups[g].length <= 1) next[g] = false;
        }
        this._collapsed = next;

        this._buildHeaders();
        this._rebuildDisplayRows();
    }
    get columns() {
        return this._columns;
    }

    @api
    set rows(v) {
        this._rows = Array.isArray(v) ? JSON.parse(JSON.stringify(v)) : [];
        //this._rebuildDisplayRows();
        this.scheduleRebuild(); // 직접 호출 대신 스케줄링
    }
    get rows() {
        return this._rows;
    }

    // 선택된 Panel 행들만 반환
    @api getSelectedRows() {
        return (this.displayRows || []).filter(r => r.isSelected);
    }
    // 선택된 Panel 행들 해제
    @api clearSelection() {
        this.displayRows = (this.displayRows || []).map(r => { return { ...r, isSelected: false }; });
        this.isAllSelected = false;
        const chk = this.template.querySelector('[data-id="selectAll"]');
        if (chk) chk.checked = false;
    }

    get hasRecords() {
        return this.displayRows.length > 0;
    }

    // @api
    // validate() {
    //     let isValid = true;
    //     const cells = this.template.querySelectorAll('c-opp-market-line-cell');
    //     cells.forEach(cell => {
    //         if (!cell.validate()) isValid = false;
    //     });
    //     return isValid;
    // }
    // @api
    // validate() {
    //     let isValid = true;
    //     const cells = this.template.querySelectorAll('c-opp-market-line-cell');
    //     cells.forEach(cell => {
    //         if (!cell.validate()) {
    //             isValid = false;
    //             const row = this.rows.find(r => r.Id === cell.rowId);
    //             if (row) {
    //                 row._errors = { ...(row._errors || {}), [cell.col.key]: 'Please check the required fields.' };
    //             }
    //         }
    //     });
    //     if (!isValid) this.rows = [...this.rows]; // 리렌더링 트리거
    //     return isValid;
    // }

    @api
    validate() {
        let isValid = true;
        const skipRowIds = new Set(this.rows.filter(r => r.BrkgAdj_is__c).map(r => r.Id));
        const cells = this.template.querySelectorAll('c-opp-market-line-cell');
        cells.forEach(cell => {
            if (skipRowIds.has(cell.rowId)) return;
            if (!cell.validate()) {
                isValid = false;
                const row = this.rows.find(r => r.Id === cell.rowId);
                if (row) {
                    row._errors = { ...(row._errors || {}), [cell.col.key]: 'Please check the required fields.' };
                }
            }
        });
        if (!isValid) this.rows = [...this.rows];
        return isValid;
    }


    @api isFullscreen = false;
    get tableContainerStyle() {
        return this.isFullscreen ? 'height: calc(100vh - 100px);' : (this.isCiCase ? 'height: 250px;' : 'height: 450px;');
    }

    get isAllCheckboxDisabled() {
        // return this.isClaim ? false : (this.isReadOnly || this._selectableRows().length === 0);
        return this.isClaim ? false : (this.isReadOnly || (this.displayRows || []).length === 0);
    }

    // 체크박스 노출 여부: (Opportunity && !CI Case) OR Claim OR isPlacement
    // get isCheckboxVisible() {
    //     return (this.isOpp && !this.isCiCase) || this.isClaim || !this.isPlacement;
    //     // return !(this.isOpp && this.isCiCase);
    // }
    get isCheckboxVisible() {//26-04-12 Placement 체크박스 조회 가능
        return ((this.isOpp && !this.isCiCase) || this.isClaim || this.isPlacement);
    }

    handleSelectAll(event) {

        const checked = !!event.target.checked;
        const rows = this.displayRows || [];
        if (rows.length === 0) return;

        // chkDisabled인 행은 isSelected 변경 제외
        this.displayRows = rows.map(r => r.chkDisabled ? r : { ...r, isSelected: checked } );

        // 전체선택 체크박스 상태: 선택 가능한 행이 모두 선택됐는지 기준
        const selectableRows = rows.filter(r => !r.chkDisabled);
        this.isAllSelected = selectableRows.length > 0 && selectableRows.every(r => r.isSelected);
    }

    handleRowSelect(event) {
        const id = event.target?.dataset?.rowId;
        const checked = !!event.target.checked;
        if (!id) return;
        this.displayRows = (this.displayRows || []).map(r => (r.Id === id) ? { ...r, isSelected: checked } : r );
        const selectableRows = (this.displayRows || []).filter(r => !r.chkDisabled);
        this.isAllSelected = selectableRows.length > 0 && selectableRows.every(r => r.isSelected);
    }

    // Cell의 valuechange를 받아서 cellchange로 변환하여 상위로 전달
    handleValueChange(event) {
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent('cellchange', { detail: event.detail }));
    }

    handleGroupHeader(event) {
        const groupName = event.currentTarget?.dataset?.group;
        const mode = event.currentTarget?.dataset?.mode;
        if (!groupName || !mode) return;

        const next = { ...(this._collapsed || {}) };
        next[groupName] = (mode === 'collapse');
        this._collapsed = next;

        this._buildHeaders();
        this._rebuildDisplayRows();
        this._emitGroupState();
    }

    // 통합 이벤트 핸들러 (stopPropagation 포함)
    handleRelayEvent(event) {
        event.stopPropagation();
        this.dispatchEvent(new CustomEvent(event.type, { detail: event.detail }));
    }

    _extractGroups(cols) {
        const groups = {};
        for (const c of (cols || [])) {
            const g = c.groupName;
            if (g) (groups[g] = groups[g] || []).push(c);
        }
        return groups;
    }

    _getSummaryLeaves(colsInGroup) {
        const cols = colsInGroup || [];

        // 1) groupPrimary = true 인 컬럼들
        const primaries = cols.filter(c => c.groupPrimary === true);
        if (primaries.length > 0) return primaries;

        // 2) 없으면 버튼이 아닌 첫 번째 컬럼
        const nonButton = cols.find(c => c.type !== 'button');
        if (nonButton) return [nonButton];

        // 3) 그래도 없으면 첫 번째 컬럼
        return cols.length > 0 ? [cols[0]] : [];
    }

    _buildHeaders() {
        const cols = this._renderColumns || this._columns || [];
        const leaves = [];

        const groups = this._extractGroups(cols);
        const seen = new Set();

        for (const col of cols) {
            if (!col.groupName) {
                leaves.push(col);
                continue;
            }
            const g = col.groupName;
            if (seen.has(g)) continue;
            seen.add(g);

            const colsInGroup = groups[g] || [];
            const collapsed = !!this._collapsed[g];

            if (collapsed) {
                const summaries = this._getSummaryLeaves(colsInGroup);
                summaries.forEach(s => leaves.push({ ...s, isGroupColumn: true }));
            } else {
                colsInGroup.forEach(c => {
                    leaves.push({ ...c, isGroupColumn: false });
                });
            }
        }

        const hRow1 = [];
        const hRow2 = [];

        const seenGroups = new Set();
        for (const col of cols) {
            if (!col.groupName) {
                hRow1.push({
                    key: col.key,
                    label: col.label,
                    colspan: 1,
                    rowspan: 2,
                    style: col.style,
                    thStyle: col.style || '',
                    required: col.required
                });
                continue;
            }

            const g = col.groupName;
            if (seenGroups.has(g)) continue;
            seenGroups.add(g);

            const colsInGroup = groups[g] || [];
            const collapsed = !!this._collapsed[g];
            const collapsible = colsInGroup.length > 1 && !colsInGroup.some(c => c.groupCollapsible === false);// 접기 가능 여부

            const summaries = this._getSummaryLeaves(colsInGroup);
            const currentCols = collapsed ? summaries : colsInGroup;

            hRow1.push({
                key: `group-${g}`,
                label: g,
                colspan: currentCols.length,
                rowspan: 1,
                isGroup: true,
                groupName: g,
                collapsed,
                collapsible,
                toggleIcon: collapsed ? 'utility:chevronright' : 'utility:chevrondown',
                toggleLabel: collapsed ? 'Expand' : 'Collapse',
                toggleMode: collapsed ? 'expand' : 'collapse',
                thStyle: ''
            });

            currentCols.forEach(c => {
                hRow2.push({ key: c.key, label: c.label, style: c.style, thStyle: c.style || '', required: c.required });
            });
        }

        this.leafColumns = leaves;
        this.headerRow1 = hRow1;
        this.headerRow2 = hRow2;
    }

    _rebuildDisplayRows() {
        console.time("⏱️⏱️⏱️⏱️⏱️ rebuildDisplayRows_execution_time"); // 타이머 시작
        const leaf = this.leafColumns || [];
        // console.log('[KYC] 🍏 🍏 🍏 _rebuildDisplayRows bizRegion:', this.bizRegion);
        // console.log('🍏 🍏 🍏 isBlankCell ctx:', JSON.stringify(this.ctx));
        const rows = Array.isArray(this._rows) ? this._rows : [];
        const out = [];

        for (let i = 0; i < rows.length; i++) {
            const r = rows[i];
            if (!r || r.isDeleted) continue;

            // console.log('🐈🐈🐈🐈🐈🐈🐈 this.isClaim=['+this.isClaim+'], chkDisabled=['+ (this.isClaim ? (!!(r.CO_is__c || r.BrkgAdj_is__c)) : this.isReadOnly) +']')

            const rowNo = (r._rowNo !== undefined && r._rowNo !== null) ? r._rowNo : (i + 1);
            const viewRow = {
                ...r,
                Id: r.Id,
                _rowNo: rowNo,
                isSelected: false,
                layerRowSpan: r.layerRowSpan,
                layerId: (r.layerId ?? r.Id),
                panelId: (r.panelId ?? r.Id),
                //chkDisabled: this.isClaim ? (!!(r.CO_is__c || r.BrkgAdj_is__c)) : (r.CO_is__c || r.BrkgAdj_is__c || this.isReadOnly)
                chkDisabled: this.isClaim
                    ? (!!(r.BrkgAdj_is__c))// 26.04.02 추가 요청 CO_is__c 선택 가능으로
                    // ? (!!(r.CO_is__c || r.BrkgAdj_is__c))
                    // : (r.CO_is__c || r.BrkgAdj_is__c || r.Type__c === 'QS' || this.isReadOnly)
                    : (r.BrkgAdj_is__c || this.isReadOnly)// 26.04.02 추가 요청 CO_is__c 선택 가능으로
                    // : (r.CO_is__c || r.BrkgAdj_is__c || this.isReadOnly)
            };

            out.push({
                ...viewRow,
                cells: leaf.map(col => {
                    const hasError = !!(viewRow._errors && viewRow._errors[col.key]);
                    const errorMessage = viewRow._errors ? (viewRow._errors[col.key] || null) : null;
                    // Dirty Check UI 표시
                    const isEdited = !!(viewRow.isEdited && viewRow._changes && viewRow._changes[col.key]);
                    const layerCurr = viewRow.LayerCurrency__c;

                    // tdClass 계산
                    const classes = [];
                    if (hasError) classes.push('cell-error');
                    if (isEdited) classes.push('slds-is-edited');
                    if (this.isClaim && col.key === 'LayerCurrency__c' && layerCurr && this.claimCurrency && layerCurr !== this.claimCurrency) {
                        // console.log('🚗 this.isClaim=[', this.isClaim, '], (col.key === LayerCurrency__c)', (col.key === 'LayerCurrency__c'), ', layerCurr=['+ layerCurr +'], this.claimCurrency=['+this.claimCurrency+']')
                        // col.type = 'text';
                        // classes.push('cus-lk-input-currency'); // 빨간색 + 굵게
                        // classes.push('slds-is-edited');
                        classes.push('cell-error');
                        // classes.push('slds-text-title_bold slds-is-edited');
                    } else {
                        // CO 또는 Brkg Adj 행이면 배경색 클래스 추가: slds-theme_gray < slds-theme_shade < slds-theme_alt-inverse slds-text-color_inverse 왼->오 순서로 진해짐
                        if (viewRow.CO_is__c) {
                            classes.push('slds-color__background_gray-5');
                        }
                        if (viewRow.BrkgAdj_is__c) {
                            classes.push('slds-color__background_gray-7');
                        }
                    }
                    const tdClass = classes.join(' ');

                    return {
                        key: col.key,
                        col,
                        value: (viewRow[col.key] ?? null),
                        isGroupColumn: col.isGroupColumn === true,
                        tdStyle: col.style || '',
                        tdClass: tdClass,
                        errorMessage,
                        isHidden: !!col.isHidden,
                        isEdited,
                        isBlank: isBlankCell(viewRow, col, this._ctx, this.selectedCurrency),
                        isReadOnly: this.isReadOnly || isReadOnlyCell(viewRow, col, this._ctx, this.selectedCurrency)
                    };
                })
            });
        }

        this.displayRows = out;
        this.isAllSelected = false;
        console.timeEnd("⏱️⏱️⏱️⏱️⏱️ rebuildDisplayRows_execution_time"); // 타이머 종료 및 시간 출력
    }
    //_rebuildDisplayRows() End

    connectedCallback() {}

    disconnectedCallback() {
        if (this._debounceTimer) {
            clearTimeout(this._debounceTimer);
        }
    }




}