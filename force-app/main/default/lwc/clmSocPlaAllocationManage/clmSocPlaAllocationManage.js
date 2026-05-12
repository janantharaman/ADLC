/**********************************************************************************
 * @filename      : clmSocPlaAllocationManage.js
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-26 (월)
 * @group         :
 * @group-content :
 * @description   :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-01-26      i2max      Create
 **********************************************************************************/
import { LightningElement, api, track, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecord } from 'lightning/uiRecordApi';

import {toast, callApex, getCurrencyScale, scaleToStep} from 'c/com';

// Schema Imports
import CLAIM_OBJECT from '@salesforce/schema/Claim';
import LAST_PLA_FIELD from '@salesforce/schema/Claim.LastPLA_is__c';
import DOC_TYPE_FIELD from '@salesforce/schema/Claim.ClaimDocType__c';

import getRecords from '@salesforce/apex/CLM_SocPlaAllocationManage_Ctrl.getRecords';
import saveAllocation from '@salesforce/apex/CLM_SocPlaAllocationManage_Ctrl.saveAllocation';

export default class clmSocPlaAllocationManage extends LightningElement {

    // 📍 1. API 속성 (외부에서 설정 가능)
    @api recordId;

    // 📍 2. 추적 속성 (반응형)
    @track summaryData;
    @track summaryErrors = {};
    @track settlementCurrency = '';
    @track errorMsg = '';
    claimCurrency = '';

    isLoading = false;
    isDisabled = true;

    // Input Form
    inputType = ''; // Default SOC
    amounts = {
        loss: null,
        expense: null,
        total: null
    };

    // Source Grid Selection
    @track ClaimOptions = [];

    // Result Grid Items
    @track resultItems = [];

    // 📍 3. Private 속성
    _init = false;
    lkSharePct = 0;
    fxRateToSettleCurr = 0;
    _claimOffsetMap = {};
    _claimName = '';

    // 📍 4. Getter/Setter
    /**
     * resultItems(그리드)의 변경 사항을 반영하여 실시간으로 계산된 Summary Data 반환
     */
    get computedSummaryData() {
        if (!this.summaryData) return [];

        const data = JSON.parse(JSON.stringify(this.summaryData));

        data.forEach(table => {
            const type = table.type; // 'SOC' 또는 'PLA'

            const { allocatedLoss, allocatedExpense, allocatedTotalLK } = this.getAllocatedSoFar(type);
            const receivedRow = table.items.find(r => r.type === 'Received');
            const allocatedRow = table.items.find(r => r.type === 'Allocated');
            const balanceRow = table.items.find(r => r.type === 'Balance');

            // LK Share 비율 계산
            // const lkShareRatio = (this.lkSharePct || 0) / 100;

            // Received 행 업데이트
            if (receivedRow) {
                // receivedRow.TotalAmtLk = (receivedRow.totalAmt || 0) * lkShareRatio;
            }

            // Allocated 행 업데이트
            if (allocatedRow) {
                allocatedRow.lossAmt = null;//allocatedLoss;
                allocatedRow.expAmt = null;//allocatedExpense;
                allocatedRow.totalAmt = null;//allocatedLoss + allocatedExpense;
                allocatedRow.TotalAmtLk = allocatedTotalLK;
            }

            // Balance 행 업데이트
            if (receivedRow && allocatedRow && balanceRow) {
                balanceRow.lossAmt = this._round((receivedRow.lossAmt || 0) - (allocatedRow.lossAmt || 0));
                balanceRow.expAmt = this._round((receivedRow.expAmt || 0) - (allocatedRow.expAmt || 0));
                balanceRow.totalAmt = this._round((receivedRow.totalAmt || 0) - (allocatedRow.totalAmt || 0));
                balanceRow.TotalAmtLk = (receivedRow.TotalAmtLk || 0) - (allocatedRow.TotalAmtLk || 0);
            }

            // 오류 정보 추가
            if (this.summaryErrors && this.summaryErrors[type]) {
                table.error = this.summaryErrors[type];
            } else {
                table.error = null;
            }
        });

        return data;
    }

    get isAllocationDisabled() {
        // 1. Loss Amount가 비어 있거나 0이면 비활성화
        //2. Expense Amount가 비어 있거나 0이면 비활성화
        if (this.amounts.loss == null || this.amounts.loss === '') return true;//|| parseFloat(this.amounts.loss) === 0
        return this.amounts.expense == null || this.amounts.expense === '';// || parseFloat(this.amounts.expense) === 0
    }

    get hasSummaryError() {
        // summaryErrors 객체의 값 중 하나라도 비어있지 않으면 에러 있음
        return Object.values(this.summaryErrors).some(msg => !!msg);
    }

    get isSaveDisabled() {
        // 1. 기본 조건 (로딩 중, 에러 있음)
        if (this.isLoading || this.hasSummaryError) return true;

        // 2. 변경사항 체크
        const hasChanges = this.resultItems.some(item =>
            (!item.isDeleted && String(item.Id).startsWith('tmp_')) ||
            (item.isDeleted && !String(item.Id).startsWith('tmp_'))
        );

        // 변경사항이 없으면 비활성화
        return !hasChanges;
    }
    // Field Labels
    get labelType() { return this.objectInfo?.data?.fields?.ClaimDocType__c?.label || 'Type'; }
    get labelLoss() { return this.objectInfo?.data?.fields?.LossAmt__c?.label || 'Loss Amount'; }
    get labelExpense() { return this.objectInfo?.data?.fields?.ExpAmt__c?.label || 'Expense Amount'; }
    get labelTotal() { return this.objectInfo?.data?.fields?.AllocatedTotalAmt_fm__c?.label || 'Total Amount'; }
    get isAmountDisabled() { return (this.isDisabled || !this.inputType); }
    get hasError() {
        return this.errorMsg?.length > 0;
    }

    get stepValue() {
        const scale = getCurrencyScale(this.claimCurrency, 2);
        if (isNaN(scale)) return 'any';
        return scaleToStep(scale);
    }

    // 📍 5. Wire 메서드
    @wire(getObjectInfo, { objectApiName: CLAIM_OBJECT })
    objectInfo;

    @wire(getRecord, { recordId: '$recordId', fields: [LAST_PLA_FIELD, DOC_TYPE_FIELD] })
    wiredClaim({ data }) {
        if (data && this._init) {
            void this.init();
        }
    }

    // 📍 6. 이벤트 핸들러
    handleInputChange(event) {
        this.inputType = event.detail.value;
        this.summaryErrors[this.inputType] = null;
        this._setDefaultAmounts();
        this.validateCumulativeAmount();
    }

    handleAmountChange(event) {
        const name = event.target.name;
        const val = event.target.value;

        this.amounts = {
            ...this.amounts,
            [name]: val
        };
        
        // 자동 합산 로직 (선택 사항)
        if (name !== 'total') {
            const loss = Number(this.amounts.loss || 0);
            const ex = Number(this.amounts.expense || 0);

            this.amounts = {
                ...this.amounts,
                total: (loss + ex)
            };
            // 입력 즉시 누적 금액 검증
            this.validateCumulativeAmount();
        }
    }

    handleKeyDown(e) {
        // 숫자 입력 필드에서 불필요한 문자(e, +, -) 입력 방지
        const invalidChars = ['e', 'E', '+', '-'];
        if (invalidChars.includes(e.key)) {
            e.preventDefault();
        }
    }

    async handleAllocate() {

        if (!this.validateInput()) return;
        if (!this.validateCumulativeAmount()) {
            toast(this, 'Allocation Failed', 'Please check the errors shown in the summary.', 'error');
            return;
        }

        const grid = this.template.querySelector('c-opp-market-line-manage');
        const selectedPanels = grid.getSelectedRows();

        const newSeq = this._generateNextSeq();
        const lossToAllocate = Number(this.amounts.loss || 0);
        const expenseToAllocate = Number(this.amounts.expense || 0);

        const newItems = selectedPanels.map((panel, index) => {
            const ratio = (panel.Signed__c || 0) / 100;
            const baseTotal = lossToAllocate + expenseToAllocate;
            const riAmount = Math.round(baseTotal * ratio * 100) / 100;

            return this._buildRowItem({
                ...panel,
                Id: `tmp_${newSeq}_${panel.Id}`,
                PanelGroupSeq__c: newSeq,
                ClaimDocType__c: this.inputType,
                LossAmt__c: this._round(lossToAllocate),
                ExpAmt__c: this._round(expenseToAllocate),
                AllocatedTotalAmt_fm__c: this._round(baseTotal),
                TotalAmtForRI__c: riAmount,
                TotalAmtForRISettled__c: (riAmount * (this.fxRateToSettleCurr || 1)).toFixed(2),
                Panel_lk__c: panel.Id,
                Reinsurer_lk__c: panel.Reinsurer_lk__c,
            }, {
                isFirst: index === 0,
                groupSize: selectedPanels.length,
                claimOffset: this._getClaimOffset(panel)
            });
        });

        this.resultItems = [...this.resultItems, ...newItems];
        // this.amounts = { loss: null, expense: null, total: 0 };
        this._setDefaultAmounts();
        if (grid) grid.clearSelection();

        this.summaryErrors = {};
    }

    async handleSave() {
        // 변경사항 체크: 신규 추가(tmp_) 또는 기존 삭제(!tmp_ && isDeleted)
        const hasChanges = this.resultItems.some(item => 
            (!item.isDeleted && String(item.Id).startsWith('tmp_')) || 
            (item.isDeleted && !String(item.Id).startsWith('tmp_'))
        );
        if (!hasChanges) return;

        this.isLoading = true;
        try {
            // 1. 데이터 매핑 (Upsert + Delete 모두 items 리스트로 병합)
            const items = [];

            this.resultItems.forEach(item => {
                // Insert 대상 (신규: tmp_로 시작하는 것만)
                if (!item.isDeleted && String(item.Id).startsWith('tmp_')) {
                    items.push({
                        Claim_md__c: this.recordId,      // Apex Key: Claim_md__c
                        Panel_lk__c: item.panelId,       // Apex Key: Panel_lk__c
                        Type__c: item.ClaimDocType__c,   // Apex Key: Type__c
                        PanelGroupSeq__c: item.PanelGroupSeq__c,
                        LossAmt__c: item.LossAmt__c ? Number(item.LossAmt__c) : null,
                        ExpAmt__c: item.ExpAmt__c ? Number(item.ExpAmt__c) : null,
                        TotalAmtForRI__c: item.TotalAmtForRI__c ? Number(item.TotalAmtForRI__c) : null,
                        Reinsurer_lk__c: item.Reinsurer_lk__c,
                        SignedLine__c: item.SignedLine__c,
                        SettlementCurrency__c: item.SettlementCurrency__c,
                        TotalAmtForRISettled__c: item.TotalAmtForRISettled__c ? Number(item.TotalAmtForRISettled__c) : null,
                        MarketType__c: item.MarketType__c,
                        FacilityMGA_lk__c: item.FacilityMGA_lk__c,
                        isDeleted: false,
                        ClaimOffset_is__c: item.ClaimOffset_is__c || false,
                        claimName: this._claimName || ''
                    });
                } 
                // Delete 대상 (DB에 존재했으나 삭제된 항목)
                else if (item.isDeleted && !String(item.Id).startsWith('tmp_')) {
                    items.push({
                        Id: item.Id,
                        isDeleted: true
                    });
                }
            });

            // 2. Apex 호출
            if (items.length > 0) {

                const hasRemainingAllocation = this.resultItems.some(r => !r.isDeleted);
                const allocationCompleted = hasRemainingAllocation && this.computedSummaryData.every(table => {
                    const received = table.items.find(r => r.type === 'Received');
                    const allocated = table.items.find(r => r.type === 'Allocated');
                    // console.log('🔌🔌🔌🔌🔌🔦🔦 received?.TotalAmtLk.toFixed(2)=', received?.TotalAmtLk.toFixed(2));
                    // console.log('🔌🔌🔌🔌🔌🔦🔦 allocated?.TotalAmtLk.toFixed(2)=', allocated?.TotalAmtLk.toFixed(2));

                    return (received?.TotalAmtLk.toFixed(2) || 0) === (allocated?.TotalAmtLk.toFixed(2) || 0);
                });

                // console.log('🔌🔌🔌🔌🔌🔦🔦 allocationCompleted=', allocationCompleted);
                // console.log('🔌🔌🔌🔌🔌🔦🔦 hasRemainingAllocation=', hasRemainingAllocation);
                // console.log('🔌🔌🔌🔌🔌🔦🔦 this.computedSummaryData.length=', this.computedSummaryData.length);

                await callApex(this, saveAllocation, { recordId: this.recordId, items: items, allocationCompleted: allocationCompleted  });
                
                toast(this, 'Success', 'Saved successfully.', 'success');
                
                // 저장 후 데이터 재조회 및 초기화
                this.resultItems = [];
                // Grid 컴포넌트의 선택 상태 초기화가 필요하다면 여기서 처리
                const grid = this.template.querySelector('c-opp-market-line-manage');
                if (grid) grid.clearSelection();

                await this.init(); // 데이터 갱신
            }
        } catch (err) {
            console.error(err)
        } finally {
            this.isLoading = false;
        }
    }

    handleResultDelete(event) {
        const itemIds = event.detail.ids; // 배열로 받음

        // 1. tmp_로 시작하는 건 배열에서 삭제
        this.resultItems = this.resultItems.filter(item => {
            return !(itemIds.includes(item.Id) && String(item.Id).startsWith('tmp_'));
        });

        // 2. DB 데이터는 isDeleted = true 설정
        this.resultItems = this.resultItems.map(item => {
            if (itemIds.includes(item.Id) && !String(item.Id).startsWith('tmp_')) {
                return { ...item, isDeleted: true };
            }
            return item;
        });
        this.validateCumulativeAmount();
    }

    async handleRefresh() {
        await this.init();
        toast(this, 'Success', 'Data reloaded.', 'success');
        this.validateCumulativeAmount();
    }

    // 📍 7. Private 메서드
    async init() {
        this.isLoading = true;
        try {
            const data = await callApex(this, getRecords, { recordId: this.recordId });
            // console.log('[Claim Allocation Manage] ⭐️⭐️⭐️⭐️⭐️⭐️ getRecords result:', JSON.stringify(data));
            this.summaryData = data?.records || [];
            this.isDisabled = data?.isReadOnly ?? true;
            this.ClaimOptions = data?.claimOptions || [];
            this.lkSharePct = data?.lkSharePct || 0;
            this.fxRateToSettleCurr = data?.fxRateToSettleCurr || 0;
            this.settlementCurrency = data?.settlementCurrency || '';
            this._claimOffsetMap = data?.claimOffsetMap || {};
            this._claimName = data?.claimName || '';
            this.claimCurrency = data?.records?.[0]?.claimCurrency || '';

            const allocations = (data?.clmAllocations || []).map(d => ({
                ...d.allocation,
                ClaimOffset_is__c: d.claimOffset || false
            }));

            // 1. Seq별 개수 계산 (rowSpan용)
            const seqCounts = allocations.reduce((acc, item) => {
                const seq = item.PanelGroupSeq__c;
                acc[seq] = (acc[seq] || 0) + 1;
                return acc;
            }, {});

            const processedSeq = new Set();

            // 2. 데이터 매핑 (handleAllocate 구조와 일치)
            this.resultItems = allocations.map(item => {
                const seq = item.PanelGroupSeq__c;
                const isFirst = !processedSeq.has(seq);
                if (isFirst) processedSeq.add(seq);

                return this._buildRowItem(item, {
                    isFirst,
                    groupSize: seqCounts[seq],
                    claimOffset: item.ClaimOffset_is__c
                });
            });
        } catch (err) {
            this.errorMsg = err?.body?.message || err?.message || 'Unknown error';
            console.error('🔕🔕🔕🔕🔕 error='+ JSON.stringify(err));
        } finally {
            this.isLoading = false;
        }
    }

    validateInput() {
        // 1. Input Fields Validation
        const allValid = [...this.template.querySelectorAll('lightning-input, lightning-combobox')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);

        if (!allValid) {
            return false;
        }

        // 2. Grid Selection Validation
        const grid = this.template.querySelector('c-opp-market-line-manage');
        if (grid.getSelectedRows().length === 0) {
            toast(this, 'Warning', 'Please select target panels.', 'warning');
            return false;
        }
        return true;
    }

    _generateNextSeq() {
        const today = new Date();
        const yy = String(today.getFullYear()).slice(-2);
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const dd = String(today.getDate()).padStart(2, '0');
        const prefix = `${yy}${mm}${dd}`; // 예: 260212

        // 기존 아이템에서 오늘 날짜의 SEQ 중 최대값 찾기
        let maxSeq = 0;
        this.resultItems.forEach(item => {
            if (item.PanelGroupSeq__c && item.PanelGroupSeq__c.startsWith(prefix)) {
                const numPart = parseInt(item.PanelGroupSeq__c.split('-')[1], 10);
                if (!isNaN(numPart) && numPart > maxSeq) {
                    maxSeq = numPart;
                }
            }
        });

        const nextNum = String(maxSeq + 1).padStart(2, '0');
        return `${prefix}-${nextNum}`;
    }

    /**
     * 입력 시 누적 금액을 실시간으로 검증하고 오류 메시지 표시
     */
    validateCumulativeAmount() {
        // 1. Get Received (Limit) amounts for the current type
        const { receivedLoss, receivedExpense, receivedTotal , receivedTotalLK} = this.getReceivedAmounts(this.inputType);
         // console.log('💰💰💰💰💰 receivedTotal=', receivedTotal, ', receivedTotalLK='+ receivedTotalLK);

        // 2. Get already allocated amounts (from DB and current grid) for the current type
        const { allocatedLoss, allocatedExpense, allocatedTotalLK } = this.getAllocatedSoFar(this.inputType);

        // 3. Get the new amounts being entered by the user
        const currentInputLoss = Number(this.amounts.loss || 0);
        const currentInputExpense = Number(this.amounts.expense || 0);
        const currentInputTotal = currentInputLoss + currentInputExpense;

        // 4. Calculate the total share of the new amount across all *selected* panels
        const grid = this.template.querySelector('c-opp-market-line-manage');
        const selectedPanels = grid ? grid.getSelectedRows() : [];

        let newAllocationTotalLK = 0;
        selectedPanels.forEach(panel => {
            const signedPercentage = Number(panel.Signed__c || 0) / 100;
            newAllocationTotalLK += (currentInputTotal * signedPercentage);
        });

        // 5. Calculate the final cumulative amounts
        const cumulativeLoss = allocatedLoss + currentInputLoss;
        const cumulativeExpense = allocatedExpense + currentInputExpense;
        const cumulativeTotalLK = (allocatedTotalLK + newAllocationTotalLK).toFixed(2);

        // 6. Calculate the total LK Share limit
        const lkShareRatio = (this.lkSharePct || 0) / 100;
        // const limitTotalLK = receivedTotal * lkShareRatio;
        const limitTotalLK = receivedTotalLK;// * lkShareRatio;

        // 7. Perform validation and set errors
        const newErrorsForType = {};
        let isValid = true;

        // --- Loss Amount Validation --- 2026-04-10(금) 현업 요청으로 주석처리
        // if (cumulativeLoss > receivedLoss) {
        //     const exceeded = cumulativeLoss - receivedLoss;
        //     newErrorsForType.loss = `Exceeded by ${this.formatCurrency(exceeded)}`;
        //     isValid = false;
        // }
        //
        // // --- Expense Amount Validation --- 2026-04-10(금) 현업 요청으로 주석처리
        // if (cumulativeExpense > receivedExpense) {
        //     const exceeded = cumulativeExpense - receivedExpense;
        //     newErrorsForType.expense = `Exceeded by ${this.formatCurrency(exceeded)}`;
        //     isValid = false;
        // }

        // console.log('⚡️⚡️⚡️⚡️⚡️ allocatedTotalLK=['+ allocatedTotalLK +'], newAllocationTotalLK=['+ newAllocationTotalLK +']');
        // console.log('⚡️⚡️⚡️⚡️⚡️ cumulativeTotalLK=['+ cumulativeTotalLK +'], limitTotalLK=['+ limitTotalLK +']');

        // --- Total LK Share Validation ---
        if (cumulativeTotalLK > limitTotalLK) {
            const exceeded = cumulativeTotalLK - limitTotalLK;
            // console.log('🏠🏠🏠🏠🏠 exceeded=['+ exceeded +']');
            newErrorsForType.totalLK = `Exceeded by ${this.formatCurrency(exceeded)}`;
            isValid = false;
        }

        // 8. Update the error state object
        this.summaryErrors = {
            ...this.summaryErrors,
            [this.inputType]: isValid ? null : newErrorsForType
        };

        //2026-04-10(금) 현업 요청으로 주석처리
        // 9. Update input field validity for immediate user feedback
        // const lossInput = this.template.querySelector('lightning-input[data-id="loss-input"]');
        // if (lossInput) {
        //     lossInput.setCustomValidity(newErrorsForType.loss || '');
        //     lossInput.reportValidity();
        // }
        // const expenseInput = this.template.querySelector('lightning-input[data-id="expense-input"]');
        // if (expenseInput) {
        //     expenseInput.setCustomValidity(newErrorsForType.expense || '');
        //     expenseInput.reportValidity();
        // }
        //2026-04-10(금) 현업 요청으로 주석처리

        // 10. Return the overall validation result
        return isValid;
    }

    getReceivedAmounts(type) {
        const targetType = type || this.inputType;
        const summaryTable = this.summaryData?.find(table => table.type === targetType);
        const receivedItem = summaryTable?.items?.find(item => item.type === 'Received');

        if (!receivedItem) return { receivedLoss: 0, receivedExpense: 0, receivedTotal: 0, receivedTotalLK: 0 };

        const parseValue = (val) => {
            if (typeof val === 'number') return val;
            if (typeof val === 'string') {
                return parseFloat(val.replace(/,/g, '')) || 0;
            }
            return 0;
        };

        return {
            receivedLoss: parseValue(receivedItem.lossAmt),
            receivedExpense: parseValue(receivedItem.expAmt),
            receivedTotal: parseValue(receivedItem.totalAmt),
            receivedTotalLK: parseValue(receivedItem.TotalAmtLk)
        };
    }

    getAllocatedSoFar(type) {
        const uniqueItemsMap = {};
        let totalAllocatedLK = 0;

        const relevantItems = this.resultItems.filter(item =>
            !item.isDeleted && item.ClaimDocType__c === type
        );

        totalAllocatedLK = relevantItems.reduce((sum, item) => {
            return sum + Number(item.TotalAmtForRI__c || 0);
        }, 0);

        relevantItems.forEach(item => {
            if (item.PanelGroupSeq__c && !uniqueItemsMap[item.PanelGroupSeq__c]) {
                uniqueItemsMap[item.PanelGroupSeq__c] = item;
            }
        });

        const { allocatedLoss, allocatedExpense } = Object.values(uniqueItemsMap).reduce((acc, item) => {
            acc.allocatedLoss += Number(item.LossAmt__c || 0);
            acc.allocatedExpense += Number(item.ExpAmt__c || 0);
            return acc;
        }, { allocatedLoss: 0, allocatedExpense: 0 });

        return {
            allocatedLoss: allocatedLoss,
            allocatedExpense: allocatedExpense,
            allocatedTotalLK: totalAllocatedLK
        };
    }

    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: this.settlementCurrency || 'USD' }).format(value);
    }

    /**
     * Allocation 행 → UI 표시용 객체 변환
     * @param {Object} item - allocation 또는 panel 데이터
     * @param {Object} options - { isFirst, groupSize, claimOffset }
     */
    _buildRowItem(item, { isFirst, groupSize, claimOffset = false }) {

        let facilityId = null;
        let facilityName = null;
        let marketType = null;

        if (item.Facility_lk__c) {
            marketType = 'Facility';
            facilityId = item.Facility_lk__c;
            facilityName = item.Facility_lk__r?.Name;
        } else if (item.MGAName_lk__c) {
            marketType = 'MGA';
            facilityId = item.MGAName_lk__c;
            facilityName = item.MGAName_lk__r?.Name;
        }

        return {
            ...item,
            panelId: item.Panel_lk__c || item.Id,
            reinsurerName: item.Reinsurer_lk__r?.Name,
            reinsurerUrl: item.Reinsurer_lk__c ? `/lightning/r/${item.Reinsurer_lk__c}/view` : null,
            facilityUrl: facilityId ? `/lightning/r/${facilityId}/view` : null,
            facilityName: facilityName,
            IssueDate_fm__c: item.IssueDate_fm__c,
            ClaimOffset_is__c: claimOffset,
            MarketType__c: marketType || item.MarketType__c,
            FacilityMGA_lk__c: facilityId,
            SettlementCurrency__c: this.settlementCurrency,
            SignedLine__c: item.SignedLine__c || item.Signed__c,
            rowSpan: isFirst ? groupSize : 0,
            isFirstInGroup: isFirst,
            isSelected: false
        };
    }

    _getClaimOffset(panel) {
        if (panel.MarketType__c !== 'Facility' || !panel.Facility_lk__c) return false;
        const key = panel.Facility_lk__c + '_' + panel.Reinsurer_lk__c;
        return this._claimOffsetMap[key] || false;
    }

    _setDefaultAmounts() {
        const { receivedLoss, receivedExpense } = this.getReceivedAmounts(this.inputType);
        this.amounts = {
            loss: receivedLoss || 0,
            expense: receivedExpense || 0,
            total: (receivedLoss || 0) + (receivedExpense || 0)
        };
    }

    _round(value, scale) {
        value = Math.round(value * 100)/100;
        return parseFloat((value || 0).toFixed(scale ?? getCurrencyScale(this.claimCurrency, 2)));
    }

    // 📍 8. 라이프사이클 메서드
    connectedCallback() {
        if(this._init) return;

        const style = document.createElement('style');
        style.innerText = `.cus-lk-input-right input { text-align: right !important; }`;
        document.body.appendChild(style);

        void this.init();

        this._init = true;
    }


}