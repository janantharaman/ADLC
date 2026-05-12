/**********************************************************************************
 * @filename      : TestDataFactory.cls
 * @projectname   : 
 * @author        : i2max
 * @date          : 2025-10-29 (수)
 * @group         :
 * @group-content :
 * @description   : 
 * @test-class    : TestDataFactory_ts.cls
 * @reference     : 
 * @copyright     : 
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2025-10-29      i2max     Create
**********************************************************************************/
@IsTest
public class TestDataFactory {

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
            // DescribeOptions를 사용하지 않도록 수정 (안정적인 접근)
            return Account.SObjectType.getDescribe().isQueryable() ? Account.SObjectType.getDescribe().hasSubtypes : false;
        }
    }

    /* ===========================  Public methods =========================== */

    /**
     * @description create an sObject
     * @param sObjectName (String): name of the sObject to be created
     * @return sObject instance
     * @example
     * Account acc = (Account)TestDataFactory.createSObject('Account');
     */
    public static SObject createSObject(String sObjectName){
        return createSObject(sObjectName,new Map<String,Object>(),true);
    }

    /**
     * @description create an sObject
     * @param sObjectName (String): name of the sObject to be created
     * @param Boolean (Boolean): if true the sObject instance is inserted to the Salesforce database
     * @return sObject instance
     * @example
     * Account acc = (Account)TestDataFactory.createSObject('Account',false);
     */
    public static SObject createSObject(String sObjectName, Boolean doInsert){
        return createSObject(sObjectName,new Map<String,Object>(),doInsert);
    }

    /**
     * @description create an sObject with a map to override field values
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @return sObject instance
     * @example
     * Account acc = (Account)TestDataFactory.createSObject('Account',new Map<String,Object>{
     * 'Description' => 'Test'
     * });
     */
    public static SObject createSObject(String sObjectName, Map<String,Object> mapOfValuesOverride){
        return createSObject(sObjectName,mapOfValuesOverride,true);
    }

    /**
     * @description create an sObject with a map to override field values (String Map 기반 - 기존 유지)
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @param doInsert (Boolean): if true the sObject instance is inserted to the Salesforce database
     * @return sObject instance
     * @example
     * Account acc = (Account)TestDataFactory.createSObject('Account',new Map<String,Object>{
     * 'Description' => 'Test'
     * },false);
     */
    public static SObject createSObject(String sObjectName, Map<String,Object> mapOfValuesOverride, Boolean doInsert){
        return createSObjectList(sObjectName,mapOfValuesOverride,1,doInsert).get(0);
    }

    // ⭐ [NEW] Map<Schema.SObjectField, Object> 기반 오버로딩 (안정성 확보)
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
     * @example
     * List<Account> accList = TestDataFactory.createSObjectList('Account',10);
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
     * @example
     * List<Account> accList = TestDataFactory.createSObjectList('Account',10,false);
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
     * @example
     * List<Account> accList = TestDataFactory.createSObjectList('Account',new Map<String,Object>{
     * 'Description' => 'Test'
     * },10);
     */
    public static List<SObject> createSObjectList(String sObjectName, Map<String,Object> mapOfValuesOverride, Integer numberOfSObjects){
        return createSObjectList(sObjectName,mapOfValuesOverride,numberOfSObjects,true);
    }

    /**
     * @description create a list of sObjects with a map to override field values (String Map 기반 - 기존 유지)
     * @param sObjectName (String): name of the sObject to be created
     * @param mapOfValuesOverride (Map<String,Object>): map of values
     * @param numberOfSObjects (Integer): number of sObjects to be created
     * @param doInsert (Boolean): if true the sObject list instances is inserted to the Salesforce database
     * @return list of sObject instances
     * @example
     * List<Account> accList = TestDataFactory.createSObjectList('Account',new Map<String,Object>{
     * 'Description' => 'Test'
     * },10,false);
     */
    public static List<SObject> createSObjectList(String sObjectName, Map<String,Object> mapOfValuesOverride, Integer numberOfSObjects, Boolean doInsert){
        Schema.SObjectType sObjectType = Schema.getGlobalDescribe().get(sObjectName);
        SObjectFactory sObjFactory = new SObjectFactory(sObjectType);
        List<SObject> listSObjectInstance = sObjFactory.getListSObjectInstance(mapOfValuesOverride, doInsert, numberOfSObjects);
        return listSObjectInstance;
    }

    // ⭐ [NEW] Map<Schema.SObjectField, Object> 기반 오버로딩 (안정성 확보)
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
        // Map<Schema.SObjectField, Object>를 Map<String, Object>로 변환
        Map<String, Object> apiNameMap = new Map<String, Object>();
        if (fieldTokensOverride != null) {
            for (Schema.SObjectField fieldToken : fieldTokensOverride.keySet()) {
                String apiName = fieldToken.getDescribe().getName();
                apiNameMap.put(apiName, fieldTokensOverride.get(fieldToken));
            }
        }

        // 기존 String Map 기반 메서드를 호출하여 로직 재사용
        return createSObjectList(sObjectName, apiNameMap, numberOfSObjects, doInsert);
    }


    /* ======================================================================================================== */
    /* =======================================  inner classes & interfaces ==================================== */
    /* ======================================================================================================== */

    /**
    * @description interface ISObjectManager
    */
    public interface ISObjectManager{
        List<SObject> getMainSObjectList();
        void setSObject(Integer index, SObject sObj);
        SObject getSObject(Integer index);
        void setRelationship(Integer index, String relationshipName, SObject sObj);
        SObject getRelationship(Integer index, String relationshipName);
        void insertAll();
    }

    /**
    * @description class SObjectManager : manage all the sObjects instances and the insertion to the salesforce DB
    */
    public class SObjectManager implements ISObjectManager{

        /** Main sObject name */
        private String sObjectName = null;
        /** List of main sObject instances */
        @TestVisible
        private List<SObject> mainSObjectList = new List<SObject>();
        /** Map of relationship names with their related list of sObject instances */
        @TestVisible
        private Map<String,List<SObject>> relatedSObjMapList = new Map<String,List<SObject>>();
        /** List of ordered relationship names by dot notation */
        @TestVisible
        private List<String> orderedRelationshipList = new List<String>();

        /* ===========================  Error Messages =========================== */
        /** Unable to insert "{0}" records: {1} */
        private final String ERR_INSERT_SOBJECT = 'Unable to insert "{0}" records: \n{1}';


        /**
        * @description constructor
        * @return sObjectName (String): main sObject name
        */
        public SObjectManager(String sObjectName){
            this.sObjectName = sObjectName;
        }

        /**
        * @description get the list of all main sObject instances
        * @return list of sObject instances
        */
        public List<SObject> getMainSObjectList(){
            return mainSObjectList;
        }

        /**
        * @description set or add an sObject to the main sObject list for a given index
        * @param index (Integer): index for which the sObject instance will be added or set
        * @param sObj (SObject): sObject instance to add or set to the main sObject list
        */
        public void setSObject(Integer index, SObject sObj){
            if(index == mainSObjectList.size()){
                mainSObjectList.add(sObj);
            }else{
                mainSObjectList.set(index,sObj);
            }
        }

        /**
        * @description get an sObject from the main sObject list for a given index
        * @param index (Integer): index for which the sObject instance will be returned
        * @return the returnd sObject instance
        */
        public SObject getSObject(Integer index){
            return mainSObjectList.get(index);
        }

        /**
        * @description set or add a related sObject into the related sObject map list for a given index and relationship name
        * @param index (Integer): index for which the sObject instance will be added or set
        * @param fullyQualifiedRelationshipName (String): fully qualified relationship name for which the sObject instance will be added or set
        * @param sObj (SObject): sObject instance to add or set to the related sObject map list
        */
        public void setRelationship(Integer index, String fullyQualifiedRelationshipName, SObject sObj){
            String fullyQualifiedRelationshipNameLowerCase = fullyQualifiedRelationshipName.toLowerCase();
            // get related sObject list for the fully qualified relationship name
            List<SObject> relatedSObjList = relatedSObjMapList.get(fullyQualifiedRelationshipNameLowerCase);
            if(relatedSObjList == null){
                // instantiate the list if null
                relatedSObjList = new List<SObject>();
                // put the list into the related sObject map list
                relatedSObjMapList.put(fullyQualifiedRelationshipNameLowerCase,relatedSObjList);
                // add the fully qualified relationship name to the list of ordered relationship names
                addRelationshipName(fullyQualifiedRelationshipNameLowerCase);
            }

            if(index == relatedSObjList.size()){
                relatedSObjList.add(sObj);
            }
            else{
                relatedSObjList.set(index,sObj);
            }
        }

        /**
        * @description get a related sObject from the related sObject map list for a given index and relationship name
        * @param index (Integer): index for which the sObject instance will be returned
        * @param fullyQualifiedRelationshipName (String): fully qualified relationship name for which the sObject instance will be returned
        * @return the returnd sObject instance
        */
        public SObject getRelationship(Integer index, String fullyQualifiedRelationshipName){
            try{
                List<SObject> relatedSObjList = relatedSObjMapList.get(fullyQualifiedRelationshipName.toLowerCase());
                return relatedSObjList.get(index);
            }catch(Exception e){
                return null;
            }
        }

        /**
        * @description insert all the sObjects stored in the sObject Manager into the Salesforce database
        */
        public void insertAll(){
            // loop through the ordered relationship list
            for(Integer i = 0; i < orderedRelationshipList.size(); i++){
                String fullyQualifiedRelationshipName = orderedRelationshipList.get(i);
                List<SObject> sObjParentList = relatedSObjMapList.get(fullyQualifiedRelationshipName);

                // insert parent sObject list
                insertList(sObjParentList,DOT+fullyQualifiedRelationshipName);

                // last relationship name in the dot notation
                String leafRelationshipName = (DOT+fullyQualifiedRelationshipName).substringAfterLast(DOT);

                if(!fullyQualifiedRelationshipName.contains(DOT)){ // single relationship
                    // link child sObject list to the main sObject list
                    setChildParentRelationship(mainSObjectList,sObjParentList,fullyQualifiedRelationshipName);

                }else{ // multiple relationships

                    // fully qualified relationship name without the leaf relationship
                    String fullyQualifiedRelationshipNameWithoutLeaf = fullyQualifiedRelationshipName.substringBeforeLast(DOT);
                    // get the list of sObject of the fully qualified relationship name without the leaf relationship name
                    List<SObject> sObjChildList = relatedSObjMapList.get(fullyQualifiedRelationshipNameWithoutLeaf);
                    // link child sObject list to the parent sObject list
                    setChildParentRelationship(sObjChildList,sObjParentList,leafRelationshipName);
                }
            }

            // insert main sObject list
            insertList(mainSObjectList,'');
        }

        /* ============================================================================================= */
        /* =======================================  private methods ==================================== */
        /* ============================================================================================= */

        /**
        * @description link a list of child sObject instances to a list of parent sObject instances for a given relationship name
        * @param sObjChildList (List<SObject>): list of child sObject instances
        * @param sObjParentList (List<SObject>): list of parent sObject instances
        * @param relationshipName (String): relationship name that links the child sObject to the parent sObject
        */
        @TestVisible
        private void setChildParentRelationship(List<SObject> sObjChildList, List<SObject> sObjParentList, String relationshipName){
            Integer index = 0;
            for(SObject sObjChild: sObjChildList){
                // get the field name that links the child sObject to the parent sObject
                String relationshipFieldName = getFieldNameFromRelationshipName(relationshipName);
                // set field related to the relationship name (on the child sObject), with the Id of the parent sObject
                sObjChild.put(relationshipFieldName,sObjParentList.get(index).get('Id'));
                index++;
            }
        }

        /**
        * @description add relationship name to the ordered relationship list, ordered by the number of dots
        * @param fullyQualifiedRelationshipName (String): fully qualified relationship name (example contact.account)
        */
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

        /**
        * @description execute a DML insert operation on a list of sObjects
        * @param sObjList (List<SObject>): list of sObjects to be inserted
        * @param errorMessageMergeValue (String): merge value provided only for error message generation (example : .contact.account)
        */
        @TestVisible
        private void insertList(List<SObject> sObjList, String errorMessageMergeValue){
            Database.SaveResult[] saveResults = Database.insert(sObjList, false);
            Integer i = 0;
            List<String> listErrors = new List<String>();
            // Iterate through the save results
            for (Database.SaveResult saveResult : saveResults) {
                if (!saveResult.isSuccess()){
                    // Iterate through the errors
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

    /**
    * @description interface ISObjectFactory
    */
    public interface ISObjectFactory{
        ISObjectManager getSObjectManager();
        SObject getSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert);
        List<SObject> getListSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert, Integer numberOfSObjects);
    }

    /**
    * @description class SObjectFactory : manage the creation of all the sObjects instances
    */
    public class SObjectFactory implements ISObjectFactory{

        /** Main sObject type to instantiated */
        private Schema.SObjectType sObjectType = null;
        /** Main sObject Name to instantiated */
        private String sObjectName;
        /** Instance of SObject Manager to store all the created sObject instances */
        private SObjectManager sObjMgr;

        /* ===========================  Error Messages =========================== */
        /** Unable to find the sObject */
        private final String ERR_NOT_FOUND_SOBJECT = 'Unable to find the sObject';
        /** The field "{0}" does not exist on "{1}" or the value type provided is incorrect */
        private final String ERR_FIELD_NOT_EXIST = 'The field "{0}" does not exist on "{1}" or the value type provided is incorrect';
        /** The relationship "{0}" does not exist on "{1}" */
        private final String ERR_RELATIONSHIP_NOT_EXIST = 'The relationship "{0}" does not exist on "{1}"';
        /** Unable to get the value for the field "{0}" */
        private final String ERR_UNABLE_TO_GET_FIELD_VALUE = 'Unable to get the value for the field "{0}"';


        /**
        * @description construtor
        * @param sObjectType (Schema.SObjectType): main sObject type to be instantiated
        */
        public SObjectFactory(Schema.SObjectType sObjectType){
            if(sObjectType == null){
                throw new TestDataFactoryException(formatErrorMessage(ERR_NOT_FOUND_SOBJECT,new List<String>{},''));
            }
            this.sObjectType = sObjectType;
            this.sObjectName = sObjectType.getDescribe().getName();
            this.sObjMgr = new SObjectManager(this.sObjectName);
        }

        /**
        * @description get the SObject Manager instance
        * @return sObject Manager instance
        */
        public SObjectManager getSObjectManager(){
            return sObjMgr;
        }

        /**
        * @description generate an sObject instance and apply the override map of values
        * @param mapOfValuesOverride (Map<String,Object>): map of values to override when instanciating the sObject
        * @param doInsert (Boolean): if true the sObject list instances is inserted to the Salesforce database
        * @return sObject instance
        */
        public SObject getSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert){
            return getListSObjectInstance(mapOfValuesOverride,doInsert,1).get(0);
        }

        /**
        * @description generate a list of sObject instances and apply the override map of values
        * @param mapOfValuesOverride (Map<String,Object>): map of values to override when instanciating the sObject
        * @param doInsert (Boolean): if true the sObject list instances is inserted to the Salesforce database
        * @param numberOfSObjects (Integer): number of sObjects to be instantiated
        * @return list of sObject instances
        */
        public List<SObject> getListSObjectInstance(Map<String,Object> mapOfValuesOverride, Boolean doInsert, Integer numberOfSObjects){
            // get the map of values formed from the union of the map of values override given by the user and the auto-generated map of values for the required fields
            Map<String,IFieldDefaultValue> mapOfValues = defaultValueProvider.getDefaultMapOfValues(sObjectType,mapOfValuesOverride);

            for(Integer i = 0; i < numberOfSObjects; i++) {
                initSObjectInstance(mapOfValues,i); // init sObject instance
            }

            if(doInsert){
                sObjMgr.insertAll(); // insert all if doInsert = true
            }

            return sObjMgr.getMainSObjectList();
        }

        /* ============================================================================================= */
        /* =======================================  private methods ==================================== */
        /* ============================================================================================= */

        /**
        * @description initiate the main sObject instance with all related sObject and apply the map of values
        * @param mapOfValues (Map<String,IFieldDefaultValue>): map of values with key as field name and value as the default value to be used when instantiating the sObject.
        * This map contains the default values provided as input by the user and the auto-generated default values for the required fields
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        */
        @TestVisible
        private void initSObjectInstance(Map<String,IFieldDefaultValue> mapOfValues, Integer recordIndex){
            // add the main sObject instance to the sObject Manager
            sObjMgr.setSObject(recordIndex,sObjectType.newSObject());

            for(String fullyQualifiedFieldName : mapOfValues.keySet()){ // loop through the map of values

                // get the field name from the fully qualified field name
                String fieldName = (DOT+fullyQualifiedFieldName).substringAfterLast(DOT);
                // get the field value from the map of values
                Object fieldValue = getFieldValueFromMapOfValues(mapOfValues,fullyQualifiedFieldName,recordIndex);

                if(!fullyQualifiedFieldName.contains(DOT)){ // field name
                    putField(sObjMgr.getSObject(recordIndex),fieldName,fieldValue,sObjectName);
                }else{ // relationship
                    // first relationship name in fully qualified relationship name
                    String firstRelationshipName = fullyQualifiedFieldName.substringBefore(DOT);
                    // fully qualified relationship name without the field name
                    String fullyQualifiedRelationshipName = fullyQualifiedFieldName.substringBeforeLast(DOT);
                    // generate the related sObject instances for a given fullyQualifiedRelationshipName
                    SObject relatedSObj = getRelationshipInstance(fullyQualifiedRelationshipName,recordIndex);
                    // apply the field value for the related sObject
                    putField(relatedSObj,fieldName,fieldValue,sObjectName+DOT+fullyQualifiedRelationshipName);
                    // link the related sObject to the main sObject
                    putSObject(sObjMgr.getSObject(recordIndex),firstRelationshipName,sObjMgr.getRelationship(recordIndex,firstRelationshipName),sObjectName);
                }
            }
        }

        /**
        * @description Recursive method that initiate all the related sObjects of a given fully qualified relationship name
        * @param fullyQualifiedRelationshipName (String): fully qualified relationship name (example : Case.Contact.Account)
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return main sObject instance with all related sObjects attached to it
        */
        @TestVisible
        private SObject getRelationshipInstance(String fullyQualifiedRelationshipName, Integer recordIndex){
            // get the sObject instance from the sObject Manager
            SObject sObj = sObjMgr.getRelationship(recordIndex,fullyQualifiedRelationshipName);
            // return the sObject instance if already exists in the sObject Manager
            if(sObj != null){
                return sObj;
            }

            // last relationship name in the dot notation
            String leafRelationshipName = (DOT+fullyQualifiedRelationshipName).substringAfterLast(DOT);

            if(!fullyQualifiedRelationshipName.contains(DOT)){ // single relationship
                sObj = getRelatedSObjectInstance(sObjectType,leafRelationshipName,sObjectName);
            }else{ // multiple relationships

                // fully qualified relationship name without the leaf relationship
                String fullyQualifiedRelationshipNameWithoutLeaf = fullyQualifiedRelationshipName.substringBeforeLast(DOT);
                // generate the all the sObject instances for the fully qualified relationship name without the leaf relationship name
                SObject relatedSObj = getRelationshipInstance(fullyQualifiedRelationshipNameWithoutLeaf,recordIndex); // <= recursion
                // merge value for error message display
                String errorMessageMergeValue = sObjectName+DOT+fullyQualifiedRelationshipNameWithoutLeaf;
                // get sObject instance for the leaf relationship
                sObj = getRelatedSObjectInstance(relatedSObj.getSObjectType(),leafRelationshipName,errorMessageMergeValue);
                // link the related instance of the leaf relationship to the related sObject of the fully qualified relationship name without the leaf relationship name
                putSObject(relatedSObj,leafRelationshipName,sObj,errorMessageMergeValue);
            }

            // add the sObject instance to the sObject Manager
            sObjMgr.setRelationship(recordIndex,fullyQualifiedRelationshipName,sObj);
            return sObj;
        }

        /**
        * @description get related sObject instance of an sObject type for a given relationship name
        * @param sObjectType (Schema.SObjectType): sObject type to which the generate sObject is related
        * @param relationshipName (String): relationship name that links the sObject type and the sObject instance that will be generated
        * @param errorMessageMergeValue (String): merge value provided only for error message generation (example : Contact.Account)
        * @return the generated related sObject instance
        */
        @TestVisible
        private SObject getRelatedSObjectInstance(Schema.SObjectType sObjectType, String relationshipName, String errorMessageMergeValue){
            Map<String, Schema.SObjectField> fieldsMap = getFieldTokensMap(sObjectType);
            Schema.DescribeFieldResult fieldDesc;
            SObject sObj;
            try{
                // get the related field describe
                fieldDesc = fieldsMap.get(getFieldNameFromRelationshipName(relationshipName)).getDescribe();
                // get related sObject instance
                sObj = fieldDesc.getReferenceTo().get(0).newSObject();
            }catch(Exception e){
                throw new TestDataFactoryException(formatErrorMessage(ERR_RELATIONSHIP_NOT_EXIST,new List<String>{relationshipName,errorMessageMergeValue},e.getMessage()));
            }
            return  sObj;
        }

        /**
        * @description get the field value from the map of values for a given record index and fully qualified field name
        * @param mapOfValues (Map<String,IFieldDefaultValue>): map of values with key as field name and value as the default value to be used when instantiating the sObject.
        * @param fullyQualifiedFieldName (String): fully qualified field name (example : Contact.Account.Name)
        * @param recordIndex (Integer): index number (starting from 0) of each record when creating a list of sObjects. For single sObject creation recordIndex is default to 0
        * @return field value
        */
        @TestVisible
        private Object getFieldValueFromMapOfValues(Map<String,IFieldDefaultValue> mapOfValues, String fullyQualifiedFieldName, Integer recordIndex){
            Object fieldValue;
            try{
                // get the field value
                fieldValue = mapOfValues.get(fullyQualifiedFieldName).getValue(recordIndex);
            }catch(Exception e){
                throw new TestDataFactoryException(formatErrorMessage(ERR_UNABLE_TO_GET_FIELD_VALUE,new List<String>{fullyQualifiedFieldName},e.getMessage()));
            }
            return fieldValue;
        }

        /**
        * @description attach an sObject into a related sObject
        * @param sObj (SObject): main sObject instance
        * @param relationshipName (String): sObject name of the related sObject
        * @param sObjectValue (SObject): related sObject instance to be attached to the main sObject instance
        * @param errorMessageMergeValue (String): merge value provided only for error message generation (example : Contact.Account)
        * @return main sObject instance
        */
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


    /* ======================================================================================================== */
    /* =========================================  Utility Methods & Classes =================================== */
    /* ======================================================================================================== */

    /**
    * @description Utility method: get the field tokens map for a given sObject type
    * @param sObjectType (Schema.SObjectType): sObject type
    * @return map of field tokens
    */
    @TestVisible
    private static Map<String, Schema.SObjectField> getFieldTokensMap(Schema.SObjectType sObjectType){
        Map<String, Schema.SObjectField> fieldsMap = mapOfFieldTokensMap.get(sObjectType);
        if(fieldsMap == null){
            fieldsMap = sObjectType.getDescribe().fields.getMap();
            mapOfFieldTokensMap.put(sObjectType,fieldsMap);
        }
        return fieldsMap;
    }

    /**
    * @description Utility method: format the error message with the provided list of merge values
    * @param errorMessage (String): error message with placeholder {0}, {1},...
    * @param mergeValues (List<String>): list of values used to replace the placeholders in the error message
    * @param exceptionMessage (String): exception message from the try-catch block
    * @return formatted error message
    */
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

    /**
    * @description Utility method: get the field name from the relationship name. Example: from 'Account' returns 'AccountId'
    * @param relationshipName (String): relationship name
    * @return field name
    */
    @TestVisible
    private static String getFieldNameFromRelationshipName(String relationshipName){
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectType = globalDescribe.get(relationshipName);

        if(sObjectType != null){ // Standard/Custom Object
            return sObjectType.getDescribe().getName() + 'Id';
        }
        // Fallback for custom objects or strange relationship names
        // Tries to return the relationship name + 'Id', which is common
        return relationshipName + 'Id';
    }

    /**
    * @description Utility method: set a field value on an sObject instance
    * @param sObj (SObject): sObject instance
    * @param fieldName (String): field api name
    * @param fieldValue (Object): value to be set
    * @param errorMessageMergeValue (String): merge value provided only for error message generation
    * @return sObject instance
    */
    @TestVisible
    private static SObject putField(SObject sObj, String fieldName, Object fieldValue, String errorMessageMergeValue){
        try{
            sObj.put(fieldName,fieldValue);
        }catch(Exception e){
            throw new TestDataFactoryException(formatErrorMessage('The field "{0}" does not exist on "{1}" or the value type provided is incorrect',new List<String>{fieldName,errorMessageMergeValue},e.getMessage()));
        }
        return sObj;
    }

    /* ======================================================================================================== */
    /* =========================================  EXCEPTION CLASS ============================================= */
    /* ======================================================================================================== */

    /**
    * @description Exception class for TestDataFactory
    */
    public class TestDataFactoryException extends Exception{}

    /* ======================================================================================================== */
    /* =========================================  FIELD DEFAULT VALUE INTERFACE & CLASSES ====================== */
    /* ======================================================================================================== */

    /**
    * @description Interface for field default value provider
    */
    public interface IFieldDefaultValue{
        Object getValue(Integer index);
    }

    /**
    * @description Default value provider for auto-generated values
    */
    public class AutoFieldDefaultValue implements IFieldDefaultValue{

        /** Field describe result */
        private Schema.DescribeFieldResult fieldDesc;

        /**
        * @description constructor
        * @param fieldDesc (Schema.DescribeFieldResult): field describe result
        */
        public AutoFieldDefaultValue(Schema.DescribeFieldResult fieldDesc){
            this.fieldDesc = fieldDesc;
        }

        /**
        * @description constructor (for DEFAULT_VALUE constant)
        */
        public AutoFieldDefaultValue(){}

        /**
        * @description get the field value
        * @param index (Integer): index of the record
        * @return field value
        */
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
                    return index + 1; // Start with 1 to avoid 0
                }
            }
            return null;
        }
    }

    /**
    * @description Constant field value provider
    */
    public class ConstantFieldDefaultValue implements IFieldDefaultValue{

        /** Field value */
        private Object fieldValue;

        /**
        * @description constructor
        * @param fieldValue (Object): field value
        */
        public ConstantFieldDefaultValue(Object fieldValue){
            this.fieldValue = fieldValue;
        }

        /**
        * @description get the field value
        * @param index (Integer): index of the record
        * @return field value
        */
        public Object getValue(Integer index){
            return fieldValue;
        }
    }

    /**
    * @description Default Value Provider class
    */
    public class DefaultValueProvider{

        /* ===========================  Error Messages =========================== */
        /** Unable to find the field "{0}" on sObject "{1}" */
        private final String ERR_NOT_FOUND_FIELD = 'Unable to find the field "{0}" on sObject "{1}"';

        /**
        * @description get default map of values for a given sObject type
        * @param sObjectType (Schema.SObjectType): sObject type
        * @param mapOfValuesOverride (Map<String,Object>): map of values from the user input
        * @return map of field name with its default value provider
        */
        public Map<String,IFieldDefaultValue> getDefaultMapOfValues(Schema.SObjectType sObjectType, Map<String,Object> mapOfValuesOverride){
            Map<String,IFieldDefaultValue> mapOfValues = new Map<String,IFieldDefaultValue>();
            Map<String, Schema.SObjectField> fieldsMap = getFieldTokensMap(sObjectType);

            // Loop through all fields on the sObject
            for(String fieldName : fieldsMap.keySet()){
                Schema.DescribeFieldResult fieldDesc = fieldsMap.get(fieldName).getDescribe();

                // Exclude read-only fields that are not creatable
                if(fieldDesc.isCreateable() || fieldDesc.getType() == Schema.DisplayType.ID){
                    // Set AutoFieldDefaultValue for required fields
                    if(!fieldDesc.isNillable() && fieldDesc.isCreateable() && fieldDesc.getDefaultValue() == null){
                        mapOfValues.put(fieldName,new AutoFieldDefaultValue(fieldDesc));
                    }
                }
            }

            // Override with user-provided values
            for(String fullyQualifiedFieldName : mapOfValuesOverride.keySet()){
                String fieldName;
                Schema.SObjectType currentSObjectType = sObjectType;

                // Handle dot notation (Relationship.Field)
                if(fullyQualifiedFieldName.contains(DOT)){
                    fieldName = (DOT+fullyQualifiedFieldName).substringAfterLast(DOT);
                    String fullyQualifiedRelationshipName = fullyQualifiedFieldName.substringBeforeLast(DOT);

                    // Traverse relationships to find the actual SObject type
                    List<String> relationshipNames = fullyQualifiedRelationshipName.split('\\'+DOT);
                    for(String rName : relationshipNames){
                        String field = getFieldNameFromRelationshipName(rName);
                        Schema.DescribeFieldResult rFieldDesc = currentSObjectType.getDescribe().fields.getMap().get(field).getDescribe();
                        currentSObjectType = rFieldDesc.getReferenceTo().get(0);
                    }
                }else{
                    fieldName = fullyQualifiedFieldName;
                }

                // Check if the field exists on the SObject (either the main or related)
                if(!currentSObjectType.getDescribe().fields.getMap().containsKey(fieldName)){
                    throw new TestDataFactoryException(formatErrorMessage(ERR_NOT_FOUND_FIELD,new List<String>{fieldName,currentSObjectType.getDescribe().getName()},''));
                }

                Object fieldValue = mapOfValuesOverride.get(fullyQualifiedFieldName);

                if(fieldValue == TestDataFactory.DEFAULT_VALUE){
                    // Use AutoFieldDefaultValue for the field
                    Schema.DescribeFieldResult fieldDesc = currentSObjectType.getDescribe().fields.getMap().get(fieldName).getDescribe();
                    mapOfValues.put(fullyQualifiedFieldName,new AutoFieldDefaultValue(fieldDesc));
                }else if(fieldValue != null){
                    // Use ConstantFieldDefaultValue for the field
                    mapOfValues.put(fullyQualifiedFieldName,new ConstantFieldDefaultValue(fieldValue));
                }else{
                    // User explicitly provided null, use ConstantFieldDefaultValue with null
                    mapOfValues.put(fullyQualifiedFieldName,new ConstantFieldDefaultValue(null));
                }
            }

            // Handle Person Account Record Type (if enabled)
            if(isPersonAccountEnabled && sObjectType == Account.SObjectType){
                // Ensure RecordTypeId is set for Person Accounts
                if(!mapOfValues.containsKey('RecordTypeId')){
                    Id personAccountRTId = getPersonAccountRecordTypeId();
                    if(personAccountRTId != null){
                        mapOfValues.put('RecordTypeId', new ConstantFieldDefaultValue(personAccountRTId));
                    }
                }
            }

            return mapOfValues;
        }

        /**
        * @description Utility method: get the Person Account Record Type Id
        * @return Record Type Id
        */
        private Id getPersonAccountRecordTypeId(){
            try{
                return Schema.SObjectType.Account.getRecordTypeInfosByName().get('Person Account').getRecordTypeId();
            }catch(Exception e){
                return null;
            }
        }
    }
}