/**
 * @description       : Account Depositor Mapping modal for BT Inquiry page.
 * @author            : shkang
 * @last modified on  : 2026-04-01
 * @last modified by  : shkang
 **/
import { api } from "lwc";
import LightningModal from "lightning/modal";
import Toast from "lightning/toast";

import apexSaveAccountDepositorMapping from "@salesforce/apex/REC_BTInquiryCtrl.saveAccountDepositorMapping";
import apexFindByDepositor from "@salesforce/apex/REC_BTInquiryCtrl.findAccountDepositorByDepositor";
import apexUpdateBTAccountName from "@salesforce/apex/REC_BTInquiryCtrl.updateBankTransactionAccountName";

export default class AccountMapping extends LightningModal {
    /** The selected BankTransaction row */
    @api btRecord = {};

    /** Pre-queried AccountDepositor records (may be empty) */
    @api existingDepositors = [];

    _depositor = null;
    _accountNameId = null;
    _remarks = "";
    _updateScope = "None";
    _isSaving = false;
    _isAutoMatched = false;
    _autoMatchedAccountNameId = null;
    _isConnectedDone = false;
    _isFormLoaded = false;

    async connectedCallback() {
        try {
            if (this.btRecord?.Depositor__c && !this.btRecord?.AccountName__c) {
                const result = await apexFindByDepositor({
                    bizRegion: this.btRecord.BizRegion__c,
                    depositorName: this.btRecord.Depositor__c
                });
                if (result.found) {
                    this._isAutoMatched = true;
                    this._autoMatchedAccountNameId = result.accountNameId;
                }
            }
        } catch (error) {
            console.error("findAccountDepositorByDepositor error:", error);
        } finally {
            this._isConnectedDone = true;
        }
    }

    get isLoading() {
        if (this._isSaving) return true;
        if (this.hasExisting) return false;
        return !this._isConnectedDone || !this._isFormLoaded;
    }

    get hasExisting() {
        return this.existingDepositors && this.existingDepositors.length > 0;
    }

    get depositorValue() {
        return this.btRecord?.Depositor__c || "";
    }

    get accountNameId() {
        if (this._isAutoMatched) return this._autoMatchedAccountNameId;
        return this.btRecord?.AccountName__c || null;
    }

    get isAutoMatched() {
        return this._isAutoMatched;
    }

    get isDepositorDisabled() {
        return this._isAutoMatched || !!this.btRecord?.Depositor__c;
    }

    get isAccountNameDisabled() {
        return this._isAutoMatched || !!this.btRecord?.AccountName__c;
    }

    get showFormContainer() {
        return !this.hasExisting;
    }

    get formVisibilityClass() {
        return this.isLoading ? "slds-hide" : "";
    }

    handleFormLoad() {
        this._isFormLoaded = true;
    }

    get isFieldDisabled() {
        return this._isAutoMatched;
    }

    get showSaveButton() {
        return !this.hasExisting;
    }

    handleDepositorChange(event) {
        this._depositor = event.target.value;
    }

    handleAccountNameChange(event) {
        this._accountNameId = event.target.value;
    }

    handleRemarksChange(event) {
        this._remarks = event.target.value;
    }

    handleUpdateScopeChange(event) {
        this._updateScope = event.target.value;
    }

    handleCancelClick() {
        this.close();
    }

    async handleSaveClick() {
        if (this._isSaving) return;
        this._isSaving = true;

        try {
            if (this._isAutoMatched) {
                await apexUpdateBTAccountName({
                    bankTransactionId: this.btRecord.Id,
                    accountNameId: this._autoMatchedAccountNameId
                });
                Toast.show(
                    {
                        label: "Success",
                        message: "Bank Transaction Account Name updated from existing mapping.",
                        variant: "success"
                    },
                    this
                );
            } else {
                const result = await apexSaveAccountDepositorMapping({
                    bizRegion: this.btRecord.BizRegion__c,
                    depositorName: this._depositor ?? this.btRecord.Depositor__c,
                    accountNameId: this._accountNameId ?? this.btRecord.AccountName__c,
                    remarks: this._remarks,
                    updateScope: this._updateScope,
                    bankTransactionId: this.btRecord.Id
                });

                if (result.isExisting) {
                    const recordUrl = `/lightning/r/AccountDepositor__c/${result.recordId}/view`;
                    Toast.show(
                        {
                            label: "Existing Mapping Used",
                            message: "An existing Account-Depositor mapping was found and updated. {0}",
                            messageData: [
                                {
                                    url: recordUrl,
                                    label: "Open Account Depositor"
                                }
                            ],
                            variant: "info",
                            mode: "sticky"
                        },
                        this
                    );
                } else {
                    Toast.show(
                        {
                            label: "Success",
                            message: "New Account-Depositor mapping created successfully.",
                            variant: "success"
                        },
                        this
                    );
                }
            }

            this.close("OK");
        } catch (error) {
            console.error("Save Account Depositor error:", error);
            Toast.show(
                {
                    label: "Error",
                    message: error.body?.message || error?.message || "An unexpected error occurred.",
                    variant: "error"
                },
                this
            );
        } finally {
            this._isSaving = false;
        }
    }
}