/**********************************************************************************
 * @filename       : oppTSIByLocationTable.js
 * @project-name  : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-09 (금)
 * @group         :
 * @group-content :
 * @description   : Slip 컴포넌트 내부에서 호출하는 TSI 섹션 부분의 LWC 컴포넌트
 *                  - Slip 에 연결된 TSI By Location 데이터를 조회·편집·저장하고,
 *                  - Excel 템플릿/데이터 업로드·다운로드, TSI mismatch 검증, 주소(Geo) 보정 처리
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-09     i2max      Create
 **********************************************************************************/
import { LightningElement, api, track, wire } from 'lwc';
import { toggleFullscreen, toast } from 'c/com';
import getTSIByLocation from '@salesforce/apex/Opp_TSIByLocationTable_Ctrl.getTSIByLocation';
import getTSICurrencyOptions from '@salesforce/apex/Opp_TSIByLocationTable_Ctrl.getTSICurrencyOptions';
import insertTSIByLocation from '@salesforce/apex/Opp_TSIByLocationTable_Ctrl.insertTSIByLocation';
import deleteTSIByLocation from '@salesforce/apex/Opp_TSIByLocationTable_Ctrl.deleteTSIByLocation';
import updateTSIByLocation from '@salesforce/apex/Opp_TSIByLocationTable_Ctrl.updateTSIByLocation';
import getSlipType from '@salesforce/apex/Opp_TSIByLocationTable_Ctrl.getSlipType';
import getTSIFieldMetadata from '@salesforce/apex/OPP_TSIUpload_Ctrl.getTSIFieldMetadata';
import downloadTSIByLocation from '@salesforce/apex/Opp_TSIByLocationTable_Ctrl.downloadTSIByLocation';
import { loadScript } from 'lightning/platformResourceLoader';
import {getObjectInfo} from "lightning/uiObjectInfoApi";
import findGeoInfo from '@salesforce/apex/COM_GoogleMapService.findGeoInfo';
import getTransactionType from '@salesforce/apex/Opp_TSIByLocationTable_Ctrl.getTransactionType';
import exceljs from '@salesforce/resourceUrl/exceljs';
import TSI_OBJ from "@salesforce/schema/OPP_TSIByLocation__c";
// Todo : TSI 연결 Currency Panel 삭제 주석
// import deleteTSIByLocationAndPanel from '@salesforce/apex/Opp_TSIByLocationTable_Ctrl.deleteTSIByLocationAndPanel';
import updateNeedRecalculateFlag from '@salesforce/apex/Opp_TSIByLocationTable_Ctrl.updateNeedRecalculateFlag';
import { CurrentPageReference } from 'lightning/navigation';

import COM_BTN_EnterFullScreen from '@salesforce/label/c.COM_BTN_ENTERFULLSCREEN';
import COM_BTN_ExitFullScreen from '@salesforce/label/c.COM_BTN_EXITFULLSCREEN';
import LABEL_TEMPLATE from '@salesforce/label/c.COM_BTN_TEMPLATE';
import LABEL_UPLOAD from '@salesforce/label/c.COM_BTN_UPLOAD';
import LABEL_ADD from '@salesforce/label/c.COM_BTN_ADD';
import LABEL_DELETE from '@salesforce/label/c.COM_BTN_DEL'
import LABEL_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import COM_MSG_SAVE_SUCCESS from '@salesforce/label/c.COM_MSG_SAVE_SUCCESS';
import COM_MSG_NO_ROW_SELECT from '@salesforce/label/c.COM_MSG_NO_ROW_SELECT';
import OPP_MISMATCH from '@salesforce/label/c.OPP_MSG_TSI_MISMATCH';
import OPP_LBL_CLOSING_TITLE from '@salesforce/label/c.OPP_LBL_CLOSING_TITLE';
import OPP_LBL_CEDANT_TITLE from '@salesforce/label/c.OPP_LBL_CEDANT_TITLE';
import MSG_CHECK_REQUIRED_FIELDS from '@salesforce/label/c.COM_MSG_CHECK_REQUIRED_FIELDS';
import MSG_LAT_LNG from '@salesforce/label/c.OPP_TSI_MSG_LAT_LNG';
import MSG_UNAMEDLOCATION from '@salesforce/label/c.OPP_TSI_MSG_UNAMEDLOCATION';

export default class OppTSIByLocationTable extends LightningElement {

    _isLockedByStage = false;

    labels = {
        enterFs: COM_BTN_EnterFullScreen,
        exitFs: COM_BTN_ExitFullScreen,
        template : LABEL_TEMPLATE,
        upload : LABEL_UPLOAD,
        add : LABEL_ADD,
        delete : LABEL_DELETE,
        save : LABEL_SAVE,
        mismatchMsg : OPP_MISMATCH,
        closingTitle : OPP_LBL_CLOSING_TITLE,
        cedantTitle : OPP_LBL_CEDANT_TITLE,
        requiredMsg : MSG_CHECK_REQUIRED_FIELDS,
        latLngMsg : MSG_LAT_LNG,
        unnamedLocationMsg : MSG_UNAMEDLOCATION,
        saveSuccessMsg: COM_MSG_SAVE_SUCCESS,
        noRowSelected: COM_MSG_NO_ROW_SELECT
    };

    isFullscreen = false;
    mismatchError = false;
    mismatchCurrencies = '';
    _init = false;
    _slipInfoId;
    _suppressMismatchMsg = false;
    slipType;
    _excelJsLoaded = false;
    rowKeySeq = 1;

    deletedRecordIds = [];
    deletedCurrencies = [];
    isSavingTSI = false;

    @api recordId;
    _slipTsiMap = {};

    @api
    get isLockedByStage() {
        return this._isLockedByStage;
    }
    set isLockedByStage(value) {
        this._isLockedByStage = value === true || value === 'true';
        this.reapplyRowLocks();
    }

    @api
    get slipTsiMap() {
        return this._slipTsiMap;
    }
    set slipTsiMap(value) {
        this._slipTsiMap = value || {};
        this.validateTSIMismatch();
    }

    @track data = [];
    @track newRows = [];
    @track TSICurrencyOptions = [];
    @track showModal = false;
    @track isSearching = false;

    @track excelData = [];
    @track fileName = '';


    // 배서 Slip
    transactionType;
    isEndTransaction = false;

    // Page 분리
    @wire(CurrentPageReference)
    pageRef;

    @api
    get slipInfoId() {
        return this._slipInfoId;
    }
    @api placementId;

    @api
    get suppressMismatchMsg() {
        return this._suppressMismatchMsg;
    }
    set suppressMismatchMsg(value) {
        this._suppressMismatchMsg = value === true || value === 'true';
        this.validateTSIMismatch();
    }

    undefinedOptions = [
        { label: 'Yes', value: 'true' },
        { label: 'No', value: 'false' }
    ];

    // SlipInfo 연결용
    @api
    async refresh() {
        await this.loadData();
    }

    set slipInfoId(value) {
        this._slipInfoId = value;

        if (value) {
            void this.loadData();
        }
    }

    @wire(getTSICurrencyOptions)
    wiredTSICurrencyOptions({ data, error }) {
        this.TSICurrencyOptions = [];
        if (data) {
            this.TSICurrencyOptions = data || [];
        } else if (error) {
           console.error('Error loading TSICurrency options:', error);
        }
    }

    @wire(getObjectInfo, { objectApiName: TSI_OBJ })
    wiredObjectInfo({ data, error }) {
        if (data?.fields) {
            this.objectFields = data.fields;
        } else if (error) {
            this.objectFields = null;
            console.error("Error loading object info:", error);
        }
    }

    get isPlacementPage() {
        const objectApiName = this.pageRef?.attributes?.objectApiName;

        if (objectApiName) {
            return objectApiName !== 'Opportunity' && objectApiName !== 'OPP_SlipInfo__c';
        }

        return !!this.placementId && !this.isOpportunityPage && !this.isSlipInfoPage;
    }

    get isOpportunityPage() {
        return this.pageRef?.attributes?.objectApiName === 'Opportunity';
    }

    get isSlipInfoPage() {
        const objectApiName = this.pageRef?.attributes?.objectApiName;

        if (objectApiName) {
            return objectApiName === 'OPP_SlipInfo__c';
        }

        return !!this.recordId && !!this.slipInfoId && this.recordId === this.slipInfoId;
    }

    get resolvedPlacementIdForFlag() {
        if (!this.isPlacementPage) return null;
        return this.placementId || this.recordId || null;
    }

    get resolvedOpportunityIdForFlag() {
        return this.isOpportunityPage ? this.recordId : null;
    }

    get isActionDisabled() {
        return this.isLockedByStage;
    }

    get isEditDisabled() {
        return this.isLockedByStage;
    }

    get isSaveDisabled() {
        return this.isEditDisabled || this.isSavingTSI;
    }

    get iconName() {
        return this.isFullscreen ? 'utility:contract' : 'utility:expand';
    }

    get buttonLabel() {
        return this.isFullscreen ? this.labels.exitFs : this.labels.enterFs;
    }

    async loadSlipType() {
        if (!this.slipInfoId && !this.placementId) return;

        try {
            this.slipType = await getSlipType ({
                slipInfoId: this.slipInfoId,
                placementId: this.placementId });
        } catch (e) {
            console.error(e);
        }
    }

    async loadTransactionType() {
        try {

            this.transactionType = await getTransactionType({
                recordId: this.recordId,
                slipInfoId: this.slipInfoId
            });

            if(this.transactionType?.toUpperCase() === 'END'){
                this.isEndTransaction = true;
            }

            this.reapplyRowLocks();

        } catch(error){
            console.error('TransactionType load error', error);
        }
    }

    applyRowLocks(row) {
        if (!row) return row;

        const isUnnamed = row.UnamedLocation__c === true || row.UnamedLocation__c === 'true';
        const isFxDisabled = row._isFxDisabled === true;

        return {
            ...row,
            _isRowEditDisabled: this.isEditDisabled,
            _isAddressDisabled: this.isLockedByStage || isUnnamed,
            _isAddressDisabledFinal: this.isLockedByStage || isUnnamed,
            _isLatLngDisabledFinal: true,
            _isFxDisabledFinal: this.isLockedByStage || isFxDisabled
        };
    }

    reapplyRowLocks() {
        this.data = (this.data || []).map(row => this.applyRowLocks(row));
        this.newRows = (this.newRows || []).map(row => this.applyRowLocks(row));
    }

    get tsiTitle() {
        if (this.slipType === 'Cedant Offer') {
            return this.labels.cedantTitle;
        }

        if (this.slipType === 'Cedant Closing') {
            return this.labels.closingTitle;
        }

        return 'TSI by Location';
    }

    /**
     * @description SlipInfo 기준으로 TSI by Location 데이터 조회 및 화면 바인딩
     * @returns {Promise<void>}
     */
    async loadData() {
        if (!this.slipInfoId && !this.placementId) {
            this.data = [];
            this.mismatchError = false;
            return;
        }

        this.isLoading = true;

        try {
            const result = await getTSIByLocation({
                slipInfoId: this.slipInfoId,
                placementId: this.placementId
            });

            const locations = result?.locations || [];

            this.data = locations.map((row, index) => {
                const addr = row.Address__c || {
                    street: '',
                    city: '',
                    state: '',
                    postalCode: '',
                    country: ''
                };

                const parts = [addr.street, addr.city, addr.state, addr.postalCode, addr.country].filter(Boolean);

                const googleMapUrl = parts.length
                    ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(parts.join(' '))}`
                    : null;

                return {
                    ...row,
                    key: row.Id,
                    no: index + 1,
                    Address__c: addr,
                    googleMapUrl,
                    GrossRatePct__c: row.GrossRatePct__c != null ? parseFloat(row.GrossRatePct__c).toFixed(4) : null,

                    _isAddressDisabled: row.UnamedLocation__c === true,
                    _dirtyFields: {},
                    _isEditing: false,
                    _showEdit: false,
                    _tdClasses: {}
                };
            }).map(row => this.applyRowLocks(row));

            this.calculatePremiumTotals();
            this.validateTSIMismatch();

        } catch (error) {
            const message =
                error?.body?.message
                || (Array.isArray(error?.body) ? error.body.map(e => e.message).join(' | ') : null)
                || error?.message
                || 'Unknown error';

            console.error('Failed to load TSI data (raw):', JSON.stringify(error));
            toast(this, 'Error', `Failed to load TSI data: ${message}`, 'error');
            this.data = [];
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Action 버튼 공통 핸들러 — 버튼 타입별 기능 분기 처리
     * @param {CustomEvent} event 버튼 클릭 이벤트
     */
    handleAction(event) {
        if (this.isActionDisabled) {
            return;
        }

        const action = event.detail?.value || event.currentTarget?.dataset?.action;

        switch (action) {
            case 'template' :
                void this.handleDownloadTemplate();
                break;
            case 'upload':
                this.openFileDialog();
                break;
            case 'download':
                void this.handleDownloadData();
                break;
            case 'refresh':
                void this.handleRefresh();
                break;
            case 'add' :
                this.addNewRow();
                break;
            case 'delete' :
                void this.handleDelete();
                break;
            case 'save' :
                void this.handleSave();
                break;
            case 'fullScreen' : {
                void this.toggleFullscreenAction();
                break;
            }
        }
    }

    // file upload modal
    openFileDialog() {
        if (this.isEditDisabled) {
            return;
        }

        const fileInput = this.template.querySelector('[data-id="fileInput"]');
        if (fileInput) {
            fileInput.value = null;
            fileInput.click();
        }
    }

    /**
     * @description Template Excel 다운로드 — 필드 메타데이터 기반 샘플 파일 생성
     * @returns {Promise<void>}
     */
    async handleDownloadTemplate() {
        if (!this._excelJsLoaded) {
            toast(this, 'Error', 'ExcelJS 라이브러리가 로드되지 않았습니다.', 'error');
            return;
        }

        try {
            const metadata = await getTSIFieldMetadata();
            const fieldOrder = metadata.fieldOrder;
            const fields = metadata.fields;

            // 헤더 / 샘플 데이터
            const headers = fieldOrder.map(apiName => fields[apiName].label);
            const sampleRow = fieldOrder.map(apiName =>
                this.getSampleValue(apiName, fields[apiName])
            );

            // ExcelJS 워크북 생성
            const wb = new ExcelJS.Workbook();
            const ws = wb.addWorksheet('OPP_TSI');

            ws.addRow(headers);   // 1행: 헤더
            ws.addRow(sampleRow); // 2행: 샘플 데이터

            // 📍 스타일 적용 (SoaNoteManager 동일 패턴)
            // 숫자 컬럼 포맷 적용 (1-based 컬럼 인덱스)
            fieldOrder.forEach((apiName, idx) => {
                const fieldMeta = fields[apiName];
                const colNum = idx + 1;
                const type = fieldMeta?.type?.toUpperCase();

                if (apiName === 'GrossRatePct__c') {
                    // Gross Rate: 소수점 4자리 콤마 포맷
                    ws.getColumn(colNum).numFmt = '#,##0.0000';
                } else if (type === 'DOUBLE' || type === 'CURRENCY' || type === 'PERCENT') {
                    // 그 외 숫자/통화: 정수 콤마 포맷
                    ws.getColumn(colNum).numFmt = '#,##0';
                }
            });

            // 1) 전체 셀: 테두리 + 가운데 정렬
            ws.eachRow(row => {
                row.eachCell(cell => {
                    cell.alignment = { horizontal: 'center', vertical: 'middle' };
                    cell.border = {
                        top:    { style: 'thin' },
                        left:   { style: 'thin' },
                        bottom: { style: 'thin' },
                        right:  { style: 'thin' }
                    };
                });
            });

            // 2) 헤더 행(1행): 볼드 + 배경색
            ws.getRow(1).eachCell(cell => {
                cell.font = { bold: true };
                cell.fill = {
                    type: 'pattern',
                    pattern: 'solid',
                    fgColor: { argb: 'FFE0E0E0' }
                };
            });

            // 3) 컬럼 너비
            // ws.columns.forEach(() => { ws.columns.forEach(c => { c.width = 22; }); });
            ws.columns.forEach(c => { c.width = 22; });

            // 파일명
            const now = new Date();
            const yy = String(now.getFullYear()).slice(2);
            const mm = String(now.getMonth() + 1).padStart(2, '0');
            const dd = String(now.getDate()).padStart(2, '0');
            // 파일 다운로드
            const buffer = await wb.xlsx.writeBuffer();
            const base64 = btoa(String.fromCharCode(...new Uint8Array(buffer)));
            const a = document.createElement('a');
            a.href = 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,' + base64;
            a.download = `TSI_Template_${yy}-${mm}-${dd}.xlsx`;
            a.click();

        } catch (error) {
            toast(this, 'Error', error.message, 'error');
        }
    }

    /**
     * @description 현재 TSI by Location 데이터를 Excel 파일로 다운로드
     * @returns {Promise<void>}
     */
    async handleDownloadData() {
        if (!this._excelJsLoaded) {
            toast(this, 'Error', 'ExcelJS 라이브러리가 로드되지 않았습니다.', 'error');
            return;
        }

        try {
            this.isLoading = true;

            const result = await downloadTSIByLocation({
                slipInfoId: this.slipInfoId,
                placementId: this.placementId
            });

            if (!result || !result.rows || result.rows.length === 0) {
                toast(this, 'Warning', 'No data to download.', 'warning');
                return;
            }

            const wb = new ExcelJS.Workbook();
            const ws = wb.addWorksheet('TSI_By_Location');

            // 헤더 행 추가
            ws.addRow(result.headers);

            const numericHeaderConfig = {
                'Insured Amount': {
                    integerFormat: '#,##0',
                    decimalFormat: '#,##0.####'
                },
                'Gross Prem (Before DP)': {
                    integerFormat: '#,##0',
                    decimalFormat: '#,##0.####'
                },
                'Gross Prem': {
                    integerFormat: '#,##0',
                    decimalFormat: '#,##0.####'
                }
            };

            const numericColumns = (result.headers || []).reduce((columns, header, index) => {
                if (numericHeaderConfig[header]) {
                    columns.push({
                        index,
                        ...numericHeaderConfig[header]
                    });
                }
                return columns;
            }, []);

            // 데이터 행 추가
            result.rows.forEach(rowData => {
                const excelRow = ws.addRow([...(rowData || [])]);

                numericColumns.forEach(({ index, integerFormat, decimalFormat }) => {
                    const cell = excelRow.getCell(index + 1);
                    const numericValue = this.toExcelNumber(rowData?.[index]);

                    if (typeof numericValue === 'number' && Number.isFinite(numericValue)) {
                        cell.value = numericValue;
                        cell.numFmt = Number.isInteger(numericValue)
                            ? integerFormat
                            : decimalFormat;
                    }
                });
            });

            // 스타일 — 전체 셀 테두리 + 가운데 정렬
            ws.eachRow(row => {
                row.eachCell(cell => {
                    cell.alignment = { horizontal: 'center', vertical: 'middle' };
                    cell.border = {
                        top:    { style: 'thin' },
                        left:   { style: 'thin' },
                        bottom: { style: 'thin' },
                        right:  { style: 'thin' }
                    };
                });
            });

            // 헤더 행(1행) 볼드 + 배경색
            ws.getRow(1).eachCell(cell => {
                cell.font = { bold: true };
                cell.fill = {
                    type: 'pattern',
                    pattern: 'solid',
                    fgColor: { argb: 'FFE0E0E0' }
                };
            });

            // 컬럼 너비
            ws.columns.forEach(c => { c.width = 22; });

            // 파일명
            const now = new Date();
            const yy = String(now.getFullYear()).slice(2);
            const mm = String(now.getMonth() + 1).padStart(2, '0');
            const dd = String(now.getDate()).padStart(2, '0');
            const fileName = `TSI_ByLocation_${yy}-${mm}-${dd}.xlsx`;

            // 다운로드
            const buffer = await wb.xlsx.writeBuffer();
            const base64 = btoa(String.fromCharCode(...new Uint8Array(buffer)));
            const a = document.createElement('a');
            a.href = 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,' + base64;
            a.download = fileName;
            a.click();

        } catch (error) {
            toast(this, 'Error', error?.body?.message || error?.message || 'Download failed.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    /**
     * @description Excel 다운로드 시 숫자 문자열을 Number 타입으로 변환
     * @param {string|number} value 셀 값
     * @returns {number|string}
     */
    toExcelNumber(value) {
        if (value === null || value === undefined || value === '') {
            return '';
        }

        if (typeof value === 'number') {
            return value;
        }

        let normalized = String(value).replace(/,/g, '').trim();

        if (/^-?\d+\.$/.test(normalized)) {
            normalized = normalized.slice(0, -1);
        }

        if (/^-?\d+\.0+$/.test(normalized)) {
            normalized = normalized.replace(/\.0+$/, '');
        }

        const parsed = Number(normalized);

        return Number.isFinite(parsed) ? parsed : value;
    }

    getSampleValue(apiName, fieldMeta) {

        const type = fieldMeta.type;

        const sampleOverrides = {
            'LocationName__c': 'Location Name A',
            'UnamedLocation__c': 'N',
            'Address__Street__s': '12 Yeouido-dong',
          /*  'GPSCoordinates__Latitude__s': '37.5665',
            'GPSCoordinates__Longitude__s': '126.9780',*/
            'Address__PostalCode__s': '07241',
            'CoveredSection__c': 'Property',
            'Asset__c': 'Asset 1',
            'TSICurrency__c': 'USD',
            'PremiumCurrency__c': 'USD',
            'FxRatePremCurrency__c': '1'
        };

        if (sampleOverrides[apiName]) {
            return sampleOverrides[apiName];
        }

        switch (type) {

            case 'DOUBLE':
            case 'CURRENCY':
            case 'PERCENT':
                return 100;

            case 'INTEGER':
                return 1;

            case 'BOOLEAN':
                return 'FALSE';

            case 'DATE':
                return '2025-01-01';

            case 'PICKLIST':
                return fieldMeta.picklistValues?.length
                    ? fieldMeta.picklistValues[0].label
                    : '';

            default:
                return '';
        }
    }

    /**
     * @description 업로드된 Excel 파일 파싱 후 데이터 변환 및 업로드 모달 오픈
     * @param {Event} event 파일 선택 이벤트
     */
    handleUploadClick(event) {
        if (this.isEditDisabled) {
            return;
        }

        const file = event.target.files?.[0];
        if (!file) return;

        this.fileName = file.name;
        const reader = new FileReader();

        reader.onload = async (e) => {
            try {
                const buffer = e.target.result;
                const workbook = new ExcelJS.Workbook();
                await workbook.xlsx.load(buffer);

                const worksheet = workbook.worksheets[0];
                if (!worksheet) {
                    toast(this, 'Error', 'No sheets found in Excel file.', 'error');
                    return;
                }

                const jsonData = [];
                worksheet.eachRow((row) => {
                    // row.values는 1-indexed → slice(1)로 0-indexed 배열 변환
                    jsonData.push(row.values.slice(1));
                });

                if (jsonData.length > 1) {
                    this.excelData = jsonData;
                    this.showModal = true;

                    const currencyJson = JSON.stringify(Object.keys(this._slipTsiMap || {}));

                    setTimeout(() => {
                        const upload = this.template.querySelector('c-opp-t-s-i-excel-upload');
                        if (upload) {
                            upload.setAllowedCurrencies(currencyJson);
                        }
                    }, 0);
                } else {
                    toast(this, 'Warning', 'No data found in the uploaded file.', 'warning');
                }
            } catch (error) {
                toast(this, 'Error', 'Failed to parse Excel file: ' + error.message, 'error');
            }
        };

        reader.readAsArrayBuffer(file);  // ExcelJS는 항상 ArrayBuffer
    }

    /**
     * @description 업로드 모달 닫기 및 상태 초기화
     */
    handleCloseModal() {
        this.showModal = false;
        this.excelData = [];
        this.fileName = '';
        // Reset file input
        const fileInput = this.template.querySelector('input[type="file"]');
        if (fileInput) {
            fileInput.value = '';
        }
    }

    /**
     * @description 업로드 완료 후 데이터 재조회
     * @returns {Promise<void>}
     */
    async handleSaveComplete() {
        // 모달 닫기
        this.showModal = false;
        await this.loadData();
    }

    /**
     * @description 입력 데이터 유효성 검증 — 필수값, 주소, 위경도, Currency 체크
     * @returns {{
     *  isValid: boolean,
     *  hasRequiredError: boolean,
     *  hasAddressError: boolean,
     *  hasLatLngError: boolean,
     *  hasCurrencyNotAllowed: boolean
     * }}
     */
    validateRows() {
        let isValid = true;

        let hasRequiredError = false;
        let hasAddressError = false;
        let hasLatLngError = false;
        let hasCurrencyNotAllowed = false;

        const allowedCurrencies = Object.keys(this._slipTsiMap || {});
        const hasCurrencyConstraint = allowedCurrencies.length > 0;

        const validateAndUpdateRow = row => {
            const addr = row.Address__c || {};
            const isUndefined = row.UnamedLocation__c === true || row.UnamedLocation__c === 'true';

            const hasLat = addr.latitude !== null && addr.latitude !== undefined && addr.latitude !== '';
            const hasLng = addr.longitude !== null && addr.longitude !== undefined && addr.longitude !== '';
            const hasLatLng = hasLat && hasLng;
            const latLngMismatch = (hasLat && !hasLng) || (!hasLat && hasLng);

            const hasStreet = addr.street && addr.street.trim() !== '';
            const hasPostal = (addr.postalCode && addr.postalCode.trim() !== '')
                || (row.postalCode && row.postalCode.trim() !== '');
            const hasAnyLocation = hasStreet || hasLatLng || hasPostal;

            const nameErr = !row.LocationName__c;
            const coveredErr = !row.CoveredSection__c;
            const assetErr = !row.Asset__c;
            const tsiCurrErr = !row.TSICurrency__c;
            const premCurrErr = !row.PremiumCurrency__c;
            const insuredErr = row.InsuredAmount__c === null || row.InsuredAmount__c === undefined;
            const grossRateErr = row.GrossRatePct__c === null || row.GrossRatePct__c === undefined;
            const dppErr = row.DPPct__c === null || row.DPPct__c === undefined;
            const currencyNotAllowed = hasCurrencyConstraint && row.TSICurrency__c && !allowedCurrencies.includes(row.TSICurrency__c);

            const isCurrencyDifferent = row.TSICurrency__c && row.PremiumCurrency__c
                && row.TSICurrency__c !== row.PremiumCurrency__c;
            const fxRateValue = row.FxRatePremCurrency__c;
            const fxRatePremErr = isCurrencyDifferent && (
                fxRateValue === null ||
                fxRateValue === undefined ||
                fxRateValue === '' ||
                (typeof fxRateValue === 'string' && fxRateValue.trim() === '')
            );

            const requiredError = nameErr || coveredErr || assetErr || tsiCurrErr || premCurrErr
                || insuredErr || grossRateErr || fxRatePremErr || dppErr;
            const addressError = !isUndefined && !hasAnyLocation;

            if (requiredError) hasRequiredError = true;
            if (addressError) hasAddressError = true;
            if (latLngMismatch) hasLatLngError = true;
            if (currencyNotAllowed) hasCurrencyNotAllowed = true;

            return {
                ...row,
                _nameClass: nameErr ? 'error-input' : '',
                _coveredClass: coveredErr ? 'error-input' : '',
                _assetClass: assetErr ? 'error-input' : '',
                _tsiCurrencyClass: (tsiCurrErr || currencyNotAllowed) ? 'error-input' : '',
                _premiumCurrencyClass: premCurrErr ? 'error-input' : '',
                _insuredClass: insuredErr ? 'error-input' : '',
                _addressClass: addressError ? 'error-box' : '',
                _latLngClass: latLngMismatch ? 'error-input' : '',
                _grossRatePctClass: grossRateErr ? 'error-input' : '',
                _fxRatePremClass: fxRatePremErr ? 'error-input' : '',
                _fxRatePremErr: fxRatePremErr,
                _dppCtErrClass: dppErr ? 'error-input' : '',
                _tdClasses: {
                    ...(row._tdClasses || {}),
                    FxRatePremCurrency__c: fxRatePremErr
                        ? 'editable-cell slds-align-center error-input'
                        : (row._tdClasses?.FxRatePremCurrency__c || 'editable-cell slds-align-center')
                            .replace('error-input', '').trim()
                }
            };
        };

        this.newRows = this.newRows.map(validateAndUpdateRow);
        this.data = this.data.map(validateAndUpdateRow);

        return {
            isValid: !(hasRequiredError || hasAddressError || hasLatLngError || hasCurrencyNotAllowed),
            hasRequiredError,
            hasAddressError,
            hasLatLngError,
            hasCurrencyNotAllowed
        };


    }

    /**
     * @description 목록 새로고침 — 신규행/선택/삭제 상태 초기화 후 재조회
     * @returns {Promise<void>}
     */
    async handleRefresh() {
        if (this.isActionDisabled) {
            return;
        }

        // 신규 행 제거
        this.newRows = [];

        // 선택 상태 초기화
        this.data = this.data.map(row => ({
            ...row,
            _checked: false,
            _dirtyFields: {},
            _tdClasses: {},
            _isEditing: false,
            _showEdit: false
        })).map(row => this.applyRowLocks(row));

        this.deletedRecordIds = [];
        this.mismatchError = false;
        await this.loadData();

    }

    /**
     * @description 신규 TSI Row 추가
     */
    addNewRow() {
        if (this.isEditDisabled) {
            return;
        }

        const newRow = this.applyRowLocks({
            key: 'NEW_' + this.rowKeySeq++,
            no: this.data.length + this.newRows.length + 1,
            _isNew: true,
            _isChecked: false,
            _isSearching: false,
            _isEditing: true,
            _tdClasses: {},

            LocationName__c: '',
            UnamedLocation__c: false,
            Address__c: {
                street: '',
                city: '',
                province: '',
                postalCode: '',
                country: ''
            },
            CoveredSection__c: '',
            Asset__c: '',
            TSICurrency__c: '',
            InsuredAmount__c: null,
            GrossRatePct__c: null,
            DPPct__c: null,
            PremiumCurrency__c: '',
            FxRatePremCurrency__c: null
        });

        this.newRows = [...this.newRows, newRow];
    }

    /**
     * @description 저장 전 위경도 기반 주소 Reverse Geocoding 처리
     * @returns {Promise<void>}
     */
    async enrichAddressBeforeSave() {

        const updatedRows = [];

        for (let row of this.newRows) {

            if (row.UnamedLocation__c === true) {
                updatedRows.push(row);
                continue;
            }

            const addr = row.Address__c || {};

            const latitude = addr.latitude;
            const longitude = addr.longitude;

            const hasLatLng =
                latitude !== undefined &&
                latitude !== null &&
                latitude.toString().trim() !== '' &&
                longitude !== undefined &&
                longitude !== null &&
                longitude.toString().trim() !== '';

            if (!hasLatLng) {
                updatedRows.push(row);
                continue;
            }

            try {
                const resultList = await findGeoInfo({
                    geoRequest: JSON.stringify({
                        mode: 'REVERSE',
                        latitude: parseFloat(latitude),
                        longitude: parseFloat(longitude)
                    })
                });

                if (resultList?.length && resultList[0]?.status === 'OK') {

                    const geo = resultList[0];

                    updatedRows.push({
                        ...row,
                        Address__c: {
                            ...addr,
                            street: geo.address || '',
                            city: geo.city || '',
                            stateCode: geo.stateCode || '',
                            postalCode: geo.postalCode || '',
                            countryCode: geo.countryCode || '',
                            latitude: geo.lat,
                            longitude: geo.lng
                        }
                    });

                } else {
                    updatedRows.push(row);
                }

            } catch (e) {
                console.error('Reverse geocode error:', e);
                updatedRows.push(row);
            }
        }

        this.newRows = updatedRows;
    }

    /**
     * @description TSI 데이터 저장 — Insert / Update / Delete 처리 및 후속 플래그 업데이트
     * @returns {Promise<void>}
     */
    async handleSave() {
        if (this.isEditDisabled) {
            return;
        }

        if (this.isSavingTSI) return;
        this.isSavingTSI = true;

        const validation = this.validateRows();

        if (!validation.isValid) {
            let message = '';

            if (validation.hasCurrencyNotAllowed) {
                const allowed = Object.keys(this._slipTsiMap || {}).join(', ');
                message = `TSI Currency must match Slip TSI Currency. Allowed: ${allowed}`;
            } else if (validation.hasRequiredError) {
                message = this.labels.requiredMsg;
            } else if (validation.hasLatLngError) {
                message = this.labels.latLngMsg;
            } else if (validation.hasAddressError) {
                message = this.labels.unnamedLocationMsg;
            }

            toast(this, 'Error', message, 'error');
            this.isSavingTSI = false;
            return;
        }

        // Todo : TSI 연결 Currency Panel 삭제 주석
        // 삭제 시 Panel 연계 삭제 로직은 현재 미사용
        // if (this.deletedRecordIds.length > 0) {
        //     const hasPanel = await deleteTSIByLocationAndPanel({
        //         placementId: this.placementId,
        //         opportunityId: this.recordId,
        //         slipInfoId: this.slipInfoId,
        //         deleteIds: this.deletedRecordIds,
        //         doDelete: false
        //     });
        //
        //     if (hasPanel) {
        //         const confirmed = await confirm(
        //             'All records for some currencies are being deleted.\nRelated Panel records will also be deleted.\n\nProceed?',
        //             'Confirm Delete'
        //         );
        //
        //         if (!confirmed) {
        //             this.isSavingTSI = false;
        //             return;
        //         }
        //     }
        //
        //     await deleteTSIByLocationAndPanel({
        //         placementId: this.placementId,
        //         opportunityId: this.recordId,
        //         slipInfoId: this.slipInfoId,
        //         deleteIds: this.deletedRecordIds,
        //         doDelete: true
        //     });
        // }

        try {
            this.isLoading = true;

            await this.enrichAddressBeforeSave();

            const insertRows = this.newRows.filter(r => r._isNew);
            const updateRows = this.data.filter(r => !r._isNew && r.Id && r._isEditing);

            const mapRowToPayload = r => {
                const addr = r.Address__c || {};

                return {
                    Id: r.Id,
                    LocationName__c: r.LocationName__c,
                    UnamedLocation__c: r.UnamedLocation__c === 'true',
                    Type__c: 'TSIByLocation',

                    // Address
                    Address__Street__s: addr.street,
                    Address__City__s: addr.city,
                    Address__StateCode__s: addr.stateCode || '',
                    Address__CountryCode__s: addr.countryCode || '',
                    Address__PostalCode__s: addr.postalCode || r.postalCode || null,

                    // 위경도
                    GPSCoordinates__Latitude__s: addr.latitude ?? null,
                    GPSCoordinates__Longitude__s: addr.longitude ?? null,

                    CoveredSection__c: r.CoveredSection__c,
                    Asset__c: r.Asset__c,
                    TSICurrency__c: r.TSICurrency__c,
                    InsuredAmount__c: r.InsuredAmount__c,
                    GrossRatePct__c: r.GrossRatePct__c,
                    DPPct__c: r.DPPct__c,
                    PremiumCurrency__c: r.PremiumCurrency__c,
                    FxRatePremCurrency__c: r.FxRatePremCurrency__c
                };
            };

            const insertPayload = insertRows.map(mapRowToPayload);
            const updatePayload = updateRows.map(mapRowToPayload);

            // Delete
            if (this.deletedRecordIds.length) {
                await deleteTSIByLocation({
                    recordIds: this.deletedRecordIds
                });
            }

            // Insert
            let isMatch = true;

            if (insertPayload.length) {
                isMatch = await insertTSIByLocation({
                    slipInfoId: this.slipInfoId,
                    placementId: this.placementId,
                    records: insertPayload
                });
            }

            if (updatePayload.length) {
                const updateMatch = await updateTSIByLocation({
                    slipInfoId: this.slipInfoId,
                    placementId: this.placementId,
                    records: updatePayload
                });

                isMatch = isMatch && updateMatch;
            }

            toast(this, 'Success', this.labels.saveSuccessMsg, 'success');

            this.newRows = [];
            this.deletedRecordIds = [];

            await this.loadData();

            /*const placementId = this.isPlacementPage ? this.recordId : null;
            const opportunityId = this.isOpportunityPage ? this.recordId : null;*/


            await updateNeedRecalculateFlag({
                placementId: this.resolvedPlacementIdForFlag,
                opportunityId: this.resolvedOpportunityIdForFlag,
                slipInfoId: this.slipInfoId
            });

        } catch (error) {
            console.error('Save error:', error);
            toast(this, 'Error', error?.body?.message || 'Unexpected error occurred.', 'error');
        } finally {
            this.isLoading = false;
            this.isSavingTSI = false;
        }
    }

    /**
     * @description 주소 검색 (신규 Row) — 입력값 기반 Geo API 호출 후 주소 세팅
     * @param {Event} event 입력 이벤트
     */
    async handleAddressSearch(event) {
        if (this.isEditDisabled) {
            return;
        }

        const key = event.target.dataset.key;
        const query = event.target.value;
        //this.isSearching = true;

        if (!query) return;

        const request = {
            mode: 'ADDRESS',
            address: query
        };

        try {
            const resultList = await findGeoInfo({
                geoRequest: JSON.stringify(request)
            });

            if (!resultList?.length || resultList[0]?.status !== 'OK') {
                return;
            }

            const geo = resultList[0];

            this.newRows = this.newRows.map(row => {
                if (row.key !== key) return row;

                return {
                    ...row,
                    Address__c: {
                        street: geo.address || '',
                        city: geo.city || '',
                        stateCode: geo.stateCode || '',
                        postalCode: geo.postalCode || '',
                        countryCode: geo.countryCode || '',
                        latitude: geo.lat,
                        longitude: geo.lng
                    },
                    hasAddressError: false,
                   // addressClass: ''
                };
            });

        } catch (e) {
            console.error(e);
            toast(this, 'Error', e.body?.message || 'Search failed', 'error');
        }
    }

    /**
     * @description Row 번호 재계산 (삭제/추가 이후 순번 정렬)
     */
    recalculateRowNo() {
        let seq = 1;

        this.data = this.data.map(r => ({
            ...r,
            no: seq++
        }));

        this.newRows = this.newRows.map(r => ({
            ...r,
            no: seq++
        }));
    }

    /**
     * @description 선택된 Row 삭제 처리 (기존 + 신규)
     * @returns {Promise<void>}
     */
    async handleDelete() {
        if (this.isEditDisabled) {
            return;
        }

        const selectedExisting = this.data.filter(r => r._checked);
        const selectedRows = this.newRows.filter(r => r._isChecked);

        if (!selectedExisting.length && !selectedRows.length) {
            toast(this, 'Info', this.labels.noRowSelected, 'info');
            return;
        }

        const currencies = [
            ...selectedExisting.map(r => r.PremiumCurrency__c),
            ...selectedRows.map(r => r.PremiumCurrency__c)
        ].filter(c => c);

        const placementId = this.resolvedPlacementIdForFlag;
        const opportunityId = this.resolvedOpportunityIdForFlag;

        let deletedExistingCount = 0;
        let deletedNewCount = 0;

        selectedExisting.forEach(row => {
            if (row.Id) {
                this.deletedRecordIds.push(row.Id);
                deletedExistingCount++;
            }
        });

        deletedNewCount = selectedRows.length;

        this.data = this.data
            .filter(r => !r._checked)
            .map((row, index) => ({
                ...row,
                no: index + 1,
                _checked: false
            }));

        this.newRows = this.newRows
            .filter(r => !r._isChecked)
            .map(row => ({
                ...row,
                _isChecked: false
            }));

        this.recalculateRowNo();

        toast(this, 'Success', `${deletedExistingCount + deletedNewCount} row(s) marked for delete.`, 'success');
    }

    /**
     * @description Fullscreen 토글 처리
     * @returns {Promise<void>}
     */

    async toggleFullscreenAction() {
        const target =
            this.template.querySelector('.fsRoot') ?? this.template.host;
        if (!target) return;

        try {
            this.isFullscreen = await toggleFullscreen(target, {
                className: 'pseudo-fs',
                lockScroll: true
            });
        } catch (e) {
            console.error('Fullscreen toggle failed', e);
        }
    }

    /**
     * @description Row 데이터 공통 업데이트 (기존/신규 공통)
     * @param {string} key Row 식별자
     * @param {string} field 필드명
     * @param {*} value 값
     * @param {{markDirty?: boolean, isNewRow?: boolean}} options 옵션
     */
    updateRow(key, field, value, options = {}) {
        const {markDirty = false, isNewRow = false} = options;

        const baseClass = 'editable-cell slds-align-center';

        const update = row => {
            if (row.key !== key) return row;

            let updatedRow = { ...row };

            if (field === 'Address_postalCode' || field === 'Address__c.postalCode') {
                updatedRow.Address__c = {
                    ...(row.Address__c || {}),
                    postalCode: value
                };
            } else if (field === 'GPSCoordinates__Latitude__s') {
                updatedRow.Address__c = {
                    ...(row.Address__c || {}),
                    latitude: value
                };
            } else if (field === 'GPSCoordinates__Longitude__s') {
                updatedRow.Address__c = {
                    ...(row.Address__c || {}),
                    longitude: value
                };
            } else {
                updatedRow[field] = value;
            }

            if (markDirty && !isNewRow) {
                const dirtyFields = { ...(row._dirtyFields || {}) };
                dirtyFields[field] = true;

                const tdClasses = { ...(row._tdClasses || {}) };
                tdClasses[field] = baseClass + ' dirty-cell';

                updatedRow._dirtyFields = dirtyFields;
                updatedRow._tdClasses = tdClasses;
            }

            updatedRow._isEditing = true;

            return updatedRow;
        };

        this.data = this.data.map(update);
        this.newRows = this.newRows.map(update);
    }

    get isAllSelected() {
        if (this.data.length === 0 && this.newRows.length === 0) {
            return false;
        }

        const allExistingChecked =
            this.data.length ? this.data.every(r => r._checked) : true;

        const allNewChecked =
            this.newRows.length ? this.newRows.every(r => r._isChecked) : true;

        return allExistingChecked && allNewChecked;
    }

    get LocationNameLabel() {
        return this.objectFields?.LocationName__c?.label ?? 'Location Name';
    }

    get UndefinedLocationLabel() {
        return this.objectFields?.UnamedLocation__c?.label ?? 'Undefined Location';
    }

    get AddressLabel() {
        return this.objectFields?.Address__c?.label ?? 'Address';
    }

    get LatitudeLabel() {
        return 'Latitude';
    }

    get LongitudeLabel() {
        return 'Longitude';
    }

    get PostalCodeLabel() {
        return this.objectFields?.Address__PostalCode__s?.label ?? 'Postal Code';
    }

    get CoveredSectionLabel() {
        return this.objectFields?.CoveredSection__c?.label ?? 'Covered Section';
    }

    get AssetLabel() {
        return this.objectFields?.Asset__c?.label ?? 'Asset';
    }

    get TSICurrencyLabel() {
        return this.objectFields?.TSICurrency__c?.label ?? 'TSI Currency';
    }

    get InsuredAmountLabel() {
        return this.objectFields?.InsuredAmount__c?.label ?? 'Insured Amount';
    }

    get GrossRateLabel() {
        return this.objectFields?.GrossRatePct__c?.label ?? 'Gross Rate(%)'
    }

    get DPLabel() {
        return this.objectFields?.DPPct__c?.label ?? 'DP(%)';
    }

    get PremiumCurrencyLabel() {
        return this.objectFields?.PremiumCurrency__c?.label ?? 'Premium Currency';
    }

    get FxRatePremCurrencyLabel() {
        return this.objectFields?.FxRatePremCurrency__c?.label ?? 'Fx Rate to Prem Currency';
    }

    get GrossPremDPLabel() {
        return this.objectFields?.GrossPremBfDP_fm__c?.label ?? 'Gross Prem (Before DP)';
    }

    get GrossPremLabel() {
        return this.objectFields?.GrossPrem_fm__c?.label ?? 'Gross Prem';
    }

    /**
     * @description 신규 Row 체크박스 선택 처리
     * @param {Event} event 체크 이벤트
     */
    handleNewRowCheck(event) {
        if (this.isEditDisabled) {
            return;
        }

        const key = event.target.dataset.key;
        const checked = event.target.checked;

        this.newRows = this.newRows.map(r =>
            r.key === key
                ? { ...r, _isChecked: checked }
                : r
        );
    }

    formatDecimal4(value) {
        if (value === null || value === undefined || value === '') return '';
        return parseFloat(value).toFixed(4);
    }

    /**
     * @description 신규 Row 값 변경 처리
     * @param {Event} event 입력 이벤트
     */
    handleNewRowChange(event) {
        if (this.isEditDisabled) {
            return;
        }
        const key = event.target.dataset.key;
        const field = event.target.dataset.field;
        let value = event.detail?.value ?? event.target.value;

        if (field === 'GrossRatePct__c' && value !== '' && value !== null) {
            value = parseFloat(parseFloat(value).toFixed(4));
        }

        const base = 'editable-cell slds-align-center';

        const updateRow = row => {
            if (row.key !== key) return row;

            const tdClasses = { ...(row._tdClasses || {}) };

            if (field === 'UnamedLocation__c') {
                tdClasses.UnamedLocation__c = base + ' dirty-cell';
            } else {
                tdClasses[field] = base + ' dirty-cell';
            }

            if (field === 'Address__c.postalCode') {
                return {
                    ...row,
                    Address__c: {
                        ...(row.Address__c || {}),
                        postalCode: value
                    },
                    _isEditing: true
                };
            }

            if (field === 'GPSCoordinates__Latitude__s') {
                return {
                    ...row,
                    Address__c: {
                        ...(row.Address__c || {}),
                        latitude: value
                    },
                    _isEditing: true
                };
            }

            if (field === 'GPSCoordinates__Longitude__s') {
                return {
                    ...row,
                    Address__c: {
                        ...(row.Address__c || {}),
                        longitude: value
                    },
                    _isEditing: true
                };
            }

            const updatedRow = {
                ...row,
                [field]: value,
                _isEditing: true,
                _tdClasses: tdClasses
            };

            if (field === 'UnamedLocation__c') {
                updatedRow._isAddressDisabled = value === 'true' || value === true;
            }

            return updatedRow;
        };

        this.newRows = this.newRows.map(updateRow).map(row => this.applyRowLocks(row));
        this.data = this.data.map(updateRow).map(row => this.applyRowLocks(row));
    }

    /**
     * @description 전체 선택 체크박스 처리 (기존 + 신규)
     * @param {Event} event 체크 이벤트
     */
    handleSelectAll(event) {
        if (this.isEditDisabled) {
            return;
        }

        const checked = event.target.checked;

        // 기존 레코드
        this.data = this.data.map(row => ({
            ...row,
            _checked: checked
        }));

        // 신규 row
        this.newRows = this.newRows.map(row => ({
            ...row,
            _isChecked: checked
        }));
    }

    /**
     * @description 기존 Row 체크박스 선택 처리
     * @param {Event} event 체크 이벤트
     */
    handleRowSelect(event) {
        if (this.isEditDisabled) {
            return;
        }

        const key = event.target.dataset.key;
        const checked = event.target.checked;

        this.data = this.data.map(row =>
            row.key === key
                ? { ...row, _checked: checked }
                : row
        );
    }

    /**
     * @description 콤보박스 값 변경 처리 (Currency/Fx 포함)
     * @param {Event} event 변경 이벤트
     */
    handleComboboxChange(event) {
        if (this.isEditDisabled) {
            return;
        }

        const key = event.target.dataset.key;
        const field = event.target.dataset.field;
        const value = event.detail.value;
        const base = 'editable-cell slds-align-center';

        const updateRow = row => {

            if (row.key !== key) return row;

            const tdClasses = { ...(row._tdClasses || {}) };
            tdClasses[field] = base + ' dirty-cell';

            let updatedRow = {
                ...row,
                [field]: value,
                _tdClasses: tdClasses,
                _isEditing: true
            };

            if (field === 'UnamedLocation__c') {
                const isUnnamed = value === 'true' || value === true;
                updatedRow._isAddressDisabled = isUnnamed;
            }

            if (field === 'TSICurrency__c' || field === 'PremiumCurrency__c') {
                const tsi = field === 'TSICurrency__c' ? value : row.TSICurrency__c;
                const prem = field === 'PremiumCurrency__c' ? value : row.PremiumCurrency__c;

                if (tsi && prem && tsi === prem) {
                    // Currency 같으면 1.0 세팅
                    updatedRow.FxRatePremCurrency__c = 1.0;
                    updatedRow._isFxDisabled = true;
                    tdClasses.FxRatePremCurrency__c = base + ' dirty-cell';
                } else {
                    updatedRow._isFxDisabled = false;
                    if (row._isFxDisabled) {  // 이전에 disabled(자동세팅) 상태였던 경우만
                        updatedRow.FxRatePremCurrency__c = null;
                    }
                    tdClasses.FxRatePremCurrency__c = base + ' dirty-cell';
                }
            }

            updatedRow._isFxDisabledFinal = updatedRow._isFxDisabled;

            return updatedRow;
        };

        this.newRows = this.newRows.map(updateRow).map(row => this.applyRowLocks(row));
        this.data = this.data.map(updateRow).map(row => this.applyRowLocks(row));
    }

    /**
     * @description 주소 입력 변경 처리 (신규 Row)
     * @param {CustomEvent} event 주소 컴포넌트 이벤트
     */
    async handleAddressChange(event) {
        if (this.isEditDisabled) {
            return;
        }

        const key = event.target.dataset.key;
        const address = event.detail;

        this.newRows = this.newRows.map(row => {
            if (row.key !== key) return row;

            return {
                ...row,
                Address__c: {
                    ...(row.Address__c || {}),
                    street: address.street || '',
                    city: address.city || '',
                    state: address.province || '',
                    postalCode: address.postalCode || '',
                    country: address.country || ''
                },
                hasAddressError: false,
                addressClass: ''
            };
        }).map(row => this.applyRowLocks(row));
    }

    get showNoDataMessage() {
        return (!this.data || this.data.length === 0)
            && (!this.newRows || this.newRows.length === 0);
    }

    handleRowHover(event) {
        const key = event.currentTarget.dataset.key;

        this.data = this.data.map(r =>
            r.key === key ? { ...r, _showEdit: true } : r
        );
    }

    handleRowLeave(event) {
        const key = event.currentTarget.dataset.key;

        this.data = this.data.map(r =>
            r.key === key ? { ...r, _showEdit: false } : r
        );
    }

    /**
     * @description 기존 Row 수정 모드 진입
     * @param {Event} event 클릭 이벤트
     */
    handleEditRow(event) {
        if (this.isEditDisabled) {
            return;
        }

        const key = event.currentTarget.dataset.key;

        this.data = this.data.map(r => {
            if (r.key !== key) return r;

            let updatedRow = {
                ...r,
                UnamedLocation__c: String(r.UnamedLocation__c),
                _isEditing: true,
                _showEdit: false,

                _isAddressDisabled: r.UnamedLocation__c === true || r.UnamedLocation__c === 'true'
            };

            const tsi = updatedRow.TSICurrency__c;
            const prem = updatedRow.PremiumCurrency__c;

            if (tsi && prem && tsi === prem) {
                updatedRow.FxRatePremCurrency__c = 1.0;
                updatedRow._isFxDisabled = true;
            } else {
                updatedRow._isFxDisabled = false;
            }

            updatedRow._isFxDisabledFinal = updatedRow._isFxDisabled;

            return this.applyRowLocks(updatedRow);
        });
    }

    /**
     * @description 기존 Row 값 변경 처리
     * @param {Event} event 입력 이벤트
     */
    handleExistingRowChange(event) {
        if (this.isEditDisabled) {
            return;
        }

        const key = event.target.dataset.key;
        const field = event.target.dataset.field;
        const value = event.detail?.value ?? event.target.value;

        this.data = this.data.map(r => {
            if (r.key !== key) return r;

            const dirtyFields = { ...(r._dirtyFields || {}) };
            dirtyFields[field] = true;

            const base = 'editable-cell slds-align-center';
            const tdClasses = { ...(r._tdClasses || {}) };
            tdClasses[field] = base + ' dirty-cell';

            let updatedRow;

            if (field === 'FxRatePremCurrency__c' && r._isFxDisabled) {
                return r;
            }

            if (field === 'UnamedLocation__c') {
                tdClasses.UnamedLocation__c = base + ' dirty-cell';

                const isAddressDisabled = value === 'true' || value === true;
                updatedRow = {
                    ...r,
                    UnamedLocation__c: value,
                    _isAddressDisabled: value === 'true' || value === true,
                    _dirtyFields: dirtyFields,
                    _tdClasses: tdClasses
                };
            }

            else if (field === 'Address_postalCode') {
                updatedRow = {
                    ...r,
                    Address__c: {
                        ...r.Address__c,
                        postalCode: value
                    },
                    _dirtyFields: dirtyFields,
                    _tdClasses: tdClasses
                };
            }

            else {
                updatedRow = {
                    ...r,
                    [field]: value,
                    _dirtyFields: dirtyFields,
                    _tdClasses: tdClasses
                };
            }

            const tsi = updatedRow.TSICurrency__c;
            const prem = updatedRow.PremiumCurrency__c;

            if (tsi && prem && tsi === prem) {
                updatedRow.FxRatePremCurrency__c = 1.0;
                updatedRow._isFxDisabled = true;
            } else {
                updatedRow._isFxDisabled = false;
            }

            updatedRow._isFxDisabledFinal = updatedRow._isFxDisabled;

            return this.applyRowLocks(updatedRow);
        });
        this.calculatePremiumTotals();
    }

    /**
     * @description 기존 Row 주소 검색
     * @param {Event} event 입력 이벤트
     */
    async handleExistingAddressSearch(event) {
        if (this.isEditDisabled) {
            return;
        }

        const key = event.target.dataset.key;
        const query = event.target.value;
        if (!query) return;

        try {
            const resultList = await findGeoInfo({
                geoRequest: JSON.stringify({
                    mode: 'ADDRESS',
                    address: query
                })
            });

            if (!resultList?.length || resultList[0]?.status !== 'OK') return;

            const geo = resultList[0];

            this.data = this.data.map(row => {
                if (row.key !== key) return row;

                return {
                    ...row,
                    Address__c: {
                        street: geo.address || '',
                        city: geo.city || '',
                        state: geo.stateCode || '',
                        postalCode: geo.postalCode || '',
                        country: geo.countryCode || '',
                        latitude: geo.lat,
                        longitude: geo.lng
                    }
                };
            }).map(row => this.applyRowLocks(row));

        } catch (e) {
            toast(this, 'Error', e.body?.message || 'Search failed', 'error');
        }
    }

    /**
     * @description 기존 Row 주소 변경 처리
     * @param {CustomEvent} event 주소 이벤트
     */
    handleExistingAddressChange(event) {
        if (this.isEditDisabled) {
            return;
        }

        const key = event.target.dataset.key;
        const address = event.detail;

        this.data = this.data.map(row => {
            if (row.key !== key) return row;

            return {
                ...row,
                Address__c: {
                    ...(row.Address__c || {}),
                    street: address.street || '',
                    city: address.city || '',
                    state: address.province || '',
                    postalCode: address.postalCode || '',
                    country: address.country || ''
                },
                _dirtyFields: {
                    ...(row._dirtyFields || {}),
                    Address: true
                },
                _tdClasses: {
                    ...(row._tdClasses || {}),
                    Address: 'address-td dirty-cell'
                }
            };
        }).map(row => this.applyRowLocks(row));
    }

    /**
     * @description Premium 합계 계산 후 상위 컴포넌트로 이벤트 전달
     */
    calculatePremiumTotals() {
        const currencyMap = {};

        const allRows = [...this.data, ...(this.newRows || [])];

        allRows.forEach(r => {

            const cur = r.PremiumCurrency__c;

            if (!cur) return;

            if (!currencyMap[cur]) {
                currencyMap[cur] = {
                    sumBfDP: 0,
                    sumDP: 0
                };
            }

            currencyMap[cur].sumBfDP += Number(r.GrossPremBfDP_fm__c || 0);
            currencyMap[cur].sumDP += Number(r.GrossPrem_fm__c || 0);
        });

        this.dispatchEvent(new CustomEvent('premchange', {
            detail: currencyMap
        }));
    }

    /**
     * @description Slip TSI vs Location TSI 불일치 검증
     */
    validateTSIMismatch() {
        if (this._suppressMismatchMsg) {
            this.mismatchCurrencies = '';
            this.mismatchError = false;
            return;
        }

        const locationMap = {};
        const allRows = [...(this.data || []), ...(this.newRows || [])];

        allRows.forEach(r => {
            const cur = r.TSICurrency__c;
            if (!cur) return;
            locationMap[cur] = (locationMap[cur] || 0) + Number(r.InsuredAmount__c || 0);
        });

        // // 없는 것은 오류 노출
        // const allCurrencies = new Set([
        //     ...Object.keys(this._slipTsiMap || {}),
        //     ...Object.keys(locationMap)
        // ]);
        // 없는 currency는 무시
        const allCurrencies = new Set(Object.keys(locationMap));
        const mismatchList = [];
        allCurrencies.forEach(cur => {
            const slipVal = this._slipTsiMap[cur] || 0;
            const locVal = locationMap[cur] || 0;
            if (Math.abs(slipVal - locVal) > 0.01) {
                mismatchList.push(cur);
            }
        });

        this.mismatchCurrencies = mismatchList.join(', ');
        this.mismatchError = mismatchList.length > 0;
    }

    /**
     * @description ExcelJS 라이브러리 로드
     * @returns {Promise<void>}
     */
    async loadExcelJS() {
        if (this._excelJsLoaded) return;
        try {
            await loadScript(this, exceljs);
            this._excelJsLoaded = true;
        } catch (error) {
            console.error('ExcelJS Load Error', error);
        }
    }

    /**
     * @description 컴포넌트 초기화 — 라이브러리 및 필수 데이터 로드
     * @returns {Promise<void>}
     */
    async connectedCallback() {
        if(this._init) return;

        await this.loadExcelJS();
        await this.loadSlipType();
        await this.loadTransactionType();
        this._init = true;
    }
}