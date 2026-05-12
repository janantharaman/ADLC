import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import recalculateExchangeRateByPeriod from "@salesforce/apex/ExchangeRateService.recalculateExchangeRateByPeriod";

export default class RecalculateFxByPeriodButton extends LightningElement {
    @api recordId;

    @api
    async invoke() {
        try {
            await recalculateExchangeRateByPeriod({
                periodCloseId: this.recordId
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Exchange Rates recalculation has started in the background.",
                    variant: "success"
                })
            );

            // Refresh the record page
            eval("$A.get('e.force:refreshView').fire()");
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Error",
                    message: error.body?.message || "An error occurred while recalculating.",
                    variant: "error"
                })
            );
        }
    }
}