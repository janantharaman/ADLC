public class UpdateRelatedExchangeRateQueueable implements Queueable {
    private ExchangeRateService.ExchangeRateContext ctx;
    private Integer stepIndex;

    public UpdateRelatedExchangeRateQueueable(ExchangeRateService.ExchangeRateContext ctx) {
        this(ctx, 0);
    }

    public UpdateRelatedExchangeRateQueueable(ExchangeRateService.ExchangeRateContext ctx, Integer stepIndex) {
        this.ctx = ctx;
        this.stepIndex = stepIndex;
    }

    public void execute(QueueableContext context) {
        Logger.setScenario('UpdateRelatedExchangeRateQueueable');
        Logger.info('ctx :: ' + this.ctx);
        Logger.info('stepIndex :: ' + this.stepIndex);
        try {
            ExchangeRateService.executeRelatedObjectExchangeRateFields(this.ctx, this.stepIndex);
        } catch (Exception e) {
            Logger.error(e.getMessage() + ' :: ' + e.getStackTraceString());
        } finally {
            Logger.saveLog();
        }
    }
}