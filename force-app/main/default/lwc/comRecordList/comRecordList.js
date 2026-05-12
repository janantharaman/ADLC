/**********************************************************************************
 * @filename      : ComRecordList.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-08 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-03-08       i2max             Create
 **********************************************************************************/
import { LightningElement, api } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { callApex, toast } from 'c/com';
import exceljs from '@salesforce/resourceUrl/exceljs';
import getChildRecords from '@salesforce/apex/COM_RecordList_Ctrl.getChildRecords';
import saveAsFileAndSendEmail from '@salesforce/apex/COM_RecordList_Ctrl.saveAsFileAndSendEmail';
import saveAsFile from "@salesforce/apex/COM_RecordList_Ctrl.saveAsFile";
import COM_BTN_REFRESH from "@salesforce/label/c.COM_BTN_REFRESH";
import COM_LBL_REFRESH from "@salesforce/label/c.COM_LBL_REFRESH";

export default class ComRecordList extends LightningElement {

    @api recordId;
    @api pageTitle = '';
    @api childObject = '';
    @api parentRecordField = '';
    @api displayFields = 'Name,CreatedDate';
    @api filterCondition = '';
    @api showExcelButton;
    @api columnDefs = null;  // [{label:'그룹명', fields:['field1','field2']}]
    @api fieldOverrides = null; // { 'fieldName': { type:'url', config: { idField, objectApiName } } }
    @api computedFields = null;
    // [{ name: 'locationOfLossUrl', sourceField: 'Claim_lk__c__id', template:'/lightning/r/Claim/{value}/related/LocationsOfLoss__r/view' },
    //  { name: 'locationOfLossLabel', sourceField: 'Claim_lk__c__id', value: 'Locations Of Loss' }]
    @api componentSize = 'Medium';
    @api nameLinkEnabled = false;// Name 레코드 링크 여부

    tableColumns = [];
    tableData = [];
    isLoading = false;
    excelJsLoaded = false;
    _objectLabel = '';
    _childObject = '';
    _init = false;
    labels = {
        COM_BTN_REFRESH,
        COM_LBL_REFRESH
    }

    get pageTitleDisplay() {
        return this.pageTitle || this._objectLabel || '';
    }
    get isExportBtnDisabled() {
        return this.tableData.length === 0;
    }
    get hideCheckbox() {
        return !this.showExcelButton;
    }

    get tableStyle() {
        const sizeMap = { Small: '200px', Medium: '400px', Large: '600px' };
        return `--rec-table-max-height: ${sizeMap[this.componentSize] || '400px'}`;
    }

    async loadExcelJS() {
        if (this.excelJsLoaded) return;
        try {
            await loadScript(this, exceljs);
            this.excelJsLoaded = true;
        } catch (event) {
            toast(this, 'Error', 'ExcelJS 로드 실패', 'error');
        }
    }

    async loadData() {
        if (!this.recordId || !this.childObject || !this.parentRecordField) return;
        this.isLoading = true;

        try {
            const result = await callApex(this, getChildRecords, {
                recordId: this.recordId,
                childObject: this.childObject,
                parentRecordField: this.parentRecordField,
                displayFields: this.displayFields,
                filterCondition: this.filterCondition,
            });

            const fields = this.displayFields.split(',').map(f => f.trim());
            const fieldTypes = result.fieldTypes || {};
            // fieldOverrides에서 idField로만 사용되는 필드를 수집
            const hiddenFields = new Set();
            if (this.fieldOverrides) {
                Object.values(this.fieldOverrides).forEach(o => {
                    if (o.config?.idField) hiddenFields.add(o.config.idField);
                });
            }
            if (this.computedFields) {
                this.computedFields.forEach(cf => {
                    if (cf.sourceField) hiddenFields.add(cf.sourceField.replace('__id', ''));
                });
            }
            const fieldColumns = fields.filter(f => !hiddenFields.has(f)).map(f => {
                const type = fieldTypes[f] || 'text';

                // fieldOverrides 우선 적용
                const override = this.fieldOverrides?.[f];
                if (override) {
                    return {
                        label: result.fieldLabels?.[f] ?? f,
                        name: f,
                        type: override.type,
                        config: override.config
                    };
                }

                if (type === 'lookup') {
                    return {
                        label: result.fieldLabels?.[f] ?? f,
                        name: f,
                        type: 'url',
                        config: {
                            idField: f + '__id',
                            objectApiName: result.fieldLookupObjects?.[f]
                        }
                    };
                }
                return {
                    label: result.fieldLabels?.[f] ?? f,
                    name: f,
                    type
                };
            });
            if (this.fieldOverrides) {
                const existingNames = new Set(fieldColumns.map(c => c.name));
                Object.entries(this.fieldOverrides).forEach(([name, override]) => {
                    if (!existingNames.has(name)) {
                        fieldColumns.push({
                            label: override.label ?? name,
                            name,
                            type: override.type,
                            config: override.config
                        });
                    }
                });
            }
            if (this.columnDefs) {
                const groupedFields = new Set(this.columnDefs.flatMap(g => g.fields));
                const ungroupedColumns = fieldColumns.filter(c => !groupedFields.has(c.name));
                const groupColumns = this.columnDefs.map(g => ({
                    label: g.label,
                    name: g.label,
                    columns: g.fields
                        .map(f => fieldColumns.find(c => c.name === f))
                        .filter(Boolean)
                }));
                this.tableColumns = [
                    {label: 'No.', name: 'rowNo', width: '3rem'},
                    ...ungroupedColumns,
                    ...groupColumns
                ];
            } else {
                this.tableColumns = [
                    {label: 'No.', name: 'rowNo', width: '3rem'},
                    ...fieldColumns
                ];
            }

            // Name에 링크 주입
            if (this.nameLinkEnabled) {
                this.tableColumns = this.tableColumns.map(col => {
                    if (col.name === 'Name') {
                        return {
                            ...col,
                            type: 'url',
                            sortable: true,
                            config: { idField: 'Id', objectApiName: this.childObject }
                        };
                    }
                    return col;
                });
            }

            this.tableData = (result.records || []).map((item, index) => {
                const row = { ...item, rowNo: index + 1 };
                this.computedFields?.forEach(cf => {
                    const src = row[cf.sourceField];
                    row[cf.name] = src
                        ? (cf.template ? cf.template.replace('{value}', src) : cf.value)
                        : null;
                });
                return row;
            });
            this._objectLabel = result.objectLabel;
            this._childObject = result.childObject;
            this._fieldLabels = result.fieldLabels;

        } catch (event) {
            this.tableData = [];
        } finally {
            this.isLoading = false;
        }
    }

    async handleExport() {
        const table = this.refs.table;
        const selectedRows = table.getSelectedRows();

        if (!selectedRows || selectedRows.length === 0) {
            toast(this, 'Warning', 'Please select records.', 'warning');
            return;
        }

        if (!this.excelJsLoaded) {
            toast(this, 'Error', 'ExcelJS 라이브러리가 로드되지 않았습니다.', 'error');
            return;
        }

        if (selectedRows.length > 5000) {
            toast(this, 'Warning', '최대 5,000건까지 내보내기 가능합니다.', 'warning');
            return;
        }

        try {
            this.isLoading = true;

            const fields = this.displayFields.split(',').map(f => f.trim());

            const wb = new ExcelJS.Workbook();
            const ws = wb.addWorksheet('Data');

            // 헤더 행
            ws.addRow(fields);

            // 데이터 행
            selectedRows.forEach(row => {
                ws.addRow(fields.map(f => row[f] ?? ''));
            });

            // 전체 셀 스타일
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

            // 헤더 스타일
            ws.getRow(1).eachCell(cell => {
                cell.font = { bold: true };
                cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E0E0' } };
            });

            // 컬럼 너비
            ws.columns.forEach(c => { c.width = 20; });

            // base64 변환
            const buffer = await wb.xlsx.writeBuffer();
            const wbOut = btoa(String.fromCharCode(...new Uint8Array(buffer)));

            const fileName = `${this._objectLabel}_${new Date().toISOString().slice(0, 10)}`;
            await callApex(this, saveAsFileAndSendEmail, {
                recordId: this.recordId,
                fileName: fileName,
                base64Data: wbOut
            });

            toast(this, 'Success', '파일이 저장되고 이메일이 발송되었습니다.', 'success');
        } catch (e) {
            // callApex가 에러 토스트 처리
        } finally {
            this.isLoading = false;
        }
    }

    async handleSaveAsExcel() {
        const selectedRows = this.refs.table.getSelectedRows();
        if (!selectedRows?.length) {
            toast(this, 'Warning', 'Please select records.', 'warning');
            return;
        }
        if (!this.excelJsLoaded) {
            toast(this, 'Error', 'ExcelJS 라이브러리가 로드되지 않았습니다.', 'error');
            return;
        }

        try {
            this.isLoading = true;

            const fields = this.displayFields.split(',').map(f => f.trim());

            const wb = new ExcelJS.Workbook();
            const ws = wb.addWorksheet('Data');

            // ws.addRow(fields);
            ws.addRow(fields.map(f => this._fieldLabels?.[f] ?? f));

            selectedRows.forEach(row => {
                ws.addRow(fields.map(f => row[f] ?? ''));
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

            ws.getRow(1).eachCell(cell => {
                cell.font = {bold: true};
                cell.fill = {type: 'pattern', pattern: 'solid', fgColor: {argb: 'FFE0E0E0'}};
            });

            ws.columns.forEach(c => {
                c.width = 20;
            });

            const buffer = await wb.xlsx.writeBuffer();
            const wbOut = btoa(String.fromCharCode(...new Uint8Array(buffer)));
            const fileName = `${this._objectLabel}_${new Date().toISOString().slice(0, 10)}`;

            await callApex(this, saveAsFile, {
                recordId: this.recordId,
                fileName: fileName,
                base64Data: wbOut
            });

            toast(this, 'Success', '파일이 저장되었습니다.', 'success');
            this.refs.table.clearSelection();
            void this.loadData();
        } catch (e) {
            // callApex handles error toast
        } finally {
            this.isLoading = false;
        }
    }

    async handleRefresh() {
        this.refs.table.clearSelection();
        await this.loadData();
    }

    async connectedCallback() {
        if(this._init) return;
        await this.loadExcelJS()
        await this.loadData();
        this._init = true;
    }
}