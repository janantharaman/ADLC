/**********************************************************************************
 * @filename      : COM_TypeaheadPicklist_Ctrl.cls
 * @project-name  : LK보험중계 신규계약관리시스템 구축
 * @author        : i2max
 * @date          : 2026-03-15 (일)
 * @group         :
 * @group-content :
 * @description   :
 * @test-class    : COM_TypeaheadPicklist_Ctrl_ts.cls
 * @reference     :
 * @copyright     : LK Insurance Services
 * @modification  Log
 * ===================================================================
 * ver   date            author           description
 * ===================================================================
 * 1.0   2026-03-15      i2max     Create
 **********************************************************************************/
public with sharing class COM_TypeaheadPicklist_Ctrl {

    @AuraEnabled(Cacheable=true)
    public static List<COM_Option> getOptions(
            String objectApiName,      // 'Placement__c'
            List<String> fieldApiNames, // ['LOB1__c', 'LOB2__c', 'LOB3__c']
            String displaySeparator,      // '>'
            String valueSeparator      // '_'
    ) {
        if (!COM_MetaUtil.existsObject(objectApiName)) throw new AuraHandledException('대상 개체가 존재하지 않습니다.');
        for (String fieldApiName : fieldApiNames) {
            if (!COM_MetaUtil.existsField(objectApiName, fieldApiName)) {
                throw new AuraHandledException('대상 필드[' + fieldApiName + ']가 존재하지 않습니다.');
            }
        }

        // 각 dependent 필드별 매핑 조회 (index 1부터)
        List<Map<Object, List<String>>> depMaps = new List<Map<Object, List<String>>>();
        for (Integer i = 1; i < fieldApiNames.size(); i++) {
            depMaps.add(COM_MetaUtil.getDependentPicklistValues(objectApiName, fieldApiNames[i]));
        }

        // 1단계: controlling 필드의 전체 picklist values
        List<String> rootValues = new List<String>();
        for (Schema.PicklistEntry e : Schema.getGlobalDescribe()
                .get(objectApiName).getDescribe()
                .fields.getMap().get(fieldApiNames[0])
                .getDescribe().getPicklistValues()) {
            if (e.isActive()) rootValues.add(e.getLabel());
        }

        // 재귀적으로 조합 생성
        List<COM_Option> results = new List<COM_Option>();
        buildCombinations(rootValues, depMaps, 0, new List<String>(), displaySeparator, valueSeparator, results);
        return results;
    }

    private static void buildCombinations(
            List<String> currentValues,
            List<Map<Object, List<String>>> depMaps,
            Integer depIndex,
            List<String> path,
            String displaySeparator,
            String valueSeparator,
            List<COM_Option> results
    ) {
        for (String val : currentValues) {
            List<String> newPath = new List<String>(path);
            newPath.add(val);

            if (depIndex >= depMaps.size()) {
                // 마지막 단계 → 옵션 추가
                results.add(new COM_Option(
                        String.join(newPath, displaySeparator),
                        String.join(newPath, valueSeparator)
                ));
            } else {
                List<String> childValues = depMaps[depIndex].get(val);
                if (childValues == null || childValues.isEmpty()) {
                    // 하위 없으면 현재까지로 옵션 추가
                    results.add(new COM_Option(String.join(newPath, displaySeparator), String.join(newPath, valueSeparator)));
                } else {
                    // 하위 있으면 재귀
                    buildCombinations(childValues, depMaps, depIndex + 1, newPath, displaySeparator, valueSeparator, results);
                }
            }
        }
    }



}