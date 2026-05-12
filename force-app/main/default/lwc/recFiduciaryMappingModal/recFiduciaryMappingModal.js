/**
 * @description       : Mapping modal used in BT Inquiry page.
 * @author            : Akrom Saidkamolov
 * @last modified on  : 2026-03-23
 * @last modified by  : Akrom Saidkamolov
 **/
import { api, track } from "lwc";
import LightningModal from "lightning/modal";
import Toast from "lightning/toast";

import apexCreateFiduciaryOthers from "@salesforce/apex/REC_BTInquiryCtrl.createFiduciaryOthers";
import apexValidateTransactions from "@salesforce/apex/REC_BTInquiryCtrl.validateTransactionsForFiduciaryOthers";

export default class RecFiduciaryMappingModal extends LightningModal {
    @api btRecords = [];
    @track tableData = [];
    @track errors = {};

    connectedCallback() {
        this.tableData = this.btRecords.map((bt, index) => ({
            rowNumber: index + 1,
            TransactionDate__c: bt.TransactionDate__c,
            SettlementCurrency__c: bt.Currency__c,
            OriginAmount__c: bt.NetBalanceAftCleared__c,
            Depositor__c: bt.Depositor__c,
            AccountName__c: bt.AccountName__c,
            RefBankTransaction__c: bt.Id,
            Remarks__c: ""
        }));

        this.setErrors();
    }

    async setErrors() {
        try {
            this.errors = await apexValidateTransactions({ transactionIds: this.btRecords.map((bt) => bt.Id) });

            const errorEntries = Object.entries(this.errors).filter(([, message]) => message);
            if (errorEntries.length === 0) return;

            this.refs.table.setCellErrors(
                errorEntries.map(([rowId, message]) => ({
                    rowId,
                    fieldName: "RefBankTransaction__c",
                    message
                }))
            );

            // Disable Remarks__c for rows that have errors
            errorEntries.forEach(([btId]) => {
                const row = this.tableData.find((r) => r.RefBankTransaction__c === btId);
                if (row) {
                    this.refs.table.setCellDisabled(row.RefBankTransaction__c, "Remarks__c", true);
                }
            });
        } catch (error) {
            console.error(error);
            Toast.show(
                {
                    label: "Error validating transactions",
                    message: error.body?.message || error?.message || "An unexpected error occurred.",
                    variant: "error"
                },
                this
            );
        }
    }

    /****************************************
     * Event Handlers                       *
     ****************************************/
    handleCancelClick() {
        this.close();
    }

    async handleSaveClick() {
        try {
            const enabledRows = this.tableData.filter((row) => !this.errors[row.RefBankTransaction__c]);
            await apexCreateFiduciaryOthers({ records: enabledRows });

            Toast.show(
                {
                    label: "Processing completed. Please review the results.",
                    message: `Total: ${this.tableData.length} || Created: ${enabledRows.length} || Errors: ${this.tableData.length - enabledRows.length}`,
                    variant: "info",
                    mode: "dismissible"
                },
                this
            );
            this.close("OK");
        } catch (error) {
            console.error("Error saving fiduciary mapping:", error);
            Toast.show(
                {
                    label: "Failed to save fiduciary others",
                    message: error.body?.message || error?.message || "An unexpected error occurred.",
                    variant: "error"
                },
                this
            );
        }
    }

    handleCellChange(event) {
        const { rowId, fieldName, value, oldValue } = event.detail;
        console.log(`Cell changed — row:${rowId} field:${fieldName} ${oldValue} → ${value}`);
        const rowIndex = this.tableData.findIndex((row) => row.RefBankTransaction__c === rowId);

        if (rowIndex !== -1) {
            this.tableData[rowIndex][fieldName] = value;
        }
    }

    tableColumns = [
        {
            label: "No.",
            name: "rowNumber"
        },
        {
            label: "Transaction Date",
            name: "TransactionDate__c",
            type: "date"
        },
        {
            label: "Settlement Currency",
            name: "SettlementCurrency__c"
        },
        {
            label: "Origin Amount",
            name: "OriginAmount__c",
            type: "currency",
            config: { ccyField: "SettlementCurrency__c" }
        },
        {
            label: "Depositor",
            name: "Depositor__c"
        },
        {
            label: "Account Name",
            name: "AccountName__c",
            type: "record-picker",
            disabled: true,
            config: {
                objectApiName: "Account",
                labelField: "Name",
                placeholder: "Search Account..."
            }
        },
        {
            label: "Ref. Bank Transaction",
            name: "RefBankTransaction__c",
            type: "record-picker",
            disabled: true,
            config: {
                objectApiName: "BankTransaction__c",
                labelField: "Name",
                placeholder: "Search Bank Transaction..."
            }
        },
        {
            label: "Remarks",
            name: "Remarks__c",
            editable: true
        }
    ];
}