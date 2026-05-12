/**********************************************************************************
 * @filename      : SoaNoteManage.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-18 (수)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-18      i2max      Create
 **********************************************************************************/
import {LightningElement, api, wire} from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';

import COM_NOTE_OBJECT from '@salesforce/schema/COM_Note__c';
import SOA_NAME_FIELD from '@salesforce/schema/SOA_Statement__c.Name';

import { callApex, toast, confirm, getFieldValue } from 'c/com';
import { NOTE_COLUMNS, EXCEL_GROUPS } from './soaNoteManageColumns';
import exceljs from '@salesforce/resourceUrl/exceljs';

import getNotes from '@salesforce/apex/SOA_NoteManager_Ctrl.getNotes';
import saveAsFile from '@salesforce/apex/SOA_NoteManager_Ctrl.saveAsFile';
import createSOA from '@salesforce/apex/SOA_NoteManager_Ctrl.createSOA';
import getNoteFileMap from '@salesforce/apex/SOA_NoteManager_Ctrl.getNoteFileMap';
import downloadNotesAsZip from '@salesforce/apex/SOA_NoteManager_Ctrl.downloadNotesAsZip';

import COM_BTN_REFRESH from '@salesforce/label/c.COM_BTN_REFRESH';
import COM_LBL_REFRESH from '@salesforce/label/c.COM_LBL_REFRESH';

export default class SoaNoteManage extends NavigationMixin(LightningElement) {
    // 📍 1. API 속성 (외부에서 설정 가능)
    @api recordId;

    // 📍 2. 추적 속성 (반응형)
    tableColumns = [];
    tableData = [];
    isLoading = false;

    // 📍 3. Private 속성
    _selectedCount = 0;
    _excelJsLoaded = false;
    _filterParams = {};
    labels = {
        COM_BTN_REFRESH,
        COM_LBL_REFRESH
    }
    _init = false;

    // 📍 4. Getter/Setter
    get isTabMode() {
        return !this.recordId;
    }

    get isRecordMode() {
        return !!this.recordId;
    }

    get isExportBtnDisabled() {
        return this._selectedCount === 0;
    }

    get isCreateSOADisabled() {
        return this._selectedCount === 0;
    }

    get totalCount() {
        return this.tableData?.length || 0;
    }

    get pageTitle() {
        return this.isTabMode ? "Create SOA" : "Notes";
    }

    get tableStyle() {
        return this.isTabMode ? '--rec-table-max-height: 360px' : '';
    }

    get soaName() {
        return getFieldValue(this.wiredSoa?.data, SOA_NAME_FIELD) || 'SOA';
    }

    get isDownloadNotesDisabled() {
        return this.totalCount === 0;
    }

    // 📍 5. Wire 메서드
    @wire(getObjectInfo, { objectApiName: COM_NOTE_OBJECT })
    wiredObjectInfo({ data }) {
        if (data) {
            const cols = this.isTabMode
                ? NOTE_COLUMNS.filter(c => c.name !== 'debitNote' && c.name !== 'coverNote')
                : NOTE_COLUMNS;
            this.tableColumns = this._applyLabels(cols, data.fields);

        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: [SOA_NAME_FIELD] })
    wiredSoa;

    // 📍 6. 이벤트 핸들러
    /**
     * @description 목록 새로고침 — 선택 초기화 후 재조회
     */
    handleRefresh() {
        if (this.isTabMode) {
            const filter = this.template.querySelector('c-soa-note-manage-filter');
            if (!filter?.validate()) return;
        }
        this.tableData = [];
        void this._loadData();
    }

    handleRowSelection(event) {
        this._selectedCount = event.detail.selectedRows.length;
    }

    handleExpandAll() {
        this.refs.table.expandAll();
    }

    handleCollapseAll() {
        this.refs.table.collapseAll();
    }

    // 탭 모드: 필터 검색
    handleFilterSearch(event) {
        this._filterParams = event.detail;
        void this._loadData();
    }

    // 탭 모드: 필터 리셋
    handleFilterReset() {
        this._filterParams = {};
        this.tableData = [];
    }

    async handleDownload() {
        const selectedRows = this.refs.table.getSelectedRows();
        if (!selectedRows?.length) {
            toast(this, 'Warning', 'Please select records.', 'warning');
            return;
        }
        if (!this._excelJsLoaded) {
            toast(this, 'Error', 'ExcelJS 라이브러리가 로드되지 않았습니다.', 'error');
            return;
        }

        try {
            this.isLoading = true;

            const hasClaimOnly = selectedRows.every(row => row.NoteType__c === 'Claim');
            const hasPremOnly = selectedRows.every(row => row.NoteType__c !== 'Claim');

            const visibleGroups = EXCEL_GROUPS.filter(g => {
                if (g.visible === 'hiddenIfClaimOnly' && hasClaimOnly) return false;
                return !(g.visible === 'hiddenIfPremOnly' && hasPremOnly);
            });

            const wb = new ExcelJS.Workbook();
            const ws = wb.addWorksheet('Data');

            const groupRow = [];
            const merges = [];
            let col = 1;
            visibleGroups.forEach(g => {
                groupRow.push(g.label);
                for (let i = 1; i < g.columns.length; i++) groupRow.push('');
                if (g.columns.length > 1) {
                    merges.push([1, col, 1, col + g.columns.length - 1]);
                }
                col += g.columns.length;
            });
            ws.addRow(groupRow);
            merges.forEach(m => ws.mergeCells(m[0], m[1], m[2], m[3]));

            const fieldRow = visibleGroups.flatMap(g => g.columns.map(c => c.label));
            ws.addRow(fieldRow);

            const fields = visibleGroups.flatMap(g => g.columns.map(c => c.field));
            selectedRows.forEach(row => {
                ws.addRow(fields.map(f => f ? (row[f] ?? '') : ''));
            });

            ws.eachRow(row => {
                row.eachCell(cell => {
                    cell.alignment = {horizontal: 'center', vertical: 'middle'};
                    cell.border = {
                        top: {style: 'thin'},
                        left: {style: 'thin'},
                        bottom: {style: 'thin'},
                        right: {style: 'thin'}
                    };
                });
            });

            [1, 2].forEach(rowNum => {
                ws.getRow(rowNum).eachCell(cell => {
                    cell.font = {bold: true};
                    cell.fill = {type: 'pattern', pattern: 'solid', fgColor: {argb: 'FFE0E0E0'}};
                });
            });

            ws.columns.forEach(c => {
                c.width = 20;
            });

            const buffer = await wb.xlsx.writeBuffer();
            const blob = new Blob([buffer], {type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'});
            const a = document.createElement('a');
            a.href = URL.createObjectURL(blob);
            a.download = `SOA_Notes_${new Date().toISOString().slice(0,
                10)}.xlsx`;
            a.click();
            URL.revokeObjectURL(a.href);
            toast(this, 'Success', '파일이 저장되었습니다.', 'success');

        } catch (e) {
            // callApex handles error toast
        } finally {
            this.isLoading = false;
        }
    }

    // 레코드 모드: Excel 저장
    async handleSaveAsExcel() {
        const selectedRows = this.refs.table.getSelectedRows();
        if (!selectedRows?.length) {
            toast(this, 'Warning', 'Please select records.', 'warning');
            return;
        }
        if (!this._excelJsLoaded) {
            toast(this, 'Error', 'ExcelJS 라이브러리가 로드되지 않았습니다.', 'error');
            return;
        }

        try {
            this.isLoading = true;

            const hasClaimOnly = selectedRows.every(row => row.NoteType__c === 'Claim');
            const hasPremOnly  = selectedRows.every(row => row.NoteType__c !== 'Claim');

            const visibleGroups = EXCEL_GROUPS.filter(g => {
                if (g.visible === 'hiddenIfClaimOnly' && hasClaimOnly) return false;
                return !(g.visible === 'hiddenIfPremOnly' && hasPremOnly);
            });

            const wb = new ExcelJS.Workbook();
            const ws = wb.addWorksheet('Data');

            const groupRow = [];
            const merges = [];
            let col = 1;
            visibleGroups.forEach(g => {
                groupRow.push(g.label);
                for (let i = 1; i < g.columns.length; i++) groupRow.push('');
                if (g.columns.length > 1) {
                    merges.push([1, col, 1, col + g.columns.length - 1]);
                }
                col += g.columns.length;
            });
            ws.addRow(groupRow);
            merges.forEach(m => ws.mergeCells(m[0], m[1], m[2], m[3]));

            const fieldRow = visibleGroups.flatMap(g => g.columns.map(c => c.label));
            ws.addRow(fieldRow);

            const fields = visibleGroups.flatMap(g => g.columns.map(c => c.field));
            selectedRows.forEach(row => {
                ws.addRow(fields.map(f => f ? (row[f] ?? '') : ''));
            });

            ws.eachRow(row => {
                row.eachCell(cell => {
                    cell.alignment = { horizontal: 'center', vertical: 'middle' };
                    cell.border = {
                        top: { style: 'thin' },
                        left: { style: 'thin' },
                        bottom: { style: 'thin' },
                        right: { style: 'thin' }
                    };
                });
            });

            [1, 2].forEach(rowNum => {
                ws.getRow(rowNum).eachCell(cell => {
                    cell.font = { bold: true };
                    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E0E0' } };
                });
            });

            ws.columns.forEach(c => { c.width = 20; });

            const buffer = await wb.xlsx.writeBuffer();
            const wbOut = btoa(String.fromCharCode(...new Uint8Array(buffer)));
            const fileName = `SOA_Notes_${new Date().toISOString().slice(0, 10)}`;

            const currencyTotals = {};
            selectedRows.forEach(row => {
                const ccy = row.OriginCurrency__c;
                const amt = row.NoteAmount__c || 0;
                if (ccy) {
                    currencyTotals[ccy] = (currencyTotals[ccy] || 0) + amt;
                }
            });
            const netAmount = Object.entries(currencyTotals)
                .map(([ccy, amt]) => `${ccy} ${amt.toLocaleString()}`)
                .join(' ');

            await callApex(this, saveAsFile, {
                recordId: this.recordId,
                fileName: fileName,
                base64Data: wbOut,
                netAmount: netAmount
            });

            toast(this, 'Success', '파일이 저장되었습니다.', 'success');
            void this._loadData();

        } catch (e) {
            // callApex handles error toast
        } finally {
            this.isLoading = false;
        }
    }

    // 탭 모드: Create SOA
    /**
     * @description Create SOA 버튼 클릭 핸들러 — 선택된 Note 기반으로 SOA 생성 모달 오픈
     * @param {CustomEvent} event 버튼 클릭 이벤트
     * @returns {Promise<void>}
     */
    async handleCreateSOA() {
        const selectedRows = this.refs.table.getSelectedRows();
        if (!selectedRows?.length) {
            toast(this, 'Warning', 'Please select records.', 'warning');
            return;
        }

        try {
            this.isLoading = true;

            const items = selectedRows.map(row => ({
                Id: row.Id,
                Account_lk__c: row.Account_lk__c,
                OriginCurrency__c: row.OriginCurrency__c,
                NoteAmount__c: row.NoteAmount__c,
                CreditAmount__c: row.CreditAmount__c,
                DebitAmount__c: row.DebitAmount__c,
                PERIODFrom_fm__c: row.PERIODFrom_fm__c,
                PERIODTo_fm__c: row.PERIODTo_fm__c
            }));

            const soaId = await callApex(this, createSOA, {
                selectedRowsStr: JSON.stringify(items)
            });

            toast(this, 'Success', 'SOA가 생성되었습니다.', 'success');

            const url = await this[NavigationMixin.GenerateUrl]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: soaId,
                    objectApiName: 'SOA_Statement__c',
                    actionName: 'view'
                }
            });
            window.open(url, '_blank');
            void this._loadData();
        } catch (e) {
            // callApex handles error toast
        } finally {
            this.isLoading = false;
        }
    }

    async handleDownloadNotes() {
        if (!this.isRecordMode) return;

        // 1) recTable 전체 데이터 → 체크된 파일 ID 수집
        const allRows = this.refs.table.getData();
        const items = []; // { docId, size }
        const seen = new Set();

        for (const r of allRows) {
            if (r.debitNoteChecked && r.debitNoteContentDocumentIds) {
                const ids = r.debitNoteContentDocumentIds.split(',');
                const sizePer = (r.debitNoteTotalSize || 0) / Math.max(ids.length, 1);
                for (const id of ids) {
                    if (id && !seen.has(id)) {
                        seen.add(id);
                        items.push({ docId: id, size: sizePer });
                    }
                }
            }
            if (r.coverNoteChecked && r.coverNoteContentDocumentIds) {
                const ids = r.coverNoteContentDocumentIds.split(',');
                const sizePer = (r.coverNoteTotalSize || 0) / Math.max(ids.length, 1);
                for (const id of ids) {
                    if (id && !seen.has(id)) {
                        seen.add(id);
                        items.push({ docId: id, size: sizePer });
                    }
                }
            }
        }

        if (!items.length) {
            toast(this, 'Warning', '선택된 파일이 없습니다.', 'warning');
            return;
        }

        // 2) 8MB 단위 청크 분할
        const MAX_CHUNK_BYTES = 8 * 1024 * 1024;
        const chunks = [];
        let current = [];
        let currentSize = 0;
        for (const it of items) {
            if (currentSize + it.size > MAX_CHUNK_BYTES && current.length) {
                chunks.push(current);
                current = [];
                currentSize = 0;
            }
            current.push(it.docId);
            currentSize += it.size;
        }
        if (current.length) chunks.push(current);

        // 3) 분할 발생 시 사용자 confirm
        if (chunks.length > 1) {
            const totalMB = (items.reduce((s, i) => s + i.size, 0) / 1024 / 1024).toFixed(1);
            const ok = await confirm(this, {
                label: 'Split ZIP',
                message: `선택한 파일 합계가 ${totalMB} MB입니다. ${chunks.length}개로 분할 압축하시겠습니까?`,
                theme: 'warning'
            });
            if (!ok) return;
        }

        // 4) 파일명 베이스
        const now = new Date();
        const pad = n => String(n).padStart(2, '0');
        const ts = `${now.getFullYear()}${pad(now.getMonth()+1)}${pad(now.getDate())}${pad(now.getHours())}${pad(now.getMinutes())}${pad(now.getSeconds())}`;
        const baseName = `[${this.soaName}]_${ts}`;

        // 5) 청크별 Apex 호출 → ZIP 첨부
        try {
            this.isLoading = true;
            for (let i = 0; i < chunks.length; i++) {
                const fileName = chunks.length === 1
                    ? baseName
                    : `${baseName}_${i + 1}of${chunks.length}`;
                await callApex(this, downloadNotesAsZip, {
                    recordId: this.recordId,
                    contentDocumentIds: chunks[i],
                    fileName
                });
            }
            toast(this, 'Success', `ZIP 파일 ${chunks.length}개가 첨부되었습니다.`, 'success');
            this.refs.table.clearSelection();
            // void this._loadData();
        } catch (e) {
            // callApex handles error toast
        } finally {
            this.isLoading = false;
        }
    }

    // 📍 7. Private 메서드
    async _loadExcelJS() {
        if (this._excelJsLoaded) return;
        try {
            await loadScript(this, exceljs);
            this._excelJsLoaded = true;
        } catch (e) {
            console.error('ExcelJS load error:', e);
            toast(this, 'Error', 'ExcelJS 로드 실패!!', 'error');
        }
    }

    async _loadData() {
        try {
            this.tableData = [];
            this.refs.table.clearSelection();
            this.isLoading = true;

            const params = this.isTabMode
                ? { filterCondition: JSON.stringify(this._filterParams) }
                : { recordId: this.recordId };

            const results = await callApex(this, getNotes, params);

            // 1) 기본 row 매핑
            let rows = results.map(row => ({
                ...row,
                locationOfLossUrl: row.ChildClaim_lk__c
                    ? `/lightning/r/Claim/${row.ChildClaim_lk__c}/related/LocationsOfLoss__r/view`
                    : null,
                locationOfLossLabel: row.ChildClaim_lk__c ? 'Locations Of Loss' : null,
                debitNoteFileName:           'N/A',
                debitNoteChecked:            false,
                debitNoteContentDocumentIds: null,
                debitNoteTotalSize:          0,
                coverNoteFileName:           'N/A',
                coverNoteChecked:            false,
                coverNoteContentDocumentIds: null,
                coverNoteTotalSize:          0
            }));

            // 2) 레코드 모드일 때만 첨부 파일 정보 머지
            if (this.isRecordMode && rows.length) {
                const noteIds = rows.map(r => r.Id);
                const fileMap = await callApex(this, getNoteFileMap, { noteIds });

                rows = rows.map(r => {
                    const info = fileMap?.[r.Id];
                    if (!info) return r;
                    return {
                        ...r,
                        debitNoteFileName:           info.debitNoteFileName || 'N/A',
                        debitNoteChecked:            !!info.debitNoteContentDocumentIds,
                        debitNoteContentDocumentIds: info.debitNoteContentDocumentIds,
                        debitNoteTotalSize:          info.debitNoteTotalSize || 0,
                        coverNoteFileName:           info.coverNoteFileName || 'N/A',
                        coverNoteChecked:            false,  // Cover Note는 기본 미선택
                        coverNoteContentDocumentIds: info.coverNoteContentDocumentIds,
                        coverNoteTotalSize:          info.coverNoteTotalSize || 0
                    };
                });
            }

            this.tableData = rows;

            // 3) 파일 없는 셀 비활성화 (다음 렌더 후)
            if (this.isRecordMode) {
                Promise.resolve().then(() => this._applyFileCellDisabled());
            }
        } catch (e) {
            this.tableData = [];
        } finally {
            this.isLoading = false;
        }
    }

    _applyFileCellDisabled() {
        const table = this.refs.table;
        if (!table) return;
        for (const r of this.tableData) {
            if (!r.debitNoteContentDocumentIds) {
                table.setCellDisabled(r.Id, 'debitNoteChecked', true);
            }
            if (!r.coverNoteContentDocumentIds) {
                table.setCellDisabled(r.Id, 'coverNoteChecked', true);
            }
        }
    }

    _applyLabels(columns, fields) {
        return columns.map(col => {
            const result = { ...col };
            if (col.columns) {
                result.columns = this._applyLabels(col.columns, fields);
            }
            if (!col.label && col.name && fields[col.name]) {
                result.label = fields[col.name].label;
            }
            return result;
        });
    }

    // 📍 8. 라이프사이클 메서드
    async connectedCallback() {
        if (this._init) return;
        if (this.isRecordMode) {
            await this._loadExcelJS();
            await this._loadData();
        }
        if (this.isTabMode) document.title = "Create SOA";
        this._init = true;
    }

    disconnectedCallback() {
    }



}