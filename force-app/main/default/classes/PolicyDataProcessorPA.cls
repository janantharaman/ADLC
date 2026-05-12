public class PolicyDataProcessorPA {
    
    // --- 1. Flow Input & Output Wrappers ---
    public class FlowInput { 
        @InvocableVariable(label='Policy Data JSON' required=true)
        public String jsonString; 
        
        @InvocableVariable(label='Master Insurance Policy ID' required=true)
        public Id insurancePolicyId;
    }

    public class FlowOutput {
        @InvocableVariable(label='Is Success')
        public Boolean isSuccess;
        @InvocableVariable(label='Error Message')
        public String errorMessage;
        @InvocableVariable(label='Processed Master Policy ID')
        public Id processedPolicyId;
        @InvocableVariable(label='Debug Log')
        public String debugLog; 

        public FlowOutput() {
            this.isSuccess = true;
            this.errorMessage = '';
            this.debugLog = '';
        }
    }

    // --- 2. JSON Structure Classes ---
    public class GroupRecord { @InvocableVariable @AuraEnabled public String GroupName; }
    
    public class PolicyRecord {
        @InvocableVariable @AuraEnabled public String Name;
        @InvocableVariable @AuraEnabled public String LKRefNo;            
        @InvocableVariable @AuraEnabled public String Notes;              
        @InvocableVariable @AuraEnabled public List<String> MasterCoverageList; 
        @InvocableVariable @AuraEnabled public String CurrencyVal;
        @InvocableVariable @AuraEnabled public List<ParticipantRecord> participants;
        @InvocableVariable @AuraEnabled public List<GroupRecord> groups;
        @InvocableVariable @AuraEnabled public List<CoverageRecord> coverages;
    }
    
    public class ParticipantRecord { 
        @InvocableVariable @AuraEnabled public String ParticipantName; 
        @InvocableVariable @AuraEnabled public String Role;
    }
    
    public class CoverageRecord {
        @InvocableVariable @AuraEnabled public String LinkedGroupName;
        @InvocableVariable @AuraEnabled public String LinkedParticipantName;
        @InvocableVariable @AuraEnabled public String PolicyNumber;       
        @InvocableVariable @AuraEnabled public Date EffectiveFromDate;    
        @InvocableVariable @AuraEnabled public Date EffectiveToDate;      
        @InvocableVariable @AuraEnabled public Decimal CoveragePremiumAmount; 
        @InvocableVariable @AuraEnabled public Decimal CommissionRate;        
        @InvocableVariable @AuraEnabled public Decimal CommissionAmount;      
        @InvocableVariable @AuraEnabled public List<LineItemRecord> coverageLineItems;
    }
    
    public class LineItemRecord {
        @InvocableVariable @AuraEnabled public String Risk_Name;
        @InvocableVariable @AuraEnabled public Decimal Risk_Insured_Amount;
    }

    // --- Main Logic ---
    @InvocableMethod(label='Process Group Master Policy OCR' description='Account Name Based Mapping with Console Debugging')
    public static List<FlowOutput> createRecords(List<FlowInput> inputs) {
        
        List<FlowOutput> results = new List<FlowOutput>();
        String superLog = '\n\n========== [초정밀 디버그 시작] ==========\n';
        superLog += '실행 시간: ' + Datetime.now() + '\n';

        for (Integer i = 0; i < inputs.size(); i++) {
            FlowInput input = inputs[i];
            FlowOutput output = new FlowOutput();
            
            try {
                superLog += '--- [인덱스 ' + i + '] 프로세스 시작 ---\n';
                superLog += 'Master Policy ID: ' + input.insurancePolicyId + '\n';
                
                output.processedPolicyId = input.insurancePolicyId;
                PolicyRecord rec = (PolicyRecord) JSON.deserialize(input.jsonString, PolicyRecord.class);
                superLog += '1. JSON 파싱 성공!\n';
                
                String lookupFieldApi = 'EGIMasterPolicy_lk__c';  
                String carrierFieldApi = 'WritingCarrierAccount.Name'; 
                String carrierAccountIdFieldApi = 'WritingCarrierAccountId'; 
                
                String queryStr = 'SELECT Id, ' + lookupFieldApi + ', ' + carrierFieldApi + ', ' + carrierAccountIdFieldApi + ' FROM InsurancePolicy WHERE ' + lookupFieldApi + ' = \'' + input.insurancePolicyId + '\'';
                List<InsurancePolicy> childPolicies = Database.query(queryStr);
                superLog += '2. DB 조회 완료 (Child 개수: ' + childPolicies.size() + '개)\n';
                
                Map<String, Id> childCarrierMap = new Map<String, Id>();
                Map<String, Id> childCarrierAccountMap = new Map<String, Id>();
                
                for (InsurancePolicy child : childPolicies) {
                    SObject accountObj = child.getSObject('WritingCarrierAccount');
                    if (accountObj != null) {
                        String accName = (String) accountObj.get('Name'); 
                        Id accountId = (Id) child.get(carrierAccountIdFieldApi);
                        
                        if (String.isNotBlank(accName)) {
                            // 1. Account Name 원본 등록
                            childCarrierMap.put(accName.toLowerCase().trim(), child.Id);
                            childCarrierAccountMap.put(accName.toLowerCase().trim(), accountId);
                            
                            // 2. Account Name에서 대괄호 영역 제거 후 유연한 매핑 등록
                            String strippedEngName = accName.replaceAll('\\[.*?\\]', '').trim();
                            if (String.isNotBlank(strippedEngName)) {
                                childCarrierMap.put(strippedEngName.toLowerCase(), child.Id);
                                childCarrierAccountMap.put(strippedEngName.toLowerCase(), accountId);
                                superLog += '   👉 Account Name 매핑 후보: 원본[' + accName + '] / 괄호제거[' + strippedEngName + ']\n';
                            }
                        }
                    }
                }
                
                List<InsurancePolicyCoverage> allChildCoverages = new List<InsurancePolicyCoverage>();
                Map<Id, InsurancePolicy> childPoliciesToUpdate = new Map<Id, InsurancePolicy>();

                if (rec.coverages != null) {
                    for (CoverageRecord c : rec.coverages) {
                        Id childPolicyId = null;
                        Id carrierAccountId = null;
                        
                        if (String.isNotBlank(c.LinkedParticipantName)) {
                            String targetName = c.LinkedParticipantName.toLowerCase().trim();
                            childPolicyId = childCarrierMap.get(targetName);
                            carrierAccountId = childCarrierAccountMap.get(targetName);
                        }
                        
                        if (childPolicyId == null) {
                            superLog += '   🚨 매핑 실패 (해당 Account Name 없음): [' + c.LinkedParticipantName + ']\n';
                            continue;
                        }
                        superLog += '   ✅ 매핑 성공: [' + c.LinkedParticipantName + ']\n';
                        
                        // 🌟 1. Child Policy 업데이트 기록
                        InsurancePolicy childUpdate = childPoliciesToUpdate.containsKey(childPolicyId) ? childPoliciesToUpdate.get(childPolicyId) : new InsurancePolicy(Id = childPolicyId);
                        
                        if (c.EffectiveFromDate != null) childUpdate.put('EffectiveFromDate', c.EffectiveFromDate);
                        if (c.EffectiveToDate != null) childUpdate.put('EffectiveToDate', c.EffectiveToDate);
                        
                        childPoliciesToUpdate.put(childPolicyId, childUpdate);
                        
                        // 🌟 2. 일반 Coverage 생성 기록
                        if (c.coverageLineItems != null) {
                            for(LineItemRecord item : c.coverageLineItems) {
                                InsurancePolicyCoverage cov = new InsurancePolicyCoverage();
                                
                                cov.InsurancePolicyId = childPolicyId; 
                                cov.put('EGIMasterPolicy_lk__c', input.insurancePolicyId); 
                                
                                if (carrierAccountId != null) {
                                    cov.put('EGIInsurer_lk__c', carrierAccountId);
                                }
                                
                                cov.put('EGIGroupInsurance_is__c', true);
                                cov.put('EGIGroupName__c', c.LinkedGroupName);
                                cov.put('EGIInsuranceCoverage__c', item.Risk_Name);
                                cov.put('EGIInsuredAmount__c', item.Risk_Insured_Amount);
                                allChildCoverages.add(cov);
                            }
                        }
                    }
                }
                
                // 🌟 3. 마스터 폴리시용 통합 Coverage 레코드 생성
                if (rec.MasterCoverageList != null && !rec.MasterCoverageList.isEmpty()) {
                    String joinedRiskNames = String.join(rec.MasterCoverageList, ', ');
                    
                    InsurancePolicyCoverage masterCov = new InsurancePolicyCoverage();
                    masterCov.InsurancePolicyId = input.insurancePolicyId; 
                    masterCov.put('EGIMasterCoverages__c', joinedRiskNames.abbreviate(30000)); 
                    
                    allChildCoverages.add(masterCov);
                }
                
                superLog += '\n4. DML Insert/Update 준비 상태\n';
                superLog += '   - 생성할 Coverage 레코드 수: ' + allChildCoverages.size() + '개\n';
                superLog += '   - 업데이트할 Child Policy 수: ' + childPoliciesToUpdate.size() + '개\n';
                
                Savepoint sp = Database.setSavepoint();
                try {
                    if (!allChildCoverages.isEmpty()) insert allChildCoverages;
                    if (!childPoliciesToUpdate.isEmpty()) update childPoliciesToUpdate.values();
                    
                    InsurancePolicy pUpdate = new InsurancePolicy(Id = input.insurancePolicyId);
                    pUpdate.put('IS_OCR_Lineitem_Complted__c', true);
                    pUpdate.put('IsOCRComplated__c', true);
                    if (String.isNotBlank(rec.Notes)) pUpdate.put('Remark__c', rec.Notes);      
                    update pUpdate;
                    
                    output.isSuccess = true;
                    superLog += '🎉 모든 데이터 DML(Insert/Update) 완료!\n';
                    
                } catch (Exception dmlEx) {
                    Database.rollback(sp);
                    superLog += '❌ [DML ERROR] ' + dmlEx.getMessage() + '\n';
                    output.isSuccess = false;
                    output.errorMessage = dmlEx.getMessage();
                }
            } catch (Exception ex) {
                superLog += '❌ [PROCESS ERROR] ' + ex.getMessage() + '\n';
                output.isSuccess = false;
                output.errorMessage = ex.getMessage();
            }
            
            superLog += '========== [초정밀 디버그 종료] ==========\n';
            output.debugLog = superLog; 
            
            // 🚨 콘솔로 디버깅 출력 (이메일 발송 대체)
            System.debug(LoggingLevel.INFO, '🔍 PolicyDataProcessorPA Debug Log:\n' + superLog);
            
            results.add(output);
        }
        
        return results;
    }
}