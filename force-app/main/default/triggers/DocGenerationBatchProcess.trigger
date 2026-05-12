trigger DocGenerationBatchProcess on DocGenerationBatchProcess(after update) {
    new DocGenBatchProcess_tr().run();
}