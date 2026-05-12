/**********************************************************************************
 * @filename      : OPP_PremiumSchedule_Ctrl.cls
 * @project-name  : LK Insurance Services
 * @author        : i2max
 * @date          : 2025-12-10(수)
 * @group         : Opportunity
 * @group-content :
 * @description   : Premium Schedule 데이터 조회 및 저장을 처리하는 컨트롤러
 * @test-class    : OPP_PremiumScheduleCtrl_ts.cls
 * @reference     :
 * @copyright     :
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-12-10      i2max            Create
 **********************************************************************************/
public with sharing class Opp_PremiumSchedule_Ctrl {
    
    // ============================================================
    // Methods
    // ============================================================
    
    /**
     * @description 객체 타입과 편집 권한 정보를 조회한다.
     * @param recordId Opportunity 또는 Placement__c 레코드 Id
     * @return InitMetaWrapper 초기 메타 정보
     */
    @AuraEnabled(cacheable=true)
    public static InitMetaWrapper getInitMeta(Id recordId) {
        try {
            InitMetaWrapper w = new InitMetaWrapper();
            if (String.isBlank(recordId))
                return w;
            String objectName = COM_MetaUtil.getObjectNameById(recordId);
            w.isPlacement = 'Placement__c'.equalsIgnoreCase(objectName);
            w.hasEditPermission = COM_MetaUtil.checkEditPermission(recordId);
            return w;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading init meta: ' + e.getMessage());
        }
    }
    
    /**
     * @description Opportunity 또는 Placement 기준의 Premium Schedule 데이터를 조회한다.
     * @param recordId Opportunity 또는 Placement__c 레코드 Id
     * @param premCurrency Premium Currency 값
     * @return OpportunityScheduleWrapper Premium Schedule 조회 결과
     */
    @AuraEnabled(cacheable=false)
    public static OpportunityScheduleWrapper getOpportunityScheduleData(Id recordId, String premCurrency) {
        try {
            if (recordId == null) {
                throw new AuraHandledException('Record ID is required');
            }
            
            String objectName = COM_MetaUtil.getObjectNameById(recordId);
            Boolean isPlacement = 'Placement__c'.equalsIgnoreCase(objectName);
            
            Opportunity opp;
            List<OPP_PremiumSchedule__c> schedules;
            Date placementClosingDate;
            
            if (isPlacement) {
                Placement__c placement = [
                    SELECT Opportunity_lk__c, PlacementClosingDate__c
                    FROM Placement__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                Id oppId = placement.Opportunity_lk__c;
                placementClosingDate = placement.PlacementClosingDate__c;
                
                List<Opportunity> opps = [
                    SELECT Id, PeriodFrom__c, Name, IsClosed
                    FROM Opportunity
                    WHERE Id = :oppId
                    LIMIT 1
                ];
                if (opps.isEmpty()) {
                    throw new AuraHandledException('Opportunity record not found');
                }
                opp = opps[0];
                
                schedules = [
                    SELECT Id, Name, DaysFromInception__c, Percentage__c, InstallDate_fm__c, PaymentType__c
                    FROM OPP_PremiumSchedule__c
                    WHERE Placement_lk__c = :recordId AND Prem_Currency__c = :premCurrency AND Type__c != 'Slip'
                    ORDER BY DaysFromInception__c ASC NULLS LAST, CreatedDate ASC
                ];
            } else {
                List<Opportunity> opps = [
                    SELECT Id, PeriodFrom__c, Name, IsClosed
                    FROM Opportunity
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                if (opps.isEmpty()) {
                    throw new AuraHandledException('Opportunity record not found');
                }
                opp = opps[0];
                
                schedules = [
                    SELECT Id, Name, DaysFromInception__c, Percentage__c, InstallDate_fm__c, PaymentType__c
                    FROM OPP_PremiumSchedule__c
                    WHERE Opportunity_lk__c = :recordId AND Prem_Currency__c = :premCurrency AND Type__c != 'Slip'
                    ORDER BY DaysFromInception__c ASC NULLS LAST, CreatedDate ASC
                ];
            }
            
            OpportunityScheduleWrapper wrapper = new OpportunityScheduleWrapper();
            wrapper.opportunityId = opp.Id;
            wrapper.opportunityName = COM_Util.nvl(opp.Name, '');
            wrapper.periodFrom = opp.PeriodFrom__c;
            wrapper.isClosed = isPlacement ? placementClosingDate != null : COM_Util.nvl(opp.IsClosed, false);
            
            // 레코드 개수 = totalInstalls
            wrapper.totalInstalls = schedules.size();
            
            wrapper.schedules = new List<PremiumScheduleItem>();
            for (OPP_PremiumSchedule__c schedule : schedules) {
                PremiumScheduleItem item = new PremiumScheduleItem();
                item.id = schedule.Id;
                item.daysFromInception = schedule.DaysFromInception__c != null ? Integer.valueOf(schedule.DaysFromInception__c) : null;
                item.percentage = schedule.Percentage__c != null ? schedule.Percentage__c : null;
                item.installDate = schedule.InstallDate_fm__c;
                wrapper.schedules.add(item);
            }
            
            System.debug('getOpportunityScheduleData - Currency: ' + premCurrency + ', Total Installs: ' + wrapper.totalInstalls);
            
            return wrapper;
        } catch (Exception e) {
            throw new AuraHandledException('Error loading data: ' + e.getMessage());
        }
    }
    
    /**
     * @description Premium Schedule 데이터를 저장한다.
     * @param recordId Opportunity 또는 Placement__c 레코드 Id
     * @param premCurrency Premium Currency 값
     * @param paymentType Payment Type 값
     * @param grossPrem Gross Premium 값 (Treaty Install 타입에서 SlipGrossPrem__c에 저장)
     * @param schedules 저장할 Premium Schedule 데이터 목록
     * @return String 저장 결과 메시지
     */
    @AuraEnabled
    public static String savePremiumSchedules(Id recordId, String premCurrency, String paymentType, Decimal grossPrem, List<Map<String, Object>> schedules) {
        System.debug('===== savePremiumSchedules START =====');
        System.debug('recordId: ' + recordId);
        System.debug('premCurrency: ' + premCurrency);
        System.debug('paymentType: ' + paymentType);
        System.debug('schedules: ' + JSON.serializePretty(schedules));
        
        try {
            if (recordId == null) {
                System.debug('ERROR: Record ID is null');
                throw new AuraHandledException('Record ID is required');
            }
            
            if (schedules == null || schedules.isEmpty()) {
                System.debug('ERROR: Schedules is null or empty');
                throw new AuraHandledException('At least one schedule is required');
            }
            
            // Opp_PremiumFromCedent_Ctrl 패턴: oppId / placementId 분리
            String objectName = COM_MetaUtil.getObjectNameById(recordId);
            Boolean isPlacement = 'Placement__c'.equalsIgnoreCase(objectName);
            
            Id oppId = recordId;
            Id placementId;
            
            if (isPlacement) {
                Placement__c placement = [
                    SELECT Opportunity_lk__c
                    FROM Placement__c
                    WHERE Id = :recordId
                    LIMIT 1
                ];
                oppId = placement.Opportunity_lk__c;
                placementId = recordId;
            }
            
            // Map을 PremiumScheduleItem으로 변환
            List<PremiumScheduleItem> scheduleItems = new List<PremiumScheduleItem>();
            for (Map<String, Object> scheduleMap : schedules) {
                PremiumScheduleItem item = new PremiumScheduleItem();
                
                item.id = (String) scheduleMap.get('id');
                
                Object daysObj = scheduleMap.get('daysFromInception');
                item.daysFromInception = daysObj != null ? Integer.valueOf(daysObj) : 0;
                
                Object pctObj = scheduleMap.get('percentage');
                item.percentage = pctObj != null ? Decimal.valueOf(String.valueOf(pctObj)) : 0;
                
                Object dateObj = scheduleMap.get('installDate');
                if (dateObj != null && dateObj instanceof String && String.isNotBlank((String) dateObj)) {
                    item.installDate = Date.valueOf((String) dateObj);
                }
                
                scheduleItems.add(item);
                System.debug('Converted item: ' + JSON.serialize(item));
            }
            
            // Validation: Total percentage check
            Decimal totalPercentage = 0;
            for (PremiumScheduleItem item : scheduleItems) {
                totalPercentage += COM_Util.nvl(item.percentage, 0);
            }
            System.debug('Total Percentage: ' + totalPercentage);
            
            if (totalPercentage != 100) {
                System.debug('ERROR: Total percentage is not 100');
                throw new AuraHandledException('Total percentage must equal 100%. Current total: ' + totalPercentage + '%');
            }
            
            // PeriodFrom은 항상 Opportunity에서 조회
            System.debug('Querying Opportunity...');
            Opportunity opp = [
                SELECT Id, PeriodFrom__c
                FROM Opportunity
                WHERE Id = :oppId
                LIMIT 1
            ];
            Date periodFrom = opp.PeriodFrom__c;
            System.debug('PeriodFrom: ' + periodFrom);
            
            if (periodFrom == null) {
                System.debug('ERROR: Period From is null');
                throw new AuraHandledException('Opportunity Period From date is required');
            }
            
            List<OPP_PremiumSchedule__c> schedulesToInsert = new List<OPP_PremiumSchedule__c>();
            List<OPP_PremiumSchedule__c> schedulesToUpdate = new List<OPP_PremiumSchedule__c>();
            
            System.debug('Building schedules to insert/update...');
            for (PremiumScheduleItem item : scheduleItems) {
                System.debug('Processing item: ' + JSON.serialize(item));
                
                // Placement 컨텍스트인 경우 Placement_lk__c + Opportunity_lk__c 모두 설정
                OPP_PremiumSchedule__c schedule = isPlacement
                    ? new OPP_PremiumSchedule__c(Placement_lk__c = placementId, Opportunity_lk__c = oppId)
                    : new OPP_PremiumSchedule__c(Opportunity_lk__c = oppId);
                
                schedule.Prem_Currency__c = premCurrency;
                schedule.PaymentType__c = paymentType;
                schedule.DaysFromInception__c = COM_Util.nvl(item.daysFromInception, 0);
                schedule.Percentage__c = COM_Util.nvl(item.percentage, 0);
                schedule.SlipGrossPrem__c = grossPrem;
                schedule.Type__c = 'Schedule';
                
                if (String.isNotBlank(item.id)) {
                    System.debug('UPDATE - Setting Id: ' + item.id);
                    schedule.Id = item.id;
                    schedulesToUpdate.add(schedule);
                } else {
                    System.debug('INSERT - No Id');
                    schedulesToInsert.add(schedule);
                }
            }
            
            if (!schedulesToInsert.isEmpty()) {
                System.debug('Insert records: ' + JSON.serializePretty(schedulesToInsert));
                insert schedulesToInsert;
            }
            
            if (!schedulesToUpdate.isEmpty()) {
                System.debug('Update records: ' + JSON.serializePretty(schedulesToUpdate));
                update schedulesToUpdate;
            }
            
            return 'Premium Schedules saved successfully';
        } catch (Exception e) {
            System.debug('===== savePremiumSchedules ERROR =====');
            System.debug('Exception Type: ' + e.getTypeName());
            System.debug('Exception Message: ' + e.getMessage());
            System.debug('Exception Line: ' + e.getLineNumber());
            System.debug('Exception StackTrace: ' + e.getStackTraceString());
            throw new AuraHandledException('Error saving schedules: ' + e.getMessage());
        }
    }
    
    /**
     * @description 지정한 Premium Schedule 레코드를 삭제한다.
     * @param scheduleId OPP_PremiumSchedule__c Id
     * @return String 삭제 결과 메시지
     */
    @AuraEnabled
    public static String deletePremiumSchedule(Id scheduleId) {
        try {
            if (scheduleId == null) {
                throw new AuraHandledException('Schedule ID is required');
            }
            
            delete new OPP_PremiumSchedule__c(Id = scheduleId);
            
            return 'Schedule deleted successfully';
        } catch (Exception e) {
            throw new AuraHandledException('Error deleting schedule: ' + e.getMessage());
        }
    }
    
    /**
     * @description Period From 과 Days From Inception 값을 기준으로 Install Date 를 계산한다.
     * @param periodFrom Opportunity Period From 날짜
     * @param daysFromInception Days from Inception 값
     * @return Date 계산된 Install Date
     */
    @AuraEnabled
    public static Date calculateInstallDate(Date periodFrom, Integer daysFromInception) {
        try {
            if (periodFrom == null) {
                return null;
            }
            
            Integer days = COM_Util.nvl(daysFromInception, 0);
            return periodFrom.addDays(days);
        } catch (Exception e) {
            System.debug('Error calculating install date: ' + e.getMessage());
            return null;
        }
    }
    
    // ============================================================
    // Inner Classes
    // ============================================================
    
    /**
     * @description 객체 타입과 편집 권한 정보를 전달하는 Wrapper 클래스
     */
    public class InitMetaWrapper {
        
        // ============================================================
        // Properties
        // ============================================================
        
        @AuraEnabled
        public Boolean isPlacement { get; set; }
        
        @AuraEnabled
        public Boolean hasEditPermission { get; set; }
        
        // ============================================================
        // Methods
        // ============================================================
        
        /**
         * @description InitMetaWrapper 기본값을 초기화한다.
         * @param 없음
         * @return 없음
         */
        public InitMetaWrapper() {
            isPlacement = false;
            hasEditPermission = false;
        }
    }
    
    /**
     * @description Opportunity Premium Schedule 조회 결과를 전달하는 Wrapper 클래스
     */
    public class OpportunityScheduleWrapper {
        
        // ============================================================
        // Properties
        // ============================================================
        
        @AuraEnabled
        public Id opportunityId;
        @AuraEnabled
        public String opportunityName;
        @AuraEnabled
        public Integer totalInstalls;
        @AuraEnabled
        public Date periodFrom;
        @AuraEnabled
        public Boolean isClosed;
        @AuraEnabled
        public List<PremiumScheduleItem> schedules;
    }
    
    /**
     * @description Premium Schedule 항목 데이터를 전달하는 Wrapper 클래스
     */
    public class PremiumScheduleItem {
        
        // ============================================================
        // Properties
        // ============================================================
        
        @AuraEnabled
        public String id;
        @AuraEnabled
        public Integer daysFromInception;
        @AuraEnabled
        public Decimal percentage;
        @AuraEnabled
        public Date installDate;
    }
}