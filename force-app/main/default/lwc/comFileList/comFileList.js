/**********************************************************************************
 * @filename      : comFileList.js
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
import { LightningElement, api, wire, track } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { registerRefreshHandler, unregisterRefreshHandler } from "lightning/refresh";
import { callApex, toast } from "c/com";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import CONTENT_VERSION_OBJECT from "@salesforce/schema/ContentVersion";

import getFiles from "@salesforce/apex/COM_FileList_Ctrl.getFiles";
import deleteFiles from "@salesforce/apex/COM_FileList_Ctrl.deleteFiles";
import updateCategory from "@salesforce/apex/COM_FileList_Ctrl.updateCategory";

import COM_BTN_REFRESH from "@salesforce/label/c.COM_BTN_REFRESH";
import COM_LBL_REFRESH from "@salesforce/label/c.COM_LBL_REFRESH";
import COM_LBL_SEARCH from '@salesforce/label/c.COM_LBL_SEARCH';
import COM_MSG_SEARCH_KEYWORD from '@salesforce/label/c.COM_MSG_SEARCH_KEYWORD_REQUIRED';
import COM_MSG_NO_SEARCH_RESULT from '@salesforce/label/c.COM_MSG_NO_SEARCH_RESULT';
import COM_MSG_SEARCH_MIN_CHARS from '@salesforce/label/c.COM_MSG_SEARCH_MIN_CHARS';

export default class ComFileList extends NavigationMixin(LightningElement) {
    // 📍 1. API 속성 (외부에서 설정 가능)
    @api recordId;
    @api pageTitle = "";
    @api category = "";
    @api allowDelete = false;
    @api allowUpload = false;
    @api allowSearch = false;
    @api allowLatestColumn = false;
    @api searchEnabled = false;
    @api componentSize = "";

    // 📍 2. 추적 속성 (반응형)
    @track searchText = '';

    // 📍 3. Private 속성
    labels = {
        COM_BTN_REFRESH,
        COM_LBL_REFRESH,
        COM_LBL_SEARCH,
        COM_MSG_NO_SEARCH_RESULT,
        COM_MSG_SEARCH_KEYWORD,
        COM_MSG_SEARCH_MIN_CHARS
    };
    tableColumns = [];
    tableData = [];
    isLoading = false;
    _selectedCount = 0;
    _refreshHandlerToken;

    _buildColumns() {
        const cols = [
            { label: "", name: "rowNo", width: "35px" },
            {
                label: "Title",
                name: "Title",
                type: "url",
                align: "left",
                width: "30rem",
                sortable: true,
                config: { idField: "ContentDocumentId", objectApiName: "ContentDocument" }
            },
            {
                label: "Owner",
                name: "OwnerName",
                width: "10rem",
                type: "url",
                align: "left",
                config: { idField: "OwnerId", objectApiName: "User" }
            },
            { label: "Size", name: "ContentSize", width: "7rem", align: "right" },
            { label: "Last Modified Date", name: "LastModifiedDate", width: "7rem", sortable: true }
        ];
        if (this.category?.toUpperCase() === "ALL") {
            cols.splice(1, 0, { label: "Category", name: "category", width: "8rem" });
        }
        if (this.allowLatestColumn) {
            const lastColumnIndex = cols.findIndex(c => c.name === 'LastModifiedDate');
            cols.splice(lastColumnIndex-1, 0, { label: "Latest(Y/N)", name: "isLatest", width: "4rem", type: 'boolean', align: "center" });
        }
        return cols;
    }

    // 📍 4. Getter/Setter
    get pageTitleDisplay() {
        return (this.pageTitle || "Files") + " (" + (this.tableData?.length || 0) + ")";
    }

    get hasData() {
        return this.tableData.length > 0;
    }

    get hideCheckboxColumn() {
        return !this.allowDelete;
    }

    get tableStyle() {
        const sizeMap = { Small: "200px", Medium: "400px", Large: "600px" };
        return `--rec-table-max-height: ${sizeMap[this.componentSize] || "400px"}`;
    }

    // 📍 5. Wire 메서드
    @wire(getObjectInfo, { objectApiName: CONTENT_VERSION_OBJECT })
    wiredObjectInfo({ data }) {
        if (data) {
            this.tableColumns = this._applyLabels(this._buildColumns(), data.fields);
        }
    }

    // 📍 6. 이벤트 핸들러
    handleFileClick(event) {
        const docId = event.detail?.row?.ContentDocumentId;
        if (docId) {
            this[NavigationMixin.Navigate]({
                type: "standard__namedPage",
                attributes: { pageName: "filePreview" },
                state: { selectedRecordId: docId }
            });
        }
    }

    handleRowSelection(event) {
        this._selectedCount = event.detail.selectedRows.length;
    }

    async handleUploadFinished(event) {
        const contentVersionIds = event.detail.files.map((f) => f.contentVersionId);
        if (this.category && contentVersionIds.length) {
            await callApex(this, updateCategory, {
                contentVersionIds,
                category: this.category
            });
        }
        toast(this, "Success", "파일이 업로드되었습니다.", "success");
        await this.loadData();
    }

    async handleDelete() {
        const table = this.refs.table;
        const selectedRows = table.getSelectedRows();
        if (!selectedRows?.length) {
            toast(this, "Warning", "삭제할 파일을 선택해주세요.", "warning");
            return;
        }
        const docIds = selectedRows.map((r) => r.ContentDocumentId);
        this.isLoading = true;
        try {
            await callApex(this, deleteFiles, { contentDocumentIds: docIds });
            toast(this, "Success", `${docIds.length}건의 파일이 삭제되었습니다.`, "success");
            await this.loadData();
        } catch (e) {
            //
        } finally {
            this.isLoading = false;
        }
    }

    async handleRefresh() {
        this.refs.table.clearSelection();
        this.searchText = '';
        await this.loadData();
    }

    handleChange(event) {
        this.searchText = event.target.value;
    }

    handleSearch() {
        // 1. 공백 제거 후 값 확인
        const searchKey = this.searchText ? this.searchText.trim() : '';

        // 2. 빈 값 체크
        if (!searchKey) {
            toast(this, this.labels.COM_MSG_SEARCH_KEYWORD, 'warning');
            return;
        }

        // 3. 글자 수 체크 (2글자 미만)
        if (searchKey.length < 2) {
            toast(this,this.COM_MSG_SEARCH_MIN_CHARS, 'warning');
            return;
        }
        void this.loadData();
    }

    // 엔터 키
    handleKeyDown(event) {
        if (event.keyCode === 13) { // 13은 Enter 키의 코드값입니다.
            this.handleSearch();
        }
    }

    // 📍 7. Private 메서드
    formatFileSize(bytes) {
        if (!bytes) return "";
        if (bytes < 1024) return bytes.toLocaleString() + " B";
        if (bytes < 1024 * 1024) return (bytes / 1024).toLocaleString(undefined, { maximumFractionDigits: 1 }) + " KB";
        return (bytes / (1024 * 1024)).toLocaleString(undefined, { maximumFractionDigits: 1 }) + " MB";
    }

    async loadData() {
        if (!this.recordId) return;
        this.isLoading = true;
        try {
            const result = await callApex(this, getFiles, {
                recordId: this.recordId,
                category: this.category,
                searchTitle: this.searchText
            });
            this.tableData = (result || []).map((item) => ({
                ...item,
                ContentSize: this.formatFileSize(item.ContentSize)
            }));
        } catch (e) {
            this.tableData = [];
        } finally {
            this.isLoading = false;
            this.refs.table.clearSelection();
        }
    }

    _applyLabels(columns, fields) {
        return columns.map((col) => {
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

    registerRefreshApi() {
        try {
            console.log("Registering refresh handler for LWS");
            this._refreshHandlerToken = registerRefreshHandler(this, this.loadData);
        } catch (error) {
            console.log("Registering refresh handler for Locker");
            this._refreshHandlerToken = registerRefreshHandler(this.template.host, this.loadData.bind(this));
        }
    }

    // 📍 8. 라이프사이클 메서드
    async connectedCallback() {
        this.registerRefreshApi();
        await this.loadData();
    }

    disconnectedCallback() {
        if (this._refreshHandlerToken) {
            unregisterRefreshHandler(this._refreshHandlerToken);
        }
    }


}