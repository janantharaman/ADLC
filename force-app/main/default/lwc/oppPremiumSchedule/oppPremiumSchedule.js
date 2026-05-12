/**********************************************************************************
 * @filename      : oppPremiumSchedule.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2025-12-10 (수)
 * @group         :
 * @group-content :
 * @description   : Opportunity Premium Schedule LWC 컴포넌트
 *                  - Premium Schedule 데이터를 조회·편집·저장·삭제하고,
 *                  - Install 개수 검증, Install Date 계산, 퍼센트 합계 검증,
 *                  - Placement/Opportunity 공통 recordId 기반 저장 처리를 수행한다.
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2025-12-09       i2max             Create
 **********************************************************************************/

import { LightningElement, api, track, wire } from "lwc";
import { toast } from "c/com";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

// Custom Labels
import LABEL_CANCEL from "@salesforce/label/c.COM_BTN_CANCEL";
import LABEL_SAVE from "@salesforce/label/c.COM_BTN_SAVE";
import LABEL_DELETE from "@salesforce/label/c.COM_BTN_DEL";
import OPP_MSG_PREMIUM_SAVE_SUCCESS from "@salesforce/label/c.OPP_MSG_PREMIUM_SAVE_SUCCESS";
import OPP_MSG_PERIODFROM_REQUIRED from "@salesforce/label/c.OPP_MSG_PERIODFROM_REQUIRED";
import OPP_MSG_PERCENTAGE from "@salesforce/label/c.OPP_MSG_PERCENTAGE";
import OPP_MSG_ALLFIELD_REQUIRED from "@salesforce/label/c.OPP_MSG_ALLFIELD_REQUIRED";
import OPP_MSG_TOTALPERCENTAGE from "@salesforce/label/c.OPP_MSG_TOTALPERCENTAGE";
import OPP_MSG_DELETEMARK from "@salesforce/label/c.OPP_MSG_DELETEMARK";

// Apex Methods
import getInitMeta from "@salesforce/apex/Opp_PremiumSchedule_Ctrl.getInitMeta";
import getOpportunityScheduleData from "@salesforce/apex/Opp_PremiumSchedule_Ctrl.getOpportunityScheduleData";
import savePremiumSchedules from "@salesforce/apex/Opp_PremiumSchedule_Ctrl.savePremiumSchedules";
import deletePremiumSchedule from "@salesforce/apex/Opp_PremiumSchedule_Ctrl.deletePremiumSchedule";
import calculateInstallDate from "@salesforce/apex/Opp_PremiumSchedule_Ctrl.calculateInstallDate";

// Schema
import PREMIUM_SCHEDULE_OBJ from "@salesforce/schema/OPP_PremiumSchedule__c";

// Constants
const PERCENTAGE_MIN = 0;
const MIN_INSTALLS = 2;

const MESSAGES = {
    ERROR_MIN_INSTALLS: `# of installs must be at least ${MIN_INSTALLS}`
};

export default class OppPremiumSchedule extends LightningElement {
    // Public Properties
    @api recordId;
    @api selectedCurrency;
    @api expectedInstalls;
    @api grossPrem;

    // Reactive Properties
    @track scheduleRows = [];
    @track editableTotalInstalls = 0;
    @track errorMessage = "";
    @track successMessage = "";
    @track showDeleteButtons = false;
    @track isClosed = false;
    @track hasEditPermission = false;

    // Private Properties
    originalTotalInstalls = 0;
    periodFrom = null;
    opportunityName = "";
    schedulesToDelete = [];
    objectFields;
    _init = false;

    // Custom Labels
    labels = {
        save: LABEL_SAVE,
        cancel: LABEL_CANCEL,
        delete: LABEL_DELETE,
        premiumSaveSuccess: OPP_MSG_PREMIUM_SAVE_SUCCESS,
        periodFromRequired: OPP_MSG_PERIODFROM_REQUIRED,
        percentage: OPP_MSG_PERCENTAGE,
        allFieldRequired: OPP_MSG_ALLFIELD_REQUIRED,
        totalPercentage: OPP_MSG_TOTALPERCENTAGE,
        deleteMark: OPP_MSG_DELETEMARK
    };

    // Getters
    get hasSchedules() {
        return this.scheduleRows && this.scheduleRows.length > 0;
    }

    get totalPercentage() {
        return this.scheduleRows.reduce((sum, row) => sum + (parseFloat(row.percentage) || 0), 0).toFixed(2);
    }

    get totalPercentageError() {
        const total = parseFloat(this.totalPercentage);
        if (total !== 100) {
            return this.labels.totalPercentage;
        }
        return "";
    }

    get isSaveDisabled() {
        if (this.isClosed) {
            return true;
        }

        const targetCount = Number(this.editableTotalInstalls) || 0;

        if (this.scheduleRows.length !== targetCount) {
            return true;
        }

        const hasNullValues = this.scheduleRows.some((row) => row.daysFromInception === null || row.daysFromInception === undefined || row.percentage === null || row.percentage === undefined);

        if (hasNullValues) {
            return true;
        }

        const total = parseFloat(this.totalPercentage);
        if (total !== 100) {
            return true;
        }

        if (!this.validatePercentageGreaterThanZero()) {
            return true;
        }

        return false;
    }

    get validationErrorMessage() {
        if (this.errorMessage) {
            return this.errorMessage;
        }

        if (!this.validateInstallsCount()) {
            return MESSAGES.ERROR_MIN_INSTALLS;
        }

        const targetCount = Number(this.editableTotalInstalls) || 0;

        if (targetCount === 0 || this.scheduleRows.length === 0) {
            return "";
        }

        const hasNullValues = this.scheduleRows.some((row) => row.daysFromInception === null || row.daysFromInception === undefined || row.percentage === null || row.percentage === undefined);

        if (hasNullValues) {
            return this.labels.allFieldRequired;
        }

        if (!this.validatePercentageGreaterThanZero()) {
            return this.labels.percentage;
        }

        return "";
    }

    get isUpdateDisabled() {
        if (!this.validateInstallsCount()) {
            return true;
        }

        return this.isClosed;
    }

    get isFieldsReadonly() {
        return this.isClosed;
    }

    get canEdit() {
        return this.hasEditPermission && !this.isClosed;
    }

    get totalInstallsLabel() {
        return this.objectFields?.TotalInstalls__c?.label ?? "# of installs";
    }

    get daysFromInceptionLabel() {
        return this.objectFields?.DaysFromInception__c?.label ?? "Days from Inception";
    }

    get percentageLabel() {
        return this.objectFields?.Percentage__c?.label ?? "%";
    }

    get installDateLabel() {
        return this.objectFields?.InstallDate_fm__c?.label ?? "Install Date";
    }

    // Wire Methods

    /**
     * @description Premium Schedule 오브젝트 메타 정보를 조회하여 필드 라벨에 사용한다.
     * @return {void}
     */
    @wire(getObjectInfo, { objectApiName: PREMIUM_SCHEDULE_OBJ })
    wiredObjectInfo({ data, error }) {
        if (data?.fields) {
            this.objectFields = data.fields;
        } else if (error) {
            this.objectFields = null;
            console.error("Error loading object info:", error);
        }
    }

    /**
     * @description 초기 메타 데이터를 조회하여 편집 권한을 설정한다.
     * @return {void}
     */
    @wire(getInitMeta, { recordId: "$recordId" })
    wiredInitMeta({ data, error }) {
        if (data) {
            this.hasEditPermission = data.hasEditPermission || false;
        } else if (error) {
            this.hasEditPermission = false;
            console.error("Error loading init meta:", error);
        }
    }

    // Event Handlers

    /**
     * @description # of installs 입력값 변경 시 editableTotalInstalls를 갱신한다.
     * @param {Event} event 변경 이벤트
     * @return {void}
     */
    handleTotalInstallsChange(event) {
        this.editableTotalInstalls = parseInt(event.target.value, 10) || 0;
    }

    /**
     * @description # of installs 값 기준으로 행 수를 검증하고 조정한다.
     * @return {void}
     */
    handleUpdateInstalls() {
        this.performValidateInstallsCount();
    }

    /**
     * @description Days from Inception 변경 시 행 데이터를 갱신하고 Install Date를 재계산한다.
     * @param {Event} event 변경 이벤트
     * @return {Promise<void>}
     */
    async handleDaysChange(event) {
        const index = parseInt(event.target.dataset.id, 10);
        const value = parseInt(event.target.value, 10) || 0;

        const rows = [...this.scheduleRows];
        rows[index].daysFromInception = value;
        this.scheduleRows = rows;

        await this.updateInstallDate(index);
    }

    /**
     * @description Percentage 변경 시 해당 행의 percentage 값을 갱신한다.
     * @param {Event} event 변경 이벤트
     * @return {void}
     */
    handlePercentageChange(event) {
        const index = parseInt(event.target.dataset.id, 10);
        const value = parseFloat(event.target.value) || 0;

        const rows = [...this.scheduleRows];
        rows[index].percentage = value;
        this.scheduleRows = rows;
    }

    /**
     * @description 특정 행을 삭제하고 삭제 대기 목록 및 검증 메시지를 갱신한다.
     * @param {Event} event 클릭 이벤트
     * @return {void}
     */
    handleDeleteRow(event) {
        const index = parseInt(event.target.dataset.id, 10);
        const rows = [...this.scheduleRows];
        const row = rows[index];

        try {
            if (row.id) {
                this.schedulesToDelete = [...this.schedulesToDelete, row.id];
                console.log("Added to delete list:", row.id);
                console.log("schedulesToDelete:", this.schedulesToDelete);
                console.log(this.totalPercentage);
            }

            rows.splice(index, 1);

            this.scheduleRows = rows.map((r, idx) => ({
                ...r,
                index: idx,
                rowNumber: idx + 1
            }));

            const currentRowCount = this.scheduleRows.length;
            const targetCount = Number(this.editableTotalInstalls) || 0;

            if (currentRowCount === targetCount) {
                this.errorMessage = "";
                this.showDeleteButtons = false;
            } else if (currentRowCount > targetCount) {
                this.errorMessage = `Please delete ${currentRowCount - targetCount} more row(s)`;
                this.showDeleteButtons = true;
            } else {
                this.errorMessage = "";
                this.showDeleteButtons = false;
            }

            toast("Success", this.labels.deleteMark, "success");
        } catch (error) {
            toast("Error", this.reduceErrors(error), "error");
        }
    }

    /**
     * @description 저장 전 검증 후 삭제 대상 스케줄을 삭제하고 현재 스케줄 데이터를 저장한다.
     * @return {Promise<void>}
     */
    async handleSave() {
        try {
            if (!this.validatePeriodFrom()) {
                return;
            }

            if (!this.validateInstallsCount()) {
                return;
            }

            await this.deleteScheduledItems();
            await this.savePremiumScheduleData();

            this.successMessage = this.labels.premiumSaveSuccess;
            this.errorMessage = "";
        } catch (error) {
            toast("Error", this.reduceErrors(error), "error");
        }
    }

    /**
     * @description 스케줄 입력 화면을 닫기 위해 scheduleclose 이벤트를 발생시킨다.
     * @return {void}
     */
    handleCancel() {
        this.dispatchEvent(new CustomEvent("scheduleclose"));
    }

    // Private Methods

    /**
     * @description PeriodFrom 값 존재 여부를 검증한다.
     * @return {Boolean} PeriodFrom 유효 여부
     */
    validatePeriodFrom() {
        if (!this.periodFrom) {
            toast("Error", this.labels.periodFromRequired, "error");
            return false;
        }
        return true;
    }

    /**
     * @description # of installs 값이 최소 개수 이상인지 검증한다.
     * @return {Boolean} installs 개수 유효 여부
     */
    validateInstallsCount() {
        const targetCount = Number(this.editableTotalInstalls) || 0;
        return targetCount >= MIN_INSTALLS;
    }

    /**
     * @description 모든 percentage 값이 0보다 큰지 검증한다.
     * @return {Boolean} percentage 유효 여부
     */
    validatePercentageGreaterThanZero() {
        return !this.scheduleRows.some((row) => {
            const percentage = parseFloat(row.percentage) || 0;
            return percentage <= PERCENTAGE_MIN;
        });
    }

    /**
     * @description 삭제 대기 목록에 있는 Premium Schedule 레코드를 서버에서 삭제한다.
     * @return {Promise<void>}
     */
    async deleteScheduledItems() {
        if (!this.schedulesToDelete?.length) return;

        console.log("Deleting schedules:", this.schedulesToDelete);

        try {
            await Promise.all(this.schedulesToDelete.map((scheduleId) => deletePremiumSchedule({ scheduleId }).then(() => console.log("Deleted schedule:", scheduleId))));

            this.schedulesToDelete = [];
            console.log("All schedules deleted successfully");
        } catch (deleteError) {
            console.error("Error deleting schedules:", deleteError);
            throw deleteError;
        }
    }

    /**
     * @description 현재 scheduleRows 데이터를 서버 저장용 payload로 변환하여 저장한다.
     * @return {Promise<void>}
     */
    async savePremiumScheduleData() {
        const schedules = this.scheduleRows.map((row) => ({
            id: row.id || null,
            daysFromInception: parseInt(row.daysFromInception, 10) || null,
            percentage: parseFloat(row.percentage) || 0,
            installDate: row.installDate || null
        }));

        console.log("Prepared schedules:", JSON.stringify(schedules));

        await savePremiumSchedules({
            recordId: this.recordId,
            premCurrency: this.selectedCurrency,
            paymentType: "Install",
            grossPrem: this.grossPrem ?? null,
            schedules: schedules
        });

        this.dispatchEvent(
            new CustomEvent("schedulesave", {
                detail: { updatedInstalls: this.editableTotalInstalls },
                bubbles: true,
                composed: true
            })
        );
    }

    /**
     * @description 서버에서 Premium Schedule 데이터를 조회하여 화면 상태를 초기화한다.
     * @return {Promise<void>}
     */
    async loadData() {
        console.log("Loading data for Opportunity ID:", this.recordId, "Currency:", this.selectedCurrency);

        try {
            const result = await getOpportunityScheduleData({
                recordId: this.recordId,
                premCurrency: this.selectedCurrency
            });

            this.originalTotalInstalls = result.totalInstalls;
            this.editableTotalInstalls = this.expectedInstalls || result.totalInstalls;
            this.periodFrom = result.periodFrom;
            this.opportunityName = result.opportunityName;
            this.isClosed = result.isClosed || false;

            this.schedulesToDelete = [];

            if (result.schedules && result.schedules.length > 0) {
                this.scheduleRows = result.schedules.map((schedule, index) => ({
                    index: index,
                    rowNumber: index + 1,
                    id: schedule.id,
                    daysFromInception: schedule.daysFromInception,
                    percentage: schedule.percentage,
                    installDate: schedule.installDate
                }));
            } else {
                this.initializeRows(this.editableTotalInstalls);
            }

            this.performValidateInstallsCount();
        } catch (error) {
            toast("Error", this.reduceErrors(error), "error");
        }
    }

    /**
     * @description 지정한 개수만큼 빈 Premium Schedule 행을 초기화한다.
     * @param {Number} count 생성할 행 개수
     * @return {void}
     */
    initializeRows(count) {
        const newCount = Number(count) || 0;
        const rows = [];

        for (let i = 0; i < newCount; i++) {
            rows.push({
                index: i,
                rowNumber: i + 1,
                id: null,
                daysFromInception: null,
                percentage: null,
                installDate: null
            });
        }

        this.scheduleRows = rows;
    }

    /**
     * @description editableTotalInstalls 값에 맞춰 행 수를 검증하고 추가/삭제 안내 상태를 갱신한다.
     * @return {void}
     */
    performValidateInstallsCount() {
        const currentRowCount = this.scheduleRows.length;
        const newCount = Number(this.editableTotalInstalls) || 0;

        if (newCount < MIN_INSTALLS) {
            this.errorMessage = MESSAGES.ERROR_MIN_INSTALLS;
            this.showDeleteButtons = false;
            return;
        }

        if (newCount > currentRowCount) {
            const rows = [...this.scheduleRows];
            for (let i = currentRowCount; i < newCount; i++) {
                rows.push({
                    index: i,
                    rowNumber: i + 1,
                    id: null,
                    daysFromInception: null,
                    percentage: null,
                    installDate: null
                });
            }
            this.scheduleRows = rows;
            this.errorMessage = "";
            this.showDeleteButtons = false;
        } else if (newCount < currentRowCount) {
            this.errorMessage = `Please delete ${currentRowCount - newCount} more row(s)`;
            this.showDeleteButtons = true;
        } else {
            this.errorMessage = "";
            this.showDeleteButtons = false;
        }
    }

    /**
     * @description 특정 행의 Days from Inception 값을 기준으로 Install Date를 재계산한다.
     * @param {Number} index 행 인덱스
     * @return {Promise<void>}
     */
    async updateInstallDate(index) {
        try {
            if (!this.periodFrom) {
                const rows = [...this.scheduleRows];
                rows[index].installDate = null;
                this.scheduleRows = rows;
                return;
            }

            const installDate = await calculateInstallDate({
                periodFrom: this.periodFrom,
                daysFromInception: this.scheduleRows[index].daysFromInception
            });

            const rows = [...this.scheduleRows];
            rows[index].installDate = installDate;
            this.scheduleRows = rows;
        } catch (error) {
            console.error("Error calculating install date:", error);
        }
    }

    /**
     * @description Apex/LDS/JS 에러 객체를 사용자 표시용 문자열로 변환한다.
     * @param {Object|Array} errors 에러 객체 또는 배열
     * @return {String} 포맷된 에러 메시지
     */
    reduceErrors(errors) {
        if (!Array.isArray(errors)) {
            errors = [errors];
        }

        return errors
            .filter((error) => !!error)
            .map((error) => {
                if (Array.isArray(error.body)) {
                    return error.body.map((e) => e.message);
                } else if (error.body && typeof error.body.message === "string") {
                    return error.body.message;
                } else if (typeof error.message === "string") {
                    return error.message;
                }
                return JSON.stringify(error);
            })
            .reduce((prev, curr) => prev.concat(curr), [])
            .filter((message, index, self) => self.indexOf(message) === index)
            .join(", ");
    }

    // Lifecycle Methods

    /**
     * @description 컴포넌트 최초 초기화 시 input 정렬 스타일을 적용하고 데이터를 조회한다.
     * @return {void}
     */
    connectedCallback() {
        if (this._init) return;

        const style = document.createElement("style");
        style.innerText = `.cus-lk-input-right input { text-align: right !important; }`;
        document.body.appendChild(style);

        void this.loadData();
        this._init = true;
    }
}