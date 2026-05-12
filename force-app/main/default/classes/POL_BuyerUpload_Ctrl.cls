/**********************************************************************************
 * @filename      : POL_BuyerUpload_Ctrl.cls
 * @project-name  : LK보험중계_신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-02-05
 * @group         :
 * @group-content :
 * @description   : POL Buyer 엑셀 업로드 처리 및 필드 메타데이터 조회를 담당하는 컨트롤러
 * @test-class    :
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-02-05      i2max            Create
 **********************************************************************************/
public with sharing class POL_BuyerUpload_Ctrl {
    
    // ============================================================
    // Methods
    // ============================================================
    
    /**
     * @description POL_Buyer__c 오브젝트의 업로드 대상 필드 메타데이터를 조회한다.
     * @param 없음
     * @return Map<String, Object> 필드별 라벨, 타입, 필수 여부, 길이, Picklist 값 등을 포함한 메타데이터
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getBuyerFieldMetadata() {
        Map<String, Object> result = new Map<String, Object>();
        
        try {
            // Get POL_Buyer__c object describe
            Schema.SObjectType objType = Schema.getGlobalDescribe().get('POL_Buyer__c');
            
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            
            // Fields to get metadata for (based on Excel headers)
            List<String> targetFields = new List<String>{
                'CompanyName__c',
                'InternatinoalBizName__c',
                'EasyNo__c',
                'Address__c',
                'Town__c',
                'Postcode__c',
                'StateCountry__c',
                'CountryName__c',
                'CountryCode__c',
                'Phone__c',
                'BuyerNo__c',
                'LeagalIdentType1__c',
                'LegalIdentValue1__c',
                'LeagalIdentType2__c',
                'LegalIdentValue2__c',
                'LeagalIdentType3__c',
                'LegalIdentValue3__c',
                'Product__c',
                'UserId__c',
                'ContractNo__c',
                'ContractType__c',
                'PolicyHolder__c',
                'RatingNotation__c',
                'RequestDate__c',
                'CustDebtorRef__c',
                'AmountAsked__c',
                'CurrencyAmtAsked__c',
                'MinShipAmt__c',
                'MinShpCurr__c',
                'ModeOfPay__c',
                'DecisionDate__c',
                'DecisionStatus__c',
                'DecisionType__c',
                'Decision1__c',
                'Decision2__c',
                'Decision3__c',
                'EffectDate__c',
                'EndDate__c',
                'AmtAgreed__c',
                'CurrAmtAgreed__c',
                'GrntReq1__c',
                'GrntReq2__c',
                'GrntReq3__c',
                'GrntProvied1__c',
                'GrntProvied2__c',
                'GrntProvied3__c',
                'DecisionComment__c',
                'InsuredPct__c',
                'DRA__c',
                'NA__c',
                'OperationLabel__c',
                'OperationNo__c',
                'FavoriteCompany__c',
                'CustRef__c',
                'OutstandingAmt__c',
                'InternalCreditLimit__c'
            };
            
            for (String fieldName : targetFields) {
                if (fieldMap.containsKey(fieldName)) {
                    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                    
                    Map<String, Object> fieldInfo = new Map<String, Object>();
                    fieldInfo.put('label', fieldDescribe.getLabel());
                    fieldInfo.put('type', String.valueOf(fieldDescribe.getType()));
                    fieldInfo.put('required', !fieldDescribe.isNillable());
                    fieldInfo.put('length', fieldDescribe.getLength());
                    fieldInfo.put('precision', fieldDescribe.getPrecision());
                    fieldInfo.put('scale', fieldDescribe.getScale());
                    
                    // Get picklist values if applicable
                    if (
                        fieldDescribe.getType() == Schema.DisplayType.PICKLIST ||
                        fieldDescribe.getType() == Schema.DisplayType.MULTIPICKLIST
                    ) {
                        List<Map<String, String>> picklistValues = new List<Map<String, String>>();
                        for (Schema.PicklistEntry entry : fieldDescribe.getPicklistValues()) {
                            if (entry.isActive()) {
                                Map<String, String> valueMap = new Map<String, String>();
                                valueMap.put('label', entry.getLabel());
                                valueMap.put('value', entry.getValue());
                                picklistValues.add(valueMap);
                            }
                        }
                        fieldInfo.put('picklistValues', picklistValues);
                    }
                    
                    result.put(fieldName, fieldInfo);
                }
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error getting field metadata: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description POL Buyer 데이터를 키 우선순위 기준으로 신규 또는 수정 저장한다.
     * @param buyers 업로드 대상 Buyer 데이터 목록
     * @return String 저장 결과 메시지
     */
    @AuraEnabled
    public static String savePOLBuyers(List<Map<String, Object>> buyers) {
        try {
            if (buyers == null || buyers.isEmpty()) {
                throw new AuraHandledException('No buyers to save');
            }
            
            // Verify POL_Buyer__c object exists
            Schema.SObjectType objType = Schema.getGlobalDescribe().get('POL_Buyer__c');
            
            // Get field metadata for type conversion
            Schema.DescribeSObjectResult objDescribe = objType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = objDescribe.fields.getMap();
            
            // Key field priority order
            List<String> keyFieldPriority = new List<String>{
                'EasyNo__c',
                'BuyerNo__c',
                'LegalIdentValue1__c',
                'LegalIdentValue2__c',
                'LegalIdentValue3__c'
            };
            
            // History tracking field mapping (current -> old)
            Map<String, String> historyFieldMap = new Map<String, String>{
                'RequestDate__c' => 'RequestDateOld__c',
                'AmountAsked__c' => 'AmtAskedOld__c',
                'CurrencyAmtAsked__c' => 'CurrencyAmtAskedOld__c',
                'MinShipAmt__c' => 'MinShipAmtOld__c',
                'MinShpCurr__c' => 'MinShpCurrOld__c',
                'EffectDate__c' => 'EffectDateOld__c',
                'EndDate__c' => 'EndDateOld__c',
                'AmtAgreed__c' => 'AmtAgreedOld__c',
                'CurrAmtAgreed__c' => 'CurrAmtAgreedOld__c',
                'OutstandingAmt__c' => 'OutstandingAmtOld__c',
                'InternalCreditLimit__c' => 'InternalCreditLimitOld__c'
            };
            
            // Use Map to prevent duplicate IDs in the upsert list
            Map<Id, SObject> buyersToUpsertMap = new Map<Id, SObject>();
            List<SObject> newBuyersToInsert = new List<SObject>();
            Integer insertCount = 0;
            Integer updateCount = 0;
            
            for (Map<String, Object> buyerData : buyers) {
                Id policyId = null;
                
                // Get Policy ID
                if (buyerData.containsKey('Policy_lk__c')) {
                    policyId = (Id) buyerData.get('Policy_lk__c');
                }
                
                SObject buyer = null;
                
                // Collect all available key values
                Map<String, Object> keyValues = new Map<String, Object>();
                for (String keyField : keyFieldPriority) {
                    if (buyerData.containsKey(keyField) && buyerData.get(keyField) != null) {
                        Object value = buyerData.get(keyField);
                        if (value instanceof String && ((String) value).trim() != '') {
                            keyValues.put(keyField, ((String) value).trim());
                        } else if (!(value instanceof String) && value != null) {
                            keyValues.put(keyField, value);
                        }
                    }
                }
                
                // Try to find existing record using all available key fields
                if (!keyValues.isEmpty() && policyId != null) {
                    // Build dynamic query to check all key fields
                    List<String> conditions = new List<String>();
                    Map<String, Object> bindVars = new Map<String, Object>();
                    bindVars.put('policyId', policyId);
                    
                    Integer keyIndex = 0;
                    for (String keyField : keyFieldPriority) {
                        if (keyValues.containsKey(keyField)) {
                            String bindVar = 'keyValue' + keyIndex;
                            conditions.add(keyField + ' = :' + bindVar);
                            bindVars.put(bindVar, keyValues.get(keyField));
                            keyIndex++;
                        }
                    }
                    
                    if (!conditions.isEmpty()) {
                        // Build field list including history tracking fields
                        Set<String> fieldsToQuery = new Set<String>{ 'Id' };
                        fieldsToQuery.addAll(keyValues.keySet());
                        fieldsToQuery.addAll(historyFieldMap.keySet());
                        fieldsToQuery.addAll(historyFieldMap.values());
                        
                        // Build query with OR conditions for all key fields
                        String query =
                            'SELECT ' +
                            String.join(new List<String>(fieldsToQuery), ', ') +
                            ' FROM POL_Buyer__c WHERE Policy_lk__c = :policyId AND (' +
                            String.join(conditions, ' OR ') +
                            ')';
                        
                        // Execute dynamic query with bind variables
                        List<SObject> existingBuyers = Database.queryWithBinds(query, bindVars, AccessLevel.USER_MODE);
                        
                        if (!existingBuyers.isEmpty()) {
                            // If multiple records match, select the one with highest priority key match
                            SObject selectedBuyer = null;
                            Integer highestPriority = keyFieldPriority.size();
                            
                            for (SObject existingBuyer : existingBuyers) {
                                for (Integer i = 0; i < keyFieldPriority.size(); i++) {
                                    String keyField = keyFieldPriority[i];
                                    if (keyValues.containsKey(keyField)) {
                                        Object existingValue = existingBuyer.get(keyField);
                                        Object newValue = keyValues.get(keyField);
                                        
                                        if (
                                            existingValue != null &&
                                            newValue != null &&
                                            String.valueOf(existingValue) == String.valueOf(newValue)
                                        ) {
                                            if (i < highestPriority) {
                                                highestPriority = i;
                                                selectedBuyer = existingBuyer;
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if (selectedBuyer != null) {
                                buyer = selectedBuyer;
                            }
                        }
                    }
                }
                
                // If no existing record found, create new one
                if (buyer == null) {
                    buyer = objType.newSObject();
                }
                
                // Set InsurancePolicy lookup
                if (policyId != null) {
                    buyer.put('Policy_lk__c', policyId);
                }
                
                // History tracking: Save current values to Old fields before updating
                Id buyerId = (Id) buyer.get('Id');
                if (buyerId != null) {
                    for (String currentField : historyFieldMap.keySet()) {
                        String oldField = historyFieldMap.get(currentField);
                        
                        if (buyerData.containsKey(currentField) && buyerData.get(currentField) != null) {
                            Object currentValue = buyer.get(currentField);
                            Object newValue = buyerData.get(currentField);
                            
                            Boolean valuesAreDifferent = false;
                            
                            if (fieldMap.containsKey(currentField)) {
                                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(currentField).getDescribe();
                                Schema.DisplayType fieldType = fieldDescribe.getType();
                                
                                if (fieldType == Schema.DisplayType.DATE) {
                                    Date currentDate = (currentValue instanceof Date) ? (Date) currentValue : null;
                                    Date newDate = null;
                                    
                                    if (newValue instanceof Date) {
                                        newDate = (Date) newValue;
                                    } else if (newValue instanceof String) {
                                        try {
                                            newDate = Date.valueOf((String) newValue);
                                        } catch (Exception e) {
                                            valuesAreDifferent = true;
                                        }
                                    }
                                    
                                    if (currentDate != null && newDate != null) {
                                        valuesAreDifferent = (currentDate != newDate);
                                    }
                                } else if (
                                fieldType == Schema.DisplayType.DOUBLE ||
                                    fieldType == Schema.DisplayType.CURRENCY ||
                                    fieldType == Schema.DisplayType.PERCENT
                                ) {
                                    Decimal currentDecimal = null;
                                    Decimal newDecimal = null;
                                    
                                    if (currentValue instanceof Decimal) {
                                        currentDecimal = (Decimal) currentValue;
                                    } else if (currentValue instanceof Integer) {
                                        currentDecimal = Decimal.valueOf((Integer) currentValue);
                                    } else if (currentValue instanceof String) {
                                        try {
                                            currentDecimal = Decimal.valueOf((String) currentValue);
                                        } catch (Exception e) {
                                        }
                                    }
                                    
                                    if (newValue instanceof Decimal) {
                                        newDecimal = (Decimal) newValue;
                                    } else if (newValue instanceof Integer) {
                                        newDecimal = Decimal.valueOf((Integer) newValue);
                                    } else if (newValue instanceof String) {
                                        try {
                                            newDecimal = Decimal.valueOf((String) newValue);
                                        } catch (Exception e) {
                                        }
                                    }
                                    
                                    if (currentDecimal != null && newDecimal != null) {
                                        valuesAreDifferent = (currentDecimal != newDecimal);
                                    }
                                } else {
                                    String curStr = (currentValue == null) ? null : String.valueOf(currentValue).trim();
                                    String newStr = (newValue == null) ? null : String.valueOf(newValue).trim();
                                    valuesAreDifferent = (curStr != newStr);
                                }
                            } else {
                                String curStr = (currentValue == null) ? null : String.valueOf(currentValue).trim();
                                String newStr = (newValue == null) ? null : String.valueOf(newValue).trim();
                                valuesAreDifferent = (curStr != newStr);
                            }
                            
                            System.debug(
                                'History Tracking - Field: ' +
                                currentField +
                                ', Current Value: ' +
                                currentValue +
                                ', New Value: ' +
                                newValue +
                                ', Different: ' +
                                valuesAreDifferent
                                );
                            
                            if (valuesAreDifferent && currentValue != null) {
                                buyer.put(oldField, currentValue);
                            }
                        }
                    }
                }
                
                // Set all fields dynamically
                for (String fieldName : buyerData.keySet()) {
                    if (fieldName != 'Policy_lk__c' && buyerData.get(fieldName) != null) {
                        Object value = buyerData.get(fieldName);
                        
                        if (value instanceof String && ((String) value).trim() != '') {
                            String strValue = ((String) value).trim();
                            
                            if (fieldMap.containsKey(fieldName)) {
                                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                                Schema.DisplayType fieldType = fieldDescribe.getType();
                                
                                if (fieldType == Schema.DisplayType.DATE) {
                                    buyer.put(fieldName, Date.valueOf(strValue));
                                } else if (fieldType == Schema.DisplayType.DATETIME) {
                                    buyer.put(fieldName, DateTime.valueOf(strValue.replace('T', ' ').replace('Z', '')));
                                } else {
                                    buyer.put(fieldName, strValue);
                                }
                            } else {
                                buyer.put(fieldName, strValue);
                            }
                        } else if (value instanceof Decimal || value instanceof Double || value instanceof Integer) {
                            buyer.put(fieldName, value);
                        } else if (value instanceof Date) {
                            buyer.put(fieldName, value);
                        }
                    }
                }
                
                // Add to appropriate collection based on whether it has an Id
                buyerId = (Id) buyer.get('Id');
                if (buyerId != null) {
                    buyersToUpsertMap.put(buyerId, buyer);
                } else {
                    newBuyersToInsert.add(buyer);
                }
            }
            
            // Combine all records for upsert
            List<SObject> allBuyersToUpsert = new List<SObject>();
            allBuyersToUpsert.addAll(buyersToUpsertMap.values());
            allBuyersToUpsert.addAll(newBuyersToInsert);
            
            if (!allBuyersToUpsert.isEmpty()) {
                upsert allBuyersToUpsert;
            }
            
            // Calculate actual counts after deduplication
            updateCount = buyersToUpsertMap.size();
            insertCount = newBuyersToInsert.size();
            
            String resultMessage = 'Successfully saved ' + allBuyersToUpsert.size() + ' buyer(s)';
            if (insertCount > 0 && updateCount > 0) {
                resultMessage += ' (' + insertCount + ' inserted, ' + updateCount + ' updated)';
            } else if (insertCount > 0) {
                resultMessage += ' (' + insertCount + ' inserted)';
            } else if (updateCount > 0) {
                resultMessage += ' (' + updateCount + ' updated)';
            }
            
            return resultMessage;
        } catch (DmlException e) {
            throw new AuraHandledException('DML Error: ' + e.getDmlMessage(0));
        } catch (Exception e) {
            throw new AuraHandledException('Error saving buyers: ' + e.getMessage());
        }
    }
}