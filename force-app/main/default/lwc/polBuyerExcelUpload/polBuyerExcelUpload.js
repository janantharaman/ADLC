/**********************************************************************************
 * @filename      : polBuyerExcelUpload.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-04-22 (수)
 * @group         :
 * @group-content :
 * @description   : POL Buyer Excel Upload LWC 컴포넌트
 *                  - Buyer Template 파일을 다운로드하고,
 *                  - 업로드된 Excel 파일을 파싱하여 미리보기 모달을 열며,
 *                  - 저장 완료 시 Quick Action을 종료한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-04-22       i2max             Create
 **********************************************************************************/

// LWC
import { LightningElement, api, track } from "lwc";

// Lightning Actions
import { CloseActionScreenEvent } from "lightning/actions";

// Common Utils
import { toast } from "c/com";

// Platform Resource
import { loadScript } from "lightning/platformResourceLoader";

// Static Resources
import sheetjs from "@salesforce/resourceUrl/sheetjs";

// Custom Labels
import POL_MSG_TEMPLATE_DOWNLOAD from "@salesforce/label/c.POL_MSG_TEMPLATE_DOWNLOAD";
import POL_MSG_NODATE_ERROR from "@salesforce/label/c.POL_MSG_NODATE_ERROR";

export default class PolBuyerExcelUpload extends LightningElement {
    // Public Properties
    @api recordId;

    // Reactive Properties
    @track showModal = false;
    @track excelData = [];
    @track fileName = "";

    // Private Properties
    sheetJsLoaded = false;

    labels = {
        templateDownload: POL_MSG_TEMPLATE_DOWNLOAD,
        noDateError: POL_MSG_NODATE_ERROR
    };

    // Lifecycle Methods

    /**
     * @description 컴포넌트 초기화 시 SheetJS 라이브러리를 로드한다.
     * @return {Promise<void>}
     */
    async connectedCallback() {
        await this.loadSheetJS();
    }

    // Event Handlers

    /**
     * @description Buyer Template Excel 파일을 생성하여 다운로드한다.
     * @return {void}
     */
    handleTemplateExport() {
        if (!this.sheetJsLoaded) {
            toast("Error", "SheetJS library not loaded", "error");
            return;
        }

        try {
            const headers = [
                "Company name",
                "International business name",
                "EASY No.",
                "Address",
                "Town",
                "Postcode",
                "State/County",
                "Country name",
                "Country code",
                "Phone",
                "Buyer No.",
                "Legal identifier type 1",
                "Legal identifier value 1",
                "Legal identifier type 2",
                "Legal identifier value 2",
                "Legal identifier type 3",
                "Legal identifier value 3",
                "Product",
                "User ID",
                "Contract number",
                "Contract type",
                "Policyholder",
                "@rating notation",
                "Request date",
                "Customer's debtor reference",
                "Amount asked",
                "Currency amount asked",
                "Minimum shipment amount",
                "Minimum shipment currency",
                "Mode of payment",
                "Decision date",
                "Decision status",
                "Decision type",
                "Decision 1",
                "Decision 2",
                "Decision 3",
                "Effect date",
                "End date",
                "Amount agreed",
                "Currency amount agreed",
                "Guarantors required 1",
                "Guarantors required 2",
                "Guarantors required 3",
                "Guarantors provided 1",
                "Guarantors provided 2",
                "Guarantors provided 3",
                "Decision comment",
                "Insured percentage",
                "DRA",
                "N/A",
                "Operation label",
                "Operation number",
                "Favorite company",
                "Customer reference",
                "Outstanding amount",
                "Internal credit limit"
            ];

            const wsData = [headers];

            const wb = XLSX.utils.book_new();
            const ws = XLSX.utils.aoa_to_sheet(wsData);

            ws["!cols"] = headers.map(() => ({ wch: 20 }));

            XLSX.utils.book_append_sheet(wb, ws, "Buyers");
            XLSX.writeFile(wb, "POL_Buyer_Template.xlsx");

            toast("Success", this.labels.templateDownload, "success");
        } catch (error) {
            toast("Error", "Failed to export template: " + error.message, "error");
        }
    }

    /**
     * @description 업로드된 Excel 파일을 읽어 JSON 배열로 변환하고 모달 표시 여부를 결정한다.
     * @param {Event} event 파일 선택 change 이벤트
     * @return {void}
     */
    handleFileChange(event) {
        const file = event.target.files[0];
        if (!file) return;

        this.fileName = file.name;
        const reader = new FileReader();

        reader.onload = (e) => {
            try {
                const data = new Uint8Array(e.target.result);
                const workbook = XLSX.read(data, { type: "array", cellDates: true, dateNF: "yyyy-mm-dd" });
                const firstSheet = workbook.Sheets[workbook.SheetNames[0]];
                const jsonData = XLSX.utils.sheet_to_json(firstSheet, { header: 1, raw: false });

                if (jsonData && jsonData.length > 1) {
                    this.excelData = jsonData;
                    this.showModal = true;
                } else {
                    toast("Warning", this.labels.noDateError, "warning");
                }
            } catch (error) {
                toast("Error", "Failed to parse Excel file: " + error.message, "error");
            }
        };

        reader.readAsArrayBuffer(file);
    }

    /**
     * @description 업로드 모달을 닫고 내부 상태 및 파일 입력값을 초기화한다.
     * @return {void}
     */
    handleCloseModal() {
        this.showModal = false;
        this.excelData = [];
        this.fileName = "";

        const fileInput = this.template.querySelector('input[type="file"]');
        if (fileInput) {
            fileInput.value = "";
        }
    }

    /**
     * @description 저장 완료 후 모달과 입력값을 초기화하고 Quick Action을 닫는다.
     * @return {void}
     */
    handleSaveComplete() {
        this.showModal = false;
        this.excelData = [];
        this.fileName = "";

        const fileInput = this.template.querySelector('input[type="file"]');
        if (fileInput) {
            fileInput.value = "";
        }

        this.dispatchEvent(new CloseActionScreenEvent());
    }

    // Private Methods

    /**
     * @description SheetJS 라이브러리를 로드한다.
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
}