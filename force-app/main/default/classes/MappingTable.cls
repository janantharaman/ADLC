/**
 * @group        : Trestle
 * @description  :
 * @author       : Yugon Hwang
 * Modifications Log
 * Ver   Date         Author        Modification
 * 1.0   2026-02-23   Yugon Hwang   Initial Version
 **/
public without sharing class MappingTable {
    /*=========================================================================
     * CONSTANTS
     *=========================================================================*/
    private static final String PARTITION_NAME = 'MappingTable';

    private static final Integer TTL_SECONDS = 43200;

    /*=========================================================================
     * INSTANCE VARIABLES
     *=========================================================================*/
    private static Cache.OrgPartition partition;

    public static Cache.OrgPartition getPartition() {
        if (partition != null) {
            return partition;
        }

        partition = Cache.Org.getPartition(PARTITION_NAME);
        return partition;
    }

    /*=========================================================================
     * MAIN METHODS
     *=========================================================================*/
    public static Map<String, String> getMappingTable(String tableName) {
        if (String.isEmpty(tableName)) {
            return null;
        }
        getPartition();

        String safeCacheKey = getHashedKey(tableName);

        Map<String, String> mappingTable = (Map<String, String>) partition.get(safeCacheKey);

        if (mappingTable == null) {
            mappingTable = new Map<String, String>();

            // 정적 SOQL로 데이터 조회
            List<MappingTable__mdt> records = [
                SELECT Key__c, Value__c
                FROM MappingTable__mdt
                WHERE TableName__c = :tableName
            ];

            if (records.isEmpty()) {
                throw new MappingTableException('Invalid Table Name :: ' + tableName);
            }

            for (MappingTable__mdt record : records) {
                mappingTable.put(record.Key__c, record.Value__c);
            }

            // 해시 처리된 키로 캐시에 저장
            partition.put(safeCacheKey, mappingTable, TTL_SECONDS);
        }

        return mappingTable;
    }

    public static String getMappingValue(String tableName, String key) {
        if (String.isEmpty(key)) {
            return null;
        }

        Map<String, String> mappingTable = getMappingTable(tableName);

        return mappingTable.get(key);
    }

    /*=========================================================================
     * UTILS
     *=========================================================================*/
    // MD5 해시 처리하여 완벽하게 안전한 캐시 키 생성(알파벳+숫자 32자)
    private static String getHashedKey(String key) {
        Blob targetBlob = Blob.valueOf(key);
        Blob hashBlob = Crypto.generateDigest('MD5', targetBlob);
        String safeCacheKey = EncodingUtil.convertToHex(hashBlob);
        return safeCacheKey;
    }

    /*=========================================================================
     * EXCEPTION
     *=========================================================================*/
    private class MappingTableException extends Exception {
    }
}