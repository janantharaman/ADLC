trigger FiduciaryOthers on FiduciaryOthers__c(before update) {
    new FiduciaryOthers_tr().run();
}