/**********************************************************************************
 * @filename       : oppTSIExcelUpload.js
 * @project-name  : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-16 (금)
 * @group         :
 * @group-content :
 * @description   : TSI By Location 데이터를 Excel 파일로 업로드·검증·저장하는 LWC 모달 컴포넌트
 *                  - SheetJS 기반 Excel 파싱, 필드 메타데이터(getTSIFieldMetadata) 기반 컬럼 매핑 및 헤더 유효성 검증
 *                  - 필수값·숫자·Picklist·Boolean·허용 Currency 등 셀 단위 실시간 유효성 검사
 *                  - 가상 스크롤(Virtual Window) 렌더링, Google Map Geo API 주소 보정, Apex 저장(saveTSIByLocation)을 포함
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-16       i2max             Create
 **********************************************************************************/

import { LightningElement, api, track, wire} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import sheetjs from '@salesforce/resourceUrl/sheetjs';
import OPP_TSI_OBJECT from '@salesforce/schema/OPP_TSIByLocation__c';
import getTSIFieldMetadata from '@salesforce/apex/OPP_TSIUpload_Ctrl.getTSIFieldMetadata';
import saveTSIByLocation from '@salesforce/apex/OPP_TSIUpload_Ctrl.saveTSIByLocation';
import findGeoInfo from '@salesforce/apex/COM_GoogleMapService.findGeoInfo';
import BTN_SAVE from '@salesforce/label/c.COM_BTN_SAVE';

const ROW_HEIGHT = 36;
const BUFFER_ROWS = 10;

export default class oppTSIExcelUpload extends LightningElement {
    @api recordId;
    @api slipInfoId;
    @api excelData;
    @api fileName;
    @api allowedCurrencies = '[]';

    @track isSaving = false;
    @track headers = [];
    @track rows = [];
    @track startIndex = 0;
    @track endIndex = 0;

    viewportRows = 0;
    fieldMetadata = {};
    columnMapping = {};
    save_label = BTN_SAVE;
    sheetJsLoaded = false;
    _scrollEl;
    objectInfoLoaded = false;


    /**
     * @description OPP_TSIByLocation__c ObjectInfo wire — objectInfoLoaded 설정 및 필드 메타데이터 처리
     * @param {Object} data ObjectInfo 데이터
     * @param {Object} error 오류 객체
     */
    @wire(getObjectInfo, { objectApiName: OPP_TSI_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.objectInfoLoaded = true;
            this.processObjectInfo(data);
        } else if (error) {
            console.error('Error loading object info:', error);
        }
    }

    /**
     * @description 스크롤 이벤트 핸들러 — 가상 스크롤 윈도우 업데이트
     */
    handleScroll() {
        this.updateWindow();
    }

    /**
     * @description 가상 스크롤 기준으로 현재 화면에 표시할 행 목록을 반환
     * @returns {Array} startIndex ~ endIndex 범위의 행 데이터
     */
    get visibleRows() {
        return this.rows.slice(this.startIndex, this.endIndex);
    }

    /**
     * @description 테이블 colspan 값 반환 — 헤더 수 + 1 (행 번호 컬럼 포함)
     * @returns {number} colspan 값
     */
    get columnSpan() {
        const count = Array.isArray(this.headers) ? this.headers.length : 0;
        return Math.max(1, count + 1);
    }

    /**
     * @description 셀 값 변경 핸들러 — 변경된 셀 값을 업데이트하고 유효성 검증 수행
     * @param {Event} event input change 이벤트 (data-row, data-field-name 속성 포함)
     */
    handleCellChange(event) {

        const rowIndex = parseInt(event.target.dataset.row, 10);
        const fieldName = event.target.dataset.fieldName;
        const newValue = event.target.value;

        const row = this.rows[rowIndex];
        if (!row) return;

        const cell = row.cells.find(c => c.fieldName === fieldName);
        if (!cell) return;

        // 값 업데이트
        cell.value = newValue;
        cell.displayValue = newValue;

        const error = this.validateCell(cell);

        if (error) {
            cell.error = error;
            cell.hasError = true;
            cell.cellInputClass = 'cell-input error-cell';
        } else {
            cell.error = null;
            cell.hasError = false;
            cell.cellInputClass = 'cell-input';
        }

        this.hasErrors = this.rows.some(r => r.cells.some(c => c.hasError));
        this.rows = [...this.rows];
    }

    /**
     * @description ObjectInfo 처리 — apiName 로깅 (확장 포인트)
     * @param {Object} objectInfo ObjectInfo 데이터
     */
    processObjectInfo(objectInfo) {
        console.log('Object Info loaded:', objectInfo.apiName);
    }

    /**
     * @description
     * 컴포넌트 초기화 — 엑셀 데이터가 있으면 SheetJS 로드 후 필드 메타데이터 조회 및 테이블 데이터 준비
     * - columnMapping 구성 후 테이블 데이터 파싱, 가상 스크롤 초기화, 전체 셀 유효성 검증 수행
     */
    async connectedCallback() {
        if (this.excelData && this.excelData.length > 0) {
            await this.loadSheetJS();
            const metadata = await getTSIFieldMetadata();

            this.fieldOrder = metadata.fieldOrder;
            this.fieldMetadata = metadata.fields;

            this.buildColumnMapping();

            // Wait for metadata to be loaded before preparing data
            if (Object.keys(this.columnMapping).length > 0) {
                this.prepareTableData();
                this.initVirtualWindow();
                await this.validateAllCells();
            }
        }
    }

    /**
     * @description SheetJS 라이브러리 동적 로드 — 이미 로드된 경우 스킵
     */
    async loadSheetJS() {
        if (this.sheetJsLoaded) return;
        try {
            await loadScript(this, sheetjs);
            this.sheetJsLoaded = true;
        } catch (error) {
            this.showToast('Error', 'Failed to load SheetJS library', 'error');
        }
    }

    /**
     * @description 렌더링 완료 후 가상 스크롤 컨테이너 엘리먼트 참조 설정
     */
    renderedCallback() {
        if (!this._scrollEl) {
            this._scrollEl = this.template.querySelector('.table-container');
        }
    }

    /**
     * @description
     * 컬럼 매핑 구성 — fieldOrder 기준으로 columnMapping(API 명 → 컬럼 정보) 및 labelToApiMap(Label → API 명) 생성
     * - Label 은 공백 정규화 및 소문자 변환 후 매핑
     */
    buildColumnMapping() {

        this.columnMapping = {};
        this.labelToApiMap = {};

        this.fieldOrder.forEach((apiName, index) => {

            const meta = this.fieldMetadata[apiName];

            const normalizedLabel = meta.label
                .replace(/\s+/g, " ")
                .trim()
                .toLowerCase();

            this.columnMapping[apiName] = {
                apiName: apiName,
                label: meta.label,
                index: index,
                required: meta.required,
                type: meta.type
            };

            this.labelToApiMap[normalizedLabel] = apiName;
        });
    }

    /**
     * @description
     * 가상 스크롤 윈도우 업데이트 — 스크롤 위치 기준으로 startIndex / endIndex 재계산
     * - BUFFER_ROWS 만큼 앞뒤로 여유 행을 포함하여 부드러운 스크롤 구현
     */
    updateWindow() {
        if (!this._scrollEl || this.totalRows === 0) return;

        const scrollTop = this._scrollEl.scrollTop;
        const firstVisible = Math.floor(scrollTop / ROW_HEIGHT);

        const newStart = Math.max(0, firstVisible - BUFFER_ROWS);
        const newEnd = Math.min(this.totalRows, firstVisible + this.viewportRows + BUFFER_ROWS);

        if (newStart !== this.startIndex || newEnd !== this.endIndex) {
            this.startIndex = newStart;
            this.endIndex = newEnd;
        }
    }

    /**
     * @description 가상 스크롤 초기화 — viewportRows 계산 후 totalRows / startIndex / endIndex 설정
     */
    initVirtualWindow() {
        this.computeViewportRows();

        this.totalRows = this.rows.length;

        this.startIndex = 0;
        this.endIndex = Math.min(
            this.viewportRows + BUFFER_ROWS,
            this.totalRows
        );
    }

    /**
     * @description 컨테이너 높이 기준으로 화면에 표시 가능한 행 수를 계산하여 viewportRows 설정
     */
    computeViewportRows() {
        if (!this._scrollEl) {
            this.viewportRows = 10; // 기본값
            return;
        }

        const containerHeight = this._scrollEl.clientHeight || 400;
        this.viewportRows = Math.ceil(containerHeight / ROW_HEIGHT);
    }

    // 파싱된 허용 통화 코드 목록
    _parsedAllowedCurrencies = [];

    /**
     * @description 파싱된 허용 통화 코드 목록 반환
     * @returns {Array} 허용 통화 코드 배열
     */
    get parsedAllowedCurrencies() {
        return this._parsedAllowedCurrencies;
    }

    /**
     * @description
     * 허용 통화 코드 목록 설정 — JSON 문자열을 파싱하여 _parsedAllowedCurrencies 에 저장 후 전체 셀 재검증
     * @param {string} jsonStr 허용 통화 코드 JSON 문자열
     */
    @api
    setAllowedCurrencies(jsonStr) {
        try {
            this._parsedAllowedCurrencies = JSON.parse(jsonStr || '[]');
        } catch (e) {
            this._parsedAllowedCurrencies = [];
        }
        this.validateAllCells();
    }

    /**
     * @description
     * 단일 셀 유효성 검증 — 필드 타입과 메타데이터 기준으로 검증 수행
     * - 필수값 검증
     * - TSICurrency__c : 허용 통화 코드 포함 여부
     * - 숫자 타입 : 유효한 숫자 형식 및 정수 여부
     * - Picklist / MultiPicklist : 유효한 값 포함 여부
     * - Boolean : Y / YES / TRUE / N / NO / FALSE 허용
     * @param {Object} cell 검증할 셀 객체
     * @returns {string|null} 오류 메시지, 유효하면 null
     */
    validateCell(cell) {

        const metadata = this.fieldMetadata[cell.fieldName];
        const value = cell.value ? cell.value.trim() : '';
        const fieldType = metadata?.type?.toLowerCase();

        // Required
        if (metadata?.required && value === '') {
            return 'Required field';
        }

        if (cell.fieldName === 'TSICurrency__c' && value !== '') {
            const allowed = this.parsedAllowedCurrencies;
            if (allowed.length > 0 && !allowed.includes(value)) {
                return `Currency not allowed. Allowed: ${allowed.join(', ')}`;
            }
        }

        if (value !== '') {

            if (fieldType === 'double' || fieldType === 'integer' || fieldType === 'currency' || fieldType === 'percent') {
                const normalized = value.replace(/,/g, '');
                const numberRegex = /^-?\d+(\.\d+)?$/;

                if (!numberRegex.test(normalized)) {
                    return 'Must be a valid number';
                }

                if (fieldType === 'integer' && normalized.includes('.')) {
                    return 'Must be an integer';
                }
            }

            if ((fieldType === 'picklist' || fieldType === 'multipicklist') && metadata?.picklistValues) {
                const validValues = metadata.picklistValues.map(pv =>
                    pv.value.toLowerCase()
                );

                if (!validValues.includes(value.toLowerCase())) {
                    return `Invalid value. Valid options: ${metadata.picklistValues
                        .map(pv => pv.value)
                        .join(', ')}`;
                }
            }

            if (fieldType === 'boolean') {

                const upperValue = value.toUpperCase();

                const validTrue = ['Y', 'YES', 'TRUE'];
                const validFalse = ['N', 'NO', 'FALSE'];

                if (!validTrue.includes(upperValue) &&
                    !validFalse.includes(upperValue)) {

                    return 'Must be Y or N';
                }
            }
        }

        return null;
    }

    /**
     * @description 전체 셀 유효성 검증 — 모든 행의 셀을 순회하여 오류 상태 업데이트
     */
    async validateAllCells() {
        let foundError = false;

        for (const row of this.rows) {
            for (const cell of row.cells) {
                const error = this.validateCell(cell);
                if (error) {
                    cell.error = error;
                    cell.hasError = true;
                    cell.cellInputClass = 'cell-input error-cell';
                    foundError = true;
                } else {
                    cell.error = '';
                    cell.hasError = false;
                    cell.cellInputClass = 'cell-input';
                }
            }
        }

        this.hasErrors = foundError;
        this.rows = [...this.rows];
    }

    /**
     * @description 취소 버튼 핸들러 — 부모 컴포넌트에 close 이벤트 발행
     */
    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    /**
     * @description
     * 저장 버튼 핸들러 — 전체 셀 유효성 검증 후 TSIByLocation 저장
     * - 오류가 있으면 Toast 표시 후 차단
     * - 행 데이터를 필드 타입에 맞게 변환 후 Apex 저장 호출
     * - 저장 성공 시 savecomplete 이벤트 발행
     * @returns {Promise<void>}
     */
    async handleSave() {
        await this.validateAllCells();
        if (this.hasErrors) {
            this.showToast('Error', 'Please fix all validation errors before saving.', 'error');
            return;
        }

        this.isSaving = true;

        try {
            const tsiList = this.rows.map(row => {
                const tsi = {};
                let street, postal, lat, lng;

                row.cells.forEach(cell => {
                    const metadata = this.fieldMetadata[cell.fieldName];
                    let value = cell.value;
    
                    if (value !== undefined && value !== null && value.trim() !== '') {
                        switch (metadata?.type) {
                            case 'DOUBLE':
                            case 'CURRENCY':
                            case 'INTEGER':
                                tsi[cell.fieldName] = Number(value);
                                break;
                            default:
                                tsi[cell.fieldName] = value;
                        }
                    } else {
                        tsi[cell.fieldName] = null;
                    }

                    if (cell.fieldName === 'Address__Street__s') street = value;
                    if (cell.fieldName === 'Address__PostalCode__s') postal = value;
                    if (cell.fieldName === 'Address__Latitude__s') lat = value;
                    if (cell.fieldName === 'Address__Longitude__s') lng = value;
                });

                if (!street) {
                    if (lat && lng) {
                        tsi.Address__Street__s = `${lat},${lng}`;
                    } else if (postal) {
                        tsi.Address__Street__s = postal;
                    }
                }

                return tsi;
            });
    
            // Google Map 서비스 호출
            const geoPromises = tsiList.map(tsi => {

                let addressParam = null;

                if (tsi.Address__Street__s) {
                    addressParam = tsi.Address__Street__s;
                } else if (tsi.Address__PostalCode__s) {
                    addressParam = tsi.Address__PostalCode__s;
                }

                if (!addressParam) return Promise.resolve();

                return findGeoInfo({
                    geoRequest: JSON.stringify({
                        address: addressParam,
                        mode: 'ADDRESS'
                    })
                }).then(res => {
                    if (res && res.length && res[0].status === 'OK') {
                        const geo = res[0];
                        tsi.GPSCoordinates__Latitude__s = geo.lat;
                        tsi.GPSCoordinates__Longitude__s = geo.lng;
                        tsi.Address__PostalCode__s = geo.postalCode;
                        tsi.Address__City__s = geo.city;
                        tsi.Address__StateCode__s = geo.stateCode;
                        tsi.Address__CountryCode__s = geo.countryCode;
                    }
                });
            });

            const isMatch = await saveTSIByLocation({
                    recordId: this.recordId,
                    slipInfoId: this.slipInfoId,
                    tsiList: tsiList
            });

            this.mismatchError = !isMatch;

    
           // await Promise.all(geoPromises);


            this.showToast('Success', `${tsiList.length} TSI location(s) saved successfully.`, 'success');
            this.dispatchEvent(new CustomEvent('savecomplete'));
    
        } catch (error) {
            console.error('Save error:', error);
            const errorMessage = error?.body?.message || error.message || 'Unknown error';
            this.showToast('Error', 'Failed to save TSI records: ' + errorMessage, 'error');
        } finally {
            this.isSaving = false;
        }
    }

    /**
     * @description 헤더 문자열 정규화 — 연속 공백 제거, 앞뒤 공백 제거, 소문자 변환
     * @param {*} value 정규화할 헤더 문자열
     * @returns {string} 정규화된 헤더 문자열
     */
    normalizeHeader(value) {
        return String(value || "")
            .replace(/\s+/g, " ")
            .trim()
            .toLowerCase();
    }

    /**
     * @description
     * 업로드 템플릿 헤더 유효성 검증
     * - 컬럼 수 불일치 검증
     * - 중복 헤더 검증
     * - 헤더 순서 및 명칭 불일치 검증
     * @returns {boolean} 유효하면 true, 실패 시 headerValidationError 설정 후 false
     */
    validateUploadTemplate() {
        if (!this.excelData || this.excelData.length === 0) {
            return false;
        }

        const headers = this.excelData[0];

        const expectedHeaders = this.fieldOrder.map(apiName =>
            this.columnMapping[apiName].label
        );

        if (headers.length !== expectedHeaders.length) {
            this.headerValidationError =
                `Template column count mismatch. Expected ${expectedHeaders.length} columns but found ${headers.length}. Please download the correct template.`;
            return false;
        }

        // Dup Check
        const headerCounts = new Map();

        headers.forEach((header, index) => {

            const normalized = this.normalizeHeader(header);

            if (!headerCounts.has(normalized)) {
                headerCounts.set(normalized, []);
            }

            headerCounts.get(normalized)
                .push({ original: header, position: index + 1 });
        });

        const duplicateGroups = [];

        headerCounts.forEach((positions) => {
            if (positions.length > 1) {

                const positionStr = positions
                    .map((p) => `Column ${p.position}`)
                    .join(", ");

                duplicateGroups.push(
                    `"${positions[0].original}" appears ${positions.length} times (${positionStr})`
                );
            }
        });

        if (duplicateGroups.length > 0) {
            this.headerValidationError =
                `Duplicate headers found: ${duplicateGroups.join("; ")}. Please download the template and use unique column names.`;
            return false;
        }

        const mismatches = [];

        for (let i = 0; i < headers.length; i++) {

            const uploadedLabel = headers[i];
            const expectedLabel = expectedHeaders[i];

            const uploadedApi = this.labelToApiMap[this.normalizeHeader(uploadedLabel)];
            const expectedApi = this.fieldOrder[i];

            if (!uploadedApi) {
                mismatches.push(
                    `Column ${i + 1}: "${uploadedLabel}" is not a valid template column`
                );
                continue;
            }

            if (uploadedApi !== expectedApi) {
                mismatches.push(
                    `Column ${i + 1}: Expected "${expectedLabel}", but found "${uploadedLabel}"`
                );
            }
        }

        if (mismatches.length > 0) {
            this.headerValidationError =
                `Template headers do not match. ${mismatches.join("; ")}. Please download the correct template.`;
            return false;
        }

        this.headerValidationError = "";
        return true;
    }

    /**
     * @description
     * 엑셀 데이터를 테이블 행 데이터로 변환 — 헤더 유효성 검증 후 각 행을 셀 목록으로 구성
     * - 헤더 검증 실패 시 Toast 표시 후 중단
     * - 각 셀에 유효성 검증 적용 후 오류 상태 설정
     * - 오류가 있는 행은 hasError = true 로 표시
     */
    prepareTableData() {

        if (!this.excelData || this.excelData.length < 2) {
            this.showToast("Warning", "No data rows found in Excel", "warning");
            return;
        }

        const headersValid = this.validateUploadTemplate();

        if (!headersValid) {
            this.showToast("Error", this.headerValidationError, "error");
            return;
        }

        const uploadedHeaders = this.excelData[0];

        const headerApiMap = new Map();

        uploadedHeaders.forEach((header, index) => {
            const apiName = this.labelToApiMap[
                this.normalizeHeader(header)
                ];

            if (apiName) {
                headerApiMap.set(apiName, index);
            }
        });

        // 헤더 정의
        this.headers = this.fieldOrder.map(apiName => ({
            label: this.columnMapping[apiName].label,
            apiName: apiName
        }));

        let hasAnyError = false;

        this.rows = this.excelData.slice(1).map((row, idx) => {

            const rowData = {
                index: idx,
                rowNumber: idx + 1,
                cells: [],
                hasError: false
            };

            this.fieldOrder.forEach(apiName => {

                const columnIndex = headerApiMap.get(apiName);

                let rawValue = "";

                if (columnIndex !== undefined) {
                    rawValue = row[columnIndex];
                }

                const cleanValue =
                    rawValue !== undefined && rawValue !== null
                        ? String(rawValue).trim()
                        : "";

                const cell = {
                    fieldName: apiName,
                    value: cleanValue,
                    displayValue: cleanValue,
                    error: null,
                    hasError: false,
                    cellInputClass: "cell-input"
                };

                const errorMsg = this.validateCell(cell);

                if (errorMsg) {
                    cell.error = errorMsg;
                    cell.hasError = true;
                    cell.cellInputClass = "cell-input error-cell";
                    rowData.hasError = true;
                    hasAnyError = true;
                }

                rowData.cells.push(cell);
            });

            return rowData;
        });
        this.hasValidationErrors = hasAnyError;

        if (hasAnyError) {
            this.showToast(
                "Error",
                "Some rows contain validation errors. Please review.",
                "error"
            );
        }
    }

    /**
     * @description Toast 메시지 표시
     * @param {string} title Toast 제목
     * @param {string} message Toast 메시지
     * @param {string} variant Toast 유형 ('success' | 'error' | 'warning' | 'info')
     */
    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

}