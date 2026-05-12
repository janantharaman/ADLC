/**********************************************************************************
 * @filename      : COM_TestDataFactory.cls
 * @projectname   : LK Insurance Services
 * @author        : i2max
 * @date          : 2025-10-29 (수)
 * @group         : Common
 * @group-content : Test Data Factory
 * @description   : Common Test Data Factory for creating SObjects
 * @test-class    : COM_TestDataFactory_ts.cls
 * @reference     : 
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-10-29      i2max     Create
**********************************************************************************/
@IsTest
public class COM_TestDataFactory {

    /** Default value provider instance */
    private static DefaultValueProvider dvPrvdr = new DefaultValueProvider();

    /** Default value generator, used to auto-generate default values for non required fields  */
    public static final IFieldDefaultValue DEFAULT_VALUE = new AutoFieldDefaultValue();

    /** Constant that contains a dot '.' */
    private static final String DOT = '.';

    /** Map of sObject types with their corresponding map of field Tokens  */
    @TestVisible
    private static Map<Schema.SObjectType,Map<String, Schema.SObjectField>> mapOfFieldTokensMap = new Map<Schema.SObjectType,Map<String, Schema.SObjectField>>();

    /* ===========================  Properties =========================== */
    /** Default Value Provider property, used to override the default value provider instance  **/
    public static DefaultValueProvider defaultValueProvider {
        get { return dvPrvdr; }
        set {
            if(value != null){
                dvPrvdr = value;
            }
        }
    }

    /** Determine if person account is enabled in current org **/
    @TestVisible
    private static Boolean isPersonAccountEnabled{
        get{
            return Account.SObjectType.getDescribe().isQueryable() ? Account.SObjectType.getDescribe().hasSubtypes : false;
        }
    }

    /* ===========================  Public methods =========================== */

    /**
     * @description create an sObject
     * @param sObjectName (String): name of the sObject to be created
     * @return sObject instance
     */
    public static SObject createSObject(String sObjectName){
        return createSObject(sObjectName,new Map<String,Object>(),true);
    }

    /**
     * @description create an sObject
     * @param sObjectName (String): name of the sObject to be created
     * @param doInsert (Boolean): if true the sObject instance is inserted to the Salesforce database
     * @return sObject instance
     */
    public static SObject createSObject(String sObjectName, Boolean doInsert){
        return createSObject(sObjectName,new Map<String,Object>(),doInsert);
    }

    /**
     * @description create an sObject with a map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @return sObject instance
     */
    public static SObject createSObject(String sObjectName, Map<String,Object> mapOfValuesOverride){
        return createSObject(sObjectName,mapOfValuesOverride,true);
    }

    /**
     * @description create an sObject with a map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @param doInsert (Boolean): if true the sObject instance is inserted to the Salesforce database
     * @return sObject instance
     */
    public static SObject createSObject(String sObjectName, Map<String,Object> mapOfValuesOverride, Boolean doInsert){
        return createSObjectList(sObjectName,mapOfValuesOverride,1,doInsert).get(0);
    }

    /**
     * @description create an sObject with a field token map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param fieldTokensOverride (Map<Schema.SObjectField,Object>): map of field tokens and values
     * @param doInsert (Boolean): if true the sObject instance is inserted to the Salesforce database
     * @return sObject instance
     */
    public static SObject createSObject(String sObjectName, Map<Schema.SObjectField, Object> fieldTokensOverride, Boolean doInsert) {
        return createSObjectList(sObjectName, fieldTokensOverride, 1, doInsert).get(0);
    }

    /**
     * @description create a list of sObjects
     * @param sObjectName (String): name of the sObject to be created
     * @param numberOfSObjects (Integer): number of sObjects to be created
     * @return list of sObject instances
     */
    public static List<SObject> createSObjectList(String sObjectName, Integer numberOfSObjects){
        return createSObjectList(sObjectName,new Map<String,Object>(),numberOfSObjects,true);
    }

    /**
     * @description create a list of sObjects
     * @param sObjectName (String): name of the sObject to be created
     * @param numberOfSObjects (Integer): number of sObjects to be created
     * @param doInsert (Boolean): if true the sObject list instances is inserted to the Salesforce database
     * @return list of sObject instances
     */
    public static List<SObject> createSObjectList(String sObjectName, Integer numberOfSObjects, Boolean doInsert){
        return createSObjectList(sObjectName,new Map<String,Object>(),numberOfSObjects, doInsert);
    }

    /**
     * @description create a list of sObjects with a map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @param numberOfSObjects (Integer): number of sObjects to be created
     * @return list of sObject instances
     */
    public static List<SObject> createSObjectList(String sObjectName, Map<String,Object> mapOfValuesOverride, Integer numberOfSObjects){
        return createSObjectList(sObjectName,mapOfValuesOverride,numberOfSObjects,true);
    }

    /**
     * @description create a list of sObjects with a map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @param numberOfSObjects (Integer): number of sObjects to be created
     * @param doInsert (Boolean): if true the sObject list instances is inserted to the Salesforce database
     * @return list of sObject instances
     */
    public static List<SObject> createSObjectList(String sObjectName, Map<String,Object> mapOfValuesOverride, Integer numberOfSObjects, Boolean doInsert){
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);
        SObjectFactory sObjFactory = new SObjectFactory(sObjectType);
        List<SObject> listSObjectInstance = sObjFactory.getListSObjectInstance(mapOfValuesOverride, doInsert, numberOfSObjects);
        return listSObjectInstance;
    }

    /**
     * @description create a list of sObjects with a field token map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param fieldTokensOverride (Map<Schema.SObjectField,Object>): map of field tokens and values
     * @param numberOfSObjects (Integer): number of sObjects to be created
     * @param doInsert (Boolean): if true the sObject list instances is inserted to the Salesforce database
     * @return list of sObject instances
     */
    public static List<SObject> createSObjectList(
            String sObjectName,
            Map<Schema.SObjectField, Object> fieldTokensOverride,
            Integer numberOfSObjects,
            Boolean doInsert
    ) {
        Map<String, Object> apiNameMap = new Map<String, Object>();
        if (fieldTokensOverride != null) {
            for (Schema.SObjectField fieldToken : fieldTokensOverride.keySet()) {
                String apiName = fieldToken.getDescribe().getName();
                apiNameMap.put(apiName, fieldTokensOverride.get(fieldToken));
            }
        }
        return createSObjectList(sObjectName, apiNameMap, numberOfSObjects, doInsert);
    }

    /* ===========================  User & Utility Methods =========================== */

    /**
     * @description Create a test user with a given profile
     * @param profileName (String): Name of the profile
     * @return User instance (inserted)
     */
    public static User createUser(String profileName) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;

        User u = new User(
            Alias = uniqueName.substring(18, 23),
            Email = uniqueName + '@test' + orgId + '.org',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = uniqueName + '@test' + orgId + '.org'
        );
        insert u;
        return u;
    }


    /**
     * @description 최소 권한 사용자 생성 (SECURITY_ENFORCED 예외 테스트용)
     * @param isInsert (Boolean): Insert flag
     * @return User
     */
    public static User createMinAccessUser(Boolean isInsert) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];
        String userNm = 'minacc';
        User u = new User(
                Alias = userNm,
                Email = userNm + '@test.com.invalid',
                EmailEncodingKey = 'UTF-8',
                LastName = 'MinAcc',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = p.Id,
                TimeZoneSidKey = 'Asia/Seoul',
                UserName = userNm + '_' + generateRandomString(6) + '@test.com.invalid'
        );
        if (isInsert) insert u;
        return u;
    }

    /**
     * @description Generate a random string of a given length
     * @param len (Integer): Length of the string
     * @return Random string
     */
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }


    /* ======================================================================================================== */
    /* =======================================  inner classes & interfaces ==================================== */
    /* ======================================================================================================== */

    public interface ISObjectManager{
        List<SObject> getMainSObjectList();
        void setSObject(Integer index, SObject sObj);
        SObject getSObject(Integer index);
        void setRelationship(Integer index, String relationshipName, SObject sObj);
        SObject getRelationship(Integer index, String relationshipName);
        void insertAll();
    }

    public class SObjectManager implements ISObjectManager{
        private String sObjectName = null;
        @TestVisible private List<SObject> mainSObjectList = new List<SObject>();
        @TestVisible private Map<String,List<SObject>> relatedSObjMapList = new Map<String,List<SObject>>();
        @TestVisible private List<String> orderedRelationshipList = new List<String>();
        private final String ERR_INSERT_SOBJECT = 'Unable to insert "{0}" records: \n{1}';

        public SObjectManager(String sObjectName){
            this.sObjectName = sObjectName;
        }

        public List<SObject> getMainSObjectList(){
            return mainSObjectList;
        }

        public void setSObject(Integer index, SObject sObj){
            if(index == mainSObjectList.size()){
                mainSObjectList.add(sObj);
            }else{
                mainSObjectList.set(index,sObj);
            }
        }

        public SObject getSObject(Integer index){
            return mainSObjectList.get(index);
        }

        public void setRelationship(Integer index, String fullyQualifiedRelationshipName, SObject sObj){
            String fullyQualifiedRelationshipNameLowerCase = fullyQualifiedRelationshipName.toLowerCase();
            List<SObject> relatedSObjList = relatedSObjMapList.get(fullyQualifiedRelationshipNameLowerCase);
            if(relatedSObjList == null){
                relatedSObjList = new List<SObject>();
                relatedSObjMapList.put(fullyQualifiedRelationshipNameLowerCase,relatedSObjList);
                addRelationshipName(fullyQualifiedRelationshipNameLowerCase);
            }

            if(index == relatedSObjList.size()){
                relatedSObjList.add(sObj);
            }
            else{
                relatedSObjList.set(index,sObj);
            }
        }

        public SObject getRelationship(Integer index, String fullyQualifiedRelationshipName){
            try{
                List<SObject> relatedSObjList = relatedSObjMapList.get(fullyQualifiedRelationshipName.toLowerCase());
                return relatedSObjList.get(index);
            }catch(Exception e){
                return null;
            }
        }

        public void insertAll(){
            for(Integer i = 0; i < orderedRelationshipList.size(); i++){
                String fullyQualifiedRelationshipName = orderedRelationshipList.get(i);
                List<SObject> sObjParentList = relatedSObjMapList.get(fullyQualifiedRelationshipName);
                insertList(sObjParentList,DOT+fullyQualifiedRelationshipName);
                String leafRelationshipName = (DOT+fullyQualifiedRelationshipName).substringAfterLast(DOT);

                if(!fullyQualifiedRelationshipName.contains(DOT)){
                    setChildParentRelationship(mainSObjectList,sObjParentList,fullyQualifiedRelationshipName);
                }else{
                    String fullyQualifiedRelationshipNameWithoutLeaf = fullyQualifiedRelationshipName.substringBeforeLast(DOT);
                    List<SObject> sObjChildList = relatedSObjMapList.get(fullyQualifiedRelationshipNameWithoutLeaf);
                    setChildParentRelationship(sObjChildList,sObjParentList,leafRelationshipName);
                }
            }
            insertList(mainSObjectList,'');
        }

        @TestVisible
        private void setChildParentRelationship(List<SObject> sObjChildList, List<SObject> sObjParentList, String relationshipName){
            Integer index = 0;
            for(SObject sObjChild: sObjChildList){
                String relationshipFieldName = getFieldNameFromRelationshipName(relationshipName);
                sObjChild.put(relationshipFieldName,sObjParentList.get(index).get('Id'));
                index++;
            }
        }

        @TestVisible
        private void addRelationshipName(String fullyQualifiedRelationshipName) {
            for (Integer i = 0; i < orderedRelationshipList.size(); i++) {
                String rName = orderedRelationshipList.get(i);
                if (fullyQualifiedRelationshipName.equalsIgnoreCase(rName)) return;
                if (rName.countMatches('.') < fullyQualifiedRelationshipName.countMatches('.')) {
                    orderedRelationshipList.add(i, fullyQualifiedRelationshipName);
                    return;
                }
            }
            orderedRelationshipList.add(fullyQualifiedRelationshipName);
        }

        @TestVisible
        private void insertList(List<SObject> sObjList, String errorMessageMergeValue){
            Database.SaveResult[] saveResults = Database.insert(sObjList, false);
            Integer i = 0;
            List<String> listErrors = new List<String>();
            for (Database.SaveResult saveResult : saveResults) {
                if (!saveResult.isSuccess()){
                    for(Database.Error error : saveResult.getErrors()) {
                        Set<String> fieldNames = new Set<String>{'Name','RecordTypeId'};
                        fieldNames.addAll(error.getFields());
                        String listFieldValues = '';
                        for(String fieldName : fieldNames){
                            Object fieldValue;
                            try {
                                fieldValue = sObjList.get(i).get(fieldName);
                            }catch(Exception e){ /* ignore errors */}
                            if(fieldValue != null){
                                listFieldValues += fieldName + '='+ fieldValue +', ';
                            }
                        }
                        listFieldValues = listFieldValues.removeEnd(', ');
                        listErrors.add(error.getStatusCode() + ': ' + error.getMessage() + ' ' +'['+listFieldValues+']');
                    }
                    i++;
                }
            }
            if(!listErrors.isEmpty()){
                throw new TestDataFactoryException(formatErrorMessage(ERR_INSERT_SOBJECT,new List<String>{sObjectName+errorMessageMergeValue,String.join(listErrors,'\n')},''));
            }
        }
    }

    public interface ISObjectFactory{
        ISObjectManager getSObjectManager();
        SObject getSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert);
        List<SObject> getListSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert, Integer numberOfSObjects);
    }

    public class SObjectFactory implements ISObjectFactory{
        private Schema.SObjectType sObjectType = null;
        private String sObjectName;
        private SObjectManager sObjMgr;
        private final String ERR_NOT_FOUND_SOBJECT = 'Unable to find the sObject';
        private final String ERR_FIELD_NOT_EXIST = 'The field "{0}" does not exist on "{1}" or the value type provided is incorrect';
        private final String ERR_RELATIONSHIP_NOT_EXIST = 'The relationship "{0}" does not exist on "{1}"';
        private final String ERR_UNABLE_TO_GET_FIELD_VALUE = 'Unable to get the value for the field "{0}"';

        public SObjectFactory(Schema.SObjectType sObjectType){
            if(sObjectType == null){
                throw new TestDataFactoryException(formatErrorMessage(ERR_NOT_FOUND_SOBJECT,new List<String>{},''));
            }
            this.sObjectType = sObjectType;
            this.sObjectName = sObjectType.getDescribe().getName();
            this.sObjMgr = new SObjectManager(this.sObjectName);
        }

        public SObjectManager getSObjectManager(){
            return sObjMgr;
        }

        public SObject getSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert){
            return getListSObjectInstance(mapOfValuesOverride,doInsert,1).get(0);
        }

        public List<SObject> getListSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert, Integer numberOfSObjects){
            Map<String,IFieldDefaultValue> mapOfValues = defaultValueProvider.getDefaultMapOfValues(sObjectType,mapOfValuesOverride);
            for(Integer i = 0; i < numberOfSObjects; i++) {
                initSObjectInstance(mapOfValues,i);
            }
            if(doInsert){
                sObjMgr.insertAll();
            }
            return sObjMgr.getMainSObjectList();
        }

        @TestVisible
        private void initSObjectInstance(Map<String,IFieldDefaultValue> mapOfValues, Integer recordIndex){
            sObjMgr.setSObject(recordIndex,sObjectType.newSObject());
            for(String fullyQualifiedFieldName : mapOfValues.keySet()){
                String fieldName = (DOT+fullyQualifiedFieldName).substringAfterLast(DOT);
                Object fieldValue = getFieldValueFromMapOfValues(mapOfValues,fullyQualifiedFieldName,recordIndex);
                if(!fullyQualifiedFieldName.contains(DOT)){
                    putField(sObjMgr.getSObject(recordIndex),fieldName,fieldValue,sObjectName);
                }else{
                    String firstRelationshipName = fullyQualifiedFieldName.substringBefore(DOT);
                    String fullyQualifiedRelationshipName = fullyQualifiedFieldName.substringBeforeLast(DOT);
                    SObject relatedSObj = getRelationshipInstance(fullyQualifiedRelationshipName,recordIndex);
                    putField(relatedSObj,fieldName,fieldValue,sObjectName+DOT+fullyQualifiedRelationshipName);
                    putSObject(sObjMgr.getSObject(recordIndex),firstRelationshipName,sObjMgr.getRelationship(recordIndex,firstRelationshipName),sObjectName);
                }
            }
        }

        @TestVisible
        private SObject getRelationshipInstance(String fullyQualifiedRelationshipName, Integer recordIndex){
            SObject sObj = sObjMgr.getRelationship(recordIndex,fullyQualifiedRelationshipName);
            if(sObj != null){
                return sObj;
            }
            String leafRelationshipName = (DOT+fullyQualifiedRelationshipName).substringAfterLast(DOT);
            if(!fullyQualifiedRelationshipName.contains(DOT)){
                sObj = getRelatedSObjectInstance(sObjectType,leafRelationshipName,sObjectName);
            }else{
                String fullyQualifiedRelationshipNameWithoutLeaf = fullyQualifiedRelationshipName.substringBeforeLast(DOT);
                SObject relatedSObj = getRelationshipInstance(fullyQualifiedRelationshipNameWithoutLeaf,recordIndex);
                String errorMessageMergeValue = sObjectName+DOT+fullyQualifiedRelationshipNameWithoutLeaf;
                sObj = getRelatedSObjectInstance(relatedSObj.getSObjectType(),leafRelationshipName,errorMessageMergeValue);
                putSObject(relatedSObj,leafRelationshipName,sObj,errorMessageMergeValue);
            }
            sObjMgr.setRelationship(recordIndex,fullyQualifiedRelationshipName,sObj);
            return sObj;
        }

        @TestVisible
        private SObject getRelatedSObjectInstance(Schema.SObjectType sObjectType, String relationshipName, String errorMessageMergeValue){
            Map<String, Schema.SObjectField> fieldsMap = getFieldTokensMap(sObjectType);
            Schema.DescribeFieldResult fieldDesc;
            SObject sObj;
            try{
                fieldDesc = fieldsMap.get(getFieldNameFromRelationshipName(relationshipName)).getDescribe();
                sObj = fieldDesc.getReferenceTo().get(0).newSObject();
            }catch(Exception e){
                throw new TestDataFactoryException(formatErrorMessage(ERR_RELATIONSHIP_NOT_EXIST,new List<String>{relationshipName,errorMessageMergeValue},e.getMessage()));
            }
            return  sObj;
        }

        @TestVisible
        private Object getFieldValueFromMapOfValues(Map<String,IFieldDefaultValue> mapOfValues, String fullyQualifiedFieldName, Integer recordIndex){
            Object fieldValue;
            try{
                fieldValue = mapOfValues.get(fullyQualifiedFieldName).getValue(recordIndex);
            }catch(Exception e){
                throw new TestDataFactoryException(formatErrorMessage(ERR_UNABLE_TO_GET_FIELD_VALUE,new List<String>{fullyQualifiedFieldName},e.getMessage()));
            }
            return fieldValue;
        }

        @TestVisible
        private SObject putSObject(SObject sObj, String relationshipName , SObject sObjectValue, String errorMessageMergeValue){
            try{
                sObj.putSObject(relationshipName,sObjectValue);
            }catch(Exception e){
                throw new TestDataFactoryException(formatErrorMessage(ERR_RELATIONSHIP_NOT_EXIST,new List<String>{relationshipName,errorMessageMergeValue},e.getMessage()));
            }
            return sObj;
        }
    }

    @TestVisible
    private static Map<String, Schema.SObjectField> getFieldTokensMap(Schema.SObjectType sObjectType){
        Map<String, Schema.SObjectField> fieldsMap = mapOfFieldTokensMap.get(sObjectType);
        if(fieldsMap == null){
            fieldsMap = sObjectType.getDescribe().fields.getMap();
            mapOfFieldTokensMap.put(sObjectType,fieldsMap);
        }
        return fieldsMap;
    }

    @TestVisible
    private static String formatErrorMessage(String errorMessage, List<String> mergeValues, String exceptionMessage){
        String formattedErrorMessage = errorMessage;
        for(Integer i = 0; i < mergeValues.size(); i++){
            formattedErrorMessage = formattedErrorMessage.replace('{'+i+'}',mergeValues.get(i));
        }
        if(!String.isEmpty(exceptionMessage)){
            formattedErrorMessage += '\n'+exceptionMessage;
        }
        return formattedErrorMessage;
    }

    @TestVisible
    private static String getFieldNameFromRelationshipName(String relationshipName){
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectType = globalDescribe.get(relationshipName);
        if(sObjectType != null){
            return sObjectType.getDescribe().getName() + 'Id';
        }
        return relationshipName + 'Id';
    }

    @TestVisible
    private static SObject putField(SObject sObj, String fieldName, Object fieldValue, String errorMessageMergeValue){
        try{
            sObj.put(fieldName,fieldValue);
        }catch(Exception e){
            throw new TestDataFactoryException(formatErrorMessage('The field "{0}" does not exist on "{1}" or the value type provided is incorrect',new List<String>{fieldName,errorMessageMergeValue},e.getMessage()));
        }
        return sObj;
    }

    public class TestDataFactoryException extends Exception{}

    public interface IFieldDefaultValue{
        Object getValue(Integer index);
    }

    public class AutoFieldDefaultValue implements IFieldDefaultValue{
        private Schema.DescribeFieldResult fieldDesc;
        public AutoFieldDefaultValue(Schema.DescribeFieldResult fieldDesc){
            this.fieldDesc = fieldDesc;
        }
        public AutoFieldDefaultValue(){}
        public Object getValue(Integer index){
            if(fieldDesc != null){
                Schema.DisplayType dataType = fieldDesc.getType();
                String label = fieldDesc.getLabel();
                String suffix = index+'';
                if(dataType == Schema.DisplayType.Boolean){
                    return false;
                }else if(dataType == Schema.DisplayType.Date){
                    return System.today();
                }else if(dataType == Schema.DisplayType.Datetime){
                    return System.now();
                }else if(dataType == Schema.DisplayType.Email){
                    return label.replace(' ','_') + suffix + '@example.com';
                }else if(dataType == Schema.DisplayType.Phone){
                    return '0123456789';
                }else if(dataType == Schema.DisplayType.Picklist || dataType == Schema.DisplayType.Multipicklist){
                    List<Schema.PicklistEntry> picklistEntries = fieldDesc.getPicklistValues();
                    if(!picklistEntries.isEmpty()){
                        return picklistEntries.get(0).getValue();
                    }
                    return '';
                }else if(dataType == Schema.DisplayType.URL){
                    return 'http://example.com/'+label.replace(' ','_') + suffix;
                }else if(dataType == Schema.DisplayType.TextArea || dataType == Schema.DisplayType.String || dataType == Schema.DisplayType.ID){
                    return label + suffix;
                }else if(dataType == Schema.DisplayType.Integer || dataType == Schema.DisplayType.Double || dataType == Schema.DisplayType.Currency || dataType == Schema.DisplayType.Percent){
                    return index + 1;
                }
            }
            return null;
        }
    }

    public class ConstantFieldDefaultValue implements IFieldDefaultValue{
        private Object fieldValue;
        public ConstantFieldDefaultValue(Object fieldValue){
            this.fieldValue = fieldValue;
        }
        public Object getValue(Integer index){
            return fieldValue;
        }
    }

    public class DefaultValueProvider{
        private final String ERR_NOT_FOUND_FIELD = 'Unable to find the field "{0}" on sObject "{1}"';
        public Map<String,IFieldDefaultValue> getDefaultMapOfValues(Schema.SObjectType sObjectType, Map<String,Object> mapOfValuesOverride){
            Map<String,IFieldDefaultValue> mapOfValues = new Map<String,IFieldDefaultValue>();
            Map<String, Schema.SObjectField> fieldsMap = getFieldTokensMap(sObjectType);
            for(String fieldName : fieldsMap.keySet()){
                Schema.DescribeFieldResult fieldDesc = fieldsMap.get(fieldName).getDescribe();
                if(fieldDesc.isCreateable() || fieldDesc.getType() == Schema.DisplayType.ID){
                    if(!fieldDesc.isNillable() && fieldDesc.isCreateable() && fieldDesc.getDefaultValue() == null){
                        mapOfValues.put(fieldName,new AutoFieldDefaultValue(fieldDesc));
                    }
                }
            }
            for(String fullyQualifiedFieldName : mapOfValuesOverride.keySet()){
                String fieldName;
                String mapKey = fullyQualifiedFieldName.toLowerCase();
                Schema.SObjectType currentSObjectType = sObjectType;
                if(fullyQualifiedFieldName.contains(DOT)){
                    fieldName = (DOT+fullyQualifiedFieldName).substringAfterLast(DOT);
                    String fullyQualifiedRelationshipName = fullyQualifiedFieldName.substringBeforeLast(DOT);
                    List<String> relationshipNames = fullyQualifiedRelationshipName.split('\\'+DOT);
                    for(String rName : relationshipNames){
                        String field = getFieldNameFromRelationshipName(rName);
                        Schema.DescribeFieldResult rFieldDesc = currentSObjectType.getDescribe().fields.getMap().get(field).getDescribe();
                        currentSObjectType = rFieldDesc.getReferenceTo().get(0);
                    }
                }else{
                    fieldName = fullyQualifiedFieldName;
                }
                if(!currentSObjectType.getDescribe().fields.getMap().containsKey(fieldName)){
                    throw new TestDataFactoryException(formatErrorMessage(ERR_NOT_FOUND_FIELD,new List<String>{fieldName,currentSObjectType.getDescribe().getName()},''));
                }
                Object fieldValue = mapOfValuesOverride.get(fullyQualifiedFieldName);
                if(fieldValue == COM_TestDataFactory.DEFAULT_VALUE){
                    Schema.DescribeFieldResult fieldDesc = currentSObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
                    mapOfValues.put(mapKey,new AutoFieldDefaultValue(fieldDesc));
                }else if(fieldValue != null){
                    mapOfValues.put(mapKey,new ConstantFieldDefaultValue(fieldValue));
                }else{
                    mapOfValues.put(mapKey,new ConstantFieldDefaultValue(null));
                }
            }
            if(isPersonAccountEnabled && sObjectType == Account.SObjectType){
                if(!mapOfValues.containsKey('RecordTypeId')){
                    Id personAccountRTId = getPersonAccountRecordTypeId();
                    if(personAccountRTId != null){
                        mapOfValues.put('RecordTypeId', new ConstantFieldDefaultValue(personAccountRTId));
                    }
                }
            }

            // [Fix] OwnerId 자동 할당 로직 추가
            if (fieldsMap.containsKey('OwnerId') && !mapOfValues.containsKey('OwnerId') && !mapOfValuesOverride.containsKey('OwnerId')) {
                mapOfValues.put('OwnerId', new ConstantFieldDefaultValue(UserInfo.getUserId()));
            }

            return mapOfValues;
        }
        private Id getPersonAccountRecordTypeId(){
            try{
                return Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
            }catch(Exception e){
                return null;
            }
        }
    }
}