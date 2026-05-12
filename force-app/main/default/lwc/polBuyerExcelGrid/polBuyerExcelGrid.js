/**********************************************************************************
 * @filename      : polBuyerExcelGrid.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-04-22 (수)
 * @group         :
 * @group-content :
 * @description   : POL Buyer Excel Grid LWC 컴포넌트
 *                  - 업로드된 Excel 데이터를 Grid 형태로 렌더링하고,
 *                  - Buyer 필드 메타데이터 기반으로 헤더/셀 유효성을 검증하며,
 *                  - Template 다운로드, Export, Error Cell 포커스, 저장 처리까지 담당한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-04-22       i2max             Create
 **********************************************************************************/

// LWC
import { LightningElement, api, track, wire } from "lwc";

// Common Utils
import { toast } from "c/com";

// Platform Resource
import { loadScript } from "lightning/platformResourceLoader";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

// Schema
import POL_BUYER_OBJECT from "@salesforce/schema/POL_Buyer__c";

// Apex Methods
import savePOLBuyers from "@salesforce/apex/POL_BuyerUpload_Ctrl.savePOLBuyers";
import getBuyerFieldMetadata from "@salesforce/apex/POL_BuyerUpload_Ctrl.getBuyerFieldMetadata";

// Static Resources
import sheetjs from "@salesforce/resourceUrl/sheetjs";

// Custom Labels
import COM_BTN_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import COM_BTN_CANCEL from "@salesforce/label/c.COM_BTN_CANCEL";

// Constants
const ROW_HEIGHT = 36;
const BUFFER_ROWS = 10;

export default class PolBuyerExcelGrid extends LightningElement {
    // Public Properties
    @api recordId;
    @api excelData;
    @api fileName;

    // Reactive Properties
    @track isSaving = false;
    @track isLoading = false;
    @track headers = [];
    @track rows = [];
    @track hasErrors = false;
    @track startIndex = 0;
    @track endIndex = 0;
    @track headerValidationError = "";

    // Private Properties
    viewportRows = 0;
    fieldMetadata = {};
    columnMapping = {};
    sheetJsLoaded = false;
    _scrollEl;
    _resizeBound = false;
    objectInfoLoaded = false;
    _allValidated = false;

    labels = {
        save: COM_BTN_SAVE,
        cancel: COM_BTN_CANCEL
    };

    // Getter / Setter
    get disableSave() {
        return this.isSaving || this.hasErrors || this.rows.length === 0 || this.headerValidationError ? true : false;
    }

    get totalRows() {
        return this.rows.length;
    }

    get visibleRows() {
        return this.rows.slice(this.startIndex, this.endIndex);
    }

    get columnSpan() {
        const count = Array.isArray(this.headers) ? this.headers.length : 0;
        return Math.max(1, count + 1);
    }

    get topSpacerStyle() {
        return `height:${this.startIndex * ROW_HEIGHT}px`;
    }

    get bottomSpacerStyle() {
        const remaining = Math.max(this.totalRows - this.endIndex, 0);
        return `height:${remaining * ROW_HEIGHT}px`;
    }

    // Wire Methods
    @wire(getObjectInfo, { objectApiName: POL_BUYER_OBJECT })
    wiredObjectInfo({ error, data }) {
        if (data) {
            this.objectInfoLoaded = true;
            this.processObjectInfo(data);
        } else if (error) {
            console.error("Error loading object info:", error);
        }
    }

    // Event Handlers
    handleResize = () => {
        this.computeViewportRows();
        this.updateWindow();
    };

    /**
     * @description 스크롤 이벤트 발생 시 현재 보이는 영역 기준으로 가상 윈도우를 갱신한다.
     * @return {void}
     */
    handleScroll() {
        this.updateWindow();
    }

    /**
     * @description 현재 Buyer 컬럼 기준으로 빈 Excel Template 파일을 생성하여 다운로드한다.
     * @return {void}
     */
    handleDownloadTemplate() {
        if (!this.sheetJsLoaded) {
            toast("Error", "SheetJS library not loaded", "error");
            return;
        }

        if (Object.keys(this.columnMapping).length === 0) {
            toast("Warning", "Template not ready. Please wait...", "warning");
            return;
        }

        try {
            const headers = Object.keys(this.columnMapping).map((fieldName) => this.columnMapping[fieldName].label);

            const wb = XLSX.utils.book_new();
            const ws = XLSX.utils.aoa_to_sheet([headers]);

            ws["!cols"] = headers.map(() => ({ wch: 20 }));

            XLSX.utils.book_append_sheet(wb, ws, "Buyers Template");

            const timestamp = new Date().toISOString().slice(0, 10);
            XLSX.writeFile(wb, `POL_Buyers_Template_${timestamp}.xlsx`);

            toast("Success", "Template downloaded successfully", "success");
        } catch (error) {
            toast("Error", "Failed to download template: " + error.message, "error");
        }
    }

    /**
     * @description 현재 Grid 데이터를 Excel 파일로 내보낸다.
     * @return {void}
     */
    handleExport() {
        if (!this.sheetJsLoaded) {
            toast("Error", "SheetJS library not loaded", "error");
            return;
        }

        if (this.rows.length === 0) {
            toast("Warning", "No data to export", "warning");
            return;
        }

        try {
            const headers = this.headers.map((h) => h.label);
            const dataRows = this.rows.map((row) => {
                return row.cells.map((cell) => cell.displayValue || "");
            });

            const wsData = [headers, ...dataRows];
            const wb = XLSX.utils.book_new();
            const ws = XLSX.utils.aoa_to_sheet(wsData);

            ws["!cols"] = headers.map(() => ({ wch: 20 }));

            XLSX.utils.book_append_sheet(wb, ws, "Buyers");

            const timestamp = new Date().toISOString().slice(0, 10);
            XLSX.writeFile(wb, `POL_Buyers_${timestamp}.xlsx`);

            toast("Success", "Data exported successfully", "success");
        } catch (error) {
            toast("Error", "Failed to export data: " + error.message, "error");
        }
    }

    /**
     * @description 첫 번째 에러 셀을 찾아 스크롤 이동 후 포커스를 설정한다.
     * @return {void}
     */
    handleFocusErrorCell() {
        if (!this._scrollEl) {
            return;
        }

        if (!this._allValidated) {
            this.isLoading = true;
            this.validateAllCells();
            this.isLoading = false;
        }

        if (!this.hasErrors) {
            toast("Info", "No error cells found", "info");
            return;
        }

        let errorRowIndex = -1;
        let errorCellIndex = -1;

        for (let i = this.startIndex; i < this.endIndex && i < this.rows.length; i++) {
            const row = this.rows[i];
            const errorCellIdx = row.cells.findIndex((c) => c.hasError);
            if (errorCellIdx !== -1) {
                errorRowIndex = i;
                errorCellIndex = errorCellIdx;
                break;
            }
        }

        if (errorRowIndex === -1) {
            for (let i = 0; i < this.rows.length; i++) {
                const row = this.rows[i];
                const errorCellIdx = row.cells.findIndex((c) => c.hasError);
                if (errorCellIdx !== -1) {
                    errorRowIndex = i;
                    errorCellIndex = errorCellIdx;
                    break;
                }
            }
        }

        if (errorRowIndex === -1) {
            toast("Info", "No error cells found", "info");
            return;
        }

        const scrollPosition = errorRowIndex * ROW_HEIGHT;
        this._scrollEl.scrollTop = scrollPosition;

        this.updateWindow();

        this.focusErrorCellWithRetry(errorRowIndex, errorCellIndex, 0);
    }

    /**
     * @description 특정 에러 셀 input 요소가 렌더링될 때까지 재시도하며 포커스를 이동한다.
     * @param {Number} errorRowIndex 에러가 발생한 row index
     * @param {Number} errorCellIndex 에러가 발생한 cell index
     * @param {Number} retryCount 현재 재시도 횟수
     * @return {void}
     */
    focusErrorCellWithRetry(errorRowIndex, errorCellIndex, retryCount) {
        const maxRetries = 10;
        const retryDelay = 50;

        const errorRow = this.rows[errorRowIndex];
        const errorCell = errorRow.cells[errorCellIndex];
        const inputSelector = `input[data-row="${errorRowIndex}"][data-field-name="${errorCell.fieldName}"]`;
        const inputElement = this.template.querySelector(inputSelector);

        if (inputElement) {
            inputElement.focus();
            inputElement.select();
        } else if (retryCount < maxRetries) {
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            setTimeout(() => {
                this.focusErrorCellWithRetry(errorRowIndex, errorCellIndex, retryCount + 1);
            }, retryDelay);
        } else {
            toast("Warning", `Could not focus on error cell in row ${errorRowIndex + 1}. Please scroll to it manually.`, "warning");
        }
    }

    /**
     * @description 셀 값 변경 시 해당 셀을 재검증하고 에러 상태를 갱신한다.
     * @param {Event} event input change 이벤트
     * @return {void}
     */
    handleCellChange(event) {
        const rowIndex = parseInt(event.target.dataset.row, 10);
        const fieldName = event.target.dataset.fieldName;
        const newValue = event.target.value;

        const row = this.rows[rowIndex];
        if (!row) return;

        const cell = row.cells.find((c) => c.fieldName === fieldName);
        if (!cell) return;

        cell.value = newValue;
        cell.displayValue = newValue;

        const error = this.validateCell(cell);
        if (error) {
            cell.error = error;
            cell.hasError = true;
            cell.cellInputClass = "cell-input error-cell";
        } else {
            cell.error = "";
            cell.hasError = false;
            cell.cellInputClass = "cell-input";
        }

        this._allValidated = false;

        this.hasErrors = this.rows.some((r) => r.cells.some((c) => c.hasError));
        this.rows = [...this.rows];
    }

    /**
     * @description 전체 데이터를 검증한 뒤 Buyer 레코드를 Apex로 저장한다.
     * @return {Promise<void>}
     */
    async handleSave() {
        if (!this._allValidated) {
            this.isLoading = true;
            const isValid = this.validateAllCells();
            this.isLoading = false;

            if (!isValid) {
                toast("Error", "Please fix all validation errors before saving", "error");
                return;
            }
        }

        if (this.hasErrors) {
            toast("Error", "Please fix all validation errors before saving", "error");
            return;
        }

        this.isSaving = true;

        try {
            const buyersToSave = this.rows.map((row) => {
                const buyer = {
                    Policy_lk__c: this.recordId
                };

                row.cells.forEach((cell) => {
                    const metadata = this.fieldMetadata[cell.fieldName];
                    let value = cell.value;

                    if (value && value.trim() !== "") {
                        if (metadata && metadata.type === "DOUBLE") {
                            buyer[cell.fieldName] = parseFloat(value);
                        } else if (metadata && metadata.type === "DATE") {
                            buyer[cell.fieldName] = value;
                        } else {
                            buyer[cell.fieldName] = value;
                        }
                    } else {
                        buyer[cell.fieldName] = null;
                    }
                });

                return buyer;
            });

            const result = await savePOLBuyers({ buyers: buyersToSave });

            toast("Success", result, "success");
            this.dispatchEvent(new CustomEvent("savecomplete"));
        } catch (error) {
            console.error("Save error:", error);
            const errorMessage = error.body?.message || error.message || "Unknown error";
            toast("Error", "Failed to save buyers: " + errorMessage, "error");
        } finally {
            this.isSaving = false;
        }
    }

    /**
     * @description Grid 팝업을 닫기 위한 close 이벤트를 부모로 전달한다.
     * @return {void}
     */
    handleCancel() {
        this.dispatchEvent(new CustomEvent("close"));
    }

    // Private Methods

    /**
     * @description Object Info 로드 완료 후 후속 확장 처리를 위해 로그를 남긴다.
     * @param {Object} objectInfo POL_Buyer__c Object Info 데이터
     * @return {void}
     */
    processObjectInfo(objectInfo) {
        console.log("Object Info loaded:", objectInfo.apiName);
    }

    /**
     * @description SheetJS 정적 리소스를 로드한다.
     * @return {Promise<void>}
     */
    async loadSheetJS() {
        if (this.sheetJsLoaded) return;

        try {
            await loadScript(this, sheetjs);
            this.sheetJsLoaded = true;
        } catch (error) {
            toast("Error", "Failed to load SheetJS library", "error");
        }
    }

    /**
     * @description Buyer 필드 메타데이터를 조회하고 컬럼 매핑 정보를 생성한다.
     * @return {Promise<void>}
     */
    async loadMetadata() {
        try {
            const metadata = await getBuyerFieldMetadata();
            this.fieldMetadata = metadata || {};
            this.buildColumnMapping();
        } catch (error) {
            console.error("Error loading metadata:", error);
            toast("Error", "Failed to load field metadata", "error");
        }
    }

    /**
     * @description Buyer Excel 템플릿 컬럼 순서 기준으로 필드 매핑 정보를 생성한다.
     * @return {void}
     */
    buildColumnMapping() {
        const fieldOrder = [
            "CompanyName__c",
            "InternatinoalBizName__c",
            "EasyNo__c",
            "Address__c",
            "Town__c",
            "Postcode__c",
            "StateCountry__c",
            "CountryName__c",
            "CountryCode__c",
            "Phone__c",
            "BuyerNo__c",
            "LeagalIdentType1__c",
            "LegalIdentValue1__c",
            "LeagalIdentType2__c",
            "LegalIdentValue2__c",
            "LeagalIdentType3__c",
            "LegalIdentValue3__c",
            "Product__c",
            "UserId__c",
            "ContractNo__c",
            "ContractType__c",
            "PolicyHolder__c",
            "RatingNotation__c",
            "RequestDate__c",
            "CustDebtorRef__c",
            "AmountAsked__c",
            "CurrencyAmtAsked__c",
            "MinShipAmt__c",
            "MinShpCurr__c",
            "ModeOfPay__c",
            "DecisionDate__c",
            "DecisionStatus__c",
            "DecisionType__c",
            "Decision1__c",
            "Decision2__c",
            "Decision3__c",
            "EffectDate__c",
            "EndDate__c",
            "AmtAgreed__c",
            "CurrAmtAgreed__c",
            "GrntReq1__c",
            "GrntReq2__c",
            "GrntReq3__c",
            "GrntProvied1__c",
            "GrntProvied2__c",
            "GrntProvied3__c",
            "DecisionComment__c",
            "InsuredPct__c",
            "DRA__c",
            "NA__c",
            "OperationLabel__c",
            "OperationNo__c",
            "FavoriteCompany__c",
            "CustRef__c",
            "OutstandingAmt__c",
            "InternalCreditLimit__c"
        ];

        this.columnMapping = {};
        fieldOrder.forEach((fieldName, index) => {
            const metadata = this.fieldMetadata[fieldName];

            this.columnMapping[fieldName] = {
                index: index,
                required: metadata?.required || false,
                type: metadata ? this.mapFieldType(metadata.type) : "text",
                label: metadata?.label || fieldName,
                length: metadata?.length,
                precision: metadata?.precision,
                scale: metadata?.scale
            };
        });

        console.log("Column Mapping:", JSON.stringify(this.columnMapping));
        console.log("Total columns:", Object.keys(this.columnMapping).length);
    }

    /**
     * @description Salesforce 필드 타입을 Grid 입력용 타입으로 변환한다.
     * @param {String} salesforceType Salesforce field type
     * @return {String} Grid input type
     */
    mapFieldType(salesforceType) {
        const typeMap = {
            STRING: "text",
            TEXTAREA: "text",
            DOUBLE: "number",
            INTEGER: "number",
            CURRENCY: "number",
            DATE: "date",
            DATETIME: "datetime",
            PICKLIST: "picklist",
            MULTIPICKLIST: "picklist"
        };

        return typeMap[salesforceType] || "text";
    }

    /**
     * @description 업로드된 Excel 헤더를 기대 헤더와 비교하여 유효성을 검증한다.
     *              헤더 개수, 중복 여부, 순서 및 이름 일치 여부를 확인한다.
     * @return {Boolean} 헤더 검증 성공 여부
     */
    validateHeaders() {
        if (!this.excelData || this.excelData.length === 0) {
            this.headerValidationError = "Excel data is empty";
            return false;
        }

        const uploadedHeaders = this.excelData[0];
        const expectedHeaders = Object.keys(this.columnMapping).map((fieldName) => this.columnMapping[fieldName].label);

        console.log("=== Header Validation Debug ===");
        console.log("Uploaded Headers:", uploadedHeaders);
        console.log("Expected Headers:", expectedHeaders);
        console.log("Column Mapping:", this.columnMapping);

        if (uploadedHeaders.length !== expectedHeaders.length) {
            this.headerValidationError = `Header count mismatch. Expected ${expectedHeaders.length} columns, but found ${uploadedHeaders.length}`;
            return false;
        }

        const headerCounts = new Map();
        uploadedHeaders.forEach((header, index) => {
            const normalizedHeader = String(header || "")
                .trim()
                .toLowerCase();

            if (!headerCounts.has(normalizedHeader)) {
                headerCounts.set(normalizedHeader, []);
            }

            headerCounts.get(normalizedHeader).push({ original: header, position: index + 1 });
        });

        console.log("Header Counts:", Array.from(headerCounts.entries()));

        const duplicateGroups = [];
        headerCounts.forEach((positions) => {
            if (positions.length > 1) {
                const positionStr = positions.map((p) => `Column ${p.position}`).join(", ");
                duplicateGroups.push(`"${positions[0].original}" appears ${positions.length} times (${positionStr})`);
            }
        });

        if (duplicateGroups.length > 0) {
            this.headerValidationError = `Duplicate headers found: ${duplicateGroups.join("; ")}. Please download the template and use unique column names.`;
            return false;
        }

        const mismatches = [];
        for (let i = 0; i < uploadedHeaders.length; i++) {
            const uploadedHeader = String(uploadedHeaders[i] || "").trim();
            const expectedHeader = expectedHeaders[i];

            if (uploadedHeader.toLowerCase() !== expectedHeader.toLowerCase()) {
                mismatches.push(`Column ${i + 1}: Expected "${expectedHeader}", but found "${uploadedHeader}"`);
            }
        }

        if (mismatches.length > 0) {
            this.headerValidationError = `Template headers do not match. ${mismatches.join("; ")}. Please download the correct template.`;
            return false;
        }

        this.headerValidationError = "";
        return true;
    }

    /**
     * @description Excel 데이터와 컬럼 매핑을 기준으로 Grid 헤더와 행 데이터를 구성한다.
     * @return {void}
     */
    prepareTableData() {
        if (!this.excelData || this.excelData.length < 2) {
            toast("Warning", "No data rows found in Excel", "warning");
            return;
        }

        const headersValid = this.validateHeaders();
        if (!headersValid) {
            toast("Error", this.headerValidationError, "error");
        }

        this.headers = Object.keys(this.columnMapping).map((fieldName) => ({
            label: this.columnMapping[fieldName].label,
            apiName: fieldName
        }));

        const fieldNames = Object.keys(this.columnMapping);
        this.rows = this.excelData.slice(1).map((row, idx) => {
            const rowData = {
                index: idx,
                rowNumber: idx + 1,
                cells: []
            };

            fieldNames.forEach((fieldName) => {
                const colConfig = this.columnMapping[fieldName];
                const rawValue = row[colConfig.index];
                const cell = {
                    fieldName: fieldName,
                    value: rawValue !== undefined && rawValue !== null ? String(rawValue).trim() : "",
                    displayValue: rawValue !== undefined && rawValue !== null ? String(rawValue).trim() : "",
                    error: "",
                    hasError: false,
                    cellInputClass: "cell-input"
                };
                rowData.cells.push(cell);
            });

            return rowData;
        });
    }

    /**
     * @description 가상 스크롤 초기 표시 범위를 계산하여 설정한다.
     * @return {void}
     */
    initVirtualWindow() {
        this.computeViewportRows();
        this.startIndex = 0;
        this.endIndex = Math.min(this.viewportRows + BUFFER_ROWS, this.totalRows);
    }

    /**
     * @description 스크롤 컨테이너 높이를 기준으로 viewport row 수를 계산한다.
     * @return {void}
     */
    computeViewportRows() {
        if (!this._scrollEl) return;

        const containerHeight = this._scrollEl.clientHeight || 400;
        this.viewportRows = Math.ceil(containerHeight / ROW_HEIGHT);
    }

    /**
     * @description 현재 스크롤 위치 기준으로 보여줄 row 범위를 갱신한다.
     * @return {void}
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

            if (!this._allValidated) {
                this.validateVisibleCells();
            }
        }
    }

    /**
     * @description 현재 화면에 보이는 row 범위만 검증하여 에러 상태를 갱신한다.
     * @return {void}
     */
    validateVisibleCells() {
        let foundError = false;

        const visibleRows = this.rows.slice(this.startIndex, this.endIndex);

        for (const row of visibleRows) {
            for (const cell of row.cells) {
                const error = this.validateCell(cell);
                if (error) {
                    cell.error = error;
                    cell.hasError = true;
                    cell.cellInputClass = "cell-input error-cell";
                    foundError = true;
                } else {
                    cell.error = "";
                    cell.hasError = false;
                    cell.cellInputClass = "cell-input";
                }
            }
        }

        this.hasErrors = this.rows.some((r) => r.cells.some((c) => c.hasError)) || foundError;
        this.rows = [...this.rows];
    }

    /**
     * @description 전체 row / cell 을 모두 검증하여 에러 상태를 갱신한다.
     * @return {Boolean} 전체 검증 통과 여부
     */
    validateAllCells() {
        let foundError = false;

        for (const row of this.rows) {
            for (const cell of row.cells) {
                const error = this.validateCell(cell);
                if (error) {
                    cell.error = error;
                    cell.hasError = true;
                    cell.cellInputClass = "cell-input error-cell";
                    foundError = true;
                } else {
                    cell.error = "";
                    cell.hasError = false;
                    cell.cellInputClass = "cell-input";
                }
            }
        }

        this.hasErrors = foundError;
        this._allValidated = true;
        this.rows = [...this.rows];
        return !foundError;
    }

    /**
     * @description 단일 셀 값을 컬럼 메타데이터 기준으로 검증하고 에러 메시지를 반환한다.
     * @param {Object} cell 검증 대상 셀 데이터
     * @return {String|null} 에러 메시지 또는 null
     */
    validateCell(cell) {
        const colConfig = this.columnMapping[cell.fieldName];
        const metadata = this.fieldMetadata[cell.fieldName];
        const value = cell.value;

        if (colConfig && colConfig.required && (!value || value.trim() === "")) {
            return "Required field";
        }

        if (value && value.trim() !== "") {
            if (colConfig && colConfig.type === "number") {
                const num = parseFloat(value);
                if (isNaN(num)) {
                    return "Must be a number";
                }

                if (colConfig.precision && colConfig.scale !== undefined) {
                    const valueStr = String(value);
                    const parts = valueStr.split(".");
                    const integerPart = parts[0].replace(/^-/, "");
                    const decimalPart = parts[1] || "";

                    const maxIntegerDigits = colConfig.precision - colConfig.scale;
                    if (integerPart.length > maxIntegerDigits) {
                        return `Integer part exceeds maximum ${maxIntegerDigits} digits`;
                    }

                    if (decimalPart.length > colConfig.scale) {
                        return `Decimal part exceeds maximum ${colConfig.scale} digits`;
                    }
                }
            }

            if (colConfig && colConfig.type === "text" && colConfig.length) {
                if (value.length > colConfig.length) {
                    return `Exceeds maximum length of ${colConfig.length} characters`;
                }
            }

            if (colConfig && colConfig.type === "date") {
                const dateRegex = /^\d{4}-\d{2}-\d{2}$/;
                if (!dateRegex.test(value)) {
                    return "Invalid date format. Use YYYY-MM-DD";
                }

                const date = new Date(value);
                if (isNaN(date.getTime())) {
                    return "Invalid date value";
                }

                const [year, month, day] = value.split("-").map(Number);
                if (date.getFullYear() !== year || date.getMonth() !== month - 1 || date.getDate() !== day) {
                    return "Invalid date (e.g., Feb 30 does not exist)";
                }
            }

            if (colConfig && colConfig.type === "datetime") {
                const datetimeRegex = /^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(\.\d{3})?Z?$/;
                if (!datetimeRegex.test(value)) {
                    return "Invalid datetime format. Use YYYY-MM-DD HH:MM:SS or ISO format";
                }

                const datetime = new Date(value);
                if (isNaN(datetime.getTime())) {
                    return "Invalid datetime value";
                }
            }

            if (colConfig && colConfig.type === "picklist" && metadata && metadata.picklistValues) {
                const picklistValues = metadata.picklistValues || [];
                const validValues = picklistValues.map((pv) => pv.value.toLowerCase());
                if (!validValues.includes(value.toLowerCase())) {
                    return `Invalid value. Valid options: ${picklistValues.map((pv) => pv.value).join(", ")}`;
                }
            }
        }

        return null;
    }

    // Lifecycle Methods

    /**
     * @description 컴포넌트 초기화 시 SheetJS와 Buyer 메타데이터를 로드하고 Grid 데이터를 준비한다.
     * @return {Promise<void>}
     */
    async connectedCallback() {
        if (this.excelData && this.excelData.length > 0) {
            this.isLoading = true;

            await this.loadSheetJS();
            await this.loadMetadata();

            if (Object.keys(this.columnMapping).length > 0) {
                this.prepareTableData();
                this.initVirtualWindow();
                this.validateVisibleCells();
            }

            this.isLoading = false;
        }
    }

    /**
     * @description 최초 렌더링 이후 스크롤 컨테이너와 resize 이벤트를 초기화한다.
     * @return {void}
     */
    renderedCallback() {
        if (!this._scrollEl) {
            this._scrollEl = this.template.querySelector(".table-container");
            if (this._scrollEl) {
                this.computeViewportRows();
                this.updateWindow();
            }
        }

        if (!this._resizeBound) {
            this._resizeBound = true;
            window.addEventListener("resize", this.handleResize);
        }
    }

    /**
     * @description 컴포넌트 제거 시 resize 이벤트를 정리한다.
     * @return {void}
     */
    disconnectedCallback() {
        if (this._resizeBound) {
            window.removeEventListener("resize", this.handleResize);
            this._resizeBound = false;
        }
    }
}