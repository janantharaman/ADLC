/**
 * @group        : Trestle
 * @description  : Bank Transaction Excel Uploader
 * @author       : Yugon Hwang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.1   01-22-2026   Yugon Hwang   Refactored for maintainability and readability
 * 1.2   01-29-2026   Yugon Hwang   Added complex duplicate handling for Bank Transactions
 **/
import { LightningElement, track } from "lwc";
import { loadScript } from "lightning/platformResourceLoader";
import Toast from "lightning/toast";
import SheetJs from "@salesforce/resourceUrl/sheetjs";
import uploadBankTransaction from "@salesforce/apex/ExcelFileUploadController.uploadBankTransaction";
import checkDuplicateBankTransactions from "@salesforce/apex/ExcelFileUploadController.checkDuplicateBankTransactions";
import getDefaultBankAccountId from "@salesforce/apex/ExcelFileUploadController.getDefaultBankAccountId";

// Custom Labels
import fileUploadExt from "@salesforce/label/c.EXC_FILE_UPLOAD_EXT";
import processing from "@salesforce/label/c.COM_LBL_PROCESSING";
import preview from "@salesforce/label/c.COM_LBL_PREVIEW";
import removeData from "@salesforce/label/c.COM_BTN_REMOVE_DATA";
import upload from "@salesforce/label/c.COM_BTN_UPLOAD";
import errorsTitle from "@salesforce/label/c.COM_LBL_ERRORS";
import bankDupSuspect from "@salesforce/label/c.BNK_LBL_DUP_SUSPECT";
import bankAccountSelect from "@salesforce/label/c.BNK_LBL_ACCOUNT_SELECT";
import cancel from "@salesforce/label/c.COM_BTN_CANCEL";
import save from "@salesforce/label/c.COM_BTN_SAVE";
import duplicateCheck from "@salesforce/label/c.COM_DUPLICATE_CHECK";
import bankDupAskMsg from "@salesforce/label/c.BNK_MSG_DUP_ASK";
import btnShowDupData from "@salesforce/label/c.BNK_BTN_SHOW_DUP_DATA";
import btnExcDupUpload from "@salesforce/label/c.BNK_BTN_EXC_DUP_UPLOAD";
import btnUploadAll from "@salesforce/label/c.BNK_BTN_UPLOAD_ALL";
import libLoadError from "@salesforce/label/c.COM_LBL_LIBRARY_LOAD_ERROR";
import fileReadFailed from "@salesforce/label/c.COM_MSG_FILE_READ_FAILED";
import dupCheckError from "@salesforce/label/c.COM_MSG_DUP_CHECK_ERROR";
import saveFailed from "@salesforce/label/c.COM_LBL_SAVE_FAILED";
import saveFailedWithCount from "@salesforce/label/c.COM_MSG_SAVE_FAILED_WITH_COUNT";
import infoLabel from "@salesforce/label/c.COM_LBL_INFO";
import successLabel from "@salesforce/label/c.COM_LBL_SUCCESS";
import serverError from "@salesforce/label/c.COM_LBL_SERVER_ERROR";
import rowLabel from "@salesforce/label/c.COM_LBL_ROW";
import colLabel from "@salesforce/label/c.COM_LBL_COLUMN";
import errorLabel from "@salesforce/label/c.COM_LBL_ERROR";
import saveSuccess from "@salesforce/label/c.COM_MSG_SAVE_SUCCESS";

const HEADERS = {
    DATETIME: ["거래일시", "TransactionDate&Type", "TransactionDate"],
    CURRENCY: ["입금", "출금", "거래후잔액", "DepositAmount", "WithdrawalAmount", "Balance"]
};
const HEADER_ROW_OFFSET = 1;

export default class BankTransactionUploadCmp extends LightningElement {
    @track errors = [];
    @track previewData = [];
    @track previewColumns = [];

    // Bank Account Selection Modal
    @track showBankAccountModal = false;
    selectedBankAccountId = null;

    // Bank Transaction Duplicate Modal & Data
    @track showBankTransactionConfirmation = false;
    @track identifiedBankDuplicates = [];
    @track duplicateBankRowsForDisplay = [];

    XLSX;
    rows = [];
    isLoading = false;
    isUploaded = false;
    sortDirection = "asc";
    sortedBy;

    label = {
        fileUploadExt,
        processing,
        preview,
        removeData,
        upload,
        errorsTitle,
        bankDupSuspect,
        bankAccountSelect,
        cancel,
        save,
        duplicateCheck,
        bankDupAskMsg,
        btnShowDupData,
        btnExcDupUpload,
        btnUploadAll,
        libLoadError,
        fileReadFailed,
        dupCheckError,
        saveFailed,
        saveFailedWithCount,
        infoLabel,
        successLabel,
        serverError,
        rowLabel,
        colLabel,
        errorLabel,
        saveSuccess
    };

    errorColumns = [
        { label: rowLabel, fieldName: "rowNumber", initialWidth: 80 },
        { label: colLabel, fieldName: "columnName", initialWidth: 150 },
        { label: errorLabel, fieldName: "message", wrapText: true }
    ];

    get isDataAvailable() {
        return this.previewData?.length > 0;
    }

    get isSaveDisabled() {
        return !this.selectedBankAccountId;
    }

    get bankDuplicateCount() {
        return this.identifiedBankDuplicates.length;
    }

    get duplicateAskMessageString() {
        return this.label.bankDupAskMsg ? this.label.bankDupAskMsg.replace("{0}", this.bankDuplicateCount) : "";
    }
    /********************************************************
     * Life Cycle Hooks
     ********************************************************/

    async connectedCallback() {
        if (!this.XLSX) {
            try {
                await loadScript(this, SheetJs);
                this.XLSX = window.XLSX;
            } catch (error) {
                this.showToast(this.label.libLoadError, error.message, "error");
            }
        }
        this.getDefaultBankAccountId();
    }

    /********************************************************
     * Event Handlers
     ********************************************************/
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
            this.showToast(this.label.fileReadFailed, error.message, "error");
        } finally {
            this.isLoading = false;
        }
    }

    handleUploadClick() {
        this.errors = [];
        this.duplicateBankRowsForDisplay = [];
        this.showBankAccountModal = true;
    }

    // --- Bank Account Modal Handlers ---
    handleBankAccountChange(event) {
        this.selectedBankAccountId = event.detail.value[0] || null;
    }

    handleBankAccountCancel() {
        this.showBankAccountModal = false;
    }

    async handleBankAccountSave() {
        this.showBankAccountModal = false;
        this.isLoading = true;

        try {
            const checkResult = await checkDuplicateBankTransactions({
                rows: this.rows,
                bankAccountId: this.selectedBankAccountId
            });
            this.identifiedBankDuplicates = checkResult.duplicateExcelRows || [];

            if (this.bankDuplicateCount > 0) {
                this.showBankTransactionConfirmation = true;
                this.isLoading = false;
            } else {
                this.proceedWithUpload(this.rows);
            }
        } catch (error) {
            this.showToast(this.label.dupCheckError, error.body?.message || error.message, "error");
            this.isLoading = false;
        }
    }

    handleModalCancel() {
        this.showBankTransactionConfirmation = false;
    }

    handleUploadWithDuplicates() {
        this.proceedWithUpload(this.rows);
    }

    handleUploadWithoutDuplicates() {
        const duplicateRowNumbers = new Set(this.identifiedBankDuplicates.map((r) => r.rowNumber));
        const newRows = this.rows.filter((r) => !duplicateRowNumbers.has(r.rowNumber));
        this.proceedWithUpload(newRows);
    }

    handleShowDuplicates() {
        this.showBankTransactionConfirmation = false;
        const duplicateRowNumbers = new Set(this.identifiedBankDuplicates.map((r) => r.rowNumber));

        this.duplicateBankRowsForDisplay = this.previewData.filter((pr) =>
            duplicateRowNumbers.has(pr.__rowKey + HEADER_ROW_OFFSET)
        );
        // Add scrolling logic
        // Use a small delay to ensure the DOM is updated before attempting to scroll
        setTimeout(() => {
            const targetElement = this.template.querySelector('[data-id="duplicateBankTable"]');
            if (targetElement) {
                targetElement.scrollIntoView({ behavior: "smooth", block: "start" });
            }
        }, 100);
    }

    /********************************************************
     * Private Methods
     ********************************************************/
    getDefaultBankAccountId() {
        getDefaultBankAccountId().then((accountId) => {
            this.selectedBankAccountId = accountId;
        });
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
        let result = [...data];
        return result;
    }

    buildRows(sheetData) {
        if (!sheetData.length) return;
        const headers = sheetData[0].map((h) => String(h || "").replace(/\s/g, ""));

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
            if (
                row.some((cell) =>
                    String(cell || "")
                        .replace(/\s/g, "")
                        .includes("합계")
                )
            )
                continue;

            const rowNum = i + HEADER_ROW_OFFSET;
            const recordForApex = { rowNumber: rowNum, values: {} };
            const recordForPreview = { __rowKey: i };

            headers.forEach((header, colIndex) => {
                let cellValue = row[colIndex];
                if (HEADERS.DATETIME.includes(header)) {
                    cellValue = this.formatDateTime(
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

    async proceedWithUpload(rowsToUpload) {
        this.isLoading = true;
        this.showBankTransactionConfirmation = false;

        try {
            const result = await uploadBankTransaction({ rows: rowsToUpload, bankAccountId: this.selectedBankAccountId });
            this.errors = result.errors || [];
            const successMessage = this.label.saveSuccess + (result.message ? " " + result.message : "");
            if (this.errors.length > 0) {
                this.showToast(
                    this.label.saveFailed,
                    this.label.saveFailedWithCount.replace("{0}", this.errors.length),
                    "error"
                );
                if (result.message) {
                    this.showToast(this.label.infoLabel, result.message, "info");
                }
            } else {
                this.isUploaded = true;
                this.showToast(this.label.successLabel, successMessage, "success");
            }
        } catch (error) {
            this.showToast(this.label.serverError, error.body?.message || error.message, "error");
        } finally {
            this.isLoading = false;
        }
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
        return d.toISOString().split("T")[0];
    }

    formatDateTime(dateVal) {
        if (!dateVal) return "";
        if (typeof dateVal === "string" && dateVal.includes(" ")) return dateVal;
        const d = dateVal instanceof Date ? dateVal : new Date(dateVal);
        if (isNaN(d.getTime())) return dateVal;
        const pad = (n) => String(n).padStart(2, "0");
        return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}:${pad(d.getSeconds())}`;
    }

    formatCurrency(value) {
        if (!value && value !== 0) return "";
        const num = Number(value);
        return isNaN(num) ? value : num.toLocaleString("ko-KR");
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
        this.duplicateBankRowsForDisplay = [];
        this.identifiedBankDuplicates = [];
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