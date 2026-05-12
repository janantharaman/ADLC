import { LightningElement, api, track } from "lwc";

import apexGetOffsetSlis from "@salesforce/apex/REC_ReverseOffsetCtrl.getOffsetSlis";

import { roundByCurrency } from "c/recUtils";

export default class RecReverseOffset extends LightningElement {
    @api recordId;

    // ── Table Data ───────────────────────────────────────────────────────
    @track offsetSliData = [];

    // ── Lifecycle ────────────────────────────────────────────────────────
    connectedCallback() {
        this.getOffsetSlis();
    }

    // ── Computed Properties ──────────────────────────────────────────────
    get displayRowCount() {
        return this.offsetSliData?.length || 0;
    }

    // ── Data Loading ─────────────────────────────────────────────────────
    async getOffsetSlis() {
        try {
            const offsetSlis = await apexGetOffsetSlis({ reconId: this.recordId });
            this.offsetSliData = offsetSlis || [];
        } catch (error) {
            console.error("Failed to load offset SLIs", error);
        }
    }

    // ── Column Definitions ──────────────────────────────────────
    offsetSliColumns = [
        {
            label: "SLI No.",
            name: "Name",
            type: "url",
            config: {
                idField: "Id"
            }
        },
        {
            label: "SLI Details",
            name: "header_SliDetails",
            columns: [
                {
                    label: "Closing Type",
                    name: "ClosingType__c"
                },
                {
                    label: "COA",
                    name: "COA_lk__c",
                    type: "record-picker",
                    disabled: true,
                    config: {
                        objectApiName: "COA__c",
                        labelField: "Name"
                    }
                },
                {
                    label: "COA Name",
                    name: "COAName_fm__c"
                },
                {
                    label: "Account Name",
                    name: "AccountName__c",
                    type: "record-picker",
                    disabled: true,
                    config: {
                        objectApiName: "Account",
                        labelField: "Name"
                    }
                },
                {
                    label: "Origin Currency",
                    name: "OriginCurrency__c"
                },
                {
                    label: "Origin Amount",
                    name: "OriginAmount__c",
                    type: "currency",
                    config: {
                        ccyField: "OriginCurrency__c"
                    }
                }
            ]
        },
        {
            label: "Settlement Details",
            name: "header_SettlementDetails",
            columns: [
                {
                    label: "Settlement Date",
                    name: "SettlementDate__c",
                    type: "date"
                },
                {
                    label: "Settlement Currency",
                    name: "SettlementCurrency__c"
                },
                {
                    label: "FX Rate (to Settlement)",
                    name: "FXRateOrigintoSettlement__c",
                    type: "number"
                },
                {
                    label: "Settlement Amount (SLI)",
                    name: "SettlementAmountSLI__c",
                    type: "currency",
                    config: {
                        ccyField: "SettlementCurrency__c"
                    }
                },
                {
                    label: "Other Charges",
                    name: "OtherCharges__c",
                    type: "currency",
                    config: {
                        ccyField: "SettlementCurrency__c"
                    }
                },
                {
                    label: "Settlement Amount (TTL)",
                    name: "SettlementAmountTTL__c",
                    type: "currency",
                    config: {
                        ccyField: "SettlementCurrency__c"
                    }
                },
                {
                    label: "Settlement Type",
                    name: "SettlementType__c"
                },
                {
                    label: "Settlement Status",
                    name: "SettlementStatus__c"
                },
                {
                    label: "Settlement Date (Counterparty)",
                    name: "SettlementDateCounterparty__c",
                    type: "date"
                },
                {
                    label: "Remittance On Hold",
                    name: "RemittanceOnHold__c",
                    type: "boolean",
                    disabled: true
                },
                {
                    label: "Hold Reason",
                    name: "HoldReason__c"
                }
            ]
        },
        {
            label: "Exchange Details",
            name: "header_ExchangeDetails",
            columns: [
                {
                    label: "Exchange Date",
                    name: "ExchangeDate__c",
                    type: "date"
                },
                {
                    label: "Exchange Currency",
                    name: "ExchangeCurrency__c"
                },
                {
                    label: "Exchange Amount",
                    name: "ExchangeAmount__c",
                    type: "currency",
                    config: {
                        ccyField: "ExchangeCurrency__c"
                    }
                },
                {
                    label: "Exchange Rate",
                    name: "ExchangeRate__c",
                    type: "number"
                }
            ]
        }
    ];
}