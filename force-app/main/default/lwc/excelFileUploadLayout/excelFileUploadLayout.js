/**
 * @group        : Trestle
 * @description  :
 * @author       : Yugon Hwang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2026-02-23   Yugon Hwang   Initial Version
 **/
import { LightningElement } from "lwc";
import tabNameUploadFXRate from "@salesforce/label/c.COM_UPLOAD_FX_RATE";
import tabNameUploadBankTransaction from "@salesforce/label/c.COM_UPLOAD_BANK_TRANSACTION";

export default class ExcelFileUploadLayout extends LightningElement {
    label = {
        tabNameUploadFXRate,
        tabNameUploadBankTransaction
    };
}