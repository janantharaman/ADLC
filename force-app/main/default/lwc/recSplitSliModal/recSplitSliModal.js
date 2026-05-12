/**
 * @description       :
 * @author            : Akrom Saidkamolov
 * @last modified on  : 2026-04-09
 * @last modified by  : Akrom Saidkamolov
 **/
import { api } from "lwc";
import LightningModal from "lightning/modal";
import LightningConfirm from "lightning/confirm";
import Toast from "lightning/toast";
import LOCALE from "@salesforce/i18n/locale";

import apexSplitSettlementLineItem from "@salesforce/apex/REC_SLIInquiryCtrl.splitSettlementLineItem";
import apexCheckSplitConditions from "@salesforce/apex/REC_SLIInquiryCtrl.checkSplitConditions";
import { getDecimalPoint, roundByCurrency } from "c/recUtils";

import SPLIT_INVALID_SIGN from "@salesforce/label/c.REC_MSG_SPLIT_INVALID_SIGN";
import SPLIT_INVALID_TOTAL from "@salesforce/label/c.REC_MSG_SPLIT_INVALID_TOTAL";
import SPLIT_AMOUNT_ZERO from "@salesforce/label/c.REC_MSG_SPLIT_AMOUNT_ZERO";
import SPLIT_CHECK_COND_ERR from "@salesforce/label/c.REC_MSG_SPLIT_CHECK_COND_ERR";
import SPLIT_EXECUTE_ERR from "@salesforce/label/c.REC_MSG_SPLIT_EXECUTE_ERR";

export default class RecSplitSliModal extends LightningModal {
    @api settlementLineItem = {};
    amount1 = 0;
    amount2 = 0;
    isLoading = false;
    errorMessage;

    get currency() {
        return this.settlementLineItem?.OriginCurrency__c;
    }

    get totalAmount() {
        return this.settlementLineItem?.OriginAmount__c || 0;
    }

    get decimalPoint() {
        return getDecimalPoint(this.currency);
    }

    get hasDecimalError() {
        return (
            roundByCurrency(this.amount1, this.currency) !== this.amount1 ||
            roundByCurrency(this.amount2, this.currency) !== this.amount2
        );
    }

    get saveBtnDisabled() {
        return this.errorMessage || this.hasDecimalError;
    }

    get cancelBtnLabel() {
        return this.errorMessage ? "OK" : "Cancel";
    }

    get cancelBtnVariant() {
        return this.errorMessage ? "brand" : "neutral";
    }

    connectedCallback() {
        this.amount1 = roundByCurrency(this.totalAmount / 2, this.currency);
        this.amount2 = roundByCurrency(this.totalAmount - this.amount1, this.currency);

        this.checkSplitConditions();
    }

    async checkSplitConditions() {
        try {
            this.isLoading = true;
            await apexCheckSplitConditions({ sliId: this.settlementLineItem.Id });
        } catch (error) {
            this.errorMessage = error.body?.message || error?.message || SPLIT_CHECK_COND_ERR;
        } finally {
            this.isLoading = false;
        }
    }

    /**********************
     * Event Handlers     *
     **********************/
    handleAmount1Change(event) {
        this.amount1 = parseFloat(event.detail.value) || 0;
        this.amount2 = roundByCurrency(this.totalAmount - this.amount1, this.currency);
    }

    handleAmount2Change(event) {
        this.amount2 = parseFloat(event.detail.value) || 0;
        this.amount1 = roundByCurrency(this.totalAmount - this.amount2, this.currency);
    }

    handleCancelClick() {
        this.close();
    }

    async handleSaveClick() {
        try {
            if (
                Math.sign(this.amount1) !== Math.sign(this.totalAmount) ||
                Math.sign(this.amount2) !== Math.sign(this.totalAmount)
            ) {
                throw new Error(SPLIT_INVALID_SIGN);
            }

            if (this.amount1 + this.amount2 !== this.totalAmount) {
                throw new Error(SPLIT_INVALID_TOTAL);
            }

            if (this.amount1 === 0 || this.amount2 === 0) {
                throw new Error(SPLIT_AMOUNT_ZERO);
            }

            const fmt = new Intl.NumberFormat(LOCALE, {
                style: "currency",
                currency: this.currency,
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            });
            const confirmed = await LightningConfirm.open({
                label: "Confirm Split",
                message: `Are you sure you want to split this Settlement Line Item into ${fmt.format(this.amount1)} and ${fmt.format(this.amount2)}? Please be aware that you cannot revert this action.`,
                theme: "warning"
            });

            if (!confirmed) return;

            this.isLoading = true;

            await apexSplitSettlementLineItem({
                recordId: this.settlementLineItem.Id,
                amount1: this.amount1,
                amount2: this.amount2
            });

            this.close("OK");
        } catch (error) {
            Toast.show(
                {
                    label: error?.message || error?.body?.message || SPLIT_EXECUTE_ERR,
                    variant: "error"
                },
                this
            );
        } finally {
            this.isLoading = false;
        }
    }
}