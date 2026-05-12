/**
 * @group        : Trestle
 * @description  : Reconciliation Line Item Inquiry Modal
 * @author       : Yugon Hwang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2026-02-25   Yugon Hwang   Initial Version
 **/
import { api, track } from "lwc";
import LightningModal from "lightning/modal";
import Toast from "lightning/toast";

import checkNewButtonDisabled from "@salesforce/apex/REC_RelatedReconCtrl.checkNewButtonDisabled";
import checkStatementUploadDisabled from "@salesforce/apex/REC_RelatedReconCtrl.checkStatementUploadDisabled";
import createNewReconciliation from "@salesforce/apex/REC_RelatedReconCtrl.createNewReconciliation";
import createStatementsFromUpload from "@salesforce/apex/REC_RelatedReconCtrl.createStatementsFromUpload";
import inquiryReconciliationLineItems from "@salesforce/apex/REC_RelatedReconCtrl.inquiryReconciliationLineItems";
import resolveAccountsByERPCodes from "@salesforce/apex/REC_RelatedReconCtrl.resolveAccountsByERPCodes";
import validateStatementData from "@salesforce/apex/REC_RelatedReconCtrl.validateStatementData";
import getPicklistOptions from "@salesforce/apex/REC_Utils.getPicklistOptions";

// Feature Flag - UAT 배포와 개발시점 차이 관리
import isFeatureEnabled from "@salesforce/apex/REC_Utils.isFeatureEnabled";

import { COLUMN_MAP, validateAndExtractRows, validateLookups, mapToSliFields, formatErrors } from "./statementParser";

const TYPE = {
    RECONCILIATION: "Reconciliation",
    STATEMENT: "Statement"
};

export default class RecRelatedReconciliationModal extends LightningModal {
    @api recordId; // 부모로부터 전달받는 recordId
    @api type;
    @api xlsx; // SheetJS library instance passed from parent
    @track tableData;

    modalHeader = "Related Reconciliation Line Item";
    isLoading = false;
    isNewDisabled = true;
    isStatementUploadDisabled = true;

    @track parsedStatementData = [];
    picklistValuesCache = {};

    // TABLE COLUMNS (고정 데이터는 필드로 정의)
    tableColumns = [
        { label: "RLI No.", name: "Name" },
        {
            label: "Reconciled AMT",
            name: "ReconciledAMT__c",
            type: "currency",
            config: { ccyField: "BTCurrency__c" }
        },
        {
            label: "Reconciled Date",
            name: "TransactionDate__c",
            type: "date"
        },
        {
            label: "Status",
            name: "RefReconciliation__r.Status__c"
        },
        {
            label: "Reconciled Details",
            name: "Action",
            type: "button",
            config: {
                variant: "border",
                iconName: "utility:search",
                size: "small"
            }
        }
    ];

    get isTypeReconciliation() {
        return this.type === TYPE.RECONCILIATION || !this.type;
    }

    get isTypeStatement() {
        return this.type === TYPE.STATEMENT;
    }

    get showNewButton() {
        return this.isTypeReconciliation;
    }

    get showFileUpload() {
        return this.isTypeStatement;
    }

    async connectedCallback() {
        this.loadTableData();

        if (this.isTypeReconciliation) {
            // Separate microtask to avoid Apex boxcar batching with loadTableData
            // eslint-disable-next-line @lwc/lwc/no-async-operation
            Promise.resolve().then(() => this.initReconciliation());
        }

        if (this.isTypeStatement) {
            await this.initStatement();
        }
    }

    loadTableData() {
        inquiryReconciliationLineItems({ recordId: this.recordId })
            .then((data) => {
                this.tableData = data;
            })
            .catch((error) => {
                console.error("Error fetching data:", error);
            });
    }

    initReconciliation() {
        checkNewButtonDisabled({ recordId: this.recordId })
            .then((disabled) => {
                this.isNewDisabled = disabled;
            })
            .catch((error) => {
                console.error("Error checking new button state:", error);
            });
    }

    async initStatement() {
        // TODO: 임시 Flag - UAT 배포와 개발시점 차이 관리, 추후 삭제 예정
        isFeatureEnabled({ featureName: "REC_Insurance" })
            .then((enabled) => {
                this.isInsuranceFeatureDisabled = !enabled;
            })
            .catch((error) => {
                console.error("Error checking feature flag:", error);
            });

        checkStatementUploadDisabled({ recordId: this.recordId })
            .then((disabled) => {
                this.isStatementUploadDisabled = disabled;
            })
            .catch((error) => {
                console.error("Error checking statement upload button state:", error);
            });

        // Load SheetJS library
        if (!this.xlsx) {
            this.showToast("Error", "XLSX 라이브러리가 전달되지 않았습니다.", "error");
            return;
        }

        // Pre-fetch picklist values
        await this.loadPicklistValues();
    }

    // EVENT HANDLERS
    async handleNewClick(event) {
        event.preventDefault();
        this.isLoading = true;

        try {
            const resultId = await createNewReconciliation({ baseRecordId: this.recordId });
            this.tableData = await inquiryReconciliationLineItems({ recordId: this.recordId });
            this.isNewDisabled = await checkNewButtonDisabled({ recordId: this.recordId });
            this.navigate(resultId);
        } catch (error) {
            console.error("Error creating record:", error);
            this.close(null);
        } finally {
            this.isLoading = false;
        }
    }

    handleCellButtonClick(event) {
        event.preventDefault();
        this.navigate(event.detail.row.RefReconciliation__c);
    }

    // UTILS
    navigate(recordId) {
        window.open(`/lightning/r/Reconciliation__c/${recordId}/view`, "_blank");
    }

    showToast(label, message, variant) {
        Toast.show({ label, message, variant }, this);
    }

    readExcel(file) {
        const xlsx = this.xlsx;
        return new Promise((resolve, reject) => {
            const reader = new FileReader();
            reader.onload = () => {
                try {
                    const workbook = xlsx.read(reader.result, { type: "array", cellDates: true });
                    const sheet = workbook.Sheets[workbook.SheetNames[0]];
                    const data = xlsx.utils.sheet_to_json(sheet, { header: 1, raw: true });
                    resolve(data);
                } catch (e) {
                    reject(e);
                }
            };
            reader.onerror = reject;
            reader.readAsArrayBuffer(file);
        });
    }

    // ----- STATEMENT UPLOAD: PARSING & VALIDATION -----

    async loadPicklistValues() {
        const picklistColumns = COLUMN_MAP.filter((c) => c.type === "picklist");
        const promises = picklistColumns.map(async (col) => {
            try {
                const options = await getPicklistOptions({
                    objectApiName: col.objectApiName,
                    fieldApiName: col.fieldApiName
                });
                const labelToValue = new Map();
                const validLabels = new Set();
                const validValues = new Set();
                for (const opt of options) {
                    labelToValue.set(opt.label, opt.value);
                    validLabels.add(opt.label);
                    validValues.add(opt.value);
                }
                this.picklistValuesCache[col.uploadColumn] = { labelToValue, validLabels, validValues };
            } catch (error) {
                console.error(`Error loading picklist values for ${col.fieldApiName}:`, error);
            }
        });
        await Promise.all(promises);
    }

    async handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        this.isLoading = true;
        this.parsedStatementData = [];

        try {
            if (!this.xlsx) {
                this.showToast("Error", "XLSX 라이브러리가 전달되지 않았습니다.", "error");
                return;
            }

            const sheetData = await this.readExcel(file);
            if (!sheetData || sheetData.length < 2) {
                this.showToast("Error", "파일에 데이터가 없습니다.", "error");
                return;
            }

            // Validate columns & rows
            const result = validateAndExtractRows(sheetData, this.picklistValuesCache);
            if (result.error) {
                this.showToast("Error", result.error, "error");
                return;
            }

            const { errors, rawRows, erpCodesToResolve } = result;
            if (errors.length > 0) {
                this.showToast("Validation Error", formatErrors(errors), "error");
                console.error("Validation errors:", errors);
                return;
            }

            // Resolve lookups (Account by ERPCode)
            let accountMap = {};
            if (erpCodesToResolve.size > 0) {
                accountMap = await resolveAccountsByERPCodes({ erpCodes: [...erpCodesToResolve] });

                const lookupErrors = validateLookups(rawRows, accountMap);
                if (lookupErrors.length > 0) {
                    this.showToast("Validation Error", formatErrors(lookupErrors), "error");
                    console.error("Lookup errors:", lookupErrors);
                    return;
                }
            }

            // Map to SLI fields
            const mappedData = mapToSliFields(rawRows, accountMap, this.picklistValuesCache);

            // Parsed Data Validation — validate against base BankTransaction
            const validationResult = await validateStatementData({
                recordId: this.recordId,
                rowsJson: JSON.stringify(mappedData)
            });

            if (!validationResult.success) {
                this.showToast("Validation Error", validationResult.errors.join(" | "), "error");
                console.error("Statement validation errors:", validationResult.errors);
                return;
            }

            // Create Statement, SLI, Reconciliation, RLI records
            const uploadResult = await createStatementsFromUpload({
                recordId: this.recordId,
                rowsJson: JSON.stringify(mappedData)
            });

            this.parsedStatementData = mappedData;

            // Refresh: RLI table + disable upload
            this.tableData = await inquiryReconciliationLineItems({ recordId: this.recordId });
            this.isStatementUploadDisabled = true;

            this.showToast(
                "Success",
                `${uploadResult.statementCount}건의 Statement, ${uploadResult.lineItemCount}건의 Line Item이 생성되었습니다.`,
                "success"
            );
        } catch (error) {
            console.error("File Processing Error:", error);
            this.showToast("Error", "파일 처리 중 오류가 발생했습니다: " + error.message, "error");
        } finally {
            this.isLoading = false;
        }
    }
}