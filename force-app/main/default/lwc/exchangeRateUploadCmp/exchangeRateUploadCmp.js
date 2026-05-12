/**
 * @group        : Trestle
 * @description  :
 * @author       : Yugon Hwang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2026-02-23   Yugon Hwang   Initial Version
 **/
import { LightningElement, track, api } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import Toast from "lightning/toast";
import SheetJs from "@salesforce/resourceUrl/sheetjs";
import uploadExchangeRate from "@salesforce/apex/ExcelFileUploadController.uploadExchangeRate";
import checkDuplicateExchangeRates from "@salesforce/apex/ExcelFileUploadController.checkDuplicateExchangeRates";
import getBizRegion from "@salesforce/apex/Util.getBizRegion";
// Custom Labels
import cancel from "@salesforce/label/c.COM_BTN_CANCEL";
import upload from "@salesforce/label/c.COM_BTN_UPLOAD";
import duplicateCheck from "@salesforce/label/c.COM_DUPLICATE_CHECK";
import excUploadCompleted from "@salesforce/label/c.EXC_UPLOAD_COMPLETED";
import duplicateWithoutUploadAlert from "@salesforce/label/c.COM_DUPLICATE_WITHOUT_UPLOAD_ALERT";
import fileUploadExt from "@salesforce/label/c.EXC_FILE_UPLOAD_EXT";
import processing from "@salesforce/label/c.COM_LBL_PROCESSING";
import preview from "@salesforce/label/c.COM_LBL_PREVIEW";
import removeData from "@salesforce/label/c.COM_BTN_REMOVE_DATA";
import errorsTitle from "@salesforce/label/c.COM_LBL_ERRORS";
import closeBtn from "@salesforce/label/c.COM_BTN_CLOSE";
import resultTotal from "@salesforce/label/c.COM_LBL_TOTAL";
import resultCreated from "@salesforce/label/c.COM_LBL_CREATED";
import resultDuplicates from "@salesforce/label/c.EXC_LBL_DUP_EXCLUDED";
import resultErrors from "@salesforce/label/c.COM_LBL_ERRORS";

const HEADERS = {
    DATE: ["거래일", "거래일시", "일자", "Date"],
    CURRENCY: [
        "입금",
        "출금",
        "거래후잔액",
        "매매기준율",
        "미화환산율",
        "Selling/BuyingRate",
        "WhenSending",
        "WhenReceiving",
        "AtTimeofPurchase",
        "AtTimeofSelling",
        "USDConversionRate"
    ]
};

export default class ExchangeRateUploadCmp extends LightningElement {
    // User Information
    @track bizRegion = "";

    @track errors = [];
    @track previewData = [];
    @track previewColumns = [];

    // Exchange Rate Modal
    @track showExchangeRateConfirmation = false;
    @track duplicateMessage = "";
    @track duplicateRows = [];

    // Upload Result Modal
    @track showResultModal = false;
    @track uploadResultDetails = {};

    XLSX;
    rows = [];
    isLoading = false;
    isUploaded = false;
    sortDirection = "asc";
    sortedBy;

    label = {
        cancel,
        upload,
        duplicateCheck,
        excUploadCompleted,
        duplicateWithoutUploadAlert,
        fileUploadExt,
        processing,
        preview,
        removeData,
        errorsTitle,
        closeBtn,
        resultTotal,
        resultCreated,
        resultDuplicates,
        resultErrors
    };

    errorColumns = [
        { label: "Row", fieldName: "rowNumber", initialWidth: 80 },
        { label: "Column", fieldName: "columnName", initialWidth: 150 },
        { label: "Error", fieldName: "message", wrapText: true }
    ];

    get isDataAvailable() {
        return this.previewData?.length > 0;
    }

    get modalSizeClass() {
        return this.duplicateRows.length > 0
            ? "slds-modal slds-fade-in-open slds-modal_large"
            : "slds-modal slds-fade-in-open";
    }

    get resultModalContentClass() {
        return this.uploadResultDetails?.isSuccess
            ? "slds-modal__content slds-p-around_medium slds-theme_success slds-is-relative"
            : "slds-modal__content slds-p-around_medium slds-theme_error slds-is-relative";
    }

    get resultModalIconName() {
        return this.uploadResultDetails?.isSuccess ? "utility:success" : "utility:error";
    }

    async connectedCallback() {
        if (!this.XLSX) {
            try {
                await loadScript(this, SheetJs);
                this.XLSX = window.XLSX;
            } catch (error) {
                this.showToast("Library Load Error", error.message, "error");
            }
        }
        this.bizRegion = await getBizRegion();
    }

    async handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        this.clearPreview();
        this.isLoading = true;

        try {
            const data = await this.readExcel(file);
            const processedData = this.preprocessData(data);
            this.buildRows(processedData);
        } catch (error) {
            console.error("File Processing Error:", error);
            this.showToast("파일 읽기 실패", error.message, "error");
        } finally {
            this.isLoading = false;
        }
    }

    readExcel(file) {
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                try {
                    const workbook = this.XLSX.read(reader.result, { type: "array", cellDates: true });
                    const sheet = workbook.Sheets[workbook.SheetNames[0]];
                    const data = this.XLSX.utils.sheet_to_json(sheet, { header: 1, raw: true });
                    resolve(data);
                } catch (e) {
                    reject(e);
                }
            };
            reader.onerror = reject;
            reader.readAsArrayBuffer(file);
        });
    }

    preprocessData(data) {
        return [...data];
    }

    buildRows(sheetData) {
        if (!sheetData.length) return;
        const rawHeaders = sheetData[0].map((h) => String(h || "").replace(/\s/g, ""));
        rawHeaders.unshift("No.");

        const headers = rawHeaders;
        this.previewColumns = headers.map((header) => ({
            label: header,
            fieldName: header,
            sortable: true,
            cellAttributes: { alignment: HEADERS.CURRENCY.includes(header) ? "right" : "left" }
        }));

        const apexRows = [];
        const previewRows = [];

        for (let i = 1; i < sheetData.length; i++) {
            const row = sheetData[i];
            if (!row || !row.length) continue;

            row.unshift(i);

            const rowNum = i + 1;
            const recordForApex = { rowNumber: rowNum, values: {} };
            const recordForPreview = { __rowKey: i };

            // Find currency for this row to determine if division by 100 is needed
            const currencyHeaderAliases = ["통화", "Currency"];
            const currencyColIndex = headers.findIndex((h) => currencyHeaderAliases.includes(h));
            const rowCurrency = currencyColIndex !== -1 ? String(row[currencyColIndex] || "") : "";
            const isSpecialCurrency = ["JPY", "VND", "IDR"].includes(rowCurrency);
            const needsDivision = this.bizRegion !== "LK_VN" && isSpecialCurrency;

            const rateHeaders = [
                "매매기준율",
                "Selling/BuyingRate",
                "미화환산율",
                "USDConversionRate",
                "WhenSending",
                "WhenReceiving",
                "AtTimeofPurchase",
                "AtTimeofSelling"
            ];

            headers.forEach((header, colIndex) => {
                let cellValue = row[colIndex];

                if (needsDivision && rateHeaders.includes(header)) {
                    const normalizedValue = typeof cellValue === "string" ? cellValue.replace(/\.{2,}/g, ".") : cellValue;
                    if (typeof normalizedValue === "number") {
                        cellValue = Number((normalizedValue / 100).toFixed(12));
                    } else if (normalizedValue && !isNaN(Number(normalizedValue))) {
                        cellValue = Number((Number(normalizedValue) / 100).toFixed(12));
                    }
                }

                if (HEADERS.DATE.includes(header)) {
                    cellValue = this.formatDate(
                        typeof cellValue === "number" ? this.excelSerialToDate(cellValue) : cellValue
                    );
                } else if (HEADERS.CURRENCY.includes(header)) {
                    cellValue = this.formatCurrency(cellValue);
                }
                recordForApex.values[header] = { value: cellValue, columnName: header, columnIndex: colIndex + 1 };
                recordForPreview[header] = cellValue;
            });
            apexRows.push(recordForApex);
            previewRows.push(recordForPreview);
        }
        this.rows = apexRows;
        this.previewData = previewRows;
    }

    async handleUploadClick() {
        this.isLoading = true;
        this.errors = [];

        try {
            const checkResult = await checkDuplicateExchangeRates({ rows: this.rows });
            if (checkResult.duplicateCount > 0) {
                const duplicateRowNumbers = new Set((checkResult.duplicateRows || []).map((r) => r.rowNumber));
                this.duplicateRows = this.previewData.filter((row) => duplicateRowNumbers.has(row.__rowKey + 1));
                this.duplicateMessage = `${checkResult.duplicateCount}` + this.label.duplicateWithoutUploadAlert;
                this.showExchangeRateConfirmation = true;
                this.isLoading = false;
            } else {
                this.proceedWithUpload(this.rows);
            }
        } catch (error) {
            this.showToast("중복 확인 오류", error.body?.message || error.message, "error");
            this.isLoading = false;
        }
    }

    async proceedWithUpload(rowsToUpload) {
        this.isLoading = true;
        this.showExchangeRateConfirmation = false;

        const action = uploadExchangeRate;
        try {
            const result = await action({ rows: rowsToUpload });
            this.errors = result.errors || [];

            const total = result.totalCount || 0;
            const created = result.createdCount || 0;
            const duplicate = result.duplicateCount || 0;
            const error = result.errorCount || 0;

            const isSuccess = this.errors.length === 0;

            this.uploadResultDetails = {
                title: this.label.excUploadCompleted,
                isSuccess,
                total,
                created,
                duplicate,
                error
            };

            if (isSuccess) {
                this.isUploaded = true;
            }
            this.showResultModal = true;
        } catch (error) {
            this.showToast("서버 오류", error.body?.message || error.message, "error");
        } finally {
            this.isLoading = false;
        }
    }

    // --- Exchange Rate Modal Handlers ---
    handleModalCancel() {
        this.showExchangeRateConfirmation = false;
    }
    handleModalConfirm() {
        // Exchange Rate: always upload without duplicates
        this.proceedWithUpload(this.rows);
    }

    // --- Result Modal Handlers ---
    handleCloseResultModal() {
        this.showResultModal = false;
    }

    // ========== Utilities =============
    excelSerialToDate(serial) {
        const date_info = new Date(Math.round((serial - 25569) * 86400 * 1000));
        const offset = date_info.getTimezoneOffset() * 60 * 1000;
        return new Date(date_info.getTime() + offset);
    }
    formatDate(dateVal) {
        if (!dateVal) return "";
        const d = dateVal instanceof Date ? dateVal : new Date(dateVal);
        if (isNaN(d.getTime())) return dateVal;
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, "0");
        const day = String(d.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`;
    }
    formatCurrency(value) {
        if (!value && value !== 0) return "";
        const num = Number(value);
        return isNaN(num) ? value : num.toLocaleString("ko-KR", { maximumFractionDigits: 10 });
    }
    showToast(label, message, variant) {
        Toast.show({ label, message, variant }, this);
    }
    clearPreview() {
        this.previewData = [];
        this.previewColumns = [];
        this.rows = [];
        this.errors = [];
        this.isUploaded = false;
    }
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.previewData];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === "asc" ? 1 : -1));
        this.previewData = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }
    sortBy(field, reverse) {
        return (a, b) => {
            const aVal = a[field] || "";
            const bVal = b[field] || "";
            return reverse * ((aVal > bVal) - (bVal > aVal));
        };
    }
}