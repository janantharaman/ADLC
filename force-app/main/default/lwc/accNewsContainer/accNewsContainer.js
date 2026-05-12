/**********************************************************************************
 * @filename      : AccNewsContainer.js
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
import {LightningElement, api} from 'lwc';
import { callApex } from 'c/com';
import getNewsByAccountId from '@salesforce/apex/ACC_News_Ctrl.getNewsByAccountId';
import COM_MSG_NORECORDS from '@salesforce/label/c.COM_MSG_NORECORDS';
import COM_BTN_RefreshRef from '@salesforce/label/c.COM_BTN_RefreshRef';
import COM_LBL_RefreshRef from '@salesforce/label/c.COM_LBL_RefreshRef';

export default class AccNewsContainer extends LightningElement {

    labels = {
        COM_MSG_NORECORDS,
        COM_BTN_RefreshRef,
        COM_LBL_RefreshRef
    }

    @api recordId;
    @api pageSize = 10;
    @api maxHeight = 400;
    @api message = this.labels.COM_MSG_NORECORDS;

    allNewsItems = [];
    visibleItems = [];
    totalCount = 0;
    error;
    isLoading = false;

    get containerStyle() {
        return `max-height: ${this.maxHeight}px; overflow-y: auto;`;
    }

    get hasNews() {
        return this.visibleItems.length > 0;
    }

    get cardTitle() {
        return `News` + (this.hasNews ? ` (${this.visibleItems.length}/${this.totalCount})` : '');
    }

    get showViewAll() {
        return this.visibleItems.length < this.totalCount;
    }

    get showTopButton() {
        return this.visibleItems.length > this.pageSize;
    }

    handleRefresh() {
        void this.loadAllNews();
    }

    handleViewAll() {
        const container = this.template.querySelector('.slds-p-horizontal_small');
        const prevScrollHeight = container.scrollHeight;

        const nextCount = this.visibleItems.length + this.pageSize;
        this.visibleItems = this.allNewsItems.slice(0, nextCount);

        // DOM 렌더링 후 스크롤 이동
        setTimeout(() => {
            container.scrollTop = prevScrollHeight;
        }, 0);
    }

    handleScrollTop() {
        const container = this.template.querySelector('.slds-p-horizontal_small');
        container.scrollTop = 0;
    }

    async loadAllNews() {
        this.isLoading = true;
        try {
            const data = await callApex(this, getNewsByAccountId, {
                accountId: this.recordId,
                limitCount: 0
            });
            this.allNewsItems = (data || []).map(item => ({
                ...item,
                formattedDate: this.formatDate(item.PubDate__c)
            }));
            this.totalCount = this.allNewsItems.length;
            this.visibleItems = this.allNewsItems.slice(0, this.pageSize);
        } catch (e) {
            this.allNewsItems = [];
            this.visibleItems = [];
        } finally {
            this.isLoading = false;
        }
    }

    formatDate(dateStr) {
        if (!dateStr) return '';
        const dt = new Date(dateStr);
        return new Intl.DateTimeFormat('ko-KR', {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit'
        }).format(dt);
    }

    connectedCallback() {
        void this.loadAllNews();
    }

}