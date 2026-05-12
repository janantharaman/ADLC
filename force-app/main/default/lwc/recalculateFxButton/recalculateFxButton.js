import { LightningElement, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import recalculateExchangeRate from "@salesforce/apex/ExchangeRateService.recalculateExchangeRate";

export default class RecalculateFxButton extends LightningElement {
    @api recordId;

    @api
    async invoke() {
        try {
            await recalculateExchangeRate({
                recordId: this.recordId
            });

            this.dispatchEvent(
                new ShowToastEvent({
                    title: "Success",
                    message: "Exchange Rate has been recalculated.",
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