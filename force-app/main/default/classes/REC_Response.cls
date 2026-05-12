/**
 * REC_Response — Unified AuraEnabled response wrapper.
 *
 * Every @AuraEnabled method in the REC module returns this single shape,
 * so the LWC layer can handle inquiry / save / action results with one
 * consistent pattern:
 *
 *   const res = await someApexCall({ … });
 *   if (res.success) {
 *       this.rows = res.data;
 *   } else {
 *       // toast res.message  &&  table.setCellErrors(res.cellErrors)
 *   }
 */
public inherited sharing class REC_Response {
    @AuraEnabled
    public Boolean success;
    @AuraEnabled
    public Object data;
    @AuraEnabled
    public String message;
    @AuraEnabled
    public Integer successCount;
    @AuraEnabled
    public Integer errorCount;
    @AuraEnabled
    public List<REC_TableHelper.CellError> cellErrors;

    // ═════════════════════════════════════════════════════════════════════════
    //  Factory Methods
    // ═════════════════════════════════════════════════════════════════════════

    /** Successful result carrying arbitrary data. */
    public static REC_Response ok(Object data) {
        REC_Response r = new REC_Response();
        r.success = true;
        r.data = data;
        return r;
    }

    /** Failure with a human-readable message (no cell errors). */
    public static REC_Response fail(String message) {
        REC_Response r = new REC_Response();
        r.success = false;
        r.message = message;
        return r;
    }

    /**
     * Wraps a TableHelper.SaveResponse, optionally carrying refreshed data.
     *
     * @param sr            SaveResponse from REC_UnitOfWork.updatePartial()
     * @param refreshedData (nullable) re-queried rows the UI should display
     */
    public static REC_Response fromSave(REC_TableHelper.SaveResponse sr, Object refreshedData) {
        REC_Response r = new REC_Response();
        r.success = sr.success;
        r.successCount = sr.successCount;
        r.errorCount = sr.errorCount;
        r.cellErrors = sr.cellErrors;
        r.data = refreshedData;
        return r;
    }

    /**
     * Wraps pre-validated cell errors (before DML) as a failure response.
     */
    public static REC_Response fromValidation(List<REC_TableHelper.CellError> errors) {
        REC_Response r = new REC_Response();
        r.success = false;
        r.successCount = 0;
        r.errorCount = errors.size();
        r.cellErrors = errors;
        return r;
    }
}