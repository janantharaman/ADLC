/**********************************************************************************
 * @filename      : Account_tr.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-01-30 (금)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : Account_tr_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-01-30      i2max     Create
**********************************************************************************/
public with sharing class Account_tr extends TriggerHandler {

    // 1. 값 초기화는 Before에서
    public override void beforeUpdate() {
//        this.clearGeoInfoIfAddressRemoved(Trigger.new, Trigger.oldMap);
    }

    // 2. API 호출은 After에서
    public override void afterInsert() {
//        this.syncGeoLocation(Trigger.new, null);
    }

    public override void afterUpdate() {
//        this.syncGeoLocation(Trigger.new, Trigger.oldMap);
    }


//    private void clearGeoInfoIfAddressRemoved(List<SObject> newList, Map<Id, SObject> oldMap) {
//
//        System.debug('>>>>>>>>>>>>> clearGeoInfoIfAddressRemoved');
//        for (Account newObj : (List<Account>) newList) {
//            Account oldObj = (Account) oldMap.get(newObj.Id);
//            if (newObj.AddrStreet__c <> oldObj.AddrStreet__c) {
//                if (String.isBlank(newObj.AddrStreet__c)) {
//                    newObj.OfficeAddress__PostalCode__s = null;
//                    newObj.OfficeAddress__Street__s = null;
//                    newObj.OfficeAddress__GeocodeAccuracy__s = null;
//                    newObj.OfficeAddress__City__s = null;
//                    newObj.OfficeAddress__Longitude__s = null;
//                    newObj.OfficeAddress__Latitude__s = null;
////                        newObj.OfficeAddress__c = null;
//                    newObj.OfficeAddress__CountryCode__s = null;
//                    newObj.OfficeAddress__StateCode__s = null;
//
//                }
//            }
//        }
//    }
/*
    private void syncGeoLocation(List<SObject> newList, Map<Id, SObject> oldMap) {

        Set<Id> acctIds = new Set<Id>();
        Account oldObj;
        Boolean isUpdate = !(oldMap == null || oldMap.isEmpty());
        System.debug('>>>>>>>>>>>>> isUpdate=' + isUpdate);

        for(Account newObj : (List<Account>) newList) {
            if (isUpdate) oldObj = (Account) oldMap.get(newObj.Id);
            if ((oldMap.isEmpty() && String.isNotBlank(newObj.AddrStreet__c)) || (isUpdate && (newObj.AddrStreet__c <> oldObj.AddrStreet__c && newObj.OfficeAddress__c == oldObj.OfficeAddress__c))) {
                if (oldMap.isEmpty()) acctIds.add(newObj.Id);
                if (!oldMap.isEmpty() && String.isNotBlank(newObj.AddrStreet__c)) {
                    acctIds.add(newObj.Id);
                }
            }
        }
        System.debug('>>>>>>>>>>>>> acctIds=' + acctIds);

        if(!acctIds.isEmpty()) {
            System.debug('>>>>>>>>>>>>> acctIds=' + acctIds);
            COM_GoogleMapService.updateGeoInfoAsync(acctIds);
        }
    }*/




}