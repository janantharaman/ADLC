/**********************************************************************************
 * @filename       : oppSlipInfoRIClosingModal.js
 * @project-name  : LK보험중개_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-06 (금)
 * @group         :
 * @group-content :
 * @description   : OPP_SlipInfo 상세 페이지에서 RI Closing Slip 버튼 눌렀을 때 실행되는 LWC 컴포넌트
 *                  - RI Closing 관련 필드들의 Diff 검증 수행 (validateDiff)
 *                  - 필수 필드 값 확인
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date             author            description
 * ===================================================================
 * 1.0   2026-02-06     i2max      Create
 **********************************************************************************/

import {LightningElement, api, wire} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import confirmAndGenerate from '@salesforce/apex/OPP_SlipInfoRIClosingModal_Ctrl.confirmAndGenerate'
import validateDiff from '@salesforce/apex/OPP_SlipInfoRIClosingModal_Ctrl.validateDiff';

export default class OppSlipInfoRIClosingModal extends LightningElement {
    @api recordId;
    isLoading = false;
    isValidated = false;

    _validationStarted = false;

    compareTarget = '';
    mismatchFields = [];

    showOmniScript = false;

    /**
     * @description CurrentPageReference에서 recordId 추출 및 초기화
     * @param {CurrentPageReference} pageRef 페이지 참조 정보
     */
    @wire(CurrentPageReference)
    wiredPageRef(pageRef) {
        if (this.recordId) return;
        const rid =
            pageRef?.state?.recordId ||
            pageRef?.attributes?.recordId ||
            null;

        if (rid) {
            this.recordId = rid;
        }
    }

    /**
     * @description 컴포넌트 렌더링 후 최초 1회 Validation 실행
     */
    renderedCallback() {
        if (this._validationStarted) return;
        if (!this.recordId) {
            return;
        }

        this._validationStarted = true;
        this.runValidation();
    }

    /**
     * @description mismatch 여부 반환
     * @returns {boolean}
     */
    get hasMismatch() {
        return this.mismatchFields && this.mismatchFields.length > 0;
    }

    /**
     * @description Confirm 버튼 비활성화 여부 반환
     * @returns {boolean}
     */
    get isConfirmDisabled() {
        return this.isLoading || this.hasMismatch;
    }

    /**
     * @description 모달 취소 (닫기)
     */
    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }

    /**
     * @description Aura/Apex 에러 메시지 파싱 (header / detail 분리)
     * @param {object} error Apex 에러 객체
     * @returns {{header: string, detail: string}}
     */
    parseAuraMessage(error) {
        const raw =
            error?.body?.message ||
            error?.message ||
            '';

        let header = raw;
        let detail = '';

        if (raw.includes('||')) {
            const parts = raw.split('||');
            header = parts[0] || raw;
            detail = parts[1] || '';
        }

        return { header, detail };
    }

    /**
     * @description RI Closing Diff 검증 수행
     *  - mismatch 필드 및 대상 객체 세팅
     *  - 에러 발생 시 메시지 파싱 후 Toast 표시
     * @returns {Promise<void>}
     */
    async runValidation() {
        this.isLoading = true;

        try {
            const result = await validateDiff({ slipInfoId: this.recordId });

            this.compareTarget = result?.targetObject || '';
            this.mismatchFields = result?.mismatchFields || [];

            this.isValidated = true;

        } catch (e) {
            console.error(e);

            // 불일치하는 경우 에러 메시지 발생 + 모달 Close
            const { header, detail } = this.parseAuraMessage(e);

            this.mismatchFields = detail ? [...detail.split(',')] : [];

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: header,
                    variant: 'error'
                })
            );
        } finally {
            this.isLoading = false;
            this.isValidated = true;
        }
    }

    /**
     * @description Confirm 클릭 시 Doc 생성 실행
     *  - 성공 시 OmniScript 표시
     *  - 실패 시 mismatch 필드 파싱 및 경고 표시
     * @returns {Promise<void>}
     */
    async handleConfirm() {
        this.isLoading = true;
        this.mismatchFields = [];

        try {
            await confirmAndGenerate({slipInfoId: this.recordId});

            this.showOmniScript = true;

        } catch (error) {

            const raw =
                error?.body?.message ||
                error?.message ||
                '';

            let header = '';
            let detail = '';

            if (raw.includes('||')) {
                const parts = raw.split('||');
                header = parts[0];
                detail = parts[1];
            } else {
                header = raw;
            }

            if (detail) {
                this.mismatchFields = [...detail.split(',')];
            } else {
                this.mismatchFields = [];
            }

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Validation Error',
                    message: header,
                    variant: 'warning'
                })
            );
        }  finally {
            this.isLoading = false;
        }
    }

    /**
     * @description OmniScript 초기 데이터(JSON) 생성
     * @returns {string}
     */
    get seedDataJson() {
        return JSON.stringify({
            ContextId: this.recordId,
            ObjectType: 'OPP_SlipInfo__c'
        });
    }

    /**
     * @description OmniScript 완료 후 처리
     *  - 성공 Toast 표시
     *  - 모달 종료
     * @param {CustomEvent} event OmniScript 완료 이벤트
     */
    handleOmniComplete(event) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'Document generated successfully.',
                variant: 'success'
            })
        );

        this.dispatchEvent(new CloseActionScreenEvent());
    }
}