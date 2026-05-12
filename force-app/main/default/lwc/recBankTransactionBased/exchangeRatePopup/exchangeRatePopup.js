import LightningModal from "lightning/modal";
import { api, track } from "lwc";

export default class ExchangeRatePopup extends LightningModal {
    @api baseCurrency;
    @track _settlements = [];

    @track fxRates = {};

    @api
    get settlements() {
        return this._settlements;
    }

    set settlements(value) {
        this._settlements = value.map((item) => {
            const fxRate = item.fxRate || 0;
            const settlementAmount = fxRate ? (item.OriginAmount__c || 0) * fxRate : 0;
            return {
                ...item,
                fxRate,
                settlementAmount
            };
        });
    }

    _isNotAvailable(settlement) {
        return settlement.SettlementStatus__c === "Not-Available";
    }

    _isBaseCurrency(settlement) {
        return settlement.OriginCurrency__c === this.baseCurrency;
    }

    renderedCallback() {
        const table = this.refs.fxTable;
        if (!table) return;
        this._settlements.forEach((s) => {
            if (this._isBaseCurrency(s) || !this._isNotAvailable(s)) {
                table.setCellDisabled(s.OriginCurrency__c, "fxRate", true);
            }
        });
    }

    get isRateEditable() {
        return this._settlements.some((s) => this._isNotAvailable(s));
    }

    get applyBtnDisabled() {
        return this._settlements.filter((s) => this._isNotAvailable(s) && !this._isBaseCurrency(s)).some((s) => !s.fxRate);
    }

    get tableColumns() {
        return [
            {
                label: "Origin Currency",
                name: "OriginCurrency__c"
            },
            {
                label: "Origin Amount",
                name: "OriginAmount__c",
                type: "currency",
                config: { ccyField: "OriginCurrency__c" }
            },
            {
                label: "Settlement Amount",
                name: "settlementAmount",
                type: "currency"
            },
            {
                label: "FX Rate (Origin to Settlement)",
                name: "fxRate",
                type: "number",
                editable: this.isRateEditable
            }
        ];
    }

    handleCancelClick() {
        this.close();
    }

    handleApplyClick() {
        const fxRates = this._settlements
            .filter((s) => this._isNotAvailable(s))
            .reduce((acc, s) => {
                acc[s.OriginCurrency__c] = s.fxRate;
                return acc;
            }, {});

        this.close(fxRates);
    }

    handleFxRateChange(event) {
        const fxRate = parseFloat(event.detail.value, 10);
        const currency = event.target.name;

        this.fxRates[currency] = fxRate;
    }

    handleCellChange(event) {
        const { rowId, fieldName, value } = event.detail;
        const parsedValue = parseFloat(value, 10);

        const idx = this._settlements.findIndex((s) => s.OriginCurrency__c === rowId);
        if (idx === -1) {
            return;
        }

        // store the new rate
        this._settlements[idx] = {
            ...this._settlements[idx],
            [fieldName]: parsedValue
        };

        if (fieldName === "fxRate") {
            // recalc the settlement amount
            const originAmt = this._settlements[idx].OriginAmount__c || 0;
            this._settlements[idx].settlementAmount = parsedValue ? originAmt * parsedValue : 0;
        }

        this._settlements = [...this._settlements];
    }
}